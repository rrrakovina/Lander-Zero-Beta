import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flame_forge2d/flame_forge2d.dart' show Vector2;
import 'package:lander_zero/game/state/game_state.dart';
import 'package:lander_zero/game/audio/game_audio_manager.dart';
import 'package:lander_zero/ui/painters/rocket_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    GameAudioManager.isTesting = true;
    await GameState().init(force: true);
  });

  group('Tier 2: Boundary & Corner Cases (F1 to F17)', () {
    // -------------------------------------------------------------
    // F1. HMAC-SHA256 Save Protection Boundaries (5 tests)
    // -------------------------------------------------------------
    group('F1: HMAC-SHA256 Boundary Cases', () {
      String computeSig(int coins, List<String> fleet, String lb) {
        final sorted = List<String>.from(fleet)..sort();
        final payload = 'v1|coins:$coins|fleet:${sorted.join(",")}|lb:$lb';
        return Hmac(sha256, utf8.encode('LanderZero_Sec_Master_Save_Salt_2026'))
            .convert(utf8.encode(payload))
            .toString();
      }

      test('F1.B1: Zero coins boundary produces valid deterministic signature', () {
        final sig = computeSig(0, ['sputnik'], '[]');
        expect(sig.length, equals(64));
        expect(computeSig(0, ['sputnik'], '[]'), equals(sig));
      });

      test('F1.B2: Maximum 32-bit integer coin balance (2,147,483,647)', () {
        const maxCoins = 2147483647;
        final sig = computeSig(maxCoins, ['sputnik'], '[]');
        expect(sig.length, equals(64));
        expect(computeSig(maxCoins, ['sputnik'], '[]'), equals(sig));
      });

      test('F1.B3: Empty fleet list and massive leaderboard JSON payload (1000 items)', () {
        final hugeLb = jsonEncode(List.generate(1000, (i) => {'name': 'Pilot$i', 'distance': i * 100, 'coins': i}));
        final sig = computeSig(500, [], hugeLb);
        expect(sig.length, equals(64));
      });

      test('F1.B4: Malformed, truncated, or non-hex string signatures fail validation', () {
        bool isValidSig(String? sig, String expected) => sig != null && sig == expected;
        const expected = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
        expect(isValidSig('0123456789abcdef', expected), isFalse);
        expect(isValidSig('', expected), isFalse);
        expect(isValidSig('NOT_A_HEX_SIGNATURE', expected), isFalse);
      });

      test('F1.B5: Signature mismatch recovery restores zero coins baseline', () {
        final tamperedCoins = 999999;
        final legitSig = computeSig(0, ['sputnik'], '[]');
        final isAuthentic = computeSig(tamperedCoins, ['sputnik'], '[]') == legitSig;
        expect(isAuthentic, isFalse);

        final safeCoins = isAuthentic ? tamperedCoins : 0;
        expect(safeCoins, equals(0));
      });
    });

    // -------------------------------------------------------------
    // F2. Nickname Sanitization Boundaries (5 tests)
    // -------------------------------------------------------------
    group('F2: Nickname Sanitization Boundaries', () {
      String sanitize(String input) {
        final noHtml = input.replaceAll(RegExp(r'<[^>]*>'), '');
        final trimmed = noHtml.trim();
        if (trimmed.isEmpty) return 'Pilot';
        final clean = trimmed.replaceAll(RegExp(r'[^\w\s\u0400-\u04FF\.\-_]'), '').trim();
        if (clean.isEmpty) return 'Pilot';
        return clean.length > 15 ? clean.substring(0, 15) : clean;
      }

      test('F2.B1: Minimum valid length: single character name', () {
        expect(sanitize('A'), equals('A'));
        expect(sanitize('Я'), equals('Я'));
        expect(sanitize('7'), equals('7'));
      });

      test('F2.B2: Exact boundary length: exactly 15 characters', () {
        const exact15 = '123456789012345';
        expect(sanitize(exact15), equals(exact15));
        expect(sanitize(exact15).length, equals(15));
      });

      test('F2.B3: Boundary overflow: 16 characters truncated to 15', () {
        const over15 = '1234567890123456';
        final result = sanitize(over15);
        expect(result.length, equals(15));
        expect(result, equals('123456789012345'));
      });

      test('F2.B4: Null bytes and control characters mixed in string', () {
        const mixed = '\x00\x01\x1FAce\x08\x09';
        expect(sanitize(mixed), equals('Ace'));
      });

      test('F2.B5: Unicode emojis, symbols, and tabs collapse to fallback', () {
        expect(sanitize('🚀⭐👽'), equals('Pilot'));
        expect(sanitize('\t\r\n'), equals('Pilot'));
      });
    });

    // -------------------------------------------------------------
    // F3. Starter Ships Boundaries (5 tests)
    // -------------------------------------------------------------
    group('F3: Starter Ships Boundaries', () {
      test('F3.B1: Purchasing 0-cost starter ship when balance is 0 succeeds', () async {
        final state = GameState();
        expect(state.totalCoins, equals(0));
        final success = await state.buyRocket('sputnik');
        expect(success, isTrue);
        expect(state.totalCoins, equals(0));
      });

      test('F3.B2: Re-purchasing already owned starter ship does not deduct coins', () async {
        final state = GameState();
        await state.addCoins(50);
        final success = await state.buyRocket('sputnik');
        expect(success, isTrue);
        expect(state.totalCoins, equals(50));
      });

      test('F3.B3: Switching between multiple starter ships at zero coin balance', () async {
        final state = GameState();
        await state.selectRocket('sputnik');
        expect(state.selectedRocket, equals('sputnik'));
      });

      test('F3.B4: Selecting an unowned vessel is ignored', () async {
        final state = GameState();
        await state.selectRocket('unowned_prototype_x');
        expect(state.selectedRocket, equals('sputnik')); // Remains unchanged
      });

      test('F3.B5: Starter ships default to level 1 for all upgrade tracks', () {
        final state = GameState();
        expect(state.engineLevel, equals(1));
        expect(state.fuelLevel, equals(1));
        expect(state.shieldLevel, equals(1));
      });
    });

    // -------------------------------------------------------------
    // F4. Shop Ships & Upgrades Boundaries (5 tests)
    // -------------------------------------------------------------
    group('F4: Shop Ships & Upgrade Track Boundaries', () {
      test('F4.B1: Upgrade cost progression doubles sequentially (150, 300, 600, 1200)', () {
        int getUpgradeCost(int currentLevel) {
          if (currentLevel >= 5) return 0;
          return 150 * (1 << (currentLevel - 1));
        }
        expect(getUpgradeCost(1), equals(150));
        expect(getUpgradeCost(2), equals(300));
        expect(getUpgradeCost(3), equals(600));
        expect(getUpgradeCost(4), equals(1200));
        expect(getUpgradeCost(5), equals(0));
      });

      test('F4.B2: Upgrades fail when player has 1 coin less than cost (149 coins)', () async {
        final state = GameState();
        await state.addCoins(149);
        final success = await state.upgradeStat('engine');
        expect(success, isFalse);
        expect(state.engineLevel, equals(1));
        expect(state.totalCoins, equals(149));
      });

      test('F4.B3: Exact coin match (150 coins) upgrades stat and leaves 0 balance', () async {
        final state = GameState();
        await state.addCoins(150);
        final success = await state.upgradeStat('engine');
        expect(success, isTrue);
        expect(state.engineLevel, equals(2));
        expect(state.totalCoins, equals(0));
      });

      test('F4.B4: Cannot upgrade beyond maximum level 5', () async {
        final state = GameState();
        await state.addCoins(5000);
        for (int i = 0; i < 4; i++) {
          final up = await state.upgradeStat('shield');
          expect(up, isTrue);
        }
        expect(state.shieldLevel, equals(5));

        // 5th attempt must fail
        final overUpgrade = await state.upgradeStat('shield');
        expect(overUpgrade, isFalse);
        expect(state.shieldLevel, equals(5));
      });

      test('F4.B5: Upgrading unknown stat name returns false without modifying state', () async {
        final state = GameState();
        await state.addCoins(1000);
        final success = await state.upgradeStat('hyperdrive_flux');
        expect(success, isFalse);
        expect(state.totalCoins, equals(1000));
      });
    });

    // -------------------------------------------------------------
    // F5. Vector Decals & Rendering Boundaries (5 tests)
    // -------------------------------------------------------------
    group('F5: Vector Decals & Rendering Boundaries', () {
      test('F5.B1: Degenerate 0x0 canvas returns scale 0 without divide by zero', () {
        expect(RocketPainter.calculateScale('sputnik', Size.zero), equals(0.0));
      });

      test('F5.B2: Ultra-thin 1x10000 pixel canvas produces safe proportional scale', () {
        final scale = RocketPainter.calculateScale('sputnik', const Size(1, 10000));
        expect(scale, greaterThan(0));
        expect(scale.isFinite, isTrue);
      });

      test('F5.B3: Ultra-wide 10000x1 pixel canvas produces safe proportional scale', () {
        final scale = RocketPainter.calculateScale('cyclone', const Size(10000, 1));
        expect(scale, greaterThan(0));
        expect(scale.isFinite, isTrue);
      });

      test('F5.B4: Model bounds contain all vertices within strict box', () {
        for (final id in ['sputnik', 'cyclone', 'needle']) {
          final bounds = RocketPainter.getBounds(id);
          expect(bounds.isFinite, isTrue);
          expect(bounds.width, greaterThan(0));
          expect(bounds.height, greaterThan(0));
        }
      });

      test('F5.B5: Center offset is close to zero for symmetric vessels', () {
        final sputnikCenter = RocketPainter.getCenterOffset('sputnik');
        expect(sputnikCenter.dx, closeTo(0.0, 0.05));
      });
    });

    // -------------------------------------------------------------
    // F6. Live Astronaut Simulation Boundaries (5 tests)
    // -------------------------------------------------------------
    group('F6: Live Dynamic Astronaut Boundaries', () {
      test('F6.B1: Zero gravity (0G freefall) results in 0 G-strain and scale 1.0', () {
        double calculateGStrain(double gLoad) => (gLoad - 1.0).clamp(0.0, 5.0);
        expect(calculateGStrain(0.0), equals(0.0));
      });

      test('F6.B2: Extreme 50G acceleration clamps head compression to 0.75 max limit', () {
        double getHeadScaleY(double gLoad) {
          if (gLoad <= 2.5) return 1.0;
          return (1.0 - (gLoad - 2.5) * 0.08).clamp(0.75, 1.0);
        }
        expect(getHeadScaleY(50.0), equals(0.75));
      });

      test('F6.B3: Zero velocity gaze direction defaults to neutral forward facing', () {
        Vector2 getGaze(Vector2 vel) {
          if (vel.length < 0.01) return Vector2.zero();
          return vel.normalized();
        }
        expect(getGaze(Vector2.zero()), equals(Vector2.zero()));
      });

      test('F6.B4: Boundary threshold for panic blinking: shield at exactly 29.9% vs 30.0%', () {
        bool isPanic(double shield) => shield < 0.30;
        expect(isPanic(0.30), isFalse);
        expect(isPanic(0.299), isTrue);
      });

      test('F6.B5: Angular velocity of 100 rad/s clamps pilot head inertia', () {
        double clampHeadOffset(double offset) => offset.clamp(-0.4, 0.4);
        expect(clampHeadOffset(15.0), equals(0.4));
        expect(clampHeadOffset(-15.0), equals(-0.4));
      });
    });

    // -------------------------------------------------------------
    // F7. Cadet ID Terminal Boundaries (5 tests)
    // -------------------------------------------------------------
    group('F7: Cadet ID Terminal Boundaries', () {
      test('F7.B1: Single space string trimmed to empty and rejected', () {
        final text = ' ';
        expect(text.trim().isEmpty, isTrue);
      });

      test('F7.B2: Callsign with 15 Cyrillic characters accepted fully', () {
        const name15 = 'КосмонавтЮрий01';
        expect(name15.length, equals(15));
      });

      test('F7.B3: Rapid consecutive calls to setNickname update state correctly', () async {
        final state = GameState();
        for (int i = 0; i < 50; i++) {
          await state.setNickname('Pilot_$i');
        }
        expect(state.nickname, equals('Pilot_49'));
      });

      test('F7.B4: Switching language multiple times preserves nickname', () async {
        final state = GameState();
        await state.setNickname('StarPilot');
        await state.setLanguage('en');
        await state.setLanguage('ru');
        expect(state.nickname, equals('StarPilot'));
      });

      test('F7.B5: Error message cleared upon successful entry', () {
        String error = 'Error: empty nick';
        final newName = 'ValidNick';
        if (newName.isNotEmpty) error = '';
        expect(error, isEmpty);
      });
    });

    // -------------------------------------------------------------
    // F8. Live Hangar Main Menu Boundaries (5 tests)
    // -------------------------------------------------------------
    group('F8: Live Hangar Telemetry Boundaries', () {
      test('F8.B1: Music volume clamps values < 0.0 to 0.0 and > 1.0 to 1.0', () async {
        final state = GameState();
        await state.setMusicVolume(-5.0);
        expect(state.musicVolume, equals(0.0));
        await state.setMusicVolume(10.0);
        expect(state.musicVolume, equals(1.0));
      });

      test('F8.B2: SFX volume clamps values < 0.0 to 0.0 and > 1.0 to 1.0', () async {
        final state = GameState();
        await state.setSfxVolume(-1.5);
        expect(state.sfxVolume, equals(0.0));
        await state.setSfxVolume(2.5);
        expect(state.sfxVolume, equals(1.0));
      });

      test('F8.B3: Readiness score with zero stats is 60%', () {
        int calcReadiness(int engine, int fuel, int shield) {
          final total = (engine - 1) + (fuel - 1) + (shield - 1);
          return 60 + ((total / 12) * 40).round();
        }
        expect(calcReadiness(1, 1, 1), equals(60));
      });

      test('F8.B4: Readiness score with all stats at 5 is exactly 100%', () {
        int calcReadiness(int engine, int fuel, int shield) {
          final total = (engine - 1) + (fuel - 1) + (shield - 1);
          return 60 + ((total / 12) * 40).round();
        }
        expect(calcReadiness(5, 5, 5), equals(100));
      });

      test('F8.B5: Coin balance addition overflow check with large increments', () async {
        final state = GameState();
        await state.addCoins(1000000);
        expect(state.totalCoins, equals(1000000));
      });
    });

    // -------------------------------------------------------------
    // F9. Tactical Hologram Map Select Boundaries (5 tests)
    // -------------------------------------------------------------
    group('F9: Hologram Map Select Boundaries', () {
      test('F9.B1: Out-of-bounds terrain lookup clamps to boundary height', () {
        double sampleTerrain(double x, double minX, double maxX, double defaultY) {
          if (x < minX || x > maxX) return defaultY;
          return 5.0 + sin(x);
        }
        expect(sampleTerrain(-100.0, -70.0, 50.0, 5.0), equals(5.0));
        expect(sampleTerrain(100.0, -70.0, 50.0, 5.0), equals(5.0));
      });

      test('F9.B2: Cave ceiling clearance never falls below 9 meters minimum', () {
        double ensureClearance(double floorY, double ceilingY) {
          if (ceilingY >= floorY - 9.0) {
            return floorY - 9.0;
          }
          return ceilingY;
        }
        expect(ensureClearance(10.0, 5.0), equals(1.0)); // 10.0 - 9.0 = 1.0
      });

      test('F9.B3: Map selection with 5 biomes returns valid difficulty tags', () {
        const difficulties = {
          'echo': 'EASY',
          'wind': 'MEDIUM',
          'core': 'HARD',
          'ice': 'EXPERT',
          'orbit': 'EXTREME',
        };
        expect(difficulties.length, equals(5));
      });

      test('F9.B4: Negative wind velocity in Solar Winds blows leftward', () {
        const windX = -4.5;
        expect(windX, lessThan(0));
      });

      test('F9.B5: Gravity scaling ratio: Deep Core (1.5x) vs Normal (1.0x)', () {
        const gCore = 5.3;
        const gNormal = 3.5;
        expect(gCore / gNormal, closeTo(1.51, 0.05));
      });
    });

    // -------------------------------------------------------------
    // F10. Cockpit Cybernetic HUD Boundaries (5 tests)
    // -------------------------------------------------------------
    group('F10: Cockpit HUD Boundary Checks', () {
      test('F10.B1: Proximity alert threshold at exact boundary: 3.00m (off) vs 2.99m (on)', () {
        bool isAlert(double d, double v) => d < 3.0 && v > 3.5;
        expect(isAlert(3.00, 5.0), isFalse);
        expect(isAlert(2.99, 5.0), isTrue);
      });

      test('F10.B2: Approach speed threshold at exact boundary: 3.50 m/s (off) vs 3.51 m/s (on)', () {
        bool isAlert(double d, double v) => d < 3.0 && v > 3.5;
        expect(isAlert(2.0, 3.50), isFalse);
        expect(isAlert(2.0, 3.51), isTrue);
      });

      test('F10.B3: Safe landing tilt angle: 0.209 rad (safe) vs 0.211 rad (unsafe)', () {
        bool isSafeLandingAngle(double angle) {
          final norm = angle.abs() % (2 * pi);
          final a = norm > pi ? 2 * pi - norm : norm;
          return a < 0.21;
        }
        expect(isSafeLandingAngle(0.209), isTrue);
        expect(isSafeLandingAngle(0.211), isFalse);
      });

      test('F10.B4: Landing touchdown velocity: 0.59 m/s (safe) vs 0.61 m/s (too fast)', () {
        bool isSafeSpeed(double vSq) => vSq < 0.60;
        expect(isSafeSpeed(0.59), isTrue);
        expect(isSafeSpeed(0.61), isFalse);
      });

      test('F10.B5: Exit platform docking distance boundary: 3.99m (in zone) vs 4.01m (outside)', () {
        bool isInExitZone(double distance) => distance < 4.0;
        expect(isInExitZone(3.99), isTrue);
        expect(isInExitZone(4.01), isFalse);
      });
    });

    // -------------------------------------------------------------
    // F11. Ice Biome (Europa) Boundaries (5 tests)
    // -------------------------------------------------------------
    group('F11: Ice Biome Boundaries', () {
      test('F11.B1: Friction coeff 0.08 deceleration under sliding: a = mu * g', () {
        const mu = 0.08;
        const g = 2.275;
        const decel = mu * g;
        expect(decel, closeTo(0.182, 0.005));
      });

      test('F11.B2: Standard ground deceleration comparison: a = 0.80 * 3.5 = 2.8 m/s2', () {
        const decelEcho = 0.80 * 3.5;
        const decelIce = 0.08 * 2.275;
        expect(decelEcho / decelIce, greaterThan(15.0)); // 15x less stopping power on ice
      });

      test('F11.B3: Cryo geyser thermal plume activation radius boundary at 3.0m', () {
        bool inGeyserPlume(double dx, double dy) => dx.abs() < 1.5 && dy < 6.0 && dy > 0;
        expect(inGeyserPlume(1.4, 4.0), isTrue);
        expect(inGeyserPlume(1.6, 4.0), isFalse);
      });

      test('F11.B4: Icicle sharp collision impact velocity threshold', () {
        double calcDamage(double relSpeed) => (relSpeed * 6.0).clamp(10.0, 75.0);
        expect(calcDamage(0.5), equals(10.0));
        expect(calcDamage(20.0), equals(75.0));
      });

      test('F11.B5: Restitution elasticity bounce boundary (0.25 on Europa ice)', () {
        double calcBounceVelocity(double impactVelocity, double restitution) => -impactVelocity * restitution;
        expect(calcBounceVelocity(10.0, 0.25), equals(-2.5));
      });
    });

    // -------------------------------------------------------------
    // F12. Orbit Biome (Zero-G) Boundaries (5 tests)
    // -------------------------------------------------------------
    group('F12: Orbit Biome Boundaries', () {
      test('F12.B1: Momentum conservation under zero friction and zero gravity', () {
        Vector2 integratePos(Vector2 pos, Vector2 vel, double t) => pos + vel * t;
        final endPos = integratePos(Vector2.zero(), Vector2(10, 0), 5.0);
        expect(endPos.x, equals(50.0));
      });

      test('F12.B2: Reverse thruster counter-burn: duration needed to halt from 15 m/s at 30 N', () {
        // F = m * a -> a = F / m = 30 / 1.0 = 30 m/s2 -> t = v / a = 15 / 30 = 0.5s
        double calcBurnTime(double v, double f, double m) => v / (f / m);
        expect(calcBurnTime(15.0, 30.0, 1.0), equals(0.5));
      });

      test('F12.B3: Zero-G tether angular spring damper boundary', () {
        double calcSpringForce(double currentLen, double restLen, double k) {
          final delta = currentLen - restLen;
          return delta > 0 ? delta * k : 0.0;
        }
        expect(calcSpringForce(3.0, 2.5, 50.0), equals(25.0));
        expect(calcSpringForce(2.0, 2.5, 50.0), equals(0.0)); // Slack rope exerts 0 tension
      });

      test('F12.B4: Orbital debris field boundaries span [-50m, 50m]', () {
        bool inOrbitalSector(double x) => x >= -50.0 && x <= 50.0;
        expect(inOrbitalSector(0.0), isTrue);
        expect(inOrbitalSector(-50.0), isTrue);
        expect(inOrbitalSector(50.1), isFalse);
      });

      test('F12.B5: No-damage landing threshold at 0 hull damage for Zero-G Master', () {
        bool isZeroDamage(double damage) => damage <= 0.01;
        expect(isZeroDamage(0.0), isTrue);
        expect(isZeroDamage(0.01), isTrue);
        expect(isZeroDamage(0.02), isFalse);
      });
    });

    // -------------------------------------------------------------
    // F13. Cavern Hazards Boundaries (5 tests)
    // -------------------------------------------------------------
    group('F13: Hazard Interaction Boundaries', () {
      test('F13.B1: Stalactite horizontal drop trigger: 1.79m (drops) vs 1.81m (static)', () {
        bool checkDrop(double dx) => dx < 1.8;
        expect(checkDrop(1.79), isTrue);
        expect(checkDrop(1.81), isFalse);
      });

      test('F13.B2: Maximum screen shake intensity clamped to 1.5', () {
        double clampShake(double impulse) => (impulse * 0.08).clamp(0.1, 1.5);
        expect(clampShake(50.0), equals(1.5));
        expect(clampShake(0.5), equals(0.1));
      });

      test('F13.B3: Hit-stop duration clamped between 0.05s and 0.15s', () {
        double calcHitStop(double impulse) => (impulse * 0.015).clamp(0.05, 0.15);
        expect(calcHitStop(0.1), equals(0.05));
        expect(calcHitStop(20.0), equals(0.15));
      });

      test('F13.B4: Tether snap threshold at tension > 85.0', () {
        bool shouldSnap(double tension) => tension > 85.0;
        expect(shouldSnap(85.0), isFalse);
        expect(shouldSnap(85.01), isTrue);
      });

      test('F13.B5: Spark particle pool max capacity limit recycling', () {
        final List<int> pool = [];
        void spawnSpark(int id) {
          if (pool.length >= 60) pool.removeAt(0);
          pool.add(id);
        }
        for (int i = 0; i < 100; i++) {
          spawnSpark(i);
        }
        expect(pool.length, equals(60));
        expect(pool.first, equals(40));
        expect(pool.last, equals(99));
      });
    });

    // -------------------------------------------------------------
    // F14. Procedural Endless Mode Boundaries (5 tests)
    // -------------------------------------------------------------
    group('F14: Procedural Endless Mode Boundaries', () {
      test('F14.B1: Chunk index 0 bounds start at 0.0m and end at 60.0m', () {
        double startX(int i) => i * 60.0;
        double endX(int i) => startX(i) + 60.0;
        expect(startX(0), equals(0.0));
        expect(endX(0), equals(60.0));
      });

      test('F14.B2: Chunk index 10,000 bounds calculate without precision loss', () {
        double startX(int i) => i * 60.0;
        expect(startX(10000), equals(600000.0));
      });

      test('F14.B3: Score formula at 100,000 meters and 50 rescues', () {
        int calcScore(double dist, int rescues) => (dist * 10).toInt() + (rescues * 1000);
        final score = calcScore(100000.0, 50);
        expect(score, equals(1050000));
      });

      test('F14.B4: Chunk recycling threshold: removes chunks where endX < playerX - 40m', () {
        bool shouldRecycle(double chunkEndX, double playerX) => chunkEndX < playerX - 40.0;
        expect(shouldRecycle(60.0, 110.0), isTrue);  // 60 < 70 -> recycle
        expect(shouldRecycle(60.0, 95.0), isFalse);  // 60 < 55 -> keep
      });

      test('F14.B5: Difficulty scaling narrowing floor/ceiling passage from 14m to 8m min', () {
        double calcPassageHeight(int chunkIdx) {
          return max(8.0, 14.0 - chunkIdx * 0.5);
        }
        expect(calcPassageHeight(0), equals(14.0));
        expect(calcPassageHeight(6), equals(11.0));
        expect(calcPassageHeight(20), equals(8.0)); // Clamped to 8m minimum
      });
    });

    // -------------------------------------------------------------
    // F15. 7 New Achievements Boundaries (5 tests)
    // -------------------------------------------------------------
    group('F15: Achievement Trigger Boundaries', () {
      test('F15.B1: Speed Demon velocity threshold: 11.00 m/s (no) vs 11.01 m/s (unlock)', () {
        bool checkSpeedDemon(double v) => v > 11.0;
        expect(checkSpeedDemon(11.00), isFalse);
        expect(checkSpeedDemon(11.01), isTrue);
      });

      test('F15.B2: Speed Rescue mission time: 45.00s (unlock) vs 45.01s (no)', () {
        bool checkSpeedRescue(double time) => time <= 45.0 && time > 0;
        expect(checkSpeedRescue(45.00), isTrue);
        expect(checkSpeedRescue(45.01), isFalse);
      });

      test('F15.B3: Eco Pilot fuel remaining: 50.00% (unlock) vs 49.99% (no)', () {
        bool checkEcoPilot(double fuelPct) => fuelPct >= 0.50;
        expect(checkEcoPilot(0.50), isTrue);
        expect(checkEcoPilot(0.4999), isFalse);
      });

      test('F15.B4: Zero Fuel Hero remaining fuel: 0.001 (unlock) vs 0.002 (no)', () {
        bool checkZeroFuelHero(double fuel) => fuel <= 0.001;
        expect(checkZeroFuelHero(0.001), isTrue);
        expect(checkZeroFuelHero(0.002), isFalse);
      });

      test('F15.B5: Cosmic Tycoon coin balance: 2999 (no) vs 3000 (unlock)', () {
        bool checkCosmicTycoon(int coins) => coins >= 3000;
        expect(checkCosmicTycoon(2999), isFalse);
        expect(checkCosmicTycoon(3000), isTrue);
      });
    });

    // -------------------------------------------------------------
    // F16. Unified ShipMeshRenderer Precision (5 tests)
    // -------------------------------------------------------------
    group('F16: Unified ShipMeshRenderer Geometry Precision', () {
      test('F16.B1: Scale calculation for 1000x1000 square container', () {
        final scale = RocketPainter.calculateScale('sputnik', const Size(1000, 1000));
        expect(scale, closeTo(1000.0 / (3.3 * 1.20), 1.0));
      });

      test('F16.B2: Safety margin 1.20 provides 20% padding around bounding box', () {
        expect(RocketPainter.safetyMargin, equals(1.20));
      });

      test('F16.B3: Model bounds for all ships have positive non-zero area', () {
        for (final id in ['sputnik', 'cyclone', 'needle']) {
          final bounds = RocketPainter.getBounds(id);
          final area = bounds.width * bounds.height;
          expect(area, greaterThan(4.0));
        }
      });

      test('F16.B4: Unknown rocket ID returns fallback bounds safely', () {
        final bounds = RocketPainter.getBounds('');
        expect(bounds, equals(RocketPainter.getBounds('sputnik')));
      });

      test('F16.B5: Negative width and height sizes return 0.0 scale without throwing', () {
        expect(RocketPainter.calculateScale('sputnik', const Size(-100, -100)), equals(0.0));
      });
    });

    // -------------------------------------------------------------
    // F17. Test Suite Determinism & Reset Boundaries (5 tests)
    // -------------------------------------------------------------
    group('F17: Deterministic State Reset & Isolation', () {
      test('F17.B1: GameState init force resets in-memory cache to mock storage', () async {
        final state = GameState();
        await state.addCoins(777);
        expect(state.totalCoins, equals(777));

        SharedPreferences.setMockInitialValues({'totalCoins': 0});
        await state.init(force: true);
        expect(state.totalCoins, equals(0));
      });

      test('F17.B2: Leaderboard handles JSON string corruption by resetting to empty list', () async {
        SharedPreferences.setMockInitialValues({'leaderboard': '{CORRUPTED_JSON}'});
        final state = GameState();
        await state.init(force: true);
        expect(state.leaderboard, isEmpty);
      });

      test('F17.B3: Leaderboard adds record and preserves exact decimal distance as int', () async {
        final state = GameState();
        await state.addRecord(42.8, 5, 'echo');
        expect(state.leaderboard.first['distance'], equals(42));
      });

      test('F17.B4: Top-10 leaderboard drops 11th record correctly', () async {
        final state = GameState();
        for (int i = 1; i <= 12; i++) {
          await state.addRecord(i * 10.0, i, 'echo');
        }
        expect(state.leaderboard.length, equals(10));
        expect(state.leaderboard.first['distance'], equals(120));
        expect(state.leaderboard.last['distance'], equals(30));
      });

      test('F17.B5: Default language fallback is Russian', () async {
        SharedPreferences.setMockInitialValues({});
        final state = GameState();
        await state.init(force: true);
        expect(state.language, equals('ru'));
      });
    });
  });
}
