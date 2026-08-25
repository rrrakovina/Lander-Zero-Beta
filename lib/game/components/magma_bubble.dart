import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../lander_zero_game.dart';

/// Interactive magma bubble hazard for the Deep Core biome.
/// Slowly rises from the molten floor towards the ceiling and inflicts thermal damage on contact.
class MagmaBubble extends PositionComponent with HasGameReference<LanderZeroGame> {
  final double minX;
  final double maxX;
  final double speed;
  final double radius;

  double _wobblePhase = 0.0;
  bool _isPopped = false;

  late final Paint _bubbleFillPaint;
  late final Paint _bubbleBorderPaint;
  late final Paint _glowPaint;

  MagmaBubble({
    required this.minX,
    required this.maxX,
    this.speed = 2.2,
    this.radius = 0.6,
  }) {
    width = radius * 2;
    height = radius * 2;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final r = Random();
    _wobblePhase = r.nextDouble() * 2 * pi;
    _resetPosition(r);

    _bubbleFillPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD54F),
          const Color(0xFFFF5722),
          const Color(0xFFD50000).withOpacity(0.85),
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));

    _bubbleBorderPaint = Paint()
      ..color = const Color(0xFFFFAB00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.06;

    _glowPaint = Paint()
      ..color = const Color(0xFFFF3D00).withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.2);
  }

  void _resetPosition([Random? rand]) {
    final r = rand ?? Random();
    final spawnX = minX + r.nextDouble() * (maxX - minX);
    final floorY = game.cave.getFloorY(spawnX);
    position = Vector2(spawnX, floorY - 0.2);
    _isPopped = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isPopped) return;

    _wobblePhase += dt * 3.5;
    final wobbleX = sin(_wobblePhase) * 0.015;

    position.y -= speed * dt;
    position.x += wobbleX;

    // Check collision with cave ceiling
    final ceilingY = game.cave.getCeilingY(position.x);
    if (position.y <= ceilingY + 0.3) {
      _pop();
      return;
    }

    // Check collision with Lander
    if (game.isLoaded && game.lander.isMounted) {
      final lander = game.lander;
      final dist = lander.body.position.distanceTo(position);
      if (dist < radius + 0.8) {
        // Deal thermal damage
        lander.shield = (lander.shield - 20.0).clamp(0.0, lander.maxShield);
        game.sparkPool.spawnSparks(position);
        game.shakeCamera(0.4, 0.2);
        _pop();
      }
    }
  }

  void _pop() {
    _isPopped = true;
    game.sparkPool.spawnSparks(position);
    // Reset after a brief delay
    _resetPosition();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_isPopped) return;

    canvas.drawCircle(Offset.zero, radius * 1.3, _glowPaint);
    canvas.drawCircle(Offset.zero, radius, _bubbleFillPaint);
    canvas.drawCircle(Offset.zero, radius, _bubbleBorderPaint);

    // Specular highlight
    final highlightPaint = Paint()..color = Colors.white.withOpacity(0.65);
    canvas.drawCircle(Offset(-radius * 0.3, -radius * 0.3), radius * 0.2, highlightPaint);
  }
}
