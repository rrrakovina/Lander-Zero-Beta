import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lander_zero/game/audio/game_audio_manager.dart';
import 'package:lander_zero/game/state/game_state.dart';
import 'package:lander_zero/ui/screens/main_menu_screen.dart';
import 'package:lander_zero/ui/screens/map_select_screen.dart';
import 'package:lander_zero/ui/dialogs/achievements_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pilot Ranking System Unit Tests', () {
    test('Cadet rank tier when beginner conditions are met', () {
      final rank = PilotRankingInfo.calculate(
        unlockedAchievementsCount: 0,
        totalUpgradeLevels: 3, // 1 + 1 + 1
        ownedShipsCount: 1,
        totalCoins: 0,
        completedRecordsCount: 0,
      );

      expect(rank.tier, equals(PilotRankTier.cadet));
      expect(rank.titleRu, equals('Кадет'));
      expect(rank.titleEn, equals('Cadet'));
      expect(rank.badgeTextRu, equals('РАНГ: КАДЕТ'));
      expect(rank.badgeTextEn, equals('RANK: CADET'));
      expect(rank.icon, equals(Icons.school_rounded));
    });

    test('Pilot rank tier when 1 achievement or upgrade threshold is met', () {
      final rankByAch = PilotRankingInfo.calculate(
        unlockedAchievementsCount: 1,
        totalUpgradeLevels: 3,
        ownedShipsCount: 1,
        totalCoins: 0,
        completedRecordsCount: 0,
      );
      expect(rankByAch.tier, equals(PilotRankTier.pilot));
      expect(rankByAch.badgeTextRu, equals('РАНГ: ПИЛОТ'));
      expect(rankByAch.badgeTextEn, equals('RANK: PILOT'));

      final rankByUpgrades = PilotRankingInfo.calculate(
        unlockedAchievementsCount: 0,
        totalUpgradeLevels: 4,
        ownedShipsCount: 1,
        totalCoins: 0,
        completedRecordsCount: 0,
      );
      expect(rankByUpgrades.tier, equals(PilotRankTier.pilot));

      final rankByCoins = PilotRankingInfo.calculate(
        unlockedAchievementsCount: 0,
        totalUpgradeLevels: 3,
        ownedShipsCount: 1,
        totalCoins: 150,
        completedRecordsCount: 0,
      );
      expect(rankByCoins.tier, equals(PilotRankTier.pilot));
    });

    test('Officer rank tier when 2 achievements or 7 upgrades or 2 ships owned', () {
      final rankByAch = PilotRankingInfo.calculate(
        unlockedAchievementsCount: 2,
        totalUpgradeLevels: 3,
        ownedShipsCount: 1,
        totalCoins: 0,
        completedRecordsCount: 0,
      );
      expect(rankByAch.tier, equals(PilotRankTier.officer));
      expect(rankByAch.badgeTextRu, equals('РАНГ: ОФИЦЕР'));
      expect(rankByAch.badgeTextEn, equals('RANK: OFFICER'));

      final rankByShips = PilotRankingInfo.calculate(
        unlockedAchievementsCount: 0,
        totalUpgradeLevels: 3,
        ownedShipsCount: 2,
        totalCoins: 0,
        completedRecordsCount: 0,
      );
      expect(rankByShips.tier, equals(PilotRankTier.officer));

      final rankByUpgrades = PilotRankingInfo.calculate(
        unlockedAchievementsCount: 0,
        totalUpgradeLevels: 7,
        ownedShipsCount: 1,
        totalCoins: 0,
        completedRecordsCount: 0,
      );
      expect(rankByUpgrades.tier, equals(PilotRankTier.officer));
    });

    test('Veteran rank tier when 3 achievements or 10 upgrades or 3 ships owned', () {
      final rankByAch = PilotRankingInfo.calculate(
        unlockedAchievementsCount: 3,
        totalUpgradeLevels: 3,
        ownedShipsCount: 1,
        totalCoins: 0,
        completedRecordsCount: 0,
      );
      expect(rankByAch.tier, equals(PilotRankTier.veteran));
      expect(rankByAch.badgeTextRu, equals('РАНГ: ВЕТЕРАН'));
      expect(rankByAch.badgeTextEn, equals('RANK: VETERAN'));

      final rankByUpgrades = PilotRankingInfo.calculate(
        unlockedAchievementsCount: 0,
        totalUpgradeLevels: 10,
        ownedShipsCount: 1,
        totalCoins: 0,
        completedRecordsCount: 0,
      );
      expect(rankByUpgrades.tier, equals(PilotRankTier.veteran));

      final rankByShips = PilotRankingInfo.calculate(
        unlockedAchievementsCount: 0,
        totalUpgradeLevels: 3,
        ownedShipsCount: 3,
        totalCoins: 0,
        completedRecordsCount: 0,
      );
      expect(rankByShips.tier, equals(PilotRankTier.veteran));
    });

    test('Commander rank tier when 4+ achievements or 13+ upgrades or veteran combo', () {
      final rankByAch = PilotRankingInfo.calculate(
        unlockedAchievementsCount: 4,
        totalUpgradeLevels: 3,
        ownedShipsCount: 1,
        totalCoins: 0,
        completedRecordsCount: 0,
      );
      expect(rankByAch.tier, equals(PilotRankTier.commander));
      expect(rankByAch.badgeTextRu, equals('РАНГ: КОМАНДОР'));
      expect(rankByAch.badgeTextEn, equals('RANK: COMMANDER'));
      expect(rankByAch.icon, equals(Icons.workspace_premium_rounded));

      final rankByUpgrades = PilotRankingInfo.calculate(
        unlockedAchievementsCount: 0,
        totalUpgradeLevels: 13,
        ownedShipsCount: 1,
        totalCoins: 0,
        completedRecordsCount: 0,
      );
      expect(rankByUpgrades.tier, equals(PilotRankTier.commander));

      final rankByCombo = PilotRankingInfo.calculate(
        unlockedAchievementsCount: 3,
        totalUpgradeLevels: 9,
        ownedShipsCount: 3,
        totalCoins: 0,
        completedRecordsCount: 0,
      );
      expect(rankByCombo.tier, equals(PilotRankTier.commander));
    });
  });

  group('Main Menu Screen Widget Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      GameAudioManager.isTesting = true;
      await GameState().init(force: true);
    });

    testWidgets('Main menu renders header, telemetry indicators, dynamic rank, and buttons', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool playTapped = false;
      bool garageTapped = false;
      bool recordsTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MainMenuWidget(
              onPlay: () => playTapped = true,
              onGarage: () => garageTapped = true,
              onLeaderboard: () => recordsTapped = true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Check title and division
      expect(find.text('LANDER ZERO: СПАСЕНИЕ'), findsOneWidget);
      expect(find.text('КОСМИЧЕСКАЯ СПАСАТЕЛЬНАЯ СЛУЖБА'), findsOneWidget);

      // Check dynamic rank badge (Officer by default with 2 starter ships)
      expect(find.text('РАНГ: ОФИЦЕР'), findsOneWidget);

      // Check sci-fi telemetry indicators
      expect(find.text('ТЕЛЕМЕТРИЯ: АКТИВНА'), findsOneWidget);
      expect(find.text('СВЯЗЬ: 99.8%'), findsOneWidget);
      expect(find.textContaining('ГОТОВНОСТЬ:'), findsOneWidget);

      // Check navigation buttons
      expect(find.text('ИГРАТЬ'), findsOneWidget);
      expect(find.text('ГАРАЖ'), findsOneWidget);
      expect(find.text('РЕКОРДЫ'), findsOneWidget);
      expect(find.text('ДОСТИЖЕНИЯ'), findsOneWidget);

      // Test callbacks
      await tester.tap(find.text('ИГРАТЬ'));
      expect(playTapped, isTrue);

      await tester.tap(find.text('ГАРАЖ'));
      expect(garageTapped, isTrue);

      await tester.tap(find.text('РЕКОРДЫ'));
      expect(recordsTapped, isTrue);

      // Test achievements modal dialog trigger
      await tester.tap(find.text('ДОСТИЖЕНИЯ'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(AchievementsDialog), findsOneWidget);
      expect(find.text('Мягкая посадка'), findsOneWidget);
    });

    testWidgets('Main menu dynamic ranking updates when stats or achievements change', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = GameState();
      // Upgrade stats to reach Commander tier (13+ total levels: 5 + 5 + 4 = 14)
      await state.addCoins(10000);
      await state.upgradeStat('engine'); // 2
      await state.upgradeStat('engine'); // 3
      await state.upgradeStat('engine'); // 4
      await state.upgradeStat('engine'); // 5
      await state.upgradeStat('fuel');   // 2
      await state.upgradeStat('fuel');   // 3
      await state.upgradeStat('fuel');   // 4
      await state.upgradeStat('fuel');   // 5
      await state.upgradeStat('shield'); // 2
      await state.upgradeStat('shield'); // 3
      await state.upgradeStat('shield'); // 4 (total: 5 + 5 + 4 = 14)

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MainMenuWidget(
              onPlay: () {},
              onGarage: () {},
              onLeaderboard: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Should now be Commander
      expect(find.text('РАНГ: КОМАНДОР'), findsOneWidget);
      // Systems readiness should be 97% or 100%
      expect(find.textContaining('ГОТОВНОСТЬ:'), findsOneWidget);
    });

    testWidgets('Language switch translates Main Menu to English and back', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MainMenuWidget(
              onPlay: () {},
              onGarage: () {},
              onLeaderboard: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Switch language to EN
      await tester.tap(find.text('EN'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('LANDER ZERO: RESCUE OPS'), findsOneWidget);
      expect(find.text('COSMIC RESCUE DIVISION'), findsOneWidget);
      expect(find.text('PLAY'), findsOneWidget);
      expect(find.text('GARAGE'), findsOneWidget);
      expect(find.text('HIGHSCORES'), findsOneWidget);
      expect(find.text('ACHIEVEMENTS'), findsOneWidget);
      expect(find.text('RANK: OFFICER'), findsOneWidget);
      expect(find.text('TELEMETRY: ACTIVE'), findsOneWidget);
      expect(find.text('LINK: 99.8%'), findsOneWidget);
      expect(find.textContaining('SYS READY:'), findsOneWidget);

      // Switch back to RU
      await tester.tap(find.text('RU'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('LANDER ZERO: СПАСЕНИЕ'), findsOneWidget);
      expect(find.text('КОСМИЧЕСКАЯ СПАСАТЕЛЬНАЯ СЛУЖБА'), findsOneWidget);
      expect(find.text('ИГРАТЬ'), findsOneWidget);
      expect(find.text('РАНГ: ОФИЦЕР'), findsOneWidget);
    });
  });

  group('Map Select Screen Widget Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      GameAudioManager.isTesting = true;
      await GameState().init(force: true);
    });

    testWidgets('Map selection cards render all maps with telemetry and parameters', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool backTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapSelectWidget(
              onBack: () => backTapped = true,
              onMapSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('ВЫБОР КАРТЫ'), findsOneWidget);

      // Verify 3 location cards
      expect(find.text('Каньон Эхо'), findsOneWidget);
      expect(find.text('Солнечные Ветра'), findsOneWidget);
      expect(find.text('Глубинное Ядро'), findsOneWidget);

      // Verify card parameters
      expect(find.text('ЛЕГКО'), findsOneWidget);
      expect(find.text('СРЕДНЕ'), findsOneWidget);
      expect(find.text('СЛОЖНО'), findsOneWidget);

      expect(find.text('1.0x (3.5 м/с²)'), findsNWidgets(2)); // echo and wind
      expect(find.text('1.5x (5.3 м/с² - Тяжелое ядро)'), findsOneWidget); // core

      // Test back button
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      expect(backTapped, isTrue);
    });

    testWidgets('Location Preview screen shows detailed environmental hazards & rewards breakdown', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? chosenMap;
      await GameState().processMissionVictory('echo', remainingFuelPercent: 80, damagePercent: 0, coinsEarned: 100);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapSelectWidget(
              onBack: () {},
              onMapSelected: (map) => chosenMap = map,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on Solar Winds map
      await tester.tap(find.text('Солнечные Ветра'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('ПРЕДПРОСМОТР ЛОКАЦИИ'), findsOneWidget);
      expect(find.text('СВЯЗЬ: ПОМЕХИ В КАНАЛЕ'), findsOneWidget);

      // Check Environmental Hazard Telemetry
      expect(find.text('ТЕЛЕМЕТРИЯ СРЕДЫ И АНОМАЛИЙ'), findsOneWidget);
      expect(find.text('-4.5 Н (Боковой снос влево)'), findsWidgets);
      expect(find.text('-120°C (Криогенная плазма)'), findsOneWidget);
      expect(find.text('18.4 мЗв (Солнечные вспышки)'), findsOneWidget);
      expect(find.text('Класс 1 (Микрометеориты)'), findsOneWidget);

      // Check Mission Rewards Breakdown
      expect(find.text('НАГРАДЫ И БОНУСЫ ЗА МИССИЮ'), findsOneWidget);
      expect(find.text('300 - 600 монет'), findsWidgets);
      expect(find.text('+100 🪙'), findsNWidgets(2)); // base extraction & soft landing
      expect(find.text('+120 🪙'), findsOneWidget); // speed rescue
      expect(find.text('+80 🪙'), findsOneWidget); // eco pilot

      // Check Cavern Diagnostics
      expect(find.text('ТАКТИЧЕСКИЙ АНАЛИЗ'), findsOneWidget);
      expect(find.text('Игла-52 (Маневренность / Мин. лобовое сопротивление)'), findsOneWidget);

      // Test Launch Button
      await tester.tap(find.text('В ПУТЬ'));
      expect(chosenMap, equals('wind'));
    });

    testWidgets('Location Preview screen works in English mode with full telemetry', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await GameState().setLanguage('en');
      await GameState().processMissionVictory('echo', remainingFuelPercent: 80, damagePercent: 0, coinsEarned: 100);
      await GameState().processMissionVictory('wind', remainingFuelPercent: 80, damagePercent: 0, coinsEarned: 100);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapSelectWidget(
              onBack: () {},
              onMapSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('SELECT MAP'), findsOneWidget);
      expect(find.text('Echo Canyon'), findsOneWidget);
      expect(find.text('Solar Winds'), findsOneWidget);
      expect(find.text('Deep Core'), findsOneWidget);

      // Tap on Deep Core
      await tester.tap(find.text('Deep Core'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('LOCATION PREVIEW'), findsOneWidget);
      expect(find.text('COMM STATUS: CRITICAL'), findsOneWidget);
      expect(find.text('ENVIRONMENTAL HAZARD TELEMETRY'), findsOneWidget);
      expect(find.text('MISSION REWARDS & CRITERIA'), findsOneWidget);

      // Verify Deep Core telemetry parameters
      expect(find.text('+850°C (Magma Thermal Venting)'), findsOneWidget);
      expect(find.text('94.2 mSv (Gamma Core Flux)'), findsOneWidget);
      expect(find.text('Class 4 (Tectonic Tremors)'), findsOneWidget);
      expect(find.text('Cyclone (Reinforced Armor & Heavy Thrust)'), findsOneWidget);
      expect(find.text('600+ coins'), findsWidgets);

      expect(find.text('LAUNCH MISSION'), findsOneWidget);
    });
  });
}
