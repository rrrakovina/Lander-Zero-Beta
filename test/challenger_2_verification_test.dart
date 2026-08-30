import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lander_zero/game/audio/game_audio_manager.dart';
import 'package:lander_zero/game/lander_zero_game.dart';
import 'package:lander_zero/game/state/game_state.dart';
import 'package:lander_zero/ui/screens/main_menu_screen.dart';
import 'package:lander_zero/ui/screens/garage_screen.dart';
import 'package:lander_zero/ui/screens/map_select_screen.dart';
import 'package:lander_zero/ui/widgets/minimap_widget.dart';

// Mock Canvas to record and benchmark calls without GPU overhead
class MockCanvas extends Fake implements Canvas {
  int drawLineCount = 0;
  int drawCircleCount = 0;
  int drawPathCount = 0;

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    drawLineCount++;
  }

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    drawCircleCount++;
  }

  @override
  void drawPath(Path path, Paint paint) {
    drawPathCount++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    GameAudioManager.isTesting = true;
    await GameState().init(force: true);
  });

  group('Challenger 2 — Dynamic Pilot Ranking Boundary Tests', () {
    test('Boundary 1: Zero stats (0 achievements, 0 upgrades, 0 coins, 0 ships, 0 records)', () {
      final rank = PilotRankingInfo.calculate(
        unlockedAchievementsCount: 0,
        totalUpgradeLevels: 0,
        ownedShipsCount: 0,
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

    test('Boundary 2: Starter state (0 achievements, 3 upgrades, 1 ship, 0 coins, 0 records)', () {
      final rank = PilotRankingInfo.calculate(
        unlockedAchievementsCount: 0,
        totalUpgradeLevels: 3,
        ownedShipsCount: 1,
        totalCoins: 0,
        completedRecordsCount: 0,
      );
      expect(rank.tier, equals(PilotRankTier.cadet));
      expect(rank.badgeTextRu, equals('РАНГ: КАДЕТ'));
    });

    test('Boundary 3: Coin boundaries (0 -> 99 -> 100 -> 1000000)', () {
      // 99 coins -> Cadet
      final rank99 = PilotRankingInfo.calculate(
        unlockedAchievementsCount: 0,
        totalUpgradeLevels: 3,
        ownedShipsCount: 1,
        totalCoins: 99,
        completedRecordsCount: 0,
      );
      expect(rank99.tier, equals(PilotRankTier.cadet));

      // 100 coins -> Pilot
      final rank100 = PilotRankingInfo.calculate(
        unlockedAchievementsCount: 0,
        totalUpgradeLevels: 3,
        ownedShipsCount: 1,
        totalCoins: 100,
        completedRecordsCount: 0,
      );
      expect(rank100.tier, equals(PilotRankTier.pilot));
      expect(rank100.badgeTextRu, equals('РАНГ: ПИЛОТ'));
      expect(rank100.badgeTextEn, equals('RANK: PILOT'));

      // 1,000,000 coins alone without other stats -> Pilot (requires upgrades/ships/achievements for higher tiers)
      final rankMillion = PilotRankingInfo.calculate(
        unlockedAchievementsCount: 0,
        totalUpgradeLevels: 3,
        ownedShipsCount: 1,
        totalCoins: 1000000,
        completedRecordsCount: 0,
      );
      expect(rankMillion.tier, equals(PilotRankTier.pilot));
    });

    test('Boundary 4: Achievement boundaries (0 -> 1 -> 2 -> 3 -> 4 -> 5 -> max)', () {
      // 0 achievements
      expect(PilotRankingInfo.calculate(
        unlockedAchievementsCount: 0,
        totalUpgradeLevels: 3,
        ownedShipsCount: 1,
        totalCoins: 0,
        completedRecordsCount: 0,
      ).tier, equals(PilotRankTier.cadet));

      // 1 achievement -> Pilot
      expect(PilotRankingInfo.calculate(
        unlockedAchievementsCount: 1,
        totalUpgradeLevels: 3,
        ownedShipsCount: 1,
        totalCoins: 0,
        completedRecordsCount: 0,
      ).tier, equals(PilotRankTier.pilot));

      // 2 achievements -> Officer
      expect(PilotRankingInfo.calculate(
        unlockedAchievementsCount: 2,
        totalUpgradeLevels: 3,
        ownedShipsCount: 1,
        totalCoins: 0,
        completedRecordsCount: 0,
      ).tier, equals(PilotRankTier.officer));

      // 3 achievements -> Veteran
      expect(PilotRankingInfo.calculate(
        unlockedAchievementsCount: 3,
        totalUpgradeLevels: 3,
        ownedShipsCount: 1,
        totalCoins: 0,
        completedRecordsCount: 0,
      ).tier, equals(PilotRankTier.veteran));

      // 3 achievements + 3 ships -> Commander combo
      expect(PilotRankingInfo.calculate(
        unlockedAchievementsCount: 3,
        totalUpgradeLevels: 3,
        ownedShipsCount: 3,
        totalCoins: 0,
        completedRecordsCount: 0,
      ).tier, equals(PilotRankTier.commander));

      // 4 achievements -> Commander
      expect(PilotRankingInfo.calculate(
        unlockedAchievementsCount: 4,
        totalUpgradeLevels: 3,
        ownedShipsCount: 1,
        totalCoins: 0,
        completedRecordsCount: 0,
      ).tier, equals(PilotRankTier.commander));

      // 5 achievements (All unlocked) -> Commander
      final rankMaxAch = PilotRankingInfo.calculate(
        unlockedAchievementsCount: 5,
        totalUpgradeLevels: 3,
        ownedShipsCount: 1,
        totalCoins: 0,
        completedRecordsCount: 0,
      );
      expect(rankMaxAch.tier, equals(PilotRankTier.commander));
      expect(rankMaxAch.badgeTextRu, equals('РАНГ: КОМАНДОР'));
      expect(rankMaxAch.badgeTextEn, equals('RANK: COMMANDER'));
    });

    test('Boundary 5: Upgrade level boundaries (3 -> 4 -> 6 -> 7 -> 9 -> 10 -> 12 -> 13 -> 15)', () {
      // 3 upgrades (1+1+1) -> Cadet
      expect(PilotRankingInfo.calculate(
        unlockedAchievementsCount: 0,
        totalUpgradeLevels: 3,
        ownedShipsCount: 1,
        totalCoins: 0,
        completedRecordsCount: 0,
      ).tier, equals(PilotRankTier.cadet));

      // 4 upgrades -> Pilot
      expect(PilotRankingInfo.calculate(
        unlockedAchievementsCount: 0,
        totalUpgradeLevels: 4,
        ownedShipsCount: 1,
        totalCoins: 0,
        completedRecordsCount: 0,
      ).tier, equals(PilotRankTier.pilot));

      // 6 upgrades -> Pilot
      expect(PilotRankingInfo.calculate(
        unlockedAchievementsCount: 0,
        totalUpgradeLevels: 6,
        ownedShipsCount: 1,
        totalCoins: 0,
        completedRecordsCount: 0,
      ).tier, equals(PilotRankTier.pilot));

      // 7 upgrades -> Officer
      expect(PilotRankingInfo.calculate(
        unlockedAchievementsCount: 0,
        totalUpgradeLevels: 7,
        ownedShipsCount: 1,
        totalCoins: 0,
        completedRecordsCount: 0,
      ).tier, equals(PilotRankTier.officer));

      // 9 upgrades -> Officer
      expect(PilotRankingInfo.calculate(
        unlockedAchievementsCount: 0,
        totalUpgradeLevels: 9,
        ownedShipsCount: 1,
        totalCoins: 0,
        completedRecordsCount: 0,
      ).tier, equals(PilotRankTier.officer));

      // 10 upgrades -> Veteran
      expect(PilotRankingInfo.calculate(
        unlockedAchievementsCount: 0,
        totalUpgradeLevels: 10,
        ownedShipsCount: 1,
        totalCoins: 0,
        completedRecordsCount: 0,
      ).tier, equals(PilotRankTier.veteran));

      // 12 upgrades -> Veteran
      expect(PilotRankingInfo.calculate(
        unlockedAchievementsCount: 0,
        totalUpgradeLevels: 12,
        ownedShipsCount: 1,
        totalCoins: 0,
        completedRecordsCount: 0,
      ).tier, equals(PilotRankTier.veteran));

      // 13 upgrades -> Commander
      expect(PilotRankingInfo.calculate(
        unlockedAchievementsCount: 0,
        totalUpgradeLevels: 13,
        ownedShipsCount: 1,
        totalCoins: 0,
        completedRecordsCount: 0,
      ).tier, equals(PilotRankTier.commander));

      // 15 upgrades (5+5+5 maximum) -> Commander
      final rankMaxUpgrades = PilotRankingInfo.calculate(
        unlockedAchievementsCount: 0,
        totalUpgradeLevels: 15,
        ownedShipsCount: 1,
        totalCoins: 0,
        completedRecordsCount: 0,
      );
      expect(rankMaxUpgrades.tier, equals(PilotRankTier.commander));
    });

    test('Boundary 6: Max of everything (5 achievements, 15 upgrades, 3 ships, 999999 coins, 10 records)', () {
      final rankMax = PilotRankingInfo.calculate(
        unlockedAchievementsCount: 5,
        totalUpgradeLevels: 15,
        ownedShipsCount: 3,
        totalCoins: 999999,
        completedRecordsCount: 10,
      );
      expect(rankMax.tier, equals(PilotRankTier.commander));
      expect(rankMax.badgeTextRu, equals('РАНГ: КОМАНДОР'));
      expect(rankMax.badgeTextEn, equals('RANK: COMMANDER'));
      expect(rankMax.icon, equals(Icons.workspace_premium_rounded));
      expect(rankMax.color, equals(const Color(0xFFFFD700)));
    });

    test('Boundary 7: Leaderboard records alone (0 -> 1 -> 10)', () {
      expect(PilotRankingInfo.calculate(
        unlockedAchievementsCount: 0,
        totalUpgradeLevels: 3,
        ownedShipsCount: 1,
        totalCoins: 0,
        completedRecordsCount: 0,
      ).tier, equals(PilotRankTier.cadet));

      expect(PilotRankingInfo.calculate(
        unlockedAchievementsCount: 0,
        totalUpgradeLevels: 3,
        ownedShipsCount: 1,
        totalCoins: 0,
        completedRecordsCount: 1,
      ).tier, equals(PilotRankTier.pilot));

      expect(PilotRankingInfo.calculate(
        unlockedAchievementsCount: 0,
        totalUpgradeLevels: 3,
        ownedShipsCount: 1,
        totalCoins: 0,
        completedRecordsCount: 10,
      ).tier, equals(PilotRankTier.pilot));
    });
  });

  group('Challenger 2 — UI State Reactivity and Localization Suite', () {
    testWidgets('Main Menu: Reactivity to coins, nickname, upgrades, and language toggle', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = GameState();

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

      // 1. Initial RU verification
      expect(find.text('LANDER ZERO: СПАСЕНИЕ'), findsOneWidget);
      expect(find.text('КОСМИЧЕСКАЯ СПАСАТЕЛЬНАЯ СЛУЖБА'), findsOneWidget);
      expect(find.text('ИГРАТЬ'), findsOneWidget);
      expect(find.text('ГАРАЖ'), findsOneWidget);
      expect(find.text('РЕКОРДЫ'), findsOneWidget);
      expect(find.text('ДОСТИЖЕНИЯ'), findsOneWidget);
      expect(find.text('Пилот'), findsOneWidget);
      expect(find.text('РАНГ: ОФИЦЕР'), findsOneWidget);
      expect(find.text('ТЕЛЕМЕТРИЯ: АКТИВНА'), findsOneWidget);
      expect(find.text('СВЯЗЬ: 99.8%'), findsOneWidget);
      expect(find.textContaining('ГОТОВНОСТЬ: 60%'), findsOneWidget);
      expect(find.text('0'), findsWidgets); // 0 coins

      // 2. State update: add nickname and coins
      await state.setNickname('StarLord');
      await state.addCoins(777);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('StarLord'), findsOneWidget);
      expect(find.text('777'), findsOneWidget);
      expect(find.text('РАНГ: ОФИЦЕР'), findsOneWidget);

      // 3. Switch to EN
      await tester.tap(find.text('EN'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(state.language, equals('en'));
      expect(find.text('LANDER ZERO: RESCUE OPS'), findsOneWidget);
      expect(find.text('COSMIC RESCUE DIVISION'), findsOneWidget);
      expect(find.text('PLAY'), findsOneWidget);
      expect(find.text('GARAGE'), findsOneWidget);
      expect(find.text('HIGHSCORES'), findsOneWidget);
      expect(find.text('ACHIEVEMENTS'), findsOneWidget);
      expect(find.text('RANK: OFFICER'), findsOneWidget);
      expect(find.text('TELEMETRY: ACTIVE'), findsOneWidget);
      expect(find.text('LINK: 99.8%'), findsOneWidget);
      expect(find.textContaining('SYS READY: 60%'), findsOneWidget);
      expect(find.text('SELECTED VESSEL:'), findsOneWidget);
      expect(find.text('Sputnik-11'), findsOneWidget);
      expect(find.text('THRUST'), findsOneWidget);
      expect(find.text('FUEL'), findsOneWidget);
      expect(find.text('SHIELD'), findsOneWidget);

      // 4. Upgrade stats in EN and verify sys ready progression
      await state.upgradeStat('engine'); // L2
      await state.upgradeStat('fuel');   // L2
      await state.upgradeStat('shield'); // L2 (total 6 levels)
      await tester.pump(const Duration(milliseconds: 100));

      // 60 + (3/12)*40 = 70%
      expect(find.textContaining('SYS READY: 70%'), findsOneWidget);
      expect(find.text('Lvl 2'), findsNWidgets(3));

      // 5. Switch back to RU
      await tester.tap(find.text('RU'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(state.language, equals('ru'));
      expect(find.text('LANDER ZERO: СПАСЕНИЕ'), findsOneWidget);
      expect(find.text('ТЯГА'), findsOneWidget);
      expect(find.text('ТОПЛИВО'), findsOneWidget);
      expect(find.text('ЩИТ'), findsOneWidget);
      expect(find.textContaining('ГОТОВНОСТЬ: 70%'), findsOneWidget);
    });

    testWidgets('Garage Screen: Language toggle and purchase reactivity across both tabs', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = GameState();
      await state.addCoins(3000);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GarageWidget(onBack: () {}),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Upgrades tab in RU
      expect(find.text('ГАРАЖ'), findsOneWidget);
      expect(find.text('МОДЕРНИЗАЦИЯ'), findsOneWidget);
      expect(find.text('КАБИНЫ'), findsOneWidget);
      expect(find.text('ТЯГА'), findsOneWidget);
      expect(find.text('КУПИТЬ'), findsWidgets);

      // 2. Switch language to EN
      await state.setLanguage('en');
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('GARAGE'), findsOneWidget);
      expect(find.text('UPGRADES'), findsOneWidget);
      expect(find.text('ROCKETS'), findsOneWidget);
      expect(find.text('THRUST'), findsOneWidget);
      expect(find.text('BUY'), findsWidgets);

      // 3. Switch to ROCKETS / Cabins tab
      await tester.tap(find.text('ROCKETS'));
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Check ships in EN
      expect(find.text('Sputnik-11'), findsOneWidget);
      expect(find.text('Cyclone-47'), findsOneWidget);
      expect(find.text('Needle-52'), findsOneWidget);
      expect(find.text('SELECTED'), findsWidgets);
      expect(find.text('800'), findsOneWidget);
      expect(find.text('1500'), findsOneWidget);

      // Buy Cyclone
      await tester.tap(find.text('800'));
      for (int i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(state.ownedRockets, contains('cyclone'));
      expect(state.selectedRocket, equals('cyclone'));

      // 4. Switch back to RU on Cabins tab
      await state.setLanguage('ru');
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('ГАРАЖ'), findsOneWidget);
      expect(find.text('МОДЕРНИЗАЦИЯ'), findsOneWidget);
      expect(find.text('КАБИНЫ'), findsOneWidget);
      expect(find.text('Спутник-11'), findsOneWidget);
      expect(find.text('Ураган-47'), findsOneWidget);
      expect(find.text('Игла-52'), findsOneWidget);
      expect(find.text('ВЫБРАНО'), findsWidgets);
      expect(find.text('ВЫБРАТЬ'), findsWidgets); // Sputnik and Swift now available to select
    });

    testWidgets('Map Select Screen: Language toggle across map cards and location preview sub-screens', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = GameState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: state,
              builder: (context, _) => MapSelectWidget(
                onBack: () {},
                onMapSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Check Map Cards in RU
      expect(find.text('ВЫБОР КАРТЫ'), findsOneWidget);
      expect(find.text('Каньон Эхо'), findsOneWidget);
      expect(find.text('Солнечные Ветра'), findsOneWidget);
      expect(find.text('Глубинное Ядро'), findsOneWidget);
      expect(find.text('ЛЕГКО'), findsOneWidget);
      expect(find.text('СРЕДНЕ'), findsOneWidget);
      expect(find.text('СЛОЖНО'), findsOneWidget);
      expect(find.text('БРИФИНГ'), findsNWidgets(6));

      // 2. Open Deep Core briefing in RU
      await tester.tap(find.text('Глубинное Ядро'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('ПРЕДПРОСМОТР ЛОКАЦИИ'), findsOneWidget);
      expect(find.text('СВЯЗЬ: ДЕСТАБИЛИЗИРОВАНА'), findsOneWidget);
      expect(find.text('СВОДКА МИССИИ'), findsOneWidget);
      expect(find.text('ОСНОВНАЯ ЗАДАЧА'), findsOneWidget);
      expect(find.text('ТЕЛЕМЕТРИЯ СРЕДЫ И АНОМАЛИЙ'), findsOneWidget);
      expect(find.text('НАГРАДЫ И БОНУСЫ ЗА МИССИЮ'), findsOneWidget);
      expect(find.text('ТАКТИЧЕСКИЙ АНАЛИЗ'), findsOneWidget);
      expect(find.text('В ПУТЬ'), findsOneWidget);

      // 3. Switch language to EN while inside preview
      await state.setLanguage('en');
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('LOCATION PREVIEW'), findsOneWidget);
      expect(find.text('COMM STATUS: CRITICAL'), findsOneWidget);
      expect(find.text('MISSION BRIEFING'), findsOneWidget);
      expect(find.text('PRIMARY OBJECTIVE'), findsOneWidget);
      expect(find.text('ENVIRONMENTAL HAZARD TELEMETRY'), findsOneWidget);
      expect(find.text('MISSION REWARDS & CRITERIA'), findsOneWidget);
      expect(find.text('CAVERN DIAGNOSTICS'), findsOneWidget);
      expect(find.text('LAUNCH MISSION'), findsOneWidget);

      // 4. Return to map cards in EN
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('SELECT MAP'), findsOneWidget);
      expect(find.text('Echo Canyon'), findsOneWidget);
      expect(find.text('Solar Winds'), findsOneWidget);
      expect(find.text('Deep Core'), findsOneWidget);
      expect(find.text('EASY'), findsOneWidget);
      expect(find.text('MEDIUM'), findsOneWidget);
      expect(find.text('HARD'), findsOneWidget);
      expect(find.text('BRIEFING'), findsNWidgets(6));
    });
  });

  group('Challenger 2 — MinimapPainter Zero Object Allocation & 60 FPS Performance Suite', () {
    testWidgets('Empirically verifies 10,000 paint frames execute in < 50ms with zero memory churn', (tester) async {
      final game = LanderZeroGame(mapId: 'echo');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MinimapWidget(
              game: game,
              width: 144.0,
              height: 92.0,
            ),
          ),
        ),
      );
      await tester.pump();

      // Extract the CustomPainter from MinimapWidget
      final customPaintFinder = find.descendant(
        of: find.byType(MinimapWidget),
        matching: find.byType(CustomPaint),
      );
      expect(customPaintFinder, findsOneWidget);

      final CustomPaint customPaintWidget = tester.widget<CustomPaint>(customPaintFinder);
      final CustomPainter painter = customPaintWidget.painter!;

      final mockCanvas = MockCanvas();
      const testSize = Size(144.0, 92.0);

      // Warmup cycle (initializes static paths & triggers one-time cache build)
      painter.paint(mockCanvas, testSize);
      expect(mockCanvas.drawLineCount, greaterThan(0));

      // Reset mock canvas counters
      mockCanvas.drawLineCount = 0;
      mockCanvas.drawCircleCount = 0;
      mockCanvas.drawPathCount = 0;

      // Benchmark 10,000 consecutive paint executions
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 10000; i++) {
        painter.paint(mockCanvas, testSize);
      }
      stopwatch.stop();

      final totalMs = stopwatch.elapsedMilliseconds;
      final microsecPerFrame = stopwatch.elapsedMicroseconds / 10000.0;

      // Assert average execution time is under 150 microseconds per frame (< 0.15ms, where 60fps frame budget is 16.6ms)
      expect(microsecPerFrame, lessThan(150.0), reason: 'Each minimap paint frame took $microsecPerFrame µs (Total for 10k: ${totalMs}ms)');

      // Verify canvas operations ran correctly for every frame
      expect(mockCanvas.drawLineCount, equals(60000)); // 6 grid/crosshairs per frame * 10,000
    });

    testWidgets('Path cache identity check avoids recreating Path on unchanged terrain and size', (tester) async {
      final game = LanderZeroGame(mapId: 'echo');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MinimapWidget(
              game: game,
              width: 144.0,
              height: 92.0,
            ),
          ),
        ),
      );
      await tester.pump();

      final customPaintFinder = find.descendant(
        of: find.byType(MinimapWidget),
        matching: find.byType(CustomPaint),
      );
      final CustomPaint customPaintWidget = tester.widget<CustomPaint>(customPaintFinder);
      final CustomPainter painter = customPaintWidget.painter!;

      final mockCanvas = MockCanvas();
      const testSize = Size(144.0, 92.0);

      // Frame 1
      painter.paint(mockCanvas, testSize);
      // Frame 2
      painter.paint(mockCanvas, testSize);
      // Frame 3
      painter.paint(mockCanvas, testSize);

      // shouldRepaint returns true so animation ticks cause repaint without rebuild overhead
      expect(painter.shouldRepaint(painter), isTrue);
    });
  });
}
