import 'dart:math';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import '../config/game_config.dart';
import '../state/game_state.dart';
import '../audio/game_audio_manager.dart';
import '../lander_zero_game.dart';
import 'thruster_flame.dart';
import 'coin.dart';
import 'fuel_pickup.dart';
import 'repair_pickup.dart';

class Lander extends BodyComponent with ContactCallbacks {
  final Vector2 initialPosition;

  Lander({required this.initialPosition});

  // Компоненты пламени
  late final ThrusterFlame leftFlame;
  late final ThrusterFlame rightFlame;

  // Состояние управления
  bool leftThrustActive = false;
  bool rightThrustActive = false;

  // Параметры Лендера (загружаются динамически)
  late final String rocketId;
  late final double maxFuel;
  late final double maxShield;
  late final double thrustPower;
  late final double fuelConsumption;
  late final double massMultiplier;
  
  double fuel = 150.0;
  double shield = 100.0;
  double _smokeTimer = 0.0;
  bool exploded = false;
  double _totalTime = 0.0; // Для анимации бликов во время полета
  double _shieldHitTimer = 0.0; // Таймер свечения защитного купола при ударе

  // Покачивание головы пилота
  final Vector2 headOffset = Vector2.zero();
  final Vector2 headVelocity = Vector2.zero();

  // Переменные для упругой деформации (Squash & Stretch)
  double scaleX = 1.0;
  double scaleY = 1.0;
  double squashTimer = 0.0;
  
  int contactCount = 0;
  bool get isGrounded => contactCount > 0;
  double legsCompression = 0.0;

  // Оптимизированные Paint объекты для снижения GC Pressure
  final Paint _sputnikBodyPaint = Paint();
  final Paint _sputnikBorderPaint = Paint()
    ..color = const Color(0xFF121214)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.11;
  final Paint _rivetPaint = Paint()..color = Colors.white30;
  final Paint _sputnikOutlinePaint = Paint()
    ..color = const Color(0xFF121214)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.16
    ..strokeCap = StrokeCap.round;
  final Paint _sputnikCylinderPaint = Paint()
    ..color = const Color(0xFF37474F) // Colors.blueGrey.shade800
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.12
    ..strokeCap = StrokeCap.round;
  final Paint _sputnikPistonPaint = Paint()
    ..color = const Color(0xFFB0BEC5) // Colors.grey.shade400
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.06
    ..strokeCap = StrokeCap.round;
  final Paint _sputnikFeetPaint = Paint()..color = const Color(0xFF121214);

  final Paint _cycloneBodyPaint = Paint();
  final Paint _cycloneBorderPaint = Paint()
    ..color = const Color(0xFF212121)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.09;
  final Paint _cycloneStripePaint = Paint()
    ..color = Colors.black.withOpacity(0.8)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.15;
  final Paint _cycloneNozzlePaint = Paint()..color = const Color(0xFF424242); // Colors.grey.shade800
  final Paint _cycloneLegOutline = Paint()
    ..color = const Color(0xFF121214)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.22
    ..strokeCap = StrokeCap.round;
  final Paint _cycloneCylinderPaint = Paint()
    ..color = const Color(0xFF616161) // Colors.grey.shade700
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.16
    ..strokeCap = StrokeCap.round;
  final Paint _cyclonePistonPaint = Paint()
    ..color = const Color(0xFFF57F17) // Colors.yellow.shade800
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.08
    ..strokeCap = StrokeCap.round;
  final Paint _cycloneFeetPaint = Paint()..color = const Color(0xFF121214);

  final Paint _needleBodyPaint = Paint();
  final Paint _needleRedPaint = Paint();
  final Paint _needleBorderPaint = Paint()
    ..color = const Color(0xFF121214)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.09;
  final Paint _needleOutlinePaint = Paint()
    ..color = const Color(0xFF121214)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.14
    ..strokeCap = StrokeCap.round;
  final Paint _needleLegsPaint = Paint()
    ..color = Colors.black54
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.08
    ..strokeCap = StrokeCap.round;
  final Paint _needleSkiOutline = Paint()
    ..color = const Color(0xFF121214)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.14;
  final Paint _needleFeetPaint = Paint()..color = const Color(0xFFB71C1C);

  final Paint _pilotBgPaint = Paint()..color = const Color(0xFF1E282D);
  final Paint _pilotSuitPaint = Paint()..color = Colors.deepOrangeAccent;
  final Paint _pilotHelmetPaint = Paint()..color = Colors.white;
  final Paint _pilotVisorPaint = Paint()..color = const Color(0xFF102027);
  final Paint _pilotEyePaint = Paint()..color = Colors.white;
  final Paint _pilotPupilPaint = Paint()..color = Colors.black;

  final Paint _glassPaint = Paint()
    ..color = Colors.cyan.withOpacity(0.35)
    ..style = PaintingStyle.fill;
  final Paint _glassBorder = Paint()
    ..color = Colors.white30
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.05;
  final Paint _glassHighlightPaint = Paint()..color = Colors.white.withOpacity(0.35);

  // Переиспользуемые Path объекты
  final Path _sputnikPath = Path();
  final Path _cyclonePath = Path();
  final Path _needlePath = Path();
  final Path _needleNosePath = Path();

  void triggerSquash(double targetX, double targetY, double duration) {
    scaleX = targetX;
    scaleY = targetY;
    squashTimer = duration;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Загрузка характеристик на основе улучшений и выбранной ракеты
    final progress = GameState();
    rocketId = progress.selectedRocket;
    final config = GameState.rocketConfigs[rocketId]!;

    // Коэффициенты прокачки (уровень 1 = 1.0x, уровень 5 = 1.6x - 2.0x)
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
    
    // Инициализируем визуальные эффекты пламени
    leftFlame = ThrusterFlame(position: Vector2.zero());
    rightFlame = ThrusterFlame(position: Vector2.zero());
    
    game.world.add(leftFlame);
    game.world.add(rightFlame);

    // Инициализация шейдеров и путей один раз в onLoad
    _sputnikBodyPaint.shader = const LinearGradient(
      colors: [Color(0xFF607D8B), Color(0xFF37474F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTRB(-1.5, -1.2, 1.5, 0.8));

    _cycloneBodyPaint.shader = const LinearGradient(
      colors: [Color(0xFFFBC02D), Color(0xFFF57F17)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTRB(-1.6, -1.3, 1.6, 1.0));

    _needleBodyPaint.shader = const LinearGradient(
      colors: [Colors.white, Color(0xFFCFD8DC)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTRB(-0.9, -1.6, 0.9, 0.9));

    _needleRedPaint.shader = const LinearGradient(
      colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTRB(-0.9, -1.6, 0.9, 0.9));

    _sputnikPath
      ..moveTo(0.0, -1.2)
      ..lineTo(1.2, -0.4)
      ..lineTo(1.5, 0.8)
      ..lineTo(-1.5, 0.8)
      ..lineTo(-1.2, -0.4)
      ..close();

    _cyclonePath
      ..moveTo(0.0, -1.3)
      ..lineTo(1.4, -0.6)
      ..lineTo(1.6, 1.0)
      ..lineTo(-1.6, 1.0)
      ..lineTo(-1.4, -0.6)
      ..close();

    _needlePath
      ..moveTo(0.0, -1.6)
      ..lineTo(0.8, -0.2)
      ..lineTo(0.9, 0.9)
      ..lineTo(-0.9, 0.9)
      ..lineTo(-0.8, -0.2)
      ..close();

    _needleNosePath
      ..moveTo(0.0, -1.6)
      ..lineTo(0.4, -0.9)
      ..lineTo(-0.4, -0.9)
      ..close();
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
    final rId = progress.selectedRocket;
    final config = GameState.rocketConfigs[rId]!;
    final massMult = config['mass'] as double;

    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: initialPosition,
      angularDamping: GameConfig.landerAngularDamping,
      linearDamping: GameConfig.landerLinearDamping,
    );

    final body = world.createBody(bodyDef);
    body.userData = this; // Для детекции коллизий

    // Геометрия полигона зависит от типа ракеты (против часовой стрелки - CCW)
    List<Vector2> vertices;
    if (rId == 'cyclone') {
      // Крупный тяжелый квадратный модуль
      vertices = [
        Vector2(0.0, -1.3),
        Vector2(1.4, -0.6),
        Vector2(1.6, 1.0),
        Vector2(-1.6, 1.0),
        Vector2(-1.4, -0.6),
      ];
    } else if (rId == 'needle') {
      // Узкая стреловидная ракета
      vertices = [
        Vector2(0.0, -1.6),
        Vector2(0.8, -0.2),
        Vector2(0.9, 0.9),
        Vector2(-0.9, 0.9),
        Vector2(-0.8, -0.2),
      ];
    } else {
      // Спутник-1 (классический пятиугольник)
      vertices = [
        Vector2(0.0, -1.2),
        Vector2(1.2, -0.4),
        Vector2(1.5, 0.8),
        Vector2(-1.5, 0.8),
        Vector2(-1.2, -0.4),
      ];
    }

    final shape = PolygonShape()..set(vertices);

    final fixtureDef = FixtureDef(
      shape,
      density: 1.0 * massMult, // Масса пропорциональна весу кабины
      friction: 0.8,
      restitution: 0.1,
    )..filter.categoryBits = 0x0002
     ..filter.maskBits = 0xFFFF & ~0x0004 & ~0x0008; // Столкновения со всем, кроме троса (0x0004) и груза (0x0008)

    body.createFixture(fixtureDef);
    return body;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _totalTime += dt;
    if (_shieldHitTimer > 0) {
      _shieldHitTimer -= dt;
    }

    final dynamic gameRef = game;
    if (fuel <= 0 || gameRef.runStateNotifier.value != GameRunState.playing) {
      leftThrustActive = false;
      rightThrustActive = false;
    }

    final isAnyThrust = leftThrustActive || rightThrustActive;
    if (isAnyThrust) {
      GameAudioManager().startThrustLoop();
    } else {
      GameAudioManager().stopThrustLoop();
    }

    // Позиционируем пламя
    if (leftFlame.isMounted) {
      leftFlame.position = body.worldPoint(rocketId == 'cyclone' ? Vector2(-1.3, 1.0) : (rocketId == 'needle' ? Vector2(-0.7, 0.9) : Vector2(-1.2, 0.8)));
      leftFlame.angle = body.angle;
      leftFlame.isActive = leftThrustActive;
    }

    if (rightFlame.isMounted) {
      rightFlame.position = body.worldPoint(rocketId == 'cyclone' ? Vector2(1.3, 1.0) : (rocketId == 'needle' ? Vector2(0.7, 0.9) : Vector2(1.2, 0.8)));
      rightFlame.angle = body.angle;
      rightFlame.isActive = rightThrustActive;
    }

    // Физика покачивания головы пилота ( spring-mass-damper)
    // Инерция основывается на угловой скорости и движении Лендера
    final velocity = body.linearVelocity;
    final angularVel = body.angularVelocity;
    
    final targetOffset = Vector2(-velocity.x * 0.02, (-velocity.y - 3.5).clamp(-10.0, 10.0) * 0.015 - angularVel * 0.01);

    final springForce = (targetOffset - headOffset) * 12.0;
    headVelocity.x += (springForce.x - headVelocity.x * 4.0) * dt;
    headVelocity.y += (springForce.y - headVelocity.y * 4.0) * dt;
    
    headOffset.x += headVelocity.x * dt;
    headOffset.y += headVelocity.y * dt;

    // Клампа в разумных пределах
    if (headOffset.length2 > 0.04) {
      headOffset.setFrom(headOffset.normalized() * 0.2);
    }

    // Тяга левого двигателя
    if (leftThrustActive) {
      final localForce = Vector2(0, -thrustPower);
      final worldForce = body.worldVector(localForce);
      final worldPoint = body.worldPoint(rocketId == 'cyclone' ? Vector2(-1.3, 1.0) : (rocketId == 'needle' ? Vector2(-0.7, 0.9) : Vector2(-1.2, 0.8)));
      body.applyForce(worldForce, point: worldPoint);
      fuel = (fuel - fuelConsumption * dt).clamp(0, maxFuel);
    }

    // Тяга правого двигателя
    if (rightThrustActive) {
      final localForce = Vector2(0, -thrustPower);
      final worldForce = body.worldVector(localForce);
      final worldPoint = body.worldPoint(rocketId == 'cyclone' ? Vector2(1.3, 1.0) : (rocketId == 'needle' ? Vector2(0.7, 0.9) : Vector2(1.2, 0.8)));
      body.applyForce(worldForce, point: worldPoint);
    }

    // Ограничение линейной скорости (Terminal Velocity)
    if (body.linearVelocity.length > GameConfig.maxLinearVelocity) {
      body.linearVelocity.normalize();
      body.linearVelocity.scale(GameConfig.maxLinearVelocity);
    }

    // Ограничение угловой скорости
    body.angularVelocity = body.angularVelocity.clamp(-GameConfig.maxAngularVelocity, GameConfig.maxAngularVelocity);

    // Интерполяция Squash & Stretch (упругое сжатие/растяжение)
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

    // Расчет усадки пружинной подвески лап
    if (isGrounded) {
      legsCompression += (0.35 - legsCompression) * 12.0 * dt;
    } else {
      legsCompression += (0.0 - legsCompression) * 6.0 * dt;
    }

    // Дым при критических повреждениях (здоровье ниже 40%)
    if (shield / maxShield < 0.4 && gameRef.isLoaded) {
      _smokeTimer += dt;
      if (_smokeTimer >= 0.08) {
        gameRef.sparkPool.spawnSmoke(body.position);
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

    // Если удар жесткий
    if (maxNormalImpulse > 5.0) {
      final damage = (maxNormalImpulse - 5.0) * 2.5;
      shield = (shield - damage).clamp(0.0, maxShield);
      _shieldHitTimer = 0.6; // Активируем визуальный щит на 0.6 сек

      // Упругое сжатие при ударе
      triggerSquash(1.15, 0.82, 0.35);

      // Спавн искр и тряска экрана в LanderZeroGame
      final contactPoints = contact.manifold.localPoint;
      final worldContact = body.worldPoint(contactPoints);
      
      final dynamic gameRef = game;
      gameRef.onCollisionImpact(worldContact, maxNormalImpulse);
    }
  }

  @override
  void render(Canvas canvas) {
    if (exploded) return;
    canvas.save();
    canvas.scale(scaleX, scaleY);
    super.render(canvas);

    // Рисовка силового щита при ударе
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

    // Рисовка кабины в стиле Hill Climb Racing (тени, градиентная кабина, пилот)
    if (rocketId == 'cyclone') {
      _renderCyclone(canvas);
    } else if (rocketId == 'needle') {
      _renderNeedle(canvas);
    } else {
      _renderSputnik(canvas);
    }
    canvas.restore();
  }

  // 1. «Спутник-1» (Базовый)
  void _renderSputnik(Canvas canvas) {
    canvas.drawPath(_sputnikPath, _sputnikBodyPaint);
    canvas.drawPath(_sputnikPath, _sputnikBorderPaint);

    // Заклепки по краям
    canvas.drawCircle(const Offset(-0.8, -0.3), 0.06, _rivetPaint);
    canvas.drawCircle(const Offset(0.8, -0.3), 0.06, _rivetPaint);
    canvas.drawCircle(const Offset(-1.1, 0.5), 0.06, _rivetPaint);
    canvas.drawCircle(const Offset(1.1, 0.5), 0.06, _rivetPaint);

    // Кабина пилота
    _renderPilot(canvas, const Offset(0.0, -0.15), 0.5);

    // Две опорные стойки (анимированная пружинная подвеска)
    final double leftFootX = -1.4 + legsCompression * 0.4;
    final double leftFootY = 1.2 - legsCompression * 0.6;
    final double rightFootX = 1.4 - legsCompression * 0.4;
    final double rightFootY = 1.2 - legsCompression * 0.6;

    // Левая лапа
    canvas.drawLine(const Offset(-1.1, 0.8), Offset(leftFootX, leftFootY), _sputnikOutlinePaint);
    final Offset leftMid = Offset(-1.1 + (leftFootX + 1.1) * 0.5, 0.8 + (leftFootY - 0.8) * 0.5);
    canvas.drawLine(const Offset(-1.1, 0.8), leftMid, _sputnikCylinderPaint);
    canvas.drawLine(leftMid, Offset(leftFootX, leftFootY), _sputnikPistonPaint);

    // Правая лапа
    canvas.drawLine(const Offset(1.1, 0.8), Offset(rightFootX, rightFootY), _sputnikOutlinePaint);
    final Offset rightMid = Offset(1.1 + (rightFootX - 1.1) * 0.5, 0.8 + (rightFootY - 0.8) * 0.5);
    canvas.drawLine(const Offset(1.1, 0.8), rightMid, _sputnikCylinderPaint);
    canvas.drawLine(rightMid, Offset(rightFootX, rightFootY), _sputnikPistonPaint);

    // Опоры (тапки)
    canvas.drawRect(Rect.fromCenter(center: Offset(leftFootX, leftFootY), width: 0.4, height: 0.12), _sputnikFeetPaint);
    canvas.drawRect(Rect.fromCenter(center: Offset(rightFootX, rightFootY), width: 0.4, height: 0.12), _sputnikFeetPaint);
  }

  // 2. «Ураган» (Тяжелый)
  void _renderCyclone(Canvas canvas) {
    canvas.drawPath(_cyclonePath, _cycloneBodyPaint);
    canvas.drawPath(_cyclonePath, _cycloneBorderPaint);

    // Полоски предупреждения (черные полосы)
    canvas.drawLine(const Offset(-1.1, 0.8), const Offset(-0.7, 0.4), _cycloneStripePaint);
    canvas.drawLine(const Offset(1.1, 0.8), const Offset(0.7, 0.4), _cycloneStripePaint);

    // Кабина
    _renderPilot(canvas, const Offset(0.0, 0.0), 0.65);

    // Мощные сопла двигателей (внешние металлические трубы)
    canvas.drawRect(Rect.fromCenter(center: const Offset(-1.3, 1.15), width: 0.5, height: 0.3), _cycloneNozzlePaint);
    canvas.drawRect(Rect.fromCenter(center: const Offset(1.3, 1.15), width: 0.5, height: 0.3), _cycloneNozzlePaint);

    // Опоры лап с амортизацией (тяжелые пружинные ноги)
    final double leftFootX = -1.8 + legsCompression * 0.5;
    final double leftFootY = 1.4 - legsCompression * 0.7;
    final double rightFootX = 1.8 - legsCompression * 0.5;
    final double rightFootY = 1.4 - legsCompression * 0.7;

    // Левая лапа
    canvas.drawLine(const Offset(-1.4, 1.0), Offset(leftFootX, leftFootY), _cycloneLegOutline);
    final Offset leftMid = Offset(-1.4 + (leftFootX + 1.4) * 0.5, 1.0 + (leftFootY - 1.0) * 0.5);
    canvas.drawLine(const Offset(-1.4, 1.0), leftMid, _cycloneCylinderPaint);
    canvas.drawLine(leftMid, Offset(leftFootX, leftFootY), _cyclonePistonPaint);

    // Правая лапа
    canvas.drawLine(const Offset(1.4, 1.0), Offset(rightFootX, rightFootY), _cycloneLegOutline);
    final Offset rightMid = Offset(1.4 + (rightFootX - 1.4) * 0.5, 1.0 + (rightFootY - 1.0) * 0.5);
    canvas.drawLine(const Offset(1.4, 1.0), rightMid, _cycloneCylinderPaint);
    canvas.drawLine(rightMid, Offset(rightFootX, rightFootY), _cyclonePistonPaint);

    // Тяжелые тапки
    canvas.drawRect(Rect.fromCenter(center: Offset(leftFootX, leftFootY), width: 0.65, height: 0.18), _cycloneFeetPaint);
    canvas.drawRect(Rect.fromCenter(center: Offset(rightFootX, rightFootY), width: 0.65, height: 0.18), _cycloneFeetPaint);
  }

  // 3. «Игла» (Сверхлегкий)
  void _renderNeedle(Canvas canvas) {
    canvas.drawPath(_needlePath, _needleBodyPaint);

    // Красный нос и стабилизаторы
    canvas.drawPath(_needleNosePath, _needleRedPaint);
    canvas.drawPath(_needleNosePath, _needleBorderPaint);

    canvas.drawPath(_needlePath, _needleBorderPaint);

    // Кабина
    _renderPilot(canvas, const Offset(0.0, -0.25), 0.4);

    // Опоры (легкие лыжи) с амортизацией подвески
    final double leftFootX = -1.1 + legsCompression * 0.3;
    final double leftFootY = 1.2 - legsCompression * 0.5;
    final double rightFootX = 1.1 - legsCompression * 0.3;
    final double rightFootY = 1.2 - legsCompression * 0.5;

    // Левая опора
    canvas.drawLine(const Offset(-0.8, 0.9), Offset(leftFootX, leftFootY), _needleOutlinePaint);
    canvas.drawLine(const Offset(-0.8, 0.9), Offset(leftFootX, leftFootY), _needleLegsPaint);

    // Правая опора
    canvas.drawLine(const Offset(0.8, 0.9), Offset(rightFootX, rightFootY), _needleOutlinePaint);
    canvas.drawLine(const Offset(0.8, 0.9), Offset(rightFootX, rightFootY), _needleLegsPaint);

    // Лыжи с обводкой
    canvas.drawOval(Rect.fromCenter(center: Offset(leftFootX, leftFootY), width: 0.5, height: 0.08), _needleSkiOutline);
    canvas.drawOval(Rect.fromCenter(center: Offset(leftFootX, leftFootY), width: 0.5, height: 0.08), _needleFeetPaint);

    canvas.drawOval(Rect.fromCenter(center: Offset(rightFootX, rightFootY), width: 0.5, height: 0.08), _needleSkiOutline);
    canvas.drawOval(Rect.fromCenter(center: Offset(rightFootX, rightFootY), width: 0.5, height: 0.08), _needleFeetPaint);
  }

  // Отрисовка прозрачного купола и пилота в скафандре
  void _renderPilot(Canvas canvas, Offset cabinCenter, double radius) {
    // 1. Отрисовка заднего фона кабины (темный)
    canvas.drawCircle(cabinCenter, radius, _pilotBgPaint);

    // 2. Рисуем пилота (голова с покачиванием)
    final headPos = cabinCenter + Offset(headOffset.x, headOffset.y + 0.05);

    // Плечи пилота (скафандр)
    canvas.drawOval(Rect.fromCenter(center: Offset(cabinCenter.dx, cabinCenter.dy + radius * 0.6), width: radius * 1.3, height: radius * 0.7), _pilotSuitPaint);

    // Шлем пилота
    canvas.drawCircle(headPos, radius * 0.42, _pilotHelmetPaint);

    // Стекло шлема (темное)
    canvas.drawCircle(headPos + const Offset(0.0, -0.02), radius * 0.28, _pilotVisorPaint);

    // Глазки пилота (испуганные при больших скоростях/столкновениях/критическом уровне ресурсов)
    final double speedVal = body.linearVelocity.length;
    final bool isLowShield = shield / maxShield < 0.35;
    final bool isLowFuel = fuel / maxFuel < 0.20;
    final bool isPanicking = speedVal > 5.0 || isLowShield || isLowFuel;

    // В состоянии паники глаза сильно увеличиваются, а зрачки становятся крошечными точками (эффект HCR)
    final double eyeRadius = isPanicking ? (radius * 0.14) : (radius * 0.08);
    final double pupilRadius = isPanicking ? (eyeRadius * 0.25) : (eyeRadius * 0.55);

    // Эффект дрожания зрачков при критических ситуациях
    double shakeX = 0.0;
    double shakeY = 0.0;
    if (isLowShield || isLowFuel) {
      final random = Random();
      shakeX = (random.nextDouble() - 0.5) * 0.02;
      shakeY = (random.nextDouble() - 0.5) * 0.02;
    }

    // Левый глаз
    final Offset leftEyePos = headPos + Offset(-radius * 0.12, -radius * 0.02);
    canvas.drawCircle(leftEyePos, eyeRadius, _pilotEyePaint);
    canvas.drawCircle(leftEyePos + Offset(shakeX, shakeY), pupilRadius, _pilotPupilPaint);

    // Правый глаз
    final Offset rightEyePos = headPos + Offset(radius * 0.12, -radius * 0.02);
    canvas.drawCircle(rightEyePos, eyeRadius, _pilotEyePaint);
    canvas.drawCircle(rightEyePos + Offset(shakeX, shakeY), pupilRadius, _pilotPupilPaint);

    // 3. Рисуем стеклянный купол кабины (полупрозрачный блик)
    canvas.drawCircle(cabinCenter, radius, _glassPaint);

    // Тонкий ободок
    canvas.drawCircle(cabinCenter, radius, _glassBorder);

    // Блик на стекле (белый овал в верхнем левом углу)
    canvas.drawOval(
      Rect.fromLTWH(
        cabinCenter.dx - radius * 0.6,
        cabinCenter.dy - radius * 0.7,
        radius * 0.6,
        radius * 0.35,
      ),
      _glassHighlightPaint,
    );

    // Бегущий блик по стеклу во время полета
    final double sweepProgress = (sin(_totalTime * 1.5) + 1.0) / 2.0;
    final double sweepX = cabinCenter.dx - radius + (radius * 2.0 * sweepProgress);
    canvas.save();
    final Path clipPath = Path()..addOval(Rect.fromCircle(center: cabinCenter, radius: radius));
    canvas.clipPath(clipPath);
    final Paint sweepPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    final Path sweepPath = Path()
      ..moveTo(sweepX - radius * 0.2, cabinCenter.dy - radius)
      ..lineTo(sweepX + radius * 0.1, cabinCenter.dy - radius)
      ..lineTo(sweepX - radius * 0.1, cabinCenter.dy + radius)
      ..lineTo(sweepX - radius * 0.4, cabinCenter.dy + radius)
      ..close();
    canvas.drawPath(sweepPath, sweepPaint);
    canvas.restore();
  }
}
