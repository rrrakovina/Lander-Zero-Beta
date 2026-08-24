import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:lander_zero/ui/painters/rocket_painter.dart';
import 'package:lander_zero/ui/widgets/minimap_widget.dart';
import 'package:lander_zero/game/lander_zero_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adversarial Challenge 1: RocketPainter Extreme Geometry & Bounds Containment', () {
    const rocketModels = ['sputnik', 'cyclone', 'needle', 'unknown_model'];
    const extremeSizes = [
      Size(10, 10),
      Size(500, 500),
      Size(10, 500),
      Size(500, 10),
      Size(1, 1),
      Size(1000, 1),
      Size(1, 1000),
      Size(10000, 10000),
      Size(0, 0),
      Size(0, 500),
      Size(500, 0),
      Size(-50, -50),
    ];
    const extremeAnimationTimes = [
      -1000000.0,
      -100.0,
      -1.0,
      0.0,
      0.0001,
      0.5,
      1.0,
      pi,
      2 * pi,
      100.0,
      1000000.0,
    ];

    test('All rocket models have strictly positive finite bounding boxes', () {
      for (final model in ['sputnik', 'cyclone', 'needle']) {
        final bounds = RocketPainter.getBounds(model);
        expect(bounds.width, greaterThan(0.0), reason: '$model width must be positive');
        expect(bounds.height, greaterThan(0.0), reason: '$model height must be positive');
        expect(bounds.isFinite, isTrue, reason: '$model bounds must be finite');
        expect(bounds.center.dx, equals(0.0), reason: '$model must be horizontally symmetric at center X = 0');
      }
    });

    test('calculateScale handles degenerate, zero, and extreme sizes without NaN or Inf', () {
      for (final model in rocketModels) {
        for (final size in extremeSizes) {
          final scale = RocketPainter.calculateScale(model, size);
          expect(scale.isFinite, isTrue, reason: 'Scale for $model at $size must be finite');
          expect(scale.isNaN, isFalse, reason: 'Scale for $model at $size must not be NaN');

          if (size.width <= 0 || size.height <= 0) {
            expect(scale, equals(0.0), reason: 'Scale for non-positive size must be 0.0');
          } else {
            expect(scale, greaterThan(0.0), reason: 'Scale for positive size must be > 0.0');
          }
        }
      }
    });

    test('Empirical containment: Transformed bounding box stays strictly within canvas bounds', () {
      final validSizes = extremeSizes.where((s) => s.width > 0 && s.height > 0).toList();

      for (final model in ['sputnik', 'cyclone', 'needle']) {
        final bounds = RocketPainter.getBounds(model);

        for (final size in validSizes) {
          final scale = RocketPainter.calculateScale(model, size);

          for (final time in extremeAnimationTimes) {
            final double animOffsetY = (time > 0) ? (sin(time) * 0.04 * scale) : 0.0;

            // Transform all 4 corners of the model's bounding box
            final corners = [
              bounds.topLeft,
              bounds.topRight,
              bounds.bottomLeft,
              bounds.bottomRight,
            ];

            for (final corner in corners) {
              // Exact transformation executed by RocketPainter:
              // 1. translate(-centerX, -centerY)
              // 2. scale(scale, scale)
              // 3. translate(0, animOffsetY)
              // 4. translate(size.width / 2, size.height / 2)
              final centeredX = (corner.dx - bounds.center.dx) * scale;
              final centeredY = (corner.dy - bounds.center.dy) * scale;

              final screenX = (size.width / 2) + centeredX;
              final screenY = (size.height / 2) + animOffsetY + centeredY;

              // Assert strict containment within [0, size.width] and [0, size.height]
              expect(
                screenX,
                greaterThanOrEqualTo(-1e-6),
                reason: 'Left clipping for $model at size $size, time $time (screenX: $screenX)',
              );
              expect(
                screenX,
                lessThanOrEqualTo(size.width + 1e-6),
                reason: 'Right clipping for $model at size $size, time $time (screenX: $screenX, max: ${size.width})',
              );
              expect(
                screenY,
                greaterThanOrEqualTo(-1e-6),
                reason: 'Top clipping for $model at size $size, time $time (screenY: $screenY)',
              );
              expect(
                screenY,
                lessThanOrEqualTo(size.height + 1e-6),
                reason: 'Bottom clipping for $model at size $size, time $time (screenY: $screenY, max: ${size.height})',
              );
            }
          }
        }
      }
    });

    test('Canvas paint execution survives all extreme sizes, times, and models without exceptions', () {
      for (final model in rocketModels) {
        for (final size in extremeSizes) {
          for (final time in [-10.0, 0.0, 1.0, 100.0]) {
            for (final isSelected in [false, true]) {
              final painter = RocketPainter(
                rocketId: model,
                animationTime: time,
                glowColor: isSelected ? Colors.cyan : null,
                isSelected: isSelected,
              );

              final recorder = ui.PictureRecorder();
              final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, max(0.0, size.width), max(0.0, size.height)));

              expect(
                () => painter.paint(canvas, size),
                returnsNormally,
                reason: 'painter.paint must not throw for $model, size $size, time $time',
              );

              final picture = recorder.endRecording();
              picture.dispose();
            }
          }
        }
      }
    });

    testWidgets('Widget rendering stress test across rapid animations and resizes', (tester) async {
      for (final model in ['sputnik', 'cyclone', 'needle']) {
        double animTime = 0.0;
        Size currentSize = const Size(120, 120);

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: CustomPaint(
                      size: currentSize,
                      painter: RocketPainter(
                        rocketId: model,
                        animationTime: animTime,
                        glowColor: Colors.amber,
                        isSelected: true,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );

        expect(find.byType(CustomPaint), findsWidgets);

        // Rapidly advance frames
        for (int step = 0; step < 20; step++) {
          animTime += 0.2;
          await tester.pump(const Duration(milliseconds: 16));
        }
      }
    });
  });

  group('Adversarial Challenge 2: MinimapWidget Math, Extreme Boundary & Out-of-Bounds Coords', () {
    const double width = 144.0;
    const double height = 92.0;

    test('Minimap projection exact linearity verification across all X coordinates', () {
      const deltaX = MinimapWidget.maxWorldX - MinimapWidget.minWorldX;
      expect(deltaX, equals(72.0));

      // Test 1000 equidistant sample points across [-72.0, 72.0]
      for (int i = 0; i <= 1000; i++) {
        final worldX = -72.0 + (144.0 * i / 1000);
        final projected = MinimapWidget.projectX(worldX, width);

        final expected = ((worldX - (-36.0)) / 72.0) * width;
        expect(projected, closeTo(expected, 1e-10));
      }
    });

    test('Minimap projection exact linearity verification across all Y coordinates', () {
      const deltaY = MinimapWidget.maxWorldY - MinimapWidget.minWorldY;
      expect(deltaY, equals(46.0));

      // Test 1000 equidistant sample points across [-60.0, 40.0]
      for (int i = 0; i <= 1000; i++) {
        final worldY = -60.0 + (100.0 * i / 1000);
        final projected = MinimapWidget.projectY(worldY, height);

        final expected = ((worldY - (-30.0)) / 46.0) * height;
        expect(projected, closeTo(expected, 1e-10));
      }
    });

    test('Minimap projection boundary and out-of-bounds coordinate behavior', () {
      // Left boundary X = -36.0 -> 0
      expect(MinimapWidget.projectX(-36.0, width), equals(0.0));
      // Right boundary X = +36.0 -> width
      expect(MinimapWidget.projectX(36.0, width), equals(width));
      // Top boundary Y = -30.0 -> 0
      expect(MinimapWidget.projectY(-30.0, height), equals(0.0));
      // Bottom boundary Y = +16.0 -> height
      expect(MinimapWidget.projectY(16.0, height), equals(height));

      // Out of bounds values extrapolate linearly without clamping bugs
      expect(MinimapWidget.projectX(-72.0, width), equals(-width * 0.5));
      expect(MinimapWidget.projectX(72.0, width), equals(width * 1.5));
      expect(MinimapWidget.projectY(-76.0, height), equals(-height));
      expect(MinimapWidget.projectY(62.0, height), equals(height * 2.0));
    });

    test('Lander heading trigonometry vector invariant norm test across full circle & extremes', () {
      const double testLength = 8.5;

      // Sample 3600 angles around the circle
      for (int deg = 0; deg < 3600; deg++) {
        final rad = deg * (pi / 1800);
        final heading = MinimapWidget.calculateHeadingVector(rad, testLength);

        // Vector magnitude must equal testLength exactly
        final magnitude = sqrt(heading.dx * heading.dx + heading.dy * heading.dy);
        expect(magnitude, closeTo(testLength, 1e-9), reason: 'Magnitude at rad $rad must be $testLength');
      }

      // Extreme angular rotations (hundreds of revolutions)
      final extremeAngles = [
        -1000 * pi,
        -100 * pi,
        -50.5 * pi,
        -2 * pi,
        -pi,
        -pi / 2,
        0.0,
        pi / 2,
        pi,
        2 * pi,
        50.5 * pi,
        100 * pi,
        1000 * pi,
      ];

      for (final angle in extremeAngles) {
        final heading = MinimapWidget.calculateHeadingVector(angle, testLength);
        final magnitude = sqrt(heading.dx * heading.dx + heading.dy * heading.dy);
        expect(magnitude, closeTo(testLength, 1e-9));
        expect(heading.dx.isFinite, isTrue);
        expect(heading.dy.isFinite, isTrue);
      }
    });

    test('Minimap projectOffset handles zero and extreme vector coords', () {
      const size = Size(200.0, 100.0);

      final origin = MinimapWidget.projectOffset(Vector2(0, 0), size);
      expect(origin.dx, closeTo((36.0 / 72.0) * 200.0, 1e-9)); // 100.0
      expect(origin.dy, closeTo((30.0 / 46.0) * 100.0, 1e-9)); // ~65.217

      final cornerMin = MinimapWidget.projectOffset(Vector2(-36.0, -30.0), size);
      expect(cornerMin.dx, equals(0.0));
      expect(cornerMin.dy, equals(0.0));

      final cornerMax = MinimapWidget.projectOffset(Vector2(36.0, 16.0), size);
      expect(cornerMax.dx, equals(200.0));
      expect(cornerMax.dy, equals(100.0));
    });
  });

  group('Adversarial Challenge 3: MinimapWidget Dynamic State, Tethering & Multi-Map Robustness', () {
    testWidgets('MinimapWidget mounts and renders cleanly across Echo, Wind, and Core maps', (tester) async {
      for (final mapId in ['echo', 'wind', 'core']) {
        final game = LanderZeroGame(mapId: mapId);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MinimapWidget(
                game: game,
                width: 144.0,
                height: 92.0,
              ),
            ),
          ),
        );

        expect(find.text('RADAR'), findsOneWidget);
        expect(find.text('LIVE'), findsOneWidget);
        expect(find.byType(MinimapWidget), findsOneWidget);

        // Verify tether check function
        expect(MinimapWidget.isTethered(game), isFalse);
      }
    });

    testWidgets('MinimapWidget dynamic stats stress test (100 rapid sequential updates)', (tester) async {
      final game = LanderZeroGame(mapId: 'echo');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MinimapWidget(
              game: game,
              width: 144.0,
              height: 92.0,
            ),
          ),
        ),
      );

      for (int i = 0; i < 100; i++) {
        game.statsNotifier.value = {
          'coins': i,
          'distance': 100.0 - i,
          'fuel': (100 - i) / 100.0,
          'maxFuel': 1.0,
          'shield': (100 - (i % 20)) / 100.0,
          'maxShield': 1.0,
          'hasRope': (i % 2 == 0),
          'alert': i % 10 == 0 ? 'CRITICAL PROXIMITY' : null,
        };
        await tester.pump(const Duration(milliseconds: 10));
      }

      expect(find.byType(MinimapWidget), findsOneWidget);
    });

    testWidgets('MinimapWidget dynamic dimension resizing stress test', (tester) async {
      final game = LanderZeroGame(mapId: 'wind');

      final sizes = [
        const Size(144.0, 92.0),
        const Size(288.0, 184.0),
        const Size(72.0, 46.0),
        const Size(200.0, 100.0),
        const Size(100.0, 200.0),
        const Size(300.0, 80.0),
      ];

      for (final size in sizes) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MinimapWidget(
                game: game,
                width: size.width,
                height: size.height,
              ),
            ),
          ),
        );

        final RenderBox renderBox = tester.renderObject(find.byType(MinimapWidget));
        expect(renderBox.size.width, equals(size.width));
        expect(renderBox.size.height, equals(size.height));
      }
    });
  });
}
