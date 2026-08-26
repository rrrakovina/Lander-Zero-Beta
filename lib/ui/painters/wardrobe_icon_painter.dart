import 'dart:math';
import 'package:flutter/material.dart';

enum WardrobeItemType { helmet, suit }

class WardrobeIconWidget extends StatelessWidget {
  final String id;
  final WardrobeItemType type;
  final bool isSelected;
  final Color accentColor;
  final double size;

  const WardrobeIconWidget({
    super.key,
    required this.id,
    required this.type,
    this.isSelected = false,
    this.accentColor = Colors.white,
    this.size = 36.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: WardrobeIconPainter(
        id: id,
        type: type,
        isSelected: isSelected,
        accentColor: accentColor,
      ),
    );
  }
}

class WardrobeIconPainter extends CustomPainter {
  final String id;
  final WardrobeItemType type;
  final bool isSelected;
  final Color accentColor;

  WardrobeIconPainter({
    required this.id,
    required this.type,
    required this.isSelected,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double r = min(w, h) * 0.44;

    if (type == WardrobeItemType.helmet) {
      _paintHelmet(canvas, cx, cy, r);
    } else {
      _paintSuit(canvas, cx, cy, r);
    }
  }

  void _paintHelmet(Canvas canvas, double cx, double cy, double r) {
    final strokeColor = isSelected ? accentColor : Colors.white;
    final fillColor = isSelected ? accentColor.withOpacity(0.2) : const Color(0xFF20262E);
    final darkVisor = const Color(0xFF0F1318);

    final linePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.2, r * 0.08)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final visorPaint = Paint()
      ..color = darkVisor
      ..style = PaintingStyle.fill;

    switch (id) {
      case 'cyber_visor':
        // Hexagonal angular tactical helmet
        final path = Path()
          ..moveTo(cx, cy - r * 0.95)
          ..lineTo(cx + r * 0.85, cy - r * 0.50)
          ..lineTo(cx + r * 0.90, cy + r * 0.40)
          ..lineTo(cx + r * 0.50, cy + r * 0.90)
          ..lineTo(cx - r * 0.50, cy + r * 0.90)
          ..lineTo(cx - r * 0.90, cy + r * 0.40)
          ..lineTo(cx - r * 0.85, cy - r * 0.50)
          ..close();

        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, linePaint);

        // Cyber Visor slit
        final visorPath = Path()
          ..moveTo(cx - r * 0.70, cy - r * 0.15)
          ..lineTo(cx + r * 0.70, cy - r * 0.15)
          ..lineTo(cx + r * 0.60, cy + r * 0.18)
          ..lineTo(cx - r * 0.60, cy + r * 0.18)
          ..close();
        canvas.drawPath(visorPath, visorPaint);
        canvas.drawPath(visorPath, linePaint);

        // Center optic sensor
        final opticPaint = Paint()
          ..color = isSelected ? accentColor : const Color(0xFF00E5FF)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(cx, cy), r * 0.12, opticPaint);

        // Side antenna fin
        canvas.drawLine(
          Offset(cx + r * 0.85, cy - r * 0.20),
          Offset(cx + r * 1.10, cy - r * 0.60),
          linePaint,
        );
        break;

      case 'miner_helmet':
        // Heavy domed blast helmet with forehead rim
        final domePath = Path()
          ..moveTo(cx - r * 0.85, cy + r * 0.70)
          ..lineTo(cx - r * 0.85, cy - r * 0.20)
          ..quadraticBezierTo(cx - r * 0.80, cy - r * 0.95, cx, cy - r * 0.95)
          ..quadraticBezierTo(cx + r * 0.80, cy - r * 0.95, cx + r * 0.85, cy - r * 0.20)
          ..lineTo(cx + r * 0.85, cy + r * 0.70)
          ..close();

        canvas.drawPath(domePath, fillPaint);
        canvas.drawPath(domePath, linePaint);

        // Top headlamp
        final lampRect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy - r * 0.95), width: r * 0.50, height: r * 0.30),
          Radius.circular(r * 0.08),
        );
        canvas.drawRRect(lampRect, Paint()..color = const Color(0xFFFFD600));
        canvas.drawRRect(lampRect, linePaint);

        // Visor with 3 protective grate bars
        final visorRect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy + r * 0.15), width: r * 1.15, height: r * 0.55),
          Radius.circular(r * 0.15),
        );
        canvas.drawRRect(visorRect, visorPaint);
        canvas.drawRRect(visorRect, linePaint);

        // Grate vertical bars
        canvas.drawLine(Offset(cx - r * 0.28, cy - r * 0.10), Offset(cx - r * 0.28, cy + r * 0.40), linePaint);
        canvas.drawLine(Offset(cx, cy - r * 0.10), Offset(cx, cy + r * 0.40), linePaint);
        canvas.drawLine(Offset(cx + r * 0.28, cy - r * 0.10), Offset(cx + r * 0.28, cy + r * 0.40), linePaint);
        break;

      case 'swift_aero':
        // Streamlined interceptor helmet with dorsal crest
        final aeroPath = Path()
          ..moveTo(cx, cy - r * 1.10)
          ..quadraticBezierTo(cx + r * 0.95, cy - r * 0.40, cx + r * 0.80, cy + r * 0.70)
          ..lineTo(cx + r * 0.40, cy + r * 0.85)
          ..lineTo(cx, cy + r * 0.70)
          ..lineTo(cx - r * 0.40, cy + r * 0.85)
          ..lineTo(cx - r * 0.80, cy + r * 0.70)
          ..quadraticBezierTo(cx - r * 0.95, cy - r * 0.40, cx, cy - r * 1.10)
          ..close();

        canvas.drawPath(aeroPath, fillPaint);
        canvas.drawPath(aeroPath, linePaint);

        // Gold/Amber tinted panoramic visor
        final visorPath = Path()
          ..moveTo(cx - r * 0.65, cy - r * 0.10)
          ..quadraticBezierTo(cx, cy - r * 0.45, cx + r * 0.65, cy - r * 0.10)
          ..quadraticBezierTo(cx + r * 0.50, cy + r * 0.50, cx, cy + r * 0.55)
          ..quadraticBezierTo(cx - r * 0.50, cy + r * 0.50, cx - r * 0.65, cy - r * 0.10)
          ..close();
        canvas.drawPath(visorPath, visorPaint);
        canvas.drawPath(visorPath, linePaint);

        // Side aerodynamic winglet fins
        canvas.drawLine(Offset(cx - r * 0.80, cy + r * 0.10), Offset(cx - r * 1.05, cy + r * 0.55), linePaint);
        canvas.drawLine(Offset(cx + r * 0.80, cy + r * 0.10), Offset(cx + r * 1.05, cy + r * 0.55), linePaint);
        break;

      case 'sphere1':
      default:
        // Retro circular bubble dome
        canvas.drawCircle(Offset(cx, cy), r * 0.88, fillPaint);
        canvas.drawCircle(Offset(cx, cy), r * 0.88, linePaint);

        // Inner visor bubble
        canvas.drawCircle(Offset(cx, cy + r * 0.05), r * 0.60, visorPaint);
        canvas.drawCircle(Offset(cx, cy + r * 0.05), r * 0.60, linePaint);

        // Specular highlight crescent
        final highlightPaint = Paint()
          ..color = Colors.white70
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.0, r * 0.07)
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy + r * 0.05), radius: r * 0.45),
          -2.2,
          1.2,
          false,
          highlightPaint,
        );

        // Base collar ring
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx, cy + r * 0.85), width: r * 1.2, height: r * 0.4),
          0,
          pi,
          false,
          linePaint,
        );
        break;
    }
  }

  void _paintSuit(Canvas canvas, double cx, double cy, double r) {
    final strokeColor = isSelected ? accentColor : Colors.white;
    final fillColor = isSelected ? accentColor.withOpacity(0.2) : const Color(0xFF20262E);

    final linePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.2, r * 0.08)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    // Standard Torso Silhouette
    final torsoPath = Path()
      ..moveTo(cx - r * 0.35, cy - r * 0.70)
      ..lineTo(cx + r * 0.35, cy - r * 0.70)
      ..lineTo(cx + r * 0.95, cy - r * 0.15)
      ..lineTo(cx + r * 0.85, cy + r * 0.85)
      ..lineTo(cx - r * 0.85, cy + r * 0.85)
      ..lineTo(cx - r * 0.95, cy - r * 0.15)
      ..close();

    canvas.drawPath(torsoPath, fillPaint);
    canvas.drawPath(torsoPath, linePaint);

    // Collar ring
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy - r * 0.70), width: r * 0.75, height: r * 0.35),
      0,
      pi,
      false,
      linePaint,
    );

    switch (id) {
      case 'exo_frame':
        // Armored heavy shoulder pauldrons
        final leftPad = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx - r * 0.80, cy - r * 0.20), width: r * 0.50, height: r * 0.45),
          Radius.circular(r * 0.10),
        );
        final rightPad = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx + r * 0.80, cy - r * 0.20), width: r * 0.50, height: r * 0.45),
          Radius.circular(r * 0.10),
        );
        canvas.drawRRect(leftPad, fillPaint);
        canvas.drawRRect(leftPad, linePaint);
        canvas.drawRRect(rightPad, fillPaint);
        canvas.drawRRect(rightPad, linePaint);

        // X-Harness belts
        canvas.drawLine(Offset(cx - r * 0.60, cy - r * 0.35), Offset(cx + r * 0.45, cy + r * 0.75), linePaint);
        canvas.drawLine(Offset(cx + r * 0.60, cy - r * 0.35), Offset(cx - r * 0.45, cy + r * 0.75), linePaint);

        // Center rotary buckle
        canvas.drawCircle(Offset(cx, cy + r * 0.20), r * 0.18, Paint()..color = const Color(0xFFFFB300));
        canvas.drawCircle(Offset(cx, cy + r * 0.20), r * 0.18, linePaint);
        break;

      case 'cryo_suit':
        // Horizontal thermal insulation ribs
        canvas.drawLine(Offset(cx - r * 0.55, cy - r * 0.10), Offset(cx + r * 0.55, cy - r * 0.10), linePaint);
        canvas.drawLine(Offset(cx - r * 0.65, cy + r * 0.20), Offset(cx + r * 0.65, cy + r * 0.20), linePaint);
        canvas.drawLine(Offset(cx - r * 0.55, cy + r * 0.50), Offset(cx + r * 0.55, cy + r * 0.50), linePaint);

        // Coolant piping lines
        final cryoPipe = Paint()
          ..color = isSelected ? accentColor : const Color(0xFF00E5FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.5, r * 0.10)
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(cx - r * 0.35, cy - r * 0.50), Offset(cx - r * 0.35, cy + r * 0.75), cryoPipe);
        canvas.drawLine(Offset(cx + r * 0.35, cy - r * 0.50), Offset(cx + r * 0.35, cy + r * 0.75), cryoPipe);

        // Baro-gauge dial
        canvas.drawCircle(Offset(cx, cy + r * 0.20), r * 0.20, Paint()..color = const Color(0xFFE0F7FA));
        canvas.drawCircle(Offset(cx, cy + r * 0.20), r * 0.20, linePaint);
        canvas.drawLine(Offset(cx, cy + r * 0.20), Offset(cx + r * 0.10, cy + r * 0.10), linePaint);
        break;

      case 'sk1_cadet':
      default:
        // Central zipper line
        canvas.drawLine(Offset(cx, cy - r * 0.50), Offset(cx, cy + r * 0.85), linePaint);

        // Cadet Star badge on left chest
        final starPaint = Paint()
          ..color = const Color(0xFFFF5252)
          ..style = PaintingStyle.fill;
        _drawStar(canvas, Offset(cx - r * 0.38, cy + r * 0.10), r * 0.18, starPaint);
        break;
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    final double innerRadius = radius * 0.45;
    for (int i = 0; i < 5; i++) {
      final double outerAngle = -pi / 2 + i * (2 * pi / 5);
      final double innerAngle = outerAngle + pi / 5;
      final double x1 = center.dx + cos(outerAngle) * radius;
      final double y1 = center.dy + sin(outerAngle) * radius;
      final double x2 = center.dx + cos(innerAngle) * innerRadius;
      final double y2 = center.dy + sin(innerAngle) * innerRadius;
      if (i == 0) {
        path.moveTo(x1, y1);
      } else {
        path.lineTo(x1, y1);
      }
      path.lineTo(x2, y2);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WardrobeIconPainter oldDelegate) {
    return oldDelegate.id != id ||
        oldDelegate.type != type ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.accentColor != accentColor;
  }
}