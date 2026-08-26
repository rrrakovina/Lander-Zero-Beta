import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lander_zero/game/audio/game_audio_manager.dart';
import 'package:lander_zero/game/components/cargo_capsule.dart';
import 'package:lander_zero/game/components/endless_cargo_data.dart';
import 'package:lander_zero/game/components/endless_cave_manager.dart';
import 'package:lander_zero/game/lander_zero_game.dart';
import 'package:lander_zero/game/state/game_state.dart';
import 'package:lander_zero/ui/screens/map_select_screen.dart';

Widget createTestApp(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    GameAudioManager.isTesting = true;
    await GameState().init(force: true);
  });

  group('Procedural Endless Cargo & Generator Tests', () {
    test('EndlessCargoGenerator generates diverse cargo archetypes, rarities and serial codes', () {
      final rand = Random(12345);
      final Set<CargoType> observedArchetypes = {};
      final Set<EndlessCargoRarity> observedRarities = {};
      final Set<EndlessCargoModifier> observedModifiers = {};
      final Set<String> observedSerials = {};

      for (int i = 0; i < 50; i++) {
        final cargo = EndlessCargoGenerator.generate(
          distanceMeters: i * 50.0,
          random: rand,
          chunkIndex: i,
        );

        observedArchetypes.add(cargo.archetype);
        observedRarities.add(cargo.rarity);
        observedModifiers.add(cargo.modifier);
        observedSerials.add(cargo.serialCode);

        expect(cargo.serialCode.length, greaterThanOrEqualTo(6));
        expect(cargo.totalScore, greaterThanOrEqualTo(1000));
        expect(cargo.totalCoins, greaterThanOrEqualTo(100));
      }

      // Verifies variety across generations
      expect(observedArchetypes.length, greaterThanOrEqualTo(3));
      expect(observedRarities.length, greaterThanOrEqualTo(3));
      expect(observedModifiers.length, greaterThanOrEqualTo(3));
      expect(observedSerials.length, equals(50)); // Unique serials
    });

    test('Rarity multipliers accurately scale total score and coins', () {
      const standard = EndlessCargoInfo(
        archetype: CargoType.rescuePod,
        rarity: EndlessCargoRarity.standard,
        modifier: EndlessCargoModifier.none,
        serialCode: 'POD-100',
        baseScore: 1000,
        baseCoins: 100,
      );
      expect(standard.totalScore, equals(1000));
      expect(standard.totalCoins, equals(100));

      const highValue = EndlessCargoInfo(
        archetype: CargoType.titaniumCrate,
        rarity: EndlessCargoRarity.highValue,
        modifier: EndlessCargoModifier.none,
        serialCode: 'VALT-200',
        baseScore: 1000,
        baseCoins: 100,
      );
      expect(highValue.totalScore, equals(1500));
      expect(highValue.totalCoins, equals(150));

      const relic = EndlessCargoInfo(
        archetype: CargoType.energyCrystal,
        rarity: EndlessCargoRarity.relic,
        modifier: EndlessCargoModifier.none,
        serialCode: 'CORE-500',
        baseScore: 1000,
        baseCoins: 100,
      );
      expect(relic.totalScore, equals(5000));
      expect(relic.totalCoins, equals(500));
    });

    test('Title generation formats localized serial code and rarity properly', () {
      const cargo = EndlessCargoInfo(
        archetype: CargoType.titaniumCrate,
        rarity: EndlessCargoRarity.prototype,
        modifier: EndlessCargoModifier.magnetic,
        serialCode: 'VALT-707',
        baseScore: 1000,
        baseCoins: 100,
      );

      expect(cargo.getTitle('ru'), contains('[VALT-707]'));
      expect(cargo.getTitle('ru'), contains('Титановый Сейф'));
      expect(cargo.getTitle('ru'), contains('Прототип'));

      expect(cargo.getTitle('en'), contains('[VALT-707]'));
      expect(cargo.getTitle('en'), contains('Titanium Vault'));
      expect(cargo.getTitle('en'), contains('Prototype'));
    });
  });

  group('EndlessCaveManager Procedural World & Outpost Tests', () {
    test('EndlessCaveManager initializes initial chunks and tracks dynamic biomes', () {
      final game = LanderZeroGame(mapId: 'endless');
      final manager = EndlessCaveManager();
      game.world.add(manager);

      expect(manager.getCurrentBiomeName('ru'), contains('Заброшенные Шахты'));
      expect(manager.getCurrentBiomeName('en'), contains('Abandoned Mines'));

      expect(manager.endlessScore, equals(0));
      expect(manager.rescuesCount, equals(0));
    });
  });

  group('GameState Endless Mode Statistics & HMAC Persistence Tests', () {
    test('Fresh install initializes zero endless statistics', () {
      final state = GameState();
      expect(state.endlessBestDistance, equals(0));
      expect(state.endlessHighScore, equals(0));
      expect(state.endlessTotalRescues, equals(0));
    });

    test('recordEndlessRun records new best distance and accumulates rescues', () async {
      final state = GameState();

      final isNew1 = await state.recordEndlessRun(distance: 450, score: 5500, rescues: 2);
      expect(isNew1, isTrue);
      expect(state.endlessBestDistance, equals(450));
      expect(state.endlessHighScore, equals(5500));
      expect(state.endlessTotalRescues, equals(2));

      // Shorter run does not override best distance, but accumulates rescues
      final isNew2 = await state.recordEndlessRun(distance: 300, score: 3200, rescues: 1);
      expect(isNew2, isFalse);
      expect(state.endlessBestDistance, equals(450));
      expect(state.endlessHighScore, equals(5500));
      expect(state.endlessTotalRescues, equals(3));

      // Re-initializing GameState from SharedPreferences restores records
      await GameState().init(force: true);
      expect(GameState().endlessBestDistance, equals(450));
      expect(GameState().endlessHighScore, equals(5500));
      expect(GameState().endlessTotalRescues, equals(3));
    });

    test('Endless mode translations exist in both Russian and English dictionaries', () {
      final state = GameState();

      state.setLanguage('ru');
      expect(state.translate('endless_title'), equals('ЭКСПЕДИЦИЯ: БЕЗДНА'));
      expect(state.translate('endless_best_dist'), equals('Рекорд глубины'));
      expect(state.translate('endless_high_score'), equals('Рекорд очков'));
      expect(state.translate('endless_rescues'), equals('Спасено выживших'));

      state.setLanguage('en');
      expect(state.translate('endless_title'), equals('ENDLESS EXPEDITION'));
      expect(state.translate('endless_best_dist'), equals('Best Depth'));
      expect(state.translate('endless_high_score'), equals('High Score'));
      expect(state.translate('endless_rescues'), equals('Total Rescued'));
    });
  });

  group('MapSelectScreen Endless Card Integration Tests', () {
    testWidgets('MapSelectScreen displays Endless Rescue Sector card and opens briefing', (tester) async {
      tester.view.physicalSize = const Size(3200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final state = GameState();
      await state.recordEndlessRun(distance: 850, score: 9200, rescues: 4);

      await tester.pumpWidget(createTestApp(
        MapSelectWidget(
          onMapSelected: (_) {},
          onBack: () {},
        ),
      ));

      for (int i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Verifies Endless card is present
      final endlessCardTitle = find.text('Бесконечный Сектор');
      expect(endlessCardTitle, findsOneWidget);

      // Tap on Endless card to open briefing preview
      await tester.tap(endlessCardTitle);
      for (int i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('850 м'), findsOneWidget); // Shows personal best depth
    });
  });
}