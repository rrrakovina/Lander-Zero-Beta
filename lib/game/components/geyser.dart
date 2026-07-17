import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../lander_zero_game.dart';

class Geyser extends PositionComponent with HasGameReference<LanderZeroGame> {
  final double activeTime = 2.5; // Время извержения
  final double inactiveTime = 3.0; // Время покоя
  final double forceMagnitude = 32.0; // Сила струи
  final double rangeHeight = 10.0; // Высота поражения
  final double rangeWidth = 2.2; // Ширина струи

  double _timer = 0.0;
  bool isActive = false;

  // Детерминированный сдвиг дрожания
  double _wobbleOffset = 0.0;

  // Оптимизированные Paint объекты для кэширования
  late final Paint _nozzlePaint;
  late final Paint _borderPaint;
  late final Paint _flamePaint;
  late final Paint _corePaint;

  // Оптимизированные Path объекты
  late final Path _nozzlePath;
  final Path _flamePath = Path();

  Geyser({required Vector2 position}) {
    this.position = position;
    width = rangeWidth;
    height = rangeHeight;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _nozzlePaint = Paint()
      ..color = const Color(0xFF263238)
      ..style = PaintingStyle.fill;

    _borderPaint = Paint()
      ..color = const Color(0xFF121214)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.08;

    _flamePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.orangeAccent.withOpacity(0.95),
          Colors.amber.withOpacity(0.7),
          Colors.redAccent.withOpacity(0.0),
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(Rect.fromLTRB(-rangeWidth / 2, -rangeHeight, rangeWidth / 2, 0.0));

    _corePaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.15);

    _nozzlePath = Path()
      ..moveTo(-0.8, 0.0)
      ..lineTo(-0.5, -0.6)
      ..lineTo(0.5, -0.6)
      ..lineTo(0.8, 0.0)
      ..close();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    // Переключение состояния активен/неактивен
    if (isActive) {
      if (_timer >= activeTime) {
        isActive = false;
        _timer = 0.0;
        _wobbleOffset = 0.0;
      } else {
        // Детерминированный сдвиг на основе времени без рандома в кадре
        _wobbleOffset = sin(_timer * 35.0) * 0.15 + cos(_timer * 18.0) * 0.08;
      }
    } else {
      if (_timer >= inactiveTime) {
        isActive = true;
        _timer = 0.0;
      }
    }

    // Если гейзер активен, прикладываем выталкивающую силу к Лендеру
    if (isActive && game.isLoaded) {
      final lander = game.lander;
      if (lander.isMounted && !lander.isGrounded) {
        final landerPos = lander.body.position;
        // Проверяем, находится ли Лендер в створе гейзера (над соплом)
        if (landerPos.x >= position.x - rangeWidth / 2 &&
            landerPos.x <= position.x + rangeWidth / 2 &&
            landerPos.y >= position.y - rangeHeight &&
            landerPos.y <= position.y) {
          
          // Выталкивающая сила направлена строго вверх
          // Сила ослабевает с расстоянием от сопла гейзера
          final distanceFactor = (1.0 - ((position.y - landerPos.y) / rangeHeight)).clamp(0.1, 1.0);
          final force = Vector2(0.0, -forceMagnitude * distanceFactor * lander.body.mass);
          lander.body.applyForce(force);

          // Наносим периодический тепловой урон щиту Лендера
          lander.shield = (lander.shield - 8.0 * dt).clamp(0.0, lander.maxShield);
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. Рисуем металлическое сопло гейзера у основания
    canvas.drawPath(_nozzlePath, _nozzlePaint);
    canvas.drawPath(_nozzlePath, _borderPaint);

    // 2. Если гейзер извергается, рисуем пламя/пар с анимацией мерцания
    if (isActive) {
      _flamePath.reset();
      _flamePath.moveTo(-0.4, -0.6);

      // Рисуем рваные края пламени
      final segments = 6;
      final step = rangeHeight / segments;
      for (int i = 1; i <= segments; i++) {
        final double currY = -0.6 - (i * step);
        final double widthFactor = 1.0 - (i / segments) * 0.7; // сужение кверху
        final double currX = (rangeWidth / 2 * widthFactor) + _wobbleOffset;
        _flamePath.lineTo(currX, currY);
      }

      for (int i = segments; i >= 1; i--) {
        final double currY = -0.6 - (i * step);
        final double widthFactor = 1.0 - (i / segments) * 0.7;
        final double currX = -(rangeWidth / 2 * widthFactor) + _wobbleOffset;
        _flamePath.lineTo(currX, currY);
      }

      _flamePath.close();
      canvas.drawPath(_flamePath, _flamePaint);

      // Добавляем внутреннее белое ядро пламени для сочности
      canvas.drawOval(
        Rect.fromLTRB(-0.25, -0.6 - rangeHeight * 0.3, 0.25, -0.6),
        _corePaint,
      );
    }
  }
}
