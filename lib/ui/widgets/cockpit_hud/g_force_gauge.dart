import 'package:flutter/material.dart';
import '../../../game/config/game_config.dart';

/// Cybernetic G-Force Arc Indicator.
/// Displays instantaneous G-load with Safe (< 2.0g), Warning (2.0-3.5g), Critical (> 3.5g) zones.
class GForceGauge extends StatelessWidget {
  final double gForce;

  const GForceGauge({
    super.key,
    required this.gForce,
  });

  @override
  Widget build(BuildContext context) {
    Color gaugeColor;
    String statusText;

    if (gForce < 2.0) {
      gaugeColor = const Color(0xFF00E676);
      statusText = 'SAFE';
    } else if (gForce < 3.5) {
      gaugeColor = GameConfig.colorWarning;
      statusText = 'WARNING';
    } else {
      gaugeColor = GameConfig.colorDanger;
      statusText = 'CRITICAL';
    }

    final clampedG = gForce.clamp(0.0, 6.0);
    final progress = (clampedG / 6.0).clamp(0.0, 1.0);

    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xCC12141C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: gaugeColor.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: gaugeColor.withOpacity(0.15),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'G-FORCE',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                statusText,
                style: TextStyle(
                  color: gaugeColor,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                gForce.toStringAsFixed(1),
                style: TextStyle(
                  color: gaugeColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 3),
              const Text(
                'G',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(gaugeColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
