import 'dart:math';
import 'package:flutter/material.dart';

class MapPreviewPainter extends CustomPainter {
  final String mapId;
  final String rocketId;
  final double animationTime;

  MapPreviewPainter({
    required this.mapId,
    required this.rocketId,
    required this.animationTime,
  });

  // Оптимизированные Paint объекты
  static final Paint _bgPaint = Paint();
  static final Paint _gridPaint = Paint()
    ..color = Colors.white.withOpacity(0.03)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  static final Paint _particlePaint = Paint()..style = PaintingStyle.fill;
  static final Paint _hillsPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _wallPaint = Paint()..style = PaintingStyle.fill;
  
  static final Paint _crustPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  static final Paint _crustGlow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6.0
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

  static final Paint _spikePaint = Paint()..style = PaintingStyle.fill;
  static final Paint _spikeBorder = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  static final Paint _platformPaint = Paint()
    ..color = const Color(0xFF263238)
    ..style = PaintingStyle.fill;

  static final Paint _platformBorder = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  static final Paint _platformLine = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  static final Paint _platformGlow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6.0
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

  static final Paint _cargoPaint = Paint()
    ..color = const Color(0xFF37474F)
    ..style = PaintingStyle.fill;

  static final Paint _cargoBorder = Paint()
    ..color = Colors.redAccent
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;

  static final Paint _cargoBeacon = Paint()
    ..color = Colors.redAccent
    ..style = PaintingStyle.fill;

  static final Paint _coinGlow = Paint()
    ..color = Colors.amber.withOpacity(0.35)
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

  static final Paint _coinPaint = Paint()
    ..color = Colors.amber
    ..style = PaintingStyle.fill;

  static final Paint _starPaint = Paint()
    ..color = const Color(0xFFD84315)
    ..style = PaintingStyle.fill;

  static final Paint _fuelGlow = Paint()
    ..color = Colors.orange.withOpacity(0.3)
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

  static final Paint _fuelPaint = Paint()
    ..color = Colors.amber.shade700
    ..style = PaintingStyle.fill;

  static final Paint _flamePaint = Paint()
    ..color = Colors.orangeAccent
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

  static final Paint _rocketSputnikBody = Paint()
    ..shader = const LinearGradient(
      colors: [Color(0xFF607D8B), Color(0xFF37474F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTRB(-1.5, -1.2, 1.5, 0.8));

  static final Paint _rocketSputnikBorder = Paint()
    ..color = const Color(0xFF212121)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.08;

  static final Paint _rocketSputnikLegs = Paint()
    ..color = const Color(0xFF37474F) // Colors.blueGrey.shade800
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.12;

  static final Paint _rocketCycloneBody = Paint()
    ..shader = const LinearGradient(
      colors: [Color(0xFFFBC02D), Color(0xFFF57F17)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTRB(-1.6, -1.3, 1.6, 1.0));

  static final Paint _rocketCycloneBorder = Paint()
    ..color = const Color(0xFF212121)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.09;

  static final Paint _rocketCycloneLegs = Paint()
    ..color = const Color(0xFF616161) // Colors.grey.shade700
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.16;

  static final Paint _rocketNeedleBody = Paint()
    ..shader = const LinearGradient(
      colors: [Colors.white, Color(0xFFCFD8DC)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTRB(-0.9, -1.6, 0.9, 0.9));

  static final Paint _rocketNeedleBorder = Paint()
    ..color = const Color(0xFF212121)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.07;

  static final Paint _rocketNeedleLegs = Paint()
    ..color = Colors.black54
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.08;

  static final Paint _windPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  static final Paint _gravityPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  // Переиспользуемые пути
  static final Path _starPath = Path()
    ..moveTo(0, -2)
    ..lineTo(0.5, -0.5)
    ..lineTo(2, -0.5)
    ..lineTo(0.7, 0.5)
    ..lineTo(1.2, 2)
    ..lineTo(0, 1)
    ..lineTo(-1.2, 2)
    ..lineTo(-0.7, 0.5)
    ..lineTo(-2, -0.5)
    ..lineTo(-0.5, -0.5)
    ..close();

  static final Path _rocketSputnikPath = Path()
    ..moveTo(0.0, -1.2)
    ..lineTo(1.2, -0.4)
    ..lineTo(1.5, 0.8)
    ..lineTo(-1.5, 0.8)
    ..lineTo(-1.2, -0.4)
    ..close();

  static final Path _rocketCyclonePath = Path()
    ..moveTo(0.0, -1.3)
    ..lineTo(1.4, -0.6)
    ..lineTo(1.6, 1.0)
    ..lineTo(-1.6, 1.0)
    ..lineTo(-1.4, -0.6)
    ..close();

  static final Path _rocketNeedlePath = Path()
    ..moveTo(0.0, -1.6)
    ..lineTo(0.8, -0.2)
    ..lineTo(0.9, 0.9)
    ..lineTo(-0.9, 0.9)
    ..lineTo(-0.8, -0.2)
    ..close();

  final Path _hillsPath1 = Path();
  final Path _hillsPath2 = Path();
  final Path _ceilingPath = Path();
  final Path _floorPath = Path();
  final Path _ceilingCrustPath = Path();
  final Path _floorCrustPath = Path();
  final Path _spikePathTemp = Path();

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    
    // 1. Рисуем космический / пещерный фон с радиальным градиентом
    if (mapId == 'wind') {
      _bgPaint.shader = const RadialGradient(
        colors: [Color(0xFF2C241E), Color(0xFF0F0E13)],
        center: Alignment.center,
        radius: 1.2,
      ).createShader(rect);
    } else if (mapId == 'core') {
      _bgPaint.shader = const RadialGradient(
        colors: [Color(0xFF2E1515), Color(0xFF0A0A0C)],
        center: Alignment.center,
        radius: 1.2,
      ).createShader(rect);
    } else {
      _bgPaint.shader = const RadialGradient(
        colors: [Color(0xFF1B1B3A), Color(0xFF0C0C14)],
        center: Alignment.center,
        radius: 1.2,
      ).createShader(rect);
    }
    canvas.drawRect(rect, _bgPaint);

    // 2. Рисуем сетку киберпространства
    const double gridSize = 30.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), _gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _gridPaint);
    }

    // 3. Рисуем космическую пыль
    final r = Random(4321);
    for (int i = 0; i < 20; i++) {
      final double px = (r.nextDouble() * size.width + (animationTime * 15 * (i % 2 == 0 ? 1 : -1))) % size.width;
      final double py = r.nextDouble() * size.height;
      final double pSize = 1.5 + r.nextDouble() * 2.0;
      
      if (mapId == 'wind') {
        _particlePaint.color = Colors.orangeAccent.withOpacity(0.12 + 0.08 * sin(animationTime + i));
      } else if (mapId == 'core') {
        _particlePaint.color = Colors.redAccent.withOpacity(0.15 + 0.1 * sin(animationTime * 2 + i));
      } else {
        _particlePaint.color = Colors.cyanAccent.withOpacity(0.15 + 0.1 * sin(animationTime + i));
      }
      
      canvas.drawCircle(Offset(px, py), pSize, _particlePaint);
    }

    // 4. Отрисовка дальних гор (Параллакс)
    if (mapId == 'core') {
      _hillsPaint.color = const Color(0xFF1B1111);
    } else if (mapId == 'wind') {
      _hillsPaint.color = const Color(0xFF1E1712);
    } else {
      _hillsPaint.color = const Color(0xFF12121E);
    }

    _hillsPath1.reset();
    _hillsPath1
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.72)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.58 + sin(animationTime * 0.2) * 5, size.width * 0.5, size.height * 0.76)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.88, size.width, size.height * 0.68)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(_hillsPath1, _hillsPaint);

    final hillsPaint2Color = _hillsPaint.color.withOpacity(0.5);
    final hillsPaint2 = Paint()..color = hillsPaint2Color;
    _hillsPath2.reset();
    _hillsPath2
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.82)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.68 - cos(animationTime * 0.2) * 5, size.width * 0.6, size.height * 0.86)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.78, size.width, size.height * 0.92)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(_hillsPath2, hillsPaint2);

    // 5. Отрисовка геометрии пещеры (потолок и пол)
    Color neonCrustColor = const Color(0xFF00E676); // Зеленый для Эхо
    
    if (mapId == 'core') {
      neonCrustColor = const Color(0xFFFF1744); // Ярко-красный
      _wallPaint.shader = const LinearGradient(
        colors: [Color(0xFF281313), Color(0xFF0F0707)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    } else if (mapId == 'wind') {
      neonCrustColor = const Color(0xFFFFB300); // Оранжевый/Янтарный
      _wallPaint.shader = const LinearGradient(
        colors: [Color(0xFF2E2018), Color(0xFF100B08)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    } else {
      neonCrustColor = const Color(0xFF00E676); // Зеленый
      _wallPaint.shader = const LinearGradient(
        colors: [Color(0xFF1D262F), Color(0xFF0E1318)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    }

    _ceilingPath.reset();
    _ceilingPath
      ..moveTo(0, 0)
      ..lineTo(0, size.height * 0.22)
      ..lineTo(size.width * 0.1, size.height * 0.1)
      ..lineTo(size.width * 0.2, size.height * 0.28)
      ..lineTo(size.width * 0.3, size.height * 0.14)
      ..lineTo(size.width * 0.45, size.height * 0.3)
      ..lineTo(size.width * 0.6, size.height * 0.1)
      ..lineTo(size.width * 0.75, size.height * 0.26)
      ..lineTo(size.width * 0.9, size.height * 0.1)
      ..lineTo(size.width, size.height * 0.2)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(_ceilingPath, _wallPaint);

    _floorPath.reset();
    _floorPath
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.92)
      ..lineTo(size.width * 0.12, size.height * 0.88)
      ..lineTo(size.width * 0.18, size.height * 0.86)
      ..lineTo(size.width * 0.32, size.height * 0.86)
      ..lineTo(size.width * 0.38, size.height * 0.9)
      ..lineTo(size.width * 0.44, size.height * 0.8)
      ..lineTo(size.width * 0.56, size.height * 0.8)
      ..lineTo(size.width * 0.62, size.height * 0.92)
      ..lineTo(size.width * 0.74, size.height * 0.83)
      ..lineTo(size.width * 0.86, size.height * 0.83)
      ..lineTo(size.width * 0.92, size.height * 0.94)
      ..lineTo(size.width, size.height * 0.92)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(_floorPath, _wallPaint);

    // 6. Отрисовка светящейся неоновой корки на стенах
    _crustPaint.color = neonCrustColor;
    _crustGlow.color = neonCrustColor.withOpacity(0.3);

    _ceilingCrustPath.reset();
    _ceilingCrustPath
      ..moveTo(0, size.height * 0.22)
      ..lineTo(size.width * 0.1, size.height * 0.1)
      ..lineTo(size.width * 0.2, size.height * 0.28)
      ..lineTo(size.width * 0.3, size.height * 0.14)
      ..lineTo(size.width * 0.45, size.height * 0.3)
      ..lineTo(size.width * 0.6, size.height * 0.1)
      ..lineTo(size.width * 0.75, size.height * 0.26)
      ..lineTo(size.width * 0.9, size.height * 0.1)
      ..lineTo(size.width, size.height * 0.2);

    canvas.drawPath(_ceilingCrustPath, _crustGlow);
    canvas.drawPath(_ceilingCrustPath, _crustPaint);

    _floorCrustPath.reset();
    _floorCrustPath
      ..moveTo(0, size.height * 0.92)
      ..lineTo(size.width * 0.12, size.height * 0.88)
      ..lineTo(size.width * 0.18, size.height * 0.86)
      ..lineTo(size.width * 0.32, size.height * 0.86)
      ..lineTo(size.width * 0.38, size.height * 0.9)
      ..lineTo(size.width * 0.44, size.height * 0.8)
      ..lineTo(size.width * 0.56, size.height * 0.8)
      ..lineTo(size.width * 0.62, size.height * 0.92)
      ..lineTo(size.width * 0.74, size.height * 0.83)
      ..lineTo(size.width * 0.86, size.height * 0.83)
      ..lineTo(size.width * 0.92, size.height * 0.94)
      ..lineTo(size.width, size.height * 0.92);

    canvas.drawPath(_floorCrustPath, _crustGlow);
    canvas.drawPath(_floorCrustPath, _crustPaint);

    // 7. Отрисовка шипов
    _spikeBorder.color = neonCrustColor.withOpacity(0.5);
    if (mapId == 'core') {
      _spikePaint.color = const Color(0xFF381A1A);
    } else if (mapId == 'wind') {
      _spikePaint.color = const Color(0xFF3C2C22);
    } else {
      _spikePaint.color = const Color(0xFF26333D);
    }

    final List<Offset> stalactites = [
      Offset(size.width * 0.15, size.height * 0.18),
      Offset(size.width * 0.68, size.height * 0.16),
    ];
    for (final st in stalactites) {
      _spikePathTemp.reset();
      _spikePathTemp
        ..moveTo(st.dx - 12, st.dy - 10)
        ..lineTo(st.dx + 12, st.dy - 10)
        ..lineTo(st.dx, st.dy + 25)
        ..close();
      canvas.drawPath(_spikePathTemp, _spikePaint);
      canvas.drawPath(_spikePathTemp, _spikeBorder);
    }

    final List<Offset> stalagmites = [
      Offset(size.width * 0.35, size.height * 0.88),
      Offset(size.width * 0.68, size.height * 0.91),
    ];
    for (final sm in stalagmites) {
      _spikePathTemp.reset();
      _spikePathTemp
        ..moveTo(sm.dx - 12, sm.dy + 10)
        ..lineTo(sm.dx + 12, sm.dy + 10)
        ..lineTo(sm.dx, sm.dy - 25)
        ..close();
      canvas.drawPath(_spikePathTemp, _spikePaint);
      canvas.drawPath(_spikePathTemp, _spikeBorder);
    }

    // 8. Отрисовка трех индустриальных платформ
    _drawPreviewPlatform(canvas, size, size.width * 0.18, size.width * 0.32, size.height * 0.86, Colors.blueAccent);
    _drawPreviewPlatform(canvas, size, size.width * 0.44, size.width * 0.56, size.height * 0.8, Colors.greenAccent);
    _drawPreviewPlatform(canvas, size, size.width * 0.74, size.width * 0.86, size.height * 0.83, Colors.orangeAccent);

    // 9. Отрисовка Грузового Контейнера
    _drawPreviewCargo(canvas, Offset(size.width * 0.5, size.height * 0.8 - 14));

    // 10. Отрисовка Подбираемых предметов
    _drawPreviewCoin(canvas, Offset(size.width * 0.38, size.height * 0.5), animationTime);
    _drawPreviewFuel(canvas, Offset(size.width * 0.65, size.height * 0.6));

    // 11. Отрисовка Ракеты
    final double hoverOffset = sin(animationTime * 2) * 2.5 - 2.5;
    canvas.save();
    canvas.translate(size.width * 0.25, size.height * 0.86 - 22 + hoverOffset);
    
    canvas.drawCircle(const Offset(-8, 14), 4 + sin(animationTime * 10) * 1.5, _flamePaint);
    canvas.drawCircle(const Offset(8, 14), 4 + sin(animationTime * 10) * 1.5, _flamePaint);

    final double rocketScale = 22.0 / 3.4;
    canvas.scale(rocketScale, rocketScale);
    _drawRocket(canvas, rocketId);
    canvas.restore();

    // 12. Рисуем анимацию Ветра или Гравитации
    if (mapId == 'wind') {
      _windPaint.color = Colors.white.withOpacity(0.18);
      final double phase = (animationTime * 30) % size.width;
      for (double y = size.height * 0.35; y < size.height * 0.75; y += 45) {
        final double xStart = (size.width - phase + (y * 2.5)) % size.width;
        canvas.drawLine(Offset(xStart, y), Offset(xStart + 50, y), _windPaint);
        canvas.drawArc(
          Rect.fromLTWH(xStart + 45, y - 5, 10, 10),
          0,
          pi,
          false,
          _windPaint,
        );
      }
    }

    if (mapId == 'core') {
      _gravityPaint.color = Colors.redAccent.withOpacity(0.25 + 0.15 * sin(animationTime * 5.0).abs());
      for (double x = size.width * 0.32; x < size.width * 0.95; x += 60) {
        final double yStart = size.height * 0.35 + (x % 50);
        canvas.drawLine(Offset(x, yStart), Offset(x, yStart + 25), _gravityPaint);
        canvas.drawLine(Offset(x, yStart + 25), Offset(x - 4, yStart + 20), _gravityPaint);
        canvas.drawLine(Offset(x, yStart + 25), Offset(x + 4, yStart + 20), _gravityPaint);
      }
    }

    // 13. Виньетка по краям превью
    final vignetteShader = RadialGradient(
      colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
      stops: const [0.75, 1.0],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = vignetteShader);
  }

  void _drawPreviewPlatform(Canvas canvas, Size size, double xStart, double xEnd, double y, Color neonColor) {
    _platformLine.color = neonColor;
    _platformGlow.color = neonColor.withOpacity(0.35);

    final rect = Rect.fromLTRB(xStart, y, xEnd, y + 8);
    canvas.drawRect(rect, _platformPaint);
    canvas.drawRect(rect, _platformBorder);
    
    canvas.drawLine(Offset(xStart, y), Offset(xEnd, y), _platformGlow);
    canvas.drawLine(Offset(xStart, y), Offset(xEnd, y), _platformLine);
  }

  void _drawPreviewCargo(Canvas canvas, Offset pos) {
    final rect = Rect.fromCenter(center: pos, width: 14, height: 18);
    canvas.drawRect(rect, _cargoPaint);
    canvas.drawRect(rect, _cargoBorder);
    canvas.drawCircle(Offset(pos.dx, pos.dy - 2), 2.5, _cargoBeacon);
  }

  void _drawPreviewCoin(Canvas canvas, Offset pos, double animTime) {
    final scale = sin(animTime * 3.5).abs();
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.drawCircle(Offset.zero, 7, _coinGlow);

    canvas.scale(scale, 1.0);
    canvas.drawCircle(Offset.zero, 4.5, _coinPaint);
    canvas.drawPath(_starPath, _starPaint);
    canvas.restore();
  }

  void _drawPreviewFuel(Canvas canvas, Offset pos) {
    canvas.drawCircle(pos, 8, _fuelGlow);
    final rect = Rect.fromCenter(center: pos, width: 8, height: 10);
    canvas.drawRect(rect, _fuelPaint);
  }

  void _drawRocket(Canvas canvas, String rId) {
    if (rId == 'sputnik') {
      canvas.drawPath(_rocketSputnikPath, _rocketSputnikBody);
      canvas.drawPath(_rocketSputnikPath, _rocketSputnikBorder);
      canvas.drawLine(const Offset(-1.1, 0.8), const Offset(-1.4, 1.2), _rocketSputnikLegs);
      canvas.drawLine(const Offset(1.1, 0.8), const Offset(1.4, 1.2), _rocketSputnikLegs);
    } else if (rId == 'cyclone') {
      canvas.drawPath(_rocketCyclonePath, _rocketCycloneBody);
      canvas.drawPath(_rocketCyclonePath, _rocketCycloneBorder);
      canvas.drawLine(const Offset(-1.4, 1.0), const Offset(-1.8, 1.4), _rocketCycloneLegs);
      canvas.drawLine(const Offset(1.4, 1.0), const Offset(1.8, 1.4), _rocketCycloneLegs);
    } else {
      canvas.drawPath(_rocketNeedlePath, _rocketNeedleBody);
      canvas.drawPath(_rocketNeedlePath, _rocketNeedleBorder);
      canvas.drawLine(const Offset(-0.8, 0.9), const Offset(-1.1, 1.2), _rocketNeedleLegs);
      canvas.drawLine(const Offset(0.8, 0.9), const Offset(1.1, 1.2), _rocketNeedleLegs);
    }
  }

  @override
  bool shouldRepaint(covariant MapPreviewPainter oldDelegate) {
    return oldDelegate.mapId != mapId ||
        oldDelegate.rocketId != rocketId ||
        oldDelegate.animationTime != animationTime;
  }
}
