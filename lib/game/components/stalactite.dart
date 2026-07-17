import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import '../lander_zero_game.dart';
import 'lander.dart';

class Stalactite extends BodyComponent<LanderZeroGame> with ContactCallbacks {
  final Vector2 initialPosition;
  bool isTriggered = false;
  bool isDestroyed = false;

  Stalactite({required this.initialPosition});

  @override
  Body createBody() {
    // 1. Создаем полигон в форме острого сталактита (треугольник вершиной вниз)
    final vertices = [
      Vector2(-0.4, -0.8), // Левый верхний угол
      Vector2(0.4, -0.8),  // Правый верхний угол
      Vector2(0.0, 0.8),   // Острая вершина внизу
    ];

    final shape = PolygonShape()..set(vertices);

    final fixtureDef = FixtureDef(shape)
      ..density = 4.0
      ..friction = 0.5
      ..restitution = 0.1;

    final bodyDef = BodyDef()
      ..type = BodyType.static
      ..position = initialPosition;

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isDestroyed) return;

    // Если сталактит еще не упал, проверяем дистанцию до Лендера
    if (!isTriggered && game.isLoaded) {
      final lander = game.lander;
      if (lander.isMounted) {
        final landerPos = lander.body.position;
        final myPos = body.position;
        
        final xDiff = (landerPos.x - myPos.x).abs();
        final yDiff = landerPos.y - myPos.y; // Разность по высоте (Лендер должен быть ниже)

        // Триггерим падение, если Лендер пролетает прямо под сталактитом на расстоянии до 7.5 метров
        if (xDiff < 1.6 && yDiff > 0 && yDiff < 7.5) {
          isTriggered = true;
          body.setType(BodyType.dynamic);
          // Даем импульс вниз для более резкого старта
          body.applyLinearImpulse(Vector2(0.0, 4.0));
        }
      }
    }
  }

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    if (isDestroyed) return;

    // Если сталактит падает и соударяется с Лендером или окружением, он разрушается
    if (isTriggered) {
      isDestroyed = true;

      // Спавним осколки через пул искр
      final contactPoint = body.position;
      game.sparkPool.spawnSparks(contactPoint);

      if (other is Lander) {
        // Наносим значительный урон кораблю
        other.shield = (other.shield - 35.0).clamp(0.0, other.maxShield);
        
        // Встряска экрана
        game.shakeCamera(0.6, 0.35);
      }

      // Безопасное удаление физического тела
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // Рисуем каменную текстуру сталактита в комикс-стиле
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF455A64), const Color(0xFF263238)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(-0.4, -0.8, 0.4, 0.8));

    final border = Paint()
      ..color = const Color(0xFF121214)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.08;

    final path = Path()
      ..moveTo(-0.4, -0.8)
      ..lineTo(0.4, -0.8)
      ..lineTo(0.0, 0.8)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, border);

    // Внутренние трещины для текстурности камня
    final crackPaint = Paint()
      ..color = const Color(0xFF1B262C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.04;
    canvas.drawLine(const Offset(0.0, -0.4), const Offset(-0.15, 0.0), crackPaint);
    canvas.drawLine(const Offset(0.0, -0.4), const Offset(0.1, 0.1), crackPaint);
  }
}
