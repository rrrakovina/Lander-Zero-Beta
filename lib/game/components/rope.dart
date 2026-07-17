import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import '../config/game_config.dart';
import 'lander.dart';
import 'cargo_capsule.dart';

class Rope extends Component with HasGameReference<Forge2DGame> {
  final Lander lander;
  final CargoCapsule capsule;

  final List<Body> _segments = [];
  final List<Joint> _joints = [];

  // Оптимизированные Paint объекты для снижения GC Pressure
  final Paint _ropePaint = Paint()
    ..color = const Color(0xFFB0BEC5) // Стальной серый
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.08
    ..strokeCap = StrokeCap.round;

  final Paint _connectorPaint = Paint()
    ..color = Colors.orangeAccent
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

    final int segmentCount = GameConfig.ropeSegmentsCount;
    final double segLength = GameConfig.ropeLength / segmentCount;
    final Vector2 direction = (endAnchor - startAnchor).normalized();

    // Настройка фильтрации столкновений
    // Трос и капсула не должны сталкиваться с кораблем
    final filter = Filter()
      ..categoryBits = 0x0002  // Категория троса
      ..maskBits = 0x0001;     // Сталкиваться только со стенами пещеры

    Body prevBody = landerBody;
    Vector2 prevAnchor = Vector2(0, 0.8); // Локальный анкер на предыдущем теле

    for (int i = 0; i < segmentCount; i++) {
      final Vector2 initialPos = startAnchor + direction * (segLength * (i + 0.5));

      final segmentDef = BodyDef(
        type: BodyType.dynamic,
        position: initialPos,
        linearDamping: 2.5,
        angularDamping: 3.0,
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

      // Соединяем с предыдущим телом
      final jointDef = RevoluteJointDef()
        ..initialize(
          prevBody,
          segmentBody,
          i == 0 ? startAnchor : prevBody.worldPoint(prevAnchor),
        )
        ..collideConnected = false;

      final joint = RevoluteJoint(jointDef);
      world.createJoint(joint);
      _joints.add(joint);

      prevBody = segmentBody;
      prevAnchor = Vector2(0, segLength / 2);
    }

    // Соединяем последнее звено с капсулой
    final finalJointDef = RevoluteJointDef()
      ..initialize(
        prevBody,
        capsuleBody,
        prevBody.worldPoint(prevAnchor),
      )
      ..collideConnected = false;

    final finalJoint = RevoluteJoint(finalJointDef);
    world.createJoint(finalJoint);
    _joints.add(finalJoint);

    capsule.isDocked = true;
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

    _ropePath.reset();
    final startPoint = lander.body.worldPoint(Vector2(0, 0.8));
    _ropePath.moveTo(startPoint.x, startPoint.y);

    for (final segment in _segments) {
      final pos = segment.position;
      _ropePath.lineTo(pos.x, pos.y);
    }

    final endPoint = capsule.body.worldPoint(Vector2(0, -0.9));
    _ropePath.lineTo(endPoint.x, endPoint.y);

    canvas.drawPath(_ropePath, _ropePaint);

    // Стыковочные карабины
    canvas.drawCircle(Offset(startPoint.x, startPoint.y), 0.12, _connectorPaint);
    canvas.drawCircle(Offset(endPoint.x, endPoint.y), 0.12, _connectorPaint);
  }
}
