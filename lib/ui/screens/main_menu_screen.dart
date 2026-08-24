import 'dart:math';
import 'package:flutter/material.dart';
import '../../game/config/game_config.dart';
import '../../game/state/game_state.dart';
import '../../game/state/achievements_manager.dart';
import '../widgets/menu_background.dart';
import '../widgets/glass_panel.dart';
import '../painters/rocket_painter.dart';
import '../dialogs/settings_dialog.dart';
import '../dialogs/achievements_dialog.dart';

class MainMenuWidget extends StatelessWidget {
  final VoidCallback onPlay;
  final VoidCallback onGarage;
  final VoidCallback onLeaderboard;

  const MainMenuWidget({
    super.key,
    required this.onPlay,
    required this.onGarage,
    required this.onLeaderboard,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GameState(),
      builder: (context, child) {
        final state = GameState();
        final isRu = state.language == 'ru';
        final selectedCabin = state.selectedRocket;
        final cabinConfig = GameState.rocketConfigs[selectedCabin]!;

        final unlockedAchievementsCount = AchievementsManager().achievements.where((a) => a.isUnlocked).length;
        final totalUpgrades = state.engineLevel + state.fuelLevel + state.shieldLevel;
        final rankInfo = PilotRankingInfo.calculate(
          unlockedAchievementsCount: unlockedAchievementsCount,
          totalUpgradeLevels: totalUpgrades,
          ownedShipsCount: state.ownedRockets.length,
          totalCoins: state.totalCoins,
          completedRecordsCount: state.leaderboard.length,
        );

        return MenuBackground(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Top Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.translate('title'),
                          style: const TextStyle(
                            color: GameConfig.colorPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isRu ? 'КОСМИЧЕСКАЯ СПАСАТЕЛЬНАЯ СЛУЖБА' : 'COSMIC RESCUE DIVISION',
                          style: const TextStyle(
                            color: Colors.white30,
                            fontSize: 13,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    // Coins, Nick, Lang
                    Row(
                      children: [
                        // Language Selector Button
                        OutlinedButton(
                          onPressed: () {
                            state.setLanguage(isRu ? 'en' : 'ru');
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white24),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: Text(isRu ? 'EN' : 'RU'),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.settings_rounded, color: Colors.white),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => const SettingsDialog(),
                            );
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.05),
                            padding: const EdgeInsets.all(12),
                            side: const BorderSide(color: Colors.white24),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Coins Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: GameConfig.colorWarning.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.stars_rounded, color: GameConfig.colorWarning, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '${state.totalCoins}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                // Main Panels
                Row(
                  children: [
                    // Navigation Buttons
                    Expanded(
                      flex: 4,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HoverMenuButton(
                            title: state.translate('play'),
                            icon: Icons.play_arrow_rounded,
                            color: GameConfig.colorPrimary,
                            onTap: onPlay,
                          ),
                          const SizedBox(height: 16),
                          HoverMenuButton(
                            title: state.translate('garage'),
                            icon: Icons.build_rounded,
                            color: GameConfig.colorWarning,
                            onTap: onGarage,
                          ),
                          const SizedBox(height: 16),
                          HoverMenuButton(
                            title: state.translate('records'),
                            icon: Icons.emoji_events_rounded,
                            color: const Color(0xFFE040FB),
                            onTap: onLeaderboard,
                          ),
                          const SizedBox(height: 16),
                          HoverMenuButton(
                            title: state.language == 'ru' ? 'ДОСТИЖЕНИЯ' : 'ACHIEVEMENTS',
                            icon: Icons.military_tech_rounded,
                            color: const Color(0xFFFFD700),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => const AchievementsDialog(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Profile/Rocket Info
                    Expanded(
                      flex: 5,
                      child: GlassPanel(
                        borderColor: Colors.white10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: rankInfo.color.withOpacity(0.15),
                                  child: Icon(Icons.person_outline_rounded, color: rankInfo.color, size: 28),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            state.nickname.isEmpty ? (isRu ? 'Пилот' : 'Pilot') : state.nickname,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: rankInfo.color.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: rankInfo.color.withOpacity(0.6)),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: rankInfo.color.withOpacity(0.15),
                                                  blurRadius: 6,
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  rankInfo.icon,
                                                  size: 13,
                                                  color: rankInfo.color,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  isRu ? rankInfo.badgeTextRu : rankInfo.badgeTextEn,
                                                  style: TextStyle(
                                                    color: rankInfo.color,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1.1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      _buildTelemetryIndicators(state, isRu),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(color: Colors.white10),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left specs column
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isRu ? 'ВЫБРАННЫЙ КОРАБЛЬ:' : 'SELECTED VESSEL:',
                                        style: const TextStyle(
                                          color: Colors.white30,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        isRu ? cabinConfig['nameRu'] : cabinConfig['nameEn'],
                                        style: const TextStyle(
                                          color: GameConfig.colorPrimary,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        isRu ? cabinConfig['descRu'] : cabinConfig['descEn'],
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildSpecBar(
                                        title: state.translate('engine'),
                                        value: (state.engineLevel / 5.0),
                                        displayValue: 'Lvl ${state.engineLevel}',
                                        color: GameConfig.colorPrimary,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildSpecBar(
                                        title: state.translate('fuel'),
                                        value: (state.fuelLevel / 5.0),
                                        displayValue: 'Lvl ${state.fuelLevel}',
                                        color: GameConfig.colorWarning,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildSpecBar(
                                        title: state.translate('shield'),
                                        value: (state.shieldLevel / 5.0),
                                        displayValue: 'Lvl ${state.shieldLevel}',
                                        color: GameConfig.colorDanger,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Right rocket visual column
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 10),
                                      MainMenuRocketPreview(rocketId: selectedCabin),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTelemetryIndicators(GameState state, bool isRu) {
    final totalUpgrades = state.engineLevel + state.fuelLevel + state.shieldLevel;
    // Compute ship systems readiness percentage: 60% base for level 1 stats, up to 100% at max level 5 stats (15 total levels)
    final readinessPercent = min(100, (60 + ((totalUpgrades - 3) / 12.0) * 40).round());

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          const TelemetryPulseDot(color: Color(0xFF00E676)),
          const SizedBox(width: 6),
          Text(
            isRu ? 'ТЕЛЕМЕТРИЯ: АКТИВНА' : 'TELEMETRY: ACTIVE',
            style: const TextStyle(
              color: Color(0xFF00E676),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 10, color: Colors.white24),
          const SizedBox(width: 8),
          Text(
            isRu ? 'СВЯЗЬ: 99.8%' : 'LINK: 99.8%',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 10, color: Colors.white24),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    isRu ? 'ГОТОВНОСТЬ: $readinessPercent%' : 'SYS READY: $readinessPercent%',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: readinessPercent >= 90 ? GameConfig.colorPrimary : GameConfig.colorWarning,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 28,
                  height: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: readinessPercent / 100.0,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        readinessPercent >= 90 ? GameConfig.colorPrimary : GameConfig.colorWarning,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecBar({
    required String title,
    required double value,
    required String displayValue,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white54, fontSize: 13)),
            Text(displayValue, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

enum PilotRankTier {
  cadet,
  pilot,
  officer,
  veteran,
  commander,
}

class PilotRankingInfo {
  final PilotRankTier tier;
  final String titleRu;
  final String titleEn;
  final Color color;
  final String badgeTextRu;
  final String badgeTextEn;
  final IconData icon;

  const PilotRankingInfo({
    required this.tier,
    required this.titleRu,
    required this.titleEn,
    required this.color,
    required this.badgeTextRu,
    required this.badgeTextEn,
    required this.icon,
  });

  static PilotRankingInfo calculate({
    required int unlockedAchievementsCount,
    required int totalUpgradeLevels,
    required int ownedShipsCount,
    required int totalCoins,
    required int completedRecordsCount,
  }) {
    if (unlockedAchievementsCount >= 4 || totalUpgradeLevels >= 13 || (unlockedAchievementsCount >= 3 && ownedShipsCount >= 3)) {
      return const PilotRankingInfo(
        tier: PilotRankTier.commander,
        titleRu: 'Командор',
        titleEn: 'Commander',
        color: Color(0xFFFFD700),
        badgeTextRu: 'РАНГ: КОМАНДОР',
        badgeTextEn: 'RANK: COMMANDER',
        icon: Icons.workspace_premium_rounded,
      );
    } else if (unlockedAchievementsCount >= 3 || totalUpgradeLevels >= 10 || ownedShipsCount >= 3) {
      return const PilotRankingInfo(
        tier: PilotRankTier.veteran,
        titleRu: 'Ветеран',
        titleEn: 'Veteran',
        color: Color(0xFFE040FB),
        badgeTextRu: 'РАНГ: ВЕТЕРАН',
        badgeTextEn: 'RANK: VETERAN',
        icon: Icons.military_tech_rounded,
      );
    } else if (unlockedAchievementsCount >= 2 || totalUpgradeLevels >= 7 || ownedShipsCount >= 2) {
      return const PilotRankingInfo(
        tier: PilotRankTier.officer,
        titleRu: 'Офицер',
        titleEn: 'Officer',
        color: Color(0xFFFF9100),
        badgeTextRu: 'РАНГ: ОФИЦЕР',
        badgeTextEn: 'RANK: OFFICER',
        icon: Icons.shield_rounded,
      );
    } else if (unlockedAchievementsCount >= 1 || totalUpgradeLevels >= 4 || totalCoins >= 100 || completedRecordsCount >= 1) {
      return const PilotRankingInfo(
        tier: PilotRankTier.pilot,
        titleRu: 'Пилот',
        titleEn: 'Pilot',
        color: Color(0xFF00E5FF),
        badgeTextRu: 'РАНГ: ПИЛОТ',
        badgeTextEn: 'RANK: PILOT',
        icon: Icons.flight_takeoff_rounded,
      );
    } else {
      return const PilotRankingInfo(
        tier: PilotRankTier.cadet,
        titleRu: 'Кадет',
        titleEn: 'Cadet',
        color: Color(0xFF80D8FF),
        badgeTextRu: 'РАНГ: КАДЕТ',
        badgeTextEn: 'RANK: CADET',
        icon: Icons.school_rounded,
      );
    }
  }
}

class TelemetryPulseDot extends StatefulWidget {
  final Color color;
  const TelemetryPulseDot({super.key, this.color = const Color(0xFF00E676)});

  @override
  State<TelemetryPulseDot> createState() => _TelemetryPulseDotState();
}

class _TelemetryPulseDotState extends State<TelemetryPulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final scale = 0.8 + (_animController.value * 0.4);
        final opacity = 0.5 + (_animController.value * 0.5);
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(opacity),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.6 * _animController.value),
                blurRadius: 6 * scale,
                spreadRadius: 2 * scale,
              ),
            ],
          ),
        );
      },
    );
  }
}

class MainMenuRocketPreview extends StatefulWidget {
  final String rocketId;
  const MainMenuRocketPreview({super.key, required this.rocketId});

  @override
  State<MainMenuRocketPreview> createState() => _MainMenuRocketPreviewState();
}

class _MainMenuRocketPreviewState extends State<MainMenuRocketPreview> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final double hoverOffset = sin(_animController.value * 2 * pi) * 6.0; // Плавная левитация на 6 пикселей
        return Transform.translate(
          offset: Offset(0, hoverOffset),
          child: CustomPaint(
            size: const Size(120, 120),
            painter: RocketPainter(
              rocketId: widget.rocketId,
              animationTime: _animController.value * 2 * pi,
            ),
          ),
        );
      },
    );
  }
}

class HoverMenuButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const HoverMenuButton({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<HoverMenuButton> createState() => _HoverMenuButtonState();
}

class _HoverMenuButtonState extends State<HoverMenuButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..translate(_isHovered ? 8.0 : 0.0, 0.0), // Смещение вправо при наведении
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            hoverColor: Colors.transparent,
            splashColor: color.withOpacity(0.15),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isHovered ? color : color.withOpacity(0.3),
                  width: _isHovered ? 2.0 : 1.5,
                ),
                color: _isHovered ? color.withOpacity(0.08) : color.withOpacity(0.03),
                boxShadow: _isHovered ? [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 15,
                    spreadRadius: 1,
                  )
                ] : [],
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: color, size: 32),
                  const SizedBox(width: 16),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.identity()..translate(_isHovered ? 4.0 : 0.0),
                    child: Icon(Icons.arrow_forward_ios_rounded, color: _isHovered ? color : color.withOpacity(0.5), size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
