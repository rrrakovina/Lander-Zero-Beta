import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import '../audio/game_audio_manager.dart';
import '../lander_zero_game.dart';
import '../state/game_state.dart';
import 'cargo_capsule.dart';
import 'coin.dart';
import 'fuel_pickup.dart';
import 'repair_pickup.dart';
import 'geyser.dart';
import 'stalactite.dart';
import 'magma_bubble.dart';
import 'rotating_debris.dart';
import 'endless_cargo_data.dart';

enum EndlessChunkType {
  startPad,
  rescueZone,
  hazardTransit,
  outpostStation,
  branchChasm,
  verticalShaft,
}

/// Registered platform location for seamless flat ground blending.
class EndlessPlatformInfo {
  final double x;
  final double y;
  final double halfWidth;

  const EndlessPlatformInfo({
    required this.x,
    required this.y,
    this.halfWidth = 4.5,
  });
}

/// Mathematical continuous procedural terrain generator with C1-continuity across chunks.
class EndlessTerrainGenerator {
  final List<EndlessPlatformInfo> platforms = [];

  void registerPlatform(double x, double y, [double halfWidth = 4.5]) {
    platforms.add(EndlessPlatformInfo(x: x, y: y, halfWidth: halfWidth));
  }

  void unregisterPlatformsBefore(double minX) {
    platforms.removeWhere((p) => p.x < minX);
  }

  void clear() {
    platforms.clear();
  }

  /// Calculates raw procedural floor height without platform leveling.
  double getRawFloorY(double x) {
    if (x < -20.0) {
      return -5.0; // Start Hangar Mesa
    }

    final double dist = max(0.0, x);
    final int biomeIdx = (dist / 400.0).floor() % 4;
    final double inBiomeX = dist % 400.0;

    double y0;
    switch (biomeIdx) {
      case 0: // Sector 1: Abandoned Mines
        y0 = 6.0 + 3.0 * sin(x * 0.08) + 1.8 * cos(x * 0.17) + 0.8 * sin(x * 0.35);
        break;
      case 1: // Sector 2: Crystal Grotto
        y0 = 4.5 + 4.0 * sin(x * 0.06) + 2.2 * cos(x * 0.12) + 0.6 * sin(x * 0.28);
        break;
      case 2: // Sector 3: Volcanic Fissure
        y0 = 7.5 + 5.0 * sin(x * 0.07) + 2.5 * cos(x * 0.15) + 1.2 * sin(x * 0.31);
        break;
      case 3: // Sector 4: Ancient Reactor
      default:
        y0 = 5.0 + 3.5 * sin(x * 0.05) + 2.0 * cos(x * 0.11) + 1.2 * sin(x * 0.25);
        break;
    }

    // Start Mesa transition from X in [-20.0, 0.0]
    if (x < 0.0) {
      final t = (x - (-20.0)) / 20.0;
      final smoothT = (1.0 - cos(t * pi)) / 2.0;
      return -5.0 * (1.0 - smoothT) + y0 * smoothT;
    }

    // Smooth blending across 40m biome transition zone
    if (inBiomeX > 360.0) {
      final nextBiomeIdx = (biomeIdx + 1) % 4;
      double y1;
      switch (nextBiomeIdx) {
        case 0:
          y1 = 6.0 + 3.0 * sin(x * 0.08) + 1.8 * cos(x * 0.17) + 0.8 * sin(x * 0.35);
          break;
        case 1:
          y1 = 4.5 + 4.0 * sin(x * 0.06) + 2.2 * cos(x * 0.12) + 0.6 * sin(x * 0.28);
          break;
        case 2:
          y1 = 7.5 + 5.0 * sin(x * 0.07) + 2.5 * cos(x * 0.15) + 1.2 * sin(x * 0.31);
          break;
        case 3:
        default:
          y1 = 5.0 + 3.5 * sin(x * 0.05) + 2.0 * cos(x * 0.11) + 1.2 * sin(x * 0.25);
          break;
      }
      final blendT = (inBiomeX - 360.0) / 40.0;
      final smoothBlend = (1.0 - cos(blendT * pi)) / 2.0;
      return y0 * (1.0 - smoothBlend) + y1 * smoothBlend;
    }

    return y0;
  }

  /// Calculates seamless floor height with smooth leveling at registered landing pads.
  double getFloorY(double x) {
    final rawY = getRawFloorY(x);

    for (final p in platforms) {
      final diff = (x - p.x).abs();
      if (diff <= p.halfWidth) {
        return p.y;
      } else if (diff <= p.halfWidth + 3.5) {
        // Smooth Hermite blend to platform
        final t = (diff - p.halfWidth) / 3.5;
        final smoothT = (1.0 - cos(t * pi)) / 2.0;
        return p.y * (1.0 - smoothT) + rawY * smoothT;
      }
    }

    return rawY;
  }

  /// Calculates raw procedural ceiling height.
  double getRawCeilingY(double x) {
    if (x < -20.0) {
      return -22.0; // Start Hangar Vault
    }

    final double dist = max(0.0, x);
    final int biomeIdx = (dist / 400.0).floor() % 4;
    final double inBiomeX = dist % 400.0;

    double y0;
    switch (biomeIdx) {
      case 0:
        y0 = -18.0 + 2.5 * cos(x * 0.09) - 1.5 * sin(x * 0.18);
        break;
      case 1:
        y0 = -21.0 + 3.5 * sin(x * 0.05) - 2.0 * cos(x * 0.11);
        break;
      case 2:
        y0 = -17.0 + 4.0 * cos(x * 0.08) - 2.0 * sin(x * 0.19);
        break;
      case 3:
      default:
        y0 = -23.0 + 3.0 * sin(x * 0.04) - 1.8 * cos(x * 0.13);
        break;
    }

    // Start Mesa transition from X in [-20.0, 0.0]
    if (x < 0.0) {
      final t = (x - (-20.0)) / 20.0;
      final smoothT = (1.0 - cos(t * pi)) / 2.0;
      return -22.0 * (1.0 - smoothT) + y0 * smoothT;
    }

    if (inBiomeX > 360.0) {
      final nextBiomeIdx = (biomeIdx + 1) % 4;
      double y1;
      switch (nextBiomeIdx) {
        case 0:
          y1 = -18.0 + 2.5 * cos(x * 0.09) - 1.5 * sin(x * 0.18);
          break;
        case 1:
          y1 = -21.0 + 3.5 * sin(x * 0.05) - 2.0 * cos(x * 0.11);
          break;
        case 2:
          y1 = -17.0 + 4.0 * cos(x * 0.08) - 2.0 * sin(x * 0.19);
          break;
        case 3:
        default:
          y1 = -23.0 + 3.0 * sin(x * 0.04) - 1.8 * cos(x * 0.13);
          break;
      }
      final blendT = (inBiomeX - 360.0) / 40.0;
      final smoothBlend = (1.0 - cos(blendT * pi)) / 2.0;
      return y0 * (1.0 - smoothBlend) + y1 * smoothBlend;
    }

    return y0;
  }

  /// Calculates ceiling height, guaranteeing at least 12m of flight clearance.
  double getCeilingY(double x) {
    final floorY = getFloorY(x);
    final rawCeil = getRawCeilingY(x);

    // Ensure generous clearance everywhere in endless exploration
    if (rawCeil >= floorY - 12.0) {
      return floorY - 12.0;
    }
    return rawCeil;
  }
}

/// Dynamic Forge2D Chunk Component owning independent Box2D ChainShape collision
/// fixtures and seamless multi-layer terrain rendering for a 48m sector.
class EndlessTerrainChunkComponent extends BodyComponent<LanderZeroGame> {
  final int index;
  final double startX;
  final double endX;
  final EndlessChunkType type;
  final Vector2? platformPos;
  final int biomeIndex;
  final EndlessTerrainGenerator generator;

  final List<Vector2> floorPoints = [];
  final List<Vector2> ceilingPoints = [];

  final Path _floorPath = Path();
  final Path _ceilingPath = Path();
  final Path _closedFloorPath = Path();
  final Path _closedCeilingPath = Path();

  final Paint _stoneFillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _soilPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.35
    ..strokeCap = StrokeCap.round;
  final Paint _crustGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.16
    ..strokeCap = StrokeCap.round;
  final Paint _platformPlinthPaint = Paint()
    ..color = const Color(0xFF212529)
    ..style = PaintingStyle.fill;
  final Paint _platformNeonPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.18;
  final Paint _platformStripePaint = Paint()
    ..color = const Color(0x99FFB300)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.08;

  EndlessTerrainChunkComponent({
    required this.index,
    required this.startX,
    required this.endX,
    required this.type,
    required this.biomeIndex,
    required this.generator,
    this.platformPos,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _configureBiomeStyling();
  }

  void _configureBiomeStyling() {
    Color stoneTop, stoneBottom, soilColor, crustColor;
    switch (biomeIndex) {
      case 1: // Crystal Grotto (Cyan)
        stoneTop = const Color(0xFF0F1E2E);
        stoneBottom = const Color(0xFF060B12);
        soilColor = const Color(0xFF1E394A);
        crustColor = const Color(0xFF00E5FF);
        break;
      case 2: // Volcanic Fissure (Molten Orange)
        stoneTop = const Color(0xFF28130E);
        stoneBottom = const Color(0xFF0F0705);
        soilColor = const Color(0xFF4E2C24);
        crustColor = const Color(0xFFFF5722);
        break;
      case 3: // Ancient Reactor (Neon Magenta)
        stoneTop = const Color(0xFF140F24);
        stoneBottom = const Color(0xFF07050E);
        soilColor = const Color(0xFF2E1A47);
        crustColor = const Color(0xFFE040FB);
        break;
      case 0: // Abandoned Mines (Amber)
      default:
        stoneTop = const Color(0xFF212529);
        stoneBottom = const Color(0xFF0A0C0D);
        soilColor = const Color(0xFF5D4037);
        crustColor = const Color(0xFFFFB300);
        break;
    }

    _stoneFillPaint.shader = LinearGradient(
      colors: [stoneTop, stoneBottom],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTRB(startX, -50.0, endX, 50.0));

    _soilPaint.color = soilColor;
    _crustGlowPaint.color = crustColor;
    _platformNeonPaint.color = crustColor;
  }

  @override
  Body createBody() {
    floorPoints.clear();
    ceilingPoints.clear();

    // Sample terrain geometry with high fidelity (dx ~ 1.2m)
    const double stepX = 1.2;
    final int steps = ((endX - startX) / stepX).ceil();

    final List<double> xSamples = [];
    for (int i = 0; i <= steps; i++) {
      final x = (startX + i * stepX).clamp(startX, endX);
      xSamples.add(x);
    }
    if (xSamples.last < endX) {
      xSamples.add(endX);
    }

    // Insert platform transition points for exact fidelity
    if (platformPos != null) {
      final px = platformPos!.x;
      xSamples.addAll([px - 4.5, px - 3.5, px, px + 3.5, px + 4.5]);
    }

    xSamples.sort();
    final List<double> uniqueXs = [];
    for (final x in xSamples) {
      if (uniqueXs.isEmpty || (x - uniqueXs.last).abs() > 0.05) {
        uniqueXs.add(x);
      }
    }

    for (final x in uniqueXs) {
      final fy = generator.getFloorY(x);
      final cy = generator.getCeilingY(x);
      floorPoints.add(Vector2(x, fy));
      ceilingPoints.add(Vector2(x, cy));
    }

    final bodyDef = BodyDef(
      type: BodyType.static,
      position: Vector2.zero(),
    );
    final body = world.createBody(bodyDef);

    final double friction = biomeIndex == 1 ? 0.08 : 0.80; // Low friction for ice crystals
    final double restitution = biomeIndex == 1 ? 0.25 : 0.05;

    // 1. Floor Box2D ChainShape fixture
    if (floorPoints.length >= 2) {
      final floorShape = ChainShape()..createChain(floorPoints);
      body.createFixture(
        FixtureDef(floorShape)
          ..friction = friction
          ..restitution = restitution,
      );
    }

    // 2. Ceiling Box2D ChainShape fixture
    if (ceilingPoints.length >= 2) {
      final ceilingShape = ChainShape()..createChain(ceilingPoints);
      body.createFixture(
        FixtureDef(ceilingShape)
          ..friction = (friction * 0.7).clamp(0.05, 0.6)
          ..restitution = restitution,
      );
    }

    // 3. Left entrance boundary wall ONLY on the very first starting chunk
    if (index == 0 && floorPoints.isNotEmpty && ceilingPoints.isNotEmpty) {
      final leftWall = EdgeShape()..set(
        Vector2(floorPoints.first.x, floorPoints.first.y),
        Vector2(ceilingPoints.first.x, ceilingPoints.first.y),
      );
      body.createFixture(
        FixtureDef(leftWall)
          ..friction = 0.5
          ..restitution = 0.2,
      );
    }

    return body;
  }

  @override
  void render(Canvas canvas) {
    if (floorPoints.isEmpty || ceilingPoints.isEmpty) return;

    // 1. Floor Bedrock Monolith Fill (continuous down to Y = 50.0)
    _floorPath.reset();
    _floorPath.moveTo(floorPoints.first.x, floorPoints.first.y);
    for (int i = 1; i < floorPoints.length; i++) {
      _floorPath.lineTo(floorPoints[i].x, floorPoints[i].y);
    }

    _closedFloorPath.reset();
    _closedFloorPath.addPath(_floorPath, Offset.zero);
    _closedFloorPath.lineTo(floorPoints.last.x, 50.0);
    _closedFloorPath.lineTo(floorPoints.first.x, 50.0);
    _closedFloorPath.close();

    canvas.drawPath(_closedFloorPath, _stoneFillPaint);

    // 2. Ceiling Bedrock Monolith Fill (continuous up to Y = -60.0)
    _ceilingPath.reset();
    _ceilingPath.moveTo(ceilingPoints.first.x, ceilingPoints.first.y);
    for (int i = 1; i < ceilingPoints.length; i++) {
      _ceilingPath.lineTo(ceilingPoints[i].x, ceilingPoints[i].y);
    }

    _closedCeilingPath.reset();
    _closedCeilingPath.addPath(_ceilingPath, Offset.zero);
    _closedCeilingPath.lineTo(ceilingPoints.last.x, -60.0);
    _closedCeilingPath.lineTo(ceilingPoints.first.x, -60.0);
    _closedCeilingPath.close();

    canvas.drawPath(_closedCeilingPath, _stoneFillPaint);

    // 3. Glowing Soil & Neon Crust Strokes
    canvas.drawPath(_floorPath, _soilPaint);
    canvas.drawPath(_floorPath, _crustGlowPaint);

    canvas.drawPath(_ceilingPath, _soilPaint);
    canvas.drawPath(_ceilingPath, _crustGlowPaint);

    // 4. Render Platform overlay if chunk contains an active landing pad
    if (platformPos != null) {
      final px = platformPos!.x;
      final py = platformPos!.y;
      final rect = Rect.fromLTRB(px - 4.5, py, px + 4.5, py + 0.6);
      canvas.drawRect(rect, _platformPlinthPaint);
      canvas.drawLine(Offset(px - 4.5, py), Offset(px + 4.5, py), _platformNeonPaint);

      for (double x = px - 4.2; x < px + 4.2; x += 0.8) {
        canvas.drawLine(Offset(x, py + 0.55), Offset(x + 0.4, py), _platformStripePaint);
      }
    }
  }
}

class EndlessChunk {
  final int index;
  final EndlessChunkType type;
  final double startX;
  final double endX;
  final Vector2? platformPos;
  final bool isOutpost;
  final bool hasSurvivor;
  final EndlessTerrainChunkComponent? terrainComponent;
  final List<Component> spawnedComponents = [];

  EndlessChunk({
    required this.index,
    required this.type,
    required this.startX,
    required this.endX,
    this.terrainComponent,
    this.platformPos,
    this.isOutpost = false,
    this.hasSurvivor = false,
  });
}

/// Outpost visual beacon tower component with animated glowing runway lights.
class OutpostBeacon extends PositionComponent with HasGameReference<LanderZeroGame> {
  final Vector2 padPosition;
  double _time = 0.0;

  OutpostBeacon({required this.padPosition}) : super(position: padPosition, size: Vector2(8.0, 3.0), anchor: Anchor.bottomCenter);

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Outpost Foundation Plinth
    final plinthPaint = Paint()..color = const Color(0xFF212529);
    final plinthBorder = Paint()..color = const Color(0xFF00E5FF)..style = PaintingStyle.stroke..strokeWidth = 0.08;
    final rect = Rect.fromCenter(center: const Offset(0, -0.2), width: 6.5, height: 0.5);
    canvas.drawRect(rect, plinthPaint);
    canvas.drawRect(rect, plinthBorder);

    // Hazard Stripes on Station Platform
    final stripePaint = Paint()..color = const Color(0xFFFFB300)..style = PaintingStyle.stroke..strokeWidth = 0.08;
    canvas.drawLine(const Offset(-2.8, -0.4), const Offset(-2.2, 0.0), stripePaint);
    canvas.drawLine(const Offset(-1.4, -0.4), const Offset(-0.8, 0.0), stripePaint);
    canvas.drawLine(const Offset(0.0, -0.4), const Offset(0.6, 0.0), stripePaint);
    canvas.drawLine(const Offset(1.4, -0.4), const Offset(2.0, 0.0), stripePaint);

    // Left and Right Illuminated Beacon Towers
    final pulse = (sin(_time * 4.0) + 1.0) / 2.0;
    final lightColor = Color.lerp(const Color(0xFF00E5FF), Colors.white, pulse)!;
    final beaconGlow = Paint()
      ..color = lightColor.withOpacity(0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.3);
    final beaconCore = Paint()..color = lightColor;

    // Left tower light
    canvas.drawCircle(const Offset(-3.2, -1.2), 0.35, beaconGlow);
    canvas.drawCircle(const Offset(-3.2, -1.2), 0.16, beaconCore);
    canvas.drawLine(const Offset(-3.2, 0.0), const Offset(-3.2, -1.2), Paint()..color = const Color(0xFF90A4AE)..strokeWidth = 0.08);

    // Right tower light
    canvas.drawCircle(const Offset(3.2, -1.2), 0.35, beaconGlow);
    canvas.drawCircle(const Offset(3.2, -1.2), 0.16, beaconCore);
    canvas.drawLine(const Offset(3.2, 0.0), const Offset(3.2, -1.2), Paint()..color = const Color(0xFF90A4AE)..strokeWidth = 0.08);
  }
}

/// Procedural Endless Cave Manager for infinite space rescue operations.
class EndlessCaveManager extends Component with HasGameReference<LanderZeroGame> {
  final List<EndlessChunk> _chunks = [];
  final EndlessTerrainGenerator generator = EndlessTerrainGenerator();

  int get activeChunksCount => _chunks.length;
  List<EndlessChunk> get activeChunks => List.unmodifiable(_chunks);

  int _nextChunkIndex = 0;
  double _lastGeneratedX = -40.0;
  final double _chunkLength = 48.0;

  int rescuesCount = 0;
  int _bonusScore = 0;

  int get endlessScore => (game.maxDistance * 10).toInt() + _bonusScore + (rescuesCount * 1000);

  EndlessCargoInfo? activeCargoInfo;
  Vector2? nextOutpostPos;
  Vector2? nextRescuePos;

  final Random _rand = Random(4242);

  double getFloorY(double x) => generator.getFloorY(x);
  double getCeilingY(double x) => generator.getCeilingY(x);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Register initial Start Pad platform at X = -28.0, Y = -5.0
    generator.registerPlatform(-28.0, -5.0, 5.0);

    // Generate initial 4 chunks ahead of player
    for (int i = 0; i < 4; i++) {
      _generateNextChunk();
    }
  }

  String getCurrentBiomeName(String lang) {
    final double dist = game.maxDistance;
    final int biomeCycle = ((dist / 400.0).floor()) % 4;
    final isRu = lang == 'ru';

    switch (biomeCycle) {
      case 0:
        return isRu ? 'Сектор 1: Заброшенные Шахты' : 'Sector 1: Abandoned Mines';
      case 1:
        return isRu ? 'Сектор 2: Кристаллический Грот' : 'Sector 2: Crystal Grotto';
      case 2:
        return isRu ? 'Сектор 3: Вулканический Разлом' : 'Sector 3: Volcanic Fissure';
      case 3:
      default:
        return isRu ? 'Сектор 4: Древний Реактор' : 'Sector 4: Ancient Reactor';
    }
  }

  int getBiomeIndexForDistance(double dist) {
    return (max(0.0, dist) / 400.0).floor() % 4;
  }

  void _generateNextChunk() {
    final startX = _lastGeneratedX;
    final endX = startX + _chunkLength;
    final index = _nextChunkIndex++;
    final double distanceMeters = max(0.0, startX);
    final int biomeIndex = getBiomeIndexForDistance(distanceMeters);

    EndlessChunkType type;
    Vector2? platformPos;
    bool isOutpost = false;
    bool hasSurvivor = false;
    final List<Component> spawnedEntities = [];

    if (index == 0) {
      type = EndlessChunkType.startPad;
      platformPos = Vector2(-28.0, -5.0);
    } else if (index % 4 == 1) {
      type = EndlessChunkType.rescueZone;
      hasSurvivor = true;
      final platX = startX + _chunkLength * 0.5;
      final rawFloorY = generator.getRawFloorY(platX);
      platformPos = Vector2(platX, rawFloorY);
      generator.registerPlatform(platX, rawFloorY, 4.5);

      // Generate bespoke procedural cargo capsule with rarity and modifiers
      final cargoInfo = EndlessCargoGenerator.generate(
        distanceMeters: distanceMeters,
        random: _rand,
        chunkIndex: index,
      );

      final capsule = CargoCapsule(
        initialPosition: Vector2(platX, platformPos.y - 0.95),
        type: cargoInfo.archetype,
        endlessInfo: cargoInfo,
      );
      game.world.add(capsule);
      spawnedEntities.add(capsule);

      nextRescuePos = platformPos;
    } else if (index % 4 == 2) {
      type = EndlessChunkType.hazardTransit;
      _spawnHazardsInChunk(startX, endX, index, biomeIndex, spawnedEntities);
    } else {
      type = EndlessChunkType.outpostStation;
      isOutpost = true;
      final platX = startX + _chunkLength * 0.5;
      final rawFloorY = generator.getRawFloorY(platX);
      platformPos = Vector2(platX, rawFloorY);
      generator.registerPlatform(platX, rawFloorY, 4.5);

      // Add visual beacon tower at outpost
      final beacon = OutpostBeacon(padPosition: platformPos);
      game.world.add(beacon);
      spawnedEntities.add(beacon);

      nextOutpostPos = platformPos;
    }

    // Spawn pickups along chunk
    _spawnPickupsInChunk(startX, endX, spawnedEntities);

    // Create independent Box2D Chunk Terrain Component
    final terrainComponent = EndlessTerrainChunkComponent(
      index: index,
      startX: startX,
      endX: endX,
      type: type,
      biomeIndex: biomeIndex,
      generator: generator,
      platformPos: platformPos,
    );
    game.world.add(terrainComponent);

    final chunk = EndlessChunk(
      index: index,
      type: type,
      startX: startX,
      endX: endX,
      terrainComponent: terrainComponent,
      platformPos: platformPos,
      isOutpost: isOutpost,
      hasSurvivor: hasSurvivor,
    );
    chunk.spawnedComponents.addAll(spawnedEntities);

    _chunks.add(chunk);
    _lastGeneratedX = endX;
  }

  void _spawnPickupsInChunk(double startX, double endX, List<Component> spawned) {
    for (double x = startX + 4.0; x < endX - 4.0; x += 4.5) {
      final floorY = generator.getFloorY(x);
      final ceilY = generator.getCeilingY(x);
      final midY = (floorY + ceilY) / 2.0 + (_rand.nextDouble() - 0.5) * 1.5;

      final coin = Coin(position: Vector2(x, midY));
      game.world.add(coin);
      spawned.add(coin);

      if (_rand.nextDouble() < 0.22) {
        final pickupY = floorY - 1.0 - _rand.nextDouble() * 2.0;
        if (_rand.nextBool()) {
          final fuel = FuelPickup(position: Vector2(x, pickupY));
          game.world.add(fuel);
          spawned.add(fuel);
        } else {
          final repair = RepairPickup(position: Vector2(x, pickupY));
          game.world.add(repair);
          spawned.add(repair);
        }
      }
    }
  }

  void _spawnHazardsInChunk(double startX, double endX, int chunkIdx, int biomeIndex, List<Component> spawned) {
    final double midX = (startX + endX) / 2.0;
    final double clearance = generator.getFloorY(midX) - generator.getCeilingY(midX);

    // Biome-specific hazard skin mapping
    String biomeSkin = 'echo';
    if (biomeIndex == 1) biomeSkin = 'ice';
    if (biomeIndex == 2) biomeSkin = 'core';
    if (biomeIndex == 3) biomeSkin = 'orbit';

    // 1. Dynamic ceiling stalactites
    final s1x = startX + 12.0;
    final s2x = startX + 28.0;
    final stal1 = Stalactite(initialPosition: Vector2(s1x, generator.getCeilingY(s1x) + 0.8), biome: biomeSkin);
    final stal2 = Stalactite(initialPosition: Vector2(s2x, generator.getCeilingY(s2x) + 0.8), biome: biomeSkin);
    game.world.add(stal1);
    game.world.add(stal2);
    spawned.add(stal1);
    spawned.add(stal2);

    // 2. Floor Geysers
    if (clearance > 12.0) {
      final geyser = Geyser(position: Vector2(midX, generator.getFloorY(midX)), biome: biomeSkin);
      game.world.add(geyser);
      spawned.add(geyser);
    }

    // 3. Volcanic magma bubbles (only in Sector 3 / Volcanic Fissures)
    if (biomeIndex == 2) {
      final bubble = MagmaBubble(minX: startX + 5.0, maxX: endX - 5.0);
      game.world.add(bubble);
      spawned.add(bubble);
    }

    // 4. Rotating orbital debris ONLY in wide reaction chambers of Sector 4 (clearance > 18.0m)
    if (biomeIndex == 3 && clearance > 18.0 && _rand.nextBool()) {
      final debrisY = (generator.getFloorY(startX + 20.0) + generator.getCeilingY(startX + 20.0)) / 2.0;
      final debris = RotatingDebris(
        initialPosition: Vector2(startX + 20.0, debrisY),
        width: 1.4,
        height: 4.0, // balanced size with room to maneuver around
        angularSpeed: 0.4,
        debrisType: 'module',
      );
      game.world.add(debris);
      spawned.add(debris);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    double landerX;
    try {
      landerX = game.lander.body.position.x;
    } catch (_) {
      return;
    }

    // 1. Generate new chunks ahead
    while (landerX + 90.0 > _lastGeneratedX) {
      _generateNextChunk();
    }

    // 2. Track currently tethered cargo
    if (game.rope != null && game.cargoCapsule.isMounted) {
      activeCargoInfo = game.cargoCapsule.endlessInfo;
    } else {
      activeCargoInfo = null;
    }

    // 3. Check outpost rescue delivery in endless mode
    if (game.rope != null && game.cargoCapsule.isMounted) {
      for (final chunk in _chunks) {
        if (chunk.isOutpost && chunk.platformPos != null) {
          final capsuleDist = game.cargoCapsule.body.position.distanceTo(chunk.platformPos!);
          final landerDist = game.lander.body.position.distanceTo(chunk.platformPos!);

          if (capsuleDist < 7.5 || landerDist < 4.5) {
            _deliverSurvivorAtOutpost(chunk);
            break;
          }
        }
      }
    }

    // 4. Memory Cleanup: Despawn old chunks 80m behind player for 60 FPS
    _cleanupPassedChunks(landerX);
  }

  void _deliverSurvivorAtOutpost(EndlessChunk outpost) {
    final info = game.cargoCapsule.endlessInfo;
    final int scoreAward = info?.totalScore ?? 1000;
    final int coinsAward = info?.totalCoins ?? 100;

    rescuesCount++;
    _bonusScore += scoreAward;
    game.coinsCollected += coinsAward;
    game.totalDamage = 0; // reset run damage penalty

    // Full Refuel & Repair lander at outpost
    game.lander.fuel = game.lander.maxFuel;
    game.lander.shield = game.lander.maxShield;

    // Play goal sound
    GameAudioManager().playSfx('victory.wav');

    final isRu = GameState().language == 'ru';
    final cargoName = info != null ? info.getTitle(GameState().language) : (isRu ? 'ВЫЖИВШИЙ' : 'SURVIVOR');
    game.triggerCustomAlert(
      isRu
          ? 'ГРУЗ $cargoName ЭВАКУИРОВАН! +$scoreAward ОЧКОВ // ПОЛНАЯ ДОЗАПРАВКА'
          : 'CARGO $cargoName DELIVERED! +$scoreAward PTS // FULL REFUEL',
      3.5,
    );

    // Release rope and remove delivered capsule
    game.world.remove(game.cargoCapsule);
    if (game.rope != null) {
      game.world.remove(game.rope!);
      game.rope = null;
    }
  }

  void _cleanupPassedChunks(double landerX) {
    generator.unregisterPlatformsBefore(landerX - 90.0);

    _chunks.removeWhere((chunk) {
      if (landerX - chunk.endX > 80.0) {
        if (chunk.terrainComponent != null && chunk.terrainComponent!.isMounted) {
          chunk.terrainComponent!.removeFromParent();
        }
        for (final comp in chunk.spawnedComponents) {
          if (comp.isMounted) {
            comp.removeFromParent();
          }
        }
        return true;
      }
      return false;
    });
  }
}