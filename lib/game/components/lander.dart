import 'dart:math';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import '../../ui/painters/ship_mesh_renderer.dart';
import '../config/game_config.dart';
import '../state/game_state.dart';
import '../audio/game_audio_manager.dart';
import '../lander_zero_game.dart';
import 'thruster_flame.dart';
import 'coin.dart';
import 'fuel_pickup.dart';
import 'repair_pickup.dart';

/// Flame/Forge2D physics component representing the player lander vessel.
/// Delegates visual rendering to [ShipMeshRenderer] and simulates dynamic
/// pilot dynamics (G-strain, danger eye-tracking, panic blinks, head inertia).
class Lander extends BodyComponent with ContactCallbacks {
  final Vector2 initialPosition;

  // Lander Parameters
  String rocketId = 'sputnik';
  double maxFuel = 150.0;
  double maxShield = 100.0;
  double thrustPower = 32.0;
  double fuelConsumption = GameConfig.landerFuelConsumption;
  double massMultiplier = 1.0;

  double fuel = 150.0;
  double shield = 100.0;
  double _smokeTimer = 0.0;
  bool exploded = false;
  double _totalTime = 0.0;
  double _shieldHitTimer = 0.0;

  Lander({required this.initialPosition, String? shipId}) {
    rocketId = shipId ?? GameState().selectedRocket;
    final config = GameState.rocketConfigs[rocketId] ?? GameState.rocketConfigs['sputnik']!;
    final progress = GameState();

    final double engineFactor = 1.0 + (progress.engineLevel - 1) * 0.15;
    final double fuelFactor = 1.0 + (progress.fuelLevel - 1) * 0.25;
    final double shieldFactor = 1.0 + (progress.shieldLevel - 1) * 0.30;

    thrustPower = config['baseThrust'] * engineFactor;
    maxFuel = config['baseFuel'] * fuelFactor;
    maxShield = config['baseShield'] * shieldFactor;
    massMultiplier = config['mass'];
    fuelConsumption = GameConfig.landerFuelConsumption;

    fuel = maxFuel;
    shield = maxShield;
  }

  // Thruster Flames
  late final ThrusterFlame leftFlame;
  late final ThrusterFlame rightFlame;

  // Control State
  bool leftThrustActive = false;
  bool rightThrustActive = false;

  // Dynamic Pilot Physics Simulation State
  final Vector2 headOffset = Vector2.zero();
  final Vector2 headVelocity = Vector2.zero();
  final Vector2 lookDirection = Vector2.zero();
  final Vector2 _prevVelocity = Vector2.zero();

  double gForce = 1.0;
  double gStrain = 0.0;
  bool isPanicking = false;
  bool isBlinking = false;
  double _blinkTimer = 0.0;
  double _blinkDuration = 0.0;

  // Squash & Stretch Elastic Deformation
  double scaleX = 1.0;
  double scaleY = 1.0;
  double squashTimer = 0.0;

  int contactCount = 0;
  bool get isGrounded => contactCount > 0;
  double legsCompression = 0.0;

  // Overturned / Stuck State Tracking
  bool isStuck = false;
  double _stuckDuration = 0.0;

  void triggerSquash(double targetX, double targetY, double duration) {
    scaleX = targetX;
    scaleY = targetY;
    squashTimer = duration;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final progress = GameState();
    rocketId = progress.selectedRocket;
    final config = GameState.rocketConfigs[rocketId] ?? GameState.rocketConfigs['sputnik']!;

    final double engineFactor = 1.0 + (progress.engineLevel - 1) * 0.15;
    final double fuelFactor = 1.0 + (progress.fuelLevel - 1) * 0.25;
    final double shieldFactor = 1.0 + (progress.shieldLevel - 1) * 0.30;

    thrustPower = config['baseThrust'] * engineFactor;
    maxFuel = config['baseFuel'] * fuelFactor;
    maxShield = config['baseShield'] * shieldFactor;
    massMultiplier = config['mass'];
    fuelConsumption = GameConfig.landerFuelConsumption;

    fuel = maxFuel;
    shield = maxShield;

    leftFlame = ThrusterFlame(position: Vector2.zero());
    rightFlame = ThrusterFlame(position: Vector2.zero());

    game.world.add(leftFlame);
    game.world.add(rightFlame);
  }

  @override
  void onRemove() {
    GameAudioManager().stopThrustLoop();
    leftFlame.removeFromParent();
    rightFlame.removeFromParent();
    super.onRemove();
  }

  @override
  Body createBody() {
    final progress = GameState();
    final rId = rocketId.isNotEmpty ? rocketId : progress.selectedRocket;
    final config = GameState.rocketConfigs[rId] ?? GameState.rocketConfigs['sputnik']!;
    final massMult = config['mass'] as double;

    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: initialPosition,
      angularDamping: GameConfig.landerAngularDamping,
      linearDamping: GameConfig.landerLinearDamping,
    );

    final body = world.createBody(bodyDef);
    body.userData = this;

    // Custom Box2D Polygon Hitbox Vertices per Ship Profile (CCW strictly convex)
    List<Vector2> vertices;
    switch (rId) {
      case 'swift':
        vertices = [
          Vector2(0.0, -1.7),
          Vector2(0.8, -0.2),
          Vector2(1.0, 0.9),
          Vector2(-1.0, 0.9),
          Vector2(-0.8, -0.2),
        ];
        break;

      case 'titan':
        vertices = [
          Vector2(0.0, -1.3),
          Vector2(1.4, -0.5),
          Vector2(1.8, 0.6),
          Vector2(1.2, 1.2),
          Vector2(-1.2, 1.2),
          Vector2(-1.8, 0.6),
        ];
        break;

      case 'quasar':
        vertices = [
          Vector2(0.0, -1.5),
          Vector2(1.1, -0.4),
          Vector2(1.2, 0.4),
          Vector2(0.0, 0.9),
          Vector2(-1.2, 0.4),
          Vector2(-1.1, -0.4),
        ];
        break;

      case 'needle':
        vertices = [
          Vector2(0.0, -1.6),
          Vector2(0.8, -0.2),
          Vector2(0.9, 0.9),
          Vector2(-0.9, 0.9),
          Vector2(-0.8, -0.2),
        ];
        break;

      case 'cyclone':
        vertices = [
          Vector2(0.0, -1.3),
          Vector2(1.4, -0.6),
          Vector2(1.6, 1.0),
          Vector2(-1.6, 1.0),
          Vector2(-1.4, -0.6),
        ];
        break;

      case 'sputnik':
      default:
        vertices = [
          Vector2(0.0, -1.2),
          Vector2(1.2, -0.4),
          Vector2(1.5, 0.8),
          Vector2(-1.5, 0.8),
          Vector2(-1.2, -0.4),
        ];
        break;
    }

    final shape = PolygonShape()..set(vertices);

    final fixtureDef = FixtureDef(
      shape,
      density: 1.0 * massMult,
      friction: 0.8,
      restitution: 0.1,
    )
      ..filter.categoryBits = 0x0002
      ..filter.maskBits = 0xFFFF & ~0x0004 & ~0x0008;

    body.createFixture(fixtureDef);
    return body;
  }

  /// Returns nozzle offset in local coordinates for thrusters.
  Vector2 _getLeftNozzleOffset() {
    switch (rocketId) {
      case 'swift':
        return Vector2(-0.6, 0.95);
      case 'titan':
        return Vector2(-1.2, 1.25);
      case 'quasar':
      case 'needle':
        return Vector2(-0.7, 0.9);
      case 'cyclone':
        return Vector2(-1.3, 1.0);
      case 'sputnik':
      default:
        return Vector2(-1.2, 0.8);
    }
  }

  Vector2 _getRightNozzleOffset() {
    switch (rocketId) {
      case 'swift':
        return Vector2(0.6, 0.95);
      case 'titan':
        return Vector2(1.2, 1.25);
      case 'quasar':
      case 'needle':
        return Vector2(0.7, 0.9);
      case 'cyclone':
        return Vector2(1.3, 1.0);
      case 'sputnik':
      default:
        return Vector2(1.2, 0.8);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _totalTime += dt;
    if (_shieldHitTimer > 0) {
      _shieldHitTimer -= dt;
    }

    final dynamic gameRef = isMounted ? game : null;
    if (fuel <= 0 || (gameRef != null && gameRef.runStateNotifier?.value != GameRunState.playing)) {
      leftThrustActive = false;
      rightThrustActive = false;
    }

    final isAnyThrust = leftThrustActive || rightThrustActive;
    if (isAnyThrust) {
      GameAudioManager().startThrustLoop();
    } else {
      GameAudioManager().stopThrustLoop();
    }
    super.update(dt);

    try {
      final _ = body;
    } catch (_) {
      return;
    }

    final leftNozzle = _getLeftNozzleOffset();
    final rightNozzle = _getRightNozzleOffset();

    // Position Flame Effects if mounted
    try {
      if (leftFlame.isMounted) {
        leftFlame.position = body.worldPoint(leftNozzle);
        leftFlame.angle = body.angle;
        leftFlame.isActive = leftThrustActive;
      }

      if (rightFlame.isMounted) {
        rightFlame.position = body.worldPoint(rightNozzle);
        rightFlame.angle = body.angle;
        rightFlame.isActive = rightThrustActive;
      }
    } catch (_) {
      // Flames might not be initialized in headless unit tests
    }

    // --- Dynamic Pilot Physics Simulation ---
    final velocity = body.linearVelocity;
    final angularVel = body.angularVelocity;

    // 1. Calculate Instantaneous G-Force Acceleration
    if (dt > 0.0001) {
      final accelX = (velocity.x - _prevVelocity.x) / dt;
      final accelY = (velocity.y - _prevVelocity.y) / dt;
      final worldGravity = world.gravity;
      final totalAx = accelX + worldGravity.x;
      final totalAy = accelY + worldGravity.y;
      final totalAccMag = sqrt(totalAx * totalAx + totalAy * totalAy);
      gForce = totalAccMag / 9.81;
      gStrain = ((gForce - 1.0) / 2.5).clamp(0.0, 1.0);
      _prevVelocity.setFrom(velocity);
    }

    // 2. Head Inertia (Spring-Mass-Damper Model)
    final targetOffset = Vector2(
      -velocity.x * 0.02,
      (-velocity.y - 3.5).clamp(-10.0, 10.0) * 0.015 - angularVel * 0.01,
    );
    final springForce = (targetOffset - headOffset) * 12.0;
    headVelocity.x += (springForce.x - headVelocity.x * 4.0) * dt;
    headVelocity.y += (springForce.y - headVelocity.y * 4.0) * dt;
    headOffset.x += headVelocity.x * dt;
    headOffset.y += headVelocity.y * dt;

    if (headOffset.length2 > 0.04) {
      headOffset.setFrom(headOffset.normalized() * 0.2);
    }

    // 3. Danger Vector & Dynamic Eye Look Tracking
    final speedVal = velocity.length;
    final bool isLowShield = maxShield > 0 && (shield / maxShield < 0.35);
    final bool isLowFuel = maxFuel > 0 && (fuel / maxFuel < 0.20);
    isPanicking = gForce > 2.5 || speedVal > 5.5 || isLowShield || isLowFuel;

    // Look vector blend: 60% velocity vector + 40% threat direction
    Vector2 threatDir = Vector2.zero();
    if (gameRef is LanderZeroGame && gameRef.isLoaded == true) {
      try {
        final landerPos = body.position;
        final cave = gameRef.cave;
        final floorY = cave.getFloorY(landerPos.x);
        final ceilY = cave.getCeilingY(landerPos.x);
        final distFloor = (floorY - landerPos.y).abs();
        final distCeil = (ceilY - landerPos.y).abs();

        if (distFloor < 4.0) {
          threatDir = Vector2(0, 1.0);
        } else if (distCeil < 4.0) {
          threatDir = Vector2(0, -1.0);
        }
      } catch (_) {}
    }

    Vector2 velDir = Vector2.zero();
    if (speedVal > 0.1) {
      velDir = velocity.normalized();
    }

    lookDirection.x = velDir.x * 0.6 + threatDir.x * 0.4;
    lookDirection.y = velDir.y * 0.6 + threatDir.y * 0.4;

    // 4. Panic Blinking Flutter
    _blinkTimer += dt;
    final double blinkInterval = isPanicking ? 1.2 : 3.5;
    if (_blinkTimer >= blinkInterval) {
      isBlinking = true;
      _blinkDuration += dt;
      if (_blinkDuration >= 0.12) {
        isBlinking = false;
        _blinkDuration = 0.0;
        _blinkTimer = 0.0;
      }
    } else {
      isBlinking = false;
    }

    // Left Thruster Propulsion
    if (leftThrustActive) {
      final localForce = Vector2(0, -thrustPower);
      final worldForce = body.worldVector(localForce);
      final worldPoint = body.worldPoint(leftNozzle);
      body.applyForce(worldForce, point: worldPoint);
      fuel = (fuel - fuelConsumption * dt).clamp(0, maxFuel);
    }

    // Right Thruster Propulsion
    if (rightThrustActive) {
      final localForce = Vector2(0, -thrustPower);
      final worldForce = body.worldVector(localForce);
      final worldPoint = body.worldPoint(rightNozzle);
      body.applyForce(worldForce, point: worldPoint);
    }

    // Speed Constraints
    if (body.linearVelocity.length > GameConfig.maxLinearVelocity) {
      body.linearVelocity.normalize();
      body.linearVelocity.scale(GameConfig.maxLinearVelocity);
    }

    body.angularVelocity = body.angularVelocity.clamp(
      -GameConfig.maxAngularVelocity,
      GameConfig.maxAngularVelocity,
    );

    // Squash & Stretch Interpolation
    if (squashTimer > 0) {
      squashTimer -= dt;
      scaleX += (1.0 - scaleX) * 15.0 * dt;
      scaleY += (1.0 - scaleY) * 15.0 * dt;
    } else {
      final speed = body.linearVelocity.length;
      if (speed > 1.0) {
        scaleY = (1.0 + (speed * 0.012)).clamp(1.0, 1.12);
        scaleX = (1.0 - (speed * 0.008)).clamp(0.88, 1.0);
      } else {
        scaleX = 1.0;
        scaleY = 1.0;
      }
    }

    // Landing Gear Suspension Compression
    if (isGrounded) {
      legsCompression += (0.35 - legsCompression) * 12.0 * dt;
    } else {
      legsCompression += (0.0 - legsCompression) * 6.0 * dt;
    }

    // Overturned / Stuck Ship Detector (Angle > 80 deg while grounded & stationary)
    final double rawAngle = body.angle.abs() % (2 * pi);
    final double normAngle = rawAngle > pi ? (2 * pi - rawAngle) : rawAngle;
    final bool isOverturned = normAngle > 1.35; // ~77-90+ degrees
    final bool isStationary = body.linearVelocity.length < 0.4 && body.angularVelocity.abs() < 0.3;

    if (isGrounded && isOverturned && isStationary) {
      _stuckDuration += dt;
      if (_stuckDuration >= 1.5) {
        isStuck = true;
      }
    } else {
      _stuckDuration = 0.0;
      isStuck = false;
    }

    // Smoke Emitters for Damaged Ship
    if (maxShield > 0 && shield / maxShield < 0.4 && gameRef != null && gameRef.isLoaded == true) {
      _smokeTimer += dt;
      if (_smokeTimer >= 0.08) {
        gameRef.sparkPool?.spawnSmoke(body.position);
        _smokeTimer = 0.0;
      }
    }
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (other is Coin) {
      other.collect();
    } else if (other is FuelPickup) {
      other.collect();
    } else if (other is RepairPickup) {
      other.collect();
    } else {
      contactCount++;
    }
  }

  @override
  void endContact(Object other, Contact contact) {
    super.endContact(other, contact);
    if (other is! Coin && other is! FuelPickup && other is! RepairPickup) {
      contactCount = (contactCount - 1).clamp(0, 99);
    }
  }

  @override
  void postSolve(Object other, Contact contact, ContactImpulse impulse) {
    super.postSolve(other, contact, impulse);

    double maxNormalImpulse = 0.0;
    for (int i = 0; i < impulse.count; i++) {
      if (impulse.normalImpulses[i] > maxNormalImpulse) {
        maxNormalImpulse = impulse.normalImpulses[i];
      }
    }

    if (maxNormalImpulse > 3.0) {
      final contactPoints = contact.manifold.localPoint;
      final worldContact = body.worldPoint(contactPoints);

      // Check landing gear upright contact
      final double rawAngle = body.angle.abs() % (2 * pi);
      final double normAngle = rawAngle > pi ? (2 * pi - rawAngle) : rawAngle;
      final bool isUpright = normAngle < 0.40; // ~23 degrees
      final bool isLegsContact = contactPoints.y > 0.4;

      // Suspension absorption on gentle/moderate touchdown
      if (isUpright && isLegsContact && maxNormalImpulse <= 8.0) {
        legsCompression = 1.0;
        triggerSquash(1.08, 0.92, 0.2);
        return; // Absorbed cleanly without hull damage
      }

      // Forgiving shield deflect calculation
      final state = GameState();
      final double shieldMitigation = (0.35 + (state.shieldLevel * 0.12)).clamp(0.35, 0.80);

      // Near-miss deflect bounce impulse
      if (maxNormalImpulse < 14.0 && shield > 0) {
        // Oblique / moderate graze deflected with shield bounce
        final damage = ((maxNormalImpulse - 3.0) * 1.4) * (1.0 - shieldMitigation);
        shield = (shield - damage).clamp(0.0, maxShield);
        _shieldHitTimer = 0.6;
        triggerSquash(1.12, 0.88, 0.25);

        final dynamic gameRef = game;
        if (gameRef is LanderZeroGame) {
          gameRef.sparkPool.spawnDeflectSparks(worldContact, Vector2(0, -1.0));
          gameRef.shakeCamera(2.5, 0.15);
          GameAudioManager().playShieldDeflect();
        }
      } else {
        // High-speed catastrophic impact
        final damage = (maxNormalImpulse - 4.0) * 2.5 * (1.0 - shieldMitigation);
        shield = (shield - damage).clamp(0.0, maxShield);
        _shieldHitTimer = 0.8;
        triggerSquash(1.20, 0.78, 0.4);

        final dynamic gameRef = game;
        if (gameRef != null) {
          gameRef.onCollisionImpact(worldContact, maxNormalImpulse);
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (exploded) return;
    canvas.save();
    canvas.scale(scaleX, scaleY);
    super.render(canvas);

    // Render Impact Shield Bubble
    if (_shieldHitTimer > 0) {
      final double opacity = (_shieldHitTimer / 0.6).clamp(0.0, 1.0) * 0.5;
      final Paint shieldPaint = Paint()
        ..color = GameConfig.colorPrimary.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.12;
      final Paint shieldGlowPaint = Paint()
        ..color = GameConfig.colorPrimary.withOpacity(opacity * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.25
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.1);

      canvas.drawCircle(Offset.zero, 1.8, shieldGlowPaint);
      canvas.drawCircle(Offset.zero, 1.8, shieldPaint);
    }

    // Unified Ship & Dynamic Astronaut Rendering
    final isAnyThrust = leftThrustActive || rightThrustActive;
    ShipMeshRenderer.renderShip(
      canvas: canvas,
      shipId: rocketId,
      scale: 1.0,
      engineThrust: isAnyThrust ? 1.0 : 0.0,
      rcsThrust: leftThrustActive ? -1.0 : (rightThrustActive ? 1.0 : 0.0),
      pilotHeadOffset: headOffset,
      pilotLookDirection: lookDirection,
      pilotGStrain: gStrain,
      isPanicking: isPanicking,
      isBlinking: isBlinking,
      showLandingGear: true,
      animationTime: _totalTime,
      legsCompression: legsCompression,
      showDecals: true,
    );

    canvas.restore();
  }
}
