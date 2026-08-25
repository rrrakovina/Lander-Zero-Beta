import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lander_zero/game/state/game_state.dart';
import 'package:lander_zero/game/state/achievements_manager.dart';
import 'package:lander_zero/game/state/save_security_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('12 Achievements System Unit & Security Tests', () {
    late SharedPreferences prefs;
    late AchievementsManager manager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      await GameState().init(force: true);
      manager = AchievementsManager();
      // Reset achievements state for testing
      for (final a in manager.achievements) {
        a.isUnlocked = false;
        a.progress = 0;
      }
    });

    test('All 12 achievements are loaded properly with distinct IDs and rewards', () {
      expect(manager.achievements.length, 12);
      final expectedIds = [
        'soft_landing',
        'eco_pilot',
        'speed_rescue',
        'treasure_hunter',
        'cave_veteran',
        'speed_demon',
        'titanium_tether',
        'zero_fuel_hero',
        'fleet_admiral',
        'ice_breaker',
        'zero_g_master',
        'cosmic_tycoon',
      ];
      for (final id in expectedIds) {
        expect(manager.achievements.any((a) => a.id == id), isTrue,
            reason: 'Missing achievement: $id');
        final ach = manager.achievements.firstWhere((a) => a.id == id);
        expect(ach.getTitle('ru').isNotEmpty, isTrue);
        expect(ach.getTitle('en').isNotEmpty, isTrue);
        expect(ach.getDesc('ru').isNotEmpty, isTrue);
        expect(ach.getDesc('en').isNotEmpty, isTrue);
        expect(ach.starReward > 0, isTrue);
      }
    });

    test('1. Soft landing unlocks on zero damage', () {
      final softLanding = manager.achievements.firstWhere((a) => a.id == 'soft_landing');
      expect(softLanding.isUnlocked, isFalse);

      manager.checkMissionCompletionStats(
        prefs: prefs,
        damageTaken: 0.0,
        fuelPercentRemaining: 0.3,
        missionSeconds: 60.0,
        coinsCollected: 2,
        isSuccess: true,
      );

      expect(softLanding.isUnlocked, isTrue);
    });

    test('2. Eco pilot unlocks when fuel remaining >= 50%', () {
      final ecoPilot = manager.achievements.firstWhere((a) => a.id == 'eco_pilot');
      expect(ecoPilot.isUnlocked, isFalse);

      manager.checkMissionCompletionStats(
        prefs: prefs,
        damageTaken: 10.0,
        fuelPercentRemaining: 0.55,
        missionSeconds: 60.0,
        coinsCollected: 2,
        isSuccess: true,
      );

      expect(ecoPilot.isUnlocked, isTrue);
    });

    test('3. Speed rescue unlocks when duration <= 45s', () {
      final speedRescue = manager.achievements.firstWhere((a) => a.id == 'speed_rescue');
      expect(speedRescue.isUnlocked, isFalse);

      manager.checkMissionCompletionStats(
        prefs: prefs,
        damageTaken: 10.0,
        fuelPercentRemaining: 0.2,
        missionSeconds: 42.5,
        coinsCollected: 2,
        isSuccess: true,
      );

      expect(speedRescue.isUnlocked, isTrue);
    });

    test('4. Treasure hunter unlocks when coinsCollected >= 10', () {
      final treasure = manager.achievements.firstWhere((a) => a.id == 'treasure_hunter');
      expect(treasure.isUnlocked, isFalse);

      manager.checkMissionCompletionStats(
        prefs: prefs,
        damageTaken: 10.0,
        fuelPercentRemaining: 0.2,
        missionSeconds: 60.0,
        coinsCollected: 12,
        isSuccess: true,
      );

      expect(treasure.isUnlocked, isTrue);
    });

    test('5. Cave veteran increments and unlocks on 5th success', () {
      final veteran = manager.achievements.firstWhere((a) => a.id == 'cave_veteran');
      expect(veteran.isUnlocked, isFalse);
      expect(veteran.progress, 0);

      for (int i = 0; i < 4; i++) {
        manager.checkMissionCompletionStats(
          prefs: prefs,
          damageTaken: 10.0,
          fuelPercentRemaining: 0.2,
          missionSeconds: 60.0,
          coinsCollected: 0,
          isSuccess: true,
        );
        expect(veteran.isUnlocked, isFalse);
        expect(veteran.progress, i + 1);
      }

      // 5th mission
      manager.checkMissionCompletionStats(
        prefs: prefs,
        damageTaken: 10.0,
        fuelPercentRemaining: 0.2,
        missionSeconds: 60.0,
        coinsCollected: 0,
        isSuccess: true,
      );

      expect(veteran.isUnlocked, isTrue);
      expect(veteran.progress, 5);
    });

    test('6. Speed demon unlocks when flight velocity >= 11.0 m/s', () {
      final speedDemon = manager.achievements.firstWhere((a) => a.id == 'speed_demon');
      expect(speedDemon.isUnlocked, isFalse);

      manager.checkSpeed(8.5, prefs);
      expect(speedDemon.isUnlocked, isFalse);

      manager.checkSpeed(11.5, prefs);
      expect(speedDemon.isUnlocked, isTrue);
    });

    test('7. Titanium tether unlocks on Solar Winds without rope snap', () {
      final tether = manager.achievements.firstWhere((a) => a.id == 'titanium_tether');
      expect(tether.isUnlocked, isFalse);

      // Other map -> no unlock
      manager.checkMissionCompletionStats(
        prefs: prefs,
        damageTaken: 5.0,
        fuelPercentRemaining: 0.3,
        missionSeconds: 50.0,
        coinsCollected: 2,
        isSuccess: true,
        mapId: 'echo',
        ropeSnapped: false,
      );
      expect(tether.isUnlocked, isFalse);

      // Wind map with rope snap -> no unlock
      manager.checkMissionCompletionStats(
        prefs: prefs,
        damageTaken: 5.0,
        fuelPercentRemaining: 0.3,
        missionSeconds: 50.0,
        coinsCollected: 2,
        isSuccess: true,
        mapId: 'wind',
        ropeSnapped: true,
      );
      expect(tether.isUnlocked, isFalse);

      // Wind map without rope snap -> unlocks!
      manager.checkMissionCompletionStats(
        prefs: prefs,
        damageTaken: 5.0,
        fuelPercentRemaining: 0.3,
        missionSeconds: 50.0,
        coinsCollected: 2,
        isSuccess: true,
        mapId: 'wind',
        ropeSnapped: false,
      );
      expect(tether.isUnlocked, isTrue);
    });

    test('8. Zero fuel hero unlocks when fuel percent <= 0.001', () {
      final hero = manager.achievements.firstWhere((a) => a.id == 'zero_fuel_hero');
      expect(hero.isUnlocked, isFalse);

      manager.checkMissionCompletionStats(
        prefs: prefs,
        damageTaken: 0.0,
        fuelPercentRemaining: 0.0,
        missionSeconds: 50.0,
        coinsCollected: 2,
        isSuccess: true,
      );
      expect(hero.isUnlocked, isTrue);
    });

    test('9. Fleet admiral unlocks when all 5 ships owned and all 3 upgrades == 5', () async {
      final admiral = manager.achievements.firstWhere((a) => a.id == 'fleet_admiral');
      expect(admiral.isUnlocked, isFalse);

      final state = GameState();
      // Unlock all 5 ships
      for (final ship in ['cyclone', 'needle', 'titan']) {
        await state.unlockRocket(ship);
      }
      expect(state.ownedRockets.length, 5);

      // Upgrade stats to max
      await state.addCoins(10000);
      for (int i = 0; i < 4; i++) {
        await state.upgradeStat('engine');
        await state.upgradeStat('fuel');
        await state.upgradeStat('shield');
      }
      expect(state.engineLevel, 5);
      expect(state.fuelLevel, 5);
      expect(state.shieldLevel, 5);

      manager.checkFleetAdmiral(state, prefs);
      expect(admiral.isUnlocked, isTrue);
    });

    test('10. Ice breaker unlocks on Europa ice map completion', () {
      final iceBreaker = manager.achievements.firstWhere((a) => a.id == 'ice_breaker');
      expect(iceBreaker.isUnlocked, isFalse);

      manager.checkMissionCompletionStats(
        prefs: prefs,
        damageTaken: 10.0,
        fuelPercentRemaining: 0.3,
        missionSeconds: 50.0,
        coinsCollected: 2,
        isSuccess: true,
        mapId: 'ice',
      );
      expect(iceBreaker.isUnlocked, isTrue);
    });

    test('11. Zero-G master unlocks on Orbit map completion with 0 hull damage', () {
      final zeroGMaster = manager.achievements.firstWhere((a) => a.id == 'zero_g_master');
      expect(zeroGMaster.isUnlocked, isFalse);

      // Orbit with damage -> no unlock
      manager.checkMissionCompletionStats(
        prefs: prefs,
        damageTaken: 15.0,
        fuelPercentRemaining: 0.3,
        missionSeconds: 50.0,
        coinsCollected: 2,
        isSuccess: true,
        mapId: 'orbit',
      );
      expect(zeroGMaster.isUnlocked, isFalse);

      // Orbit without damage -> unlocks!
      manager.checkMissionCompletionStats(
        prefs: prefs,
        damageTaken: 0.0,
        fuelPercentRemaining: 0.3,
        missionSeconds: 50.0,
        coinsCollected: 2,
        isSuccess: true,
        mapId: 'orbit',
      );
      expect(zeroGMaster.isUnlocked, isTrue);
    });

    test('12. Cosmic tycoon unlocks when coins >= 3000', () {
      final tycoon = manager.achievements.firstWhere((a) => a.id == 'cosmic_tycoon');
      expect(tycoon.isUnlocked, isFalse);

      manager.checkCoins(2999, prefs);
      expect(tycoon.isUnlocked, isFalse);

      manager.checkCoins(3000, prefs);
      expect(tycoon.isUnlocked, isTrue);
    });

    test('Achievements data tampering resets state to legitimate defaults', () async {
      final ach = manager.achievements.firstWhere((a) => a.id == 'soft_landing');
      ach.isUnlocked = true;
      await manager.save(prefs);

      // Manipulate achievements_data directly in preferences with invalid signature
      await prefs.setString(
        'achievements_data',
        '[{"id":"soft_landing","progress":1,"isUnlocked":true},{"id":"fleet_admiral","progress":1,"isUnlocked":true}]',
      );
      // Alter signature to corrupt string
      await prefs.setString(SaveSecurityManager.achievementsSignatureKey, 'tampered_signature_xyz');

      // Reload
      await manager.load(prefs);

      // Should have safely reset
      final reloadedSoft = manager.achievements.firstWhere((a) => a.id == 'soft_landing');
      final reloadedFleet = manager.achievements.firstWhere((a) => a.id == 'fleet_admiral');
      expect(reloadedSoft.isUnlocked, isFalse);
      expect(reloadedFleet.isUnlocked, isFalse);
    });
  });
}
