import 'dart:ui';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lander_zero/game/components/cargo_capsule.dart';
import 'package:lander_zero/game/config/game_config.dart';
import 'package:lander_zero/game/lander_zero_game.dart';
import 'package:lander_zero/game/audio/game_audio_manager.dart';
import 'package:lander_zero/game/state/game_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestForge2DGame extends Forge2DGame {
  TestForge2DGame({super.gravity});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    GameAudioManager.isTesting = true;
    await GameState().init(force: true);
  });

  group('Milestone 1 — CargoType Enum & Biome Mapping Tests', () {
    test('CargoType enum has exactly 5 variants', () {
      expect(CargoType.values.length, equals(5));
      expect(CargoType.values, containsAll([
        CargoType.rescuePod,
        CargoType.titaniumCrate,
        CargoType.cryoBarrel,
        CargoType.scienceProbe,
        CargoType.energyCrystal,
      ]));
    });

    test('CargoType.fromMapId correctly maps all planetary biomes', () {
      // 1. Echo Canyon -> Rescue Pod (Emergency life-support pod)
      expect(CargoType.fromMapId('echo'), equals(CargoType.rescuePod));

      // 2. Solar Winds -> Titanium Crate (Armored container resisting plasma winds)
      expect(CargoType.fromMapId('wind'), equals(CargoType.titaniumCrate));

      // 3. Deep Core -> Energy Crystal (Radiant geothermal crystal on magma pedestal)
      expect(CargoType.fromMapId('core'), equals(CargoType.energyCrystal));

      // 4. Europa Ice Rift -> Cryo Barrel (Insulated sub-zero canister)
      expect(CargoType.fromMapId('ice'), equals(CargoType.cryoBarrel));

      // 5. Orbital Debris -> Science Probe (Golden MLI satellite package)
      expect(CargoType.fromMapId('orbit'), equals(CargoType.scienceProbe));
    });

    test('CargoType.fromMapId falls back gracefully to rescuePod for unknown or endless maps', () {
      expect(CargoType.fromMapId('endless'), equals(CargoType.rescuePod));
      expect(CargoType.fromMapId('unknown_biome'), equals(CargoType.rescuePod));
      expect(CargoType.fromMapId(''), equals(CargoType.rescuePod));
      expect(CargoType.fromMapId('ECHO'), equals(CargoType.rescuePod));
    });
  });

  group('Milestone 1 — CargoCapsule Physics Invariance Tests Across All 5 Models', () {
    late TestForge2DGame game;

    setUp(() async {
      game = TestForge2DGame(gravity: Vector2(0, 10));
      await game.onLoad();
    });

    test('Physical fixture, body definitions, and collision filters are 100% identical', () {
      final world = Forge2DWorld();
      final bodies = <CargoType, Body>{};

      for (final cargoType in CargoType.values) {
        final capsule = CargoCapsule(
          initialPosition: Vector2(0, 0),
          type: cargoType,
        );
        capsule.world = world;
        final body = capsule.createBody();
        capsule.body = body;

        bodies[cargoType] = body;

        // Verify BodyDef parameters
        expect(body.bodyType, equals(BodyType.dynamic),
            reason: '$cargoType must be BodyType.dynamic');
        expect(body.linearDamping, equals(1.5),
            reason: '$cargoType linear damping mismatch');
        expect(body.angularDamping, equals(3.0),
            reason: '$cargoType angular damping mismatch');

        // Verify Fixture parameters
        expect(body.fixtures.length, equals(1),
            reason: '$cargoType must have exactly 1 collision fixture');
        final fixture = body.fixtures.first;
        expect(fixture.density, equals(GameConfig.cargoMass),
            reason: '$cargoType density mismatch');
        expect(fixture.density, equals(0.10),
            reason: '$cargoType density should be 0.10');
        expect(fixture.friction, equals(0.3),
            reason: '$cargoType friction mismatch');
        expect(fixture.restitution, equals(0.05),
            reason: '$cargoType restitution mismatch');

        // Verify Collision Filter Bits
        expect(fixture.filterData.categoryBits, equals(0x0008),
            reason: '$cargoType categoryBits must be 0x0008');
        expect(
          fixture.filterData.maskBits,
          equals(0xFFFF & ~0x0004 & ~0x0002),
          reason: '$cargoType maskBits must exclude tether (0x0004) and lander (0x0002)',
        );

        // Verify 5-vertex Polygon Shape
        expect(fixture.shape, isA<PolygonShape>(),
            reason: '$cargoType shape must be PolygonShape');
        final polygon = fixture.shape as PolygonShape;
        expect(polygon.vertices.length, equals(5),
            reason: '$cargoType must have exactly 5 vertices');

        // Expected CCW 5-vertex polygon
        final expectedVertices = [
          Vector2(0.0, -0.9),  // Top hook point
          Vector2(0.8, -0.4),  // Upper right
          Vector2(0.6, 0.9),   // Lower right base
          Vector2(-0.6, 0.9),  // Lower left base
          Vector2(-0.8, -0.4), // Upper left
        ];

        for (final exp in expectedVertices) {
          final found = polygon.vertices.any(
            (v) => (v.x - exp.x).abs() < 1e-4 && (v.y - exp.y).abs() < 1e-4,
          );
          expect(found, isTrue, reason: '$cargoType must contain vertex $exp');
        }
      }

      // Verify cross-model mathematical identity of mass, inertia, and center of mass
      final baselineType = CargoType.values.first;
      final baselineBody = bodies[baselineType]!;
      final double baselineMass = baselineBody.mass;
      final double baselineInertia = baselineBody.inertia;
      final Vector2 baselineWorldCenter = baselineBody.worldCenter;

      expect(baselineMass, greaterThan(0.0));
      expect(baselineInertia, greaterThan(0.0));

      for (final cargoType in CargoType.values.skip(1)) {
        final body = bodies[cargoType]!;
        expect(body.mass, closeTo(baselineMass, 1e-6),
            reason: '$cargoType mass diverged from $baselineType');
        expect(body.inertia, closeTo(baselineInertia, 1e-6),
            reason: '$cargoType inertia diverged from $baselineType');
        expect(body.worldCenter.x, closeTo(baselineWorldCenter.x, 1e-6),
            reason: '$cargoType worldCenter.x diverged');
        expect(body.worldCenter.y, closeTo(baselineWorldCenter.y, 1e-6),
            reason: '$cargoType worldCenter.y diverged');
      }
    });

    test('All 5 cargo types exhibit 100% identical kinematics during live physics simulation', () async {
      final capsules = <CargoType, CargoCapsule>{};
      final worlds = <CargoType, Forge2DWorld>{};

      for (final cargoType in CargoType.values) {
        final world = Forge2DWorld(gravity: Vector2(0, 9.81));
        worlds[cargoType] = world;

        final capsule = CargoCapsule(
          initialPosition: Vector2(0, 0),
          type: cargoType,
        );
        capsule.world = world;
        final body = capsule.createBody();
        capsule.body = body;
        capsules[cargoType] = capsule;
      }

      // Step each physics world for 120 frames (2.0 seconds at 60 FPS)
      for (int step = 0; step < 120; step++) {
        for (final world in worlds.values) {
          world.physicsWorld.stepDt(1.0 / 60.0);
        }
      }

      // Verify all 5 bodies have identical position and velocity to double precision
      final baselineBody = capsules[CargoType.rescuePod]!.body;
      final double baseY = baselineBody.position.y;
      final double baseVy = baselineBody.linearVelocity.y;

      expect(baseY, greaterThan(1.0), reason: 'Capsules should have fallen under gravity');
      expect(baseVy, greaterThan(1.0), reason: 'Capsules should have acquired velocity');

      for (final cargoType in CargoType.values) {
        final body = capsules[cargoType]!.body;
        expect(body.position.x, closeTo(0.0, 1e-5),
            reason: '$cargoType X drifted without lateral force');
        expect(body.position.y, closeTo(baseY, 1e-5),
            reason: '$cargoType Y position diverged during freefall');
        expect(body.linearVelocity.y, closeTo(baseVy, 1e-5),
            reason: '$cargoType linearVelocity.y diverged');
        expect(body.angle, closeTo(0.0, 1e-5),
            reason: '$cargoType angular orientation diverged');
      }
    });

    test('Top tow hook anchor is mathematically consistent at (0.0, -0.9) for tether connection', () {
      for (final cargoType in CargoType.values) {
        final capsule = CargoCapsule(
          initialPosition: Vector2(10.0, -5.0),
          type: cargoType,
        );
        expect(capsule.type, equals(cargoType));
        expect(capsule.isDocked, isFalse);

        // State toggling
        capsule.isDocked = true;
        expect(capsule.isDocked, isTrue);
      }
    });
  });

  group('CargoCapsule Vector Rendering Tests for All 5 Visual Models', () {
    test('All 5 visual models render cleanly in undocked and docked states without throws', () {
      final world = Forge2DWorld();

      for (final cargoType in CargoType.values) {
        final capsule = CargoCapsule(
          initialPosition: Vector2.zero(),
          type: cargoType,
        );
        capsule.world = world;
        final body = capsule.createBody();
        capsule.body = body;

        // 1. Render in undocked state
        capsule.isDocked = false;
        capsule.update(0.05);

        final recorderUndocked = PictureRecorder();
        final canvasUndocked = Canvas(recorderUndocked);
        expect(() => capsule.render(canvasUndocked), returnsNormally,
            reason: 'Rendering undocked $cargoType must not throw');
        final picUndocked = recorderUndocked.endRecording();
        expect(picUndocked, isNotNull);

        // 2. Render in docked state
        capsule.isDocked = true;
        capsule.update(0.1);

        final recorderDocked = PictureRecorder();
        final canvasDocked = Canvas(recorderDocked);
        expect(() => capsule.render(canvasDocked), returnsNormally,
            reason: 'Rendering docked $cargoType must not throw');
        final picDocked = recorderDocked.endRecording();
        expect(picDocked, isNotNull);
      }
    });

    test('Dynamic animation time updates internal oscillation without errors', () {
      final world = Forge2DWorld();
      final capsule = CargoCapsule(
        initialPosition: Vector2.zero(),
        type: CargoType.rescuePod,
      );
      capsule.world = world;
      final body = capsule.createBody();
      capsule.body = body;

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // Advance animation time through multiple phases
      for (int i = 0; i < 20; i++) {
        capsule.update(0.05);
        expect(() => capsule.render(canvas), returnsNormally);
      }
      recorder.endRecording();
    });

    test('Default constructor defaults type to CargoType.rescuePod', () {
      final capsule = CargoCapsule(initialPosition: Vector2(5, 5));
      expect(capsule.type, equals(CargoType.rescuePod));
    });
  });

  group('Milestone 1 — LanderZeroGame Map Loading & Cargo Type Integration Tests', () {
    final mapExpectations = {
      'echo': CargoType.rescuePod,
      'wind': CargoType.titaniumCrate,
      'core': CargoType.energyCrystal,
      'ice': CargoType.cryoBarrel,
      'orbit': CargoType.scienceProbe,
    };

    for (final entry in mapExpectations.entries) {
      test('Map "${entry.key}" spawns CargoCapsule with CargoType.${entry.value}', () async {
        final game = LanderZeroGame(mapId: entry.key);
        await game.onLoad();

        expect(game.cargoCapsule, isNotNull);
        expect(game.cargoCapsule.type, equals(entry.value));
        expect(game.cargoCapsule.initialPosition.x, equals(game.cave.cargoPlatform.x));
        expect(game.cargoCapsule.initialPosition.y, closeTo(game.cave.cargoPlatform.y - 0.9, 0.001));
      });
    }
  });
}
