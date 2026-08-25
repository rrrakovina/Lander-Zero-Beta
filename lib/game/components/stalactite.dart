import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import '../lander_zero_game.dart';
import 'lander.dart';

class Stalactite extends BodyComponent<LanderZeroGame> with ContactCallbacks {
  final Vector2 initialPosition;
  final String biome;
  bool isTriggered = false;
  bool isDestroyed = false;

  Stalactite({required this.initialPosition, this.biome = 'echo'});

  @override
  Body createBody() {
    // 1. Создаем полигон в форме острого сталактита / сосульки (треугольник вершиной вниз)
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
    if (!isTriggered) {
      try {
        final lander = game.lander;
        final landerPos = lander.body.position;
        final myPos = body.position;
        
        final xDiff = (landerPos.x - myPos.x).abs();
        final yDiff = landerPos.y - myPos.y; // Разность по высоте (Лендер должен быть ниже)

        // Engine vibration sensitivity: acoustic vibration from active thrusters expands trigger radius
        final isThrusting = lander.leftThrustActive || lander.rightThrustActive;
        final maxTriggerX = isThrusting ? 3.0 : 1.6;
        final maxTriggerY = isThrusting ? 10.0 : 7.5;

        // Триггерим падение, если Лендер пролетает прямо под сталактитом
        if (xDiff < maxTriggerX && yDiff > 0 && yDiff < maxTriggerY) {
          isTriggered = true;
          body.setType(BodyType.dynamic);
          // Даем импульс вниз для более резкого старта
          body.applyLinearImpulse(Vector2(0.0, 4.0));
        }
      } catch (_) {}
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
    List<Color> gradientColors;
    Color borderColor;
    Color crackColor;

    if (biome == 'ice') {
      gradientColors = [const Color(0xFFE0F7FA), const Color(0xFF00E5FF)];
      borderColor = const Color(0xFF00B8D4);
      crackColor = const Color(0xFF80DEEA);
    } else if (biome == 'core') {
      gradientColors = [const Color(0xFF5D4037), const Color(0xFFFF5722)];
      borderColor = const Color(0xFFBF360C);
      crackColor = const Color(0xFFFFAB91);
    } else {
      gradientColors = [const Color(0xFF455A64), const Color(0xFF263238)];
      borderColor = const Color(0xFF121214);
      crackColor = const Color(0xFF1B262C);
    }

    final paint = Paint()
      ..shader = LinearGradient(
        colors: gradientColors,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(-0.4, -0.8, 0.4, 0.8));

    final border = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.08;

    final path = Path()
      ..moveTo(-0.4, -0.8)
      ..lineTo(0.4, -0.8)
      ..lineTo(0.0, 0.8)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, border);

    // Внутренние трещины для текстурности
    final crackPaint = Paint()
      ..color = crackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.04;
    canvas.drawLine(const Offset(0.0, -0.4), const Offset(-0.15, 0.0), crackPaint);
    canvas.drawLine(const Offset(0.0, -0.4), const Offset(0.1, 0.1), crackPaint);
  }
}
