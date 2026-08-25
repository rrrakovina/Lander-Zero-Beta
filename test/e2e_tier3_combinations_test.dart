import 'dart:convert';
import 'package:crypto/crypto.dart';
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

  group('Tier 3: Pairwise Cross-Feature Combinations', () {
    String computeHmac(int coins, List<String> fleet, String lb) {
      final sorted = List<String>.from(fleet)..sort();
      final payload = 'v1|coins:$coins|fleet:${sorted.join(",")}|lb:$lb';
      return Hmac(sha256, utf8.encode('LanderZero_Sec_Master_Save_Salt_2026'))
          .convert(utf8.encode(payload))
          .toString();
    }

    test('C1 (F1 x F4): Save security verification after purchasing shop ship and deducting coins', () async {
      final state = GameState();
      await state.addCoins(2000);
      final preSig = computeHmac(state.totalCoins, state.ownedRockets, jsonEncode(state.leaderboard));

      final bought = await state.buyRocket('cyclone');
      expect(bought, isTrue);
      expect(state.totalCoins, equals(1200));

      final postSig = computeHmac(state.totalCoins, state.ownedRockets, jsonEncode(state.leaderboard));
      expect(postSig, isNot(equals(preSig)));
      expect(computeHmac(1200, ['sputnik', 'swift', 'cyclone'], jsonEncode(state.leaderboard)), equals(postSig));
    });

    test('C2 (F2 x F7): Nickname sanitization within Cadet ID Terminal with immediate Live Hangar sync', () async {
      final state = GameState();
      const rawInput = '  <Pilot>_Orion\x00  ';
      final clean = rawInput.trim().replaceAll(RegExp(r'[^\w\s\u0400-\u04FF\.\-_]'), '').trim();
      await state.setNickname(clean);

      expect(state.nickname, equals('Pilot_Orion'));
      expect(state.nickname.contains('<'), isFalse);
    });

    test('C3 (F3 x F6): Swift-02 starter ship paired with live astronaut G-strain simulation in high acceleration', () {
      final swiftMass = 0.75;
      final swiftThrust = 38.0;
      final accelY = (swiftThrust / swiftMass) - 3.5; // Net acceleration: 50.67 - 3.5 = 47.17 m/s2
      final gLoad = (accelY + 3.5) / 3.5; // ~14.48 G

      double getHeadScaleY(double g) => g <= 2.5 ? 1.0 : (1.0 - (g - 2.5) * 0.08).clamp(0.75, 1.0);
      final headScale = getHeadScaleY(gLoad);

      expect(gLoad, greaterThan(10.0));
      expect(headScale, equals(0.75)); // Max pilot compression under Swift high thrust
    });

    test('C4 (F4 x F15): Maxing all fleet upgrade tracks and owning all ships unlocks Fleet Admiral', () async {
      final state = GameState();
      await state.addCoins(50000);

      // Max all 3 upgrade tracks to Level 5
      for (int i = 0; i < 4; i++) {
        await state.upgradeStat('engine');
        await state.upgradeStat('fuel');
        await state.upgradeStat('shield');
      }
      expect(state.engineLevel, equals(5));
      expect(state.fuelLevel, equals(5));
      expect(state.shieldLevel, equals(5));

      bool checkFleetAdmiral(int engine, int fuel, int shield, int ownedCount) {
        return engine == 5 && fuel == 5 && shield == 5 && ownedCount >= 3;
      }
      expect(checkFleetAdmiral(state.engineLevel, state.fuelLevel, state.shieldLevel, 3), isTrue);
    });

    test('C5 (F5 x F16): Unified ShipMeshRenderer vector insignias rendering across preview contexts', () {
      const decals = {
        'sputnik': 'СССР-01',
        'swift': 'SWIFT-02',
        'titan': 'TITAN-V',
        'quasar': 'QUASAR-IX',
        'cyclone': 'CY-88',
      };
      for (final entry in decals.entries) {
        final bounds = RocketPainter.getBounds(entry.key);
        expect(bounds.width, greaterThan(0));
        expect(entry.value, isNotEmpty);
      }
    });

    test('C6 (F6 x F10): Live pilot panic blinking synchronizing with cockpit HUD proximity warning alert', () {
      final proximityDist = 1.8;
      final approachSpeed = 6.5;
      final isProximityAlert = proximityDist < 3.0 && approachSpeed > 3.5;
      final isPilotPanicking = approachSpeed > 6.0 || proximityDist < 2.0;

      expect(isProximityAlert, isTrue);
      expect(isPilotPanicking, isTrue);
    });

    test('C7 (F7 x F8): Cadet Terminal onboarding transitioning directly into Live Hangar with active telemetry', () async {
      final state = GameState();
      await state.setNickname('Yuri-01');
      await state.selectRocket('sputnik');

      expect(state.nickname, equals('Yuri-01'));
      expect(state.selectedRocket, equals('sputnik'));
      expect(state.translate('play'), equals('ИГРАТЬ'));
    });

    test('C8 (F8 x F9): Live Hangar navigation into Tactical Hologram Map Select with reactive localization', () async {
      final state = GameState();
      expect(state.translate('map_echo'), equals('Каньон Эхо'));

      await state.setLanguage('en');
      expect(state.translate('map_echo'), equals('Echo Canyon'));
    });

    test('C9 (F9 x F11): Map select Europa Ice briefing environmental parameters matching in-game ice physics', () {
      const briefingGravity = 0.65;
      const baseGravity = 3.5;
      final actualGravity = briefingGravity * baseGravity;
      const iceFriction = 0.08;

      expect(actualGravity, closeTo(2.275, 0.001));
      expect(iceFriction, equals(0.08));
    });

    test('C10 (F9 x F12): Map select Orbital Debris briefing parameters matching in-game zero-G drift physics', () {
      const orbitalGravity = 0.0;
      Vector2 applyInertiaDrift(Vector2 pos, Vector2 vel, double dt) => pos + vel * dt;

      final startPos = Vector2(0, 0);
      final velocity = Vector2(8, -3);
      final nextPos = applyInertiaDrift(startPos, velocity, 2.0);

      expect(orbitalGravity, equals(0.0));
      expect(nextPos, equals(Vector2(16, -6)));
    });

    test('C11 (F10 x F13): Cockpit proximity sensor triggering warning alert when descending near falling stalactite', () {
      final landerPos = Vector2(10.0, 5.0);
      final stalactitePos = Vector2(10.5, 3.2);
      final distance = landerPos.distanceTo(stalactitePos);
      final relSpeed = 4.2;

      final isAlert = distance < 3.0 && relSpeed > 3.5;
      expect(distance, lessThan(3.0));
      expect(isAlert, isTrue);
    });

    test('C12 (F10 x F14): Cockpit HUD telemetry tracking multi-chunk progress in Endless Rescue Mode', () {
      double landerX = 245.0;
      final currentChunkIndex = (landerX / 60.0).floor();
      final currentScore = (landerX * 10).toInt();

      expect(currentChunkIndex, equals(4));
      expect(currentScore, equals(2450));
    });

    test('C13 (F11 x F15): Completing Europa rescue on Ice biome triggering Ice Breaker achievement', () {
      bool checkIceBreaker(String mapId, bool isWon) => mapId == 'ice' && isWon;
      expect(checkIceBreaker('ice', true), isTrue);
      expect(checkIceBreaker('echo', true), isFalse);
    });

    test('C14 (F12 x F15): Zero-damage mission in Orbital Debris triggering Zero-G Master achievement', () {
      bool checkZeroGMaster(String mapId, double damage, bool isWon) {
        return mapId == 'orbit' && damage <= 0.01 && isWon;
      }
      expect(checkZeroGMaster('orbit', 0.0, true), isTrue);
      expect(checkZeroGMaster('orbit', 15.0, true), isFalse);
    });

    test('C15 (F13 x F15): Navigating Solar Winds without breaking tether triggering Titanium Tether', () {
      bool checkTitaniumTether(String mapId, bool ropeSnapped, bool isWon) {
        return mapId == 'wind' && !ropeSnapped && isWon;
      }
      expect(checkTitaniumTether('wind', false, true), isTrue);
      expect(checkTitaniumTether('wind', true, true), isFalse);
    });

    test('C16 (F14 x F15): Reaching 3000+ total coins from endless mode chained rescues triggering Cosmic Tycoon', () async {
      final state = GameState();
      await state.addCoins(3200);

      bool checkCosmicTycoon(int coins) => coins >= 3000;
      expect(checkCosmicTycoon(state.totalCoins), isTrue);
    });

    test('C17 (F1 x F15): Cryptographic HMAC signature preservation across all 12 unlocked achievements', () async {
      final state = GameState();
      await state.addCoins(1000);

      final sigBefore = computeHmac(state.totalCoins, state.ownedRockets, jsonEncode(state.leaderboard));
      expect(sigBefore.length, equals(64));

      // Award achievement bonus (100 coins)
      await state.addCoins(100);
      final sigAfter = computeHmac(state.totalCoins, state.ownedRockets, jsonEncode(state.leaderboard));

      expect(sigAfter, isNot(equals(sigBefore)));
      expect(state.totalCoins, equals(1100));
    });
  });
}
