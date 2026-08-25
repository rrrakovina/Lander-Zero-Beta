import 'dart:math';
import 'package:flame_forge2d/flame_forge2d.dart' show Vector2;
import 'package:flutter/material.dart';

/// Unified vector rendering engine for all 5 Lander Zero ships:
/// 1. `sputnik` («Спутник-1», USSR-01, balanced spherical capsule)
/// 2. `swift` («Стриж / Swift-02», high-speed interceptor)
/// 3. `titan` («Буран-М / Titan-V», heavy armored triple-thruster ship)
/// 4. `quasar` / `needle` («Квазар / Quasar-IX», high-tech ion RCS vessel)
/// 5. `cyclone` («Циклон-CY88», industrial heavy multi-nozzle hauler)
///
/// Features crisp vector decals (`СССР-01`, `SWIFT-02`, `TITAN-V`, `QUASAR-IX`, `CY-88`, `INTERCEPTOR-07`),
/// hazard stripes, landing gear suspension, and live dynamic astronaut simulation.
class ShipMeshRenderer {
  /// Exact model bounding boxes enclosing hull, landing gear/skis/feet, nozzles, and antenna tips.
  static const Map<String, Rect> modelBounds = {
    'sputnik': Rect.fromLTRB(-1.65, -1.30, 1.65, 1.30),
    'swift': Rect.fromLTRB(-1.45, -1.70, 1.45, 1.35),
    'titan': Rect.fromLTRB(-2.20, -1.40, 2.20, 1.55),
    'quasar': Rect.fromLTRB(-1.45, -1.70, 1.45, 1.35),
    'needle': Rect.fromLTRB(-1.45, -1.70, 1.45, 1.35),
    'cyclone': Rect.fromLTRB(-2.20, -1.40, 2.20, 1.55),
  };

  /// Safety margin ensuring hover/tilt dynamics, strokes, and glows fit comfortably without clipping.
  static const double safetyMargin = 1.20;

  static Rect getModelBounds(String shipId) =>
      modelBounds[shipId] ?? modelBounds['sputnik']!;

  static Rect getBounds(String shipId) => getModelBounds(shipId);

  static Offset getCenterOffset(String shipId) => getModelBounds(shipId).center;

  static double calculateScale(String shipId, Size size, {double margin = safetyMargin}) {
    if (size.width <= 0 || size.height <= 0) return 0.0;
    final b = getModelBounds(shipId);
    final maxDim = max(b.width, b.height);
    return min(size.width, size.height) / (maxDim * margin);
  }

  // --- Optimized Cached Paint Objects ---
  static final Paint _sputnikBodyPaint = Paint()
    ..shader = const LinearGradient(
      colors: [Color(0xFF78909C), Color(0xFF37474F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTRB(-1.5, -1.2, 1.5, 0.8));

  static final Paint _sputnikBorderPaint = Paint()
    ..color = const Color(0xFF121214)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.11;

  static final Paint _sputnikCowlingPaint = Paint()
    ..shader = const LinearGradient(
      colors: [Color(0xFF90A4AE), Color(0xFF455A64)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTRB(-1.5, 0.2, 1.5, 0.8));

  static final Paint _rivetPaint = Paint()..color = Colors.white54;

  static final Paint _antennaPaint = Paint()
    ..color = const Color(0xFFB0BEC5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.04
    ..strokeCap = StrokeCap.round;

  static final Paint _antennaTipPaint = Paint()..color = const Color(0xFFE0E0E0);

  static final Paint _starPaint = Paint()
    ..color = const Color(0xFFD32F2F)
    ..style = PaintingStyle.fill;

  static final Paint _starOutlinePaint = Paint()
    ..color = Colors.white70
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.015;

  static final Paint _sputnikOutlinePaint = Paint()
    ..color = const Color(0xFF121214)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.16
    ..strokeCap = StrokeCap.round;

  static final Paint _sputnikCylinderPaint = Paint()
    ..color = const Color(0xFF37474F)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.12
    ..strokeCap = StrokeCap.round;

  static final Paint _sputnikPistonPaint = Paint()
    ..color = const Color(0xFFB0BEC5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.06
    ..strokeCap = StrokeCap.round;

  static final Paint _sputnikFeetPaint = Paint()..color = const Color(0xFF121214);

  // --- Swift Interceptor Paints ---
  static final Paint _swiftBodyPaint = Paint()
    ..shader = const LinearGradient(
      colors: [Color(0xFFECEFF1), Color(0xFF90A4AE)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTRB(-1.2, -1.7, 1.2, 0.9));

  static final Paint _swiftWingPaint = Paint()
    ..shader = const LinearGradient(
      colors: [Color(0xFF00E5FF), Color(0xFF00838F)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTRB(-1.2, -0.4, 1.2, 0.9));

  static final Paint _swiftNosePaint = Paint()
    ..shader = const LinearGradient(
      colors: [Color(0xFF00E5FF), Color(0xFF0097A7)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTRB(-0.5, -1.7, 0.5, -0.8));

  static final Paint _swiftBorderPaint = Paint()
    ..color = const Color(0xFF121214)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.09;

  static final Paint _swiftOutlinePaint = Paint()
    ..color = const Color(0xFF121214)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.13
    ..strokeCap = StrokeCap.round;

  static final Paint _swiftLegsPaint = Paint()
    ..color = const Color(0xFF37474F)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.08
    ..strokeCap = StrokeCap.round;

  static final Paint _swiftSkiOutline = Paint()
    ..color = const Color(0xFF121214)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.12;

  static final Paint _swiftFeetPaint = Paint()..color = const Color(0xFF00BCD4);

  static final Paint _swiftNozzlePaint = Paint()..color = const Color(0xFF263238);

  // --- Titan Heavy Paints ---
  static final Paint _titanBodyPaint = Paint()
    ..shader = const LinearGradient(
      colors: [Color(0xFF455A64), Color(0xFF263238)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTRB(-2.0, -1.3, 2.0, 1.2));

  static final Paint _titanArmorPlatePaint = Paint()
    ..shader = const LinearGradient(
      colors: [Color(0xFF78909C), Color(0xFF37474F)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTRB(-1.8, -0.6, 1.8, 0.9));

  static final Paint _titanBorderPaint = Paint()
    ..color = const Color(0xFF101418)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.12;

  static final Paint _hazardYellowPaint = Paint()..color = const Color(0xFFFFD600);
  static final Paint _hazardBlackPaint = Paint()
    ..color = const Color(0xFF1B1B1E)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.12;

  static final Paint _titanNozzlePaint = Paint()
    ..shader = const LinearGradient(
      colors: [Color(0xFF424242), Color(0xFF212121)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTRB(-1.5, 1.0, 1.5, 1.35));

  static final Paint _titanLegOutline = Paint()
    ..color = const Color(0xFF121214)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.24
    ..strokeCap = StrokeCap.round;

  static final Paint _titanCylinderPaint = Paint()
    ..color = const Color(0xFF546E7A)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.18
    ..strokeCap = StrokeCap.round;

  static final Paint _titanPistonPaint = Paint()
    ..color = const Color(0xFFFF8F00)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.10
    ..strokeCap = StrokeCap.round;

  static final Paint _titanFeetPaint = Paint()..color = const Color(0xFF212121);

  // --- Quasar / Needle Ion Vessel Paints ---
  static final Paint _quasarBodyPaint = Paint()
    ..shader = const LinearGradient(
      colors: [Color(0xFF283593), Color(0xFF0D1B2A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTRB(-1.3, -1.6, 1.3, 0.9));

  static final Paint _quasarFacetPaint = Paint()
    ..shader = const LinearGradient(
      colors: [Color(0xFF3F51B5), Color(0xFF1A237E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTRB(-1.0, -1.2, 1.0, 0.6));

  static final Paint _quasarBorderPaint = Paint()
    ..color = const Color(0xFF00E5FF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.08;

  static final Paint _circuitGlowPaint = Paint()
    ..color = const Color(0xFF00E5FF).withOpacity(0.7)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.035;

  static final Paint _ionRcsPaint = Paint()
    ..color = const Color(0xFF7C4DFF)
    ..style = PaintingStyle.fill;

  static final Paint _ionGlowPaint = Paint()
    ..color = const Color(0xFF00E5FF).withOpacity(0.5)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.15);

  static final Paint _quasarLegOutline = Paint()
    ..color = const Color(0xFF121214)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.14
    ..strokeCap = StrokeCap.round;

  static final Paint _quasarLegPaint = Paint()
    ..color = const Color(0xFF00E5FF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.06
    ..strokeCap = StrokeCap.round;

  static final Paint _quasarFeetPaint = Paint()..color = const Color(0xFF536DFE);

  // --- Cyclone Industrial Paints ---
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

  static final Paint _cycloneNozzlePaint = Paint()..color = const Color(0xFF424242);

  static final Paint _cycloneLegOutline = Paint()
    ..color = const Color(0xFF121214)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.22
    ..strokeCap = StrokeCap.round;

  static final Paint _cycloneCylinderPaint = Paint()
    ..color = const Color(0xFF616161)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.16
    ..strokeCap = StrokeCap.round;

  static final Paint _cyclonePistonPaint = Paint()
    ..color = const Color(0xFFF57F17)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.08
    ..strokeCap = StrokeCap.round;

  static final Paint _cycloneFeetPaint = Paint()..color = const Color(0xFF121214);

  // --- Pilot / Cockpit Shared Paints ---
  static final Paint _pilotBgPaint = Paint()..color = const Color(0xFF1E282D);
  static final Paint _pilotEyePaint = Paint()..color = Colors.white;
  static final Paint _pilotPupilPaint = Paint()..color = Colors.black;
  static final Paint _pilotBlinkPaint = Paint()
    ..color = const Color(0xFF102027)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.04
    ..strokeCap = StrokeCap.round;

  static final Paint _glassPaint = Paint()
    ..color = Colors.cyan.withOpacity(0.35)
    ..style = PaintingStyle.fill;

  static final Paint _glassBorder = Paint()
    ..color = Colors.white30
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.05;

  static final Paint _glassHighlightPaint = Paint()..color = Colors.white.withOpacity(0.35);

  // --- Reusable Path Objects ---
  static final Path _sputnikPath = Path()
    ..moveTo(0.0, -1.2)
    ..lineTo(1.2, -0.4)
    ..lineTo(1.5, 0.8)
    ..lineTo(-1.5, 0.8)
    ..lineTo(-1.2, -0.4)
    ..close();

  static final Path _sputnikCowlingPath = Path()
    ..moveTo(-1.3, 0.2)
    ..lineTo(1.3, 0.2)
    ..lineTo(1.5, 0.8)
    ..lineTo(-1.5, 0.8)
    ..close();

  static final Path _swiftPath = Path()
    ..moveTo(0.0, -1.6)
    ..lineTo(0.8, -0.2)
    ..lineTo(0.9, 0.9)
    ..lineTo(-0.9, 0.9)
    ..lineTo(-0.8, -0.2)
    ..close();

  static final Path _swiftNosePath = Path()
    ..moveTo(0.0, -1.6)
    ..lineTo(0.4, -0.9)
    ..lineTo(-0.4, -0.9)
    ..close();

  static final Path _swiftWingsPath = Path()
    ..moveTo(-0.4, -0.2)
    ..lineTo(-1.15, 0.4)
    ..lineTo(-0.8, 0.9)
    ..lineTo(0.8, 0.9)
    ..lineTo(1.15, 0.4)
    ..lineTo(0.4, -0.2)
    ..close();

  static final Path _titanPath = Path()
    ..moveTo(0.0, -1.3)
    ..lineTo(1.5, -0.5)
    ..lineTo(1.8, 1.1)
    ..lineTo(0.0, 1.2)
    ..lineTo(-1.8, 1.1)
    ..lineTo(-1.5, -0.5)
    ..close();

  static final Path _titanArmorPlatePath = Path()
    ..moveTo(0.0, -1.0)
    ..lineTo(1.2, -0.3)
    ..lineTo(1.4, 0.8)
    ..lineTo(-1.4, 0.8)
    ..lineTo(-1.2, -0.3)
    ..close();

  static final Path _quasarPath = Path()
    ..moveTo(0.0, -1.5)
    ..lineTo(1.1, -0.6)
    ..lineTo(1.3, 0.8)
    ..lineTo(0.0, 0.6)
    ..lineTo(-1.3, 0.8)
    ..lineTo(-1.1, -0.6)
    ..close();

  static final Path _cyclonePath = Path()
    ..moveTo(0.0, -1.3)
    ..lineTo(1.4, -0.6)
    ..lineTo(1.6, 1.0)
    ..lineTo(-1.6, 1.0)
    ..lineTo(-1.4, -0.6)
    ..close();

  /// Primary unified render entry point used by both [RocketPainter] and [Lander].
  static void renderShip({
    required Canvas canvas,
    required String shipId,
    double scale = 1.0,
    double engineThrust = 0.0,
    double rcsThrust = 0.0,
    Vector2? pilotHeadOffset,
    Vector2? pilotLookDirection,
    double pilotGStrain = 0.0,
    bool isPanicking = false,
    bool isBlinking = false,
    bool showLandingGear = true,
    double animationTime = 0.0,
    double legsCompression = 0.0,
    bool showDecals = true,
  }) {
    canvas.save();
    if (scale != 1.0) {
      canvas.scale(scale, scale);
    }

    final normalizedId = _normalizeShipId(shipId);

    switch (normalizedId) {
      case 'swift':
        _renderSwift(
          canvas: canvas,
          pilotHeadOffset: pilotHeadOffset,
          pilotLookDirection: pilotLookDirection,
          pilotGStrain: pilotGStrain,
          isPanicking: isPanicking,
          isBlinking: isBlinking,
          showLandingGear: showLandingGear,
          animationTime: animationTime,
          legsCompression: legsCompression,
          showDecals: showDecals,
          engineThrust: engineThrust,
        );
        break;

      case 'titan':
        _renderTitan(
          canvas: canvas,
          pilotHeadOffset: pilotHeadOffset,
          pilotLookDirection: pilotLookDirection,
          pilotGStrain: pilotGStrain,
          isPanicking: isPanicking,
          isBlinking: isBlinking,
          showLandingGear: showLandingGear,
          animationTime: animationTime,
          legsCompression: legsCompression,
          showDecals: showDecals,
          engineThrust: engineThrust,
        );
        break;

      case 'quasar':
      case 'needle':
        _renderQuasar(
          canvas: canvas,
          pilotHeadOffset: pilotHeadOffset,
          pilotLookDirection: pilotLookDirection,
          pilotGStrain: pilotGStrain,
          isPanicking: isPanicking,
          isBlinking: isBlinking,
          showLandingGear: showLandingGear,
          animationTime: animationTime,
          legsCompression: legsCompression,
          showDecals: showDecals,
          rcsThrust: rcsThrust,
        );
        break;

      case 'cyclone':
        _renderCyclone(
          canvas: canvas,
          pilotHeadOffset: pilotHeadOffset,
          pilotLookDirection: pilotLookDirection,
          pilotGStrain: pilotGStrain,
          isPanicking: isPanicking,
          isBlinking: isBlinking,
          showLandingGear: showLandingGear,
          animationTime: animationTime,
          legsCompression: legsCompression,
          showDecals: showDecals,
          engineThrust: engineThrust,
        );
        break;

      case 'sputnik':
      default:
        _renderSputnik(
          canvas: canvas,
          pilotHeadOffset: pilotHeadOffset,
          pilotLookDirection: pilotLookDirection,
          pilotGStrain: pilotGStrain,
          isPanicking: isPanicking,
          isBlinking: isBlinking,
          showLandingGear: showLandingGear,
          animationTime: animationTime,
          legsCompression: legsCompression,
          showDecals: showDecals,
        );
        break;
    }

    canvas.restore();
  }

  static String _normalizeShipId(String id) {
    if (id == 'needle') return 'needle';
    if (id == 'quasar') return 'quasar';
    if (id == 'swift') return 'swift';
    if (id == 'titan') return 'titan';
    if (id == 'cyclone') return 'cyclone';
    return 'sputnik';
  }

  // =========================================================================
  // 1. «Спутник-1» (USSR-01, Balanced Classic Capsule)
  // =========================================================================
  static void _renderSputnik({
    required Canvas canvas,
    Vector2? pilotHeadOffset,
    Vector2? pilotLookDirection,
    double pilotGStrain = 0.0,
    bool isPanicking = false,
    bool isBlinking = false,
    bool showLandingGear = true,
    double animationTime = 0.0,
    double legsCompression = 0.0,
    bool showDecals = true,
  }) {
    // 4 Stabilization Antennas (Background Layer)
    _renderAntenna(canvas, const Offset(-1.0, -0.6), const Offset(-1.55, -1.25));
    _renderAntenna(canvas, const Offset(1.0, -0.6), const Offset(1.55, -1.25));
    _renderAntenna(canvas, const Offset(-1.3, 0.2), const Offset(-1.6, -0.3));
    _renderAntenna(canvas, const Offset(1.3, 0.2), const Offset(1.6, -0.3));

    // Hull Body & Lower Cowling
    canvas.drawPath(_sputnikPath, _sputnikBodyPaint);
    canvas.drawPath(_sputnikCowlingPath, _sputnikCowlingPaint);
    canvas.drawPath(_sputnikPath, _sputnikBorderPaint);

    // Perimeter Rivets
    canvas.drawCircle(const Offset(-0.8, -0.3), 0.06, _rivetPaint);
    canvas.drawCircle(const Offset(0.8, -0.3), 0.06, _rivetPaint);
    canvas.drawCircle(const Offset(-1.1, 0.5), 0.06, _rivetPaint);
    canvas.drawCircle(const Offset(1.1, 0.5), 0.06, _rivetPaint);
    canvas.drawCircle(const Offset(0.0, 0.7), 0.05, _rivetPaint);

    // Vector Decals: "СССР-01" + Soviet Red Stars
    if (showDecals) {
      _renderVectorText(
        canvas: canvas,
        text: 'СССР-01',
        position: const Offset(0.0, -0.78),
        fontSize: 10.0,
        color: const Color(0xFFFF5252),
        isBold: true,
      );

      _renderSovietStar(canvas, const Offset(-0.85, 0.48), 0.12);
      _renderSovietStar(canvas, const Offset(0.85, 0.48), 0.12);
    }

    // Cockpit & Live Cosmonaut (Vintage Sokol-KV2 Orange Suit)
    _renderPilot(
      canvas: canvas,
      cabinCenter: const Offset(0.0, -0.15),
      radius: 0.50,
      shipId: 'sputnik',
      pilotHeadOffset: pilotHeadOffset,
      pilotLookDirection: pilotLookDirection,
      pilotGStrain: pilotGStrain,
      isPanicking: isPanicking,
      isBlinking: isBlinking,
      animationTime: animationTime,
    );

    // Landing Gear (Dual Hydraulic Struts)
    if (showLandingGear) {
      final double leftFootX = -1.4 + legsCompression * 0.4;
      final double leftFootY = 1.2 - legsCompression * 0.6;
      final double rightFootX = 1.4 - legsCompression * 0.4;
      final double rightFootY = 1.2 - legsCompression * 0.6;

      // Left Leg
      canvas.drawLine(const Offset(-1.1, 0.8), Offset(leftFootX, leftFootY), _sputnikOutlinePaint);
      final Offset leftMid = Offset(-1.1 + (leftFootX + 1.1) * 0.5, 0.8 + (leftFootY - 0.8) * 0.5);
      canvas.drawLine(const Offset(-1.1, 0.8), leftMid, _sputnikCylinderPaint);
      canvas.drawLine(leftMid, Offset(leftFootX, leftFootY), _sputnikPistonPaint);

      // Right Leg
      canvas.drawLine(const Offset(1.1, 0.8), Offset(rightFootX, rightFootY), _sputnikOutlinePaint);
      final Offset rightMid = Offset(1.1 + (rightFootX - 1.1) * 0.5, 0.8 + (rightFootY - 0.8) * 0.5);
      canvas.drawLine(const Offset(1.1, 0.8), rightMid, _sputnikCylinderPaint);
      canvas.drawLine(rightMid, Offset(rightFootX, rightFootY), _sputnikPistonPaint);

      // Foot Pads
      canvas.drawRect(Rect.fromCenter(center: Offset(leftFootX, leftFootY), width: 0.4, height: 0.12), _sputnikFeetPaint);
      canvas.drawRect(Rect.fromCenter(center: Offset(rightFootX, rightFootY), width: 0.4, height: 0.12), _sputnikFeetPaint);
    }
  }

  // =========================================================================
  // 2. «Стриж / Swift-02» (SWIFT-02, High-Speed Interceptor)
  // =========================================================================
  static void _renderSwift({
    required Canvas canvas,
    Vector2? pilotHeadOffset,
    Vector2? pilotLookDirection,
    double pilotGStrain = 0.0,
    bool isPanicking = false,
    bool isBlinking = false,
    bool showLandingGear = true,
    double animationTime = 0.0,
    double legsCompression = 0.0,
    bool showDecals = true,
    double engineThrust = 0.0,
  }) {
    // Delta Wings & Body
    canvas.drawPath(_swiftWingsPath, _swiftWingPaint);
    canvas.drawPath(_swiftWingsPath, _swiftBorderPaint);

    canvas.drawPath(_swiftPath, _swiftBodyPaint);
    canvas.drawPath(_swiftNosePath, _swiftNosePaint);
    canvas.drawPath(_swiftNosePath, _swiftBorderPaint);
    canvas.drawPath(_swiftPath, _swiftBorderPaint);

    // Dual Micro-Thruster Nozzles
    canvas.drawRect(Rect.fromCenter(center: const Offset(-0.6, 0.95), width: 0.35, height: 0.2), _swiftNozzlePaint);
    canvas.drawRect(Rect.fromCenter(center: const Offset(0.6, 0.95), width: 0.35, height: 0.2), _swiftNozzlePaint);

    // Vector Decals: "SWIFT-02" + "INTERCEPTOR-07" + Chevrons + Nozzle IDs
    if (showDecals) {
      _renderVectorText(
        canvas: canvas,
        text: 'SWIFT-02',
        position: const Offset(0.0, -0.65),
        fontSize: 8.5,
        color: const Color(0xFF00E5FF),
        isBold: true,
      );

      _renderVectorText(
        canvas: canvas,
        text: 'INTERCEPTOR-07',
        position: const Offset(0.0, 0.55),
        fontSize: 6.0,
        color: const Color(0xFF263238),
        isBold: true,
      );

      // Nozzle serial tags
      _renderVectorText(canvas: canvas, text: 'NZ-01', position: const Offset(-0.6, 0.8), fontSize: 5.0, color: Colors.white70);
      _renderVectorText(canvas: canvas, text: 'NZ-02', position: const Offset(0.6, 0.8), fontSize: 5.0, color: Colors.white70);

      // Wing chevrons
      _renderChevron(canvas, const Offset(-0.95, 0.35), 0.15, Colors.cyanAccent);
      _renderChevron(canvas, const Offset(0.95, 0.35), 0.15, Colors.cyanAccent);
    }

    // Cockpit & Pilot (High-G Jet Fighter Pilot in Midnight-Blue Suit)
    _renderPilot(
      canvas: canvas,
      cabinCenter: const Offset(0.0, -0.25),
      radius: 0.42,
      shipId: 'swift',
      pilotHeadOffset: pilotHeadOffset,
      pilotLookDirection: pilotLookDirection,
      pilotGStrain: pilotGStrain,
      isPanicking: isPanicking,
      isBlinking: isBlinking,
      animationTime: animationTime,
    );

    // Landing Skis
    if (showLandingGear) {
      final double leftFootX = -1.1 + legsCompression * 0.3;
      final double leftFootY = 1.2 - legsCompression * 0.5;
      final double rightFootX = 1.1 - legsCompression * 0.3;
      final double rightFootY = 1.2 - legsCompression * 0.5;

      canvas.drawLine(const Offset(-0.8, 0.9), Offset(leftFootX, leftFootY), _swiftOutlinePaint);
      canvas.drawLine(const Offset(-0.8, 0.9), Offset(leftFootX, leftFootY), _swiftLegsPaint);

      canvas.drawLine(const Offset(0.8, 0.9), Offset(rightFootX, rightFootY), _swiftOutlinePaint);
      canvas.drawLine(const Offset(0.8, 0.9), Offset(rightFootX, rightFootY), _swiftLegsPaint);

      canvas.drawOval(Rect.fromCenter(center: Offset(leftFootX, leftFootY), width: 0.5, height: 0.08), _swiftSkiOutline);
      canvas.drawOval(Rect.fromCenter(center: Offset(leftFootX, leftFootY), width: 0.5, height: 0.08), _swiftFeetPaint);

      canvas.drawOval(Rect.fromCenter(center: Offset(rightFootX, rightFootY), width: 0.5, height: 0.08), _swiftSkiOutline);
      canvas.drawOval(Rect.fromCenter(center: Offset(rightFootX, rightFootY), width: 0.5, height: 0.08), _swiftFeetPaint);
    }
  }

  // =========================================================================
  // 3. «Буран-М / Titan-V» (TITAN-V, Heavy Armored Rescue Ship)
  // =========================================================================
  static void _renderTitan({
    required Canvas canvas,
    Vector2? pilotHeadOffset,
    Vector2? pilotLookDirection,
    double pilotGStrain = 0.0,
    bool isPanicking = false,
    bool isBlinking = false,
    bool showLandingGear = true,
    double animationTime = 0.0,
    double legsCompression = 0.0,
    bool showDecals = true,
    double engineThrust = 0.0,
  }) {
    // Heavy Hull Structure
    canvas.drawPath(_titanPath, _titanBodyPaint);
    canvas.drawPath(_titanArmorPlatePath, _titanArmorPlatePaint);
    canvas.drawPath(_titanPath, _titanBorderPaint);

    // Hazard Stripes across Armored Sponsons
    _renderHazardStripes(canvas, const Rect.fromLTRB(-1.75, 0.2, -1.2, 0.85));
    _renderHazardStripes(canvas, const Rect.fromLTRB(1.2, 0.2, 1.75, 0.85));

    // Triple Nozzle Cluster at Base
    canvas.drawRect(Rect.fromCenter(center: const Offset(-1.2, 1.25), width: 0.45, height: 0.25), _titanNozzlePaint);
    canvas.drawRect(Rect.fromCenter(center: const Offset(0.0, 1.30), width: 0.55, height: 0.28), _titanNozzlePaint);
    canvas.drawRect(Rect.fromCenter(center: const Offset(1.2, 1.25), width: 0.45, height: 0.25), _titanNozzlePaint);

    // Vector Decals: "TITAN-V" + Triple Cluster IDs "TH-A", "TH-B", "TH-C"
    if (showDecals) {
      _renderVectorText(
        canvas: canvas,
        text: 'TITAN-V',
        position: const Offset(0.0, -0.85),
        fontSize: 10.5,
        color: const Color(0xFFFFB300),
        isBold: true,
      );

      _renderVectorText(canvas: canvas, text: 'TH-A', position: const Offset(-1.2, 1.05), fontSize: 5.0, color: Colors.amberAccent);
      _renderVectorText(canvas: canvas, text: 'TH-B', position: const Offset(0.0, 1.08), fontSize: 5.5, color: Colors.amberAccent);
      _renderVectorText(canvas: canvas, text: 'TH-C', position: const Offset(1.2, 1.05), fontSize: 5.0, color: Colors.amberAccent);
    }

    // Heavy Armored Cockpit & Pilot (Heavy Armored EVA Suit with Titanium Cage)
    _renderPilot(
      canvas: canvas,
      cabinCenter: const Offset(0.0, -0.10),
      radius: 0.58,
      shipId: 'titan',
      pilotHeadOffset: pilotHeadOffset,
      pilotLookDirection: pilotLookDirection,
      pilotGStrain: pilotGStrain,
      isPanicking: isPanicking,
      isBlinking: isBlinking,
      animationTime: animationTime,
    );

    // Reinforced Heavy Landing Struts
    if (showLandingGear) {
      final double leftFootX = -1.8 + legsCompression * 0.5;
      final double leftFootY = 1.4 - legsCompression * 0.7;
      final double rightFootX = 1.8 - legsCompression * 0.5;
      final double rightFootY = 1.4 - legsCompression * 0.7;

      // Left Heavy Strut
      canvas.drawLine(const Offset(-1.4, 1.0), Offset(leftFootX, leftFootY), _titanLegOutline);
      final Offset leftMid = Offset(-1.4 + (leftFootX + 1.4) * 0.5, 1.0 + (leftFootY - 1.0) * 0.5);
      canvas.drawLine(const Offset(-1.4, 1.0), leftMid, _titanCylinderPaint);
      canvas.drawLine(leftMid, Offset(leftFootX, leftFootY), _titanPistonPaint);

      // Right Heavy Strut
      canvas.drawLine(const Offset(1.4, 1.0), Offset(rightFootX, rightFootY), _titanLegOutline);
      final Offset rightMid = Offset(1.4 + (rightFootX - 1.4) * 0.5, 1.0 + (rightFootY - 1.0) * 0.5);
      canvas.drawLine(const Offset(1.4, 1.0), rightMid, _titanCylinderPaint);
      canvas.drawLine(rightMid, Offset(rightFootX, rightFootY), _titanPistonPaint);

      // Heavy Reinforced Footpads
      canvas.drawRect(Rect.fromCenter(center: Offset(leftFootX, leftFootY), width: 0.65, height: 0.18), _titanFeetPaint);
      canvas.drawRect(Rect.fromCenter(center: Offset(rightFootX, rightFootY), width: 0.65, height: 0.18), _titanFeetPaint);
    }
  }

  // =========================================================================
  // 4. «Квазар / Quasar-IX» / «Игла» (QUASAR-IX, High-Tech Ion RCS Vessel)
  // =========================================================================
  static void _renderQuasar({
    required Canvas canvas,
    Vector2? pilotHeadOffset,
    Vector2? pilotLookDirection,
    double pilotGStrain = 0.0,
    bool isPanicking = false,
    bool isBlinking = false,
    bool showLandingGear = true,
    double animationTime = 0.0,
    double legsCompression = 0.0,
    bool showDecals = true,
    double rcsThrust = 0.0,
  }) {
    // Diamond Cybernetic Hull & Facets
    canvas.drawPath(_quasarPath, _quasarBodyPaint);

    final Path innerFacet = Path()
      ..moveTo(0.0, -1.1)
      ..lineTo(0.7, -0.3)
      ..lineTo(0.8, 0.5)
      ..lineTo(0.0, 0.4)
      ..lineTo(-0.8, 0.5)
      ..lineTo(-0.7, -0.3)
      ..close();
    canvas.drawPath(innerFacet, _quasarFacetPaint);
    canvas.drawPath(_quasarPath, _quasarBorderPaint);

    // Glowing Cybernetic Circuit Lines
    final Path circuitLines = Path()
      ..moveTo(-0.9, -0.4)..lineTo(-0.4, -0.1)..lineTo(-0.4, 0.4)..lineTo(-0.8, 0.6)
      ..moveTo(0.9, -0.4)..lineTo(0.4, -0.1)..lineTo(0.4, 0.4)..lineTo(0.8, 0.6);
    canvas.drawPath(circuitLines, _circuitGlowPaint);

    // Quad Ion RCS Thruster Pods
    _renderRcsPod(canvas, const Offset(-1.1, -0.5), rcsThrust < 0);
    _renderRcsPod(canvas, const Offset(1.1, -0.5), rcsThrust > 0);
    _renderRcsPod(canvas, const Offset(-1.25, 0.35), rcsThrust < 0);
    _renderRcsPod(canvas, const Offset(1.25, 0.35), rcsThrust > 0);

    // Vector Decals: "QUASAR-IX" Neon Digital Typography
    if (showDecals) {
      _renderVectorText(
        canvas: canvas,
        text: 'QUASAR-IX',
        position: const Offset(0.0, -0.75),
        fontSize: 9.0,
        color: const Color(0xFF00E5FF),
        isBold: true,
      );

      _renderVectorText(
        canvas: canvas,
        text: 'ION-DRIVE',
        position: const Offset(0.0, 0.48),
        fontSize: 5.5,
        color: const Color(0xFF80D8FF),
        isBold: true,
      );
    }

    // High-Tech Cybernetic Cockpit & Pilot
    _renderPilot(
      canvas: canvas,
      cabinCenter: const Offset(0.0, -0.25),
      radius: 0.44,
      shipId: 'quasar',
      pilotHeadOffset: pilotHeadOffset,
      pilotLookDirection: pilotLookDirection,
      pilotGStrain: pilotGStrain,
      isPanicking: isPanicking,
      isBlinking: isBlinking,
      animationTime: animationTime,
    );

    // Ion Levitation Landing Skids
    if (showLandingGear) {
      final double leftFootX = -1.1 + legsCompression * 0.3;
      final double leftFootY = 1.2 - legsCompression * 0.5;
      final double rightFootX = 1.1 - legsCompression * 0.3;
      final double rightFootY = 1.2 - legsCompression * 0.5;

      canvas.drawLine(const Offset(-0.8, 0.8), Offset(leftFootX, leftFootY), _quasarLegOutline);
      canvas.drawLine(const Offset(-0.8, 0.8), Offset(leftFootX, leftFootY), _quasarLegPaint);

      canvas.drawLine(const Offset(0.8, 0.8), Offset(rightFootX, rightFootY), _quasarLegOutline);
      canvas.drawLine(const Offset(0.8, 0.8), Offset(rightFootX, rightFootY), _quasarLegPaint);

      canvas.drawOval(Rect.fromCenter(center: Offset(leftFootX, leftFootY), width: 0.5, height: 0.08), _quasarLegOutline);
      canvas.drawOval(Rect.fromCenter(center: Offset(leftFootX, leftFootY), width: 0.5, height: 0.08), _quasarFeetPaint);

      canvas.drawOval(Rect.fromCenter(center: Offset(rightFootX, rightFootY), width: 0.5, height: 0.08), _quasarLegOutline);
      canvas.drawOval(Rect.fromCenter(center: Offset(rightFootX, rightFootY), width: 0.5, height: 0.08), _quasarFeetPaint);
    }
  }

  // =========================================================================
  // 5. «Циклон-CY88» / «Ураган» (CY-88, Industrial Multi-Nozzle Interceptor)
  // =========================================================================
  static void _renderCyclone({
    required Canvas canvas,
    Vector2? pilotHeadOffset,
    Vector2? pilotLookDirection,
    double pilotGStrain = 0.0,
    bool isPanicking = false,
    bool isBlinking = false,
    bool showLandingGear = true,
    double animationTime = 0.0,
    double legsCompression = 0.0,
    bool showDecals = true,
    double engineThrust = 0.0,
  }) {
    // Rugged Industrial Hull
    canvas.drawPath(_cyclonePath, _cycloneBodyPaint);
    canvas.drawPath(_cyclonePath, _cycloneBorderPaint);

    // Hazard Stripes & Markings
    canvas.drawLine(const Offset(-1.1, 0.8), const Offset(-0.7, 0.4), _cycloneStripePaint);
    canvas.drawLine(const Offset(1.1, 0.8), const Offset(0.7, 0.4), _cycloneStripePaint);

    // Heavy Multi-Nozzle Cluster
    canvas.drawRect(Rect.fromCenter(center: const Offset(-1.3, 1.15), width: 0.5, height: 0.3), _cycloneNozzlePaint);
    canvas.drawRect(Rect.fromCenter(center: const Offset(1.3, 1.15), width: 0.5, height: 0.3), _cycloneNozzlePaint);

    // Vector Decals: "CY-88" Industrial Stamp
    if (showDecals) {
      _renderVectorText(
        canvas: canvas,
        text: 'CY-88',
        position: const Offset(0.0, -0.8),
        fontSize: 11.0,
        color: const Color(0xFF212121),
        isBold: true,
      );

      _renderVectorText(
        canvas: canvas,
        text: 'RESCUE-UNIT',
        position: const Offset(0.0, 0.65),
        fontSize: 6.0,
        color: const Color(0xFF424242),
        isBold: true,
      );
    }

    // Industrial Cockpit & Pilot (Tactical Engineer Suit with Bubble Helmet)
    _renderPilot(
      canvas: canvas,
      cabinCenter: const Offset(0.0, 0.0),
      radius: 0.65,
      shipId: 'cyclone',
      pilotHeadOffset: pilotHeadOffset,
      pilotLookDirection: pilotLookDirection,
      pilotGStrain: pilotGStrain,
      isPanicking: isPanicking,
      isBlinking: isBlinking,
      animationTime: animationTime,
    );

    // Heavy Hydraulic Landing Gear
    if (showLandingGear) {
      final double leftFootX = -1.8 + legsCompression * 0.5;
      final double leftFootY = 1.4 - legsCompression * 0.7;
      final double rightFootX = 1.8 - legsCompression * 0.5;
      final double rightFootY = 1.4 - legsCompression * 0.7;

      canvas.drawLine(const Offset(-1.4, 1.0), Offset(leftFootX, leftFootY), _cycloneLegOutline);
      final Offset leftMid = Offset(-1.4 + (leftFootX + 1.4) * 0.5, 1.0 + (leftFootY - 1.0) * 0.5);
      canvas.drawLine(const Offset(-1.4, 1.0), leftMid, _cycloneCylinderPaint);
      canvas.drawLine(leftMid, Offset(leftFootX, leftFootY), _cyclonePistonPaint);

      canvas.drawLine(const Offset(1.4, 1.0), Offset(rightFootX, rightFootY), _cycloneLegOutline);
      final Offset rightMid = Offset(1.4 + (rightFootX - 1.4) * 0.5, 1.0 + (rightFootY - 1.0) * 0.5);
      canvas.drawLine(const Offset(1.4, 1.0), rightMid, _cycloneCylinderPaint);
      canvas.drawLine(rightMid, Offset(rightFootX, rightFootY), _cyclonePistonPaint);

      canvas.drawRect(Rect.fromCenter(center: Offset(leftFootX, leftFootY), width: 0.65, height: 0.18), _cycloneFeetPaint);
      canvas.drawRect(Rect.fromCenter(center: Offset(rightFootX, rightFootY), width: 0.65, height: 0.18), _cycloneFeetPaint);
    }
  }

  // =========================================================================
  // Live Dynamic Astronaut Simulator
  // =========================================================================
  static void _renderPilot({
    required Canvas canvas,
    required Offset cabinCenter,
    required double radius,
    required String shipId,
    Vector2? pilotHeadOffset,
    Vector2? pilotLookDirection,
    double pilotGStrain = 0.0,
    bool isPanicking = false,
    bool isBlinking = false,
    double animationTime = 0.0,
  }) {
    // 1. Dark Cabin Background
    canvas.drawCircle(cabinCenter, radius, _pilotBgPaint);

    // 2. Head Position & Inertia Offset
    double headX = cabinCenter.dx;
    double headY = cabinCenter.dy + 0.05;

    if (pilotHeadOffset != null) {
      headX += pilotHeadOffset.x;
      headY += pilotHeadOffset.y;
    } else if (animationTime > 0) {
      // Menu hover bobbing
      headX += sin(animationTime * 2.0) * 0.03 * radius;
      headY += cos(animationTime * 3.5) * 0.015 * radius;
    }

    final headPos = Offset(headX, headY);

    // G-Force Strain Vertical Compression & Squint
    final double gCompression = (pilotGStrain.clamp(0.0, 1.0) * 0.22);
    final double headScaleY = 1.0 - gCompression;
    final double headScaleX = 1.0 + gCompression * 0.12;

    // Suit Colors & Helmet Details Per Ship Class
    Color suitColor = Colors.deepOrangeAccent;
    Color helmetColor = Colors.white;
    Color visorColor = const Color(0xFF102027);

    switch (shipId) {
      case 'swift':
        suitColor = const Color(0xFF1A237E); // Midnight Blue G-Suit
        helmetColor = const Color(0xFF37474F); // Jet Fighter Helmet
        visorColor = const Color(0xFF006064); // Cyan Visor
        break;
      case 'titan':
        suitColor = const Color(0xFFFFB300); // Hazard Yellow Armored Exo-Suit
        helmetColor = const Color(0xFF455A64); // Titanium Reinforced Dome
        visorColor = const Color(0xFF212121);
        break;
      case 'quasar':
      case 'needle':
        suitColor = const Color(0xFF1E1E24); // Dark Synthetic Vacuum Suit
        helmetColor = const Color(0xFF121214); // Cybernetic Helmet
        visorColor = const Color(0xFF0D47A1); // Deep Blue Ion Visor
        break;
      case 'cyclone':
        suitColor = const Color(0xFF757575); // Heavy Grey/Amber Suit
        helmetColor = const Color(0xFFCFD8DC); // Panoramic Dome
        visorColor = const Color(0xFF263238);
        break;
      case 'sputnik':
      default:
        suitColor = Colors.deepOrange; // Classic Sokol-KV2 Orange
        helmetColor = Colors.white;
        visorColor = const Color(0xFF102027);
        break;
    }

    final suitPaint = Paint()..color = suitColor;
    final helmetPaint = Paint()..color = helmetColor;
    final visorPaint = Paint()..color = visorColor;

    // Astronaut Shoulders / Suit Base
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cabinCenter.dx, cabinCenter.dy + radius * 0.6),
        width: radius * 1.3,
        height: radius * 0.7,
      ),
      suitPaint,
    );

    // Class-specific suit chest accents
    if (shipId == 'swift') {
      // Oxygen regulator chest harness
      final harnessPaint = Paint()..color = const Color(0xFF00E5FF)..style = PaintingStyle.stroke..strokeWidth = 0.03;
      canvas.drawLine(Offset(cabinCenter.dx - 0.15, cabinCenter.dy + 0.4), Offset(cabinCenter.dx + 0.15, cabinCenter.dy + 0.4), harnessPaint);
    } else if (shipId == 'sputnik') {
      // Blue ribbing
      final ribPaint = Paint()..color = const Color(0xFF1E88E5)..style = PaintingStyle.stroke..strokeWidth = 0.025;
      canvas.drawLine(Offset(cabinCenter.dx - 0.2, cabinCenter.dy + 0.5), Offset(cabinCenter.dx + 0.2, cabinCenter.dy + 0.5), ribPaint);
    }

    // Transform Canvas for Head G-Strain Deformation
    canvas.save();
    canvas.translate(headPos.dx, headPos.dy);
    canvas.scale(headScaleX, headScaleY);

    // Helmet Outer Shell
    canvas.drawCircle(Offset.zero, radius * 0.42, helmetPaint);

    // Sputnik Red Star on Helmet Forehead
    if (shipId == 'sputnik') {
      _renderSovietStar(canvas, Offset(0.0, -radius * 0.28), 0.05);
    }

    // Visor Glass (Inner Mask)
    canvas.drawCircle(const Offset(0.0, -0.02), radius * 0.28, visorPaint);

    // Titan Protective Titanium Cage Grill
    if (shipId == 'titan') {
      final grillPaint = Paint()..color = const Color(0xFF78909C)..style = PaintingStyle.stroke..strokeWidth = 0.03;
      canvas.drawLine(Offset(-radius * 0.22, -0.02), Offset(radius * 0.22, -0.02), grillPaint);
      canvas.drawLine(Offset(-radius * 0.15, -radius * 0.15), Offset(-radius * 0.15, radius * 0.12), grillPaint);
      canvas.drawLine(Offset(radius * 0.15, -radius * 0.15), Offset(radius * 0.15, radius * 0.12), grillPaint);
    }

    // 3. Dynamic Eye / Pupil Tracking Along Ship Velocity & Threat Vectors
    final double eyeRadius = isPanicking ? (radius * 0.14) : (radius * 0.08);
    final double pupilRadius = isPanicking ? (eyeRadius * 0.28) : (eyeRadius * 0.52);

    double lookShiftX = 0.0;
    double lookShiftY = 0.0;
    if (pilotLookDirection != null && pilotLookDirection.length2 > 0.001) {
      final normalizedLook = pilotLookDirection.normalized();
      lookShiftX = (normalizedLook.x * eyeRadius * 0.5).clamp(-eyeRadius * 0.5, eyeRadius * 0.5);
      lookShiftY = (normalizedLook.y * eyeRadius * 0.5).clamp(-eyeRadius * 0.5, eyeRadius * 0.5);
    }

    // Panic Micro-Saccadic Eye Jitter
    if (isPanicking) {
      final double jitter = sin(animationTime * 45.0) * 0.015;
      lookShiftX += jitter;
      lookShiftY += cos(animationTime * 35.0) * 0.015;
    }

    final double eyeSpacing = radius * 0.11;
    final double eyeY = -radius * 0.02;

    if (isBlinking) {
      // Squinting / Panic Blinking Slits
      canvas.drawLine(Offset(-eyeSpacing - eyeRadius, eyeY), Offset(-eyeSpacing + eyeRadius, eyeY), _pilotBlinkPaint);
      canvas.drawLine(Offset(eyeSpacing - eyeRadius, eyeY), Offset(eyeSpacing + eyeRadius, eyeY), _pilotBlinkPaint);
    } else {
      // Left Eye & Pupil
      final leftEyeCenter = Offset(-eyeSpacing, eyeY);
      canvas.drawCircle(leftEyeCenter, eyeRadius, _pilotEyePaint);
      canvas.drawCircle(leftEyeCenter + Offset(lookShiftX, lookShiftY), pupilRadius, _pilotPupilPaint);

      // Right Eye & Pupil
      final rightEyeCenter = Offset(eyeSpacing, eyeY);
      canvas.drawCircle(rightEyeCenter, eyeRadius, _pilotEyePaint);
      canvas.drawCircle(rightEyeCenter + Offset(lookShiftX, lookShiftY), pupilRadius, _pilotPupilPaint);
    }

    // Quasar Cybernetic HUD Waveform inside Visor
    if (shipId == 'quasar' || shipId == 'needle') {
      final hudWavePaint = Paint()
        ..color = const Color(0xFF00E5FF).withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.02;
      final wavePath = Path()
        ..moveTo(-radius * 0.20, radius * 0.08)
        ..lineTo(-radius * 0.10, radius * 0.08)
        ..lineTo(-radius * 0.05, 0.0)
        ..lineTo(0.0, radius * 0.14)
        ..lineTo(radius * 0.05, radius * 0.04)
        ..lineTo(radius * 0.20, radius * 0.08);
      canvas.drawPath(wavePath, hudWavePaint);
    }

    // Swift HUD Reticle
    if (shipId == 'swift') {
      final reticlePaint = Paint()
        ..color = const Color(0xFF00E5FF).withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.015;
      canvas.drawCircle(Offset.zero, radius * 0.15, reticlePaint);
      canvas.drawLine(Offset(-radius * 0.2, 0), Offset(radius * 0.2, 0), reticlePaint);
    }

    canvas.restore(); // Restore G-Strain Transform

    // 4. Transparent Glass Cockpit Dome & Light Highlights
    canvas.drawCircle(cabinCenter, radius, _glassPaint);
    canvas.drawCircle(cabinCenter, radius, _glassBorder);

    // Static Specular Arc Highlight
    canvas.drawOval(
      Rect.fromLTWH(
        cabinCenter.dx - radius * 0.6,
        cabinCenter.dy - radius * 0.7,
        radius * 0.6,
        radius * 0.35,
      ),
      _glassHighlightPaint,
    );

    // Animated Light Sweep Across Canopy Glass
    final double sweepProgress = (sin(animationTime * 0.8) + 1.0) / 2.0;
    final double sweepX = cabinCenter.dx - radius + (radius * 2.0 * sweepProgress);
    canvas.save();
    final Path clipPath = Path()..addOval(Rect.fromCircle(center: cabinCenter, radius: radius));
    canvas.clipPath(clipPath);
    final Paint sweepPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    final Path sweepPath = Path()
      ..moveTo(sweepX - radius * 0.2, cabinCenter.dy - radius)
      ..lineTo(sweepX + radius * 0.1, cabinCenter.dy - radius)
      ..lineTo(sweepX - radius * 0.1, cabinCenter.dy + radius)
      ..lineTo(sweepX - radius * 0.4, cabinCenter.dy + radius)
      ..close();
    canvas.drawPath(sweepPath, sweepPaint);
    canvas.restore();
  }

  // =========================================================================
  // Vector Graphics Helper Utilities
  // =========================================================================

  /// Renders crisp vector text on Canvas without pixelation.
  static void _renderVectorText({
    required Canvas canvas,
    required String text,
    required Offset position,
    required double fontSize,
    required Color color,
    bool isBold = false,
  }) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    // Scale factor so standard font metrics render crisply in meter space
    const double fontBaseScale = 0.015;
    canvas.scale(fontBaseScale, fontBaseScale);

    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
          letterSpacing: 0.6,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  /// Renders a 5-pointed Soviet vector star.
  static void _renderSovietStar(Canvas canvas, Offset center, double outerRadius) {
    final double innerRadius = outerRadius * 0.382;
    final Path starPath = Path();

    for (int i = 0; i < 10; i++) {
      final double r = i.isEven ? outerRadius : innerRadius;
      final double angle = (i * pi / 5) - (pi / 2);
      final double x = center.dx + r * cos(angle);
      final double y = center.dy + r * sin(angle);
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();

    canvas.drawPath(starPath, _starPaint);
    canvas.drawPath(starPath, _starOutlinePaint);
  }

  /// Renders a radio stabilization antenna.
  static void _renderAntenna(Canvas canvas, Offset base, Offset tip) {
    canvas.drawLine(base, tip, _antennaPaint);
    canvas.drawCircle(tip, 0.04, _antennaTipPaint);
  }

  /// Renders yellow/black diagonal hazard stripes clipped to a bounding box.
  static void _renderHazardStripes(Canvas canvas, Rect bounds) {
    canvas.save();
    canvas.clipRect(bounds);
    canvas.drawRect(bounds, _hazardYellowPaint);

    for (double x = bounds.left - bounds.height; x <= bounds.right + bounds.height; x += 0.25) {
      canvas.drawLine(Offset(x, bounds.top), Offset(x + bounds.height, bounds.bottom), _hazardBlackPaint);
    }
    canvas.restore();
  }

  /// Renders a decorative racing chevron.
  static void _renderChevron(Canvas canvas, Offset center, double size, Color color) {
    final chevronPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.04
      ..strokeCap = StrokeCap.round;

    final Path p = Path()
      ..moveTo(center.dx - size, center.dy + size * 0.5)
      ..lineTo(center.dx, center.dy - size * 0.5)
      ..lineTo(center.dx + size, center.dy + size * 0.5);
    canvas.drawPath(p, chevronPaint);
  }

  /// Renders an Ion RCS maneuvering pod.
  static void _renderRcsPod(Canvas canvas, Offset center, bool isFiring) {
    canvas.drawCircle(center, 0.08, _ionRcsPaint);
    if (isFiring) {
      canvas.drawCircle(center, 0.18, _ionGlowPaint);
    }
  }
}
