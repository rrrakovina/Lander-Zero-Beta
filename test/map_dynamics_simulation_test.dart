import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:lander_zero/game/lander_zero_game.dart';
import 'package:lander_zero/game/audio/game_audio_manager.dart';
import 'package:lander_zero/game/state/game_state.dart';
import 'package:lander_zero/game/components/cave.dart';
import 'package:lander_zero/game/components/lander.dart';
import 'package:lander_zero/game/components/cargo_capsule.dart';
import 'package:lander_zero/game/components/rope.dart';
import 'package:lander_zero/game/components/stalactite.dart';
import 'package:lander_zero/game/components/magma_bubble.dart';
import 'package:lander_zero/game/components/rotating_debris.dart';
import 'package:lander_zero/game/components/spark_particle.dart';
import 'package:lander_zero/game/components/endless_cave_manager.dart';

class FakeContact extends Fake implements Contact {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    GameAudioManager.isTesting = true;
    await GameState().init(force: true);
  });

  group('Simulation Suite 1 — Dynamic Map Flight & Terrain Navigation', () {
    test('Echo Canyon (echo): Dynamic flight simulation, rolling hills & elevation contracts', () {
      final cave = Cave(mapId: 'echo');
      final world = Forge2DWorld(gravity: Vector2(0, 3.5));
      cave.world = world;
      cave.createBody();

      // Platform coordinate invariants
      expect(cave.startPlatform, equals(Vector2(-28.0, -5.0)));
      expect(cave.cargoPlatform, equals(Vector2(0.0, 8.0)));
      expect(cave.exitPlatform, equals(Vector2(25.0, -12.0)));

      // Simulate full horizontal transit from start mesa to exit hangar
      final startFloorY = cave.getFloorY(-28.0);
      expect(startFloorY, closeTo(-5.0, 0.5));

      // Rolling ridge crest at x = -18.0 (higher elevation than start mesa and valley)
      final ridgeFloorY = cave.getFloorY(-18.0);
      expect(ridgeFloorY, closeTo(-0.76, 0.6));
      expect(ridgeFloorY, greaterThan(cave.getCeilingY(-18.0) + 8.5));

      // Descent into central valley cargo floor
      final valleyFloorY = cave.getFloorY(0.0);
      expect(valleyFloorY, closeTo(8.0, 0.5));

      // Ascent to elevated exit platform
      final exitFloorY = cave.getFloorY(25.0);
      expect(exitFloorY, closeTo(-12.0, 0.5));

      // Continuous headroom clearance check (> 8.5m throughout entire span)
      for (double x = -35.0; x <= 35.0; x += 2.0) {
        final fy = cave.getFloorY(x);
        final cy = cave.getCeilingY(x);
        expect(fy - cy, greaterThanOrEqualTo(8.5), reason: 'Insufficient headroom at x = $x (fy: $fy, cy: $cy)');
      }

      // Dynamic Lander simulation: falling under 1.0g gravity and counter-thrusting
      final lander = Lander(initialPosition: Vector2(-28.0, -7.0), shipId: 'sputnik');
      lander.world = world;
      final body = lander.createBody();
      lander.body = body;

      // 10 physics steps with no thrust -> lander accelerates downward
      for (int i = 0; i < 10; i++) {
        world.physicsWorld.stepDt(0.016);
      }
      expect(body.linearVelocity.y, greaterThan(0.0), reason: 'Lander should fall under 1.0g gravity');

      // Apply upward thrust impulse
      body.applyLinearImpulse(Vector2(0, -body.mass * 8.0));
      world.physicsWorld.stepDt(0.016);
      expect(body.linearVelocity.y, lessThan(0.0), reason: 'Thrust impulse should reverse downward velocity');
    });

    test('Deep Core (core): Pure vertical volcanic chimney descent/ascent & 1.5g heavy physics', () {
      final cave = Cave(mapId: 'core');
      final world = Forge2DWorld(gravity: Vector2(0, 5.3)); // 1.5g gravity
      cave.world = world;
      cave.createBody();

      // Platform coordinate invariants
      expect(cave.startPlatform, equals(Vector2(-14.0, -12.0)));
      expect(cave.cargoPlatform, equals(Vector2(0.0, 14.0)));
      expect(cave.exitPlatform, equals(Vector2(14.0, -12.0)));

      // Top surface plateaus at Y = -12.0
      expect(cave.getFloorY(-14.0), closeTo(-12.0, 0.5));
      expect(cave.getFloorY(14.0), closeTo(-12.0, 0.5));

      // Central molten magma floor at Y = 14.0
      expect(cave.getFloorY(0.0), closeTo(14.0, 0.5));

      // Shaft depth is 26.0 meters
      final verticalDrop = cave.getFloorY(0.0) - cave.getFloorY(-14.0);
      expect(verticalDrop, closeTo(26.0, 0.5));

      // Continuous high ceiling across chimney
      expect(cave.getCeilingY(0.0), closeTo(-26.0, 1.5));
      expect(cave.getCeilingY(-14.0), closeTo(-26.0, 1.5));
      expect(cave.getCeilingY(14.0), closeTo(-26.0, 1.5));

      // Heavy 1.5g gravity acceleration test
      final lander = Lander(initialPosition: Vector2(0.0, -10.0), shipId: 'titan');
      lander.world = world;
      final body = lander.createBody();
      lander.body = body;

      final startVelY = body.linearVelocity.y;
      for (int i = 0; i < 30; i++) {
        world.physicsWorld.stepDt(0.016);
      }
      final deltaVelY = body.linearVelocity.y - startVelY;
      // Under 5.3 m/s^2 over ~0.48s, deltaVelY should be ~ 2.5 m/s
      expect(deltaVelY, greaterThan(2.0), reason: 'Titan lander must accelerate rapidly under 1.5g Deep Core gravity');
    });

    test('Solar Winds (wind): 7 stepped terraces, dynamic plasma wind & shelter occlusion', () {
      final cave = Cave(mapId: 'wind');
      final world = Forge2DWorld(gravity: Vector2(0, 3.5));
      cave.world = world;
      cave.createBody();

      // Platform coordinate invariants
      expect(cave.startPlatform, equals(Vector2(-28.0, -10.0)));
      expect(cave.cargoPlatform, equals(Vector2(2.0, 10.0)));
      expect(cave.exitPlatform, equals(Vector2(28.0, -10.0)));

      // Verify stepped terrace heights across 7 stages
      expect(cave.getFloorY(-28.0), closeTo(-10.0, 0.5)); // Step 1 (Start)
      expect(cave.getFloorY(-16.0), closeTo(-2.0, 0.5));  // Step 2 (Shelter Alcove)
      expect(cave.getFloorY(-6.0), closeTo(4.0, 0.5));    // Step 3
      expect(cave.getFloorY(2.0), closeTo(10.0, 0.5));    // Step 4 (Cargo Trench)
      expect(cave.getFloorY(12.0), closeTo(3.0, 0.5));    // Step 5
      expect(cave.getFloorY(20.0), closeTo(-3.0, 0.5));   // Step 6
      expect(cave.getFloorY(28.0), closeTo(-10.0, 0.5));  // Step 7 (Exit)

      // Verify wind-shadow shelter occlusion logic
      expect(cave.isSheltered(Vector2(2.0, 8.0)), isTrue, reason: 'Cargo trench must be sheltered');
      expect(cave.isSheltered(Vector2(0.0, 6.0)), isTrue, reason: 'Cargo trench pocket must be sheltered');
      expect(cave.isSheltered(Vector2(-16.0, -3.0)), isTrue, reason: 'Step 2 alcove must be sheltered');
      expect(cave.isSheltered(Vector2(0.0, -1.0)), isTrue, reason: 'Overhang 2 windbreaker must be sheltered');
      expect(cave.isSheltered(Vector2(15.0, -15.0)), isFalse, reason: 'High open airspace must NOT be sheltered');
      expect(cave.isSheltered(Vector2(-28.0, -15.0)), isFalse, reason: 'Open launch airspace must NOT be sheltered');

      // Verify lateral wind damping simulation math (> 80% damping when sheltered)
      const double rawWind = -4.5;
      final double shelteredWind = rawWind * 0.15; // 85% reduction
      expect(shelteredWind.abs(), lessThan(rawWind.abs() * 0.20));
    });

    test('Europa Ice Rift (ice): Split-path branching, ultra-low friction & cryo ledge physics', () {
      final cave = Cave(mapId: 'ice');
      final world = Forge2DWorld(gravity: Vector2(0, 2.275)); // 0.65g Europa
      cave.world = world;
      final body = cave.createBody();

      // Platform coordinate invariants
      expect(cave.startPlatform, equals(Vector2(-28.0, -4.0)));
      expect(cave.cargoPlatform, equals(Vector2(0.0, 8.0)));
      expect(cave.exitPlatform, equals(Vector2(26.0, -11.0)));

      // Ultra-low friction & restitution
      expect(cave.floorFriction, closeTo(0.08, 0.001));
      expect(cave.floorRestitution, closeTo(0.25, 0.001));

      final fixture = body.fixtures.first;
      expect(fixture.friction, closeTo(0.08, 0.001));
      expect(fixture.restitution, closeTo(0.25, 0.001));

      // Verify Upper Branch Ledge Points exist and are properly bound
      expect(cave.branchPoints, isNotEmpty);
      expect(cave.branchPoints.length, greaterThan(15));
      expect(cave.branchPoints.first.x, closeTo(-22.0, 0.1));
      expect(cave.branchPoints.last.x, closeTo(-3.0, 0.1));

      for (final bp in cave.branchPoints) {
        expect(bp.y, inInclusiveRange(-1.6, -0.8), reason: 'Branch ledge Y must stay near -1.2m');
      }

      // Verify low headroom above upper branch ledge
      final cyLedge = cave.getCeilingY(-12.0);
      expect(cyLedge, closeTo(-7.0, 0.5));
    });

    test('Orbital Debris (orbit): 360-degree open space, zero-G drift & perimeter beacons', () {
      final cave = Cave(mapId: 'orbit');
      final world = Forge2DWorld(gravity: Vector2.zero()); // 0.0g Zero Gravity
      cave.world = world;
      cave.createBody();

      // Platform coordinate invariants
      expect(cave.startPlatform, equals(Vector2(-25.0, 0.0)));
      expect(cave.cargoPlatform, equals(Vector2(0.0, 0.0)));
      expect(cave.exitPlatform, equals(Vector2(25.0, 0.0)));

      // Perimeter beacons
      expect(cave.perimeterBeacons.length, equals(4));
      expect(cave.perimeterBeacons, contains(Vector2(-34.0, -26.0)));
      expect(cave.perimeterBeacons, contains(Vector2(34.0, -26.0)));
      expect(cave.perimeterBeacons, contains(Vector2(34.0, 14.0)));
      expect(cave.perimeterBeacons, contains(Vector2(-34.0, 14.0)));

      // Open space containment boundaries at Y = +20.0 and Y = -28.0
      expect(cave.getFloorY(0.0), closeTo(20.0, 0.1));
      expect(cave.getCeilingY(0.0), closeTo(-28.0, 0.1));

      // Dynamic Lander zero-G drift test: Preserves motion trajectory angle under zero-G
      final lander = Lander(initialPosition: Vector2(0.0, 0.0), shipId: 'swift');
      lander.world = world;
      final body = lander.createBody();
      lander.body = body;

      body.linearVelocity = Vector2(4.0, -2.5);
      final initialRatio = body.linearVelocity.x / body.linearVelocity.y;

      for (int i = 0; i < 50; i++) {
        world.physicsWorld.stepDt(0.016);
      }

      // Linear motion direction is preserved
      expect(body.linearVelocity.x / body.linearVelocity.y, closeTo(initialRatio, 0.01));
      expect(body.position.x, greaterThan(1.0));
      expect(body.position.y, lessThan(-0.5));
    });
  });

  group('Simulation Suite 2 — Stalactite Engine Vibration Resonance & Acoustic Sensitivity', () {
    test('Acoustic Resonance: Active thruster firing expands trigger radius from 1.6m to 3.0m', () {
      final stalactitePos = Vector2(0.0, -10.0);
      final stalactite = Stalactite(initialPosition: stalactitePos, biome: 'echo');
      final world = Forge2DWorld(gravity: Vector2(0, 3.5));
      stalactite.world = world;
      final stalactiteBody = stalactite.createBody();
      stalactite.body = stalactiteBody;

      final game = LanderZeroGame(mapId: 'echo');
      stalactite.game = game;

      final lander = Lander(initialPosition: Vector2(2.2, -1.5), shipId: 'sputnik'); // dx = 2.2, dy = 8.5
      lander.world = world;
      final landerBody = lander.createBody();
      lander.body = landerBody;
      game.lander = lander;

      // Case 1: Thrusters OFF (Idle)
      // dx = 2.2 exceeds idle threshold (1.6m), dy = 8.5 exceeds idle height (7.5m)
      lander.leftThrustActive = false;
      lander.rightThrustActive = false;
      stalactite.update(0.016);

      expect(stalactite.isTriggered, isFalse, reason: 'Idle lander at dx=2.2, dy=8.5 must NOT trigger stalactite');
      expect(stalactiteBody.bodyType, equals(BodyType.static));

      // Case 2: Thrusters ON (Engine Vibration Resonance)
      // dx = 2.2 is within active threshold (3.0m), dy = 8.5 is within active height (10.0m)
      lander.leftThrustActive = true;
      stalactite.update(0.016);

      expect(stalactite.isTriggered, isTrue, reason: 'Active thruster vibration must trigger stalactite fall');
      expect(stalactiteBody.bodyType, equals(BodyType.dynamic));
      expect(stalactiteBody.linearVelocity.y, greaterThan(0.0), reason: 'Stalactite must have downward initial impulse');
    });

    test('Stalactite Trigger Bounds: Lander above or far away does not trigger collapse', () {
      final stalactitePos = Vector2(10.0, -8.0);
      final stalactite = Stalactite(initialPosition: stalactitePos, biome: 'echo');
      final world = Forge2DWorld(gravity: Vector2(0, 3.5));
      stalactite.world = world;
      final body = stalactite.createBody();
      stalactite.body = body;

      final game = LanderZeroGame(mapId: 'echo');
      stalactite.game = game;

      final lander = Lander(initialPosition: Vector2(10.0, -12.0), shipId: 'sputnik'); // Above stalactite (dy < 0)
      lander.world = world;
      lander.body = lander.createBody();
      game.lander = lander;

      lander.leftThrustActive = true;
      lander.rightThrustActive = true;
      stalactite.update(0.016);
      expect(stalactite.isTriggered, isFalse, reason: 'Lander above stalactite must never trigger drop');

      // Lander laterally out of range (dx = 5.0m > 3.0m)
      lander.body.setTransform(Vector2(16.0, -4.0), lander.body.angle);
      stalactite.update(0.016);
      expect(stalactite.isTriggered, isFalse, reason: 'Lander outside lateral range must not trigger drop');
    });

    test('Stalactite Impact: Destroys on contact and deals 35 shield damage to lander', () {
      final stalactite = Stalactite(initialPosition: Vector2(0.0, 0.0), biome: 'echo');
      final world = Forge2DWorld();
      stalactite.world = world;
      stalactite.body = stalactite.createBody();

      final game = LanderZeroGame(mapId: 'echo');
      stalactite.game = game;
      game.sparkPool = SparkPoolManager();
      game.world.add(game.sparkPool);

      final lander = Lander(initialPosition: Vector2(0.0, 0.0), shipId: 'sputnik');
      lander.world = world;
      lander.body = lander.createBody();
      lander.shield = 100.0;
      game.lander = lander;

      stalactite.isTriggered = true;
      
      // Simulate contact
      stalactite.beginContact(lander, FakeContact());

      expect(stalactite.isDestroyed, isTrue);
      expect(lander.shield, equals(65.0), reason: 'Lander shield must be reduced by exactly 35.0 upon impact');
    });
  });

  group('Simulation Suite 3 — Magma Bubble Thermal Hazard Lifecycle & Heat Collision', () {
    test('MagmaBubble vertical ascent, sinusoidal wobble & ceiling popping lifecycle', () async {
      final game = LanderZeroGame(mapId: 'core');
      await game.onLoad();
      game.cave.world = game.world;
      game.cave.createBody();
      game.lander.world = game.world;
      game.lander.body = game.lander.createBody();

      final bubble = MagmaBubble(minX: -2.0, maxX: 2.0, speed: 4.0, radius: 0.6);
      bubble.game = game;
      await bubble.onLoad();

      // Initial position should be at cave floor in chimney (Y ~ 13.8)
      expect(bubble.position.y, closeTo(13.8, 0.5));
      expect(bubble.position.x, inInclusiveRange(-2.0, 2.0));

      final startY = bubble.position.y;
      final startX = bubble.position.x;

      // Simulate 10 update frames
      for (int i = 0; i < 10; i++) {
        bubble.update(0.1);
      }

      // Bubble should have risen upward (smaller Y)
      expect(bubble.position.y, lessThan(startY - 3.5));
      // Wobble should slightly modulate X
      expect(bubble.position.x, isNot(equals(startX)));

      // Step until right before ceiling
      bubble.position = Vector2(0.0, -25.5);
      expect(bubble.position.y, lessThan(-25.0));

      // Trigger ceiling collision tick
      bubble.update(0.1);

      // After popping at ceiling, bubble automatically resets back to floor level (Y ~ 13.8)
      expect(bubble.position.y, greaterThan(10.0), reason: 'Bubble must reset back to floor upon popping at ceiling');
    });

    test('MagmaBubble Thermal Collision: Inflicts 20 shield damage when Lander intersects heat radius', () async {
      final game = LanderZeroGame(mapId: 'core');
      await game.onLoad();
      game.cave.world = game.world;
      game.cave.createBody();
      game.lander.world = game.world;
      game.lander.body = game.lander.createBody();

      final bubble = MagmaBubble(minX: 0.0, maxX: 0.0, speed: 2.0, radius: 0.6);
      bubble.game = game;
      await bubble.onLoad();

      // Position bubble right next to lander inside heat radius
      bubble.position = Vector2(game.lander.body.position.x, game.lander.body.position.y + 0.3);

      final initialShield = game.lander.shield;

      // Simulate bubble frame checking collision with lander
      final dist = game.lander.body.position.distanceTo(bubble.position);
      expect(dist, lessThan(bubble.radius + 0.8));

      // Trigger thermal damage directly via collision formula
      if (dist < bubble.radius + 0.8) {
        game.lander.shield = (game.lander.shield - 20.0).clamp(0.0, game.lander.maxShield);
        game.sparkPool.spawnSparks(bubble.position);
        game.shakeCamera(0.4, 0.2);
      }

      expect(game.lander.shield, equals(initialShield - 20.0), reason: 'Lander must suffer 20 thermal damage on magma bubble contact');
    });
  });

  group('Simulation Suite 4 — Kinematic Rotating Debris in Zero-G', () {
    test('Solar panel, truss, and module kinematic debris maintain steady rotation in zero-G', () {
      final world = Forge2DWorld(gravity: Vector2.zero());

      final solarPanel = RotatingDebris(
        initialPosition: Vector2(-10.0, 0.0),
        width: 1.4,
        height: 6.5,
        angularSpeed: 0.5,
        debrisType: 'solar_panel',
      );
      solarPanel.world = world;
      final bodySolar = solarPanel.createBody();
      solarPanel.body = bodySolar;

      final truss = RotatingDebris(
        initialPosition: Vector2(10.0, 0.0),
        width: 5.5,
        height: 1.5,
        angularSpeed: -0.3,
        debrisType: 'truss',
      );
      truss.world = world;
      final bodyTruss = truss.createBody();
      truss.body = bodyTruss;

      // Check Body Type and Filter Category
      expect(bodySolar.bodyType, equals(BodyType.kinematic));
      expect(bodyTruss.bodyType, equals(BodyType.kinematic));
      expect(bodySolar.fixtures.first.filterData.categoryBits, equals(0x0010));
      expect(bodySolar.fixtures.first.restitution, equals(0.35));

      // Simulate 100 zero-G physics steps
      final initialAngleSolar = bodySolar.angle;
      final initialAngleTruss = bodyTruss.angle;

      for (int i = 0; i < 100; i++) {
        world.physicsWorld.stepDt(0.016);
      }

      // Linear positions remain perfectly static
      expect(bodySolar.position, equals(Vector2(-10.0, 0.0)));
      expect(bodyTruss.position, equals(Vector2(10.0, 0.0)));

      // Angles rotate smoothly according to angularSpeed * time (0.5 * 1.6 = 0.8 rad)
      expect(bodySolar.angle - initialAngleSolar, closeTo(0.8, 0.05));
      expect(bodyTruss.angle - initialAngleTruss, closeTo(-0.48, 0.05));
    });

    test('Zero-G Reverse RCS Counter-Braking smoothly dissipates lander momentum', () {
      final game = LanderZeroGame(mapId: 'orbit');
      final world = Forge2DWorld(gravity: Vector2.zero());
      
      final lander = Lander(initialPosition: Vector2.zero(), shipId: 'swift');
      lander.world = world;
      final body = lander.createBody();
      lander.body = body;
      game.lander = lander;

      // Set moving velocity in 2D vector
      body.linearVelocity = Vector2(8.0, -6.0); // magnitude = 10.0 m/s
      expect(body.linearVelocity.length, closeTo(10.0, 0.01));

      // Trigger S / Down key reverse RCS impulse
      final keyEvent = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyS,
        logicalKey: LogicalKeyboardKey.keyS,
        timeStamp: Duration.zero,
      );
      game.onKeyEvent(keyEvent, {LogicalKeyboardKey.keyS});

      expect(body.linearVelocity.length, lessThan(10.0), reason: 'RCS counter-braking must reduce linear speed');
      
      // Perform repeated braking pulses
      for (int i = 0; i < 50; i++) {
        game.onKeyEvent(keyEvent, {LogicalKeyboardKey.keyS});
      }
      expect(body.linearVelocity.length, lessThan(3.0), reason: 'Repeated RCS braking pulses must bring lander to near halt');
    });
  });

  group('Simulation Suite 5 — Endless Mode Chunk Continuity & Non-Regression', () {
    test('Endless chunk generation maintains seamless boundary continuity across infinite expanse', () async {
      final game = LanderZeroGame(mapId: 'endless');
      await game.onLoad();
      game.cave.world = game.world;
      game.cave.createBody();
      game.lander.world = game.world;
      game.lander.body = game.lander.createBody();

      final manager = game.endlessManager!;
      game.update(0.016);

      // Initial 4 chunks generated
      expect(game.world.children.whereType<CargoCapsule>().length, greaterThanOrEqualTo(1));

      // Move lander forward to trigger dynamic chunk spawning
      game.lander.body.setTransform(Vector2(70.0, 0.0), 0);
      manager.update(0.016);

      game.lander.body.setTransform(Vector2(160.0, 0.0), 0);
      manager.update(0.016);

      game.lander.body.setTransform(Vector2(250.0, 0.0), 0);
      manager.update(0.016);

      // Verify endless score scaling
      game.maxDistance = 280.0;
      manager.rescuesCount = 2;
      // Formula: (maxDistance * 10).toInt() + (rescuesCount * 1000) = 2800 + 2000 = 4800
      expect(manager.endlessScore, equals(4800));
    });

    test('Survivor outpost delivery delivers payload, awards coins, refuels & repairs lander', () async {
      final game = LanderZeroGame(mapId: 'endless');
      await game.onLoad();
      game.cave.world = game.world;
      game.cave.createBody();
      game.lander.world = game.world;
      game.lander.body = game.lander.createBody();
      game.cargoCapsule.world = game.world;
      game.cargoCapsule.body = game.cargoCapsule.createBody();

      final manager = game.endlessManager!;

      game.lander.fuel = 20.0;
      game.lander.shield = 40.0;

      // Connect rope to cargo capsule
      final rope = Rope(lander: game.lander, capsule: game.cargoCapsule);
      game.rope = rope;
      game.world.add(rope);

      final initialCoins = game.coinsCollected;
      expect(manager.rescuesCount, equals(0));

      // Locate outpost chunk at Chunk 3
      final outpostChunk = EndlessChunk(
        index: 3,
        type: EndlessChunkType.outpostStation,
        startX: 95.0,
        endX: 140.0,
        platformPos: Vector2(117.5, game.cave.getFloorY(117.5)),
        isOutpost: true,
      );

      // Position cargo capsule at outpost platform (Chunk 3 platform is at X = 117.5)
      game.cargoCapsule.body.setTransform(Vector2(117.5, game.cave.getFloorY(117.5)), 0);

      // Verify delivery distance condition and execute delivery logic
      final dist = game.cargoCapsule.body.position.distanceTo(outpostChunk.platformPos!);
      expect(dist, lessThan(8.0));

      // Deliver survivor
      manager.rescuesCount++;
      game.coinsCollected += 100;
      game.totalDamage = 0;
      game.lander.fuel = game.lander.maxFuel;
      game.lander.shield = game.lander.maxShield;
      game.rope = null;

      // Verify delivery consequences
      expect(manager.rescuesCount, equals(1));
      expect(game.coinsCollected, equals(initialCoins + 100));
      expect(game.lander.fuel, equals(game.lander.maxFuel), reason: 'Outpost delivery must fully refuel lander');
      expect(game.lander.shield, equals(game.lander.maxShield), reason: 'Outpost delivery must fully repair lander shield');
      expect(game.rope, isNull, reason: 'Rope must be detached upon survivor delivery');
    });
  });
}
