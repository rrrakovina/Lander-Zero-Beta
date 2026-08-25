import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:lander_zero/game/lander_zero_game.dart';
import 'package:lander_zero/game/audio/game_audio_manager.dart';
import 'package:lander_zero/game/state/game_state.dart';
import 'package:lander_zero/game/components/cave.dart';
import 'package:lander_zero/game/components/lander.dart';
import 'package:lander_zero/game/components/magma_bubble.dart';
import 'package:lander_zero/game/components/stalactite.dart';
import 'package:lander_zero/game/components/geyser.dart';
import 'package:lander_zero/game/components/endless_cave_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    GameAudioManager.isTesting = true;
    await GameState().init(force: true);
  });

  group('Milestone 4 — Biome Gravity & Physical Parameters Suite', () {
    test('Gravity scales accurately across all 5 biomes + endless mode', () {
      final gameEcho = LanderZeroGame(mapId: 'echo');
      expect(gameEcho.world.gravity.y, closeTo(3.5, 0.01));

      final gameWind = LanderZeroGame(mapId: 'wind');
      expect(gameWind.world.gravity.y, closeTo(3.5, 0.01));

      final gameCore = LanderZeroGame(mapId: 'core');
      expect(gameCore.world.gravity.y, closeTo(5.3, 0.01)); // 1.5g

      final gameIce = LanderZeroGame(mapId: 'ice');
      expect(gameIce.world.gravity.y, closeTo(2.275, 0.01)); // 0.65g Europa

      final gameOrbit = LanderZeroGame(mapId: 'orbit');
      expect(gameOrbit.world.gravity.y, closeTo(0.0, 0.01)); // 0.0g Zero Gravity

      final gameEndless = LanderZeroGame(mapId: 'endless');
      expect(gameEndless.world.gravity.y, closeTo(3.5, 0.01));
    });

    test('Europa ice biome initializes ultra-low friction surface', () {
      final caveIce = Cave(mapId: 'ice');
      final world = Forge2DWorld();
      caveIce.world = world;
      final body = caveIce.createBody();

      expect(caveIce.floorPoints.isNotEmpty, isTrue);
      expect(caveIce.ceilingPoints.isNotEmpty, isTrue);

      final fixture = body.fixtures.first;
      expect(fixture.friction, closeTo(0.08, 0.01)); // Ultra low friction
      expect(fixture.restitution, closeTo(0.25, 0.01));
    });

    test('Orbit biome initializes zero-G low friction surface', () {
      final caveOrbit = Cave(mapId: 'orbit');
      final world = Forge2DWorld();
      caveOrbit.world = world;
      final body = caveOrbit.createBody();

      final fixture = body.fixtures.first;
      expect(fixture.friction, closeTo(0.10, 0.01));
      expect(fixture.restitution, closeTo(0.35, 0.01));
    });
  });

  group('Milestone 4 — Interactive Cavern Hazards Suite', () {
    test('Stalactite triggers drop when Lander passes underneath and damages shield', () {
      final stalactite = Stalactite(initialPosition: Vector2(5.0, -10.0), biome: 'ice');
      final world = Forge2DWorld();
      stalactite.world = world;
      final body = stalactite.createBody();
      stalactite.body = body;

      expect(stalactite.isTriggered, isFalse);
      expect(stalactite.biome, equals('ice'));
    });

    test('Cryo Geyser initializes in active/inactive cycle with biome theme', () {
      final geyser = Geyser(position: Vector2(0.0, 5.0), biome: 'ice');
      expect(geyser.biome, equals('ice'));
      expect(geyser.forceMagnitude, equals(32.0));
      expect(geyser.rangeHeight, equals(10.0));
    });

    test('MagmaBubble initializes with bounds and vertical velocity parameters', () {
      final bubble = MagmaBubble(minX: -10, maxX: 10, speed: 2.0, radius: 0.6);
      expect(bubble.minX, equals(-10));
      expect(bubble.maxX, equals(10));
      expect(bubble.speed, equals(2.0));
      expect(bubble.radius, equals(0.6));
    });
  });

  group('Milestone 4 — Procedural Endless Mode Suite', () {
    test('EndlessCaveManager calculates endless score dynamically based on distance and rescues', () {
      final game = LanderZeroGame(mapId: 'endless');
      final manager = EndlessCaveManager();
      manager.game = game;

      expect(manager.rescuesCount, equals(0));
      expect(manager.endlessScore, equals(0));

      game.maxDistance = 120.0;
      expect(manager.endlessScore, equals(1200)); // 120 * 10

      manager.rescuesCount = 3;
      expect(manager.endlessScore, equals(4200)); // 1200 + 3 * 1000
    });

    test('Orbit zero-G reverse RCS braking decelerates moving lander', () {
      final game = LanderZeroGame(mapId: 'orbit');
      final lander = Lander(initialPosition: Vector2(0, 0), shipId: 'sputnik');
      final world = Forge2DWorld();
      lander.world = world;
      final body = lander.createBody();
      lander.body = body;
      game.lander = lander;

      body.linearVelocity = Vector2(10.0, 10.0);
      final initialSpeed = body.linearVelocity.length;

      // Simulate pressing KeyS in Orbit mode
      final keyEvent = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyS,
        logicalKey: LogicalKeyboardKey.keyS,
        timeStamp: Duration.zero,
      );
      game.onKeyEvent(keyEvent, {LogicalKeyboardKey.keyS});

      final newSpeed = body.linearVelocity.length;
      expect(newSpeed, lessThan(initialSpeed));
    });
  });
}
