import 'dart:math';
import 'package:flutter/material.dart';
import '../../../game/config/game_config.dart';

/// Cybernetic Attitude Pitch & Bank Artificial Horizon Indicator.
/// Displays bank tilt angle in degrees and level alignment guidance.
class ArtificialHorizon extends StatelessWidget {
  final double angleRadians; // Ship angle in radians

  const ArtificialHorizon({
    super.key,
    required this.angleRadians,
  });

  @override
  Widget build(BuildContext context) {
    final deg = (angleRadians * 180 / pi).round();
    final norm = angleRadians.abs() % (2 * pi);
    final normalizedAngle = norm > pi ? 2 * pi - norm : norm;
    final isSafeLanding = normalizedAngle < 0.21; // ~12 degrees

    final Color horizonColor = isSafeLanding ? const Color(0xFF00E676) : GameConfig.colorWarning;
    final sign = deg >= 0 ? '+' : '';

    return Container(
      width: 110,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xCC12141C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: horizonColor.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: horizonColor.withOpacity(0.12),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ATTITUDE',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '$sign$deg°',
                style: TextStyle(
                  color: horizonColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: CustomPaint(
              painter: ArtificialHorizonPainter(
                angleRadians: angleRadians,
                color: horizonColor,
              ),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }
}

class ArtificialHorizonPainter extends CustomPainter {
  final double angleRadians;
  final Color color;

  ArtificialHorizonPainter({required this.angleRadians, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Fixed Aircraft Reference Wings
    final refPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(center.dx - 18, center.dy), Offset(center.dx - 6, center.dy), refPaint);
    canvas.drawLine(Offset(center.dx + 6, center.dy), Offset(center.dx + 18, center.dy), refPaint);
    canvas.drawCircle(center, 2.0, refPaint);

    // Rotating Artificial Horizon Line
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-angleRadians);

    final horizonPaint = Paint()
      ..color = color
      ..strokeWidth = 1.8;
    canvas.drawLine(const Offset(-22, 0), const Offset(22, 0), horizonPaint);

    // Pitch ladder rungs
    final rungPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 1.0;
    canvas.drawLine(const Offset(-8, -8), const Offset(8, -8), rungPaint);
    canvas.drawLine(const Offset(-8, 8), const Offset(8, 8), rungPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ArtificialHorizonPainter oldDelegate) {
    return oldDelegate.angleRadians != angleRadians || oldDelegate.color != color;
  }
}
