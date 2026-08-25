import 'dart:math';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import '../lander_zero_game.dart';

/// Interactive rotating space debris obstacle for the Orbital Debris biome.
/// Provides rigid-body Box2D collision, angular rotation in zero-G, and custom vector visuals.
class RotatingDebris extends BodyComponent<LanderZeroGame> with ContactCallbacks {
  final Vector2 initialPosition;
  final double width;
  final double height;
  final double angularSpeed;
  final String debrisType; // 'solar_panel', 'truss', 'module'

  RotatingDebris({
    required this.initialPosition,
    this.width = 1.4,
    this.height = 6.5,
    this.angularSpeed = 0.6,
    this.debrisType = 'solar_panel',
  });

  // Pre-cached Paint objects
  static final Paint _solarCellPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _framePaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _gridLinePaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _glowPaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _hubPaint = Paint()..style = PaintingStyle.fill;

  @override
  Body createBody() {
    final shape = PolygonShape()
      ..setAsBox(width / 2, height / 2, Vector2.zero(), 0);

    final fixtureDef = FixtureDef(shape)
      ..density = 5.0
      ..friction = 0.2
      ..restitution = 0.35
      ..filter.categoryBits = 0x0010; // Dynamic obstacle category

    final bodyDef = BodyDef()
      ..type = BodyType.kinematic
      ..position = initialPosition
      ..angularVelocity = angularSpeed;

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }



  @override
  void render(Canvas canvas) {
    final halfW = width / 2;
    final halfH = height / 2;

    if (debrisType == 'solar_panel') {
      _renderSolarPanel(canvas, halfW, halfH);
    } else if (debrisType == 'truss') {
      _renderTruss(canvas, halfW, halfH);
    } else {
      _renderModule(canvas, halfW, halfH);
    }
  }

  void _renderSolarPanel(Canvas canvas, double hw, double hh) {
    final rect = Rect.fromLTRB(-hw, -hh, hw, hh);

    // Photovoltaic blue gradient background
    _solarCellPaint.shader = const LinearGradient(
      colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF0A2558)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(rect);
    canvas.drawRect(rect, _solarCellPaint);

    // Gold foil / titanium frame
    _framePaint
      ..color = const Color(0xFFFFD54F)
      ..strokeWidth = 0.08;
    canvas.drawRect(rect, _framePaint);

    // Outer cyan/purple hazard glow
    _glowPaint
      ..color = const Color(0x66E040FB)
      ..strokeWidth = 0.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.15);
    canvas.drawRect(rect, _glowPaint);

    // Photovoltaic cell grid lines
    _gridLinePaint
      ..color = const Color(0x8890CAF9)
      ..strokeWidth = 0.03;

    // Horizontal cell divisions
    const int cells = 6;
    final cellHeight = height / cells;
    for (int i = 1; i < cells; i++) {
      final y = -hh + i * cellHeight;
      canvas.drawLine(Offset(-hw, y), Offset(hw, y), _gridLinePaint);
    }

    // Central structural strut
    _gridLinePaint
      ..color = const Color(0xFFFFE082)
      ..strokeWidth = 0.05;
    canvas.drawLine(Offset(0, -hh), Offset(0, hh), _gridLinePaint);

    // Central mounting hub
    _hubPaint.color = const Color(0xFF37474F);
    canvas.drawCircle(Offset.zero, 0.35, _hubPaint);
    _hubPaint.color = const Color(0xFFFFD54F);
    canvas.drawCircle(Offset.zero, 0.15, _hubPaint);
  }

  void _renderTruss(Canvas canvas, double hw, double hh) {
    final rect = Rect.fromLTRB(-hw, -hh, hw, hh);

    _solarCellPaint.shader = null;
    _solarCellPaint.color = const Color(0xFF263238);
    canvas.drawRect(rect, _solarCellPaint);

    _framePaint
      ..color = const Color(0xFF90A4AE)
      ..strokeWidth = 0.08;
    canvas.drawRect(rect, _framePaint);

    // Cross lattice
    _gridLinePaint
      ..color = const Color(0xFFCFD8DC)
      ..strokeWidth = 0.04;

    const int segments = 4;
    final segW = width / segments;
    for (int i = 0; i < segments; i++) {
      final x1 = -hw + i * segW;
      final x2 = x1 + segW;
      canvas.drawLine(Offset(x1, -hh), Offset(x2, hh), _gridLinePaint);
      canvas.drawLine(Offset(x1, hh), Offset(x2, -hh), _gridLinePaint);
    }
  }

  void _renderModule(Canvas canvas, double hw, double hh) {
    final rect = Rect.fromLTRB(-hw, -hh, hw, hh);

    _solarCellPaint.shader = const RadialGradient(
      colors: [Color(0xFF455A64), Color(0xFF1C2833)],
    ).createShader(rect);
    canvas.drawRect(rect, _solarCellPaint);

    _framePaint
      ..color = const Color(0xFFE040FB)
      ..strokeWidth = 0.10;
    canvas.drawRect(rect, _framePaint);

    // Center viewport
    _hubPaint.color = const Color(0xFF00E5FF);
    canvas.drawCircle(Offset.zero, min(hw, hh) * 0.4, _hubPaint);
  }
}
