import 'dart:math';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import '../lander_zero_game.dart';
import 'endless_cave_manager.dart';

class Cave extends BodyComponent {
  LanderZeroGame get gameRef => game as LanderZeroGame;
  final String mapId;
  final List<Vector2> floorPoints = [];
  final List<Vector2> ceilingPoints = [];
  final List<Vector2> branchPoints = [];
  final List<Vector2> perimeterBeacons = [];

  // Key platform coordinates
  late final Vector2 startPlatform;
  late final Vector2 cargoPlatform;
  late final Vector2 exitPlatform;

  // Biome physical properties
  double floorFriction = 0.80;
  double floorRestitution = 0.05;

  // Decoration indices
  final List<int> stalactiteIndices = [];
  final List<int> stalagmiteIndices = [];

  Cave({required this.mapId}) {
    if (mapId == 'wind') {
      startPlatform = Vector2(-28, -10);
      cargoPlatform = Vector2(2, 10);
      exitPlatform = Vector2(28, -10);
      floorFriction = 0.80;
      floorRestitution = 0.05;
    } else if (mapId == 'core') {
      startPlatform = Vector2(-14, -12);
      cargoPlatform = Vector2(0, 14);
      exitPlatform = Vector2(14, -12);
      floorFriction = 0.80;
      floorRestitution = 0.05;
    } else if (mapId == 'ice') {
      startPlatform = Vector2(-28, -4);
      cargoPlatform = Vector2(0, 8);
      exitPlatform = Vector2(26, -11);
      floorFriction = 0.08; // Ultra-low friction Europa ice
      floorRestitution = 0.25;
    } else if (mapId == 'orbit') {
      startPlatform = Vector2(-25, 0);
      cargoPlatform = Vector2(0, 0);
      exitPlatform = Vector2(25, 0);
      floorFriction = 0.10;
      floorRestitution = 0.35;
      perimeterBeacons.addAll([
        Vector2(-34, -26),
        Vector2(34, -26),
        Vector2(34, 14),
        Vector2(-34, 14),
      ]);
    } else {
      // echo / endless / default
      startPlatform = Vector2(-28, -5);
      cargoPlatform = Vector2(0, 8);
      exitPlatform = Vector2(25, -12);
      floorFriction = 0.80;
      floorRestitution = 0.05;
    }
  }

  /// Returns true if [pos] is situated inside a wind-shadow shelter pocket or trench
  bool isSheltered(Vector2 pos) {
    if (mapId != 'wind') return false;

    // 1. Low sheltered trench pocket containing cargo
    if (pos.x >= -2.0 && pos.x <= 7.0 && pos.y >= 5.0) {
      return true;
    }

    // 2. Behind Step 2 rock overhang
    if (pos.x >= -22.0 && pos.x <= -11.0 && pos.y >= -4.0) {
      return true;
    }

    // 3. Under Overhang 2 windbreaker
    if (pos.x >= -4.0 && pos.x <= 7.0 && pos.y >= -2.0) {
      return true;
    }

    return false;
  }

  // Pre-allocated static and cached Paint objects for zero GC pressure during 60 FPS flight
  final Paint _stoneFillPaint = Paint()
    ..color = const Color(0xFF1E2429)
    ..style = PaintingStyle.fill;

  final Paint _spikePaint = Paint()
    ..color = const Color(0xFF161A1D)
    ..style = PaintingStyle.fill;

  final Paint _spikeBorderPaint = Paint()
    ..color = const Color(0xFF37474F)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.05;

  final Paint _soilPaint = Paint()
    ..color = const Color(0xFF5D4037)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.35
    ..strokeCap = StrokeCap.round;

  final Paint _grassPaint = Paint()
    ..color = const Color(0xFFFF7043)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.12
    ..strokeCap = StrokeCap.round;

  final Paint _ceilingSoilPaint = Paint()
    ..color = const Color(0xFF4E342E)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.35
    ..strokeCap = StrokeCap.round;

  final Paint _ceilingTopPaint = Paint()
    ..color = const Color(0xFFFFB74D)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.12
    ..strokeCap = StrokeCap.round;

  final Paint _platformPaint = Paint()
    ..color = const Color(0xFF263238)
    ..style = PaintingStyle.fill;

  final Paint _linePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.18;

  final Paint _borderPaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.05;

  final Paint _glowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.4
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.2);

  final Paint _stripePaint = Paint()
    ..color = Colors.yellow.withOpacity(0.4)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.1;

  final Paint _branchBridgePaint = Paint()
    ..color = const Color(0xFF00E5FF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.35
    ..strokeCap = StrokeCap.round;

  final Paint _magmaPoolPaint = Paint()..style = PaintingStyle.fill;

  // Reusable Path objects
  final Path _floorPath = Path();
  final Path _ceilingPath = Path();
  final Path _closedFloorPath = Path();
  final Path _closedCeilingPath = Path();
  final Path _spikePath = Path();
  final Path _branchPath = Path();

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    if (mapId == 'core') {
      _stoneFillPaint.shader = const LinearGradient(
        colors: [Color(0xFF28130E), Color(0xFF0F0705)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(const Rect.fromLTRB(-70.0, -35.0, 50.0, 25.0));
      
      _soilPaint.color = const Color(0xFF4E2C24);
      _grassPaint.color = const Color(0xFFFF5722); // Molten magma crust
      
      _ceilingSoilPaint.color = const Color(0xFF3E1F1A);
      _ceilingTopPaint.color = const Color(0xFFFF7043);

      _spikePaint.color = const Color(0xFF22110D);
      _spikeBorderPaint.color = const Color(0xFFFF5722);

      _magmaPoolPaint.shader = const LinearGradient(
        colors: [Color(0xFFFFD54F), Color(0xFFFF5722), Color(0xFFD50000)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(const Rect.fromLTRB(-6.0, 13.5, 6.0, 16.0));
    } else if (mapId == 'wind') {
      _stoneFillPaint.shader = const LinearGradient(
        colors: [Color(0xFF14242A), Color(0xFF070E10)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(const Rect.fromLTRB(-70.0, -35.0, 50.0, 25.0));
      
      _soilPaint.color = const Color(0xFF37474F);
      _grassPaint.color = const Color(0xFFFFB300); // Amber windstorm crust
      
      _ceilingSoilPaint.color = const Color(0xFF263238);
      _ceilingTopPaint.color = const Color(0xFFFFD54F);

      _spikePaint.color = const Color(0xFF121E23);
      _spikeBorderPaint.color = const Color(0xFFFFB300);
    } else if (mapId == 'ice') {
      _stoneFillPaint.shader = const LinearGradient(
        colors: [Color(0xFF0F1E2E), Color(0xFF060B12)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(const Rect.fromLTRB(-70.0, -35.0, 50.0, 25.0));
      
      _soilPaint.color = const Color(0xFF1E394A);
      _grassPaint.color = const Color(0xFF00E5FF); // Neon cyan ice crust
      
      _ceilingSoilPaint.color = const Color(0xFF152634);
      _ceilingTopPaint.color = const Color(0xFF80D8FF);

      _spikePaint.color = const Color(0xFF102634);
      _spikeBorderPaint.color = const Color(0xFF00E5FF);
    } else if (mapId == 'orbit') {
      _stoneFillPaint.shader = const LinearGradient(
        colors: [Color(0xFF140F24), Color(0xFF07050E)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(const Rect.fromLTRB(-70.0, -35.0, 50.0, 25.0));
      
      _soilPaint.color = const Color(0xFF2E1A47);
      _grassPaint.color = const Color(0xFFE040FB); // Neon purple space boundary
      
      _ceilingSoilPaint.color = const Color(0xFF221338);
      _ceilingTopPaint.color = const Color(0xFFEA80FC);

      _spikePaint.color = const Color(0xFF1E1333);
      _spikeBorderPaint.color = const Color(0xFFE040FB);
    } else {
      // echo / default
      _stoneFillPaint.shader = const LinearGradient(
        colors: [Color(0xFF212529), Color(0xFF0A0C0D)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(const Rect.fromLTRB(-70.0, -35.0, 50.0, 25.0));
      
      _soilPaint.color = const Color(0xFF5D4037);
      _grassPaint.color = const Color(0xFFFFB300); // Amber crust
      
      _ceilingSoilPaint.color = const Color(0xFF4E342E);
      _ceilingTopPaint.color = const Color(0xFFFFD54F);

      _spikePaint.color = const Color(0xFF161A1D);
      _spikeBorderPaint.color = const Color(0xFF37474F);
    }
  }

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.static,
      position: Vector2.zero(),
    );

    final body = world.createBody(bodyDef);

    if (mapId == 'endless') {
      // In endless mode, terrain collision fixtures and rendering are managed dynamically per chunk
      return body;
    }

    _generateCaveGeometry();

    // 1. Floor collision chain
    final floorShape = ChainShape()..createChain(floorPoints);
    body.createFixture(
      FixtureDef(floorShape)
        ..friction = floorFriction
        ..restitution = floorRestitution,
    );

    // 2. Ceiling collision chain
    final ceilingShape = ChainShape()..createChain(ceilingPoints);
    body.createFixture(
      FixtureDef(ceilingShape)
        ..friction = (floorFriction * 0.7).clamp(0.05, 0.6)
        ..restitution = floorRestitution,
    );

    // 3. Side boundaries (left and right edges)
    final leftWall = EdgeShape()..set(
      Vector2(floorPoints.first.x, floorPoints.first.y),
      Vector2(ceilingPoints.first.x, ceilingPoints.first.y),
    );
    body.createFixture(
      FixtureDef(leftWall)
        ..friction = 0.5
        ..restitution = 0.2,
    );

    final rightWall = EdgeShape()..set(
      Vector2(floorPoints.last.x, floorPoints.last.y),
      Vector2(ceilingPoints.last.x, ceilingPoints.last.y),
    );
    body.createFixture(
      FixtureDef(rightWall)
        ..friction = 0.5
        ..restitution = 0.2,
    );

    // 4. Intermediate Upper Branch Ledge for Europa Ice Rift
    if (branchPoints.isNotEmpty) {
      final branchShape = ChainShape()..createChain(branchPoints);
      body.createFixture(
        FixtureDef(branchShape)
          ..friction = floorFriction
          ..restitution = floorRestitution,
      );
    }

    return body;
  }

  void _generateCaveGeometry() {
    floorPoints.clear();
    ceilingPoints.clear();
    branchPoints.clear();
    stalactiteIndices.clear();
    stalagmiteIndices.clear();

    final random = Random(12345);
    const int resolution = 100;
    const double startX = -70.0;
    const double endX = 50.0;
    const double stepX = (endX - startX) / resolution;

    if (mapId == 'echo') {
      _generateEchoGeometry(resolution, startX, stepX, random);
    } else if (mapId == 'core') {
      _generateCoreGeometry(resolution, startX, stepX, random);
    } else if (mapId == 'wind') {
      _generateWindGeometry(resolution, startX, stepX, random);
    } else if (mapId == 'ice') {
      _generateIceGeometry(resolution, startX, stepX, random);
    } else if (mapId == 'orbit') {
      _generateOrbitGeometry(resolution, startX, stepX, random);
    } else {
      // Endless or fallback
      _generateEchoGeometry(resolution, startX, stepX, random);
    }
  }

  void _generateEchoGeometry(int resolution, double startX, double stepX, Random random) {
    for (int i = 0; i <= resolution; i++) {
      final x = startX + i * stepX;
      double floorY = 5.0;
      double ceilingY = -22.0;

      // Floor profile: High launch mesa -> rolling ridge -> valley cargo -> ascending terrace -> exit hangar
      if (x < -32.5) {
        floorY = -5.0;
      } else if (x <= -23.5) {
        floorY = -5.0; // Start platform (-28.0, -5.0)
      } else if (x < -12.0) {
        // Rolling limestone ridge cresting at x = -18, y = -2.0
        final t = (x - (-23.5)) / ((-12.0) - (-23.5));
        floorY = -5.0 + 3.0 * sin(t * pi) + (t * 3.0);
      } else if (x < -4.5) {
        // Slope down into valley
        final t = (x - (-12.0)) / ((-4.5) - (-12.0));
        floorY = -2.0 + t * 10.0; // drops from -2 to 8
      } else if (x <= 4.5) {
        floorY = 8.0; // Cargo valley floor (0.0, 8.0)
      } else if (x < 14.0) {
        // Ascending hill
        final t = (x - 4.5) / (14.0 - 4.5);
        floorY = 8.0 - t * 11.0; // rises from 8 to -3
      } else if (x < 20.5) {
        // Upper terrace
        final t = (x - 14.0) / (20.5 - 14.0);
        floorY = -3.0 - t * 9.0; // rises from -3 to -12
      } else if (x <= 29.5) {
        floorY = -12.0; // Exit platform (25.0, -12.0)
      } else {
        floorY = -12.0;
      }

      // Add minor organic rock noise (outside flat platforms)
      final bool onPlatform = (x - startPlatform.x).abs() < 4.5 ||
                              (x - cargoPlatform.x).abs() < 5.5 ||
                              (x - exitPlatform.x).abs() < 4.5;
      if (!onPlatform) {
        floorY += (random.nextDouble() - 0.5) * 0.6;
      }

      // Ceiling profile
      if (x < 10.0) {
        ceilingY = -20.0 + 2.0 * sin(x * 0.12) - 1.5 * cos(x * 0.08);
      } else {
        // Opening up over elevated exit hangar for generous clearance
        ceilingY = -26.0 + 1.0 * sin(x * 0.1);
      }

      if (ceilingY >= floorY - 8.5) {
        ceilingY = floorY - 8.5;
      }

      floorPoints.add(Vector2(x, floorY));
      ceilingPoints.add(Vector2(x, ceilingY));

      if (i > 3 && i < resolution - 3 && !onPlatform) {
        if (random.nextDouble() < 0.12) {
          if (random.nextBool()) {
            stalactiteIndices.add(i);
          } else {
            stalagmiteIndices.add(i);
          }
        }
      }
    }
  }

  void _generateCoreGeometry(int resolution, double startX, double stepX, Random random) {
    for (int i = 0; i <= resolution; i++) {
      final x = startX + i * stepX;
      double floorY = -12.0;
      double ceilingY = -26.0;

      // Pure vertical volcanic chimney geometry:
      // High top-left surface plateau (Start at -14, -12) -> vertical drop wall -> magma floor (0, 14) -> vertical climb wall -> top-right surface plateau (Exit at 14, -12)
      if (x < -6.5) {
        floorY = -12.0; // Left surface plateau
      } else if (x < -4.5) {
        // Vertical chimney left wall plunge
        final t = (x - (-6.5)) / ((-4.5) - (-6.5));
        floorY = -12.0 + t * 26.0; // -12 -> 14
      } else if (x <= 4.5) {
        floorY = 14.0; // Molten magma pedestal (0.0, 14.0)
      } else if (x < 6.5) {
        // Vertical chimney right wall ascent
        final t = (x - 4.5) / (6.5 - 4.5);
        floorY = 14.0 - t * 26.0; // 14 -> -12
      } else {
        floorY = -12.0; // Right surface plateau (Exit at 14, -12)
      }

      final bool onPlatform = (x - startPlatform.x).abs() < 4.5 ||
                              (x - cargoPlatform.x).abs() < 4.0 ||
                              (x - exitPlatform.x).abs() < 4.5;
      if (!onPlatform && (x < -6.5 || x > 6.5)) {
        floorY += (random.nextDouble() - 0.5) * 0.4;
      }

      ceilingY = -26.0 + 1.2 * sin(x * 0.1);

      if (ceilingY >= floorY - 8.5) {
        ceilingY = floorY - 8.5;
      }

      floorPoints.add(Vector2(x, floorY));
      ceilingPoints.add(Vector2(x, ceilingY));

      if (i > 3 && i < resolution - 3 && !onPlatform) {
        if (random.nextDouble() < 0.15) {
          stalactiteIndices.add(i);
        }
      }
    }
  }

  void _generateWindGeometry(int resolution, double startX, double stepX, Random random) {
    for (int i = 0; i <= resolution; i++) {
      final x = startX + i * stepX;
      double floorY = -10.0;
      double ceilingY = -23.0;

      // 7 Stepped Terraces:
      // Step 1: [-36, -23.5] -> Y = -10.0 (Start -28, -10)
      // Step 2: [-22, -12.0] -> Y = -2.0 (Shelter Alcove)
      // Step 3: [-10.5, -2.0] -> Y = 4.0
      // Step 4: [-1.0, 5.5]   -> Y = 10.0 (Cargo Trench 2, 10)
      // Step 5: [7.5, 16.0]   -> Y = 3.0
      // Step 6: [17.5, 23.5]  -> Y = -3.0
      // Step 7: [24.5, 36.0]  -> Y = -10.0 (Exit 28, -10)
      if (x < -23.5) {
        floorY = -10.0;
      } else if (x < -22.0) {
        final t = (x - (-23.5)) / 1.5;
        floorY = -10.0 + t * 8.0;
      } else if (x <= -12.0) {
        floorY = -2.0;
      } else if (x < -10.5) {
        final t = (x - (-12.0)) / 1.5;
        floorY = -2.0 + t * 6.0;
      } else if (x <= -2.0) {
        floorY = 4.0;
      } else if (x < -1.0) {
        final t = (x - (-2.0)) / 1.0;
        floorY = 4.0 + t * 6.0;
      } else if (x <= 5.5) {
        floorY = 10.0; // Sheltered Cargo Trench
      } else if (x < 7.5) {
        final t = (x - 5.5) / 2.0;
        floorY = 10.0 - t * 7.0;
      } else if (x <= 16.0) {
        floorY = 3.0;
      } else if (x < 17.5) {
        final t = (x - 16.0) / 1.5;
        floorY = 3.0 - t * 6.0;
      } else if (x <= 23.5) {
        floorY = -3.0;
      } else if (x < 24.5) {
        final t = (x - 23.5) / 1.0;
        floorY = -3.0 - t * 7.0;
      } else {
        floorY = -10.0;
      }

      // Ceiling with rock overhangs creating wind shadow
      if (x >= -18.0 && x <= -11.0) {
        // Overhang 1
        final t = sin(((x - (-18.0)) / 7.0) * pi);
        ceilingY = -22.0 + t * 8.0; // dips to -14.0
      } else if (x >= -3.0 && x <= 6.0) {
        // Overhang 2 over cargo trench
        final t = sin(((x - (-3.0)) / 9.0) * pi);
        ceilingY = -20.0 + t * 14.0; // dips to -6.0
      } else {
        ceilingY = -23.0 + 1.5 * sin(x * 0.15);
      }

      if (ceilingY >= floorY - 8.5) {
        ceilingY = floorY - 8.5;
      }

      floorPoints.add(Vector2(x, floorY));
      ceilingPoints.add(Vector2(x, ceilingY));

      final bool onPlatform = (x - startPlatform.x).abs() < 4.5 ||
                              (x - cargoPlatform.x).abs() < 4.5 ||
                              (x - exitPlatform.x).abs() < 4.5;
      if (i > 3 && i < resolution - 3 && !onPlatform && random.nextDouble() < 0.14) {
        stalactiteIndices.add(i);
      }
    }
  }

  void _generateIceGeometry(int resolution, double startX, double stepX, Random random) {
    for (int i = 0; i <= resolution; i++) {
      final x = startX + i * stepX;
      double floorY = -4.0;
      double ceilingY = -18.0;

      // Lower path: Sliding ice ramp descending to sunken cargo cavern (0, 8) then ascending to exit (26, -11)
      if (x < -23.5) {
        floorY = -4.0; // Start platform (-28, -4)
      } else if (x < -4.0) {
        // Sliding ramp descending from -4 to 8
        final t = (x - (-23.5)) / ((-4.0) - (-23.5));
        floorY = -4.0 + t * 12.0;
      } else if (x <= 4.0) {
        floorY = 8.0; // Sunken cargo cavern floor (0, 8)
      } else if (x < 21.0) {
        // Cryo tunnel ascent
        final t = (x - 4.0) / (21.0 - 4.0);
        floorY = 8.0 - t * 19.0; // 8 -> -11
      } else {
        floorY = -11.0; // Exit platform (26, -11)
      }

      // Ceiling: Low ceiling over upper path ($Y = -7.0$), opening over cargo dome ($Y = -18.0$)
      if (x < -24.0) {
        ceilingY = -18.0;
      } else if (x < -4.0) {
        ceilingY = -7.0; // Low headroom above upper branch ledge
      } else if (x <= 4.0) {
        ceilingY = -18.0; // High cavern dome above cargo
      } else if (x < 21.0) {
        final t = (x - 4.0) / (21.0 - 4.0);
        ceilingY = -16.0 - t * 8.0; // -16 -> -24
      } else {
        ceilingY = -24.0;
      }

      if (ceilingY >= floorY - 7.5) {
        ceilingY = floorY - 7.5;
      }

      floorPoints.add(Vector2(x, floorY));
      ceilingPoints.add(Vector2(x, ceilingY));

      final bool onPlatform = (x - startPlatform.x).abs() < 4.5 ||
                              (x - cargoPlatform.x).abs() < 4.5 ||
                              (x - exitPlatform.x).abs() < 4.5;
      if (i > 3 && i < resolution - 3 && !onPlatform && random.nextDouble() < 0.18) {
        stalactiteIndices.add(i);
      }
    }

    // Generate Upper Branch Ledge Points (x in [-22.0, -3.0], y around -1.0)
    branchPoints.clear();
    const int branchRes = 20;
    const double bStartX = -22.0;
    const double bEndX = -3.0;
    const double bStepX = (bEndX - bStartX) / branchRes;
    for (int j = 0; j <= branchRes; j++) {
      final bx = bStartX + j * bStepX;
      final by = -1.2 + 0.3 * sin(bx * 0.3);
      branchPoints.add(Vector2(bx, by));
    }
  }

  void _generateOrbitGeometry(int resolution, double startX, double stepX, Random random) {
    for (int i = 0; i <= resolution; i++) {
      final x = startX + i * stepX;
      // Open space containment boundaries at Y = +20.0 and Y = -28.0
      final floorY = 20.0;
      final ceilingY = -28.0;

      floorPoints.add(Vector2(x, floorY));
      ceilingPoints.add(Vector2(x, ceilingY));
    }
  }

  @override
  void render(Canvas canvas) {
    if (mapId == 'endless') return;
    if (floorPoints.isEmpty || ceilingPoints.isEmpty) return;

    final double camX = gameRef.camera.viewfinder.position.x;
    final double zoom = gameRef.camera.viewfinder.zoom;
    final double viewWidth = gameRef.size.x / zoom;
    final double leftX = camX - viewWidth / 2 - 4.0;
    final double rightX = camX + viewWidth / 2 + 4.0;

    int startIdx = 0;
    int endIdx = floorPoints.length - 1;

    for (int i = 0; i < floorPoints.length; i++) {
      if (floorPoints[i].x < leftX) {
        startIdx = i;
      } else {
        break;
      }
    }

    for (int i = floorPoints.length - 1; i >= 0; i--) {
      if (floorPoints[i].x > rightX) {
        endIdx = i;
      } else {
        break;
      }
    }

    if (startIdx >= endIdx) return;

    final List<Vector2> visibleFloor = floorPoints.sublist(startIdx, endIdx + 1);
    final List<Vector2> visibleCeiling = ceilingPoints.sublist(startIdx, endIdx + 1);

    // 1. Terrain Rock / Bedrock Background Fills
    _floorPath.reset();
    _floorPath.moveTo(visibleFloor.first.x, visibleFloor.first.y);
    for (int i = 1; i < visibleFloor.length; i++) {
      _floorPath.lineTo(visibleFloor[i].x, visibleFloor[i].y);
    }
    
    _closedFloorPath.reset();
    _closedFloorPath.addPath(_floorPath, Offset.zero);
    _closedFloorPath.lineTo(visibleFloor.last.x, 40.0);
    _closedFloorPath.lineTo(visibleFloor.first.x, 40.0);
    _closedFloorPath.close();

    canvas.drawPath(_closedFloorPath, _stoneFillPaint);

    _ceilingPath.reset();
    _ceilingPath.moveTo(visibleCeiling.first.x, visibleCeiling.first.y);
    for (int i = 1; i < visibleCeiling.length; i++) {
      _ceilingPath.lineTo(visibleCeiling[i].x, visibleCeiling[i].y);
    }

    _closedCeilingPath.reset();
    _closedCeilingPath.addPath(_ceilingPath, Offset.zero);
    _closedCeilingPath.lineTo(visibleCeiling.last.x, -50.0);
    _closedCeilingPath.lineTo(visibleCeiling.first.x, -50.0);
    _closedCeilingPath.close();

    canvas.drawPath(_closedCeilingPath, _stoneFillPaint);

    // 2. Magma pool glow in Deep Core
    if (mapId == 'core') {
      final magmaRect = const Rect.fromLTRB(-5.0, 13.8, 5.0, 16.0);
      canvas.drawRect(magmaRect, _magmaPoolPaint);
    }

    // 3. Stalactites & Stalagmites
    for (final index in stalactiteIndices) {
      if (index < ceilingPoints.length) {
        final p = ceilingPoints[index];
        if (p.x >= leftX - 2.0 && p.x <= rightX + 2.0) {
          _spikePath.reset();
          _spikePath.moveTo(p.x - 0.6, p.y);
          _spikePath.lineTo(p.x + 0.6, p.y);
          _spikePath.lineTo(p.x, p.y + 1.8 + sin(p.x) * 0.4);
          _spikePath.close();
          canvas.drawPath(_spikePath, _spikePaint);
          canvas.drawPath(_spikePath, _spikeBorderPaint);
        }
      }
    }

    for (final index in stalagmiteIndices) {
      if (index < floorPoints.length) {
        final p = floorPoints[index];
        if (p.x >= leftX - 2.0 && p.x <= rightX + 2.0) {
          _spikePath.reset();
          _spikePath.moveTo(p.x - 0.6, p.y);
          _spikePath.lineTo(p.x + 0.6, p.y);
          _spikePath.lineTo(p.x, p.y - 1.8 - cos(p.x) * 0.4);
          _spikePath.close();
          canvas.drawPath(_spikePath, _spikePaint);
          canvas.drawPath(_spikePath, _spikeBorderPaint);
        }
      }
    }

    // 4. Glowing Terrain Outlines
    canvas.drawPath(_floorPath, _soilPaint);
    canvas.drawPath(_floorPath, _grassPaint);

    canvas.drawPath(_ceilingPath, _ceilingSoilPaint);
    canvas.drawPath(_ceilingPath, _ceilingTopPaint);

    // 5. Draw Upper Branch Ledge in Europa Ice Rift
    if (mapId == 'ice' && branchPoints.isNotEmpty) {
      _branchPath.reset();
      _branchPath.moveTo(branchPoints.first.x, branchPoints.first.y);
      for (int i = 1; i < branchPoints.length; i++) {
        _branchPath.lineTo(branchPoints[i].x, branchPoints[i].y);
      }
      canvas.drawPath(_branchPath, _branchBridgePaint);

      // Ice bridge depth
      final bridgeDepthPaint = Paint()
        ..color = const Color(0x6600B0FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6;
      canvas.drawPath(_branchPath, bridgeDepthPaint);
    }

    // 6. Draw Perimeter Forcefield in Orbital Debris
    if (mapId == 'orbit' && perimeterBeacons.isNotEmpty) {
      final beaconPaint = Paint()
        ..color = const Color(0xFFE040FB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.15;
      final beaconDot = Paint()
        ..color = const Color(0xFFE040FB)
        ..style = PaintingStyle.fill;

      for (final b in perimeterBeacons) {
        canvas.drawCircle(Offset(b.x, b.y), 0.5, beaconDot);
        canvas.drawCircle(Offset(b.x, b.y), 1.2, beaconPaint);
      }
    }

    // 7. Platforms Overlays
    final platformNeon = mapId == 'ice'
        ? const Color(0xFF00E5FF)
        : (mapId == 'orbit'
            ? const Color(0xFFE040FB)
            : (mapId == 'core' ? const Color(0xFFFF5722) : Colors.blueAccent));

    if (mapId != 'endless') {
      if (startPlatform.x >= leftX - 6.0 && startPlatform.x <= rightX + 6.0) {
        _drawPlatformOverlay(canvas, startPlatform, 4.5, platformNeon);
      }
      if (cargoPlatform.x >= leftX - 7.0 && cargoPlatform.x <= rightX + 7.0) {
        _drawPlatformOverlay(canvas, cargoPlatform, 5.5, Colors.greenAccent);
      }
      if (exitPlatform.x >= leftX - 6.0 && exitPlatform.x <= rightX + 6.0) {
        _drawPlatformOverlay(canvas, exitPlatform, 4.5, Colors.orangeAccent);
      }
    }
  }

  void _drawPlatformOverlay(Canvas canvas, Vector2 platformCenter, double halfWidth, Color neonColor) {
    _linePaint.color = neonColor;
    _glowPaint.color = neonColor.withOpacity(0.4);

    canvas.drawLine(
      Offset(platformCenter.x - halfWidth, platformCenter.y),
      Offset(platformCenter.x + halfWidth, platformCenter.y),
      _glowPaint,
    );

    final rect = Rect.fromLTRB(
      platformCenter.x - halfWidth,
      platformCenter.y,
      platformCenter.x + halfWidth,
      platformCenter.y + 0.6,
    );

    canvas.drawRect(rect, _platformPaint);
    canvas.drawRect(rect, _borderPaint);
    canvas.drawLine(
      Offset(platformCenter.x - halfWidth, platformCenter.y),
      Offset(platformCenter.x + halfWidth, platformCenter.y),
      _linePaint,
    );

    for (double x = platformCenter.x - halfWidth + 0.4; x < platformCenter.x + halfWidth; x += 0.8) {
      canvas.drawLine(
        Offset(x, platformCenter.y + 0.6),
        Offset(x + 0.4, platformCenter.y),
        _stripePaint,
      );
    }
  }

  double _getYFromPoints(List<Vector2> points, double x) {
    if (points.isEmpty) return 0.0;
    if (x <= points.first.x) return points.first.y;
    if (x >= points.last.x) return points.last.y;

    int lo = 0, hi = points.length - 1;
    while (lo < hi - 1) {
      final mid = (lo + hi) ~/ 2;
      if (points[mid].x <= x) {
        lo = mid;
      } else {
        hi = mid;
      }
    }

    final p0 = points[lo];
    final p1 = points[hi];
    final t = (x - p0.x) / (p1.x - p0.x);
    return p0.y + (p1.y - p0.y) * t;
  }

  double getFloorY(double x) {
    if (mapId == 'endless') {
      try {
        final em = gameRef.endlessManager;
        if (em != null) {
          return em.getFloorY(x);
        }
      } catch (_) {}
      return EndlessTerrainGenerator().getFloorY(x);
    }
    return _getYFromPoints(floorPoints, x);
  }

  double getCeilingY(double x) {
    if (mapId == 'endless') {
      try {
        final em = gameRef.endlessManager;
        if (em != null) {
          return em.getCeilingY(x);
        }
      } catch (_) {}
      return EndlessTerrainGenerator().getCeilingY(x);
    }
    return _getYFromPoints(ceilingPoints, x);
  }
}
