import 'dart:ui';
import 'package:flame/components.dart';
import '../lander_zero_game.dart';

class ScreenFlash extends Component with HasGameReference<LanderZeroGame> {
  double alpha = 0.0;

  void trigger() {
    alpha = 0.6; // Стартовая непрозрачность вспышки
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (alpha > 0.0) {
      alpha = (alpha - dt * 3.5).clamp(0.0, 1.0); // Быстрое затухание за ~0.17 сек
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (alpha > 0.0) {
      final rect = Rect.fromLTWH(0, 0, game.size.x, game.size.y);
      final paint = Paint()..color = Color.fromARGB((alpha * 255).toInt(), 255, 255, 255);
      canvas.drawRect(rect, paint);
    }
  }
}
