import 'package:flutter/material.dart';
import '../../../game/config/game_config.dart';

/// Flashing audio-visual Proximity Warning alarm indicator when ship nears cavern walls.
class ProximityWarningAlarm extends StatefulWidget {
  final bool isAlert;
  final double distance;

  const ProximityWarningAlarm({
    super.key,
    required this.isAlert,
    required this.distance,
  });

  @override
  State<ProximityWarningAlarm> createState() => _ProximityWarningAlarmState();
}

class _ProximityWarningAlarmState extends State<ProximityWarningAlarm> with SingleTickerProviderStateMixin {
  late final AnimationController _flashController;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAlert) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _flashController,
      builder: (context, _) {
        final double opacity = 0.4 + 0.6 * _flashController.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: GameConfig.colorDanger.withOpacity(opacity),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: GameConfig.colorDanger.withOpacity(0.5 * _flashController.value),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: GameConfig.colorDanger.withOpacity(opacity),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'PROXIMITY WARNING // TERRAIN CLOSE',
                style: TextStyle(
                  color: GameConfig.colorDanger.withOpacity(opacity),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
