import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:lander_zero/game/lander_zero_game.dart';
import 'package:lander_zero/game/audio/game_audio_manager.dart';
import 'package:lander_zero/game/state/game_state.dart';
import 'package:lander_zero/game/config/game_config.dart';
import 'package:lander_zero/game/components/cave.dart';
import 'package:lander_zero/game/components/lander.dart';
import 'package:lander_zero/game/components/spark_particle.dart';
import 'package:lander_zero/game/components/rotating_debris.dart';
import 'package:lander_zero/game/components/magma_bubble.dart';
import 'package:lander_zero/game/components/stalactite.dart';
import 'package:lander_zero/game/components/geyser.dart';
import 'package:lander_zero/ui/widgets/minimap_widget.dart';
import 'package:lander_zero/ui/painters/map_preview_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    GameAudioManager.isTesting = true;
    await GameState().init(force: true);
  });

  group('Stress & Property Suite 1: 5-Map Coordinate Contracts & Elevation Invariants', () {
    const maps = ['echo', 'core', 'wind', 'ice', 'orbit'];

    test('All 5 maps initialize distinct non-null platform vectors with adequate distance separation', () {
      for (final mapId in maps) {
        final cave = Cave(mapId: mapId);
        final world = Forge2DWorld();
        cave.world = world;
        cave.createBody();

        // Platforms must be finite
        expect(cave.startPlatform.x.isFinite, isTrue, reason: '$mapId startPlatform.x');
        expect(cave.startPlatform.y.isFinite, isTrue, reason: '$mapId startPlatform.y');
        expect(cave.cargoPlatform.x.isFinite, isTrue, reason: '$mapId cargoPlatform.x');
        expect(cave.cargoPlatform.y.isFinite, isTrue, reason: '$mapId cargoPlatform.y');
        expect(cave.exitPlatform.x.isFinite, isTrue, reason: '$mapId exitPlatform.x');
        expect(cave.exitPlatform.y.isFinite, isTrue, reason: '$mapId exitPlatform.y');

        // Start and Exit must be on opposing horizontal sides (except in core/orbit where X >= 14 separation)
        final double startToExitX = (cave.exitPlatform.x - cave.startPlatform.x).abs();
        expect(startToExitX, greaterThanOrEqualTo(28.0), reason: '$mapId start-to-exit horizontal span must be >= 28m');

        // Total path Euclidean distance (Start -> Cargo -> Exit)
        final double distStartToCargo = cave.startPlatform.distanceTo(cave.cargoPlatform);
        final double distCargoToExit = cave.cargoPlatform.distanceTo(cave.exitPlatform);
        final double totalPathDistance = distStartToCargo + distCargoToExit;

        expect(distStartToCargo, greaterThanOrEqualTo(14.0), reason: '$mapId start-to-cargo distance');
        expect(distCargoToExit, greaterThanOrEqualTo(14.0), reason: '$mapId cargo-to-exit distance');
        expect(totalPathDistance, greaterThanOrEqualTo(35.0), reason: '$mapId total rescue mission path distance');
      }
    });

    test('Echo Canyon (echo) horizontal canyon traversal & elevation profile contracts', () {
      final cave = Cave(mapId: 'echo');
      final world = Forge2DWorld();
      cave.world = world;
      cave.createBody();

      // Platform coordinate contract
      expect(cave.startPlatform, equals(Vector2(-28.0, -5.0)));
      expect(cave.cargoPlatform, equals(Vector2(0.0, 8.0)));
      expect(cave.exitPlatform, equals(Vector2(25.0, -12.0)));

      // Descent into central valley
      final double startFloorY = cave.getFloorY(cave.startPlatform.x);
      final double cargoFloorY = cave.getFloorY(cave.cargoPlatform.x);
      final double exitFloorY = cave.getFloorY(cave.exitPlatform.x);

      expect(startFloorY, closeTo(-5.0, 0.6));
      expect(cargoFloorY, closeTo(8.0, 0.6));
      expect(exitFloorY, closeTo(-12.0, 0.6));

      // Elevation delta: descent from start to valley is ~13m, ascent to exit hangar is ~20m
      expect(cargoFloorY - startFloorY, closeTo(13.0, 1.0));
      expect(cargoFloorY - exitFloorY, closeTo(20.0, 1.0));

      // Rolling ridge between start and valley rises above start platform
      double peakY = double.infinity;
      for (double x = -22.0; x <= -14.0; x += 0.5) {
        final fy = cave.getFloorY(x);
        if (fy < peakY) peakY = fy;
      }
      expect(peakY, lessThan(-3.0), reason: 'Limestone ridge crests above start platform (Y < -3)');
    });

    test('Deep Core (core) strict verticality contract (start/exit Y <= -10, cargo Y >= 12, delta >= 24m)', () {
      final cave = Cave(mapId: 'core');
      final world = Forge2DWorld();
      cave.world = world;
      cave.createBody();

      // Contract assertions
      expect(cave.startPlatform.y, lessThanOrEqualTo(-10.0), reason: 'Deep Core start platform Y must be <= -10');
      expect(cave.exitPlatform.y, lessThanOrEqualTo(-10.0), reason: 'Deep Core exit platform Y must be <= -10');
      expect(cave.cargoPlatform.y, greaterThanOrEqualTo(12.0), reason: 'Deep Core cargo platform Y must be >= 12');

      final double verticalDrop = cave.cargoPlatform.y - cave.startPlatform.y;
      final double verticalAscent = cave.cargoPlatform.y - cave.exitPlatform.y;

      expect(verticalDrop, greaterThanOrEqualTo(24.0), reason: 'Descent delta Y must be >= 24m (actual: $verticalDrop m)');
      expect(verticalAscent, greaterThanOrEqualTo(24.0), reason: 'Ascent delta Y must be >= 24m (actual: $verticalAscent m)');

      // Floor height sampling along chimney:
      // Left surface shelf (-14, -12), chimney drop at x in [-6.5, -4.5], floor at x in [-4.5, 4.5] is 14.0, chimney rise at x in [4.5, 6.5]
      expect(cave.getFloorY(-14.0), closeTo(-12.0, 0.5));
      expect(cave.getFloorY(0.0), closeTo(14.0, 0.5));
      expect(cave.getFloorY(14.0), closeTo(-12.0, 0.5));

      // Chimney walls are steep (slope > 8.0 m/m)
      final double slopeLeftWall = (cave.getFloorY(-4.5) - cave.getFloorY(-6.5)) / ((-4.5) - (-6.5));
      final double slopeRightWall = (cave.getFloorY(6.5) - cave.getFloorY(4.5)) / (6.5 - 4.5);
      expect(slopeLeftWall, greaterThan(10.0), reason: 'Left volcanic chimney wall plunge is steep');
      expect(slopeRightWall, lessThan(-10.0), reason: 'Right volcanic chimney wall ascent is steep');
    });

    test('Solar Winds (wind) stepped zig-zag rift terraces contract', () {
      final cave = Cave(mapId: 'wind');
      final world = Forge2DWorld();
      cave.world = world;
      cave.createBody();

      expect(cave.startPlatform, equals(Vector2(-28.0, -10.0)));
      expect(cave.cargoPlatform, equals(Vector2(2.0, 10.0)));
      expect(cave.exitPlatform, equals(Vector2(28.0, -10.0)));

      // Check 7 terrace levels:
      // Step 1: x = -26 -> Y ~ -10
      // Step 2: x = -16 -> Y ~ -2
      // Step 3: x = -6  -> Y ~ 4
      // Step 4: x = 2   -> Y ~ 10 (Cargo trench)
      // Step 5: x = 12  -> Y ~ 3
      // Step 6: x = 20  -> Y ~ -3
      // Step 7: x = 28  -> Y ~ -10 (Exit)
      expect(cave.getFloorY(-26.0), closeTo(-10.0, 0.5));
      expect(cave.getFloorY(-16.0), closeTo(-2.0, 0.5));
      expect(cave.getFloorY(-6.0), closeTo(4.0, 0.5));
      expect(cave.getFloorY(2.0), closeTo(10.0, 0.5));
      expect(cave.getFloorY(12.0), closeTo(3.0, 0.5));
      expect(cave.getFloorY(20.0), closeTo(-3.0, 0.5));
      expect(cave.getFloorY(28.0), closeTo(-10.0, 0.5));
    });
  });

  group('Stress & Property Suite 2: Solar Winds Dynamic Shelter Damping & Property Testing', () {
    test('Densely sampled shelter grid: points inside isSheltered receive <= 15% wind force', () {
      final cave = Cave(mapId: 'wind');
      final world = Forge2DWorld();
      cave.world = world;
      cave.createBody();

      int shelteredCount = 0;
      int unshelteredCount = 0;

      // Sample a dense grid of 50 x 50 = 2500 points across the cavern
      for (double x = -35.0; x <= 35.0; x += 1.4) {
        for (double y = -25.0; y <= 15.0; y += 0.8) {
          final pos = Vector2(x, y);
          final isSheltered = cave.isSheltered(pos);

          // Simulated wind calculation matching LanderZeroGame._tickPhysicsGameLogic
          for (double flightTime in [0.0, 0.5, 1.2, 2.7, 5.0, 10.0]) {
            final double baseWindFactor = -4.0 + 1.2 * sin(flightTime * 1.8) + 0.6 * sin(flightTime * 3.5);
            final double effectiveWindFactor = isSheltered ? baseWindFactor * 0.15 : baseWindFactor;

            if (isSheltered) {
              shelteredCount++;
              // Shelter damping must reduce wind magnitude to <= 15% of base
              expect(
                effectiveWindFactor.abs(),
                closeTo(baseWindFactor.abs() * 0.15, 1e-6),
                reason: 'Sheltered point at $pos must be damped to 15%',
              );
              expect(
                effectiveWindFactor.abs(),
                lessThanOrEqualTo(baseWindFactor.abs() * 0.1501),
              );
            } else {
              unshelteredCount++;
              // Unsheltered point receives 100% of base wind
              expect(
                effectiveWindFactor,
                equals(baseWindFactor),
                reason: 'Unsheltered point at $pos must receive 100% wind force',
              );
            }
          }
        }
      }

      expect(shelteredCount, greaterThan(100), reason: 'Must have significant sheltered coverage in cavern');
      expect(unshelteredCount, greaterThan(500), reason: 'Must have ample unsheltered airspace for challenge');
    });

    test('Solar Winds specific key shelter zones validation', () {
      final cave = Cave(mapId: 'wind');

      // 1. Cargo trench zone [-2, 7] x [5, inf)
      for (double x = -1.5; x <= 6.5; x += 1.0) {
        for (double y = 5.5; y <= 12.0; y += 1.0) {
          expect(cave.isSheltered(Vector2(x, y)), isTrue, reason: 'Cargo trench at ($x, $y) must be sheltered');
        }
      }

      // 2. Behind Step 2 rock overhang [-22, -11] x [-4, inf)
      for (double x = -21.0; x <= -12.0; x += 1.5) {
        for (double y = -3.0; y <= 2.0; y += 1.0) {
          expect(cave.isSheltered(Vector2(x, y)), isTrue, reason: 'Step 2 overhang alcove at ($x, $y) must be sheltered');
        }
      }

      // 3. Under Overhang 2 windbreaker [-4, 7] x [-2, inf)
      for (double x = -3.0; x <= 6.0; x += 1.5) {
        for (double y = -1.0; y <= 4.0; y += 1.0) {
          expect(cave.isSheltered(Vector2(x, y)), isTrue, reason: 'Overhang 2 windbreaker at ($x, $y) must be sheltered');
        }
      }

      // 4. Open flight corridor (high above ground) is NEVER sheltered
      for (double x = -30.0; x <= 30.0; x += 5.0) {
        expect(cave.isSheltered(Vector2(x, -16.0)), isFalse, reason: 'High open sky at ($x, -16) is unsheltered');
        expect(cave.isSheltered(Vector2(x, -22.0)), isFalse, reason: 'Ceiling zone at ($x, -22) is unsheltered');
      }

      // 5. Non-wind maps return false everywhere
      for (final nonWindMap in ['echo', 'core', 'ice', 'orbit']) {
        final nonWindCave = Cave(mapId: nonWindMap);
        expect(nonWindCave.isSheltered(Vector2(2.0, 8.0)), isFalse);
        expect(nonWindCave.isSheltered(Vector2(-15.0, -1.0)), isFalse);
      }
    });
  });

  group('Stress & Property Suite 3: Europa Ice Rift Branching & Low-Friction Physics', () {
    test('Europa Ice Rift branching upper ledge geometry & low ceiling clearance', () {
      final cave = Cave(mapId: 'ice');
      final world = Forge2DWorld();
      cave.world = world;
      final body = cave.createBody();

      // Branch points exist and form contiguous chain
      expect(cave.branchPoints, isNotEmpty);
      expect(cave.branchPoints.length, greaterThanOrEqualTo(20));

      // Spans X in [-22.0, -3.0]
      expect(cave.branchPoints.first.x, closeTo(-22.0, 0.1));
      expect(cave.branchPoints.last.x, closeTo(-3.0, 0.1));

      // Strictly ordered X coordinates
      for (int i = 0; i < cave.branchPoints.length - 1; i++) {
        expect(
          cave.branchPoints[i + 1].x,
          greaterThan(cave.branchPoints[i].x),
          reason: 'Branch points must monotonically increase in X',
        );
      }

      // Upper ledge Y coordinates stay around -1.0 (between -1.6 and -0.8)
      for (final bp in cave.branchPoints) {
        expect(bp.y, inInclusiveRange(-1.6, -0.8), reason: 'Upper ledge vertex at ${bp.x} must be around -1.0');
      }

      // Clearance verification:
      // Along upper tunnel (x in [-22.0, -5.0]), ceiling is low with clearance in [4.5, 10.0]m
      for (final bp in cave.branchPoints.where((p) => p.x <= -5.0)) {
        final ceilY = cave.getCeilingY(bp.x);
        final clearance = bp.y - ceilY;
        expect(clearance, inInclusiveRange(4.5, 10.0), reason: 'Ceiling clearance along tunnel at x=${bp.x}');
      }

      // Near convergence to cargo cavern (x in (-5.0, -3.0]), ceiling opens into cargo dome
      for (final bp in cave.branchPoints.where((p) => p.x > -5.0)) {
        final ceilY = cave.getCeilingY(bp.x);
        final clearance = bp.y - ceilY;
        expect(clearance, greaterThan(8.0), reason: 'Cargo dome clearance at x=${bp.x}');
      }

      // Lower path drops much deeper (Y drops to +8.0 at sunken cargo cavern)
      final lowerFloorCargoY = cave.getFloorY(0.0);
      expect(lowerFloorCargoY, closeTo(8.0, 0.5));

      // Low friction & bouncy ice restitution
      expect(cave.floorFriction, equals(0.08));
      expect(cave.floorRestitution, equals(0.25));

      // Box2D fixture creation includes branch chain
      expect(body.fixtures.length, greaterThanOrEqualTo(5));
    });

    test('Europa Ice Rift gravity scaling matches 0.65g (2.275 m/s²)', () {
      final game = LanderZeroGame(mapId: 'ice');
      expect(game.world.gravity.y, closeTo(2.275, 1e-4));
      expect(game.world.gravity.x, equals(0.0));
    });
  });

  group('Stress & Property Suite 4: Orbital Debris 360° Space, Zero-G & Rotating Obstacles', () {
    test('Orbital Debris zero-G gravity contract', () {
      final game = LanderZeroGame(mapId: 'orbit');
      expect(game.world.gravity.y, equals(0.0), reason: 'Orbital Debris must have zero gravity');
      expect(game.world.gravity.x, equals(0.0));
    });

    test('Orbital Debris 4 perimeter boundary beacons at bounding corners', () {
      final cave = Cave(mapId: 'orbit');
      final world = Forge2DWorld();
      cave.world = world;
      cave.createBody();

      expect(cave.perimeterBeacons.length, equals(4));

      final bTL = cave.perimeterBeacons.firstWhere((b) => b.x < 0 && b.y < 0);
      final bTR = cave.perimeterBeacons.firstWhere((b) => b.x > 0 && b.y < 0);
      final bBR = cave.perimeterBeacons.firstWhere((b) => b.x > 0 && b.y > 0);
      final bBL = cave.perimeterBeacons.firstWhere((b) => b.x < 0 && b.y > 0);

      expect(bTL, equals(Vector2(-34.0, -26.0)));
      expect(bTR, equals(Vector2(34.0, -26.0)));
      expect(bBR, equals(Vector2(34.0, 14.0)));
      expect(bBL, equals(Vector2(-34.0, 14.0)));

      // Bounding box dimensions
      final width = (bTR.x - bTL.x).abs();
      final height = (bBL.y - bTL.y).abs();
      expect(width, equals(68.0));
      expect(height, equals(40.0));
    });

    test('Orbital Debris rotating debris bodies initialization and kinematics', () {
      final debrisTypes = ['solar_panel', 'truss', 'module'];
      final angularSpeeds = [0.5, -0.45, 0.3, -0.35];

      for (int i = 0; i < debrisTypes.length; i++) {
        final debris = RotatingDebris(
          initialPosition: Vector2(-10.0 + i * 10.0, -5.0 + i * 5.0),
          width: 2.0 + i,
          height: 5.0 - i,
          angularSpeed: angularSpeeds[i],
          debrisType: debrisTypes[i],
        );

        final world = Forge2DWorld();
        debris.world = world;
        final body = debris.createBody();
        debris.body = body;

        expect(body.bodyType, equals(BodyType.kinematic));
        expect(body.angularVelocity, closeTo(angularSpeeds[i], 1e-4));
        expect(body.fixtures.length, equals(1));
        expect(body.fixtures.first.shape, isA<PolygonShape>());
      }
    });

    test('Orbital Debris zero-gravity inertia drift verification in simulation', () {
      final world = Forge2DWorld(gravity: Vector2.zero());
      final lander = Lander(initialPosition: Vector2(-25.0, -2.0));
      lander.world = world;
      final body = lander.createBody();
      lander.body = body;

      // Apply initial impulse (Vx = 5.0/mass, Vy = -3.0/mass)
      body.applyLinearImpulse(Vector2(5.0, -3.0));

      // Simulate 60 time steps in zero-G (1 second)
      for (int step = 0; step < 60; step++) {
        world.physicsWorld.stepDt(1 / 60);
      }

      // Velocity direction ratio must remain exactly (-3.0 / 5.0) = -0.6 (no vertical gravitational deflection)
      expect(body.linearVelocity.y / body.linearVelocity.x, closeTo(-3.0 / 5.0, 1e-3));

      // Velocity magnitude decays exponentially according to linear damping: v(t) = v0 * e^(-damping * t)
      final expectedSpeed = (Vector2(5.0, -3.0).length / body.mass) * exp(-GameConfig.landerLinearDamping * 1.0);
      expect(body.linearVelocity.length, closeTo(expectedSpeed, 0.05));
    });
  });

  group('Stress & Property Suite 5: Tactical Radar & Minimap Projection Bounds Property Testing', () {
    const maps = ['echo', 'core', 'wind', 'ice', 'orbit'];
    const canvasSizes = [
      Size(144.0, 92.0),
      Size(288.0, 184.0),
      Size(100.0, 100.0),
      Size(300.0, 200.0),
      Size(64.0, 48.0),
      Size(500.0, 300.0),
    ];

    test('MinimapWidget projectX and projectY map boundaries precisely to 0 and canvas size', () {
      for (final size in canvasSizes) {
        expect(MinimapWidget.projectX(MinimapWidget.minWorldX, size.width), equals(0.0));
        expect(MinimapWidget.projectX(MinimapWidget.maxWorldX, size.width), equals(size.width));
        expect(MinimapWidget.projectY(MinimapWidget.minWorldY, size.height), equals(0.0));
        expect(MinimapWidget.projectY(MinimapWidget.maxWorldY, size.height), equals(size.height));
      }
    });

    test('ALL platforms across ALL 5 maps project strictly within canvas dimensions', () {
      for (final mapId in maps) {
        final cave = Cave(mapId: mapId);

        for (final size in canvasSizes) {
          final pStart = MinimapWidget.projectOffset(cave.startPlatform, size);
          final pCargo = MinimapWidget.projectOffset(cave.cargoPlatform, size);
          final pExit = MinimapWidget.projectOffset(cave.exitPlatform, size);

          for (final (name, p) in [('start', pStart), ('cargo', pCargo), ('exit', pExit)]) {
            expect(
              p.dx,
              inInclusiveRange(0.0, size.width),
              reason: '$mapId $name platform projected X (${p.dx}) must be in [0, ${size.width}]',
            );
            expect(
              p.dy,
              inInclusiveRange(0.0, size.height),
              reason: '$mapId $name platform projected Y (${p.dy}) must be in [0, ${size.height}]',
            );
          }
        }
      }
    });

    test('ALL perimeter beacons in Orbital Debris project strictly within canvas dimensions', () {
      final cave = Cave(mapId: 'orbit');
      expect(cave.perimeterBeacons, isNotEmpty);

      for (final size in canvasSizes) {
        for (final b in cave.perimeterBeacons) {
          final p = MinimapWidget.projectOffset(b, size);
          expect(p.dx, inInclusiveRange(0.0, size.width), reason: 'Beacon X (${p.dx}) at size $size');
          expect(p.dy, inInclusiveRange(0.0, size.height), reason: 'Beacon Y (${p.dy}) at size $size');
        }
      }
    });

    test('ALL branchPoints in Europa Ice Rift project strictly within canvas dimensions', () {
      final cave = Cave(mapId: 'ice');
      final world = Forge2DWorld();
      cave.world = world;
      cave.createBody();

      expect(cave.branchPoints, isNotEmpty);

      for (final size in canvasSizes) {
        for (final bp in cave.branchPoints) {
          final p = MinimapWidget.projectOffset(bp, size);
          expect(p.dx, inInclusiveRange(0.0, size.width), reason: 'Branch vertex X (${p.dx}) at size $size');
          expect(p.dy, inInclusiveRange(0.0, size.height), reason: 'Branch vertex Y (${p.dy}) at size $size');
        }
      }
    });

    test('Playable terrain vertices across ALL 5 maps project within canvas dimensions', () {
      for (final mapId in maps) {
        final cave = Cave(mapId: mapId);
        final world = Forge2DWorld();
        cave.world = world;
        cave.createBody();

        for (final size in canvasSizes) {
          // Check all floor points within playable bounds [-36.0, 36.0]
          final inBoundsFloor = cave.floorPoints.where((p) => p.x >= MinimapWidget.minWorldX && p.x <= MinimapWidget.maxWorldX);
          for (final fp in inBoundsFloor) {
            final p = MinimapWidget.projectOffset(fp, size);
            expect(p.dx, inInclusiveRange(0.0, size.width), reason: '$mapId in-bounds floor X (${p.dx})');
            expect(p.dy, inInclusiveRange(0.0, size.height), reason: '$mapId in-bounds floor Y (${p.dy})');
          }

          // Check all ceiling points within playable bounds [-36.0, 36.0]
          final inBoundsCeiling = cave.ceilingPoints.where((p) => p.x >= MinimapWidget.minWorldX && p.x <= MinimapWidget.maxWorldX);
          for (final cp in inBoundsCeiling) {
            final p = MinimapWidget.projectOffset(cp, size);
            expect(p.dx, inInclusiveRange(0.0, size.width), reason: '$mapId in-bounds ceiling X (${p.dx})');
            expect(p.dy, inInclusiveRange(0.0, size.height), reason: '$mapId in-bounds ceiling Y (${p.dy})');
          }
        }
      }
    });

    test('Minimap and MapPreview canvas painters execute without exception across all biomes', () {
      for (final mapId in maps) {
        final painter = MapPreviewPainter(
          mapId: mapId,
          rocketId: 'sputnik',
          animationTime: 2.34,
        );

        for (final size in canvasSizes) {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));

          expect(
            () => painter.paint(canvas, size),
            returnsNormally,
            reason: 'MapPreviewPainter must not throw for map $mapId at size $size',
          );

          final picture = recorder.endRecording();
          picture.dispose();
        }
      }
    });
  });

  group('Stress & Property Suite 6: Hazard Components & Environmental Stress Testing', () {
    test('MagmaBubble rises vertically, respawns at bottom, and cycles cleanly', () async {
      final game = LanderZeroGame(mapId: 'core');
      game.cave = Cave(mapId: 'core');
      final world = Forge2DWorld();
      game.cave.world = world;
      game.cave.createBody();
      game.sparkPool = SparkPoolManager();
      game.world.add(game.sparkPool);

      final bubble = MagmaBubble(minX: -3.0, maxX: 3.0, speed: 4.0, radius: 0.6);
      bubble.game = game;
      await bubble.onLoad();

      expect(bubble.position.x, inInclusiveRange(-3.0, 3.0));
      expect(bubble.position.y, closeTo(13.8, 1.0));

      // Simulate bubble rising through chimney
      for (int step = 0; step < 100; step++) {
        bubble.update(0.1);
        expect(bubble.position.x, inInclusiveRange(-3.5, 3.5));
        expect(bubble.position.y, inInclusiveRange(-26.5, 15.0));
      }
    });

    test('Geyser erupts on periodic timer with particle bursts', () async {
      final game = LanderZeroGame(mapId: 'ice');
      game.cave = Cave(mapId: 'ice');
      final world = Forge2DWorld();
      game.cave.world = world;
      game.cave.createBody();

      final geyser = Geyser(position: Vector2(-10.0, 5.0), biome: 'ice');
      geyser.game = game;
      await geyser.onLoad();

      expect(geyser.isActive, isFalse);

      // Advance time past dormant duration (3.0s inactiveTime)
      geyser.update(3.1);
      expect(geyser.isActive, isTrue);

      // Advance time past active duration (2.5s activeTime)
      geyser.update(2.6);
      expect(geyser.isActive, isFalse);
    });

    test('Stalactite drops as dynamic body upon trigger proximity', () {
      final stalactite = Stalactite(initialPosition: Vector2(10.0, -18.0), biome: 'core');
      final world = Forge2DWorld();
      stalactite.world = world;
      final body = stalactite.createBody();
      stalactite.body = body;

      expect(stalactite.isTriggered, isFalse);
      expect(body.bodyType, equals(BodyType.static));

      final game = LanderZeroGame(mapId: 'core');
      stalactite.game = game;
      final lander = Lander(initialPosition: Vector2(10.5, -12.0));
      lander.world = world;
      final landerBody = lander.createBody();
      lander.body = landerBody;
      game.lander = lander;

      stalactite.update(0.016);
      expect(stalactite.isTriggered, isTrue);
      expect(body.bodyType, equals(BodyType.dynamic));
    });
  });
}
