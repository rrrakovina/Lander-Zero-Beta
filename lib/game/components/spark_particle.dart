import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Spark {
  final Vector2 position = Vector2.zero();
  final Vector2 velocity = Vector2.zero();
  double life = 0.0;
  double maxLife = 0.0;
  Color color = Colors.orangeAccent;
  bool isSmoke = false;
}

class SparkPoolManager extends Component {
  static const int _maxSparks = 200;
  late final List<Spark> _pool;
  final Random _random = Random();

  // Оптимизированный Paint объект
  final Paint _paint = Paint()..style = PaintingStyle.fill;

  SparkPoolManager() {
    _pool = List.generate(_maxSparks, (_) => Spark());
  }

  // Спавн веера искр из точки контакта
  void spawnSparks(Vector2 worldContact) {
    int spawned = 0;
    const int sparksToSpawn = 16;

    for (final spark in _pool) {
      if (spark.life <= 0.0) {
        final angle = _random.nextDouble() * 2 * pi;
        final speed = 2.0 + _random.nextDouble() * 5.0;
        
        spark.position.setFrom(worldContact);
        spark.velocity.setValues(cos(angle) * speed, sin(angle) * speed);
        spark.maxLife = 0.4 + _random.nextDouble() * 0.4;
        spark.life = spark.maxLife;
        spark.color = _random.nextBool() ? Colors.orangeAccent : Colors.yellowAccent;
        spark.isSmoke = false;

        spawned++;
        if (spawned >= sparksToSpawn) break;
      }
    }
  }

  // Спавн неоновых защитных искр при отражении удара щитом
  void spawnDeflectSparks(Vector2 worldContact, Vector2 normal) {
    int spawned = 0;
    const int sparksToSpawn = 22;
    final baseAngle = atan2(normal.y, normal.x);

    for (final spark in _pool) {
      if (spark.life <= 0.0) {
        final spread = (_random.nextDouble() - 0.5) * 1.5;
        final angle = baseAngle + spread;
        final speed = 3.5 + _random.nextDouble() * 6.5;

        spark.position.setFrom(worldContact);
        spark.velocity.setValues(cos(angle) * speed, sin(angle) * speed);
        spark.maxLife = 0.35 + _random.nextDouble() * 0.35;
        spark.life = spark.maxLife;

        final rng = _random.nextDouble();
        if (rng < 0.45) {
          spark.color = const Color(0xFF00E5FF); // Neon cyan
        } else if (rng < 0.75) {
          spark.color = const Color(0xFF80D8FF); // Electric light blue
        } else {
          spark.color = const Color(0xFFFFD700); // Gold spark
        }
        spark.isSmoke = false;

        spawned++;
        if (spawned >= sparksToSpawn) break;
      }
    }
  }

  // Спавн поднимающегося дыма при критическом состоянии корабля
  void spawnSmoke(Vector2 worldPosition) {
    int spawned = 0;
    const int smokeToSpawn = 2;

    for (final spark in _pool) {
      if (spark.life <= 0.0) {
        // Дым медленно поднимается вверх с небольшим разбросом
        final angle = -pi / 2 + (_random.nextDouble() - 0.5) * 0.4;
        final speed = 0.5 + _random.nextDouble() * 1.0;
        
        spark.position.setFrom(worldPosition);
        // Смещение от центра корпуса
        spark.position.x += (_random.nextDouble() - 0.5) * 0.6;
        spark.position.y += (_random.nextDouble() - 0.5) * 0.6;

        spark.velocity.setValues(cos(angle) * speed, sin(angle) * speed);
        spark.maxLife = 0.7 + _random.nextDouble() * 0.7;
        spark.life = spark.maxLife;

        // Оттенки серого
        final val = 60 + _random.nextInt(80); // 60 to 140
        spark.color = Color.fromARGB(255, val, val, val);
        spark.isSmoke = true;

        spawned++;
        if (spawned >= smokeToSpawn) break;
      }
    }
  }

  // Спавн взрыва (огромное облако искр во все стороны)
  void spawnExplosion(Vector2 position) {
    int spawned = 0;
    const int sparksToSpawn = 80;

    for (final spark in _pool) {
      if (spark.life <= 0.0) {
        final angle = _random.nextDouble() * 2 * pi;
        final speed = 3.0 + _random.nextDouble() * 9.0;
        
        spark.position.setFrom(position);
        spark.velocity.setValues(cos(angle) * speed, sin(angle) * speed);
        spark.maxLife = 0.6 + _random.nextDouble() * 0.8;
        spark.life = spark.maxLife;

        final rng = _random.nextDouble();
        if (rng < 0.33) {
          spark.color = Colors.redAccent;
        } else if (rng < 0.66) {
          spark.color = Colors.orangeAccent;
        } else {
          spark.color = Colors.yellowAccent;
        }
        spark.isSmoke = false;

        spawned++;
        if (spawned >= sparksToSpawn) break;
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    for (final spark in _pool) {
      if (spark.life > 0.0) {
        spark.position.add(spark.velocity * dt);
        if (spark.isSmoke) {
          // Трение воздуха для дыма + подъем вверх
          spark.velocity.x *= 0.93;
          spark.velocity.y -= 0.8 * dt;
        } else {
          // Сила тяжести тянет искру вниз
          spark.velocity.y += 6.5 * dt;
        }
        spark.life -= dt;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    for (final spark in _pool) {
      if (spark.life > 0.0) {
        final progress = (spark.life / spark.maxLife).clamp(0.0, 1.0);
        
        _paint.color = spark.color.withOpacity(progress * 0.85);
        
        final double size;
        if (spark.isSmoke) {
          // Дым расширяется при подъеме
          size = 0.15 + 0.35 * (1.0 - progress);
        } else {
          // Искры сжимаются
          size = 0.08 * progress;
        }
        
        canvas.drawCircle(Offset(spark.position.x, spark.position.y), size, _paint);
      }
    }
  }
}
