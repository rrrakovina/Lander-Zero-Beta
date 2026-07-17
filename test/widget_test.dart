import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lander_zero/game/state/game_state.dart';
import 'package:lander_zero/game/audio/game_audio_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameState Unit Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      GameAudioManager.isTesting = true;
      await GameState().init(force: true);
    });

    test('Initialization works and sets default values', () async {
      final state = GameState();

      expect(state.initialized, isTrue);
      expect(state.nickname, isEmpty);
      expect(state.language, equals('ru'));
      expect(state.musicVolume, equals(0.7));
      expect(state.sfxVolume, equals(0.8));
      expect(state.totalCoins, equals(0));
      expect(state.selectedRocket, equals('sputnik'));
      expect(state.ownedRockets, equals(['sputnik']));
      expect(state.engineLevel, equals(1));
      expect(state.fuelLevel, equals(1));
      expect(state.shieldLevel, equals(1));
      expect(state.leaderboard, isEmpty);
    });

    test('setNickname modifies the state and notifies listeners', () async {
      final state = GameState();
      await state.init();

      int calls = 0;
      state.addListener(() => calls++);

      await state.setNickname('  StarLord  ');
      expect(state.nickname, equals('StarLord'));
      expect(calls, equals(1));
    });

    test('setLanguage translates correctly', () async {
      final state = GameState();
      await state.init();

      await state.setLanguage('en');
      expect(state.language, equals('en'));
      expect(state.translate('play'), equals('PLAY'));

      await state.setLanguage('ru');
      expect(state.language, equals('ru'));
      expect(state.translate('play'), equals('ИГРАТЬ'));
    });

    test('setMusicVolume and setSfxVolume clamps values', () async {
      final state = GameState();
      await state.init();

      await state.setMusicVolume(1.5);
      expect(state.musicVolume, equals(1.0));

      await state.setMusicVolume(-0.5);
      expect(state.musicVolume, equals(0.0));

      await state.setSfxVolume(0.5);
      expect(state.sfxVolume, equals(0.5));
    });

    test('addCoins and canAfford check balance', () async {
      final state = GameState();
      await state.init();

      expect(state.canAfford(100), isFalse);
      await state.addCoins(100);
      expect(state.totalCoins, equals(100));
      expect(state.canAfford(100), isTrue);
      expect(state.canAfford(101), isFalse);
    });

    test('buyRocket purchases owned/unowned rockets and charges coins', () async {
      final state = GameState();
      await state.init();

      // Цена Cyclone = 800
      expect(await state.buyRocket('cyclone'), isFalse);

      await state.addCoins(1000);
      expect(await state.buyRocket('cyclone'), isTrue);
      expect(state.totalCoins, equals(200));
      expect(state.ownedRockets, contains('cyclone'));
      expect(state.selectedRocket, equals('cyclone'));

      // Повторная покупка уже купленного не должна тратить монеты
      expect(await state.buyRocket('cyclone'), isTrue);
      expect(state.totalCoins, equals(200));
    });

    test('selectRocket switches active vessel', () async {
      final state = GameState();
      await state.init();

      // Нельзя выбрать то, чем не владеем
      await state.selectRocket('needle');
      expect(state.selectedRocket, equals('sputnik'));

      // Даем монеты и покупаем Needle
      await state.addCoins(2000);
      expect(await state.buyRocket('needle'), isTrue);
      expect(state.selectedRocket, equals('needle'));

      // Переключаемся обратно на Sputnik
      await state.selectRocket('sputnik');
      expect(state.selectedRocket, equals('sputnik'));
    });

    test('upgradeStat increases stat levels sequentially costing coins', () async {
      final state = GameState();
      await state.init();

      // L1->L2: 150 * 2^0 = 150
      expect(await state.upgradeStat('engine'), isFalse);
      await state.addCoins(150);
      expect(await state.upgradeStat('engine'), isTrue);
      expect(state.engineLevel, equals(2));
      expect(state.totalCoins, equals(0));

      // L2->L3: 150 * 2^1 = 300
      await state.addCoins(300);
      expect(await state.upgradeStat('engine'), isTrue);
      expect(state.engineLevel, equals(3));

      // Прокачиваем до максимума (L3->L4->L5)
      await state.addCoins(600 + 1200);
      expect(await state.upgradeStat('engine'), isTrue); // L4
      expect(await state.upgradeStat('engine'), isTrue); // L5
      expect(state.engineLevel, equals(5));

      // Максимальный уровень больше не прокачивается
      expect(await state.upgradeStat('engine'), isFalse);
    });

    test('addRecord updates and sorts leaderboard', () async {
      final state = GameState();
      await state.init();
      await state.setNickname('Ace');

      await state.addRecord(100.0, 5, 'echo');
      await state.addRecord(250.0, 15, 'wind');
      await state.addRecord(50.0, 2, 'core');

      expect(state.leaderboard.length, equals(3));
      
      // Проверяем сортировку (по убыванию дистанции)
      expect(state.leaderboard[0]['distance'], equals(250));
      expect(state.leaderboard[1]['distance'], equals(100));
      expect(state.leaderboard[2]['distance'], equals(50));
      
      // Лимит топ-10 записей
      for (int i = 0; i < 15; i++) {
        await state.addRecord(10.0 + i, 1, 'echo');
      }
      expect(state.leaderboard.length, equals(10));
      expect(state.leaderboard.first['distance'], equals(250));
    });
  });
}
