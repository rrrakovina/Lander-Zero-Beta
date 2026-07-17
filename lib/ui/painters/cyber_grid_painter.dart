import 'package:flutter/material.dart';
import '../../../game/config/game_config.dart';

class CyberGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke;

    final double horizon = size.height * 0.25; // Линия горизонта
    const double baseStep = 45.0;
    
    // 1. Рисуем горизонтальные линии с перспективным сжатием
    double currentY = size.height;
    double currentStep = baseStep;
    while (currentY > horizon) {
      final double ratio = (currentY - horizon) / (size.height - horizon);
      paint.color = GameConfig.colorPrimary.withOpacity(0.15 * ratio);
      paint.strokeWidth = 0.5 + 1.2 * ratio;
      
      canvas.drawLine(Offset(0, currentY), Offset(size.width, currentY), paint);
      
      currentY -= currentStep;
      currentStep *= 0.88; // Линии сближаются к горизонту
      if (currentStep < 3.0) break;
    }

    // 2. Рисуем сходящиеся лучи из точки схода на горизонте
    final Offset vanishingPoint = Offset(size.width / 2, horizon);
    const int linesCount = 20;
    for (int i = 0; i <= linesCount; i++) {
      final double fraction = i / linesCount;
      // Широкий веер лучей у низа экрана
      final double startX = size.width * (fraction * 2.5 - 0.75); 
      
      paint.color = GameConfig.colorPrimary.withOpacity(0.08);
      paint.strokeWidth = 0.8;
      
      canvas.drawLine(vanishingPoint, Offset(startX, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
