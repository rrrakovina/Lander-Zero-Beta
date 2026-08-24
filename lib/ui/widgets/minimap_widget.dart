import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import '../../game/config/game_config.dart';
import '../../game/lander_zero_game.dart';
import '../../game/components/cave.dart';

/// Real-time tactical radar minimap widget rendering cave contours,
/// player lander heading, cargo capsule beacon, docking tether, and exit zone.
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

  /// Calibrated radar world bounds covering all planetary caves with margin:
  /// X in [-36.0, 36.0] (Delta X = 72.0 m)
  /// Y in [-30.0, 16.0] (Delta Y = 46.0 m)
  static const double minWorldX = -36.0;
  static const double maxWorldX = 36.0;
  static const double minWorldY = -30.0;
  static const double maxWorldY = 16.0;

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

  // Cached Path objects for static cave terrain
  static final Path _cachedFloorPath = Path();
  static final Path _cachedCeilingPath = Path();
  static Size _cachedSize = Size.zero;
  static Object? _cachedCaveIdentity;
  static int _cachedFloorLength = 0;
  static int _cachedCeilingLength = 0;

  static void _updateCaveCache(Cave cave, Size size) {
    if (_cachedSize == size &&
        identical(_cachedCaveIdentity, cave) &&
        _cachedFloorLength == cave.floorPoints.length &&
        _cachedCeilingLength == cave.ceilingPoints.length &&
        cave.floorPoints.isNotEmpty) {
      return;
    }

    _cachedFloorPath.reset();
    _cachedCeilingPath.reset();

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

    _cachedSize = size;
    _cachedCaveIdentity = cave;
    _cachedFloorLength = cave.floorPoints.length;
    _cachedCeilingLength = cave.ceilingPoints.length;
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

    // 3. Start platform marker
    final startPos = cave.startPlatform;
    final double startScreenX = MinimapWidget.projectX(startPos.x, size.width);
    final double startScreenY = MinimapWidget.projectY(startPos.y, size.height);
    canvas.drawLine(
      Offset(startScreenX - 4.0, startScreenY),
      Offset(startScreenX + 4.0, startScreenY),
      _startPlatformPaint,
    );
    canvas.drawCircle(Offset(startScreenX, startScreenY), 1.6, _startDotPaint);

    // 4. Exit extraction zone beacon & tactical brackets
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

    // 5. Cargo capsule beacon
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

    // 6. Player lander, heading vector, and pulsating radar ring
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
