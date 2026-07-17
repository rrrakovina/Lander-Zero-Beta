import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class FlameParticle {
  Vector2 position;
  Vector2 velocity;
  double life;
  final double maxLife;
  final double startSize;
  final Color startColor;
  final Color endColor;

  FlameParticle({
    required this.position,
    required this.velocity,
    required this.maxLife,
    required this.startSize,
    required this.startColor,
    required this.endColor,
  }) : life = maxLife;

  bool get isDead => life <= 0;

  void update(double dt) {
    position += velocity * dt;
    // Применяем небольшое трение воздуха к частицам
    velocity *= 0.95;
    life -= dt;
  }
}

class ThrusterFlame extends PositionComponent {
  final Random _random = Random();
  final List<FlameParticle> _particles = [];
  
  // Флаг активности двигателя
  bool isActive = false;

  // Конфигурация пламени
  final double particleSpawnInterval = 0.015; // Секунды между спавном частиц
  double _spawnTimer = 0.0;

  // Оптимизированный Paint объект
  final Paint _paint = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.05); // Легкое свечение

  ThrusterFlame({required super.position});

  @override
  void update(double dt) {
    super.update(dt);

    // Обновляем существующие частицы
    for (int i = _particles.length - 1; i >= 0; i--) {
      _particles[i].update(dt);
      if (_particles[i].isDead) {
        _particles.removeAt(i);
      }
    }

    // Если двигатель активен, генерируем новые частицы
    if (isActive) {
      _spawnTimer += dt;
      while (_spawnTimer >= particleSpawnInterval) {
        _spawnParticle();
        _spawnTimer -= particleSpawnInterval;
      }
    } else {
      _spawnTimer = 0.0;
    }
  }

  void _spawnParticle() {
    // Начальная позиция частицы (немного шума по горизонтали)
    final localX = (_random.nextDouble() - 0.5) * 0.3;
    final pos = Vector2(localX, 0.0);

    // Скорость направлена вниз с небольшим разбросом (в локальных координатах компонента)
    final angle = pi / 2 + (_random.nextDouble() - 0.5) * 0.4;
    final speed = 8.0 + _random.nextDouble() * 6.0;
    final vel = Vector2(cos(angle), sin(angle)) * speed;

    // Время жизни частицы
    final maxLife = 0.15 + _random.nextDouble() * 0.2;

    // Стартовый цвет пламени (плазма): синий/голубой в начале, переходящий в оранжево-желтый и красный на конце
    final randColor = _random.nextDouble();
    Color start;
    Color end;
    if (randColor > 0.4) {
      start = const Color(0xFF00E5FF); // Неоновый циан
      end = const Color(0xFFFF8F00);   // Насыщенный оранжевый
    } else {
      start = const Color(0xFF2979FF); // Насыщенный синий
      end = const Color(0xFFFF3D00);   // Ярко-красный
    }

    _particles.add(
      FlameParticle(
        position: pos,
        velocity: vel,
        maxLife: maxLife,
        startSize: 0.15 + _random.nextDouble() * 0.2,
        startColor: start,
        endColor: end,
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    for (final particle in _particles) {
      final progress = (1.0 - (particle.life / particle.maxLife)).clamp(0.0, 1.0);
      final size = particle.startSize * (1.0 - progress * 0.7);

      // Интерполяция цвета по ходу жизни частицы
      final color = Color.lerp(
        particle.startColor,
        particle.endColor,
        progress,
      )!.withOpacity(1.0 - progress); // Затухание прозрачности

      _paint.color = color;

      canvas.drawCircle(
        Offset(particle.position.x, particle.position.y),
        size,
        _paint,
      );
    }
  }
}
