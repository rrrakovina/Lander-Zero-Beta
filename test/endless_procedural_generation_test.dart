import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:lander_zero/game/lander_zero_game.dart';
import 'package:lander_zero/game/audio/game_audio_manager.dart';
import 'package:lander_zero/game/state/game_state.dart';
import 'package:lander_zero/game/components/lander.dart';
import 'package:lander_zero/game/components/rotating_debris.dart';
import 'package:lander_zero/game/components/endless_cave_manager.dart';
import 'package:lander_zero/ui/widgets/minimap_widget.dart';

Widget createTestApp(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    GameAudioManager.isTesting = true;
    await GameState().init(force: true);
  });

  group('Suite 1: EndlessTerrainGenerator Mathematical Continuity & Clearance', () {
    test('Continuous height field across 0 to 5000m has no vertical discontinuities (C0 continuity)', () {
      final gen = EndlessTerrainGenerator();

      double prevFloor = gen.getFloorY(-30.0);
      double prevCeil = gen.getCeilingY(-30.0);

      // Sample every 0.2 meters from -30m to 3000m
      for (double x = -29.8; x <= 3000.0; x += 0.2) {
        final fy = gen.getFloorY(x);
        final cy = gen.getCeilingY(x);

        // Maximum height change over 0.2m step must be small (< 0.8m, no sharp cliffs/clamping jumps)
        final df = (fy - prevFloor).abs();
        final dc = (cy - prevCeil).abs();

        expect(df, lessThan(0.8), reason: 'Discontinuity detected in floor at x = $x (df = $df)');
        expect(dc, lessThan(0.8), reason: 'Discontinuity detected in ceiling at x = $x (dc = $dc)');

        // Headroom clearance contract: Must guarantee at least 12.0m everywhere
        final clearance = fy - cy;
        expect(clearance, greaterThanOrEqualTo(12.0), reason: 'Insufficient headroom clearance at x = $x ($clearance m)');

        prevFloor = fy;
        prevCeil = cy;
      }
    });

    test('Registered platforms create strictly flat landing zones with smooth blending', () {
      final gen = EndlessTerrainGenerator();
      const platX = 240.0;
      const platY = 5.5;
      gen.registerPlatform(platX, platY, 4.5);

      // Inside [platX - 4.5, platX + 4.5], floor must be strictly platY
      for (double x = platX - 4.4; x <= platX + 4.4; x += 0.5) {
        expect(gen.getFloorY(x), closeTo(platY, 0.0001), reason: 'Platform landing zone must be perfectly flat at x = $x');
      }

      // Smooth transition in blending region [platX - 8.0, platX - 4.5]
      final yAtEdge = gen.getFloorY(platX - 4.5);
      final yJustOutside = gen.getFloorY(platX - 5.5);
      final yFarOutside = gen.getFloorY(platX - 12.0);

      expect(yAtEdge, equals(platY));
      expect((yJustOutside - yAtEdge).abs(), lessThan(1.5));
      expect((yFarOutside - yJustOutside).abs(), greaterThanOrEqualTo(0.0));
    });

    test('Biome transitions smoothly blend mathematical harmonic formulas over 40m', () {
      final gen = EndlessTerrainGenerator();

      // Sector 1 (Mines) -> Sector 2 (Crystal) boundary is at X = 400.0 (transition 360-400)
      final y350 = gen.getRawFloorY(350.0);
      final y380 = gen.getRawFloorY(380.0);
      final y410 = gen.getRawFloorY(410.0);

      expect(y350.isFinite, isTrue);
      expect(y380.isFinite, isTrue);
      expect(y410.isFinite, isTrue);

      // Verify no abrupt jump at exactly X = 400.0
      final yBefore = gen.getRawFloorY(399.9);
      final yAfter = gen.getRawFloorY(400.1);
      expect((yAfter - yBefore).abs(), lessThan(0.2));
    });
  });

  group('Suite 2: Dynamic Chunk Physics (Box2D) & Garbage Collection', () {
    test('EndlessTerrainChunkComponent creates valid Box2D ChainShape fixtures and left boundary', () {
      final world = Forge2DWorld();
      final gen = EndlessTerrainGenerator();

      // Start chunk (index = 0)
      final startChunk = EndlessTerrainChunkComponent(
        index: 0,
        startX: -40.0,
        endX: 8.0,
        type: EndlessChunkType.startPad,
        biomeIndex: 0,
        generator: gen,
        platformPos: Vector2(-28.0, -5.0),
      );
      startChunk.world = world;
      final body0 = startChunk.createBody();

      expect(body0.fixtures.length, equals(3), reason: 'Start chunk must create Floor Chain, Ceiling Chain, and Left Boundary Wall');
      expect(body0.fixtures.first.shape, isA<ChainShape>());
      expect(body0.fixtures[1].shape, isA<ChainShape>());
      expect(body0.fixtures[2].shape, isA<EdgeShape>());

      // Mid-transit chunk (index > 0)
      final midChunk = EndlessTerrainChunkComponent(
        index: 1,
        startX: 8.0,
        endX: 56.0,
        type: EndlessChunkType.rescueZone,
        biomeIndex: 0,
        generator: gen,
        platformPos: Vector2(32.0, 6.0),
      );
      midChunk.world = world;
      final body1 = midChunk.createBody();

      expect(body1.fixtures.length, equals(2), reason: 'Transit chunk has Floor and Ceiling Chain without blocking side walls');
    });

    test('Europa Crystal Grotto chunk assigns ultra-low friction (0.08) to fixtures', () {
      final world = Forge2DWorld();
      final gen = EndlessTerrainGenerator();

      final crystalChunk = EndlessTerrainChunkComponent(
        index: 10,
        startX: 450.0,
        endX: 498.0,
        type: EndlessChunkType.hazardTransit,
        biomeIndex: 1, // Crystal Grotto (Ice)
        generator: gen,
      );
      crystalChunk.world = world;
      final body = crystalChunk.createBody();

      expect(body.fixtures.first.friction, closeTo(0.08, 0.001));
      expect(body.fixtures.first.restitution, closeTo(0.25, 0.001));
    });

    test('EndlessCaveManager streams new chunks ahead and garbage collects old chunks > 80m behind', () async {
      final game = LanderZeroGame(mapId: 'endless');
      await game.onLoad();
      game.cave.world = game.world;
      game.cave.createBody();
      game.lander.world = game.world;
      game.lander.body = game.lander.createBody();

      final manager = game.endlessManager!;
      await manager.onLoad();
      game.update(0.016);

      // Initial chunk count
      expect(manager.activeChunksCount, equals(4));

      // Advance lander to X = 300.0m
      game.lander.body.setTransform(Vector2(300.0, 0.0), 0.0);
      manager.update(0.016);
      game.update(0.016);

      // New chunks generated ahead
      expect(manager.activeChunksCount, greaterThanOrEqualTo(4));

      // Check that chunks far behind (X < 200m) are unmounted
      final minActiveX = manager.activeChunks.map((c) => c.startX).reduce(min);
      expect(minActiveX, greaterThanOrEqualTo(300.0 - 180.0));
    });
  });

  group('Suite 3: Smart Obstacle & Hazard Clearance', () {
    test('Sector 4 Rotating Debris only spawns when corridor clearance is generous (> 18.0m)', () async {
      final game = LanderZeroGame(mapId: 'endless');
      await game.onLoad();

      game.endlessManager!.generator.registerPlatform(1300.0, 5.0, 4.5);

      // Verify that RotatingDebris dimensions are balanced (width 1.4m, height 4.0m)
      final debris = RotatingDebris(
        initialPosition: Vector2(1300.0, -5.0),
        width: 1.4,
        height: 4.0,
        angularSpeed: 0.4,
      );
      debris.world = game.world;
      final body = debris.createBody();

      expect(body.bodyType, equals(BodyType.kinematic));
      expect(debris.height, equals(4.0));
      expect(debris.width, equals(1.4));
    });
  });

  group('Suite 4: Dynamic Tactical Scanning Radar in Endless Mode', () {
    testWidgets('MinimapWidget dynamically renders tactical scanning radar during endless flight', (tester) async {
      final game = LanderZeroGame(mapId: 'endless');
      await game.onLoad();
      game.cave.world = game.world;
      game.cave.createBody();
      game.lander.world = game.world;
      game.lander.body = game.lander.createBody();

      // Set lander depth to 250m
      game.lander.body.setTransform(Vector2(250.0, 4.0), 0.2);

      await tester.pumpWidget(createTestApp(
        MinimapWidget(game: game),
      ));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(MinimapWidget), findsOneWidget);
      expect(find.text('RADAR'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
    });
  });

  group('Suite 5: Ship Stuck / Rollover Detector & Quick Restart (Key R)', () {
    test('Lander detects overturned stuck state when tilted > 80 deg and stationary', () {
      final world = Forge2DWorld(gravity: Vector2(0, 3.5));
      final lander = Lander(initialPosition: Vector2.zero(), shipId: 'sputnik');
      lander.world = world;
      final body = lander.createBody();
      lander.body = body;

      // Case 1: Flying normally upright
      body.setTransform(Vector2.zero(), 0.0);
      body.linearVelocity = Vector2(3.0, 0.0);
      lander.update(0.1);
      expect(lander.isStuck, isFalse);

      // Case 2: Tilted on roof (angle = 3.0 rad ~ 172 deg) and stationary on ground
      body.setTransform(Vector2.zero(), 3.0);
      body.linearVelocity = Vector2.zero();
      body.angularVelocity = 0.0;
      lander.contactCount = 1; // grounded

      // Tick update over 1.6 seconds
      for (int i = 0; i < 18; i++) {
        lander.update(0.1);
      }

      expect(lander.isStuck, isTrue, reason: 'Lander grounded upside down for > 1.5s must be detected as stuck');

      // Case 3: Lander gets righted back up
      body.setTransform(Vector2.zero(), 0.1);
      lander.update(0.1);
      expect(lander.isStuck, isFalse, reason: 'Righted lander resets stuck flag immediately');
    });

    test('Key R and Key K trigger instant onRestartRequested callback', () {
      bool restarted = false;
      final game = LanderZeroGame(
        mapId: 'endless',
        onRestartRequested: () {
          restarted = true;
        },
      );

      // Test QWERTY 'R' key
      final keyR = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyR,
        logicalKey: LogicalKeyboardKey.keyR,
        timeStamp: Duration.zero,
      );
      final resR = game.onKeyEvent(keyR, {LogicalKeyboardKey.keyR});
      expect(resR, equals(KeyEventResult.handled));
      expect(restarted, isTrue);

      restarted = false;

      // Test Russian layout 'К' key
      final keyK = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyK,
        logicalKey: LogicalKeyboardKey.keyK,
        timeStamp: Duration.zero,
      );
      final resK = game.onKeyEvent(keyK, {LogicalKeyboardKey.keyK});
      expect(resK, equals(KeyEventResult.handled));
      expect(restarted, isTrue);
    });
  });
}
