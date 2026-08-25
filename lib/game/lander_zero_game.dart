import 'dart:async';
import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'components/lander.dart';
import 'components/cave.dart';
import 'components/cargo_capsule.dart';
import 'components/rope.dart';
import 'components/docking_laser.dart';
import 'components/background.dart';
import 'components/coin.dart';
import 'components/fuel_pickup.dart';
import 'components/repair_pickup.dart';
import 'components/spark_particle.dart';
import 'components/screen_flash.dart';
import 'components/geyser.dart';
import 'components/stalactite.dart';
import 'components/magma_bubble.dart';
import 'components/wind_effect.dart';
import 'components/endless_cave_manager.dart';
import 'config/game_config.dart';
import 'state/game_state.dart';
import 'state/achievements_manager.dart';
import 'audio/game_audio_manager.dart';

enum GameRunState { playing, won, lost }

class LanderZeroGame extends Forge2DGame with HasKeyboardHandlerComponents {
  final String mapId;

  LanderZeroGame({required this.mapId}) : super(gravity: Vector2(0, _getGravity(mapId)));

  static double _getGravity(String mapId) {
    if (mapId == 'core') return 5.3; // 1.5g Heavy Core
    if (mapId == 'ice') return 2.275; // 0.65g Europa low gravity
    if (mapId == 'orbit') return 0.0; // 0.0g Zero Gravity
    return 3.5; // 1.0g Standard
  }

  late final Lander lander;
  late final CargoCapsule cargoCapsule;
  late final Cave cave;
  Rope? rope;
  late final SparkPoolManager sparkPool;
  late final ScreenFlash screenFlash;
  EndlessCaveManager? endlessManager;
  double _hitStopTimer = 0.0;
  double _accumulator = 0.0;
  static const double _fixedTimeStep = 1 / 60;

  // Система кастомных всплывающих предупреждений
  String? _customAlert;
  double _customAlertTimer = 0.0;

  void triggerCustomAlert(String message, double duration) {
    _customAlert = message;
    _customAlertTimer = duration;
  }

  // Игровая статистика для отчета
  int coinsCollected = 0;
  double maxDistance = 0.0;
  double flightTime = 0.0;
  double totalDamage = 0.0;

  // Реактивный статус заезда
  final runStateNotifier = ValueNotifier<GameRunState>(GameRunState.playing);
  final statsNotifier = ValueNotifier<Map<String, dynamic>>({
    'coins': 0,
    'distance': 0.0,
    'alert': '',
    'fuel': 1.0,
    'maxFuel': 1.0,
    'shield': 1.0,
    'maxShield': 1.0,
  });

  // Эффект тряски камеры
  double _shakeTimer = 0.0;
  double _shakeIntensity = 0.0;
  final Random _random = Random();

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    // Камера
    camera.viewfinder.zoom = 35.0; // 1 метр = 35 пикселей

    // 1. Добавляем многослойный параллакс-фон
    world.add(Background());

    if (mapId == 'wind') {
      world.add(WindVisualEffect());
    }

    if (mapId == 'endless') {
      endlessManager = EndlessCaveManager();
      world.add(endlessManager!);
    }

    // 2. Добавляем ландшафт пещеры
    cave = Cave(mapId: mapId);
    await world.add(cave);

    // 3. Спавним Лендер на стартовой платформе
    lander = Lander(initialPosition: Vector2(cave.startPlatform.x, cave.startPlatform.y - 2.0));
    world.add(lander);

    // 4. Спавним капсулу
    cargoCapsule = CargoCapsule(initialPosition: Vector2(cave.cargoPlatform.x, cave.cargoPlatform.y - 0.9));
    world.add(cargoCapsule);

    // 5. Распределяем подбираемые предметы вдоль пещеры
    _spawnPickups();
    _spawnObstacles();

    // 6. Инициализируем и добавляем пул искр
    sparkPool = SparkPoolManager();
    world.add(sparkPool);

    // Добавляем докинг-лазер для визуализации сближения и магнитного зацепа
    world.add(DockingLaser());

    // 7. Добавляем компонент вспышки экрана
    screenFlash = ScreenFlash();
    add(screenFlash);
  }

  void _spawnPickups() {
    final random = Random(888);
    // Расставляем монеты с интервалом в 3 метра
    for (double x = -38.0; x <= 38.0; x += 3.5) {
      // Исключаем непосредственные зоны стартовой, грузовой и выходной платформ
      final onStart = (x - cave.startPlatform.x).abs() < 5.0;
      final onCargo = (x - cave.cargoPlatform.x).abs() < 6.0;
      final onExit = (x - cave.exitPlatform.x).abs() < 5.0;

      if (onStart || onCargo || onExit) continue;

      // Вычисляем высоту пещеры в этой точке из сгенерированной геометрии Cave
      final double floorY = cave.getFloorY(x);
      final double ceilingY = cave.getCeilingY(x);

      // Спавним монету посередине высоты прохода
      final middleY = (floorY + ceilingY) / 2.0 + (random.nextDouble() - 0.5) * 1.5;
      world.add(Coin(position: Vector2(x, middleY)));

      // С некоторой вероятностью спавним топливо или щит
      if (random.nextDouble() < 0.18) {
        final pickupY = floorY - 1.0 - random.nextDouble() * 2.0;
        if (random.nextBool()) {
          world.add(FuelPickup(position: Vector2(x, pickupY)));
        } else {
          world.add(RepairPickup(position: Vector2(x, pickupY)));
        }
      }
    }
  }

  void _spawnObstacles() {
    // Спавним гейзеры на полу
    final double g1x = -13.0;
    world.add(Geyser(position: Vector2(g1x, cave.getFloorY(g1x)), biome: mapId));

    final double g2x = 11.0;
    world.add(Geyser(position: Vector2(g2x, cave.getFloorY(g2x)), biome: mapId));

    // Спавним сталактиты на потолке
    final stalactiteXs = [-20.0, -7.0, 7.0, 17.0];
    for (final sx in stalactiteXs) {
      final cy = cave.getCeilingY(sx);
      world.add(Stalactite(initialPosition: Vector2(sx, cy + 0.8), biome: mapId));
    }

    if (mapId == 'core') {
      world.add(MagmaBubble(minX: -22.0, maxX: 22.0));
      world.add(MagmaBubble(minX: -15.0, maxX: 15.0, speed: 2.8));
    }
  }

  // Метод триггера тряски камеры при ударах
  void shakeCamera(double intensity, double duration) {
    _shakeIntensity = intensity;
    _shakeTimer = duration;
  }

  // Внешний вызов при ударе из lander.dart
  void onCollisionImpact(Vector2 worldContact, double impulse) {
    // Трясем камеру пропорционально силе
    final intensity = (impulse * 0.08).clamp(0.1, 0.9);
    final duration = (impulse * 0.05).clamp(0.15, 0.6);
    shakeCamera(intensity, duration);

    // Звук столкновения
    GameAudioManager().playSfx('collision.wav');

    // Добавляем искры из пула
    sparkPool.spawnSparks(worldContact);
    totalDamage += impulse * 2.5;

    // Триггер вспышки и заморозки (Hit-Stop) при сильном ударе
    if (impulse > 10.0) {
      screenFlash.trigger();
      _hitStopTimer = (impulse * 0.015).clamp(0.05, 0.15); // от 50мс до 150мс
    }
  }

  // Сбор монеты
  void collectCoin() {
    coinsCollected++;
    _updateStats();
    GameAudioManager().playSfx('coin.wav');
  }

  // Подбор топлива
  void collectFuel(double percent) {
    lander.fuel = (lander.fuel + lander.maxFuel * percent).clamp(0.0, lander.maxFuel);
    GameAudioManager().playSfx('dock.wav');
  }

  // Подбор ремонта
  void collectShield(double percent) {
    lander.shield = (lander.shield + lander.maxShield * percent).clamp(0.0, lander.maxShield);
    GameAudioManager().playSfx('dock.wav');
  }

  void _updateStats() {
    String alertText = '';
    double gForceVal = 1.0;
    double pitchAngleVal = 0.0;
    double proxDistance = 99.0;
    bool isProxAlert = false;
    String radioMessage = '';

    if (lander.isMounted) {
      gForceVal = lander.gForce;
      pitchAngleVal = lander.body.angle;
      if (cave.isMounted) {
        final pos = lander.body.position;
        final floorY = cave.getFloorY(pos.x);
        final ceilY = cave.getCeilingY(pos.x);
        final distFloor = (floorY - pos.y).abs();
        final distCeil = (ceilY - pos.y).abs();
        proxDistance = min(distFloor, distCeil);
        final speed = lander.body.linearVelocity.length;
        if (proxDistance < 3.0 && speed > 3.5) {
          isProxAlert = true;
        }
      }

      final state = GameState();
      final isRu = state.language == 'ru';
      final fuelPct = lander.maxFuel > 0 ? lander.fuel / lander.maxFuel : 1.0;

      if (isProxAlert) {
        radioMessage = isRu ? 'ТРЕВОГА: Опасное сближение со скалой!' : 'ALERT: Terrain proximity warning!';
      } else if (fuelPct < 0.20 && lander.fuel > 0) {
        radioMessage = isRu ? 'ВНИМАНИЕ: Критический остаток топлива (< 20%)!' : 'WARNING: Fuel reserves critical (< 20%)!';
      } else if (rope != null) {
        final exitDist = cargoCapsule.isMounted ? cargoCapsule.body.position.distanceTo(cave.exitPlatform) : 99.0;
        if (exitDist < 12.0) {
          radioMessage = isRu ? 'База: Выходной шлюз на прицеле, погасите скорость!' : 'Base: Extraction bay in sight, slow down!';
        } else {
          radioMessage = isRu ? 'Пилот: Груз зафиксирован, начинаю транспортировку.' : 'Pilot: Cargo secured on tether, proceeding to exit.';
        }
      } else if (flightTime < 4.0) {
        radioMessage = isRu ? 'База: Старт разрешен, контролируйте вектор тяги.' : 'Base: Clearance granted, monitor thrust vector.';
      }
    }

    if (_customAlert != null) {
      alertText = _customAlert!;
    } else if (rope == null && lander.isMounted && cargoCapsule.isMounted && lander.body.position.distanceTo(cargoCapsule.body.position) < 8.0) {
      alertText = GameState().translate('cargo_nearby');
    } else if (rope != null && cargoCapsule.isMounted) {
      final exitDistance = cargoCapsule.body.position.distanceTo(cave.exitPlatform);
      if (exitDistance < 12.0) {
        alertText = GameState().translate('exit_gate_alert');
      } else {
        alertText = GameState().translate('docked_alert');
      }
    }

    statsNotifier.value = {
      'coins': coinsCollected,
      'distance': maxDistance,
      'alert': alertText,
      'fuel': lander.isMounted ? lander.fuel : 1.0,
      'maxFuel': lander.isMounted ? lander.maxFuel : 1.0,
      'shield': lander.isMounted ? lander.shield : 1.0,
      'maxShield': lander.isMounted ? lander.maxShield : 1.0,
      'hasRope': rope != null,
      'gForce': gForceVal,
      'pitchAngle': pitchAngleVal,
      'proximityDistance': proxDistance,
      'isProximityAlert': isProxAlert,
      'radioChatterMessage': radioMessage,
    };
  }

  @override
  void update(double dt) {
    if (_hitStopTimer > 0) {
      _hitStopTimer -= dt;
      // Вспышка экрана должна продолжать обновляться во время паузы
      if (screenFlash.isMounted) {
        screenFlash.update(dt);
      }
      return;
    }

    // Внедрение Physics Accumulator для стабильной симуляции Forge2D
    _accumulator += dt;
    while (_accumulator >= _fixedTimeStep) {
      super.update(_fixedTimeStep);
      _accumulator -= _fixedTimeStep;
      
      _tickPhysicsGameLogic(_fixedTimeStep);
    }
  }

  void _tickPhysicsGameLogic(double fixedDt) {
    if (!isLoaded || 
        !lander.isMounted || 
        !cargoCapsule.isMounted || 
        !cave.isMounted || 
        runStateNotifier.value != GameRunState.playing) {
      return;
    }

    if (_customAlertTimer > 0) {
      _customAlertTimer -= fixedDt;
      if (_customAlertTimer <= 0) {
        _customAlert = null;
      }
    }

    // Симуляция ветра на карте ветров (динамический снос влево с турбулентностью)
    if (mapId == 'wind') {
      final double windFactor = -4.0 + 1.2 * sin(flightTime * 1.8) + 0.6 * sin(flightTime * 3.5);
      final windForce = Vector2(windFactor * lander.body.mass, 0);
      lander.body.applyForce(windForce);
    }

    // Трекинг полетного времени и дистанции
    flightTime += fixedDt;
    final currentDist = (lander.body.position.x - cave.startPlatform.x).clamp(0.0, 1000.0);
    if (currentDist > maxDistance) {
      maxDistance = currentDist;
    }

    _updateStats();

    // Физическое следование камеры за Лендером с учетом тряски экрана
    if (_shakeTimer > 0) {
      _shakeTimer -= fixedDt;
      final dx = (_random.nextDouble() - 0.5) * _shakeIntensity;
      final dy = (_random.nextDouble() - 0.5) * _shakeIntensity;
      camera.viewfinder.position = lander.body.position + Vector2(dx, dy);
    } else {
      camera.viewfinder.position = lander.body.position;
    }

    // Автоматический зацеп капсулы тросом при сближении
    if (rope == null) {
      final landerHook = lander.body.worldPoint(Vector2(0, 0.8));
      final cargoHook = cargoCapsule.body.worldPoint(Vector2(0, -0.9));
      
      final distance = landerHook.distanceTo(cargoHook);
      if (distance <= GameConfig.dockingRange) {
        _dockCargo();
      }
    }

    // Проверка поражения
    if (lander.shield <= 0) {
      _finishGame(GameRunState.lost);
    } else if (lander.fuel <= 0 && lander.body.linearVelocity.length2 < 0.05) {
      _finishGame(GameRunState.lost);
    }

    // Проверка победы (груз доставлен к выходному шлюзу с проверкой угла крена)
    if (rope != null && mapId != 'endless') {
      final exitDistance = cargoCapsule.body.position.distanceTo(cave.exitPlatform);
      if (exitDistance < 4.0 && lander.body.linearVelocity.length2 < 0.6) {
        final angle = lander.body.angle.abs() % (2 * pi);
        final normalizedAngle = angle > pi ? 2 * pi - angle : angle;
        
        if (normalizedAngle < 0.21) {
          _finishGame(GameRunState.won);
        } else {
          statsNotifier.value = {
            ...statsNotifier.value,
            'alert': GameState().translate('align_landing_alert'),
          };
        }
      }
    }
  }

  void _dockCargo() {
    if (rope != null) return;
    
    // Создаем трос на гибкой сцепке
    rope = Rope(lander: lander, capsule: cargoCapsule);
    world.add(rope!);
    _updateStats();

    // Звук успешной стыковки
    GameAudioManager().playSfx('dock.wav');
  }

  void snapRope() {
    if (rope == null) return;
    
    // Звук лопнувшего троса
    GameAudioManager().playSfx('collision.wav');
    
    // Спавним искры на месте разрыва (посередине между кораблем и капсулой)
    final startPoint = lander.body.worldPoint(Vector2(0, 0.8));
    final endPoint = cargoCapsule.body.worldPoint(Vector2(0, -0.9));
    final midPoint = (startPoint + endPoint) / 2;
    sparkPool.spawnSparks(midPoint);
    
    rope!.removeFromParent();
    rope = null;
    
    // Тряска экрана от разрыва
    shakeCamera(0.8, 0.4);
    
    // Уведомление об обрыве
    triggerCustomAlert(GameState().translate('rope_snapped'), 4.0);
  }

  void releaseCargo() {
    if (rope == null) return;
    
    // Звук сброса
    GameAudioManager().playSfx('dock.wav');
    
    rope!.removeFromParent();
    rope = null;
    
    // Уведомление о сбросе
    triggerCustomAlert(GameState().translate('cargo_released'), 2.5);
  }

  // Завершение миссии: расчет начисления монет и сохранение рекордов
  void _finishGame(GameRunState endState) {
    runStateNotifier.value = endState;
    setLeftThrust(false);
    setRightThrust(false);
    GameAudioManager().stopThrustLoop();

    if (endState == GameRunState.lost) {
      sparkPool.spawnExplosion(lander.body.position);
      lander.exploded = true;
      if (rope != null) {
        rope!.removeFromParent();
        rope = null;
      }
      lander.body.linearVelocity.setZero();
      lander.body.angularVelocity = 0.0;
      lander.body.setActive(false);
      shakeCamera(1.5, 0.8);
    }

    final state = GameState();
    
    // Монеты заезда: 10 монет за каждую собранную + бонус за успешную эвакуацию (100 монет)
    int rewardCoins = coinsCollected * 10;
    if (endState == GameRunState.won) {
      rewardCoins += 100;
      GameAudioManager().playSfx('victory.wav');

      // Проверка и начисление достижений
      final double fuelPercent = lander.fuel / lander.maxFuel;
      AchievementsManager().checkMissionCompletionStats(
        prefs: state.prefs,
        damageTaken: totalDamage,
        fuelPercentRemaining: fuelPercent,
        missionSeconds: flightTime,
        coinsCollected: coinsCollected,
        isSuccess: true,
      );
    } else {
      GameAudioManager().playSfx('defeat.wav');
    }
    
    if (mapId == 'endless' && endlessManager != null) {
      rewardCoins += endlessManager!.rescuesCount * 100;
    }

    state.addCoins(rewardCoins);
    state.addRecord(maxDistance, coinsCollected, mapId);
  }

  // Методы для UI
  void setLeftThrust(bool active) {
    if (runStateNotifier.value != GameRunState.playing) {
      lander.leftThrustActive = false;
      return;
    }
    lander.leftThrustActive = active;
  }

  void setRightThrust(bool active) {
    if (runStateNotifier.value != GameRunState.playing) {
      lander.rightThrustActive = false;
      return;
    }
    lander.rightThrustActive = active;
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final result = super.onKeyEvent(event, keysPressed);
    if (result == KeyEventResult.handled) {
      return KeyEventResult.handled;
    }

    if (runStateNotifier.value != GameRunState.playing) {
      setLeftThrust(false);
      setRightThrust(false);
      return KeyEventResult.ignored;
    }

    final isKeyDown = event is KeyDownEvent || event is KeyRepeatEvent;
    
    if (event.logicalKey == LogicalKeyboardKey.keyA || event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      setLeftThrust(isKeyDown);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyD || event.logicalKey == LogicalKeyboardKey.arrowRight) {
      setRightThrust(isKeyDown);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyW ||
        event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.space) {
      setLeftThrust(isKeyDown);
      setRightThrust(isKeyDown);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyS || event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (isKeyDown && rope != null) {
        releaseCargo();
        return KeyEventResult.handled;
      } else if (mapId == 'orbit' && isKeyDown && rope == null) {
        // Zero-G reverse RCS counter-braking
        final vel = lander.body.linearVelocity;
        if (vel.length > 0.05) {
          lander.body.applyLinearImpulse(-vel.normalized() * 0.15 * lander.body.mass);
        }
        return KeyEventResult.handled;
      }
    }
    
    return KeyEventResult.ignored;
  }
}
