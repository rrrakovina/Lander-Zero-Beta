import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lander_zero/game/state/game_state.dart';
import 'package:lander_zero/game/state/achievements_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Achievements System Unit Tests', () {
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

    test('Default achievements are loaded properly', () {
      expect(manager.achievements.length, 5);
      expect(manager.achievements.any((a) => a.id == 'soft_landing'), isTrue);
      expect(manager.achievements.any((a) => a.id == 'eco_pilot'), isTrue);
      expect(manager.achievements.any((a) => a.id == 'speed_rescue'), isTrue);
      expect(manager.achievements.any((a) => a.id == 'treasure_hunter'), isTrue);
      expect(manager.achievements.any((a) => a.id == 'cave_veteran'), isTrue);
    });

    test('Soft landing unlock on zero damage', () {
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

    test('Eco pilot unlock when fuel remaining > 50%', () {
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

    test('Speed rescue unlock when duration <= 45s', () {
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

    test('Cave veteran increments and unlocks on 5th success', () {
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
  });
}
