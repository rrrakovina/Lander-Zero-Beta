import 'dart:ui' as ui;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lander_zero/game/components/lander.dart';
import 'package:lander_zero/game/state/game_state.dart';
import 'package:lander_zero/ui/painters/ship_mesh_renderer.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GameState().init(force: true);
  });

  group('ShipMeshRenderer Vector Bounds & Scale Tests', () {
    const ships = ['sputnik', 'swift', 'titan', 'quasar', 'needle', 'cyclone'];

    test('All 5 fleet ships have accurate, positive, symmetric bounding boxes', () {
      for (final shipId in ships) {
        final bounds = ShipMeshRenderer.getModelBounds(shipId);
        expect(bounds.width, greaterThan(2.0), reason: '$shipId width must be > 2.0');
        expect(bounds.height, greaterThan(2.0), reason: '$shipId height must be > 2.0');
        expect(bounds.isFinite, isTrue);
        expect(bounds.center.dx, equals(0.0), reason: '$shipId must be symmetric on X axis');
      }

      // Sputnik specs: 3.30 x 2.60
      final sputnik = ShipMeshRenderer.getModelBounds('sputnik');
      expect(sputnik.width, equals(3.30));
      expect(sputnik.height, equals(2.60));

      // Cyclone specs: 4.40 x 2.95
      final cyclone = ShipMeshRenderer.getModelBounds('cyclone');
      expect(cyclone.width, equals(4.40));
      expect(cyclone.height, equals(2.95));

      // Titan specs: 4.40 x 2.95
      final titan = ShipMeshRenderer.getModelBounds('titan');
      expect(titan.width, equals(4.40));
      expect(titan.height, equals(2.95));

      // Swift specs: 2.90 x 3.05
      final swift = ShipMeshRenderer.getModelBounds('swift');
      expect(swift.width, equals(2.90));
      expect(swift.height, equals(3.05));

      // Quasar specs: 2.90 x 3.05
      final quasar = ShipMeshRenderer.getModelBounds('quasar');
      expect(quasar.width, equals(2.90));
      expect(quasar.height, equals(3.05));
    });

    test('calculateScale guarantees containment and handles degenerate canvas sizes', () {
      expect(ShipMeshRenderer.calculateScale('sputnik', Size.zero), equals(0.0));
      expect(ShipMeshRenderer.calculateScale('swift', const Size(-100, 100)), equals(0.0));
      expect(ShipMeshRenderer.calculateScale('titan', const Size(100, -100)), equals(0.0));

      const testSizes = [
        Size(80, 80),
        Size(120, 120),
        Size(240, 160),
        Size(160, 240),
        Size(500, 500),
      ];

      for (final shipId in ships) {
        for (final size in testSizes) {
          final scale = ShipMeshRenderer.calculateScale(shipId, size);
          final bounds = ShipMeshRenderer.getModelBounds(shipId);
          final renderedW = bounds.width * scale;
          final renderedH = bounds.height * scale;

          expect(renderedW, lessThanOrEqualTo(size.width));
          expect(renderedH, lessThanOrEqualTo(size.height));
        }
      }
    });
  });

  group('ShipMeshRenderer Comprehensive Rendering Tests', () {
    const ships = ['sputnik', 'swift', 'titan', 'quasar', 'needle', 'cyclone'];

    test('Canvas paints all 5 ships with varied thruster, landing gear, and decal states without exceptions', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 400, 400));

      for (final shipId in ships) {
        for (final showDecals in [true, false]) {
          for (final showGear in [true, false]) {
            for (final engineThrust in [0.0, 0.5, 1.0]) {
              for (final rcsThrust in [-1.0, 0.0, 1.0]) {
                expect(
                  () => ShipMeshRenderer.renderShip(
                    canvas: canvas,
                    shipId: shipId,
                    scale: 1.0,
                    engineThrust: engineThrust,
                    rcsThrust: rcsThrust,
                    pilotHeadOffset: Vector2(0.05, -0.05),
                    pilotLookDirection: Vector2(0.5, -0.5),
                    pilotGStrain: 0.5,
                    isPanicking: false,
                    isBlinking: false,
                    showLandingGear: showGear,
                    animationTime: 1.5,
                    legsCompression: 0.2,
                    showDecals: showDecals,
                  ),
                  returnsNormally,
                  reason: 'renderShip failed for $shipId (decals: $showDecals, gear: $showGear)',
                );
              }
            }
          }
        }
      }

      final pic = recorder.endRecording();
      pic.dispose();
    });

    test('Live Astronaut dynamic simulation states paint cleanly across G-force, look angles, and panic flutter', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 400, 400));

      final testGStrains = [0.0, 0.25, 0.5, 0.75, 1.0];
      final testLookVectors = [
        Vector2.zero(),
        Vector2(1.0, 0.0),   // Looking full right
        Vector2(-1.0, 0.0),  // Looking full left
        Vector2(0.0, 1.0),   // Looking down at hazard
        Vector2(0.0, -1.0),  // Looking up at ceiling
        Vector2(0.707, 0.707),
      ];

      for (final shipId in ships) {
        for (final gStrain in testGStrains) {
          for (final lookVec in testLookVectors) {
            for (final panicking in [false, true]) {
              for (final blinking in [false, true]) {
                expect(
                  () => ShipMeshRenderer.renderShip(
                    canvas: canvas,
                    shipId: shipId,
                    pilotHeadOffset: Vector2(0.02, 0.01),
                    pilotLookDirection: lookVec,
                    pilotGStrain: gStrain,
                    isPanicking: panicking,
                    isBlinking: blinking,
                    animationTime: 2.3,
                  ),
                  returnsNormally,
                  reason: 'Pilot render failed for $shipId at G-strain $gStrain, panic: $panicking, blink: $blinking',
                );
              }
            }
          }
        }
      }

      final pic = recorder.endRecording();
      pic.dispose();
    });
  });

  group('Lander Physics & Hitbox Verification Tests', () {
    test('Lander creates distinct Box2D polygon hitboxes matching all 5 ship profiles', () async {
      for (final shipId in ['sputnik', 'swift', 'titan', 'needle', 'cyclone']) {
        await GameState().selectRocket(shipId);
        final lander = Lander(initialPosition: Vector2(0, 0), shipId: shipId);

        final world = Forge2DWorld();
        lander.world = world;
        final body = lander.createBody();

        expect(body.fixtures.length, equals(1));
        final shape = body.fixtures.first.shape as PolygonShape;
        expect(shape.vertices.length, greaterThanOrEqualTo(5));

        // Mass multiplier check from GameState config
        final expectedMass = GameState.rocketConfigs[shipId]!['mass'] as double;
        expect(body.fixtures.first.density, closeTo(expectedMass, 0.001));
      }
    });

    test('Lander dynamic physics updates G-force, look direction, and panic triggers correctly', () async {
      await GameState().selectRocket('sputnik');
      final lander = Lander(initialPosition: Vector2(0, 0), shipId: 'sputnik');

      final world = Forge2DWorld();
      lander.world = world;
      final body = lander.createBody();
      lander.body = body;

      // Steady state at constant low velocity
      body.linearVelocity = Vector2(1.0, 0.0);
      lander.shield = 100.0;
      lander.fuel = 150.0;
      // Step 1 establishes baseline velocity
      lander.update(0.016);
      // Step 2 has zero acceleration (constant speed) -> normal state
      lander.update(0.016);

      expect(lander.isPanicking, isFalse);
      expect(lander.lookDirection.x, greaterThan(0.0)); // Tracking velocity along X

      // Simulate high speed -> triggers panic
      body.linearVelocity = Vector2(8.0, 0.0);
      lander.update(0.016);
      expect(lander.isPanicking, isTrue);

      // Low fuel triggers panic
      body.linearVelocity = Vector2(1.0, 0.0);
      lander.update(0.016);
      lander.fuel = 10.0; // 10 / 150 < 0.20
      lander.update(0.016);
      expect(lander.isPanicking, isTrue);

      // Low shield triggers panic
      lander.fuel = 150.0;
      lander.shield = 15.0; // 15 / 100 < 0.35
      lander.update(0.016);
      expect(lander.isPanicking, isTrue);
    });
  });
}
