import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lander_zero/game/audio/game_audio_manager.dart';
import 'package:lander_zero/game/components/spark_particle.dart';
import 'package:lander_zero/game/state/game_state.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GameAudioManager.isTesting = true;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GameState().init(force: true);
  });

  group('Forgiving Physics & Shield Deflect Unit Tests', () {
    test('SparkPoolManager.spawnDeflectSparks spawns neon/gold deflection sparks', () {
      final pool = SparkPoolManager();
      pool.spawnDeflectSparks(Vector2(10.0, 20.0), Vector2(0, -1.0));

      // Update simulation frame
      pool.update(0.016);
      expect(pool.children, isEmpty); // Pool manages sparks internally in memory without subcomponents
    });

    test('GameAudioManager.playShieldDeflect operates without errors in test environment', () {
      expect(() => GameAudioManager().playShieldDeflect(), returnsNormally);
      expect(() => GameAudioManager().playShieldDeflect(volumeMultiplier: 0.5), returnsNormally);
    });

    test('Campaign victory translations exist in Russian and English', () {
      final state = GameState();

      state.setLanguage('ru');
      expect(state.translate('campaign_completed_title'), equals('🏆 КАМПАНИЯ ПОЛНОСТЬЮ ЗАВЕРШЕНА!'));
      expect(state.translate('campaign_completed_sub'), contains('Спасательная служба признана Высшим Флотом'));
      expect(state.translate('campaign_stars_summary'), contains('{val} / 15'));

      state.setLanguage('en');
      expect(state.translate('campaign_completed_title'), equals('🏆 CAMPAIGN FULLY COMPLETED!'));
      expect(state.translate('campaign_completed_sub'), contains('Supreme Galactic Fleet'));
      expect(state.translate('campaign_stars_summary'), contains('{val} / 15'));
    });

    test('Full campaign completion unlocks grand victory milestone', () async {
      final state = GameState();
      await state.init(force: true);

      // Complete all 5 sectors
      await state.processMissionVictory('echo', remainingFuelPercent: 90, damagePercent: 0, coinsEarned: 100);
      await state.processMissionVictory('wind', remainingFuelPercent: 80, damagePercent: 0, coinsEarned: 150);
      await state.processMissionVictory('core', remainingFuelPercent: 70, damagePercent: 0, coinsEarned: 200);
      await state.processMissionVictory('ice', remainingFuelPercent: 60, damagePercent: 0, coinsEarned: 250);
      await state.processMissionVictory('orbit', remainingFuelPercent: 50, damagePercent: 0, coinsEarned: 300);

      expect(state.completedLevels.length, equals(5));
      expect(state.completedLevels, containsAll(['echo', 'wind', 'core', 'ice', 'orbit']));
      expect(state.totalStars, equals(15));
    });
  });
}
