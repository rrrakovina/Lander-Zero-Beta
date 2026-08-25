import 'dart:math';
import 'package:flutter/material.dart';
import 'ship_mesh_renderer.dart';

class MapPreviewPainter extends CustomPainter {
  final String mapId;
  final String rocketId;
  final double animationTime;

  MapPreviewPainter({
    required this.mapId,
    required this.rocketId,
    required this.animationTime,
  });

  // Cached Paint objects
  static final Paint _bgPaint = Paint();
  static final Paint _gridPaint = Paint()
    ..color = Colors.white.withOpacity(0.04)
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

  static final Paint _effectPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  static final Paint _hologramPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;

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

    // 1. Background Gradient per Biome
    if (mapId == 'ice') {
      _bgPaint.shader = const RadialGradient(
        colors: [Color(0xFF132B3A), Color(0xFF08121A)],
        center: Alignment.center,
        radius: 1.2,
      ).createShader(rect);
    } else if (mapId == 'orbit') {
      _bgPaint.shader = const RadialGradient(
        colors: [Color(0xFF231435), Color(0xFF08060F)],
        center: Alignment.center,
        radius: 1.2,
      ).createShader(rect);
    } else if (mapId == 'endless') {
      _bgPaint.shader = const RadialGradient(
        colors: [Color(0xFF2A2312), Color(0xFF0D0B06)],
        center: Alignment.center,
        radius: 1.2,
      ).createShader(rect);
    } else if (mapId == 'wind') {
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

    // 2. Cyber Grid
    const double gridSize = 30.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), _gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _gridPaint);
    }

    // 3. 3D Holographic Rotating Planetary Sphere in Top-Right
    _draw3DHolographicPlanet(canvas, Offset(size.width * 0.78, size.height * 0.28), 45.0, mapId, animationTime);

    // 4. Biome-specific Atmospheric Particles
    final r = Random(4321);
    for (int i = 0; i < 24; i++) {
      final double px = (r.nextDouble() * size.width + (animationTime * 15 * (i % 2 == 0 ? 1 : -1))) % size.width;
      final double py = r.nextDouble() * size.height;
      final double pSize = 1.5 + r.nextDouble() * 2.5;

      if (mapId == 'ice') {
        _particlePaint.color = const Color(0xFF00E5FF).withOpacity(0.20 + 0.1 * sin(animationTime * 1.5 + i));
      } else if (mapId == 'orbit') {
        _particlePaint.color = const Color(0xFFE040FB).withOpacity(0.22 + 0.1 * sin(animationTime + i));
      } else if (mapId == 'endless') {
        _particlePaint.color = const Color(0xFFFFD700).withOpacity(0.20 + 0.1 * sin(animationTime * 2.0 + i));
      } else if (mapId == 'wind') {
        _particlePaint.color = Colors.orangeAccent.withOpacity(0.15 + 0.08 * sin(animationTime + i));
      } else if (mapId == 'core') {
        _particlePaint.color = Colors.redAccent.withOpacity(0.18 + 0.1 * sin(animationTime * 2 + i));
      } else {
        _particlePaint.color = Colors.cyanAccent.withOpacity(0.15 + 0.1 * sin(animationTime + i));
      }

      canvas.drawCircle(Offset(px, py), pSize, _particlePaint);
    }

    // 5. Parallax Hills
    if (mapId == 'ice') {
      _hillsPaint.color = const Color(0xFF0B212D);
    } else if (mapId == 'orbit') {
      _hillsPaint.color = const Color(0xFF180E24);
    } else if (mapId == 'endless') {
      _hillsPaint.color = const Color(0xFF1E1A0E);
    } else if (mapId == 'core') {
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

    final hillsPaint2 = Paint()..color = _hillsPaint.color.withOpacity(0.5);
    _hillsPath2.reset();
    _hillsPath2
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.82)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.68 - cos(animationTime * 0.2) * 5, size.width * 0.6, size.height * 0.86)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.78, size.width, size.height * 0.92)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(_hillsPath2, hillsPaint2);

    // 6. Cave Geometry (Floor & Ceiling)
    Color neonCrustColor = const Color(0xFF00E676);

    if (mapId == 'ice') {
      neonCrustColor = const Color(0xFF00E5FF);
      _wallPaint.shader = const LinearGradient(
        colors: [Color(0xFF0E2533), Color(0xFF051017)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    } else if (mapId == 'orbit') {
      neonCrustColor = const Color(0xFFE040FB);
      _wallPaint.shader = const LinearGradient(
        colors: [Color(0xFF221133), Color(0xFF09040F)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    } else if (mapId == 'endless') {
      neonCrustColor = const Color(0xFFFFD700);
      _wallPaint.shader = const LinearGradient(
        colors: [Color(0xFF2B210F), Color(0xFF0E0B05)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    } else if (mapId == 'core') {
      neonCrustColor = const Color(0xFFFF1744);
      _wallPaint.shader = const LinearGradient(
        colors: [Color(0xFF281313), Color(0xFF0F0707)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    } else if (mapId == 'wind') {
      neonCrustColor = const Color(0xFFFFB300);
      _wallPaint.shader = const LinearGradient(
        colors: [Color(0xFF2E2018), Color(0xFF100B08)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    } else {
      neonCrustColor = const Color(0xFF00E676);
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

    // 7. Glowing Neon Crust
    _crustPaint.color = neonCrustColor;
    _crustGlow.color = neonCrustColor.withOpacity(0.35);

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

    // 8. Stalactites & Stalagmites
    _spikeBorder.color = neonCrustColor.withOpacity(0.5);
    _spikePaint.color = neonCrustColor.withOpacity(0.2);

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

    // 9. Platforms
    _drawPreviewPlatform(canvas, size, size.width * 0.18, size.width * 0.32, size.height * 0.86, Colors.blueAccent);
    _drawPreviewPlatform(canvas, size, size.width * 0.44, size.width * 0.56, size.height * 0.8, Colors.greenAccent);
    _drawPreviewPlatform(canvas, size, size.width * 0.74, size.width * 0.86, size.height * 0.83, Colors.orangeAccent);

    // 10. Cargo Capsule
    _drawPreviewCargo(canvas, Offset(size.width * 0.5, size.height * 0.8 - 14));

    // 11. Pickups (Coin & Fuel)
    _drawPreviewCoin(canvas, Offset(size.width * 0.38, size.height * 0.5), animationTime);
    _drawPreviewFuel(canvas, Offset(size.width * 0.65, size.height * 0.6));

    // 12. Rocket
    final double hoverOffset = sin(animationTime * 2) * 2.5 - 2.5;
    canvas.save();
    canvas.translate(size.width * 0.25, size.height * 0.86 - 22 + hoverOffset);

    canvas.drawCircle(const Offset(-8, 14), 4 + sin(animationTime * 10) * 1.5, _flamePaint);
    canvas.drawCircle(const Offset(8, 14), 4 + sin(animationTime * 10) * 1.5, _flamePaint);

    final double rocketScale = 22.0 / 3.4;
    canvas.scale(rocketScale, rocketScale);
    _drawRocket(canvas, rocketId);
    canvas.restore();

    // 13. Dynamic Biome Visual Effects
    if (mapId == 'wind') {
      _effectPaint.color = Colors.white.withOpacity(0.18);
      final double phase = (animationTime * 30) % size.width;
      for (double y = size.height * 0.35; y < size.height * 0.75; y += 45) {
        final double xStart = (size.width - phase + (y * 2.5)) % size.width;
        canvas.drawLine(Offset(xStart, y), Offset(xStart + 50, y), _effectPaint);
        canvas.drawArc(
          Rect.fromLTWH(xStart + 45, y - 5, 10, 10),
          0,
          pi,
          false,
          _effectPaint,
        );
      }
    } else if (mapId == 'core') {
      _effectPaint.color = Colors.redAccent.withOpacity(0.25 + 0.15 * sin(animationTime * 5.0).abs());
      for (double x = size.width * 0.32; x < size.width * 0.95; x += 60) {
        final double yStart = size.height * 0.35 + (x % 50);
        canvas.drawLine(Offset(x, yStart), Offset(x, yStart + 25), _effectPaint);
        canvas.drawLine(Offset(x, yStart + 25), Offset(x - 4, yStart + 20), _effectPaint);
        canvas.drawLine(Offset(x, yStart + 25), Offset(x + 4, yStart + 20), _effectPaint);
      }
    } else if (mapId == 'ice') {
      // Cryo Geyser Steam Jet
      final geyserPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            const Color(0xFF00E5FF).withOpacity(0.4),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(size.width * 0.62, size.height * 0.45, 20, 90));
      canvas.drawRect(Rect.fromLTWH(size.width * 0.62, size.height * 0.45, 20, 90), geyserPaint);
    }

    // 14. CRT Holographic Scanline Overlay
    final scanlinePaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..strokeWidth = 1.0;
    for (double y = 0; y < size.height; y += 4.0) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanlinePaint);
    }

    // 15. Vignette
    final vignetteShader = RadialGradient(
      colors: [Colors.transparent, Colors.black.withOpacity(0.65)],
      stops: const [0.75, 1.0],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = vignetteShader);
  }

  void _draw3DHolographicPlanet(Canvas canvas, Offset center, double radius, String mapId, double time) {
    Color planetColor;
    switch (mapId) {
      case 'ice':
        planetColor = const Color(0xFF00E5FF);
        break;
      case 'orbit':
        planetColor = const Color(0xFFE040FB);
        break;
      case 'endless':
        planetColor = const Color(0xFFFFD700);
        break;
      case 'core':
        planetColor = const Color(0xFFFF1744);
        break;
      case 'wind':
        planetColor = const Color(0xFFFFB300);
        break;
      case 'echo':
      default:
        planetColor = const Color(0xFF00E676);
        break;
    }

    _hologramPaint.color = planetColor.withOpacity(0.45);

    // Planet Outer Sphere & Glow
    canvas.drawCircle(center, radius, _hologramPaint);
    final glowPaint = Paint()
      ..color = planetColor.withOpacity(0.12)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
    canvas.drawCircle(center, radius, glowPaint);

    // Rotating 3D Latitude and Longitude Rings
    final double rotPhase = time * 0.8;
    for (int i = -2; i <= 2; i++) {
      final double latY = center.dy + i * (radius / 3.0);
      final double latRadius = sqrt(max(0, radius * radius - (latY - center.dy) * (latY - center.dy)));
      if (latRadius > 0) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(center.dx, latY), width: latRadius * 2, height: latRadius * 0.4),
          _hologramPaint,
        );
      }
    }

    // Longitude Meridian Ellipses
    for (double deg = 0; deg < pi; deg += pi / 3) {
      final double widthFactor = cos(deg + rotPhase).abs();
      canvas.drawOval(
        Rect.fromCenter(center: center, width: radius * 2 * widthFactor, height: radius * 2),
        _hologramPaint,
      );
    }

    // Outer Orbit Ring for Orbit / Endless biomes
    if (mapId == 'orbit' || mapId == 'ice') {
      final ringPaint = Paint()
        ..color = planetColor.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawOval(
        Rect.fromCenter(center: center, width: radius * 2.8, height: radius * 0.8),
        ringPaint,
      );
    }
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
    ShipMeshRenderer.renderShip(
      canvas: canvas,
      shipId: rId,
      showLandingGear: true,
      animationTime: animationTime,
      showDecals: true,
    );
  }

  @override
  bool shouldRepaint(covariant MapPreviewPainter oldDelegate) {
    return oldDelegate.mapId != mapId ||
        oldDelegate.rocketId != rocketId ||
        oldDelegate.animationTime != animationTime;
  }
}
