import 'dart:math';
import 'package:flutter/material.dart';

class RocketPainter extends CustomPainter {
  final String rocketId;
  final double animationTime;

  // Оптимизированные Paint объекты
  static final Paint _sputnikBodyPaint = Paint()
    ..shader = const LinearGradient(
      colors: [Color(0xFF607D8B), Color(0xFF37474F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTRB(-1.5, -1.2, 1.5, 0.8));

  static final Paint _sputnikBorderPaint = Paint()
    ..color = const Color(0xFF121214)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.11;

  static final Paint _rivetPaint = Paint()..color = Colors.white30;

  static final Paint _sputnikOutlinePaint = Paint()
    ..color = const Color(0xFF121214)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.16
    ..strokeCap = StrokeCap.round;

  static final Paint _sputnikCylinderPaint = Paint()
    ..color = const Color(0xFF37474F) // Colors.blueGrey.shade800
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.12
    ..strokeCap = StrokeCap.round;

  static final Paint _sputnikPistonPaint = Paint()
    ..color = const Color(0xFFB0BEC5) // Colors.grey.shade400
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.06
    ..strokeCap = StrokeCap.round;

  static final Paint _sputnikFeetPaint = Paint()..color = const Color(0xFF121214);

  static final Paint _cycloneBodyPaint = Paint()
    ..shader = const LinearGradient(
      colors: [Color(0xFFFBC02D), Color(0xFFF57F17)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTRB(-1.6, -1.3, 1.6, 1.0));

  static final Paint _cycloneBorderPaint = Paint()
    ..color = const Color(0xFF121214)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.11;

  static final Paint _cycloneStripePaint = Paint()
    ..color = Colors.black.withOpacity(0.8)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.15;

  static final Paint _cycloneNozzlePaint = Paint()..color = const Color(0xFF424242); // Colors.grey.shade800;

  static final Paint _cycloneLegOutline = Paint()
    ..color = const Color(0xFF121214)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.22
    ..strokeCap = StrokeCap.round;

  static final Paint _cycloneCylinderPaint = Paint()
    ..color = const Color(0xFF616161) // Colors.grey.shade700
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.16
    ..strokeCap = StrokeCap.round;

  static final Paint _cyclonePistonPaint = Paint()
    ..color = const Color(0xFFF57F17) // Colors.yellow.shade800
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.08
    ..strokeCap = StrokeCap.round;

  static final Paint _cycloneFeetPaint = Paint()..color = const Color(0xFF121214);

  static final Paint _needleBodyPaint = Paint()
    ..shader = const LinearGradient(
      colors: [Colors.white, Color(0xFFCFD8DC)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTRB(-0.9, -1.6, 0.9, 0.9));

  static final Paint _needleRedPaint = Paint()
    ..shader = const LinearGradient(
      colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTRB(-0.9, -1.6, 0.9, 0.9));

  static final Paint _needleBorderPaint = Paint()
    ..color = const Color(0xFF121214)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.09;

  static final Paint _needleOutlinePaint = Paint()
    ..color = const Color(0xFF121214)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.14
    ..strokeCap = StrokeCap.round;

  static final Paint _needleLegsPaint = Paint()
    ..color = Colors.black54
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.08;

  static final Paint _needleSkiOutline = Paint()
    ..color = const Color(0xFF121214)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.14;

  static final Paint _needleFeetPaint = Paint()..color = const Color(0xFFB71C1C);

  static final Paint _pilotBgPaint = Paint()..color = const Color(0xFF1E282D);
  static final Paint _pilotSuitPaint = Paint()..color = Colors.deepOrangeAccent;
  static final Paint _pilotHelmetPaint = Paint()..color = Colors.white;
  static final Paint _pilotVisorPaint = Paint()..color = const Color(0xFF102027);
  static final Paint _pilotEyePaint = Paint()..color = Colors.white;
  static final Paint _pilotPupilPaint = Paint()..color = Colors.black;

  static final Paint _glassPaint = Paint()
    ..color = Colors.cyan.withOpacity(0.35)
    ..style = PaintingStyle.fill;

  static final Paint _glassBorder = Paint()
    ..color = Colors.white30
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.05;

  static final Paint _glassHighlightPaint = Paint()..color = Colors.white.withOpacity(0.35);

  // Переиспользуемые пути
  static final Path _sputnikPath = Path()
    ..moveTo(0.0, -1.2)
    ..lineTo(1.2, -0.4)
    ..lineTo(1.5, 0.8)
    ..lineTo(-1.5, 0.8)
    ..lineTo(-1.2, -0.4)
    ..close();

  static final Path _cyclonePath = Path()
    ..moveTo(0.0, -1.3)
    ..lineTo(1.4, -0.6)
    ..lineTo(1.6, 1.0)
    ..lineTo(-1.6, 1.0)
    ..lineTo(-1.4, -0.6)
    ..close();

  static final Path _needlePath = Path()
    ..moveTo(0.0, -1.6)
    ..lineTo(0.8, -0.2)
    ..lineTo(0.9, 0.9)
    ..lineTo(-0.9, 0.9)
    ..lineTo(-0.8, -0.2)
    ..close();

  static final Path _needleNosePath = Path()
    ..moveTo(0.0, -1.6)
    ..lineTo(0.4, -0.9)
    ..lineTo(-0.4, -0.9)
    ..close();

  RocketPainter({required this.rocketId, this.animationTime = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    final double scale = min(size.width, size.height) / 2.0;
    canvas.scale(scale, scale);

    if (animationTime > 0) {
      canvas.translate(0, sin(animationTime) * 0.06);
    }

    if (rocketId == 'cyclone') {
      _renderCyclone(canvas);
    } else if (rocketId == 'needle') {
      _renderNeedle(canvas);
    } else {
      _renderSputnik(canvas);
    }

    canvas.restore();
  }

  void _renderSputnik(Canvas canvas) {
    canvas.drawPath(_sputnikPath, _sputnikBodyPaint);
    canvas.drawPath(_sputnikPath, _sputnikBorderPaint);

    canvas.drawCircle(const Offset(-0.8, -0.3), 0.06, _rivetPaint);
    canvas.drawCircle(const Offset(0.8, -0.3), 0.06, _rivetPaint);
    canvas.drawCircle(const Offset(-1.1, 0.5), 0.06, _rivetPaint);
    canvas.drawCircle(const Offset(1.1, 0.5), 0.06, _rivetPaint);

    _renderPilot(canvas, const Offset(0.0, -0.15), 0.5);

    // Ноги без сжатия в меню (legsCompression = 0.0)
    canvas.drawLine(const Offset(-1.1, 0.8), const Offset(-1.4, 1.2), _sputnikOutlinePaint);
    canvas.drawLine(const Offset(-1.1, 0.8), const Offset(-1.25, 1.0), _sputnikCylinderPaint);
    canvas.drawLine(const Offset(-1.25, 1.0), const Offset(-1.4, 1.2), _sputnikPistonPaint);

    canvas.drawLine(const Offset(1.1, 0.8), const Offset(1.4, 1.2), _sputnikOutlinePaint);
    canvas.drawLine(const Offset(1.1, 0.8), const Offset(1.25, 1.0), _sputnikCylinderPaint);
    canvas.drawLine(const Offset(1.25, 1.0), const Offset(1.4, 1.2), _sputnikPistonPaint);

    canvas.drawRect(Rect.fromCenter(center: const Offset(-1.4, 1.2), width: 0.4, height: 0.12), _sputnikFeetPaint);
    canvas.drawRect(Rect.fromCenter(center: const Offset(1.4, 1.2), width: 0.4, height: 0.12), _sputnikFeetPaint);
  }

  void _renderCyclone(Canvas canvas) {
    canvas.drawPath(_cyclonePath, _cycloneBodyPaint);
    canvas.drawPath(_cyclonePath, _cycloneBorderPaint);

    canvas.drawLine(const Offset(-1.1, 0.8), const Offset(-0.7, 0.4), _cycloneStripePaint);
    canvas.drawLine(const Offset(1.1, 0.8), const Offset(0.7, 0.4), _cycloneStripePaint);

    _renderPilot(canvas, const Offset(0.0, 0.0), 0.65);

    canvas.drawRect(Rect.fromCenter(center: const Offset(-1.3, 1.15), width: 0.5, height: 0.3), _cycloneNozzlePaint);
    canvas.drawRect(Rect.fromCenter(center: const Offset(1.3, 1.15), width: 0.5, height: 0.3), _cycloneNozzlePaint);

    canvas.drawLine(const Offset(-1.4, 1.0), const Offset(-1.8, 1.4), _cycloneLegOutline);
    canvas.drawLine(const Offset(-1.4, 1.0), const Offset(-1.6, 1.2), _cycloneCylinderPaint);
    canvas.drawLine(const Offset(-1.6, 1.2), const Offset(-1.8, 1.4), _cyclonePistonPaint);

    canvas.drawLine(const Offset(1.4, 1.0), const Offset(1.8, 1.4), _cycloneLegOutline);
    canvas.drawLine(const Offset(1.4, 1.0), const Offset(1.6, 1.2), _cycloneCylinderPaint);
    canvas.drawLine(const Offset(1.6, 1.2), const Offset(1.8, 1.4), _cyclonePistonPaint);

    canvas.drawRect(Rect.fromCenter(center: const Offset(-1.8, 1.4), width: 0.65, height: 0.18), _cycloneFeetPaint);
    canvas.drawRect(Rect.fromCenter(center: const Offset(1.8, 1.4), width: 0.65, height: 0.18), _cycloneFeetPaint);
  }

  void _renderNeedle(Canvas canvas) {
    canvas.drawPath(_needlePath, _needleBodyPaint);

    canvas.drawPath(_needleNosePath, _needleRedPaint);
    canvas.drawPath(_needleNosePath, _needleBorderPaint);

    canvas.drawPath(_needlePath, _needleBorderPaint);

    _renderPilot(canvas, const Offset(0.0, -0.25), 0.4);

    canvas.drawLine(const Offset(-0.8, 0.9), const Offset(-1.1, 1.2), _needleOutlinePaint);
    canvas.drawLine(const Offset(-0.8, 0.9), const Offset(-1.1, 1.2), _needleLegsPaint);

    canvas.drawLine(const Offset(0.8, 0.9), const Offset(1.1, 1.2), _needleOutlinePaint);
    canvas.drawLine(const Offset(0.8, 0.9), const Offset(1.1, 1.2), _needleLegsPaint);

    canvas.drawOval(Rect.fromCenter(center: const Offset(-1.1, 1.2), width: 0.5, height: 0.08), _needleSkiOutline);
    canvas.drawOval(Rect.fromCenter(center: const Offset(-1.1, 1.2), width: 0.5, height: 0.08), _needleFeetPaint);

    canvas.drawOval(Rect.fromCenter(center: const Offset(1.1, 1.2), width: 0.5, height: 0.08), _needleSkiOutline);
    canvas.drawOval(Rect.fromCenter(center: const Offset(1.1, 1.2), width: 0.5, height: 0.08), _needleFeetPaint);
  }

  void _renderPilot(Canvas canvas, Offset cabinCenter, double radius) {
    canvas.drawCircle(cabinCenter, radius, _pilotBgPaint);

    final headPos = cabinCenter + const Offset(0.0, 0.05);

    canvas.drawOval(Rect.fromCenter(center: Offset(cabinCenter.dx, cabinCenter.dy + radius * 0.6), width: radius * 1.3, height: radius * 0.7), _pilotSuitPaint);
    canvas.drawCircle(headPos, radius * 0.42, _pilotHelmetPaint);
    canvas.drawCircle(headPos + const Offset(0.0, -0.02), radius * 0.28, _pilotVisorPaint);

    const double eyeSize = 0.025;
    canvas.drawCircle(headPos + Offset(-radius * 0.09, -radius * 0.02), eyeSize, _pilotEyePaint);
    canvas.drawCircle(headPos + Offset(-radius * 0.09, -radius * 0.02), eyeSize * 0.5, _pilotPupilPaint);

    canvas.drawCircle(headPos + Offset(radius * 0.09, -radius * 0.02), eyeSize, _pilotEyePaint);
    canvas.drawCircle(headPos + Offset(radius * 0.09, -radius * 0.02), eyeSize * 0.5, _pilotPupilPaint);

    canvas.drawCircle(cabinCenter, radius, _glassPaint);
    canvas.drawCircle(cabinCenter, radius, _glassBorder);

    canvas.drawOval(
      Rect.fromLTWH(
        cabinCenter.dx - radius * 0.6,
        cabinCenter.dy - radius * 0.7,
        radius * 0.6,
        radius * 0.35,
      ),
      _glassHighlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
