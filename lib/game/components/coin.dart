import 'dart:math';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import '../lander_zero_game.dart';

class Coin extends BodyComponent<LanderZeroGame> {
  @override
  final Vector2 position;
  double _time = 0.0;
  bool _isCollected = false;

  // Оптимизированные Paint объекты для снижения GC Pressure
  final Paint _glowPaint = Paint()
    ..color = Colors.amber.withOpacity(0.35)
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.12);

  final Paint _coinPaint = Paint()
    ..color = Colors.amber
    ..style = PaintingStyle.fill;

  final Paint _borderPaint = Paint()
    ..color = Colors.orangeAccent
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.04;

  final Paint _starPaint = Paint()
    ..color = const Color(0xFFD84315) // Темно-оранжевый оттенок
    ..style = PaintingStyle.fill;

  // Переиспользуемый Path
  final Path _starPath = Path();

  Coin({required this.position}) {
    _time = Random().nextDouble() * 10; // Случайная фаза вращения
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Строим звезду один раз
    const double innerRadius = 0.05;
    const double outerRadius = 0.12;
    const int points = 5;
    const double step = pi / points;

    for (int i = 0; i < 2 * points; i++) {
      final r = (i % 2 == 0) ? outerRadius : innerRadius;
      final angle = i * step - pi / 2;
      final x = r * cos(angle);
      final y = r * sin(angle);
      if (i == 0) {
        _starPath.moveTo(x, y);
      } else {
        _starPath.lineTo(x, y);
      }
    }
    _starPath.close();
  }

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.static,
      position: position,
    );

    final body = world.createBody(bodyDef);

    final shape = CircleShape()..radius = 0.25;

    final fixtureDef = FixtureDef(
      shape,
      isSensor: true, // Пролетаем насквозь
    );

    body.userData = this;
    body.createFixture(fixtureDef);
    return body;
  }

  void collect() {
    if (_isCollected) return;
    _isCollected = true;
    
    // Добавляем монеты в игровую сессию
    game.collectCoin();
    
    // Удаляем из мира
    removeFromParent();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Фоновое неоновое свечение (всегда круглое)
    canvas.drawCircle(Offset.zero, 0.38, _glowPaint);

    // 3D эффект вращения (изменение ширины эллипса по синусоиде)
    final widthScale = sin(_time * 4.0).abs();
    
    canvas.save();
    canvas.scale(widthScale, 1.0);

    // Отрисовка золотой монеты
    canvas.drawCircle(Offset.zero, 0.25, _coinPaint);
    canvas.drawCircle(Offset.zero, 0.25, _borderPaint);

    // Рисуем нейтральную звездочку в центре монеты
    canvas.drawPath(_starPath, _starPaint);

    canvas.restore();
  }
}
