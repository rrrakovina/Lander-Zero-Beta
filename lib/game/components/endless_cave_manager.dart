import 'dart:math';
import 'package:flame/components.dart';
import '../state/game_state.dart';
import '../lander_zero_game.dart';
import 'cargo_capsule.dart';
import 'coin.dart';
import 'fuel_pickup.dart';
import 'repair_pickup.dart';
import 'geyser.dart';
import 'stalactite.dart';
import 'magma_bubble.dart';

enum EndlessChunkType {
  startPad,
  rescueZone,
  hazardTransit,
  outpostStation,
}

class EndlessChunk {
  final int index;
  final EndlessChunkType type;
  final double startX;
  final double endX;
  final Vector2? platformPos;
  final bool isOutpost;
  final bool hasSurvivor;

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

/// Procedural Endless Cave Manager for infinite space rescue operations.
class EndlessCaveManager extends Component with HasGameReference<LanderZeroGame> {
  final List<EndlessChunk> _chunks = [];
  int _nextChunkIndex = 0;
  double _lastGeneratedX = -40.0;
  final double _chunkLength = 45.0;

  int rescuesCount = 0;
  int get endlessScore => (game.maxDistance * 10).toInt() + (rescuesCount * 1000);

  final Random _rand = Random(4242);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Generate initial 4 chunks
    for (int i = 0; i < 4; i++) {
      _generateNextChunk();
    }
  }

  void _generateNextChunk() {
    final startX = _lastGeneratedX;
    final endX = startX + _chunkLength;
    final index = _nextChunkIndex++;

    EndlessChunkType type;
    Vector2? platformPos;
    bool isOutpost = false;
    bool hasSurvivor = false;

    if (index == 0) {
      type = EndlessChunkType.startPad;
      platformPos = Vector2(startX + 10.0, game.cave.getFloorY(startX + 10.0));
    } else if (index % 3 == 1) {
      type = EndlessChunkType.rescueZone;
      hasSurvivor = true;
      final platX = startX + _chunkLength * 0.5;
      platformPos = Vector2(platX, game.cave.getFloorY(platX));
      // Spawn Cargo Capsule on platform
      game.world.add(CargoCapsule(initialPosition: Vector2(platX, platformPos.y - 0.9)));
    } else if (index % 3 == 2) {
      type = EndlessChunkType.hazardTransit;
      _spawnHazardsInChunk(startX, endX, index);
    } else {
      type = EndlessChunkType.outpostStation;
      isOutpost = true;
      final platX = startX + _chunkLength * 0.5;
      platformPos = Vector2(platX, game.cave.getFloorY(platX));
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

      game.world.add(Coin(position: Vector2(x, midY)));

      if (_rand.nextDouble() < 0.20) {
        final pickupY = floorY - 1.0 - _rand.nextDouble() * 2.0;
        if (_rand.nextBool()) {
          game.world.add(FuelPickup(position: Vector2(x, pickupY)));
        } else {
          game.world.add(RepairPickup(position: Vector2(x, pickupY)));
        }
      }
    }
  }

  void _spawnHazardsInChunk(double startX, double endX, int chunkIdx) {
    final double midX = (startX + endX) / 2.0;

    // Spawn falling stalactites
    final s1x = startX + 12.0;
    final s2x = startX + 28.0;
    game.world.add(Stalactite(initialPosition: Vector2(s1x, game.cave.getCeilingY(s1x) + 0.8)));
    game.world.add(Stalactite(initialPosition: Vector2(s2x, game.cave.getCeilingY(s2x) + 0.8)));

    // Spawn geyser
    game.world.add(Geyser(position: Vector2(midX, game.cave.getFloorY(midX))));

    // Spawn magma bubbles in deeper chunks
    if (chunkIdx > 3) {
      game.world.add(MagmaBubble(minX: startX + 5.0, maxX: endX - 5.0));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isLoaded || !game.lander.isMounted) return;

    final landerX = game.lander.body.position.x;

    // Generate new chunks ahead
    if (landerX + 80.0 > _lastGeneratedX) {
      _generateNextChunk();
    }

    // Check outpost rescue delivery in endless mode
    if (game.rope != null && game.cargoCapsule.isMounted) {
      for (final chunk in _chunks) {
        if (chunk.isOutpost && chunk.platformPos != null) {
          final dist = game.cargoCapsule.body.position.distanceTo(chunk.platformPos!);
          if (dist < 8.0) {
            _deliverSurvivorAtOutpost(chunk);
            break;
          }
        }
      }
    }
  }

  void _deliverSurvivorAtOutpost(EndlessChunk outpost) {
    rescuesCount++;
    game.coinsCollected += 100;
    game.totalDamage = 0; // reset run damage penalty

    // Refuel & repair lander at outpost
    game.lander.fuel = game.lander.maxFuel;
    game.lander.shield = game.lander.maxShield;

    game.triggerCustomAlert(
      GameState().language == 'ru'
          ? 'ВЫЖИВШИЙ СПАСЕН! +1000 ОЧКОВ // ПОЛНАЯ ДОЗАПРАВКА'
          : 'SURVIVOR RESCUED! +1000 PTS // FULL REFUEL & REPAIR',
      3.0,
    );

    // Release rope and remove delivered capsule
    game.world.remove(game.cargoCapsule);
    if (game.rope != null) {
      game.world.remove(game.rope!);
      game.rope = null;
    }
  }
}
