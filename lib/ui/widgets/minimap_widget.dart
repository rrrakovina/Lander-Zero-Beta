import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import '../../game/config/game_config.dart';
import '../../game/lander_zero_game.dart';
import '../../game/components/cave.dart';

/// Real-time tactical radar minimap widget rendering cave contours,
/// multi-chain branch ledges, perimeter beacons, player lander heading,
/// cargo capsule beacon, docking tether, and exit zone.
class MinimapWidget extends StatelessWidget {
  final LanderZeroGame game;
  final double width;
  final double height;

  const MinimapWidget({
    super.key,
    required this.game,
    this.width = 144.0,
    this.height = 92.0,
  });

  /// Calibrated radar world bounds covering all 5 planetary maps without clipping:
  /// X in [-36.0, 36.0] (Delta X = 72.0 m)
  /// Y in [-30.0, 24.0] (Delta Y = 54.0 m)
  static const double minWorldX = -36.0;
  static const double maxWorldX = 36.0;
  static const double minWorldY = -30.0;
  static const double maxWorldY = 24.0;

  /// Projects world horizontal coordinate (meters) to canvas X (pixels).
  static double projectX(double worldX, double canvasWidth) {
    return ((worldX - minWorldX) / (maxWorldX - minWorldX)) * canvasWidth;
  }

  /// Projects world vertical coordinate (meters) to canvas Y (pixels).
  static double projectY(double worldY, double canvasHeight) {
    return ((worldY - minWorldY) / (maxWorldY - minWorldY)) * canvasHeight;
  }

  /// Projects a 2D world position vector to a canvas [Offset].
  static Offset projectOffset(Vector2 worldPos, Size canvasSize) {
    return Offset(
      projectX(worldPos.x, canvasSize.width),
      projectY(worldPos.y, canvasSize.height),
    );
  }

  /// Calculates the lander heading offset vector given lander angle in radians.
  /// When angle is 0, vector points straight up (0, -length).
  static Offset calculateHeadingVector(double angle, [double length = 7.5]) {
    return Offset(sin(angle) * length, -cos(angle) * length);
  }

  /// Returns true if an active docking tether line connects the lander and cargo.
  static bool isTethered(LanderZeroGame game) {
    return game.rope != null;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: game.statsNotifier,
      builder: (context, stats, _) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xD90B101B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: GameConfig.colorPrimary.withOpacity(0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: GameConfig.colorPrimary.withOpacity(0.12),
                blurRadius: 6,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MinimapPainter(game: game),
                  ),
                ),
                Positioned(
                  top: 3,
                  left: 5,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'RADAR',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 7.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 3,
                  right: 5,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00E676),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 7.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MinimapPainter extends CustomPainter {
  final LanderZeroGame game;

  _MinimapPainter({required this.game});

  // Pre-allocated static Paint instances to guarantee zero GC pressure during 60fps flight
  static final Paint _gridPaint = Paint()
    ..color = const Color(0x1400E5FF)
    ..strokeWidth = 1.0;

  static final Paint _subgridPaint = Paint()
    ..color = const Color(0x0800E5FF)
    ..strokeWidth = 0.5;

  static final Paint _caveFloorPaint = Paint()
    ..color = const Color(0x9981D4FA)
    ..strokeWidth = 1.3
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static final Paint _caveCeilingPaint = Paint()
    ..color = const Color(0x5590CAF9)
    ..strokeWidth = 1.1
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static final Paint _branchPaint = Paint()
    ..color = const Color(0xCC00E5FF)
    ..strokeWidth = 1.4
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static final Paint _startPlatformPaint = Paint()
    ..color = const Color(0x99FFFFFF)
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round;

  static final Paint _startDotPaint = Paint()
    ..color = const Color(0x77FFFFFF)
    ..style = PaintingStyle.fill;

  static final Paint _exitPlatformPaint = Paint()
    ..color = const Color(0xFF00E676)
    ..style = PaintingStyle.fill;

  static final Paint _exitBracketPaint = Paint()
    ..color = const Color(0xFF00E676)
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  static final Paint _cargoPaint = Paint()
    ..color = GameConfig.colorWarning
    ..style = PaintingStyle.fill;

  static final Paint _cargoRingPaint = Paint()
    ..color = const Color(0x66FFB300)
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  static final Paint _landerPaint = Paint()
    ..color = GameConfig.colorPrimary
    ..style = PaintingStyle.fill;

  static final Paint _landerGlowPaint = Paint()
    ..color = const Color(0x8000E5FF)
    ..style = PaintingStyle.fill;

  static final Paint _headingPaint = Paint()
    ..color = Colors.white
    ..strokeWidth = 1.8
    ..strokeCap = StrokeCap.round;

  static final Paint _pulsePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  static final Paint _tetherPaint = Paint()
    ..color = const Color(0xFFFFD54F)
    ..strokeWidth = 1.4
    ..strokeCap = StrokeCap.round;

  static final Paint _beaconPaint = Paint()
    ..color = const Color(0xFFE040FB)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  static final Paint _beaconDotPaint = Paint()
    ..color = const Color(0xFFE040FB)
    ..style = PaintingStyle.fill;

  static final Paint _boundaryBorderPaint = Paint()
    ..color = const Color(0x33E040FB)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;

  // Cached Path objects for static cave terrain
  static final Path _cachedFloorPath = Path();
  static final Path _cachedCeilingPath = Path();
  static final Path _cachedBranchPath = Path();
  static Size _cachedSize = Size.zero;
  static Object? _cachedCaveIdentity;
  static int _cachedFloorLength = 0;
  static int _cachedCeilingLength = 0;
  static int _cachedBranchLength = 0;

  static void _updateCaveCache(Cave cave, Size size) {
    if (_cachedSize == size &&
        identical(_cachedCaveIdentity, cave) &&
        _cachedFloorLength == cave.floorPoints.length &&
        _cachedCeilingLength == cave.ceilingPoints.length &&
        _cachedBranchLength == cave.branchPoints.length &&
        cave.floorPoints.isNotEmpty) {
      return;
    }

    _cachedFloorPath.reset();
    _cachedCeilingPath.reset();
    _cachedBranchPath.reset();

    if (cave.floorPoints.isNotEmpty) {
      _cachedFloorPath.moveTo(
        MinimapWidget.projectX(cave.floorPoints.first.x, size.width),
        MinimapWidget.projectY(cave.floorPoints.first.y, size.height),
      );
      for (int i = 1; i < cave.floorPoints.length; i++) {
        _cachedFloorPath.lineTo(
          MinimapWidget.projectX(cave.floorPoints[i].x, size.width),
          MinimapWidget.projectY(cave.floorPoints[i].y, size.height),
        );
      }
    }

    if (cave.ceilingPoints.isNotEmpty) {
      _cachedCeilingPath.moveTo(
        MinimapWidget.projectX(cave.ceilingPoints.first.x, size.width),
        MinimapWidget.projectY(cave.ceilingPoints.first.y, size.height),
      );
      for (int i = 1; i < cave.ceilingPoints.length; i++) {
        _cachedCeilingPath.lineTo(
          MinimapWidget.projectX(cave.ceilingPoints[i].x, size.width),
          MinimapWidget.projectY(cave.ceilingPoints[i].y, size.height),
        );
      }
    }

    if (cave.branchPoints.isNotEmpty) {
      _cachedBranchPath.moveTo(
        MinimapWidget.projectX(cave.branchPoints.first.x, size.width),
        MinimapWidget.projectY(cave.branchPoints.first.y, size.height),
      );
      for (int i = 1; i < cave.branchPoints.length; i++) {
        _cachedBranchPath.lineTo(
          MinimapWidget.projectX(cave.branchPoints[i].x, size.width),
          MinimapWidget.projectY(cave.branchPoints[i].y, size.height),
        );
      }
    }

    _cachedSize = size;
    _cachedCaveIdentity = cave;
    _cachedFloorLength = cave.floorPoints.length;
    _cachedCeilingLength = cave.ceilingPoints.length;
    _cachedBranchLength = cave.branchPoints.length;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Radar coordinate grid
    final double midX = size.width / 2;
    final double midY = size.height / 2;

    // Subgrid lines
    canvas.drawLine(Offset(size.width * 0.25, 0), Offset(size.width * 0.25, size.height), _subgridPaint);
    canvas.drawLine(Offset(size.width * 0.75, 0), Offset(size.width * 0.75, size.height), _subgridPaint);
    canvas.drawLine(Offset(0, size.height * 0.25), Offset(size.width, size.height * 0.25), _subgridPaint);
    canvas.drawLine(Offset(0, size.height * 0.75), Offset(size.width, size.height * 0.75), _subgridPaint);

    // Primary crosshairs
    canvas.drawLine(Offset(midX, 0), Offset(midX, size.height), _gridPaint);
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), _gridPaint);

    if (!game.isLoaded) return;

    final isEndless = game.mapId == 'endless';
    if (isEndless) {
      _paintEndlessRadar(canvas, size);
    } else {
      _paintStaticStoryRadar(canvas, size);
    }
  }

  void _paintEndlessRadar(Canvas canvas, Size size) {
    final landerPos = game.lander.isMounted ? game.lander.body.position : Vector2.zero();
    final double minX = landerPos.x - 16.0;
    final double maxX = landerPos.x + 48.0;
    const double minY = -26.0;
    const double maxY = 18.0;

    double pX(double wx) => ((wx - minX) / (maxX - minX)) * size.width;
    double pY(double wy) => ((wy - minY) / (maxY - minY)) * size.height;

    // 1. Dynamic local terrain wireframe sampling
    final floorPath = Path();
    final ceilPath = Path();
    bool firstPoint = true;

    for (double x = minX; x <= maxX + 1.0; x += 1.8) {
      final fy = game.cave.getFloorY(x);
      final cy = game.cave.getCeilingY(x);
      final sx = pX(x);
      final sfy = pY(fy);
      final scy = pY(cy);

      if (firstPoint) {
        floorPath.moveTo(sx, sfy);
        ceilPath.moveTo(sx, scy);
        firstPoint = false;
      } else {
        floorPath.lineTo(sx, sfy);
        ceilPath.lineTo(sx, scy);
      }
    }

    canvas.drawPath(floorPath, _caveFloorPaint);
    canvas.drawPath(ceilPath, _caveCeilingPaint);

    // 2. Animated vertical radar scanline
    final double scanProgress = (DateTime.now().millisecondsSinceEpoch % 2000) / 2000.0;
    final double scanX = scanProgress * size.width;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0x0000E5FF),
          const Color(0x4400E5FF),
          const Color(0x0000E5FF),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(scanX - 2, 0, scanX + 2, size.height))
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(scanX, 0), Offset(scanX, size.height), scanPaint);

    // 3. Outpost Station Beacon & landing pad
    final outpostPos = game.endlessManager?.nextOutpostPos;
    if (outpostPos != null) {
      final double ox = pX(outpostPos.x);
      final double oy = pY(outpostPos.y);

      if (outpostPos.x >= minX - 5.0 && outpostPos.x <= maxX + 5.0) {
        // Outpost pad runway line
        final double padLeft = pX(outpostPos.x - 4.5);
        final double padRight = pX(outpostPos.x + 4.5);
        canvas.drawLine(Offset(padLeft, oy), Offset(padRight, oy), _exitPlatformPaint..strokeWidth = 2.5);

        // Pulsing Outpost beacon
        final double pulse = (sin(DateTime.now().millisecondsSinceEpoch * 0.005) + 1.0) / 2.0;
        final beaconColor = Color.lerp(const Color(0xFF00E5FF), const Color(0xFF00E676), pulse)!;
        canvas.drawCircle(Offset(ox, oy - 3), 3.0, Paint()..color = beaconColor);
        canvas.drawCircle(Offset(ox, oy - 3), 6.0 + pulse * 4.0, Paint()..color = beaconColor.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 1.0);
      }
    }

    // 4. Rescue Capsule Target Beacon
    if (game.cargoCapsule.isMounted) {
      final cargoPos = game.cargoCapsule.body.position;
      final double cx = pX(cargoPos.x);
      final double cy = pY(cargoPos.y);

      if (cargoPos.x >= minX - 10.0 && cargoPos.x <= maxX + 10.0) {
        canvas.drawCircle(Offset(cx, cy), 2.8, _cargoPaint);
        canvas.drawCircle(Offset(cx, cy), 5.5, _cargoRingPaint);
      }

      // Tether line if attached
      if (game.lander.isMounted && MinimapWidget.isTethered(game)) {
        final lx = pX(landerPos.x);
        final ly = pY(landerPos.y);
        canvas.drawLine(Offset(lx, ly), Offset(cx, cy), _tetherPaint);
      }
    }

    // 5. Player Lander Marker & Heading
    if (game.lander.isMounted) {
      final double lx = pX(landerPos.x);
      final double ly = pY(landerPos.y);

      // Radar pulse
      final double pulseProgress = (DateTime.now().millisecondsSinceEpoch % 1200) / 1200.0;
      final double pulseRadius = 3.5 + pulseProgress * 6.5;
      _pulsePaint.color = GameConfig.colorPrimary.withOpacity((1.0 - pulseProgress) * 0.7);
      canvas.drawCircle(Offset(lx, ly), pulseRadius, _pulsePaint);

      // Lander core
      canvas.drawCircle(Offset(lx, ly), 3.2, _landerPaint);
      canvas.drawCircle(Offset(lx, ly), 1.5, _landerGlowPaint);

      // Heading vector
      final double angle = game.lander.body.angle;
      final Offset heading = MinimapWidget.calculateHeadingVector(angle, 7.5);
      canvas.drawLine(
        Offset(lx, ly),
        Offset(lx + heading.dx, ly + heading.dy),
        _headingPaint,
      );
    }
  }

  void _paintStaticStoryRadar(Canvas canvas, Size size) {
    final cave = game.cave;
    if (!cave.isMounted) return;

    // 2. Wireframe cave contours (cached paths)
    _updateCaveCache(cave, size);
    if (_cachedFloorLength > 0) {
      canvas.drawPath(_cachedFloorPath, _caveFloorPaint);
    }
    if (_cachedCeilingLength > 0) {
      canvas.drawPath(_cachedCeilingPath, _caveCeilingPaint);
    }
    if (_cachedBranchLength > 0) {
      canvas.drawPath(_cachedBranchPath, _branchPaint);
    }

    // 3. Orbital Debris perimeter beacons and boundary lines
    if (cave.perimeterBeacons.length >= 4) {
      final p0 = MinimapWidget.projectOffset(cave.perimeterBeacons[0], size);
      final p2 = MinimapWidget.projectOffset(cave.perimeterBeacons[2], size);

      final boundaryRect = Rect.fromLTRB(p0.dx, p0.dy, p2.dx, p2.dy);
      canvas.drawRect(boundaryRect, _boundaryBorderPaint);

      for (final beacon in cave.perimeterBeacons) {
        final screenPos = MinimapWidget.projectOffset(beacon, size);
        canvas.drawCircle(screenPos, 2.0, _beaconDotPaint);
        canvas.drawCircle(screenPos, 4.0, _beaconPaint);
      }
    }

    // 4. Start platform marker
    final startPos = cave.startPlatform;
    final double startScreenX = MinimapWidget.projectX(startPos.x, size.width);
    final double startScreenY = MinimapWidget.projectY(startPos.y, size.height);
    canvas.drawLine(
      Offset(startScreenX - 4.0, startScreenY),
      Offset(startScreenX + 4.0, startScreenY),
      _startPlatformPaint,
    );
    canvas.drawCircle(Offset(startScreenX, startScreenY), 1.6, _startDotPaint);

    // 5. Exit extraction zone beacon & tactical brackets
    final exitPos = cave.exitPlatform;
    final double exitScreenX = MinimapWidget.projectX(exitPos.x, size.width);
    final double exitScreenY = MinimapWidget.projectY(exitPos.y, size.height);

    // Exit beacon core
    canvas.drawCircle(Offset(exitScreenX, exitScreenY), 2.5, _exitPlatformPaint);

    // Tactical HUD corner brackets around exit [ ]
    const double br = 5.5;
    const double bn = 2.2;
    // Top-left
    canvas.drawLine(Offset(exitScreenX - br, exitScreenY - br), Offset(exitScreenX - br + bn, exitScreenY - br), _exitBracketPaint);
    canvas.drawLine(Offset(exitScreenX - br, exitScreenY - br), Offset(exitScreenX - br, exitScreenY - br + bn), _exitBracketPaint);
    // Top-right
    canvas.drawLine(Offset(exitScreenX + br, exitScreenY - br), Offset(exitScreenX + br - bn, exitScreenY - br), _exitBracketPaint);
    canvas.drawLine(Offset(exitScreenX + br, exitScreenY - br), Offset(exitScreenX + br, exitScreenY - br + bn), _exitBracketPaint);
    // Bottom-left
    canvas.drawLine(Offset(exitScreenX - br, exitScreenY + br), Offset(exitScreenX - br + bn, exitScreenY + br), _exitBracketPaint);
    canvas.drawLine(Offset(exitScreenX - br, exitScreenY + br), Offset(exitScreenX - br, exitScreenY + br - bn), _exitBracketPaint);
    // Bottom-right
    canvas.drawLine(Offset(exitScreenX + br, exitScreenY + br), Offset(exitScreenX + br - bn, exitScreenY + br), _exitBracketPaint);
    canvas.drawLine(Offset(exitScreenX + br, exitScreenY + br), Offset(exitScreenX + br, exitScreenY + br - bn), _exitBracketPaint);

    // 6. Cargo capsule beacon
    double cargoScreenX = 0.0;
    double cargoScreenY = 0.0;
    bool hasCargoPos = false;

    if (game.cargoCapsule.isMounted) {
      final cargoPos = game.cargoCapsule.body.position;
      cargoScreenX = MinimapWidget.projectX(cargoPos.x, size.width);
      cargoScreenY = MinimapWidget.projectY(cargoPos.y, size.height);
      hasCargoPos = true;

      // Amber beacon dot and pulsing ring
      canvas.drawCircle(Offset(cargoScreenX, cargoScreenY), 2.8, _cargoPaint);
      canvas.drawCircle(Offset(cargoScreenX, cargoScreenY), 5.0, _cargoRingPaint);
    }

    // 7. Player lander, heading vector, and pulsating radar ring
    if (game.lander.isMounted) {
      final landerPos = game.lander.body.position;
      final double landerScreenX = MinimapWidget.projectX(landerPos.x, size.width);
      final double landerScreenY = MinimapWidget.projectY(landerPos.y, size.height);

      // Docking tether line connecting lander to cargo
      if (hasCargoPos && MinimapWidget.isTethered(game)) {
        canvas.drawLine(
          Offset(landerScreenX, landerScreenY),
          Offset(cargoScreenX, cargoScreenY),
          _tetherPaint,
        );
      }

      // Pulsating radar ring
      final double pulseProgress = (DateTime.now().millisecondsSinceEpoch % 1200) / 1200.0;
      final double pulseRadius = 3.5 + pulseProgress * 6.5;
      _pulsePaint.color = GameConfig.colorPrimary.withOpacity((1.0 - pulseProgress) * 0.7);
      canvas.drawCircle(Offset(landerScreenX, landerScreenY), pulseRadius, _pulsePaint);

      // Lander core marker
      canvas.drawCircle(Offset(landerScreenX, landerScreenY), 3.2, _landerPaint);
      canvas.drawCircle(Offset(landerScreenX, landerScreenY), 1.5, _landerGlowPaint);

      // Heading vector
      final double angle = game.lander.body.angle;
      final Offset heading = MinimapWidget.calculateHeadingVector(angle, 7.5);
      canvas.drawLine(
        Offset(landerScreenX, landerScreenY),
        Offset(landerScreenX + heading.dx, landerScreenY + heading.dy),
        _headingPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MinimapPainter oldDelegate) => true;
}
