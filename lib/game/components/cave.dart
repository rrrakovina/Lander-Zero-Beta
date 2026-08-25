import 'dart:math';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import '../lander_zero_game.dart';

class Cave extends BodyComponent {
  LanderZeroGame get gameRef => game as LanderZeroGame;
  final String mapId;
  final List<Vector2> floorPoints = [];
  final List<Vector2> ceilingPoints = [];

  // Координаты важных платформ
  late final Vector2 startPlatform;
  late final Vector2 cargoPlatform;
  late final Vector2 exitPlatform;

  // Для генерации декораций (сталактитов и сталагмитов)
  final List<int> stalactiteIndices = [];
  final List<int> stalagmiteIndices = [];

  Cave({required this.mapId}) {
    if (mapId == 'wind') {
      startPlatform = Vector2(-30, -2);
      cargoPlatform = Vector2(2, 6);
      exitPlatform = Vector2(28, -10);
    } else if (mapId == 'core') {
      startPlatform = Vector2(-26, -8);
      cargoPlatform = Vector2(-2, 10);
      exitPlatform = Vector2(22, -15);
    } else if (mapId == 'ice') {
      startPlatform = Vector2(-28, -4);
      cargoPlatform = Vector2(0, 7);
      exitPlatform = Vector2(26, -11);
    } else if (mapId == 'orbit') {
      startPlatform = Vector2(-25, 0);
      cargoPlatform = Vector2(0, 0);
      exitPlatform = Vector2(25, 0);
    } else {
      // echo / endless / default
      startPlatform = Vector2(-28, -5);
      cargoPlatform = Vector2(0, 8);
      exitPlatform = Vector2(25, -12);
    }
  }

  // Кэшированные Paint объекты для снижения GC Pressure
  final Paint _stoneFillPaint = Paint()
    ..color = const Color(0xFF1E2429)
    ..style = PaintingStyle.fill;

  final Paint _spikePaint = Paint()
    ..color = const Color(0xFF161A1D)
    ..style = PaintingStyle.fill;

  final Paint _spikeBorderPaint = Paint()
    ..color = const Color(0xFF37474F)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.05;

  final Paint _soilPaint = Paint()
    ..color = const Color(0xFF5D4037)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.35
    ..strokeCap = StrokeCap.round;

  final Paint _grassPaint = Paint()
    ..color = const Color(0xFFFF7043)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.12
    ..strokeCap = StrokeCap.round;

  final Paint _ceilingSoilPaint = Paint()
    ..color = const Color(0xFF4E342E)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.35
    ..strokeCap = StrokeCap.round;

  final Paint _ceilingTopPaint = Paint()
    ..color = const Color(0xFFFFB74D)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.12
    ..strokeCap = StrokeCap.round;

  final Paint _platformPaint = Paint()
    ..color = const Color(0xFF263238)
    ..style = PaintingStyle.fill;

  final Paint _linePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.18;

  final Paint _borderPaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.05;

  final Paint _glowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.4
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.2);

  final Paint _stripePaint = Paint()
    ..color = Colors.yellow.withOpacity(0.4)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.1;

  // Переиспользуемые Path объекты
  final Path _floorPath = Path();
  final Path _ceilingPath = Path();
  final Path _closedFloorPath = Path();
  final Path _closedCeilingPath = Path();
  final Path _spikePath = Path();

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Настраиваем уникальные шейдеры и цвета в зависимости от планеты/карты
    if (mapId == 'core') {
      _stoneFillPaint.shader = const LinearGradient(
        colors: [Color(0xFF28130E), Color(0xFF0F0705)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(const Rect.fromLTRB(-70.0, -35.0, 50.0, 25.0));
      
      _soilPaint.color = const Color(0xFF4E2C24);
      _grassPaint.color = const Color(0xFFFF5722); // Ярко-оранжевая раскаленная каемка
      
      _ceilingSoilPaint.color = const Color(0xFF3E1F1A);
      _ceilingTopPaint.color = const Color(0xFFFF7043);

      _spikePaint.color = const Color(0xFF22110D);
      _spikeBorderPaint.color = const Color(0xFFFF5722);
    } else if (mapId == 'wind') {
      _stoneFillPaint.shader = const LinearGradient(
        colors: [Color(0xFF14242A), Color(0xFF070E10)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(const Rect.fromLTRB(-70.0, -35.0, 50.0, 25.0));
      
      _soilPaint.color = const Color(0xFF37474F);
      _grassPaint.color = const Color(0xFF00E5FF); // Неоново-бирюзовая каемка
      
      _ceilingSoilPaint.color = const Color(0xFF263238);
      _ceilingTopPaint.color = const Color(0xFF80DEEA);

      _spikePaint.color = const Color(0xFF121E23);
      _spikeBorderPaint.color = const Color(0xFF00E5FF);
    } else if (mapId == 'ice') {
      _stoneFillPaint.shader = const LinearGradient(
        colors: [Color(0xFF0F1E2E), Color(0xFF060B12)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(const Rect.fromLTRB(-70.0, -35.0, 50.0, 25.0));
      
      _soilPaint.color = const Color(0xFF1E394A);
      _grassPaint.color = const Color(0xFF00E5FF); // Неоновый ледяной циановый ободок
      
      _ceilingSoilPaint.color = const Color(0xFF152634);
      _ceilingTopPaint.color = const Color(0xFF80D8FF);

      _spikePaint.color = const Color(0xFF102634);
      _spikeBorderPaint.color = const Color(0xFF00E5FF);
    } else if (mapId == 'orbit') {
      _stoneFillPaint.shader = const LinearGradient(
        colors: [Color(0xFF140F24), Color(0xFF07050E)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(const Rect.fromLTRB(-70.0, -35.0, 50.0, 25.0));
      
      _soilPaint.color = const Color(0xFF2E1A47);
      _grassPaint.color = const Color(0xFFE040FB); // Неоново-фиолетовый космический рубеж
      
      _ceilingSoilPaint.color = const Color(0xFF221338);
      _ceilingTopPaint.color = const Color(0xFFEA80FC);

      _spikePaint.color = const Color(0xFF1E1333);
      _spikeBorderPaint.color = const Color(0xFFE040FB);
    } else {
      // echo / default
      _stoneFillPaint.shader = const LinearGradient(
        colors: [Color(0xFF212529), Color(0xFF0A0C0D)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(const Rect.fromLTRB(-70.0, -35.0, 50.0, 25.0));
      
      _soilPaint.color = const Color(0xFF5D4037);
      _grassPaint.color = const Color(0xFFFFB300); // Янтарная каемка
      
      _ceilingSoilPaint.color = const Color(0xFF4E342E);
      _ceilingTopPaint.color = const Color(0xFFFFD54F);

      _spikePaint.color = const Color(0xFF161A1D);
      _spikeBorderPaint.color = const Color(0xFF37474F);
    }
  }

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.static,
      position: Vector2.zero(),
    );

    final body = world.createBody(bodyDef);

    _generateCaveGeometry();

    // Физические свойства грунта в зависимости от биома
    double floorFriction = 0.8;
    double floorRestitution = 0.05;

    if (mapId == 'ice') {
      floorFriction = 0.08; // Сверхскользкий лед Европы
      floorRestitution = 0.25;
    } else if (mapId == 'orbit') {
      floorFriction = 0.10;
      floorRestitution = 0.35;
    }

    // Физическая форма пола
    final floorShape = ChainShape()..createChain(floorPoints);
    body.createFixture(
      FixtureDef(floorShape)
        ..friction = floorFriction
        ..restitution = floorRestitution,
    );

    // Физическая форма потолка
    final ceilingShape = ChainShape()..createChain(ceilingPoints);
    body.createFixture(
      FixtureDef(ceilingShape)
        ..friction = (floorFriction * 0.7).clamp(0.05, 0.6)
        ..restitution = floorRestitution,
    );

    // Боковые стенки (левая и правая границы пещеры)
    final leftWall = EdgeShape()..set(
      Vector2(floorPoints.first.x, floorPoints.first.y),
      Vector2(ceilingPoints.first.x, ceilingPoints.first.y),
    );
    body.createFixture(
      FixtureDef(leftWall)
        ..friction = 0.5
        ..restitution = 0.2,
    );

    final rightWall = EdgeShape()..set(
      Vector2(floorPoints.last.x, floorPoints.last.y),
      Vector2(ceilingPoints.last.x, ceilingPoints.last.y),
    );
    body.createFixture(
      FixtureDef(rightWall)
        ..friction = 0.5
        ..restitution = 0.2,
    );

    return body;
  }

  void _generateCaveGeometry() {
    final random = Random(12345); // Зафиксируем сид
    const int resolution = 80; // Больше сегментов для длинной пещеры
    const double startX = -70.0; // Сдвинуто далеко влево, чтобы не было пустой полосы
    const double endX = 50.0;
    const double stepX = (endX - startX) / resolution;

    for (int i = 0; i <= resolution; i++) {
      final x = startX + i * stepX;
      double floorY = 5.0;
      double ceilingY = -22.0;

      // 1. Формирование платформ (ровных горизонтальных участков)
      if ((x - startPlatform.x).abs() < 4.5) {
        floorY = startPlatform.y;
      } else if ((x - cargoPlatform.x).abs() < 5.5) {
        floorY = cargoPlatform.y;
      } else if ((x - exitPlatform.x).abs() < 4.5) {
        floorY = exitPlatform.y;
      } else {
        if (mapId == 'wind') {
          final double baseFloor = 2.0 * sin(x * 0.22) + 1.5 * cos(x * 0.15) + 3.0;
          final double noise = (random.nextDouble() - 0.5) * 1.0;
          floorY = baseFloor + noise;
        } else if (mapId == 'core') {
          final double baseFloor = 5.5 * sin(x * 0.2) + 3.5 * cos(x * 0.1) - 1.0;
          final double noise = (random.nextDouble() - 0.5) * 2.0;
          floorY = baseFloor + noise;
        } else if (mapId == 'ice') {
          // Скользящие гладкие волны ледников с острыми трещинами
          final double baseFloor = 3.5 * sin(x * 0.16) + 1.8 * cos(x * 0.24) + 2.5;
          final double noise = (random.nextDouble() - 0.5) * 0.8;
          floorY = baseFloor + noise;
        } else if (mapId == 'orbit') {
          // Просторные орбитальные пустоты вокруг астероидов
          final double baseFloor = 4.0 * sin(x * 0.10) + 1.5 * cos(x * 0.08) + 6.0;
          final double noise = (random.nextDouble() - 0.5) * 1.0;
          floorY = baseFloor + noise;
        } else {
          // echo / default
          final double baseFloor = 3.0 * sin(x * 0.12) + 2.0 * cos(x * 0.07) + 2.0;
          final double noise = (random.nextDouble() - 0.5) * 1.5;
          floorY = baseFloor + noise;
        }
      }

      // Генерация потолка пещеры (высота прохода не менее 9-12 метров)
      if ((x - exitPlatform.x).abs() < 4.5) {
        ceilingY = exitPlatform.y - 12.0; 
      } else {
        if (mapId == 'wind') {
          final double baseCeiling = -22.0 + 2.0 * sin(x * 0.18) - 1.5 * cos(x * 0.12);
          final double noise = (random.nextDouble() - 0.5) * 1.0;
          ceilingY = baseCeiling + noise;
        } else if (mapId == 'core') {
          final double baseCeiling = -25.0 + 5.0 * sin(x * 0.15) - 3.0 * cos(x * 0.08);
          final double noise = (random.nextDouble() - 0.5) * 2.0;
          ceilingY = baseCeiling + noise;
        } else if (mapId == 'ice') {
          final double baseCeiling = -22.0 + 3.0 * sin(x * 0.14) - 2.0 * cos(x * 0.09);
          final double noise = (random.nextDouble() - 0.5) * 1.0;
          ceilingY = baseCeiling + noise;
        } else if (mapId == 'orbit') {
          final double baseCeiling = -26.0 + 3.5 * sin(x * 0.08) - 2.0 * cos(x * 0.05);
          final double noise = (random.nextDouble() - 0.5) * 1.0;
          ceilingY = baseCeiling + noise;
        } else {
          // echo / default
          final double baseCeiling = -20.0 + 3.0 * sin(x * 0.1) - 2.0 * cos(x * 0.06);
          final double noise = (random.nextDouble() - 0.5) * 1.5;
          ceilingY = baseCeiling + noise;
        }
      }

      // Ограничиваем сжатие пещеры
      if (ceilingY >= floorY - 9.0) {
        ceilingY = floorY - 9.0;
      }

      floorPoints.add(Vector2(x, floorY));
      ceilingPoints.add(Vector2(x, ceilingY));

      // Добавляем индексы для декораций (исключая платформы)
      if (i > 3 && i < resolution - 3) {
        final onPlatform = (x - startPlatform.x).abs() < 6.0 ||
                           (x - cargoPlatform.x).abs() < 7.0 ||
                           (x - exitPlatform.x).abs() < 6.0;
        if (!onPlatform) {
          final double spawnProb = mapId == 'core' ? 0.25 : (mapId == 'ice' ? 0.22 : (mapId == 'wind' ? 0.15 : 0.10));
          if (random.nextDouble() < spawnProb) {
            if (random.nextBool()) {
              stalactiteIndices.add(i);
            } else {
              stalagmiteIndices.add(i);
            }
          }
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (floorPoints.isEmpty || ceilingPoints.isEmpty) return;

    // Определяем видимый диапазон по оси X с запасом по краям
    final double camX = gameRef.camera.viewfinder.position.x;
    final double zoom = gameRef.camera.viewfinder.zoom;
    final double viewWidth = gameRef.size.x / zoom;
    final double leftX = camX - viewWidth / 2 - 4.0;
    final double rightX = camX + viewWidth / 2 + 4.0;

    // Находим индексы видимых вершин
    int startIdx = 0;
    int endIdx = floorPoints.length - 1;

    for (int i = 0; i < floorPoints.length; i++) {
      if (floorPoints[i].x < leftX) {
        startIdx = i;
      } else {
        break;
      }
    }

    for (int i = floorPoints.length - 1; i >= 0; i--) {
      if (floorPoints[i].x > rightX) {
        endIdx = i;
      } else {
        break;
      }
    }

    if (startIdx >= endIdx) return;

    final List<Vector2> visibleFloor = floorPoints.sublist(startIdx, endIdx + 1);
    final List<Vector2> visibleCeiling = ceilingPoints.sublist(startIdx, endIdx + 1);

    // 1. Отрисовка темных глубин скалы (фон земли) с использованием кэшированного _stoneFillPaint
    _floorPath.reset();
    _floorPath.moveTo(visibleFloor.first.x, visibleFloor.first.y);
    for (int i = 1; i < visibleFloor.length; i++) {
      _floorPath.lineTo(visibleFloor[i].x, visibleFloor[i].y);
    }
    
    _closedFloorPath.reset();
    _closedFloorPath.addPath(_floorPath, Offset.zero);
    _closedFloorPath.lineTo(visibleFloor.last.x, 40.0);
    _closedFloorPath.lineTo(visibleFloor.first.x, 40.0);
    _closedFloorPath.close();

    canvas.drawPath(_closedFloorPath, _stoneFillPaint);

    // Путь для потолка
    _ceilingPath.reset();
    _ceilingPath.moveTo(visibleCeiling.first.x, visibleCeiling.first.y);
    for (int i = 1; i < visibleCeiling.length; i++) {
      _ceilingPath.lineTo(visibleCeiling[i].x, visibleCeiling[i].y);
    }

    _closedCeilingPath.reset();
    _closedCeilingPath.addPath(_ceilingPath, Offset.zero);
    _closedCeilingPath.lineTo(visibleCeiling.last.x, -50.0);
    _closedCeilingPath.lineTo(visibleCeiling.first.x, -50.0);
    _closedCeilingPath.close();

    canvas.drawPath(_closedCeilingPath, _stoneFillPaint);

    // 2. Рисуем только те сталактиты и сталагмиты, которые попадают в видимый диапазон
    for (final index in stalactiteIndices) {
      final p = ceilingPoints[index];
      if (p.x >= leftX - 2.0 && p.x <= rightX + 2.0) {
        _spikePath.reset();
        _spikePath.moveTo(p.x - 0.6, p.y);
        _spikePath.lineTo(p.x + 0.6, p.y);
        _spikePath.lineTo(p.x, p.y + 1.8 + sin(p.x) * 0.4);
        _spikePath.close();
        canvas.drawPath(_spikePath, _spikePaint);
        canvas.drawPath(_spikePath, _spikeBorderPaint);
      }
    }

    for (final index in stalagmiteIndices) {
      final p = floorPoints[index];
      if (p.x >= leftX - 2.0 && p.x <= rightX + 2.0) {
        _spikePath.reset();
        _spikePath.moveTo(p.x - 0.6, p.y);
        _spikePath.lineTo(p.x + 0.6, p.y);
        _spikePath.lineTo(p.x, p.y - 1.8 - cos(p.x) * 0.4);
        _spikePath.close();
        canvas.drawPath(_spikePath, _spikePaint);
        canvas.drawPath(_spikePath, _spikeBorderPaint);
      }
    }

    // 3. Текстурированный ободок грунта
    canvas.drawPath(_floorPath, _soilPaint);
    canvas.drawPath(_floorPath, _grassPaint);

    canvas.drawPath(_ceilingPath, _ceilingSoilPaint);
    canvas.drawPath(_ceilingPath, _ceilingTopPaint);

    // 4. Отрисовка платформ, если они видны
    final platformNeon = mapId == 'ice'
        ? const Color(0xFF00E5FF)
        : (mapId == 'orbit'
            ? const Color(0xFFE040FB)
            : (mapId == 'core' ? const Color(0xFFFF5722) : Colors.blueAccent));

    if (startPlatform.x >= leftX - 6.0 && startPlatform.x <= rightX + 6.0) {
      _drawPlatformOverlay(canvas, startPlatform, 4.5, platformNeon);
    }
    if (cargoPlatform.x >= leftX - 7.0 && cargoPlatform.x <= rightX + 7.0) {
      _drawPlatformOverlay(canvas, cargoPlatform, 5.5, Colors.greenAccent);
    }
    if (exitPlatform.x >= leftX - 6.0 && exitPlatform.x <= rightX + 6.0) {
      _drawPlatformOverlay(canvas, exitPlatform, 4.5, Colors.orangeAccent);
    }
  }

  void _drawPlatformOverlay(Canvas canvas, Vector2 platformCenter, double halfWidth, Color neonColor) {
    _linePaint.color = neonColor;
    _glowPaint.color = neonColor.withOpacity(0.4);

    // Свечение под неоновой линией платформы
    canvas.drawLine(
      Offset(platformCenter.x - halfWidth, platformCenter.y),
      Offset(platformCenter.x + halfWidth, platformCenter.y),
      _glowPaint,
    );

    final rect = Rect.fromLTRB(
      platformCenter.x - halfWidth,
      platformCenter.y,
      platformCenter.x + halfWidth,
      platformCenter.y + 0.6,
    );

    canvas.drawRect(rect, _platformPaint);
    canvas.drawRect(rect, _borderPaint);
    canvas.drawLine(
      Offset(platformCenter.x - halfWidth, platformCenter.y),
      Offset(platformCenter.x + halfWidth, platformCenter.y),
      _linePaint,
    );

    // Рисуем индустриальные желто-черные полосы
    for (double x = platformCenter.x - halfWidth + 0.4; x < platformCenter.x + halfWidth; x += 0.8) {
      canvas.drawLine(
        Offset(x, platformCenter.y + 0.6),
        Offset(x + 0.4, platformCenter.y),
        _stripePaint,
      );
    }
  }

  double _getYFromPoints(List<Vector2> points, double x) {
    if (points.isEmpty) return 0.0;
    if (x <= points.first.x) return points.first.y;
    if (x >= points.last.x) return points.last.y;

    int lo = 0, hi = points.length - 1;
    while (lo < hi - 1) {
      final mid = (lo + hi) ~/ 2;
      if (points[mid].x <= x) {
        lo = mid;
      } else {
        hi = mid;
      }
    }

    final p0 = points[lo];
    final p1 = points[hi];
    final t = (x - p0.x) / (p1.x - p0.x);
    return p0.y + (p1.y - p0.y) * t;
  }

  double getFloorY(double x) => _getYFromPoints(floorPoints, x);

  double getCeilingY(double x) => _getYFromPoints(ceilingPoints, x);
}
