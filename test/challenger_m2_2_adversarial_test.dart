import 'dart:math';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lander_zero/game/components/lander.dart';
import 'package:lander_zero/game/state/game_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GameState().init(force: true);
  });

  group('Adversarial Verification 1: G-Strain Physics Under Extreme Accelerations', () {
    test('1.1 High acceleration (50 m/s^2 to 500 m/s^2) produces clamped [0.0, 1.0] G-strain without NaN', () {
      final lander = Lander(initialPosition: Vector2.zero(), shipId: 'sputnik');
      final world = Forge2DWorld();
      lander.world = world;
      final body = lander.createBody();
      lander.body = body;

      // Baseline step
      lander.update(0.016);

      final extremeAccels = [50.0, 100.0, 250.0, 500.0, 1000.0];
      for (final targetAccel in extremeAccels) {
        // DeltaV = targetAccel * dt
        body.linearVelocity = Vector2(targetAccel * 0.016, 0.0);
        lander.update(0.016);

        expect(lander.gForce.isFinite, isTrue, reason: 'gForce must be finite for accel $targetAccel');
        expect(lander.gForce.isNaN, isFalse, reason: 'gForce must not be NaN for accel $targetAccel');
        expect(lander.gForce, greaterThan(2.5), reason: 'gForce must exceed panic threshold');
        expect(lander.gStrain, equals(1.0), reason: 'gStrain must clamp to exactly 1.0 under high G');
        expect(lander.isPanicking, isTrue, reason: 'Pilot must enter panic state under high G');
      }
    });

    test('1.2 Freefall (zero coordinate acceleration & zero gravity) yields zero G-strain', () {
      final lander = Lander(initialPosition: Vector2.zero(), shipId: 'swift');
      final world = Forge2DWorld(gravity: Vector2.zero()); // Zero-G orbit biome
      lander.world = world;
      final body = lander.createBody();
      lander.body = body;

      // Step 1: Establish steady drift velocity (no accel)
      body.linearVelocity = Vector2(5.0, 0.0);
      lander.update(0.016);

      // Step 2: Constant velocity -> accel = 0, gravity = 0
      lander.update(0.016);

      expect(lander.gForce, closeTo(0.0, 1e-4), reason: 'Zero-G drift must yield 0.0 G-force');
      expect(lander.gStrain, equals(0.0), reason: 'Zero-G drift must yield 0.0 G-strain');
      expect(lander.gStrain.isNaN, isFalse);
    });

    test('1.3 Inverse & arbitrary angled gravity vectors evaluate accurately without NaN', () {
      final gravityVectors = [
        Vector2(0.0, -9.81),  // Inverted gravity (ceiling pull)
        Vector2(-9.81, 0.0),  // Leftward gravity
        Vector2(9.81, 0.0),   // Rightward gravity
        Vector2(14.715, 14.715), // Diagonal heavy gravity (Deep Core)
      ];

      for (final grav in gravityVectors) {
        final lander = Lander(initialPosition: Vector2.zero(), shipId: 'titan');
        final world = Forge2DWorld(gravity: grav);
        lander.world = world;
        final body = lander.createBody();
        lander.body = body;

        body.linearVelocity = Vector2.zero();
        lander.update(0.016);
        lander.update(0.016);

        final expectedG = grav.length / 9.81;
        expect(lander.gForce, closeTo(expectedG, 1e-3), reason: 'Static G-force under gravity $grav must match');
        expect(lander.gStrain, greaterThanOrEqualTo(0.0));
        expect(lander.gStrain, lessThanOrEqualTo(1.0));
        expect(lander.gStrain.isFinite, isTrue);
      }
    });

    test('1.4 Degenerate time steps (dt <= 0.0001, dt = 100.0) do not cause division by zero or NaN', () {
      final lander = Lander(initialPosition: Vector2.zero(), shipId: 'cyclone');
      final world = Forge2DWorld();
      lander.world = world;
      final body = lander.createBody();
      lander.body = body;

      final degenerateDts = [0.0, -0.016, 0.000001, 0.0001, 10.0, 100.0];
      for (final dt in degenerateDts) {
        expect(() => lander.update(dt), returnsNormally);
        expect(lander.gForce.isFinite, isTrue);
        expect(lander.gForce.isNaN, isFalse);
        expect(lander.gStrain.isFinite, isTrue);
        expect(lander.gStrain.isNaN, isFalse);
      }
    });
  });

  group('Adversarial Verification 2: Eye-Tracking Trigonometry & Danger Vector Angles', () {
    test('2.1 Danger vectors across 360 degrees sweep produce zero NaN and strictly finite look vectors', () {
      final lander = Lander(initialPosition: Vector2.zero(), shipId: 'sputnik');
      final world = Forge2DWorld();
      lander.world = world;
      final body = lander.createBody();
      lander.body = body;

      for (int deg = 0; deg < 360; deg += 15) {
        final rad = deg * pi / 180.0;
        final velX = cos(rad) * 4.0;
        final velY = sin(rad) * 4.0;

        body.linearVelocity = Vector2(velX, velY);
        lander.update(0.016);

        expect(lander.lookDirection.x.isFinite, isTrue, reason: 'LookDir X must be finite at $deg deg');
        expect(lander.lookDirection.y.isFinite, isTrue, reason: 'LookDir Y must be finite at $deg deg');
        expect(lander.lookDirection.x.isNaN, isFalse, reason: 'LookDir X must not be NaN at $deg deg');
        expect(lander.lookDirection.y.isNaN, isFalse, reason: 'LookDir Y must not be NaN at $deg deg');

        // Look direction must align with velocity vector
        final expectedLookX = cos(rad) * 0.6;
        final expectedLookY = sin(rad) * 0.6;
        expect(lander.lookDirection.x, closeTo(expectedLookX, 0.01));
        expect(lander.lookDirection.y, closeTo(expectedLookY, 0.01));
      }
    });

    test('2.2 Zero velocity and micro-velocity vectors (speed <= 0.1) yield zero velocity look shift without NaN', () {
      final lander = Lander(initialPosition: Vector2.zero(), shipId: 'swift');
      final world = Forge2DWorld();
      lander.world = world;
      final body = lander.createBody();
      lander.body = body;

      final microVelocities = [
        Vector2.zero(),
        Vector2(0.01, 0.0),
        Vector2(0.0, 0.05),
        Vector2(0.07, 0.07),
        Vector2(-0.09, 0.0),
      ];

      for (final vel in microVelocities) {
        body.linearVelocity = vel;
        lander.update(0.016);

        expect(lander.lookDirection.x, equals(0.0), reason: 'Sub-0.1 speed must yield 0 lookDirection X');
        expect(lander.lookDirection.y, equals(0.0), reason: 'Sub-0.1 speed must yield 0 lookDirection Y');
        expect(lander.lookDirection.x.isNaN, isFalse);
        expect(lander.lookDirection.y.isNaN, isFalse);
      }
    });

    test('2.3 Pilot head offset spring-mass-damper remains bounded under erratic high-frequency impulses', () {
      final lander = Lander(initialPosition: Vector2.zero(), shipId: 'titan');
      final world = Forge2DWorld();
      lander.world = world;
      final body = lander.createBody();
      lander.body = body;

      final rng = Random(42);
      for (int step = 0; step < 200; step++) {
        final randVelX = (rng.nextDouble() - 0.5) * 50.0;
        final randVelY = (rng.nextDouble() - 0.5) * 50.0;
        body.linearVelocity = Vector2(randVelX, randVelY);
        body.angularVelocity = (rng.nextDouble() - 0.5) * 20.0;

        lander.update(0.016);

        expect(lander.headOffset.x.isFinite, isTrue);
        expect(lander.headOffset.y.isFinite, isTrue);
        expect(lander.headOffset.length, lessThanOrEqualTo(0.25),
            reason: 'Head offset must be clamped within 0.2m limit');
      }
    });
  });

  group('Adversarial Verification 3: Box2D Polygon Hitbox Validity for All 5 Fleet Vessels', () {
    // Exact polygon vertex definitions from Lander.dart
    final shipVertices = <String, List<Vector2>>{
      'sputnik': [
        Vector2(0.0, -1.2),
        Vector2(1.2, -0.4),
        Vector2(1.5, 0.8),
        Vector2(-1.5, 0.8),
        Vector2(-1.2, -0.4),
      ],
      'swift': [
        Vector2(0.0, -1.7),
        Vector2(0.8, -0.2),
        Vector2(1.0, 0.9),
        Vector2(-1.0, 0.9),
        Vector2(-0.8, -0.2),
      ],
      'titan': [
        Vector2(0.0, -1.3),
        Vector2(1.4, -0.5),
        Vector2(1.8, 0.6),
        Vector2(1.2, 1.2),
        Vector2(-1.2, 1.2),
        Vector2(-1.8, 0.6),
      ],
      'quasar': [
        Vector2(0.0, -1.5),
        Vector2(1.1, -0.4),
        Vector2(1.2, 0.4),
        Vector2(0.0, 0.9),
        Vector2(-1.2, 0.4),
        Vector2(-1.1, -0.4),
      ],
      'needle': [
        Vector2(0.0, -1.6),
        Vector2(0.8, -0.2),
        Vector2(0.9, 0.9),
        Vector2(-0.9, 0.9),
        Vector2(-0.8, -0.2),
      ],
      'cyclone': [
        Vector2(0.0, -1.3),
        Vector2(1.4, -0.6),
        Vector2(1.6, 1.0),
        Vector2(-1.6, 1.0),
        Vector2(-1.4, -0.6),
      ],
    };

    double calculateSignedArea(List<Vector2> verts) {
      double area = 0.0;
      final n = verts.length;
      for (int i = 0; i < n; i++) {
        final j = (i + 1) % n;
        area += verts[i].x * verts[j].y - verts[j].x * verts[i].y;
      }
      return area * 0.5;
    }

    test('3.1 All ship hitboxes have valid Box2D vertex counts (3 <= n <= 8)', () {
      shipVertices.forEach((shipId, verts) {
        expect(verts.length, greaterThanOrEqualTo(3), reason: '$shipId must have >= 3 vertices');
        expect(verts.length, lessThanOrEqualTo(8), reason: '$shipId must have <= 8 vertices for standard Box2D');
      });
    });

    test('3.2 All ship hitboxes have non-zero positive area (Shoelace Formula)', () {
      shipVertices.forEach((shipId, verts) {
        final signedArea = calculateSignedArea(verts);
        expect(signedArea.abs(), greaterThan(0.5), reason: '$shipId area must be non-degenerate (> 0.5 m^2)');
        expect(signedArea.isFinite, isTrue);
      });
    });

    test('3.3 All ship hitboxes are strictly convex with uniform edge cross products', () {
      shipVertices.forEach((shipId, verts) {
        final n = verts.length;
        double? prevCrossSign;

        for (int i = 0; i < n; i++) {
          final p0 = verts[i];
          final p1 = verts[(i + 1) % n];
          final p2 = verts[(i + 2) % n];

          final edge1 = Vector2(p1.x - p0.x, p1.y - p0.y);
          final edge2 = Vector2(p2.x - p1.x, p2.y - p1.y);

          // 2D cross product: e1.x * e2.y - e1.y * e2.x
          final cross = edge1.x * edge2.y - edge1.y * edge2.x;
          expect(cross.abs(), greaterThan(1e-4), reason: 'Collinear or degenerate edge found in $shipId at vertex $i');

          final sign = cross > 0 ? 1.0 : -1.0;
          if (prevCrossSign == null) {
            prevCrossSign = sign;
          } else {
            expect(sign, equals(prevCrossSign),
                reason: 'Concave / non-convex vertex found in $shipId at vertex $i (cross: $cross)');
          }
        }
      });
    });

    test('3.4 Forge2D PolygonShape.set successfully initializes and computes valid mass properties in physics world', () {
      final world = Forge2DWorld();
      for (final shipId in ['sputnik', 'swift', 'titan', 'needle', 'cyclone']) {
        final lander = Lander(initialPosition: Vector2.zero(), shipId: shipId);
        lander.world = world;
        final body = lander.createBody();

        expect(body.fixtures.length, equals(1));
        expect(body.mass, greaterThan(0.0), reason: '$shipId body mass must be positive');
        expect(body.inertia, greaterThan(0.0), reason: '$shipId rotational inertia must be positive');
        expect(body.worldCenter, isNotNull);
      }
    });
  });
}
