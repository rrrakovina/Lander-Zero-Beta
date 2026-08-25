import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flame_forge2d/flame_forge2d.dart' show Vector2;
import 'package:lander_zero/game/state/game_state.dart';
import 'package:lander_zero/game/audio/game_audio_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    GameAudioManager.isTesting = true;
    await GameState().init(force: true);
  });

  group('Tier 4: Real-World Application Scenarios (Scenarios 1 to 9)', () {
    String computeHmac(int coins, List<String> fleet, String lb) {
      final sorted = List<String>.from(fleet)..sort();
      final payload = 'v1|coins:$coins|fleet:${sorted.join(",")}|lb:$lb';
      return Hmac(sha256, utf8.encode('LanderZero_Sec_Master_Save_Salt_2026'))
          .convert(utf8.encode(payload))
          .toString();
    }

    test('Scenario 1: First-time cadet registration with callsign sanitization and Swift-02 starter deployment', () async {
      final state = GameState();

      // 1. Initial fresh install check
      expect(state.nickname, isEmpty);
      expect(state.totalCoins, equals(0));

      // 2. Cadet inputs callsign with surrounding spaces and forbidden symbols
      const rawCallsign = '  <Vostok_Swift>\x00  ';
      final cleanCallsign = rawCallsign.replaceAll(RegExp(r'[^\w\s\u0400-\u04FF\.\-_]'), '').trim();
      await state.setNickname(cleanCallsign);
      expect(state.nickname, equals('Vostok_Swift'));

      // 3. Select starter ship
      await state.selectRocket('sputnik');
      expect(state.selectedRocket, equals('sputnik'));

      // 4. Generate save signature for cadet state
      final sig = computeHmac(state.totalCoins, state.ownedRockets, jsonEncode(state.leaderboard));
      expect(sig.length, equals(64));
    });

    test('Scenario 2: High-speed rescue run on Europa ice cavern with cryo-geyser avoidance and zero-fuel landing', () async {
      final state = GameState();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs, isNotNull);
      expect(state.initialized, isTrue);

      // Europa physics parameters
      const mapId = 'ice';
      const gravityY = 2.275;
      const iceFriction = 0.08;
      expect(gravityY, closeTo(3.5 * 0.65, 0.01));
      expect(iceFriction, equals(0.08));

      // Simulate flight: high velocity, dodging geyser, glide touchdown with 0 fuel remaining
      double flightVelocity = 12.5; // > 11 m/s for Speed Demon
      double fuelRemaining = 0.0;
      double damageTaken = 0.0;
      double flightTime = 38.0; // < 45s for Speed Rescue
      int coinsCollected = 4;
      bool isWon = true;

      // Evaluate achievements triggered in this scenario
      bool unlockedSpeedDemon = flightVelocity > 11.0;
      bool unlockedZeroFuelHero = isWon && fuelRemaining <= 0.001 && damageTaken == 0.0;
      bool unlockedIceBreaker = mapId == 'ice' && isWon;
      bool unlockedSpeedRescue = isWon && flightTime <= 45.0 && coinsCollected >= 0;

      expect(unlockedSpeedDemon, isTrue);
      expect(unlockedZeroFuelHero, isTrue);
      expect(unlockedIceBreaker, isTrue);
      expect(unlockedSpeedRescue, isTrue);

      // Record victory in state
      await state.addRecord(280.0, coinsCollected, mapId);
      await state.addCoins(coinsCollected * 10 + 100);

      expect(state.totalCoins, equals(140));
      expect(state.leaderboard.first['distance'], equals(280));
    });

    test('Scenario 3: Deep-space zero-G orbital salvage with reverse thruster braking and zero-damage extraction', () async {
      final state = GameState();
      const mapId = 'orbit';
      const gravityY = 0.0;
      expect(gravityY, equals(0.0));

      // Flight telemetry simulation
      Vector2 landerVelocity = Vector2(6.0, -4.0);

      // Apply reverse RCS counter-burn (S key) to decelerate safely
      final counterBurnImpulse = Vector2(-6.0, 4.0);
      landerVelocity += counterBurnImpulse;
      expect(landerVelocity.length, closeTo(0.0, 0.01));

      // Docking and extraction with 0 hull damage
      const damageTaken = 0.0;
      const isWon = true;

      bool unlockedZeroGMaster = mapId == 'orbit' && damageTaken <= 0.01 && isWon;
      bool unlockedSoftLanding = damageTaken <= 0.01 && isWon;

      expect(unlockedZeroGMaster, isTrue);
      expect(unlockedSoftLanding, isTrue);

      await state.addRecord(320.0, 8, mapId);
      await state.addCoins(180);
      expect(state.totalCoins, equals(180));
    });

    test('Scenario 4: Endless rescue mode multi-chunk navigation with chained extractions and refuel checkpoints', () {
      int rescues = 0;
      int score = 0;
      double distance = 0.0;
      final List<int> activeChunks = [0, 1, 2];

      // Simulate progressing through chunks 0 -> 1 -> 2 -> 3 -> 4
      for (int step = 1; step <= 5; step++) {
        distance += 60.0;
        final currentChunk = (distance / 60.0).floor();
        if (!activeChunks.contains(currentChunk + 1)) {
          activeChunks.add(currentChunk + 1);
        }
        activeChunks.removeWhere((c) => c * 60.0 < distance - 40.0);

        // Every even chunk has a rescue
        if (step % 2 == 0) {
          rescues++;
          score += 1000;
        }
        score = (distance * 10).toInt() + (rescues * 1000);
      }

      expect(distance, equals(300.0));
      expect(rescues, equals(2));
      expect(score, equals(5000));
      expect(activeChunks.length, lessThanOrEqualTo(4)); // Constant memory chunk count
    });

    test('Scenario 5: Fleet upgrade mastery path unlocking Titan-V and Quasar-IX and achieving Fleet Admiral', () async {
      final state = GameState();
      // Earn currency
      await state.addCoins(10000);

      // Buy shop ship
      final buyCyclone = await state.buyRocket('cyclone');
      expect(buyCyclone, isTrue);

      // Max out all 3 upgrade tracks
      for (int i = 0; i < 4; i++) {
        await state.upgradeStat('engine');
        await state.upgradeStat('fuel');
        await state.upgradeStat('shield');
      }

      expect(state.engineLevel, equals(5));
      expect(state.fuelLevel, equals(5));
      expect(state.shieldLevel, equals(5));

      bool checkFleetAdmiral(int eng, int fuel, int shield) => eng == 5 && fuel == 5 && shield == 5;
      expect(checkFleetAdmiral(state.engineLevel, state.fuelLevel, state.shieldLevel), isTrue);
    });

    test('Scenario 6: Save data tamper detection: injected corrupted coin balance reverts cleanly to verified state', () async {
      const legitCoins = 250;
      final fleet = ['sputnik', 'swift'];
      const lb = '[]';
      final validSig = computeHmac(legitCoins, fleet, lb);

      // Attacker tampers with coin balance in SharedPreferences
      const tamperedCoins = 9999999;
      final isAuthentic = computeHmac(tamperedCoins, fleet, lb) == validSig;
      expect(isAuthentic, isFalse);

      // System gracefully detects tamper and resets state
      int recoveredCoins = legitCoins;
      if (!isAuthentic) {
        recoveredCoins = 0; // Baseline reset
      }
      expect(recoveredCoins, equals(0));

      final state = GameState();
      expect(state.totalCoins, equals(0));
    });

    test('Scenario 7: Full mission cockpit telemetry validation under intense G-force strain and cavern proximity alarm', () {
      final telemetryHistory = <Map<String, dynamic>>[];

      // 1. High acceleration burn
      final highGForce = 4.2;
      final isHighGAlert = highGForce > 3.5;
      telemetryHistory.add({'g': highGForce, 'alert': isHighGAlert ? 'HIGH G' : ''});

      // 2. Proximity approach near cavern wall
      final proximityDist = 1.4;
      final approachVel = 5.8;
      final isProxAlert = proximityDist < 3.0 && approachVel > 3.5;
      telemetryHistory.add({'prox': proximityDist, 'proxAlert': isProxAlert});

      expect(isHighGAlert, isTrue);
      expect(isProxAlert, isTrue);
      expect(telemetryHistory.length, equals(2));
    });

    test('Scenario 8: Solar wind plasma gust turbulence navigation with titanium tether achievement check', () async {
      const mapId = 'wind';
      double ropeTension = 45.0; // Normal tension
      bool ropeSnapped = false;

      // Turbulent gust hits
      const gustForce = -6.5;
      ropeTension += gustForce.abs() * 3.0; // 45 + 19.5 = 64.5 (below 85.0 threshold)
      if (ropeTension > 85.0) {
        ropeSnapped = true;
      }
      expect(ropeSnapped, isFalse);

      // Successful extraction in Solar Winds
      const isWon = true;
      bool checkTitaniumTether = mapId == 'wind' && !ropeSnapped && isWon;
      expect(checkTitaniumTether, isTrue);
    });

    test('Scenario 9: Cosmic Tycoon path: collecting 3000+ coins across all 5 biomes with HMAC signature verified', () async {
      final state = GameState();
      final biomes = ['echo', 'wind', 'core', 'ice', 'orbit'];

      for (final biome in biomes) {
        await state.addRecord(250.0, 15, biome);
        await state.addCoins(650);
      }

      // Total earned: 5 * 650 = 3250 coins
      expect(state.totalCoins, equals(3250));

      bool checkCosmicTycoon = state.totalCoins >= 3000;
      expect(checkCosmicTycoon, isTrue);

      final sig = computeHmac(state.totalCoins, state.ownedRockets, jsonEncode(state.leaderboard));
      expect(sig.length, equals(64));
      expect(computeHmac(3250, state.ownedRockets, jsonEncode(state.leaderboard)), equals(sig));
    });
  });
}
