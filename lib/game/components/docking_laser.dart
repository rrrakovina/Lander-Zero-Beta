import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../config/game_config.dart';
import '../lander_zero_game.dart';

class DockingLaser extends Component with HasGameReference<LanderZeroGame> {
  final Paint _laserPaint = Paint()
    ..style = PaintingStyle.fill;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final lander = game.lander;
    final cargo = game.cargoCapsule;

    // Отрисовываем луч только если трос не подключен и оба тела живы
    if (game.rope != null || !lander.isMounted || !cargo.isMounted || lander.exploded) {
      return;
    }

    final landerHook = lander.body.worldPoint(Vector2(0, 0.8));
    final cargoHook = cargo.body.worldPoint(Vector2(0, -0.9));
    final double distance = landerHook.distanceTo(cargoHook);

    // Дальность действия магнитного захвата
    final double maxTargetingDistance = GameConfig.dockingRange + 2.0;

    if (distance > maxTargetingDistance) {
      return;
    }

    // Проверка безопасности скорости сближения
    final relativeVel = lander.body.linearVelocity - cargo.body.linearVelocity;
    final bool isSafeSpeed = relativeVel.length <= 3.0;

    Color beamColor;
    if (distance <= GameConfig.dockingRange) {
      beamColor = isSafeSpeed ? const Color(0xFF00E5FF) : const Color(0xFFFF1744); // Циан или Сигнальный красный
    } else {
      beamColor = isSafeSpeed 
          ? const Color(0xFF00E5FF).withOpacity(0.4) // Полупрозрачный циан
          : const Color(0xFFFFB300).withOpacity(0.3); // Полупрозрачный янтарный
    }

    _laserPaint.color = beamColor;

    // Отрисовываем бегущие точки (эффект притяжения лебедки)
    final int dotCount = (distance * 6).toInt().clamp(4, 30);
    // Скорость анимации бегущих точек
    final double scrollSpeed = 4.0; 
    final double offsetFraction = (game.flightTime * scrollSpeed) % 1.0;

    for (int i = 0; i < dotCount; i++) {
      final double t = (i + offsetFraction) / dotCount;
      if (t > 1.0) continue;
      
      final Vector2 p = landerHook + (cargoHook - landerHook) * t;
      // Точки сужаются по направлению к грузу, создавая эффект фокуса
      final double dotRadius = 0.07 * (1.0 - t * 0.4);
      
      canvas.drawCircle(Offset(p.x, p.y), dotRadius, _laserPaint);
    }
  }
}
