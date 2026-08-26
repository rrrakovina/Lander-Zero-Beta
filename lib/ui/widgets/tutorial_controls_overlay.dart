import 'package:flutter/material.dart';
import '../../game/config/game_config.dart';
import '../../game/state/game_state.dart';

class TutorialControlsOverlay extends StatelessWidget {
  final double opacity;

  const TutorialControlsOverlay({
    super.key,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0.0) {
      return const SizedBox.shrink();
    }

    final state = GameState();

    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: opacity.clamp(0.0, 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Верхний ряд: основные клавиши полета (Влево, Тяга, Вправо)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Левый маневровый (A / ←)
                  _buildControlCard(
                    title: state.translate('hint_turn_left'),
                    primaryKey: 'A',
                    secondaryKey: '←',
                    icon: Icons.arrow_back_rounded,
                    accentColor: GameConfig.colorPrimary,
                  ),
                  const SizedBox(width: 12),

                  // Главная тяга (W / ↑ / SPACE)
                  _buildControlCard(
                    title: state.translate('hint_main_thrust'),
                    primaryKey: 'W',
                    secondaryKey: '↑',
                    extraKey: state.translate('hint_space'),
                    icon: Icons.rocket_launch_rounded,
                    accentColor: GameConfig.colorWarning,
                    isProminent: true,
                  ),
                  const SizedBox(width: 12),

                  // Правый маневровый (D / →)
                  _buildControlCard(
                    title: state.translate('hint_turn_right'),
                    primaryKey: 'D',
                    secondaryKey: '→',
                    icon: Icons.arrow_forward_rounded,
                    accentColor: GameConfig.colorPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Нижний ряд: вспомогательные клавиши (S/↓ Сброс груза, ESC Пауза)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCompactChip(
                    keys: 'S / ↓',
                    action: state.translate('hint_drop_brake'),
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 12),
                  _buildCompactChip(
                    keys: 'ESC',
                    action: state.translate('hint_pause'),
                    color: Colors.white70,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlCard({
    required String title,
    required String primaryKey,
    required String secondaryKey,
    String? extraKey,
    required IconData icon,
    required Color accentColor,
    bool isProminent = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isProminent ? 18 : 14,
        vertical: isProminent ? 14 : 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xE60D1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withOpacity(isProminent ? 0.7 : 0.4),
          width: isProminent ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(isProminent ? 0.25 : 0.1),
            blurRadius: isProminent ? 16 : 8,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildKeyBadge(primaryKey, accentColor),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '/',
                  style: TextStyle(
                    color: Colors.white38,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              _buildKeyBadge(secondaryKey, accentColor),
              if (extraKey != null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '/',
                    style: TextStyle(
                      color: Colors.white38,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                _buildKeyBadge(extraKey, accentColor),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: accentColor, size: isProminent ? 16 : 14),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: isProminent ? 11 : 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyBadge(String text, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: accentColor.withOpacity(0.5),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.15),
            blurRadius: 4,
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: accentColor,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildCompactChip({
    required String keys,
    required String action,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xD90D1117),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              keys,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            action,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}