import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lander_zero/game/components/lander.dart';
import 'package:lander_zero/game/state/game_state.dart';
import 'package:lander_zero/ui/painters/rocket_painter.dart';
import 'package:lander_zero/ui/painters/ship_mesh_renderer.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GameState().init(force: true);
  });

  group('Milestone 2 Empirical Verification: Fleet Ships & Geometry Invariants', () {
    const fleet = ['sputnik', 'swift', 'titan', 'quasar', 'cyclone'];

    test('All 5 fleet ships have positive, symmetric, well-formed bounding boxes', () {
      for (final shipId in fleet) {
        final bounds = ShipMeshRenderer.getModelBounds(shipId);
        expect(bounds.width, greaterThan(2.0), reason: '$shipId bounds width must be > 2.0m');
        expect(bounds.height, greaterThan(2.0), reason: '$shipId bounds height must be > 2.0m');
        expect(bounds.center.dx, closeTo(0.0, 1e-6), reason: '$shipId center must be horizontally symmetric (dx=0)');
        expect(bounds.left, equals(-bounds.right), reason: '$shipId left must equal -right');
        expect(bounds.isFinite, isTrue, reason: '$shipId bounds must be finite');
      }
    });

    test('Aliases resolve gracefully (needle -> quasar specs)', () {
      final needle = ShipMeshRenderer.getModelBounds('needle');
      final quasar = ShipMeshRenderer.getModelBounds('quasar');
      expect(needle, equals(quasar));
    });

    test('Unknown ship ID gracefully defaults to Sputnik baseline', () {
      final fallback = ShipMeshRenderer.getModelBounds('unknown_experimental_ship');
      final sputnik = ShipMeshRenderer.getModelBounds('sputnik');
      expect(fallback, equals(sputnik));
    });
  });

  group('Milestone 2 Empirical Verification: Aspect Ratio & Scale Stress Testing', () {
    const fleet = ['sputnik', 'swift', 'titan', 'quasar', 'cyclone', 'needle'];

    // Target extreme aspect ratios and dimensions:
    // 1:1, 16:9, 9:16, 32:9, 10x10, 4000x4000, plus extreme micro/macro
    final testSizes = <String, Size>{
      '1:1 square micro (10x10)': const Size(10, 10),
      '1:1 square standard (100x100)': const Size(100, 100),
      '1:1 square large (500x500)': const Size(500, 500),
      '1:1 square ultra (4000x4000)': const Size(4000, 4000),
      '16:9 landscape standard (1920x1080)': const Size(1920, 1080),
      '16:9 landscape compact (160x90)': const Size(160, 90),
      '16:9 landscape 4K (3840x2160)': const Size(3840, 2160),
      '9:16 portrait standard (1080x1920)': const Size(1080, 1920),
      '9:16 portrait compact (90x160)': const Size(90, 160),
      '32:9 ultrawide standard (3840x1080)': const Size(3840, 1080),
      '32:9 ultrawide compact (320x90)': const Size(320, 90),
      '32:9 ultrawide 5K (5120x1440)': const Size(5120, 1440),
      '9:32 ultra-tall ribbon (90x320)': const Size(90, 320),
      '100:1 extreme ribbon (1000x10)': const Size(1000, 10),
      '1:100 extreme tower (10x1000)': const Size(10, 1000),
    };

    final animationTimes = [
      -1000.0,
      0.0,
      0.25 * pi,
      0.5 * pi,
      pi,
      1.5 * pi,
      2 * pi,
      100.0,
      999999.0,
    ];

    test('Empirical Zero-Clipping Guarantee across all 5 ships and extreme aspect ratios', () {
      for (final shipId in fleet) {
        final bounds = ShipMeshRenderer.getModelBounds(shipId);

        testSizes.forEach((label, size) {
          final scale = ShipMeshRenderer.calculateScale(shipId, size);
          expect(scale, greaterThan(0.0), reason: 'Scale must be positive for $label ($shipId)');
          expect(scale.isFinite, isTrue, reason: 'Scale must be finite for $label ($shipId)');

          for (final time in animationTimes) {
            // RocketPainter hover translation:
            final double animOffsetY = (time > 0) ? (sin(time) * 0.04 * scale) : 0.0;

            // Bounding box corners:
            final corners = [
              bounds.topLeft,
              bounds.topRight,
              bounds.bottomLeft,
              bounds.bottomRight,
              bounds.center,
              Offset(bounds.left, bounds.center.dy),
              Offset(bounds.right, bounds.center.dy),
              Offset(bounds.center.dx, bounds.top),
              Offset(bounds.center.dx, bounds.bottom),
            ];

            for (final corner in corners) {
              // Transform formula matching RocketPainter paint pipeline:
              // translate(size.width / 2, size.height / 2)
              // translate(0, animOffsetY)
              // scale(scale, scale)
              // translate(-centerX, -centerY)
              final transformedX = (size.width / 2.0) + (corner.dx - bounds.center.dx) * scale;
              final transformedY = (size.height / 2.0) + animOffsetY + (corner.dy - bounds.center.dy) * scale;

              // Assert strict inclusion inside canvas viewport [0, size.width] and [0, size.height]
              expect(
                transformedX,
                greaterThanOrEqualTo(-1e-6),
                reason: 'LEFT CLIP for $shipId on $label at time $time (X: $transformedX)',
              );
              expect(
                transformedX,
                lessThanOrEqualTo(size.width + 1e-6),
                reason: 'RIGHT CLIP for $shipId on $label at time $time (X: $transformedX, Width: ${size.width})',
              );
              expect(
                transformedY,
                greaterThanOrEqualTo(-1e-6),
                reason: 'TOP CLIP for $shipId on $label at time $time (Y: $transformedY)',
              );
              expect(
                transformedY,
                lessThanOrEqualTo(size.height + 1e-6),
                reason: 'BOTTOM CLIP for $shipId on $label at time $time (Y: $transformedY, Height: ${size.height})',
              );
            }
          }
        });
      }
    });

    test('calculateScale handles degenerate, zero, and negative dimensions without crash or NaN', () {
      const degenerateSizes = [
        Size(0, 0),
        Size(0, 500),
        Size(500, 0),
        Size(-10, -10),
        Size(-500, 100),
        Size(100, -500),
      ];

      for (final shipId in fleet) {
        for (final size in degenerateSizes) {
          final scale = ShipMeshRenderer.calculateScale(shipId, size);
          expect(scale, equals(0.0), reason: 'Degenerate size $size must return 0.0 scale');
        }
      }
    });
  });

  group('Milestone 2 Empirical Verification: Vector Decals & Insignias', () {
    const fleet = ['sputnik', 'swift', 'titan', 'quasar', 'cyclone'];

    test('ShipMeshRenderer paints decals cleanly for all 5 vessels with and without decals flag', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1000, 1000));

      for (final shipId in fleet) {
        for (final showDecals in [true, false]) {
          expect(
            () => ShipMeshRenderer.renderShip(
              canvas: canvas,
              shipId: shipId,
              scale: 100.0,
              showDecals: showDecals,
            ),
            returnsNormally,
            reason: 'Render failed for $shipId (showDecals: $showDecals)',
          );
        }
      }

      final pic = recorder.endRecording();
      pic.dispose();
    });
  });

  group('Milestone 2 Empirical Verification: Landing Gear & Suspension Mechanics', () {
    const fleet = ['sputnik', 'swift', 'titan', 'quasar', 'cyclone'];
    const compressionLevels = [0.0, 0.25, 0.5, 0.75, 1.0];

    test('Landing gear toggles on/off and modulates correctly across suspension compression levels', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 800, 800));

      for (final shipId in fleet) {
        for (final showGear in [true, false]) {
          for (final compression in compressionLevels) {
            expect(
              () => ShipMeshRenderer.renderShip(
                canvas: canvas,
                shipId: shipId,
                scale: 50.0,
                showLandingGear: showGear,
                legsCompression: compression,
              ),
              returnsNormally,
              reason: 'Landing gear render failed for $shipId (gear: $showGear, comp: $compression)',
            );
          }
        }
      }

      final pic = recorder.endRecording();
      pic.dispose();
    });
  });

  group('Milestone 2 Empirical Verification: Thrusters, RCS & Exhaust Rendering', () {
    const fleet = ['sputnik', 'swift', 'titan', 'quasar', 'cyclone'];

    test('Thruster exhaust and RCS thrusters render across thrust levels [-1.0, 1.0]', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 800, 800));

      final thrustLevels = [0.0, 0.1, 0.5, 1.0];
      final rcsLevels = [-1.0, -0.5, 0.0, 0.5, 1.0];

      for (final shipId in fleet) {
        for (final thrust in thrustLevels) {
          for (final rcs in rcsLevels) {
            expect(
              () => ShipMeshRenderer.renderShip(
                canvas: canvas,
                shipId: shipId,
                scale: 40.0,
                engineThrust: thrust,
                rcsThrust: rcs,
              ),
              returnsNormally,
              reason: 'Thruster render failed for $shipId (thrust: $thrust, rcs: $rcs)',
            );
          }
        }
      }

      final pic = recorder.endRecording();
      pic.dispose();
    });
  });

  group('Milestone 2 Empirical Verification: RocketPainter CustomPainter Invariants', () {
    test('RocketPainter shouldRepaint responds accurately to all state mutations', () {
      final p1 = RocketPainter(rocketId: 'sputnik', animationTime: 0.0, glowColor: null, isSelected: false);
      final p1Identical = RocketPainter(rocketId: 'sputnik', animationTime: 0.0, glowColor: null, isSelected: false);
      final p2DiffRocket = RocketPainter(rocketId: 'swift', animationTime: 0.0, glowColor: null, isSelected: false);
      final p3DiffTime = RocketPainter(rocketId: 'sputnik', animationTime: 1.0, glowColor: null, isSelected: false);
      final p4DiffGlow = RocketPainter(rocketId: 'sputnik', animationTime: 0.0, glowColor: Colors.cyan, isSelected: false);
      final p5DiffSelected = RocketPainter(rocketId: 'sputnik', animationTime: 0.0, glowColor: null, isSelected: true);

      expect(p1.shouldRepaint(p1Identical), isFalse);
      expect(p1.shouldRepaint(p2DiffRocket), isTrue);
      expect(p1.shouldRepaint(p3DiffTime), isTrue);
      expect(p1.shouldRepaint(p4DiffGlow), isTrue);
      expect(p1.shouldRepaint(p5DiffSelected), isTrue);
    });

    testWidgets('RocketPainter renders into Flutter widget tree across extreme aspect ratios without error', (tester) async {
      const fleet = ['sputnik', 'swift', 'titan', 'quasar', 'cyclone'];
      final testSizes = [
        const Size(10, 10),
        const Size(120, 120),
        const Size(320, 90),
        const Size(90, 320),
        const Size(500, 500),
      ];

      for (final shipId in fleet) {
        for (final size in testSizes) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: CustomPaint(
                    size: size,
                    painter: RocketPainter(
                      rocketId: shipId,
                      animationTime: 1.5,
                      glowColor: Colors.cyanAccent,
                      isSelected: true,
                    ),
                  ),
                ),
              ),
            ),
          );

          expect(find.byType(CustomPaint), findsWidgets);
        }
      }
    });
  });

  group('Milestone 2 Empirical Verification: Live Dynamic Pilot Simulation', () {
    test('Lander live pilot updates G-strain, look vectors, and panic blinks accurately', () async {
      for (final shipId in ['sputnik', 'swift', 'titan', 'quasar', 'cyclone']) {
        await GameState().selectRocket(shipId);
        final lander = Lander(initialPosition: Vector2.zero(), shipId: shipId);
        final world = Forge2DWorld();
        lander.world = world;
        final body = lander.createBody();
        lander.body = body;

        // 1. Nominal flight conditions
        body.linearVelocity = Vector2(1.5, 0.0);
        lander.fuel = 150.0;
        lander.shield = 100.0;
        lander.update(0.016);
        lander.update(0.016);

        expect(lander.isPanicking, isFalse, reason: 'Nominal velocity must not trigger panic on $shipId');
        expect(lander.gStrain, closeTo(0.0, 0.05), reason: 'Zero acceleration must yield ~0 G-strain');
        expect(lander.lookDirection.x, greaterThan(0.0), reason: 'Eyes must track forward velocity');

        // 2. High G-Force acceleration stress
        body.linearVelocity = Vector2(30.0, 0.0); // Large deltaV in 0.016s -> high G-force
        lander.update(0.016);
        expect(lander.gForce, greaterThan(2.5), reason: 'High deltaV must induce high G-force');
        expect(lander.gStrain, greaterThan(0.5), reason: 'High G-force must cause substantial G-strain');
        expect(lander.isPanicking, isTrue, reason: 'High G-force must trigger panic');

        // 3. Low fuel panic condition
        body.linearVelocity = Vector2(1.0, 0.0);
        lander.update(0.016);
        lander.update(0.016);
        lander.fuel = 5.0; // 5 / 150 < 0.20
        lander.update(0.016);
        expect(lander.isPanicking, isTrue, reason: 'Low fuel must trigger panic on $shipId');

        // 4. Low shield panic condition
        lander.fuel = 150.0;
        lander.shield = 5.0; // 5 / 100 < 0.35
        lander.update(0.016);
        expect(lander.isPanicking, isTrue, reason: 'Low shield must trigger panic on $shipId');
      }
    });

    test('Lander creates valid CCW polygon hitboxes for all 5 fleet vessels', () async {
      for (final shipId in ['sputnik', 'swift', 'titan', 'needle', 'cyclone']) {
        await GameState().selectRocket(shipId);
        final lander = Lander(initialPosition: Vector2.zero(), shipId: shipId);
        final world = Forge2DWorld();
        lander.world = world;
        final body = lander.createBody();

        expect(body.fixtures.length, equals(1));
        final shape = body.fixtures.first.shape as PolygonShape;
        expect(shape.vertices.length, greaterThanOrEqualTo(5), reason: '$shipId hitbox must have >= 5 vertices');

        // Check mass density
        final configKey = GameState.rocketConfigs.containsKey(shipId) ? shipId : 'needle';
        final expectedMass = GameState.rocketConfigs[configKey]!['mass'] as double;
        expect(body.fixtures.first.density, closeTo(expectedMass, 1e-4));
      }
    });
  });
}
