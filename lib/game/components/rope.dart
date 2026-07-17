import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import '../config/game_config.dart';
import '../lander_zero_game.dart';
import 'lander.dart';
import 'cargo_capsule.dart';

class Rope extends Component with HasGameReference<LanderZeroGame> {
  final Lander lander;
  final CargoCapsule capsule;

  final List<Body> _segments = [];
  final List<Joint> _joints = [];

  // Накопитель времени высокого натяжения для обрыва
  double _tensionTimer = 0.0;

  // Оптимизированные Paint объекты для снижения GC Pressure
  final Paint _ropePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.08
    ..strokeCap = StrokeCap.round;

  final Paint _connectorPaint = Paint()
    ..style = PaintingStyle.fill;

  // Переиспользуемый Path
  final Path _ropePath = Path();

  Rope({required this.lander, required this.capsule});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final world = game.world;
    final landerBody = lander.body;
    final capsuleBody = capsule.body;

    final startAnchor = landerBody.worldPoint(Vector2(0, 0.8));
    final endAnchor = capsuleBody.worldPoint(Vector2(0, -0.9));
    final double distance = startAnchor.distanceTo(endAnchor);

    final int segmentCount = GameConfig.ropeSegmentsCount;
    final double maxLength = GameConfig.ropeLength;

    // Расчет провисания троса (sag) по цепной линии на основе расстояния
    double sag = 0.0;
    if (distance < maxLength) {
      sag = 0.5 * sqrt(maxLength * maxLength - distance * distance);
    }

    // Опорная точка квадратичной кривой Безье
    final midPoint = (startAnchor + endAnchor) / 2;
    // Провисание направлено вниз по вектору гравитации (в мире Forge2D +y — вниз)
    final controlPoint = midPoint + Vector2(0, sag);

    // Генерируем точки вдоль провисшего троса
    final List<Vector2> points = [];
    for (int i = 0; i <= segmentCount; i++) {
      final double t = i / segmentCount;
      // Формула квадратичной кривой Безье: (1-t)^2 * A + 2*(1-t)*t * P + t^2 * B
      final Vector2 p = startAnchor * ((1 - t) * (1 - t)) +
                        controlPoint * (2 * (1 - t) * t) +
                        endAnchor * (t * t);
      points.add(p);
    }

    // Настройка фильтрации столкновений
    // Трос и капсула не должны сталкиваться с кораблем или друг с другом
    final filter = Filter()
      ..categoryBits = 0x0004  // Категория троса (0x0004)
      ..maskBits = 0x0001;     // Сталкиваться только со стенами пещеры (0x0001)

    Body prevBody = landerBody;

    for (int i = 0; i < segmentCount; i++) {
      final Vector2 pCurr = points[i];
      final Vector2 pNext = points[i + 1];
      
      final Vector2 segmentCenter = (pCurr + pNext) / 2;
      final Vector2 segDir = pNext - pCurr;
      final double segLength = segDir.length;
      final double angle = atan2(segDir.y, segDir.x) - pi / 2;

      final segmentDef = BodyDef(
        type: BodyType.dynamic,
        position: segmentCenter,
        angle: angle,
        linearDamping: 1.8,   // Повышенное сопротивление снижает бесконечное болтание
        angularDamping: 2.5,  // Высокая стабилизация вращения звеньев
      );

      final segmentBody = world.createBody(segmentDef);
      segmentBody.userData = this;

      // Тонкая линия-коллайдер для звена веревки
      final shape = EdgeShape()
        ..set(Vector2(0, -segLength / 2), Vector2(0, segLength / 2));

      final fixtureDef = FixtureDef(shape)
        ..density = 0.2
        ..friction = 0.2
        ..filter.categoryBits = filter.categoryBits
        ..filter.maskBits = filter.maskBits;

      segmentBody.createFixture(fixtureDef);
      _segments.add(segmentBody);

      // Соединяем с предыдущим телом точно в точке их стыка pCurr без напряжений
      final jointDef = RevoluteJointDef()
        ..initialize(
          prevBody,
          segmentBody,
          pCurr,
        )
        ..collideConnected = false;

      final joint = RevoluteJoint(jointDef);
      world.createJoint(joint);
      _joints.add(joint);

      prevBody = segmentBody;
    }

    // Соединяем последнее звено с капсулой точно в точке points[segmentCount]
    final finalJointDef = RevoluteJointDef()
      ..initialize(
        prevBody,
        capsuleBody,
        points[segmentCount],
      )
      ..collideConnected = false;

    final finalJoint = RevoluteJoint(finalJointDef);
    world.createJoint(finalJoint);
    _joints.add(finalJoint);

    capsule.isDocked = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_segments.isEmpty) return;

    final startPoint = lander.body.worldPoint(Vector2(0, 0.8));
    final endPoint = capsule.body.worldPoint(Vector2(0, -0.9));
    final double currentLength = (endPoint - startPoint).length;
    final double maxLength = GameConfig.ropeLength;

    // Если трос растягивается сверх лимита на 10%
    if (currentLength > maxLength * 1.10) {
      _tensionTimer += dt;
      if (_tensionTimer >= 0.4) {
        // Трос лопается
        game.snapRope();
      }
    } else {
      _tensionTimer = (_tensionTimer - dt).clamp(0.0, 1.0);
    }
  }

  @override
  void onRemove() {
    for (final joint in _joints) {
      game.world.destroyJoint(joint);
    }
    _joints.clear();
    for (final body in _segments) {
      game.world.destroyBody(body);
    }
    _segments.clear();
    
    capsule.isDocked = false;
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_segments.isEmpty) return;

    final startPoint = lander.body.worldPoint(Vector2(0, 0.8));
    final endPoint = capsule.body.worldPoint(Vector2(0, -0.9));

    // Расчет натяжения троса на основе текущего расстояния между крайними точками
    final double currentLength = (endPoint - startPoint).length;
    final double maxLength = GameConfig.ropeLength;
    final double tension = ((currentLength - 3.0) / (maxLength - 3.0)).clamp(0.0, 1.0);

    // Динамический цвет троса: от циана (безопасно) через желтый к сигнальному красному (натянут)
    Color ropeColor;
    if (tension < 0.5) {
      ropeColor = Color.lerp(
        const Color(0xFF00E5FF), // Циан
        const Color(0xFFFFB300), // Желтый/Оранжевый
        tension * 2.0,
      )!;
    } else {
      ropeColor = Color.lerp(
        const Color(0xFFFFB300), // Желтый/Оранжевый
        const Color(0xFFFF1744), // Сигнальный красный
        (tension - 0.5) * 2.0,
      )!;
    }

    // Если трос находится под угрозой разрыва, он мигает красным
    if (_tensionTimer > 0.0) {
      final bool flashOn = (game.flightTime * 15).toInt() % 2 == 0;
      if (flashOn) {
        ropeColor = const Color(0xFFFF1744);
      }
    }

    _ropePaint.color = ropeColor;
    _ropePaint.strokeWidth = 0.07 + (tension * 0.05); // Трос сужается/утолщается при натяжении

    // Расчет дрожания троса перед разрывом
    final double jitterAmount = (_tensionTimer / 0.4) * 0.06;
    final random = Random();

    _ropePath.reset();
    _ropePath.moveTo(startPoint.x, startPoint.y);

    for (int i = 0; i < _segments.length; i++) {
      final segment = _segments[i];
      final double segLength = maxLength / GameConfig.ropeSegmentsCount;
      final bottomPoint = segment.worldPoint(Vector2(0, segLength / 2));
      
      double jx = 0;
      double jy = 0;
      if (jitterAmount > 0) {
        jx = (random.nextDouble() - 0.5) * jitterAmount;
        jy = (random.nextDouble() - 0.5) * jitterAmount;
      }
      
      _ropePath.lineTo(bottomPoint.x + jx, bottomPoint.y + jy);
    }

    _ropePath.lineTo(endPoint.x, endPoint.y);

    canvas.drawPath(_ropePath, _ropePaint);

    // Стыковочные карабины с подсветкой под цвет натяжения
    _connectorPaint.color = ropeColor;
    canvas.drawCircle(Offset(startPoint.x, startPoint.y), 0.12, _connectorPaint);
    canvas.drawCircle(Offset(endPoint.x, endPoint.y), 0.12, _connectorPaint);
  }
}
