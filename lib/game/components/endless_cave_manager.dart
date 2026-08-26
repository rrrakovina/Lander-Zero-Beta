import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../audio/game_audio_manager.dart';
import '../lander_zero_game.dart';
import '../state/game_state.dart';
import 'cargo_capsule.dart';
import 'coin.dart';
import 'fuel_pickup.dart';
import 'repair_pickup.dart';
import 'geyser.dart';
import 'stalactite.dart';
import 'magma_bubble.dart';
import 'rotating_debris.dart';
import 'endless_cargo_data.dart';

enum EndlessChunkType {
  startPad,
  rescueZone,
  hazardTransit,
  outpostStation,
  branchChasm,
  verticalShaft,
}

class EndlessChunk {
  final int index;
  final EndlessChunkType type;
  final double startX;
  final double endX;
  final Vector2? platformPos;
  final bool isOutpost;
  final bool hasSurvivor;
  final List<Component> spawnedComponents = [];

  EndlessChunk({
    required this.index,
    required this.type,
    required this.startX,
    required this.endX,
    this.platformPos,
    this.isOutpost = false,
    this.hasSurvivor = false,
  });
}

/// Outpost visual beacon tower component with animated glowing runway lights.
class OutpostBeacon extends PositionComponent with HasGameReference<LanderZeroGame> {
  final Vector2 padPosition;
  double _time = 0.0;

  OutpostBeacon({required this.padPosition}) : super(position: padPosition, size: Vector2(8.0, 3.0), anchor: Anchor.bottomCenter);

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Outpost Foundation Plinth
    final plinthPaint = Paint()..color = const Color(0xFF212529);
    final plinthBorder = Paint()..color = const Color(0xFF00E5FF)..style = PaintingStyle.stroke..strokeWidth = 0.08;
    final rect = Rect.fromCenter(center: const Offset(0, -0.2), width: 6.5, height: 0.5);
    canvas.drawRect(rect, plinthPaint);
    canvas.drawRect(rect, plinthBorder);

    // Hazard Stripes on Station Platform
    final stripePaint = Paint()..color = const Color(0xFFFFB300)..style = PaintingStyle.stroke..strokeWidth = 0.08;
    canvas.drawLine(const Offset(-2.8, -0.4), const Offset(-2.2, 0.0), stripePaint);
    canvas.drawLine(const Offset(-1.4, -0.4), const Offset(-0.8, 0.0), stripePaint);
    canvas.drawLine(const Offset(0.0, -0.4), const Offset(0.6, 0.0), stripePaint);
    canvas.drawLine(const Offset(1.4, -0.4), const Offset(2.0, 0.0), stripePaint);

    // Left and Right Illuminated Beacon Towers
    final pulse = (sin(_time * 4.0) + 1.0) / 2.0;
    final lightColor = Color.lerp(const Color(0xFF00E5FF), Colors.white, pulse)!;
    final beaconGlow = Paint()
      ..color = lightColor.withOpacity(0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.3);
    final beaconCore = Paint()..color = lightColor;

    // Left tower light
    canvas.drawCircle(const Offset(-3.2, -1.2), 0.35, beaconGlow);
    canvas.drawCircle(const Offset(-3.2, -1.2), 0.16, beaconCore);
    canvas.drawLine(const Offset(-3.2, 0.0), const Offset(-3.2, -1.2), Paint()..color = const Color(0xFF90A4AE)..strokeWidth = 0.08);

    // Right tower light
    canvas.drawCircle(const Offset(3.2, -1.2), 0.35, beaconGlow);
    canvas.drawCircle(const Offset(3.2, -1.2), 0.16, beaconCore);
    canvas.drawLine(const Offset(3.2, 0.0), const Offset(3.2, -1.2), Paint()..color = const Color(0xFF90A4AE)..strokeWidth = 0.08);
  }
}

/// Procedural Endless Cave Manager for infinite space rescue operations.
class EndlessCaveManager extends Component with HasGameReference<LanderZeroGame> {
  final List<EndlessChunk> _chunks = [];
  int _nextChunkIndex = 0;
  double _lastGeneratedX = -40.0;
  final double _chunkLength = 48.0;

  int rescuesCount = 0;
  int _bonusScore = 0;

  int get endlessScore => (game.maxDistance * 10).toInt() + _bonusScore + (rescuesCount * 1000);

  EndlessCargoInfo? activeCargoInfo;
  Vector2? nextOutpostPos;
  Vector2? nextRescuePos;

  final Random _rand = Random(4242);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Generate initial 4 chunks ahead of player
    for (int i = 0; i < 4; i++) {
      _generateNextChunk();
    }
  }

  String getCurrentBiomeName(String lang) {
    final double dist = game.maxDistance;
    final int biomeCycle = ((dist / 400.0).floor()) % 4;
    final isRu = lang == 'ru';

    switch (biomeCycle) {
      case 0:
        return isRu ? 'Сектор 1: Заброшенные Шахты' : 'Sector 1: Abandoned Mines';
      case 1:
        return isRu ? 'Сектор 2: Кристаллический Грот' : 'Sector 2: Crystal Grotto';
      case 2:
        return isRu ? 'Сектор 3: Вулканический Разлом' : 'Sector 3: Volcanic Fissure';
      case 3:
      default:
        return isRu ? 'Сектор 4: Древний Реактор' : 'Sector 4: Ancient Reactor';
    }
  }

  void _generateNextChunk() {
    final startX = _lastGeneratedX;
    final endX = startX + _chunkLength;
    final index = _nextChunkIndex++;
    final double distanceMeters = max(0.0, startX);

    EndlessChunkType type;
    Vector2? platformPos;
    bool isOutpost = false;
    bool hasSurvivor = false;

    if (index == 0) {
      type = EndlessChunkType.startPad;
      platformPos = Vector2(startX + 12.0, game.cave.getFloorY(startX + 12.0));
    } else if (index % 4 == 1) {
      type = EndlessChunkType.rescueZone;
      hasSurvivor = true;
      final platX = startX + _chunkLength * 0.5;
      final floorY = game.cave.getFloorY(platX);
      platformPos = Vector2(platX, floorY);

      // Generate bespoke procedural cargo capsule with rarity and modifiers
      final cargoInfo = EndlessCargoGenerator.generate(
        distanceMeters: distanceMeters,
        random: _rand,
        chunkIndex: index,
      );

      final capsule = CargoCapsule(
        initialPosition: Vector2(platX, platformPos.y - 0.95),
        type: cargoInfo.archetype,
        endlessInfo: cargoInfo,
      );
      game.world.add(capsule);

      nextRescuePos = platformPos;
    } else if (index % 4 == 2) {
      type = EndlessChunkType.hazardTransit;
      _spawnHazardsInChunk(startX, endX, index);
    } else {
      type = EndlessChunkType.outpostStation;
      isOutpost = true;
      final platX = startX + _chunkLength * 0.5;
      final floorY = game.cave.getFloorY(platX);
      platformPos = Vector2(platX, floorY);

      // Add visual beacon tower at outpost
      final beacon = OutpostBeacon(padPosition: platformPos);
      game.world.add(beacon);

      nextOutpostPos = platformPos;
    }

    // Spawn pickups along chunk
    _spawnPickupsInChunk(startX, endX);

    final chunk = EndlessChunk(
      index: index,
      type: type,
      startX: startX,
      endX: endX,
      platformPos: platformPos,
      isOutpost: isOutpost,
      hasSurvivor: hasSurvivor,
    );

    _chunks.add(chunk);
    _lastGeneratedX = endX;
  }

  void _spawnPickupsInChunk(double startX, double endX) {
    for (double x = startX + 4.0; x < endX - 4.0; x += 4.5) {
      final floorY = game.cave.getFloorY(x);
      final ceilY = game.cave.getCeilingY(x);
      final midY = (floorY + ceilY) / 2.0 + (_rand.nextDouble() - 0.5) * 1.5;

      final coin = Coin(position: Vector2(x, midY));
      game.world.add(coin);

      if (_rand.nextDouble() < 0.22) {
        final pickupY = floorY - 1.0 - _rand.nextDouble() * 2.0;
        if (_rand.nextBool()) {
          final fuel = FuelPickup(position: Vector2(x, pickupY));
          game.world.add(fuel);
        } else {
          final repair = RepairPickup(position: Vector2(x, pickupY));
          game.world.add(repair);
        }
      }
    }
  }

  void _spawnHazardsInChunk(double startX, double endX, int chunkIdx) {
    final double midX = (startX + endX) / 2.0;

    // Spawn falling stalactites
    final s1x = startX + 12.0;
    final s2x = startX + 28.0;
    final stal1 = Stalactite(initialPosition: Vector2(s1x, game.cave.getCeilingY(s1x) + 0.8));
    final stal2 = Stalactite(initialPosition: Vector2(s2x, game.cave.getCeilingY(s2x) + 0.8));
    game.world.add(stal1);
    game.world.add(stal2);

    // Spawn thermal geyser
    final geyser = Geyser(position: Vector2(midX, game.cave.getFloorY(midX)));
    game.world.add(geyser);

    // Spawn magma bubbles in deeper chunks
    if (chunkIdx > 3) {
      final bubble = MagmaBubble(minX: startX + 5.0, maxX: endX - 5.0);
      game.world.add(bubble);
    }

    // Spawn rotating orbital debris in deep space reactor sectors
    if (chunkIdx > 6 && _rand.nextBool()) {
      final debris = RotatingDebris(initialPosition: Vector2(startX + 18.0, game.cave.getCeilingY(startX + 18.0) + 4.0));
      game.world.add(debris);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isLoaded || !game.lander.isMounted) return;

    final landerX = game.lander.body.position.x;

    // 1. Generate new chunks ahead
    if (landerX + 90.0 > _lastGeneratedX) {
      _generateNextChunk();
    }

    // 2. Track currently tethered cargo
    if (game.rope != null && game.cargoCapsule.isMounted) {
      activeCargoInfo = game.cargoCapsule.endlessInfo;
    } else {
      activeCargoInfo = null;
    }

    // 3. Check outpost rescue delivery in endless mode
    if (game.rope != null && game.cargoCapsule.isMounted) {
      for (final chunk in _chunks) {
        if (chunk.isOutpost && chunk.platformPos != null) {
          final capsuleDist = game.cargoCapsule.body.position.distanceTo(chunk.platformPos!);
          final landerDist = game.lander.body.position.distanceTo(chunk.platformPos!);

          if (capsuleDist < 7.5 || landerDist < 4.5) {
            _deliverSurvivorAtOutpost(chunk);
            break;
          }
        }
      }
    }

    // 4. Memory Cleanup: Despawn old chunks 75m behind player for 60 FPS
    _cleanupPassedChunks(landerX);
  }

  void _deliverSurvivorAtOutpost(EndlessChunk outpost) {
    final info = game.cargoCapsule.endlessInfo;
    final int scoreAward = info?.totalScore ?? 1000;
    final int coinsAward = info?.totalCoins ?? 100;

    rescuesCount++;
    _bonusScore += scoreAward;
    game.coinsCollected += coinsAward;
    game.totalDamage = 0; // reset run damage penalty

    // Full Refuel & Repair lander at outpost
    game.lander.fuel = game.lander.maxFuel;
    game.lander.shield = game.lander.maxShield;

    // Play goal sound
    GameAudioManager().playSfx('victory.wav');

    final isRu = GameState().language == 'ru';
    final cargoName = info != null ? info.getTitle(GameState().language) : (isRu ? 'ВЫЖИВШИЙ' : 'SURVIVOR');
    game.triggerCustomAlert(
      isRu
          ? 'ГРУЗ $cargoName ЭВАКУИРОВАН! +$scoreAward ОЧКОВ // ПОЛНАЯ ДОЗАПРАВКА'
          : 'CARGO $cargoName DELIVERED! +$scoreAward PTS // FULL REFUEL',
      3.5,
    );

    // Release rope and remove delivered capsule
    game.world.remove(game.cargoCapsule);
    if (game.rope != null) {
      game.world.remove(game.rope!);
      game.rope = null;
    }
  }

  void _cleanupPassedChunks(double landerX) {
    _chunks.removeWhere((chunk) {
      if (landerX - chunk.endX > 80.0) {
        for (final comp in chunk.spawnedComponents) {
          if (comp.isMounted) {
            comp.removeFromParent();
          }
        }
        return true;
      }
      return false;
    });
  }
}