import 'dart:math';
import 'package:flutter/material.dart';
import '../../game/config/game_config.dart';
import '../../game/state/game_state.dart';
import '../widgets/menu_background.dart';
import '../widgets/glass_panel.dart';
import '../painters/rocket_painter.dart';
import '../dialogs/settings_dialog.dart';

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
                          _buildMenuButton(
                            title: state.translate('play'),
                            icon: Icons.play_arrow_rounded,
                            color: GameConfig.colorPrimary,
                            onTap: onPlay,
                          ),
                          const SizedBox(height: 16),
                          _buildMenuButton(
                            title: state.translate('garage'),
                            icon: Icons.build_rounded,
                            color: GameConfig.colorWarning,
                            onTap: onGarage,
                          ),
                          const SizedBox(height: 16),
                          _buildMenuButton(
                            title: state.translate('records'),
                            icon: Icons.emoji_events_rounded,
                            color: const Color(0xFFE040FB),
                            onTap: onLeaderboard,
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
                                  backgroundColor: GameConfig.colorPrimary.withOpacity(0.1),
                                  child: const Icon(Icons.person_outline_rounded, color: GameConfig.colorPrimary),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.nickname,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      isRu ? 'Статус: Готов к вылету' : 'Status: Ready for flight',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
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

  Widget _buildMenuButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: color.withOpacity(0.08),
        splashColor: color.withOpacity(0.15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            color: color.withOpacity(0.03),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity(0.5), size: 18),
            ],
          ),
        ),
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
        return CustomPaint(
          size: const Size(120, 120),
          painter: RocketPainter(
            rocketId: widget.rocketId,
            animationTime: _animController.value * 2 * pi,
          ),
        );
      },
    );
  }
}
