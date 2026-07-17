import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import '../lander_zero_game.dart';

class RepairPickup extends BodyComponent<LanderZeroGame> {
  @override
  final Vector2 position;
  bool _isCollected = false;

  RepairPickup({required this.position});

  // Оптимизированные Paint объекты — кэш для render()
  final Paint _glowPaint = Paint()
    ..color = Colors.cyanAccent.withOpacity(0.35)
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.15);

  final Paint _bodyPaint = Paint()
    ..color = Colors.cyan.shade700
    ..style = PaintingStyle.fill;

  final Paint _borderPaint = Paint()
    ..color = Colors.cyanAccent
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.05;

  final Paint _crossPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.05;

  // Переиспользуемый Path
  late final Path _shieldPath;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _shieldPath = Path()
      ..moveTo(0.0, -0.35)
      ..lineTo(0.25, -0.15)
      ..lineTo(0.2, 0.25)
      ..lineTo(0.0, 0.4)
      ..lineTo(-0.2, 0.25)
      ..lineTo(-0.25, -0.15)
      ..close();
  }

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.static,
      position: position,
    );

    final body = world.createBody(bodyDef);

    final shape = CircleShape()..radius = 0.6;

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
    
    // Пополняем 25% щита
    game.collectShield(0.25);
    
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Свечение сзади
    canvas.drawCircle(Offset.zero, 0.5, _glowPaint);

    // Путь для щита (выпуклый пятиугольник)
    canvas.drawPath(_shieldPath, _bodyPaint);
    canvas.drawPath(_shieldPath, _borderPaint);

    // Белый крест в центре
    canvas.drawLine(const Offset(-0.1, 0.0), const Offset(0.1, 0.0), _crossPaint);
    canvas.drawLine(const Offset(0.0, -0.1), const Offset(0.0, 0.1), _crossPaint);
  }
}
