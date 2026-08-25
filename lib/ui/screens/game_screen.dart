import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import '../../game/config/game_config.dart';
import '../../game/state/game_state.dart';
import '../../game/lander_zero_game.dart';
import '../widgets/glass_panel.dart';
import '../widgets/achievement_toast.dart';
import '../widgets/minimap_widget.dart';
import '../widgets/cockpit_hud/g_force_gauge.dart';
import '../widgets/cockpit_hud/artificial_horizon.dart';
import '../widgets/cockpit_hud/proximity_warning.dart';
import '../widgets/cockpit_hud/radio_chatter_overlay.dart';

class GameScreen extends StatefulWidget {
  final String mapId;
  final VoidCallback onExit;

  const GameScreen({
    super.key,
    required this.mapId,
    required this.onExit,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late LanderZeroGame _game;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _initNewGame();
  }

  void _initNewGame() {
    setState(() {
      _game = LanderZeroGame(mapId: widget.mapId);
      _isPaused = false;
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _game.pauseEngine();
      } else {
        _game.resumeEngine();
      }
    });
  }

  void _restartGame() {
    _initNewGame();
  }

  @override
  Widget build(BuildContext context) {
    final state = GameState();

    return Scaffold(
      backgroundColor: GameConfig.colorBackground,
      body: AchievementToastOverlay(
        child: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
              _togglePause();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: SizedBox.expand(
            child: Stack(
            children: [
              // 1. Игровое поле Flame
              Positioned.fill(
                child: GameWidget(
                  game: _game,
                ),
              ),

              // 2. HUD (Верхняя панель с датчиками)
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: ValueListenableBuilder<Map<String, dynamic>>(
                  valueListenable: _game.statsNotifier,
                  builder: (context, stats, _) {
                    if (!_game.isLoaded) {
                      return const SizedBox.shrink();
                    }

                    final double fuel = (stats['fuel'] as num?)?.toDouble() ?? 1.0;
                    final double maxFuel = (stats['maxFuel'] as num?)?.toDouble() ?? 1.0;
                    final double shield = (stats['shield'] as num?)?.toDouble() ?? 1.0;
                    final double maxShield = (stats['maxShield'] as num?)?.toDouble() ?? 1.0;

                    final fuelPercent = fuel / maxFuel;
                    final shieldPercent = shield / maxShield;

                    final alertText = stats['alert'] as String? ?? '';
                    final coins = stats['coins'] as int? ?? 0;
                    final distance = stats['distance'] as double? ?? 0.0;

                    final double gForce = (stats['gForce'] as num?)?.toDouble() ?? 1.0;
                    final double pitchAngle = (stats['pitchAngle'] as num?)?.toDouble() ?? 0.0;
                    final double proxDist = (stats['proximityDistance'] as num?)?.toDouble() ?? 99.0;
                    final bool isProxAlert = stats['isProximityAlert'] as bool? ?? false;
                    final String radioMsg = stats['radioChatterMessage'] as String? ?? '';

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fuel Gauge + G-Force Gauge
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStatusIndicator(
                                  title: state.translate('fuel'),
                                  value: fuelPercent,
                                  activeColor: GameConfig.colorWarning,
                                  icon: Icons.local_gas_station_rounded,
                                ),
                                const SizedBox(width: 8),
                                GForceGauge(gForce: gForce),
                              ],
                            ),
                            
                            // Distance, Coins & Pause + Attitude Horizon
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: GameConfig.colorPrimary.withOpacity(0.3)),
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.black54,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.terrain_rounded, color: GameConfig.colorPrimary, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${distance.toInt()} ${state.translate('stats_meters')}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Icon(Icons.stars_rounded, color: GameConfig.colorWarning, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$coins',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: _togglePause,
                                          borderRadius: BorderRadius.circular(10),
                                          child: const Padding(
                                            padding: EdgeInsets.all(4.0),
                                            child: Icon(Icons.pause_rounded, color: Colors.white, size: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ArtificialHorizon(angleRadians: pitchAngle),
                              ],
                            ),

                            // Shield Gauge + Minimap
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStatusIndicator(
                                  title: state.translate('shield'),
                                  value: shieldPercent,
                                  activeColor: GameConfig.colorDanger,
                                  icon: Icons.shield_rounded,
                                ),
                                const SizedBox(width: 12),
                                MinimapWidget(game: _game),
                              ],
                            ),
                          ],
                        ),

                        // Proximity Warning & Alerts
                        if (isProxAlert) ...[
                          const SizedBox(height: 8),
                          ProximityWarningAlarm(isAlert: isProxAlert, distance: proxDist),
                        ] else if (alertText.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: GameConfig.colorWarning, width: 1),
                            ),
                            child: Text(
                              alertText,
                              style: const TextStyle(
                                color: GameConfig.colorWarning,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],

                        // Radio Chatter Overlay
                        if (radioMsg.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          RadioChatterOverlay(message: radioMsg),
                        ],
                      ],
                    );
                  },
                ),
              ),

              // 3. Сенсорное управление
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: Listener(
                        onPointerDown: (_) => _game.setLeftThrust(true),
                        onPointerUp: (_) => _game.setLeftThrust(false),
                        onPointerCancel: (_) => _game.setLeftThrust(false),
                        child: Container(
                          color: Colors.transparent,
                          alignment: Alignment.bottomLeft,
                          padding: const EdgeInsets.all(30),
                          child: _buildControlHint(
                              state.translate('thrust_left'),
                              Alignment.bottomLeft),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Listener(
                        onPointerDown: (_) => _game.setRightThrust(true),
                        onPointerUp: (_) => _game.setRightThrust(false),
                        onPointerCancel: (_) => _game.setRightThrust(false),
                        child: Container(
                          color: Colors.transparent,
                          alignment: Alignment.bottomRight,
                          padding: const EdgeInsets.all(30),
                          child: _buildControlHint(
                              state.translate('thrust_right'),
                              Alignment.bottomRight),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Кнопка сброса груза для мобильных/сенсорных экранов
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: ValueListenableBuilder<Map<String, dynamic>>(
                    valueListenable: _game.statsNotifier,
                    builder: (context, stats, _) {
                      if (!_game.isLoaded) return const SizedBox.shrink();
                      final hasRope = stats['hasRope'] as bool? ?? false;
                      if (!hasRope) return const SizedBox.shrink();

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (_game.runStateNotifier.value == GameRunState.playing) {
                              _game.releaseCargo();
                            }
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: GameConfig.colorDanger, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: GameConfig.colorDanger.withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.link_off_rounded, color: GameConfig.colorDanger, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  state.translate('cargo_release').toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 4. Пауза
              if (_isPaused)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                    child: Container(
                      color: Colors.black.withOpacity(0.65),
                      child: Center(
                        child: GlassPanel(
                          borderColor: GameConfig.colorPrimary.withOpacity(0.4),
                          borderRadius: 16,
                          child: SizedBox(
                            width: 320,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.pause_circle_filled_rounded,
                                    color: GameConfig.colorPrimary, size: 48),
                                const SizedBox(height: 16),
                                Text(
                                  state.translate('esc_paused'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _togglePause,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: GameConfig.colorPrimary,
                                    foregroundColor: Colors.black,
                                    minimumSize: const Size.fromHeight(45),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  child: Text(
                                    state.translate('resume').toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: _restartGame,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.white24),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(45),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  child: Text(
                                    state.translate('restart').toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: widget.onExit,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: GameConfig.colorDanger.withOpacity(0.5)),
                                    foregroundColor: GameConfig.colorDanger,
                                    minimumSize: const Size.fromHeight(45),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  child: Text(
                                    state.translate('exit_menu').toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // 5. Пост-ран статистика
              ValueListenableBuilder<GameRunState>(
                valueListenable: _game.runStateNotifier,
                builder: (context, runState, _) {
                  if (runState == GameRunState.playing) {
                    return const SizedBox.shrink();
                  }

                  return PostRunStatsOverlay(
                    game: _game,
                    runState: runState,
                    onExit: widget.onExit,
                    onRestart: _restartGame,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildStatusIndicator({
    required String title,
    required double value,
    required Color activeColor,
    required IconData icon,
  }) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xAA16161E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: activeColor, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white60,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '${(value * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: activeColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: value.clamp(0.0, 1.0),
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlHint(String text, Alignment alignment) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x55000000),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 11,
          letterSpacing: 1,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class PostRunStatsOverlay extends StatefulWidget {
  final LanderZeroGame game;
  final GameRunState runState;
  final VoidCallback onExit;
  final VoidCallback onRestart;

  const PostRunStatsOverlay({
    super.key,
    required this.game,
    required this.runState,
    required this.onExit,
    required this.onRestart,
  });

  @override
  State<PostRunStatsOverlay> createState() => _PostRunStatsOverlayState();
}

class _PostRunStatsOverlayState extends State<PostRunStatsOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _counterController;
  late Animation<double> _counterAnimation;
  int _animatedReward = 0;

  @override
  void initState() {
    super.initState();
    final isWon = widget.runState == GameRunState.won;
    int reward = widget.game.coinsCollected * 10 + (isWon ? 100 : 0);
    if (widget.game.mapId == 'endless' && widget.game.endlessManager != null) {
      reward += widget.game.endlessManager!.rescuesCount * 100;
    }

    _counterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _counterAnimation = Tween<double>(begin: 0.0, end: reward.toDouble()).animate(
      CurvedAnimation(parent: _counterController, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() {
          _animatedReward = _counterAnimation.value.toInt();
        });
      });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _counterController.forward();
      }
    });
  }

  @override
  void dispose() {
    _counterController.dispose();
    super.dispose();
  }

  Widget _buildStatsRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = GameState();
    final isWon = widget.runState == GameRunState.won;
    final accentColor = isWon ? GameConfig.colorPrimary : GameConfig.colorDanger;
    final titleText = isWon ? state.translate('victory') : state.translate('defeat');
    final subTitleText = isWon ? state.translate('victory_desc') : state.translate('defeat_desc');
    final flightSec = widget.game.flightTime;
    final damage = widget.game.totalDamage;

    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Container(
          color: Colors.black.withOpacity(0.7),
          child: Center(
            child: SingleChildScrollView(
              child: GlassPanel(
                borderColor: accentColor.withOpacity(0.5),
                borderRadius: 16,
                padding: 24,
                child: SizedBox(
                  width: 440,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isWon ? Icons.verified_rounded : Icons.gavel_rounded,
                        color: accentColor,
                        size: 56,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        titleText,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subTitleText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 12),
                      _buildStatsRow(state.translate('stats_dist'),
                          '${widget.game.maxDistance.toInt()} ${state.translate('stats_meters')}'),
                      const SizedBox(height: 8),
                      if (widget.game.mapId == 'endless') ...[
                        _buildStatsRow(
                          state.language == 'ru' ? 'Спасенных выживших' : 'Rescued survivors',
                          '${widget.game.endlessManager?.rescuesCount ?? 0}',
                        ),
                        const SizedBox(height: 8),
                      ],
                      _buildStatsRow(state.translate('stats_time'),
                          '${flightSec.toStringAsFixed(1)} ${state.translate('stats_sec')}'),
                      const SizedBox(height: 8),
                      _buildStatsRow(state.translate('stats_coins'), '${widget.game.coinsCollected}'),
                      const SizedBox(height: 8),
                      _buildStatsRow(state.translate('stats_damage'), '${damage.toInt()}%'),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            state.translate('stats_reward').toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.stars_rounded,
                                  color: GameConfig.colorWarning, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                '+$_animatedReward',
                                style: const TextStyle(
                                  color: GameConfig.colorWarning,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: widget.onExit,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white24),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              child: Text(
                                state.translate('exit_menu').toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: widget.onRestart,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              child: Text(
                                (isWon ? state.translate('play') : state.translate('restart'))
                                    .toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
