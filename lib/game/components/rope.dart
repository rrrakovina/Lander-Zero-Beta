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

  late final RopeJoint _joint;

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
    // Используем встроенный в Box2D RopeJoint для абсолютно стабильного физического ограничения максимальной длины.
    // Он не создает промежуточных тел, не дает раскачки и идеально решает уравнения масс.
    final jointDef = RopeJointDef()
      ..bodyA = landerBody
      ..bodyB = capsuleBody
      ..localAnchorA.setFrom(Vector2(0, 0.8))
      ..localAnchorB.setFrom(Vector2(0, -0.9))
      ..maxLength = GameConfig.ropeLength
      ..collideConnected = false;

    _joint = RopeJoint(jointDef);
    world.createJoint(_joint);

    capsule.isDocked = true;
  }

  @override
  void update(double dt) {
    super.update(dt);

    final startPoint = lander.body.worldPoint(Vector2(0, 0.8));
    final endPoint = capsule.body.worldPoint(Vector2(0, -0.9));
    final double currentLength = (endPoint - startPoint).length;
    final double maxLength = GameConfig.ropeLength;

    // Проверяем растяжение троса для его обрыва
    // Так как суставы Box2D могут растягиваться под большой нагрузкой, ставим порог 1.25 (5.0м)
    if (currentLength > maxLength * 1.25) {
      _tensionTimer += dt;
      if (_tensionTimer >= 1.2) {
        // Трос лопается
        game.snapRope();
      }
    } else {
      _tensionTimer = (_tensionTimer - dt).clamp(0.0, 1.5);
    }
  }

  @override
  void onRemove() {
    game.world.destroyJoint(_joint);
    capsule.isDocked = false;
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final startPoint = lander.body.worldPoint(Vector2(0, 0.8));
    final endPoint = capsule.body.worldPoint(Vector2(0, -0.9));

    final double currentLength = (endPoint - startPoint).length;
    final double maxLength = GameConfig.ropeLength;
    
    // Расчет натяжения для визуального цвета
    final double tension = ((currentLength - 3.0) / (maxLength - 3.0)).clamp(0.0, 1.0);

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

    if (_tensionTimer > 0.0) {
      final bool flashOn = (game.flightTime * 15).toInt() % 2 == 0;
      if (flashOn) {
        ropeColor = const Color(0xFFFF1744);
      }
    }

    _ropePaint.color = ropeColor;
    _ropePaint.strokeWidth = 0.07 + (tension * 0.05);

    // Рассчитываем визуальное провисание (sag)
    double sag = 0.0;
    if (currentLength < maxLength) {
      sag = 0.5 * sqrt(maxLength * maxLength - currentLength * currentLength);
    }

    // Дрожание при критическом натяжении
    final double jitterAmount = (_tensionTimer / 1.2) * 0.08;
    final random = Random();
    
    double jx = 0;
    double jy = 0;
    if (jitterAmount > 0) {
      jx = (random.nextDouble() - 0.5) * jitterAmount;
      jy = (random.nextDouble() - 0.5) * jitterAmount;
    }

    final midPoint = (startPoint + endPoint) / 2;
    final controlPoint = midPoint + Vector2(jx, sag + jy);

    // Рендерим красивую гладкую кривую Безье
    _ropePath.reset();
    _ropePath.moveTo(startPoint.x, startPoint.y);
    _ropePath.quadraticBezierTo(
      controlPoint.x,
      controlPoint.y,
      endPoint.x,
      endPoint.y,
    );

    canvas.drawPath(_ropePath, _ropePaint);

    // Отрисовываем стыковочные карабины
    _connectorPaint.color = ropeColor;
    canvas.drawCircle(Offset(startPoint.x, startPoint.y), 0.12, _connectorPaint);
    canvas.drawCircle(Offset(endPoint.x, endPoint.y), 0.12, _connectorPaint);
  }
}
