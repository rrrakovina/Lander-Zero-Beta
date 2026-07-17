import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import '../lander_zero_game.dart';

class FuelPickup extends BodyComponent<LanderZeroGame> {
  @override
  final Vector2 position;
  bool _isCollected = false;

  FuelPickup({required this.position});

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.static,
      position: position,
    );

    final body = world.createBody(bodyDef);

    // Немного больше, чем монета
    final shape = CircleShape()..radius = 0.35;

    final fixtureDef = FixtureDef(
      shape,
      isSensor: true,
    );

    body.userData = this;
    body.createFixture(fixtureDef);
    return body;
  }

  void collect() {
    if (_isCollected) return;
    _isCollected = true;
    
    // Пополняем 35% бака
    game.collectFuel(0.35);
    
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Свечение сзади
    final glowPaint = Paint()
      ..color = Colors.orange.withOpacity(0.35)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.15);
    canvas.drawCircle(Offset.zero, 0.5, glowPaint);

    // Рисуем канистру (прямоугольник со срезанными углами сверху, ручкой и пробкой)
    final bodyPaint = Paint()
      ..color = Colors.amber.shade700
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.yellowAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.05;

    // Основная емкость
    final rect = Rect.fromLTRB(-0.25, -0.25, 0.25, 0.35);
    canvas.drawRect(rect, bodyPaint);
    canvas.drawRect(rect, borderPaint);

    // Крышка
    final capPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTRB(-0.15, -0.35, -0.05, -0.25), capPaint);

    // Ручка
    final handlePaint = Paint()
      ..color = Colors.yellowAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.04;
    canvas.drawPath(
      Path()
        ..moveTo(-0.15, -0.25)
        ..lineTo(-0.15, -0.3)
        ..lineTo(0.15, -0.3)
        ..lineTo(0.15, -0.25),
      handlePaint,
    );

    // Знак "F" в центре
    final textPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.04;
    
    canvas.drawPath(
      Path()
        ..moveTo(-0.08, 0.15)
        ..lineTo(-0.08, -0.1)
        ..lineTo(0.08, -0.1)
        ..moveTo(-0.08, 0.02)
        ..lineTo(0.04, 0.02),
      textPaint,
    );
  }
}
