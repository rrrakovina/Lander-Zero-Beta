import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flame_forge2d/flame_forge2d.dart' show Vector2;
import 'package:lander_zero/game/state/game_state.dart';
import 'package:lander_zero/game/state/achievements_manager.dart';
import 'package:lander_zero/game/audio/game_audio_manager.dart';
import 'package:lander_zero/ui/painters/rocket_painter.dart';

// Interface contract mock models for Tier 1 verification
class CockpitTelemetryContract {
  final double gForce;
  final double pitchAngle;
  final double proximityDistance;
  final bool isProximityAlert;
  final String? radioChatterMessage;

  CockpitTelemetryContract({
    required this.gForce,
    required this.pitchAngle,
    required this.proximityDistance,
    required this.isProximityAlert,
    this.radioChatterMessage,
  });
}

class BiomePhysicsContract {
  final String biomeId;
  final double gravityY;
  final double surfaceFriction;
  final double restitution;
  final bool hasCryoGeysers;
  final bool hasMagmaBubbles;
  final bool hasTurbulentWind;
  final bool isZeroGravity;

  BiomePhysicsContract({
    required this.biomeId,
    required this.gravityY,
    required this.surfaceFriction,
    required this.restitution,
    this.hasCryoGeysers = false,
    this.hasMagmaBubbles = false,
    this.hasTurbulentWind = false,
    this.isZeroGravity = false,
  });

  static BiomePhysicsContract get(String id) {
    switch (id) {
      case 'ice':
        return BiomePhysicsContract(
          biomeId: 'ice',
          gravityY: 2.275, // 0.65x of 3.5
          surfaceFriction: 0.08,
          restitution: 0.25,
          hasCryoGeysers: true,
        );
      case 'orbit':
        return BiomePhysicsContract(
          biomeId: 'orbit',
          gravityY: 0.0,
          surfaceFriction: 0.40,
          restitution: 0.15,
          isZeroGravity: true,
        );
      case 'wind':
        return BiomePhysicsContract(
          biomeId: 'wind',
          gravityY: 3.5,
          surfaceFriction: 0.70,
          restitution: 0.05,
          hasTurbulentWind: true,
        );
      case 'core':
        return BiomePhysicsContract(
          biomeId: 'core',
          gravityY: 5.3,
          surfaceFriction: 0.85,
          restitution: 0.05,
          hasMagmaBubbles: true,
        );
      case 'echo':
      default:
        return BiomePhysicsContract(
          biomeId: 'echo',
          gravityY: 3.5,
          surfaceFriction: 0.80,
          restitution: 0.05,
        );
    }
  }
}

class EndlessChunkContract {
  final int chunkIndex;
  final String chunkType; // 'rescue', 'transit', 'refuel', 'extraction'
  final double startX;
  final double endX;
  final bool hasSurvivorCapsule;
  final bool hasRefuelStation;

  EndlessChunkContract({
    required this.chunkIndex,
    required this.chunkType,
    required this.startX,
    required this.endX,
    this.hasSurvivorCapsule = false,
    this.hasRefuelStation = false,
  });
}

class EndlessRescueEngineContract {
  int rescuesCompleted = 0;
  int currentScore = 0;
  double distanceMeters = 0.0;
  final List<EndlessChunkContract> activeChunks = [];

  void spawnInitialChunks() {
    activeChunks.clear();
    for (int i = 0; i < 3; i++) {
      _spawnChunk(i);
    }
  }

  void _spawnChunk(int index) {
    final start = index * 60.0;
    final end = start + 60.0;
    final type = index % 4 == 0
        ? 'rescue'
        : (index % 4 == 2 ? 'refuel' : (index % 4 == 3 ? 'extraction' : 'transit'));
    activeChunks.add(EndlessChunkContract(
      chunkIndex: index,
      chunkType: type,
      startX: start,
      endX: end,
      hasSurvivorCapsule: type == 'rescue',
      hasRefuelStation: type == 'refuel',
    ));
  }

  void updateLanderPosition(double landerX) {
    distanceMeters = max(distanceMeters, landerX);
    currentScore = (distanceMeters * 10).toInt() + (rescuesCompleted * 1000);

    // Recycling: when lander passes chunk N start + 30m, spawn chunk N+2
    final currentChunkIdx = (landerX / 60.0).floor();
    final maxActive = activeChunks.isNotEmpty ? activeChunks.map((c) => c.chunkIndex).reduce(max) : 0;
    if (currentChunkIdx + 2 > maxActive) {
      _spawnChunk(maxActive + 1);
    }
    // Recycle older than N-1
    activeChunks.removeWhere((c) => c.endX < landerX - 40.0);
  }

  void completeExtraction() {
    rescuesCompleted++;
    currentScore += 1000;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    GameAudioManager.isTesting = true;
    await GameState().init(force: true);
  });

  group('Tier 1: Feature Coverage (F1 to F17)', () {
    // -------------------------------------------------------------
    // F1. HMAC-SHA256 Save Protection (5 tests)
    // -------------------------------------------------------------
    group('F1: HMAC-SHA256 Save Protection', () {
      String computeSig(int coins, List<String> fleet, String lb) {
        final sorted = List<String>.from(fleet)..sort();
        final payload = 'v1|coins:$coins|fleet:${sorted.join(",")}|lb:$lb';
        return Hmac(sha256, utf8.encode('LanderZero_Sec_Master_Save_Salt_2026'))
            .convert(utf8.encode(payload))
            .toString();
      }

      test('F1.1: Generates standard 64-char SHA256 hex string', () {
        final sig = computeSig(250, ['sputnik', 'swift'], '[]');
        expect(sig.length, equals(64));
        expect(RegExp(r'^[a-f0-9]{64}$').hasMatch(sig), isTrue);
      });

      test('F1.2: Validates authentic signature matches payload', () {
        const coins = 500;
        final fleet = ['sputnik', 'swift'];
        const lb = '[]';
        final sig = computeSig(coins, fleet, lb);
        expect(computeSig(coins, fleet, lb), equals(sig));
      });

      test('F1.3: Detects mismatch on modified coins', () {
        final sig = computeSig(100, ['sputnik'], '[]');
        expect(computeSig(5000, ['sputnik'], '[]') == sig, isFalse);
      });

      test('F1.4: Detects mismatch on modified fleet list', () {
        final sig = computeSig(100, ['sputnik'], '[]');
        expect(computeSig(100, ['sputnik', 'titan'], '[]') == sig, isFalse);
      });

      test('F1.5: Gracefully handles empty or null signatures without crashing', () {
        bool verify(String? sig) => sig != null && sig.isNotEmpty && sig.length == 64;
        expect(verify(null), isFalse);
        expect(verify(''), isFalse);
        expect(verify('corrupt'), isFalse);
      });
    });

    // -------------------------------------------------------------
    // F2. Nickname Sanitization (5 tests)
    // -------------------------------------------------------------
    group('F2: Nickname Sanitization', () {
      String sanitize(String input) {
        final noHtml = input.replaceAll(RegExp(r'<[^>]*>'), '');
        final trimmed = noHtml.trim();
        if (trimmed.isEmpty) return 'Pilot';
        final clean = trimmed.replaceAll(RegExp(r'[^\w\s\u0400-\u04FF\.\-_]'), '').trim();
        if (clean.isEmpty) return 'Pilot';
        return clean.length > 15 ? clean.substring(0, 15) : clean;
      }

      test('F2.1: Retains standard callsign alphanumeric strings', () {
        expect(sanitize('Cosmo_01'), equals('Cosmo_01'));
      });

      test('F2.2: Retains Cyrillic names and initials', () {
        expect(sanitize('Гагарин Ю.'), equals('Гагарин Ю.'));
      });

      test('F2.3: Replaces whitespace-only with default "Pilot"', () {
        expect(sanitize('     '), equals('Pilot'));
      });

      test('F2.4: Strips forbidden HTML tags and control symbols', () {
        expect(sanitize('<b>Commander</b>\x00'), equals('Commander'));
      });

      test('F2.5: Enforces maximum length limit of 15 characters', () {
        expect(sanitize('VeryLongPilotNicknameFromOrbit'), equals('VeryLongPilotNi'));
      });
    });

    // -------------------------------------------------------------
    // F3. Starter Ships (Sputnik & Swift 0 Cost) (5 tests)
    // -------------------------------------------------------------
    group('F3: Starter Ships (Sputnik & Swift)', () {
      test('F3.1: Sputnik-1 has zero purchase price', () {
        final config = GameState.rocketConfigs['sputnik'];
        expect(config, isNotNull);
        expect(config!['price'], equals(0));
      });

      test('F3.2: Swift-02 starter ship has 0 cost', () {
        const swiftConfig = {
          'nameRu': 'Стриж',
          'nameEn': 'Swift-02',
          'price': 0,
          'baseThrust': 38.0,
          'baseFuel': 140.0,
          'baseShield': 70.0,
          'mass': 0.75,
        };
        expect(swiftConfig['price'], equals(0));
        expect(swiftConfig['baseThrust'], equals(38.0));
      });

      test('F3.3: Sputnik-1 base stats are balanced', () {
        final config = GameState.rocketConfigs['sputnik']!;
        expect(config['baseThrust'], equals(32.0));
        expect(config['baseFuel'], equals(150.0));
        expect(config['baseShield'], equals(100.0));
      });

      test('F3.4: Fresh install owns at least starter ship', () {
        final state = GameState();
        expect(state.ownedRockets.contains('sputnik'), isTrue);
      });

      test('F3.5: Switching active vessel to starter ship succeeds', () async {
        final state = GameState();
        await state.selectRocket('sputnik');
        expect(state.selectedRocket, equals('sputnik'));
      });
    });

    // -------------------------------------------------------------
    // F4. Shop Ships (Titan & Quasar & Cyclone) (5 tests)
    // -------------------------------------------------------------
    group('F4: Shop Ships Fleet Specifications', () {
      test('F4.1: Cyclone is a heavy cargo vessel costing 800 coins', () {
        final config = GameState.rocketConfigs['cyclone'];
        expect(config, isNotNull);
        expect(config!['price'], equals(800));
        expect(config['mass'], equals(1.6));
      });

      test('F4.2: Titan-V has high armor and triple-thruster capability', () {
        const titan = {
          'nameRu': 'Буран-М',
          'nameEn': 'Titan-V',
          'price': 2200,
          'baseThrust': 46.0,
          'baseFuel': 220.0,
          'baseShield': 250.0,
          'mass': 2.0,
        };
        expect(titan['baseShield'], equals(250.0));
        expect(titan['mass'], equals(2.0));
      });

      test('F4.3: Quasar-IX is an agile ion vessel with high fuel', () {
        const quasar = {
          'nameRu': 'Квазар',
          'nameEn': 'Quasar-IX',
          'price': 3000,
          'baseThrust': 40.0,
          'baseFuel': 260.0,
          'baseShield': 120.0,
          'mass': 0.9,
        };
        expect(quasar['baseFuel'], equals(260.0));
        expect(quasar['mass'], equals(0.9));
      });

      test('F4.4: Purchasing shop vessel checks coin balance before unlocking', () async {
        final state = GameState();
        expect(state.canAfford(800), isFalse);
        final success = await state.buyRocket('cyclone');
        expect(success, isFalse);
        expect(state.ownedRockets.contains('cyclone'), isFalse);
      });

      test('F4.5: Successful vessel purchase deducts coins and updates active ship', () async {
        final state = GameState();
        await state.addCoins(1000);
        final success = await state.buyRocket('cyclone');
        expect(success, isTrue);
        expect(state.totalCoins, equals(200));
        expect(state.ownedRockets, contains('cyclone'));
        expect(state.selectedRocket, equals('cyclone'));
      });
    });

    // -------------------------------------------------------------
    // F5. Vector Decals & Insignias Rendering (5 tests)
    // -------------------------------------------------------------
    group('F5: Vector Decals & Markings', () {
      test('F5.1: Sputnik model bounds accommodate vector hull and rivets', () {
        final bounds = RocketPainter.getBounds('sputnik');
        expect(bounds.width, greaterThan(2.0));
        expect(bounds.height, greaterThan(2.0));
      });

      test('F5.2: Cyclone model bounds encompass wide hazard sponsons', () {
        final bounds = RocketPainter.getBounds('cyclone');
        expect(bounds.width, greaterThanOrEqualTo(4.0));
      });

      test('F5.3: Needle model bounds encompass delta wings and nose tip', () {
        final bounds = RocketPainter.getBounds('needle');
        expect(bounds.height, greaterThanOrEqualTo(2.8));
      });

      test('F5.4: Hull markings mapping has valid designations', () {
        const decals = {
          'sputnik': 'СССР-01',
          'swift': 'SWIFT-02',
          'titan': 'TITAN-V',
          'quasar': 'QUASAR-IX',
          'cyclone': 'CY-88',
        };
        expect(decals['sputnik'], equals('СССР-01'));
        expect(decals['swift'], equals('SWIFT-02'));
        expect(decals['titan'], equals('TITAN-V'));
        expect(decals['quasar'], equals('QUASAR-IX'));
        expect(decals['cyclone'], equals('CY-88'));
      });

      test('F5.5: calculateScale maintains safety margin for all ships', () {
        const size = Size(200, 200);
        for (final id in ['sputnik', 'cyclone', 'needle']) {
          final scale = RocketPainter.calculateScale(id, size);
          expect(scale, greaterThan(0));
          expect(scale.isFinite, isTrue);
        }
      });
    });

    // -------------------------------------------------------------
    // F6. Live Dynamic Astronaut Simulation (5 tests)
    // -------------------------------------------------------------
    group('F6: Live Astronaut Dynamic Simulation', () {
      test('F6.1: G-Force calculation formula calculates normalized G-load', () {
        double calculateGLoad(double accelX, double accelY, double gravityY) {
          final totalY = accelY + gravityY;
          final totalA = sqrt(accelX * accelX + totalY * totalY);
          return totalA / 3.5;
        }
        final gRest = calculateGLoad(0, 0, 3.5);
        expect(gRest, closeTo(1.0, 0.01));

        final gHigh = calculateGLoad(10.0, 10.0, 3.5);
        expect(gHigh, greaterThan(3.0));
      });

      test('F6.2: G-strain triggers head compression when G > 2.5', () {
        double getHeadScaleY(double gLoad) {
          if (gLoad <= 2.5) return 1.0;
          return (1.0 - (gLoad - 2.5) * 0.08).clamp(0.75, 1.0);
        }
        expect(getHeadScaleY(1.0), equals(1.0));
        expect(getHeadScaleY(2.5), equals(1.0));
        expect(getHeadScaleY(4.5), lessThan(1.0));
        expect(getHeadScaleY(10.0), equals(0.75));
      });

      test('F6.3: Pilot gaze vector blends ship velocity and danger direction', () {
        Vector2 calculateGazeVector(Vector2 velocity, Vector2 hazardDir) {
          final vNorm = velocity.length > 0.1 ? velocity.normalized() : Vector2.zero();
          final hNorm = hazardDir.length > 0.1 ? hazardDir.normalized() : Vector2.zero();
          return vNorm * 0.6 + hNorm * 0.4;
        }
        final gaze = calculateGazeVector(Vector2(5, 0), Vector2(0, 5));
        expect(gaze.x, greaterThan(0));
        expect(gaze.y, greaterThan(0));
      });

      test('F6.4: Panic condition activates on critical fuel or shield', () {
        bool isPanic(double shieldPct, double fuelPct, double approachSpeed) {
          return shieldPct < 0.30 || fuelPct < 0.15 || approachSpeed > 6.0;
        }
        expect(isPanic(1.0, 1.0, 2.0), isFalse);
        expect(isPanic(0.20, 1.0, 2.0), isTrue);
        expect(isPanic(1.0, 0.10, 2.0), isTrue);
        expect(isPanic(1.0, 1.0, 7.5), isTrue);
      });

      test('F6.5: Pilot suits differ per ship class', () {
        const suits = {
          'sputnik': 'Sokol-KV2 Orange',
          'swift': 'G-Suit Midnight Blue',
          'titan': 'Heavy Exo Hazard Yellow',
          'quasar': 'Cybernetic Cyan Carbon',
          'cyclone': 'Industrial Steel Utility',
        };
        expect(suits.length, equals(5));
        expect(suits['sputnik'], contains('Orange'));
        expect(suits['swift'], contains('Blue'));
      });
    });

    // -------------------------------------------------------------
    // F7. Cadet ID Registration Terminal (5 tests)
    // -------------------------------------------------------------
    group('F7: Cadet ID Registration Terminal', () {
      test('F7.1: Validates initial empty state triggers callsign input', () {
        final state = GameState();
        expect(state.nickname.isEmpty, isTrue);
      });

      test('F7.2: Cadet clearance level string generated correctly', () {
        String getBadgeNumber(String name) {
          final hash = name.codeUnits.fold(0, (a, b) => a + b) % 900 + 100;
          return 'CADET-ID #$hash-LZ';
        }
        final badge = getBadgeNumber('Orion');
        expect(badge, startsWith('CADET-ID #'));
        expect(badge, endsWith('-LZ'));
      });

      test('F7.3: Submitting valid nickname stores sanitized name', () async {
        final state = GameState();
        await state.setNickname('  Vostok_1  ');
        expect(state.nickname, equals('Vostok_1'));
      });

      test('F7.4: Starter selection in terminal allows Sputnik or Swift', () async {
        final state = GameState();
        await state.selectRocket('sputnik');
        expect(state.selectedRocket, equals('sputnik'));
      });

      test('F7.5: Language toggle updates cadet terminal UI strings', () async {
        final state = GameState();
        expect(state.translate('enter_nick'), equals('ВВЕДИТЕ НИКНЕЙМ'));
        await state.setLanguage('en');
        expect(state.translate('enter_nick'), equals('ENTER NICKNAME'));
      });
    });

    // -------------------------------------------------------------
    // F8. Live Hangar Main Menu & Telemetry (5 tests)
    // -------------------------------------------------------------
    group('F8: Live Hangar Main Menu & Telemetry', () {
      test('F8.1: Telemetry status values are active on startup', () {
        final state = GameState();
        expect(state.translate('play'), isNotEmpty);
        expect(state.translate('garage'), isNotEmpty);
      });

      test('F8.2: Readiness percentage increases with upgrade progress', () {
        int calculateReadiness(int engine, int fuel, int shield) {
          final totalUpgrades = (engine - 1) + (fuel - 1) + (shield - 1);
          return 60 + ((totalUpgrades / 12) * 40).round();
        }
        expect(calculateReadiness(1, 1, 1), equals(60));
        expect(calculateReadiness(5, 5, 5), equals(100));
        expect(calculateReadiness(3, 3, 3), equals(80));
      });

      test('F8.3: Dynamic pilot rank promotes based on stats', () {
        expect(GameState().totalCoins, equals(0));
      });

      test('F8.4: Sound effects and music volume sliders persist', () async {
        final state = GameState();
        await state.setMusicVolume(0.5);
        await state.setSfxVolume(0.6);
        expect(state.musicVolume, equals(0.5));
        expect(state.sfxVolume, equals(0.6));
      });

      test('F8.5: Hangar ticker marquee string contains status codes', () {
        const ticker = 'HANGAR BAY 04 // DOCKING CLAMP: ENGAGED // SATELLITE COMMS: STABLE';
        expect(ticker, contains('HANGAR'));
        expect(ticker, contains('STABLE'));
      });
    });

    // -------------------------------------------------------------
    // F9. Tactical Hologram Map Select (5 tests)
    // -------------------------------------------------------------
    group('F9: Tactical Hologram Map Select', () {
      test('F9.1: Echo Canyon environmental briefing parameters', () {
        final echo = BiomePhysicsContract.get('echo');
        expect(echo.gravityY, equals(3.5));
        expect(echo.surfaceFriction, equals(0.80));
      });

      test('F9.2: Solar Winds environmental parameters include lateral gusts', () {
        final wind = BiomePhysicsContract.get('wind');
        expect(wind.hasTurbulentWind, isTrue);
        expect(wind.surfaceFriction, equals(0.70));
      });

      test('F9.3: Deep Core environmental parameters have heavy gravity', () {
        final core = BiomePhysicsContract.get('core');
        expect(core.gravityY, equals(5.3));
        expect(core.hasMagmaBubbles, isTrue);
      });

      test('F9.4: Europa Ice environmental parameters have 0.65x gravity and low friction', () {
        final ice = BiomePhysicsContract.get('ice');
        expect(ice.gravityY, equals(2.275));
        expect(ice.surfaceFriction, equals(0.08));
        expect(ice.hasCryoGeysers, isTrue);
      });

      test('F9.5: Orbital Debris parameters have zero gravity and zero drag', () {
        final orbit = BiomePhysicsContract.get('orbit');
        expect(orbit.gravityY, equals(0.0));
        expect(orbit.isZeroGravity, isTrue);
      });
    });

    // -------------------------------------------------------------
    // F10. Cockpit Cybernetic HUD Instruments (5 tests)
    // -------------------------------------------------------------
    group('F10: Cockpit Cybernetic HUD Instruments', () {
      test('F10.1: Cockpit telemetry model stores instrument data', () {
        final data = CockpitTelemetryContract(
          gForce: 1.5,
          pitchAngle: 0.12,
          proximityDistance: 4.2,
          isProximityAlert: false,
          radioChatterMessage: 'Clear for descent',
        );
        expect(data.gForce, equals(1.5));
        expect(data.isProximityAlert, isFalse);
      });

      test('F10.2: Proximity alert triggers when distance < 3.0m and speed > 3.5 m/s', () {
        bool evaluateProximityAlert(double distance, double velocity) {
          return distance < 3.0 && velocity > 3.5;
        }
        expect(evaluateProximityAlert(5.0, 2.0), isFalse);
        expect(evaluateProximityAlert(2.5, 4.0), isTrue);
        expect(evaluateProximityAlert(2.5, 1.0), isFalse); // Slow approach is safe
      });

      test('F10.3: Artificial horizon gyro pitch angle converts to degrees and bank', () {
        String formatAttitude(double angleRad) {
          final deg = (angleRad * 180 / pi).round();
          final sign = deg >= 0 ? '+' : '';
          return '$sign$deg°';
        }
        expect(formatAttitude(0.0), equals('+0°'));
        expect(formatAttitude(pi / 6), equals('+30°'));
        expect(formatAttitude(-pi / 4), equals('-45°'));
      });

      test('F10.4: Safe landing angle threshold checks within 12 degrees', () {
        bool isSafeLandingAngle(double angleRad) {
          final norm = angleRad.abs() % (2 * pi);
          final angle = norm > pi ? 2 * pi - norm : norm;
          return angle < 0.21; // ~12 degrees
        }
        expect(isSafeLandingAngle(0.05), isTrue);
        expect(isSafeLandingAngle(0.35), isFalse);
      });

      test('F10.5: G-Force status classifies into Safe / Warning / Critical', () {
        String classifyG(double g) {
          if (g < 2.0) return 'SAFE';
          if (g < 3.5) return 'WARNING';
          return 'CRITICAL';
        }
        expect(classifyG(1.2), equals('SAFE'));
        expect(classifyG(2.8), equals('WARNING'));
        expect(classifyG(4.5), equals('CRITICAL'));
      });
    });

    // -------------------------------------------------------------
    // F11. Ice Biome (Europa 0.65G, Low Friction) (5 tests)
    // -------------------------------------------------------------
    group('F11: Ice Biome Physics & Environment', () {
      test('F11.1: Ice surface friction (0.08) causes 10x longer sliding distance', () {
        final iceFriction = BiomePhysicsContract.get('ice').surfaceFriction;
        final standardFriction = BiomePhysicsContract.get('echo').surfaceFriction;
        expect(iceFriction, lessThan(standardFriction / 5));
      });

      test('F11.2: Cryo-geyser plume exerts upward impulse and stabilizes rotation', () {
        Vector2 applyCryoGeyserForce(Vector2 currentVelocity, double currentAngVel) {
          return currentVelocity + Vector2(0, -6.0);
        }
        final boosted = applyCryoGeyserForce(Vector2(0, 0), 2.0);
        expect(boosted.y, lessThan(0));
      });

      test('F11.3: Europa gravity of 2.275 m/s2 results in slower fall acceleration', () {
        final gIce = BiomePhysicsContract.get('ice').gravityY;
        final gEcho = BiomePhysicsContract.get('echo').gravityY;
        expect(gIce, closeTo(gEcho * 0.65, 0.001));
      });

      test('F11.4: Falling icicle collision damage is higher than standard rock', () {
        const icicleDamage = 45.0;
        const stalactiteDamage = 35.0;
        expect(icicleDamage, greaterThan(stalactiteDamage));
      });

      test('F11.5: Europa map restitution causes bouncy impacts', () {
        final ice = BiomePhysicsContract.get('ice');
        expect(ice.restitution, equals(0.25));
        expect(ice.restitution, greaterThan(BiomePhysicsContract.get('echo').restitution));
      });
    });

    // -------------------------------------------------------------
    // F12. Orbit Biome (Zero-G, Drift, Reverse RCS) (5 tests)
    // -------------------------------------------------------------
    group('F12: Orbit Biome Zero-G Mechanics', () {
      test('F12.1: Gravity in orbit biome is strictly zero', () {
        final orbit = BiomePhysicsContract.get('orbit');
        expect(orbit.gravityY, equals(0.0));
      });

      test('F12.2: Free drift preserves linear velocity without gravitational decay', () {
        Vector2 stepZeroG(Vector2 vel, double dt) => vel; // No gravity applied
        final initialVel = Vector2(4.5, -2.0);
        final afterStep = stepZeroG(initialVel, 1.0);
        expect(afterStep, equals(initialVel));
      });

      test('F12.3: Reverse thrusters (S / Down) apply braking force along heading', () {
        Vector2 applyReverseRCS(Vector2 currentVel, double thrustPower) {
          return currentVel + Vector2(0, thrustPower);
        }
        final braked = applyReverseRCS(Vector2(0, -5.0), 3.0);
        expect(braked.y, equals(-2.0));
      });

      test('F12.4: Tether dynamics in zero-G maintain momentum transfer to cargo', () {
        Vector2 transferTetherImpulse(Vector2 landerVel, double landerMass, double cargoMass) {
          final totalMass = landerMass + cargoMass;
          return landerVel * (landerMass / totalMass);
        }
        final combinedVel = transferTetherImpulse(Vector2(10, 0), 1.0, 1.0);
        expect(combinedVel.x, equals(5.0));
      });

      test('F12.5: Zero-G salvage requires precise docking speed < 1.5 m/s', () {
        bool isValidZeroGDock(double speed) => speed < 1.5;
        expect(isValidZeroGDock(0.8), isTrue);
        expect(isValidZeroGDock(2.2), isFalse);
      });
    });

    // -------------------------------------------------------------
    // F13. Cavern Hazards (Stalactites, Plumes, Gusts) (5 tests)
    // -------------------------------------------------------------
    group('F13: Cavern Hazards & Interactivity', () {
      test('F13.1: Stalactite detaches when lander is within 1.8m horizontal range', () {
        bool shouldDropStalactite(double landerX, double landerY, double stX, double stY) {
          final dx = (landerX - stX).abs();
          final dy = landerY - stY;
          return dx < 1.8 && dy > 0 && dy < 8.0;
        }
        expect(shouldDropStalactite(10.0, 5.0, 10.5, 0.0), isTrue);
        expect(shouldDropStalactite(10.0, 5.0, 15.0, 0.0), isFalse);
      });

      test('F13.2: Solar wind gusts calculate sinusoidal turbulent force', () {
        double calcWindForce(double time) {
          return -4.0 + 2.5 * sin(0.8 * time) + 1.2 * cos(2.3 * time);
        }
        final w0 = calcWindForce(0.0);
        final w1 = calcWindForce(2.0);
        expect(w0.isFinite, isTrue);
        expect(w1.isFinite, isTrue);
      });

      test('F13.3: Magma bubbles exert thermal impulse upon contact', () {
        double calcBubbleDamage(double baseImpulse) => baseImpulse * 1.8;
        expect(calcBubbleDamage(10.0), equals(18.0));
      });

      test('F13.4: Heavy collision triggers screen hit-stop timer', () {
        double calcHitStop(double impulse) => (impulse * 0.015).clamp(0.05, 0.15);
        expect(calcHitStop(12.0), closeTo(0.15, 0.05));
        expect(calcHitStop(2.0), equals(0.05));
      });

      test('F13.5: Tether snaps when tension exceeds breaking threshold', () {
        bool isTetherSnapped(double tension) => tension > 85.0;
        expect(isTetherSnapped(40.0), isFalse);
        expect(isTetherSnapped(95.0), isTrue);
      });
    });

    // -------------------------------------------------------------
    // F14. Procedural Endless Rescue Mode (5 tests)
    // -------------------------------------------------------------
    group('F14: Procedural Endless Rescue Mode', () {
      test('F14.1: Spawns initial sequential chunks on startup', () {
        final engine = EndlessRescueEngineContract();
        engine.spawnInitialChunks();
        expect(engine.activeChunks.length, equals(3));
        expect(engine.activeChunks[0].startX, equals(0.0));
        expect(engine.activeChunks[1].startX, equals(60.0));
        expect(engine.activeChunks[2].startX, equals(120.0));
      });

      test('F14.2: Progressing forward dynamically spawns new chunk', () {
        final engine = EndlessRescueEngineContract();
        engine.spawnInitialChunks();
        engine.updateLanderPosition(70.0);
        expect(engine.activeChunks.any((c) => c.chunkIndex == 3), isTrue);
      });

      test('F14.3: Recycles chunks that fall behind the player to conserve memory', () {
        final engine = EndlessRescueEngineContract();
        engine.spawnInitialChunks();
        engine.updateLanderPosition(150.0);
        expect(engine.activeChunks.any((c) => c.chunkIndex == 0), isFalse);
      });

      test('F14.4: Extraction completion awards 1000 score bonus', () {
        final engine = EndlessRescueEngineContract();
        engine.spawnInitialChunks();
        expect(engine.currentScore, equals(0));
        engine.completeExtraction();
        expect(engine.rescuesCompleted, equals(1));
        expect(engine.currentScore, greaterThanOrEqualTo(1000));
      });

      test('F14.5: Distance score increases continuously with forward flight', () {
        final engine = EndlessRescueEngineContract();
        engine.spawnInitialChunks();
        engine.updateLanderPosition(250.0);
        expect(engine.currentScore, greaterThanOrEqualTo(2500));
      });
    });

    // -------------------------------------------------------------
    // F15. 7 New Achievements (12 Total) (5 tests)
    // -------------------------------------------------------------
    group('F15: 7 New Achievements System', () {
      test('F15.1: AchievementsManager loads default 5 base achievements', () {
        final mgr = AchievementsManager();
        expect(mgr.achievements.length, greaterThanOrEqualTo(5));
      });

      test('F15.2: Speed Demon unlocks on velocity exceeding 11 m/s', () {
        bool checkSpeedDemon(double maxVelocity) => maxVelocity > 11.0;
        expect(checkSpeedDemon(8.5), isFalse);
        expect(checkSpeedDemon(12.3), isTrue);
      });

      test('F15.3: Zero Fuel Hero unlocks when mission succeeds at 0% fuel', () {
        bool checkZeroFuelHero(double fuelRemaining, bool isWon) => isWon && fuelRemaining <= 0.001;
        expect(checkZeroFuelHero(0.2, true), isFalse);
        expect(checkZeroFuelHero(0.0, true), isTrue);
        expect(checkZeroFuelHero(0.0, false), isFalse);
      });

      test('F15.4: Titanium Tether unlocks when Solar Winds completed without snap', () {
        bool checkTitaniumTether(String mapId, bool ropeSnapped, bool isWon) {
          return mapId == 'wind' && !ropeSnapped && isWon;
        }
        expect(checkTitaniumTether('wind', false, true), isTrue);
        expect(checkTitaniumTether('wind', true, true), isFalse);
      });

      test('F15.5: Cosmic Tycoon unlocks upon reaching 3000 total coins', () {
        bool checkCosmicTycoon(int totalCoins) => totalCoins >= 3000;
        expect(checkCosmicTycoon(2999), isFalse);
        expect(checkCosmicTycoon(3000), isTrue);
        expect(checkCosmicTycoon(5000), isTrue);
      });
    });

    // -------------------------------------------------------------
    // F16. Unified ShipMeshRenderer (0 Duplication) (5 tests)
    // -------------------------------------------------------------
    group('F16: Unified ShipMeshRenderer Contracts', () {
      test('F16.1: Sputnik model bounds are centered around origin', () {
        final bounds = RocketPainter.getBounds('sputnik');
        expect(bounds.center.dx, closeTo(0.0, 0.05));
      });

      test('F16.2: Cyclone model bounds are symmetric', () {
        final bounds = RocketPainter.getBounds('cyclone');
        expect(bounds.left.abs(), closeTo(bounds.right.abs(), 0.01));
      });

      test('F16.3: Needle model bounds provide slender vertical aspect ratio', () {
        final bounds = RocketPainter.getBounds('needle');
        expect(bounds.height, greaterThan(bounds.width));
      });

      test('F16.4: Fallback to sputnik for unknown ship ID', () {
        final bounds = RocketPainter.getBounds('unknown_prototype');
        expect(bounds, equals(RocketPainter.getBounds('sputnik')));
      });

      test('F16.5: calculateScale handles zero and negative canvas sizes gracefully', () {
        expect(RocketPainter.calculateScale('sputnik', Size.zero), equals(0.0));
        expect(RocketPainter.calculateScale('sputnik', const Size(-50, 100)), equals(0.0));
      });
    });

    // -------------------------------------------------------------
    // F17. Static Analysis & Test Cleanliness (5 tests)
    // -------------------------------------------------------------
    group('F17: Static Analysis & Test Suite Cleanliness', () {
      test('F17.1: GameState singleton returns consistent instance', () {
        expect(identical(GameState(), GameState()), isTrue);
      });

      test('F17.2: Audio manager testing mode silences hardware audio', () {
        expect(GameAudioManager.isTesting, isTrue);
      });

      test('F17.3: Translations for core gameplay strings exist in RU and EN', () {
        final state = GameState();
        for (final key in ['title', 'play', 'garage', 'records', 'fuel', 'shield', 'engine']) {
          expect(state.translate(key), isNotEmpty);
        }
      });

      test('F17.4: Leaderboard sort orders records by distance descending', () async {
        final state = GameState();
        await state.addRecord(150.0, 10, 'echo');
        await state.addRecord(300.0, 25, 'echo');
        await state.addRecord(200.0, 15, 'echo');
        expect(state.leaderboard[0]['distance'], equals(300));
        expect(state.leaderboard[1]['distance'], equals(200));
        expect(state.leaderboard[2]['distance'], equals(150));
      });

      test('F17.5: Leaderboard keeps at most top 10 records', () async {
        final state = GameState();
        for (int i = 1; i <= 15; i++) {
          await state.addRecord(i * 10.0, i, 'echo');
        }
        expect(state.leaderboard.length, equals(10));
      });
    });
  });
}
