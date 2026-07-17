import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class WindLine {
  double x = 0.0;
  double y = 0.0;
  double length = 0.0;
  double speed = 0.0;
}

class WindVisualEffect extends Component with HasGameReference {
  final List<WindLine> _lines = [];
  final Random _random = Random();
  
  final Paint _paint = Paint()
    ..color = Colors.white.withOpacity(0.12)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.04
    ..strokeCap = StrokeCap.round;

  static const int _maxLines = 25; // Слегка увеличили плотность для сочности

  WindVisualEffect() {
    for (int i = 0; i < _maxLines; i++) {
      _lines.add(WindLine()
        ..x = (_random.nextDouble() - 0.5) * 80.0
        ..y = -25.0 + _random.nextDouble() * 35.0
        ..length = 2.0 + _random.nextDouble() * 4.0
        ..speed = 8.0 + _random.nextDouble() * 12.0);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final double camX = game.camera.viewfinder.position.x;
    final double camY = game.camera.viewfinder.position.y;

    for (final line in _lines) {
      // Движемся влево (ветер дует влево)
      line.x -= line.speed * dt;

      // Если улетел далеко влево от камеры, возвращаем вправо с легким шумом
      if (line.x < camX - 40.0) {
        line.x = camX + 40.0 + _random.nextDouble() * 10.0;
        line.y = camY - 20.0 + _random.nextDouble() * 40.0;
        line.length = 2.0 + _random.nextDouble() * 4.0;
        line.speed = 8.0 + _random.nextDouble() * 12.0;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    for (final line in _lines) {
      canvas.drawLine(
        Offset(line.x, line.y),
        Offset(line.x - line.length, line.y),
        _paint,
      );
    }
  }
}
