import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:lander_zero/game/lander_zero_game.dart';
import 'package:lander_zero/game/audio/game_audio_manager.dart';
import 'package:lander_zero/game/state/game_state.dart';
import 'package:lander_zero/game/components/cave.dart';
import 'package:lander_zero/game/components/lander.dart';
import 'package:lander_zero/game/components/stalactite.dart';
import 'package:lander_zero/game/components/rotating_debris.dart';
import 'package:lander_zero/ui/widgets/minimap_widget.dart';
import 'package:lander_zero/ui/painters/map_preview_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    GameAudioManager.isTesting = true;
    await GameState().init(force: true);
  });

  group('Milestone 1 — 5-Map Level Design & Geometric Coordinate Contracts', () {
    test('Echo Canyon (echo) geometry, platform coordinates & elevation invariants', () {
      final cave = Cave(mapId: 'echo');
      final world = Forge2DWorld();
      cave.world = world;
      cave.createBody();

      // Platform coordinates
      expect(cave.startPlatform, equals(Vector2(-28.0, -5.0)));
      expect(cave.cargoPlatform, equals(Vector2(0.0, 8.0)));
      expect(cave.exitPlatform, equals(Vector2(25.0, -12.0)));

      // Horizontal span coverage
      expect(cave.floorPoints.first.x, lessThanOrEqualTo(-36.0));
      expect(cave.floorPoints.last.x, greaterThanOrEqualTo(36.0));

      // Valley descent & elevation ascent
      final startFloor = cave.getFloorY(-28.0);
      final valleyFloor = cave.getFloorY(0.0);
      final exitFloor = cave.getFloorY(25.0);

      expect(startFloor, closeTo(-5.0, 0.5));
      expect(valleyFloor, closeTo(8.0, 0.5));
      expect(exitFloor, closeTo(-12.0, 0.5));

      // Headroom clearance (> 8.0m everywhere)
      for (double x = -30.0; x <= 25.0; x += 5.0) {
        final fy = cave.getFloorY(x);
        final cy = cave.getCeilingY(x);
        expect(fy - cy, greaterThanOrEqualTo(8.0), reason: 'Clearance at x = $x');
      }
    });

    test('Deep Core (core) vertical volcanic chimney geometry invariants', () {
      final cave = Cave(mapId: 'core');
      final world = Forge2DWorld();
      cave.world = world;
      cave.createBody();

      // Platform coordinates
      expect(cave.startPlatform, equals(Vector2(-14.0, -12.0)));
      expect(cave.cargoPlatform, equals(Vector2(0.0, 14.0)));
      expect(cave.exitPlatform, equals(Vector2(14.0, -12.0)));

      // Surface shelves at top
      final leftShelfY = cave.getFloorY(-14.0);
      final rightShelfY = cave.getFloorY(14.0);
      expect(leftShelfY, closeTo(-12.0, 0.5));
      expect(rightShelfY, closeTo(-12.0, 0.5));

      // Volcanic chimney bottom
      final chimneyBottomY = cave.getFloorY(0.0);
      expect(chimneyBottomY, closeTo(14.0, 0.5));

      // Vertical shaft depth is 26 meters
      final verticalDrop = chimneyBottomY - leftShelfY;
      expect(verticalDrop, closeTo(26.0, 1.0));

      // High continuous ceiling at y ~ -26.0
      expect(cave.getCeilingY(0.0), closeTo(-26.0, 1.5));
      expect(cave.getCeilingY(-14.0), closeTo(-26.0, 1.5));
    });

    test('Solar Winds (wind) stepped zig-zag rift & shelter pocket invariants', () {
      final cave = Cave(mapId: 'wind');
      final world = Forge2DWorld();
      cave.world = world;
      cave.createBody();

      expect(cave.startPlatform, equals(Vector2(-28.0, -10.0)));
      expect(cave.cargoPlatform, equals(Vector2(2.0, 10.0)));
      expect(cave.exitPlatform, equals(Vector2(28.0, -10.0)));

      // Test isSheltered method
      // Cargo trench is sheltered
      expect(cave.isSheltered(Vector2(2.0, 8.0)), isTrue);
      expect(cave.isSheltered(Vector2(0.0, 9.5)), isTrue);

      // Step 2 overhang alcove is sheltered
      expect(cave.isSheltered(Vector2(-15.0, -1.0)), isTrue);

      // High open air corridor is NOT sheltered
      expect(cave.isSheltered(Vector2(-28.0, -15.0)), isFalse);
      expect(cave.isSheltered(Vector2(10.0, -15.0)), isFalse);
      expect(cave.isSheltered(Vector2(0.0, -18.0)), isFalse);
    });

    test('Europa Ice Rift (ice) branching fork & upper ledge invariants', () {
      final cave = Cave(mapId: 'ice');
      final world = Forge2DWorld();
      cave.world = world;
      final body = cave.createBody();

      expect(cave.startPlatform, equals(Vector2(-28.0, -4.0)));
      expect(cave.cargoPlatform, equals(Vector2(0.0, 8.0)));
      expect(cave.exitPlatform, equals(Vector2(26.0, -11.0)));

      // Multi-chain branchPoints must be present
      expect(cave.branchPoints.isNotEmpty, isTrue);
      expect(cave.branchPoints.first.x, closeTo(-22.0, 0.1));
      expect(cave.branchPoints.last.x, closeTo(-3.0, 0.1));

      // Upper ledge is at y ~ -1.0
      for (final bp in cave.branchPoints) {
        expect(bp.y, closeTo(-1.0, 1.0));
      }

      // Fixture count includes floor, ceiling, left wall, right wall, and upper branch ledge
      expect(body.fixtures.length, greaterThanOrEqualTo(5));
      expect(cave.floorFriction, closeTo(0.08, 0.01));
      expect(cave.floorRestitution, closeTo(0.25, 0.01));
    });

    test('Orbital Debris (orbit) 360 open space & perimeter beacon invariants', () {
      final cave = Cave(mapId: 'orbit');
      final world = Forge2DWorld();
      cave.world = world;
      cave.createBody();

      expect(cave.startPlatform, equals(Vector2(-25.0, 0.0)));
      expect(cave.cargoPlatform, equals(Vector2(0.0, 0.0)));
      expect(cave.exitPlatform, equals(Vector2(25.0, 0.0)));

      // 4 Perimeter boundary beacons
      expect(cave.perimeterBeacons.length, equals(4));
      expect(cave.perimeterBeacons, contains(Vector2(-34.0, -26.0)));
      expect(cave.perimeterBeacons, contains(Vector2(34.0, -26.0)));
      expect(cave.perimeterBeacons, contains(Vector2(34.0, 14.0)));
      expect(cave.perimeterBeacons, contains(Vector2(-34.0, 14.0)));
    });
  });

  group('Milestone 2 — Hazards & Dynamic Environmental Physics', () {
    test('RotatingDebris initializes with kinematic body, angular speed, and Box2D polygon', () {
      final debris = RotatingDebris(
        initialPosition: Vector2(-12.0, -7.0),
        width: 1.4,
        height: 6.5,
        angularSpeed: 0.5,
        debrisType: 'solar_panel',
      );
      final world = Forge2DWorld();
      debris.world = world;
      final body = debris.createBody();
      debris.body = body;

      expect(body.bodyType, equals(BodyType.kinematic));
      expect(body.angularVelocity, closeTo(0.5, 0.001));
      expect(body.fixtures.first.shape, isA<PolygonShape>());
      expect(body.fixtures.first.filterData.categoryBits, equals(0x0010));
    });

    test('Stalactite engine vibration expands trigger detection when thrusters active', () {
      final stalactite = Stalactite(initialPosition: Vector2(0.0, -10.0), biome: 'echo');
      final world = Forge2DWorld();
      stalactite.world = world;
      final body = stalactite.createBody();
      stalactite.body = body;

      final game = LanderZeroGame(mapId: 'echo');
      stalactite.game = game;
      final lander = Lander(initialPosition: Vector2(2.5, -4.0)); // xDiff = 2.5, yDiff = 6.0
      lander.world = world;
      final landerBody = lander.createBody();
      lander.body = landerBody;
      game.lander = lander;

      // When engines are idle, xDiff = 2.5 is outside default range (1.6) -> does not trigger
      lander.leftThrustActive = false;
      lander.rightThrustActive = false;
      stalactite.update(0.016);
      expect(stalactite.isTriggered, isFalse);

      // When engines are active, acoustic vibrations expand trigger range to 3.0 -> triggers drop!
      lander.leftThrustActive = true;
      stalactite.update(0.016);
      expect(stalactite.isTriggered, isTrue);
      expect(body.bodyType, equals(BodyType.dynamic));
    });

    test('Solar Winds wind force attenuation in shelter zones', () {
      final cave = Cave(mapId: 'wind');
      expect(cave.isSheltered(Vector2(2.0, 8.0)), isTrue);
      expect(cave.isSheltered(Vector2(2.0, -15.0)), isFalse);
    });
  });

  group('Milestone 3 — Tactical Radar Minimap & Holographic Preview Synchronization', () {
    test('MinimapWidget bounds encompass full Deep Core shaft and high ceilings without clipping', () {
      const double w = 144.0;
      const double h = 92.0;

      // Deep Core magma floor (y = 14.0)
      final coreFloorY = MinimapWidget.projectY(14.0, h);
      expect(coreFloorY, greaterThan(0.0));
      expect(coreFloorY, lessThan(h));

      // Deep Core ceiling (y = -26.0)
      final coreCeilingY = MinimapWidget.projectY(-26.0, h);
      expect(coreCeilingY, greaterThan(0.0));
      expect(coreCeilingY, lessThan(h));

      // Start, cargo, exit pads across all 5 maps
      for (final mapId in ['echo', 'core', 'wind', 'ice', 'orbit']) {
        final cave = Cave(mapId: mapId);
        final startOffset = MinimapWidget.projectOffset(cave.startPlatform, const Size(w, h));
        final cargoOffset = MinimapWidget.projectOffset(cave.cargoPlatform, const Size(w, h));
        final exitOffset = MinimapWidget.projectOffset(cave.exitPlatform, const Size(w, h));

        expect(startOffset.dx, inInclusiveRange(0.0, w));
        expect(startOffset.dy, inInclusiveRange(0.0, h));
        expect(cargoOffset.dx, inInclusiveRange(0.0, w));
        expect(cargoOffset.dy, inInclusiveRange(0.0, h));
        expect(exitOffset.dx, inInclusiveRange(0.0, w));
        expect(exitOffset.dy, inInclusiveRange(0.0, h));
      }
    });

    testWidgets('MapPreviewPainter renders all 5 maps without exceptions', (tester) async {
      for (final mapId in ['echo', 'core', 'wind', 'ice', 'orbit']) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                size: const Size(300, 200),
                painter: MapPreviewPainter(
                  mapId: mapId,
                  rocketId: 'sputnik',
                  animationTime: 1.5,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsWidgets);
      }
    });
  });
}
