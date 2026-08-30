import 'package:flutter/material.dart';
import '../../game/config/game_config.dart';
import '../../game/state/game_state.dart';

class InteractiveTutorialGuide extends StatelessWidget {
  final int step;
  final VoidCallback onSkip;

  const InteractiveTutorialGuide({
    super.key,
    required this.step,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    if (step <= 0 || step > 5) {
      return const SizedBox.shrink();
    }

    final state = GameState();

    String title;
    String desc;
    IconData icon;
    List<String> keys;
    Color accentColor;

    switch (step) {
      case 1:
        title = state.translate('tut_step1_title');
        desc = state.translate('tut_step1_desc');
        icon = Icons.rocket_launch_rounded;
        keys = ['W', '↑', state.translate('hint_space')];
        accentColor = GameConfig.colorWarning;
        break;
      case 2:
        title = state.translate('tut_step2_title');
        desc = state.translate('tut_step2_desc');
        icon = Icons.sync_alt_rounded;
        keys = ['A', 'D', '←', '→'];
        accentColor = GameConfig.colorPrimary;
        break;
      case 3:
        title = state.translate('tut_step3_title');
        desc = state.translate('tut_step3_desc');
        icon = Icons.anchor_rounded;
        keys = [state.language == 'ru' ? 'ЛАЗЕРНАЯ СЦЕПКА' : 'AUTO-DOCK'];
        accentColor = const Color(0xFF00E5FF);
        break;
      case 4:
        title = state.translate('tut_step4_title');
        desc = state.translate('tut_step4_desc');
        icon = Icons.flight_takeoff_rounded;
        keys = ['W', 'A', 'D'];
        accentColor = const Color(0xFF76FF03);
        break;
      case 5:
      default:
        title = state.translate('tut_step5_title');
        desc = state.translate('tut_step5_desc');
        icon = Icons.precision_manufacturing_rounded;
        keys = [state.language == 'ru' ? 'КРЕН < 12°' : 'TILT < 12°', state.language == 'ru' ? 'СКОРОСТЬ < 6 М/С' : 'SPEED < 6 M/S'];
        accentColor = const Color(0xFF00E676);
        break;
    }

    return Positioned(
      bottom: 24,
      left: 20,
      right: 20,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 580),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xEE0B111B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accentColor.withOpacity(0.7),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.2),
                blurRadius: 16,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: Step Title, Step Progress Dots, and Skip button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: accentColor, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Progress Dots 1..5
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      final isCurrent = index + 1 == step;
                      final isDone = index + 1 < step;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: isCurrent ? 12 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? accentColor
                              : (isDone ? const Color(0xFF00E676) : Colors.white24),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: accentColor.withOpacity(0.6),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(width: 8),
                  // Skip Button
                  InkWell(
                    onTap: onSkip,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        state.translate('tut_skip'),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 8),
              // Description and Keycaps
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      desc,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: keys.map((k) => _buildKeyBadge(k, accentColor)).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyBadge(String text, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xDD16202E),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: accentColor.withOpacity(0.5),
          width: 1.0,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: accentColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
