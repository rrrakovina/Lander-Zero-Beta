import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import '../lander_zero_game.dart';

class FuelPickup extends BodyComponent<LanderZeroGame> {
  @override
  final Vector2 position;
  bool _isCollected = false;

  FuelPickup({required this.position});

  // Оптимизированные Paint объекты — кэш для render()
  final Paint _glowPaint = Paint()
    ..color = Colors.orange.withOpacity(0.35)
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.15);

  final Paint _bodyPaint = Paint()
    ..color = Colors.amber.shade700
    ..style = PaintingStyle.fill;

  final Paint _borderPaint = Paint()
    ..color = Colors.yellowAccent
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.05;

  final Paint _capPaint = Paint()
    ..color = Colors.black87
    ..style = PaintingStyle.fill;

  final Paint _handlePaint = Paint()
    ..color = Colors.yellowAccent
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.04;

  final Paint _textPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.04;

  // Переиспользуемые Path
  late final Path _handlePath;
  late final Path _fLetterPath;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _handlePath = Path()
      ..moveTo(-0.15, -0.25)
      ..lineTo(-0.15, -0.3)
      ..lineTo(0.15, -0.3)
      ..lineTo(0.15, -0.25);

    _fLetterPath = Path()
      ..moveTo(-0.08, 0.15)
      ..lineTo(-0.08, -0.1)
      ..lineTo(0.08, -0.1)
      ..moveTo(-0.08, 0.02)
      ..lineTo(0.04, 0.02);
  }

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
    canvas.drawCircle(Offset.zero, 0.5, _glowPaint);

    // Основная емкость
    final rect = Rect.fromLTRB(-0.25, -0.25, 0.25, 0.35);
    canvas.drawRect(rect, _bodyPaint);
    canvas.drawRect(rect, _borderPaint);

    // Крышка
    canvas.drawRect(Rect.fromLTRB(-0.15, -0.35, -0.05, -0.25), _capPaint);

    // Ручка
    canvas.drawPath(_handlePath, _handlePaint);

    // Знак "F" в центре
    canvas.drawPath(_fLetterPath, _textPaint);
  }
}
