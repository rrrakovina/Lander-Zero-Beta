import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import '../config/game_config.dart';

class CargoCapsule extends BodyComponent {
  final Vector2 initialPosition;

  CargoCapsule({required this.initialPosition});

  // Состояние зацепа
  bool isDocked = false;

  // Оптимизированные Paint объекты для снижения GC Pressure
  final Paint _bodyPaint = Paint()
    ..color = const Color(0xFF37474F) // Темный индастриал
    ..style = PaintingStyle.fill;

  final Paint _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.08;

  final Paint _lightPaint = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.1);

  final Paint _innerLightPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  final Paint _hookPaint = Paint()
    ..color = Colors.grey
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.1;

  // Переиспользуемый Path
  final Path _capsulePath = Path();

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _capsulePath
      ..moveTo(0.0, -0.9)
      ..lineTo(0.8, -0.4)
      ..lineTo(0.6, 0.9)
      ..lineTo(-0.6, 0.9)
      ..lineTo(-0.8, -0.4)
      ..close();
  }

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: initialPosition,
      linearDamping: 1.5,   // Сопротивление воздуха для груза
      angularDamping: 3.0,  // Сильная стабилизация вращения
    );

    final body = world.createBody(bodyDef);

    // Геометрия спасательной капсулы (шестиугольник) - против часовой стрелки (CCW)
    final vertices = [
      Vector2(0.0, -0.9),   // Верхняя точка (петля зацепа)
      Vector2(0.8, -0.4),   // Правый верх
      Vector2(0.6, 0.9),    // Правый низ
      Vector2(-0.6, 0.9),   // Левый низ
      Vector2(-0.8, -0.4),  // Левый верх
    ];

    final shape = PolygonShape()..set(vertices);

    final fixtureDef = FixtureDef(
      shape,
      density: GameConfig.cargoMass,
      friction: 0.3,
      restitution: 0.05,
    )..filter.categoryBits = 0x0008
     ..filter.maskBits = 0xFFFF & ~0x0004 & ~0x0002; // Столкновения со всем, кроме троса (0x0004) и корабля (0x0002)

    body.createFixture(fixtureDef);
    return body;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Подсветка статуса стыковки
    _borderPaint.color = isDocked ? Colors.greenAccent : Colors.redAccent;
    _lightPaint.color = isDocked 
        ? Colors.greenAccent.withOpacity(0.8) 
        : Colors.redAccent.withOpacity(0.8);

    canvas.drawPath(_capsulePath, _bodyPaint);
    canvas.drawPath(_capsulePath, _borderPaint);

    // Сигнальный маяк/иллюминатор по центру капсулы
    canvas.drawCircle(const Offset(0.0, 0.0), 0.25, _lightPaint);
    
    // Внутренний свет маяка
    canvas.drawCircle(const Offset(0.0, 0.0), 0.08, _innerLightPaint);

    // Зацепная петля на самом верху
    canvas.drawCircle(const Offset(0.0, -0.9), 0.15, _hookPaint);
  }
}
