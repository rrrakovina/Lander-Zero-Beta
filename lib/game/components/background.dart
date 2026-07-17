import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

class Background extends Component with HasGameReference<Forge2DGame> {
  final List<Offset> _stars = [];
  final List<Offset> _crystals = [];
  final Random _random = Random(101);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Генерируем случайные фоновые звезды/пылинки в пещере
    for (int i = 0; i < 50; i++) {
      final x = (_random.nextDouble() - 0.5) * 160.0;
      final y = (_random.nextDouble() - 0.6) * 60.0;
      _stars.add(Offset(x, y));
    }

    // Генерируем кристаллы в фоне
    for (int i = 0; i < 18; i++) {
      final x = (_random.nextDouble() - 0.5) * 140.0;
      // Спавним на разной высоте потолка и пола
      final y = -14.0 + (_random.nextDouble() - 0.5) * 16.0;
      _crystals.add(Offset(x, y));
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final camX = game.camera.viewfinder.position.x;
    final camY = game.camera.viewfinder.position.y;

    // 1. Отрисовка звезд/пыли с очень медленным параллаксом
    final starPaint = Paint()
      ..color = const Color(0xFF90A4AE).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(-camX * 0.02, -camY * 0.02);
    for (final star in _stars) {
      canvas.drawCircle(star, 0.06, starPaint);
    }
    canvas.restore();

    // 2. Слой 1: Дальние горы (светло-серые, медленные)
    _renderMountainLayer(
      canvas,
      camX: camX,
      camY: camY,
      factor: 0.05,
      color: const Color(0xFF161C20),
      heightOffset: -5.0,
      amplitude: 2.5,
      frequency: 0.04,
    );

    // 3. Силуэты заброшенных шахтных конструкций (Layer 1.5)
    _renderIndustrialSilhouettes(canvas, camX, camY);

    // 4. Слой 2: Средние горы (более темные, средняя скорость)
    _renderMountainLayer(
      canvas,
      camX: camX,
      camY: camY,
      factor: 0.15,
      color: const Color(0xFF111518),
      heightOffset: 2.0,
      amplitude: 1.8,
      frequency: 0.08,
    );

    // 5. Светящиеся кристаллы на среднем слое
    _renderGlowingCrystals(canvas, camX, camY);

    // 6. Слой 3: Ближние скалы/холмы (самые темные, быстрые)
    _renderMountainLayer(
      canvas,
      camX: camX,
      camY: camY,
      factor: 0.28,
      color: const Color(0xFF090C0E),
      heightOffset: 7.0,
      amplitude: 1.2,
      frequency: 0.15,
    );
  }

  void _renderMountainLayer(
    Canvas canvas, {
    required double camX,
    required double camY,
    required double factor,
    required Color color,
    required double heightOffset,
    required double amplitude,
    required double frequency,
  }) {
    canvas.save();
    canvas.translate(-camX * factor, -camY * factor);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    const double startX = -100.0;
    const double endX = 100.0;
    const double step = 2.0;

    path.moveTo(startX, 40.0);
    
    for (double x = startX; x <= endX; x += step) {
      final y = heightOffset + amplitude * sin(x * frequency) + (amplitude * 0.4) * cos(x * frequency * 2.3);
      path.lineTo(x, y);
    }
    
    path.lineTo(endX, 40.0);
    path.close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _renderIndustrialSilhouettes(Canvas canvas, double camX, double camY) {
    canvas.save();
    canvas.translate(-camX * 0.10, -camY * 0.10);

    final paint = Paint()
      ..color = const Color(0xFF13181C)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = const Color(0xFF13181C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.12;

    // Рисуем опоры, балки, вышки в определенных точках по ширине
    final xs = [-55.0, -30.0, -5.0, 20.0, 45.0];
    for (final x in xs) {
      // 1. Вертикальная опора
      canvas.drawRect(Rect.fromLTRB(x - 0.5, -22.0, x + 0.5, 20.0), paint);
      // 2. Поперечные фермы (балки)
      canvas.drawRect(Rect.fromLTRB(x - 4.0, -18.0, x + 4.0, -17.5), paint);
      canvas.drawRect(Rect.fromLTRB(x - 3.0, -8.0, x + 3.0, -7.5), paint);
      // 3. Диагональные связи
      canvas.drawLine(Offset(x - 0.5, -18.0), Offset(x - 3.0, -8.0), linePaint);
      canvas.drawLine(Offset(x + 0.5, -18.0), Offset(x + 3.0, -8.0), linePaint);
    }
    canvas.restore();
  }

  void _renderGlowingCrystals(Canvas canvas, double camX, double camY) {
    canvas.save();
    canvas.translate(-camX * 0.15, -camY * 0.15);

    final crystalColors = [
      const Color(0xFF00E5FF), // Неоновый циан
      const Color(0xFFFF7043), // Неоновый оранжевый
      const Color(0xFFE040FB), // Неоновый фиолетовый
    ];

    for (int i = 0; i < _crystals.length; i++) {
      final pos = _crystals[i];
      final color = crystalColors[i % crystalColors.length];
      final size = 0.35 + sin(i * 0.5) * 0.1;

      // Геометрия кристалла (ромб)
      final path = Path()
        ..moveTo(pos.dx, pos.dy - size)
        ..lineTo(pos.dx + size * 0.6, pos.dy)
        ..lineTo(pos.dx, pos.dy + size)
        ..lineTo(pos.dx - size * 0.6, pos.dy)
        ..close();

      // Эффект свечения в фоне
      final glowPaint = Paint()
        ..color = color.withOpacity(0.35)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.2);

      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final outlinePaint = Paint()
        ..color = const Color(0xFF121214)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.04;

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, outlinePaint);
    }
    canvas.restore();
  }
}
