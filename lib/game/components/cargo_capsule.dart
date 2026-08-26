import 'dart:math';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import '../config/game_config.dart';
import '../lander_zero_game.dart';
import 'coin.dart';
import 'endless_cargo_data.dart';

/// Thematic cosmetic cargo types mapped per planetary biome.
enum CargoType {
  /// Echo Canyon: Emergency life-support salvage capsule with porthole and SOS beacon.
  rescuePod,

  /// Solar Winds: Heavy industrial riveted container with hazard stripes and lifting lugs.
  titaniumCrate,

  /// Europa Ice Rift: Insulated cylindrical canister with pressure gauges and frosty mist.
  cryoBarrel,

  /// Orbital Debris: Golden MLI satellite instrument package with micro-antennas and solar panels.
  scienceProbe,

  /// Deep Core: Faceted crystal block emitting soft neon luminescence and plasma filaments.
  energyCrystal;

  /// Resolves the thematic cosmetic cargo type for a given map ID.
  static CargoType fromMapId(String mapId) {
    switch (mapId) {
      case 'wind':
        return CargoType.titaniumCrate;
      case 'core':
        return CargoType.energyCrystal;
      case 'ice':
        return CargoType.cryoBarrel;
      case 'orbit':
        return CargoType.scienceProbe;
      case 'echo':
      default:
        return CargoType.rescuePod;
    }
  }
}

/// Cargo Capsule component with strict physics invariance and 5 distinct cosmetic vector models.
class CargoCapsule extends BodyComponent<LanderZeroGame> {
  final Vector2 initialPosition;
  final CargoType type;
  final EndlessCargoInfo? endlessInfo;

  CargoCapsule({
    required this.initialPosition,
    this.type = CargoType.rescuePod,
    this.endlessInfo,
  });

  /// Docking connection state with the lander tether
  bool isDocked = false;

  /// Internal animation timer for dynamic vector rendering effects
  double _animTime = 0.0;

  // Reusable static/final Paint objects for high-performance zero-allocation rendering
  static final Paint _hullFillPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _hullStrokePaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _accentFillPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _accentStrokePaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _glowPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _lightPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _hookPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.08;

  // Reusable Path objects
  final Path _capsulePath = Path()
    ..moveTo(0.0, -0.9)
    ..lineTo(0.8, -0.4)
    ..lineTo(0.6, 0.9)
    ..lineTo(-0.6, 0.9)
    ..lineTo(-0.8, -0.4)
    ..close();
  final Path _innerPath = Path();
  final Path _facetPath = Path();

  @override
  void update(double dt) {
    super.update(dt);
    _animTime += dt;

    if (!isMounted) return;

    // 1. Modifier: Magnetic coin attraction when docked
    if (isDocked && endlessInfo?.modifier == EndlessCargoModifier.magnetic) {
      final coins = game.world.children.whereType<Coin>();
      final pos = body.position;
      for (final coin in coins) {
        final d = coin.body.position.distanceTo(pos);
        if (d < 6.0 && d > 0.01) {
          final dir = (pos - coin.body.position).normalized();
          coin.body.setTransform(coin.body.position + dir * (dt * 6.5), 0);
          if (d < 1.3) {
            coin.collect();
          }
        }
      }
    }

    // 2. Modifier: Antigrav buoyant upward force
    if (endlessInfo?.modifier == EndlessCargoModifier.antigrav) {
      body.applyForce(Vector2(0, -0.4 * body.mass * 9.8));
    }
  }

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: initialPosition,
      linearDamping: 1.5,
      angularDamping: 3.0,
    );

    final body = world.createBody(bodyDef);

    // 5-vertex PolygonShape (Width = 1.6m, Height = 1.8m)
    final vertices = [
      Vector2(0.0, -0.9),  // Top hook point
      Vector2(0.8, -0.4),  // Upper right chamfer
      Vector2(0.6, 0.9),   // Lower right base
      Vector2(-0.6, 0.9),  // Lower left base
      Vector2(-0.8, -0.4), // Upper left chamfer
    ];

    final shape = PolygonShape()..set(vertices);

    final fixtureDef = FixtureDef(
      shape,
      density: endlessInfo?.modifier.density ?? GameConfig.cargoMass,
      friction: 0.3,
      restitution: 0.05,
    )
      ..filter.categoryBits = 0x0008
      ..filter.maskBits = 0xFFFF & ~0x0004 & ~0x0002;

    body.createFixture(fixtureDef);
    return body;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. Rarity Aura Halo Background
    if (endlessInfo != null && endlessInfo!.rarity != EndlessCargoRarity.standard) {
      final auraPaint = Paint()
        ..color = endlessInfo!.rarity.glowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.22
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.3);
      canvas.drawPath(_capsulePath, auraPaint);
    }

    // 2. Render Archetype Body Model
    switch (type) {
      case CargoType.rescuePod:
        _renderRescuePod(canvas);
        break;
      case CargoType.titaniumCrate:
        _renderTitaniumCrate(canvas);
        break;
      case CargoType.cryoBarrel:
        _renderCryoBarrel(canvas);
        break;
      case CargoType.scienceProbe:
        _renderScienceProbe(canvas);
        break;
      case CargoType.energyCrystal:
        _renderEnergyCrystal(canvas);
        break;
    }

    // 3. Serial Code / Modifier Stamp Overlay
    if (endlessInfo != null) {
      _renderEndlessBadge(canvas);
    }
  }

  void _renderEndlessBadge(Canvas canvas) {
    final rarityColor = endlessInfo!.rarity.color;
    
    // Glowing Rarity Status LED in lower center
    canvas.drawCircle(const Offset(0.0, 0.65), 0.10, Paint()..color = rarityColor);
    canvas.drawCircle(
      const Offset(0.0, 0.65),
      0.18,
      Paint()
        ..color = rarityColor.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.2),
    );

    // Modifier Indicator (if special)
    if (endlessInfo!.modifier != EndlessCargoModifier.none) {
      final modColor = endlessInfo!.modifier == EndlessCargoModifier.volatile
          ? const Color(0xFFFF1744)
          : endlessInfo!.modifier == EndlessCargoModifier.magnetic
              ? const Color(0xFF00E5FF)
              : const Color(0xFFFFD600);
      canvas.drawCircle(const Offset(0.0, -0.60), 0.08, Paint()..color = modColor);
    }
  }

  // ===========================================================================
  // 1. RESCUE POD — Salvage capsule with porthole, waving astronaut & SOS beacon
  // ===========================================================================
  void _renderRescuePod(Canvas canvas) {
    // Main armor hull
    _hullFillPaint.color = const Color(0xFF263238);
    canvas.drawPath(_capsulePath, _hullFillPaint);

    // Inner hull panel
    _innerPath.reset();
    _innerPath
      ..moveTo(0.0, -0.75)
      ..lineTo(0.68, -0.32)
      ..lineTo(0.50, 0.78)
      ..lineTo(-0.50, 0.78)
      ..lineTo(-0.68, -0.32)
      ..close();

    _accentFillPaint.color = const Color(0xFF37474F);
    canvas.drawPath(_innerPath, _accentFillPaint);

    // Hull border
    _hullStrokePaint
      ..color = isDocked ? const Color(0xFF00E676) : const Color(0xFF78909C)
      ..strokeWidth = 0.06;
    canvas.drawPath(_capsulePath, _hullStrokePaint);

    // Circular Glass Porthole
    final portholeCenter = const Offset(0.0, 0.0);
    // Outer metallic rim
    _hullFillPaint.color = const Color(0xFF1C2833);
    canvas.drawCircle(portholeCenter, 0.28, _hullFillPaint);

    _accentStrokePaint
      ..color = const Color(0xFF90A4AE)
      ..strokeWidth = 0.03;
    canvas.drawCircle(portholeCenter, 0.28, _accentStrokePaint);

    // Deep space glass interior
    _hullFillPaint.color = const Color(0xFF0A192F);
    canvas.drawCircle(portholeCenter, 0.24, _hullFillPaint);

    // Interior Astronaut inside porthole
    // Torso / shoulders
    _lightPaint.color = const Color(0xFFECEFF1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.11, 0.05, 0.22, 0.14),
        const Radius.circular(0.05),
      ),
      _lightPaint,
    );

    // Helmet
    _lightPaint.color = Colors.white;
    canvas.drawCircle(const Offset(0.0, -0.04), 0.10, _lightPaint);

    // Gold reflective visor
    _lightPaint.color = const Color(0xFFFFD54F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.06, -0.07, 0.12, 0.06),
        const Radius.circular(0.03),
      ),
      _lightPaint,
    );

    // Animated waving arm
    final double waveArmY = -0.06 + 0.04 * sin(_animTime * 7.0);
    _accentStrokePaint
      ..color = const Color(0xFFECEFF1)
      ..strokeWidth = 0.04
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      const Offset(0.08, 0.06),
      Offset(0.14, waveArmY),
      _accentStrokePaint,
    );
    _lightPaint.color = Colors.white;
    canvas.drawCircle(Offset(0.14, waveArmY), 0.03, _lightPaint);

    // Glass reflection glare
    _lightPaint.color = const Color(0x33FFFFFF);
    canvas.drawArc(
      const Rect.fromLTWH(-0.20, -0.20, 0.40, 0.40),
      -2.4,
      1.2,
      false,
      _accentStrokePaint..strokeWidth = 0.04..color = const Color(0x44FFFFFF),
    );

    // SOS Emergency Strobe Beacon at top
    final double strobe = sin(_animTime * 10.0);
    final Color beaconColor;
    if (isDocked) {
      beaconColor = const Color(0xFF00E676);
    } else {
      beaconColor = strobe > 0 ? const Color(0xFFFF1744) : const Color(0xFFFF9100);
    }

    _glowPaint
      ..color = beaconColor.withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.15);
    canvas.drawCircle(const Offset(0.0, -0.68), 0.14, _glowPaint);

    _lightPaint.color = beaconColor;
    canvas.drawCircle(const Offset(0.0, -0.68), 0.07, _lightPaint);

    _lightPaint.color = Colors.white;
    canvas.drawCircle(const Offset(0.0, -0.68), 0.03, _lightPaint);

    // Medical Rescue Cross Badge on lower hull
    final crossCenter = const Offset(0.0, 0.52);
    _lightPaint.color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: crossCenter, width: 0.22, height: 0.22),
        const Radius.circular(0.03),
      ),
      _lightPaint,
    );
    _accentFillPaint.color = const Color(0xFFFF1744);
    canvas.drawRect(
      Rect.fromCenter(center: crossCenter, width: 0.06, height: 0.16),
      _accentFillPaint,
    );
    canvas.drawRect(
      Rect.fromCenter(center: crossCenter, width: 0.16, height: 0.06),
      _accentFillPaint,
    );

    // Top Tow Hook Eyelet
    _hookPaint.color = isDocked ? const Color(0xFF00E676) : const Color(0xFFB0BEC5);
    canvas.drawCircle(const Offset(0.0, -0.9), 0.12, _hookPaint);
  }

  // ===========================================================================
  // 2. TITANIUM CRATE — Heavy industrial container with hazard stripes & lugs
  // ===========================================================================
  void _renderTitaniumCrate(Canvas canvas) {
    // Heavy industrial dark steel hull
    _hullFillPaint.color = const Color(0xFF21272B);
    canvas.drawPath(_capsulePath, _hullFillPaint);

    // Corner reinforcement plates
    _accentFillPaint.color = const Color(0xFF37474F);
    // Upper-left plate
    _facetPath.reset();
    _facetPath
      ..moveTo(0.0, -0.9)
      ..lineTo(-0.8, -0.4)
      ..lineTo(-0.5, -0.3)
      ..lineTo(-0.15, -0.65)
      ..close();
    canvas.drawPath(_facetPath, _accentFillPaint);

    // Upper-right plate
    _facetPath.reset();
    _facetPath
      ..moveTo(0.0, -0.9)
      ..lineTo(0.8, -0.4)
      ..lineTo(0.5, -0.3)
      ..lineTo(0.15, -0.65)
      ..close();
    canvas.drawPath(_facetPath, _accentFillPaint);

    // Lower base plate
    _facetPath.reset();
    _facetPath
      ..moveTo(-0.6, 0.9)
      ..lineTo(0.6, 0.9)
      ..lineTo(0.55, 0.65)
      ..lineTo(-0.55, 0.65)
      ..close();
    canvas.drawPath(_facetPath, _accentFillPaint);

    // Hazard Stripes Mid-Band
    canvas.save();
    final hazardRect = const Rect.fromLTRB(-0.68, -0.22, 0.68, 0.38);
    canvas.clipRect(hazardRect);

    // Yellow warning background
    _lightPaint.color = const Color(0xFFFFD600);
    canvas.drawRect(hazardRect, _lightPaint);

    // Black diagonal stripes
    _accentFillPaint.color = const Color(0xFF212121);
    const double stripeWidth = 0.12;
    for (double x = -1.2; x <= 1.2; x += stripeWidth * 2) {
      _facetPath.reset();
      _facetPath
        ..moveTo(x, -0.3)
        ..lineTo(x + stripeWidth, -0.3)
        ..lineTo(x + stripeWidth + 0.4, 0.45)
        ..lineTo(x + 0.4, 0.45)
        ..close();
      canvas.drawPath(_facetPath, _accentFillPaint);
    }
    canvas.restore();

    // Hazard band metallic framing
    _accentStrokePaint
      ..color = const Color(0xFF78909C)
      ..strokeWidth = 0.04;
    canvas.drawRect(hazardRect, _accentStrokePaint);

    // Structural Rivet Bolts (Silver metallic dots)
    _lightPaint.color = const Color(0xFFCFD8DC);
    const rivets = [
      Offset(-0.65, -0.35),
      Offset(-0.40, -0.48),
      Offset(0.65, -0.35),
      Offset(0.40, -0.48),
      Offset(-0.50, 0.78),
      Offset(-0.20, 0.78),
      Offset(0.20, 0.78),
      Offset(0.50, 0.78),
    ];
    for (final r in rivets) {
      canvas.drawCircle(r, 0.035, _lightPaint);
      _accentStrokePaint
        ..color = const Color(0xFF263238)
        ..strokeWidth = 0.015;
      canvas.drawCircle(r, 0.035, _accentStrokePaint);
    }

    // Heavy Forged Steel Lifting Lugs (Left & Right)
    _hookPaint.color = const Color(0xFF78909C);
    canvas.drawCircle(const Offset(-0.68, -0.32), 0.09, _hookPaint);
    canvas.drawCircle(const Offset(0.68, -0.32), 0.09, _hookPaint);

    // Center Magnetic Lock & Status LED
    final statusColor = isDocked ? const Color(0xFF00E676) : const Color(0xFFFF1744);
    _lightPaint.color = const Color(0xFF263238);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.16, 0.02, 0.32, 0.12),
        const Radius.circular(0.03),
      ),
      _lightPaint,
    );

    _glowPaint
      ..color = statusColor.withOpacity(0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.12);
    canvas.drawCircle(const Offset(0.0, 0.08), 0.07, _glowPaint);

    _lightPaint.color = statusColor;
    canvas.drawCircle(const Offset(0.0, 0.08), 0.04, _lightPaint);

    // Hull Outer Frame
    _hullStrokePaint
      ..color = isDocked ? const Color(0xFF00E676) : const Color(0xFF90A4AE)
      ..strokeWidth = 0.06;
    canvas.drawPath(_capsulePath, _hullStrokePaint);

    // Top Forged Steel Tow Hook
    _hookPaint.color = isDocked ? const Color(0xFF00E676) : const Color(0xFFCFD8DC);
    canvas.drawRect(const Rect.fromLTWH(-0.10, -0.98, 0.20, 0.16), _hookPaint);
  }

  // ===========================================================================
  // 3. CRYO BARREL — Insulated canister with pressure gauges & frosty mist
  // ===========================================================================
  void _renderCryoBarrel(Canvas canvas) {
    // Insulated cylindrical canister body
    _hullFillPaint.color = const Color(0xFF1A262C);
    canvas.drawPath(_capsulePath, _hullFillPaint);

    // Circumferential Insulated Metallic Rings
    _accentFillPaint.color = const Color(0xFF37474F);
    // Top Ring
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.68, -0.38, 1.36, 0.12),
        const Radius.circular(0.04),
      ),
      _accentFillPaint,
    );
    // Middle Ring
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.62, 0.16, 1.24, 0.12),
        const Radius.circular(0.04),
      ),
      _accentFillPaint,
    );
    // Bottom Ring
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.56, 0.62, 1.12, 0.12),
        const Radius.circular(0.04),
      ),
      _accentFillPaint,
    );

    // Dual Cryogenic Pressure Gauges (Left & Right)
    void drawGauge(Offset center, double needleAngle) {
      // Chrome bezel
      _accentFillPaint.color = const Color(0xFFB0BEC5);
      canvas.drawCircle(center, 0.15, _accentFillPaint);

      // Dark dial face
      _lightPaint.color = const Color(0xFF0D1B2A);
      canvas.drawCircle(center, 0.12, _lightPaint);

      // Glowing Cyan Dial Arc
      _accentStrokePaint
        ..color = const Color(0xFF00E5FF)
        ..strokeWidth = 0.025;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 0.09),
        -2.5,
        3.5,
        false,
        _accentStrokePaint,
      );

      // Glowing Needle
      _accentStrokePaint
        ..color = isDocked ? const Color(0xFF00E676) : const Color(0xFF00E5FF)
        ..strokeWidth = 0.025
        ..strokeCap = StrokeCap.round;
      final needleEnd = center + Offset(cos(needleAngle) * 0.08, sin(needleAngle) * 0.08);
      canvas.drawLine(center, needleEnd, _accentStrokePaint);

      // Center pivot
      _lightPaint.color = Colors.white;
      canvas.drawCircle(center, 0.025, _lightPaint);
    }

    final double needleOsc = 0.15 * sin(_animTime * 5.0);
    drawGauge(const Offset(-0.26, -0.10), -2.0 + needleOsc);
    drawGauge(const Offset(0.26, -0.10), -1.1 - needleOsc);

    // Sub-zero Frost Snowflake Decal at center
    final snowflakeCenter = const Offset(0.0, 0.40);
    _accentStrokePaint
      ..color = const Color(0xFF80DEEA)
      ..strokeWidth = 0.03
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final double angle = i * (pi / 3);
      final p1 = snowflakeCenter + Offset(cos(angle) * 0.14, sin(angle) * 0.14);
      final p2 = snowflakeCenter - Offset(cos(angle) * 0.14, sin(angle) * 0.14);
      canvas.drawLine(p1, p2, _accentStrokePaint);
    }
    _lightPaint.color = Colors.white;
    canvas.drawCircle(snowflakeCenter, 0.03, _lightPaint);

    // Animated Frosty Mist Particles / Cryo-Vapor Vents near bottom
    _glowPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.08);
    final mistOffsets = [
      Offset(-0.42 + 0.04 * sin(_animTime * 4.0), 0.78 + 0.03 * cos(_animTime * 3.0)),
      Offset(-0.30 + 0.03 * cos(_animTime * 5.0), 0.82 + 0.02 * sin(_animTime * 4.0)),
      Offset(0.42 + 0.04 * cos(_animTime * 4.0), 0.78 + 0.03 * sin(_animTime * 3.0)),
      Offset(0.30 + 0.03 * sin(_animTime * 5.0), 0.82 + 0.02 * cos(_animTime * 4.0)),
    ];
    for (int i = 0; i < mistOffsets.length; i++) {
      final double radius = 0.05 + 0.02 * sin(_animTime * 6.0 + i);
      _glowPaint.color = const Color(0x6680DEEA);
      canvas.drawCircle(mistOffsets[i], radius, _glowPaint);
    }

    // Outer Hull Border
    _hullStrokePaint
      ..color = isDocked ? const Color(0xFF00E676) : const Color(0xFF00E5FF)
      ..strokeWidth = 0.06;
    canvas.drawPath(_capsulePath, _hullStrokePaint);

    // Top Cryo Relief Manifold & Tow Hook
    _hookPaint.color = isDocked ? const Color(0xFF00E676) : const Color(0xFF80DEEA);
    canvas.drawCircle(const Offset(0.0, -0.9), 0.12, _hookPaint);
  }

  // ===========================================================================
  // 4. SCIENCE PROBE — Golden MLI satellite with micro-antennas & solar panels
  // ===========================================================================
  void _renderScienceProbe(Canvas canvas) {
    // Golden MLI (Multi-Layer Insulation) Foil Core
    _hullFillPaint.color = const Color(0xFFFFA000);
    canvas.drawPath(_capsulePath, _hullFillPaint);

    // Quilted Gold Thermal Blanket Facets
    _accentFillPaint.color = const Color(0xFFFFD54F);
    _facetPath.reset();
    _facetPath
      ..moveTo(0.0, -0.72)
      ..lineTo(0.55, -0.32)
      ..lineTo(0.40, 0.72)
      ..lineTo(-0.40, 0.72)
      ..lineTo(-0.55, -0.32)
      ..close();
    canvas.drawPath(_facetPath, _accentFillPaint);

    // Gold thermal foil cross-hatch quilt grid
    _accentStrokePaint
      ..color = const Color(0xFFFF8F00)
      ..strokeWidth = 0.025;
    for (double y = -0.3; y <= 0.6; y += 0.20) {
      canvas.drawLine(Offset(-0.45, y), Offset(0.45, y), _accentStrokePaint);
    }
    for (double x = -0.3; x <= 0.3; x += 0.20) {
      canvas.drawLine(Offset(x, -0.3), Offset(x, 0.6), _accentStrokePaint);
    }

    // Deployable Photovoltaic Solar Panel Wings (Left & Right)
    void drawSolarPanel(Rect rect) {
      // Panel frame
      _lightPaint.color = const Color(0xFF1A237E);
      canvas.drawRect(rect, _lightPaint);

      // Deep space photovoltaic cells
      _accentFillPaint.color = const Color(0xFF0D47A1);
      canvas.drawRect(
        Rect.fromLTRB(rect.left + 0.02, rect.top + 0.02, rect.right - 0.02, rect.bottom - 0.02),
        _accentFillPaint,
      );

      // Cyan Grid Division Lines
      _accentStrokePaint
        ..color = const Color(0xFF00E5FF)
        ..strokeWidth = 0.015;
      final midX = (rect.left + rect.right) / 2;
      final midY = (rect.top + rect.bottom) / 2;
      canvas.drawLine(Offset(midX, rect.top), Offset(midX, rect.bottom), _accentStrokePaint);
      canvas.drawLine(Offset(rect.left, midY), Offset(rect.right, midY), _accentStrokePaint);

      // Outer bezel
      _accentStrokePaint
        ..color = const Color(0xFF90A4AE)
        ..strokeWidth = 0.03;
      canvas.drawRect(rect, _accentStrokePaint);
    }

    drawSolarPanel(const Rect.fromLTRB(-0.76, -0.15, -0.42, 0.35));
    drawSolarPanel(const Rect.fromLTRB(0.42, -0.15, 0.76, 0.35));

    // Dual Micro-Antennas extending diagonally
    _accentStrokePaint
      ..color = const Color(0xFFECEFF1)
      ..strokeWidth = 0.03
      ..strokeCap = StrokeCap.round;
    // Left antenna
    canvas.drawLine(const Offset(-0.25, -0.40), const Offset(-0.55, -0.80), _accentStrokePaint);
    // Right antenna
    canvas.drawLine(const Offset(0.25, -0.40), const Offset(0.55, -0.80), _accentStrokePaint);

    // Blinking Telemetry LEDs at antenna tips
    final bool beaconBlink = sin(_animTime * 8.0) > 0;
    final Color probeLedColor = isDocked
        ? const Color(0xFF00E676)
        : (beaconBlink ? const Color(0xFF00E5FF) : const Color(0xFFE040FB));

    _glowPaint
      ..color = probeLedColor.withOpacity(0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.10);
    canvas.drawCircle(const Offset(-0.55, -0.80), 0.06, _glowPaint);
    canvas.drawCircle(const Offset(0.55, -0.80), 0.06, _glowPaint);

    _lightPaint.color = probeLedColor;
    canvas.drawCircle(const Offset(-0.55, -0.80), 0.03, _lightPaint);
    canvas.drawCircle(const Offset(0.55, -0.80), 0.03, _lightPaint);

    // Multi-Spectral Optical Sensor Aperture / Camera Lens at center
    final sensorCenter = const Offset(0.0, 0.05);
    _accentFillPaint.color = const Color(0xFF37474F);
    canvas.drawCircle(sensorCenter, 0.18, _accentFillPaint);

    _lightPaint.color = const Color(0xFF7C4DFF); // Purple anti-reflective coating
    canvas.drawCircle(sensorCenter, 0.14, _lightPaint);

    _lightPaint.color = const Color(0xFF0A192F); // Deep sensor iris
    canvas.drawCircle(sensorCenter, 0.10, _lightPaint);

    _lightPaint.color = const Color(0xFF00E5FF); // Glowing cyan optical pupil
    canvas.drawCircle(sensorCenter, 0.04, _lightPaint);

    _lightPaint.color = Colors.white; // Optical glare reflection dot
    canvas.drawCircle(sensorCenter + const Offset(-0.04, -0.04), 0.02, _lightPaint);

    // Hull Outer Frame
    _hullStrokePaint
      ..color = isDocked ? const Color(0xFF00E676) : const Color(0xFFFFD54F)
      ..strokeWidth = 0.06;
    canvas.drawPath(_capsulePath, _hullStrokePaint);

    // Top Magnetic Satellite Capture Ring & Tow Hook
    _hookPaint.color = isDocked ? const Color(0xFF00E676) : const Color(0xFFFFD54F);
    canvas.drawCircle(const Offset(0.0, -0.9), 0.12, _hookPaint);
  }

  // ===========================================================================
  // 5. ENERGY CRYSTAL — Faceted crystal block with neon luminescence & sparks
  // ===========================================================================
  void _renderEnergyCrystal(Canvas canvas) {
    final double pulse = 0.75 + 0.25 * sin(_animTime * 4.0);

    // Radiant Neon Luminescence / Glow Aura
    final Color glowColor = isDocked ? const Color(0xFF00E676) : const Color(0xFF00E5FF);
    _glowPaint
      ..color = glowColor.withOpacity(0.4 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.22);
    canvas.drawPath(_capsulePath, _glowPaint);

    // Dark crystalline background
    _hullFillPaint.color = const Color(0xFF004D40);
    canvas.drawPath(_capsulePath, _hullFillPaint);

    // 1. Upper Left Facet
    _facetPath.reset();
    _facetPath
      ..moveTo(0.0, -0.72)
      ..lineTo(-0.65, -0.25)
      ..lineTo(0.0, 0.05)
      ..close();
    _accentFillPaint.color = const Color(0xFF00BFA5).withOpacity(0.85);
    canvas.drawPath(_facetPath, _accentFillPaint);

    // 2. Upper Right Facet
    _facetPath.reset();
    _facetPath
      ..moveTo(0.0, -0.72)
      ..lineTo(0.65, -0.25)
      ..lineTo(0.0, 0.05)
      ..close();
    _accentFillPaint.color = const Color(0xFF00E676).withOpacity(0.85);
    canvas.drawPath(_facetPath, _accentFillPaint);

    // 3. Lower Left Facet
    _facetPath.reset();
    _facetPath
      ..moveTo(0.0, 0.05)
      ..lineTo(-0.65, -0.25)
      ..lineTo(-0.48, 0.65)
      ..lineTo(0.0, 0.78)
      ..close();
    _accentFillPaint.color = const Color(0xFF00897B).withOpacity(0.90);
    canvas.drawPath(_facetPath, _accentFillPaint);

    // 4. Lower Right Facet
    _facetPath.reset();
    _facetPath
      ..moveTo(0.0, 0.05)
      ..lineTo(0.65, -0.25)
      ..lineTo(0.48, 0.65)
      ..lineTo(0.0, 0.78)
      ..close();
    _accentFillPaint.color = const Color(0xFF1DE9B6).withOpacity(0.90);
    canvas.drawPath(_facetPath, _accentFillPaint);

    // 5. Central Diamond Core Facet
    _facetPath.reset();
    _facetPath
      ..moveTo(0.0, -0.30)
      ..lineTo(0.24, 0.05)
      ..lineTo(0.0, 0.40)
      ..lineTo(-0.24, 0.05)
      ..close();
    _accentFillPaint.color = const Color(0xFFE0F2F1).withOpacity(0.75 * pulse);
    canvas.drawPath(_facetPath, _accentFillPaint);

    // Internal Plasma Energy Spark / Lightning Filaments
    final double sparkPhase = _animTime * 6.0;
    _accentStrokePaint
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 0.025
      ..strokeCap = StrokeCap.round;

    final pCenter = const Offset(0.0, 0.05);
    final pApex = Offset(0.04 * sin(sparkPhase), -0.55);
    final pLeft = Offset(-0.40 + 0.03 * cos(sparkPhase * 1.3), -0.15);
    final pRight = Offset(0.40 + 0.03 * sin(sparkPhase * 1.5), -0.15);
    final pBottom = Offset(0.03 * cos(sparkPhase), 0.60);

    canvas.drawLine(pCenter, pApex, _accentStrokePaint);
    canvas.drawLine(pCenter, pLeft, _accentStrokePaint);
    canvas.drawLine(pCenter, pRight, _accentStrokePaint);
    canvas.drawLine(pCenter, pBottom, _accentStrokePaint);

    // Glowing Central Spark Point
    _lightPaint.color = Colors.white;
    canvas.drawCircle(pCenter, 0.04 * pulse, _lightPaint);

    // Sharp Specular Facet Edge Highlights
    _accentStrokePaint
      ..color = const Color(0xFFA7FFEB).withOpacity(0.8)
      ..strokeWidth = 0.03;
    canvas.drawLine(const Offset(0.0, -0.72), const Offset(0.0, 0.78), _accentStrokePaint);
    canvas.drawLine(const Offset(-0.65, -0.25), const Offset(0.65, -0.25), _accentStrokePaint);

    // Magnetic Containment Cradle at Base
    _accentFillPaint.color = const Color(0xFF263238);
    _facetPath.reset();
    _facetPath
      ..moveTo(-0.60, 0.9)
      ..lineTo(0.60, 0.9)
      ..lineTo(0.45, 0.68)
      ..lineTo(-0.45, 0.68)
      ..close();
    canvas.drawPath(_facetPath, _accentFillPaint);

    // Glowing Rune / Power nodes on base clamp
    _lightPaint.color = glowColor;
    canvas.drawCircle(const Offset(-0.30, 0.80), 0.035, _lightPaint);
    canvas.drawCircle(const Offset(0.30, 0.80), 0.035, _lightPaint);

    // Hull Outer Glowing Shard Contour
    _hullStrokePaint
      ..color = glowColor
      ..strokeWidth = 0.06;
    canvas.drawPath(_capsulePath, _hullStrokePaint);

    // Top Containment Tow Hook Eyelet
    _hookPaint.color = glowColor;
    canvas.drawCircle(const Offset(0.0, -0.9), 0.12, _hookPaint);
  }
}
