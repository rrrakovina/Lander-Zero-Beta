import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lander_zero/game/state/game_state.dart';
import 'package:lander_zero/game/state/save_security_manager.dart';
import 'package:lander_zero/ui/screens/map_select_screen.dart';
import 'package:lander_zero/ui/screens/main_menu_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GameState().init(force: true);
  });

  group('Sequential Level Unlocking & Progression Tests', () {
    test('Initial fresh state: Echo Canyon and Endless are unlocked, others are locked', () {
      final state = GameState();
      expect(state.isLevelUnlocked('echo'), isTrue);
      expect(state.isLevelUnlocked('endless'), isTrue);
      expect(state.isLevelUnlocked('wind'), isFalse);
      expect(state.isLevelUnlocked('core'), isFalse);
      expect(state.isLevelUnlocked('ice'), isFalse);
      expect(state.isLevelUnlocked('orbit'), isFalse);
    });

    test('Requirements hierarchy maps correctly', () {
      final state = GameState();
      expect(state.getRequiredLevelToUnlock('wind'), 'echo');
      expect(state.getRequiredLevelToUnlock('core'), 'wind');
      expect(state.getRequiredLevelToUnlock('ice'), 'core');
      expect(state.getRequiredLevelToUnlock('orbit'), 'ice');
      expect(state.getRequiredLevelToUnlock('echo'), '');
      expect(state.getRequiredLevelToUnlock('endless'), '');
    });

    test('Completing levels sequentially unlocks next tiers', () async {
      final state = GameState();

      // Complete Echo
      final r1 = await state.processMissionVictory(
        'echo',
        remainingFuelPercent: 50.0,
        damagePercent: 0.0,
        coinsEarned: 100,
      );
      expect(r1['isNewLevelUnlocked'], isTrue);
      expect(r1['unlockedMapId'], 'wind');
      expect(state.isLevelUnlocked('wind'), isTrue);
      expect(state.isLevelUnlocked('core'), isFalse);

      // Complete Wind
      final r2 = await state.processMissionVictory(
        'wind',
        remainingFuelPercent: 30.0,
        damagePercent: 10.0,
        coinsEarned: 50,
      );
      expect(r2['unlockedMapId'], 'core');
      expect(state.isLevelUnlocked('core'), isTrue);
      expect(state.isLevelUnlocked('ice'), isFalse);

      // Complete Core
      final r3 = await state.processMissionVictory(
        'core',
        remainingFuelPercent: 45.0,
        damagePercent: 0.0,
        coinsEarned: 150,
      );
      expect(r3['unlockedMapId'], 'ice');
      expect(state.isLevelUnlocked('ice'), isTrue);
      expect(state.isLevelUnlocked('orbit'), isFalse);

      // Complete Ice
      final r4 = await state.processMissionVictory(
        'ice',
        remainingFuelPercent: 60.0,
        damagePercent: 0.0,
        coinsEarned: 200,
      );
      expect(r4['unlockedMapId'], 'orbit');
      expect(state.isLevelUnlocked('orbit'), isTrue);
    });
  });

  group('3-Star Rating System Tests', () {
    test('calculateEarnedStars evaluation', () {
      final state = GameState();

      // 1 Star: Delivered cargo, low fuel (<40%), took damage (>0%)
      expect(state.calculateEarnedStars(remainingFuelPercent: 20.0, damagePercent: 15.0), 1);

      // 2 Stars: Delivered cargo, fuel >= 40%, took damage
      expect(state.calculateEarnedStars(remainingFuelPercent: 55.0, damagePercent: 5.0), 2);

      // 2 Stars: Delivered cargo, fuel < 40%, zero damage
      expect(state.calculateEarnedStars(remainingFuelPercent: 35.0, damagePercent: 0.0), 2);

      // 3 Stars: Flawless (cargo delivered, fuel >= 40%, zero damage)
      expect(state.calculateEarnedStars(remainingFuelPercent: 40.0, damagePercent: 0.0), 3);
      expect(state.calculateEarnedStars(remainingFuelPercent: 80.0, damagePercent: 0.0), 3);
    });

    test('Stars persist and never downgrade upon replaying', () async {
      final state = GameState();

      // First run: 3 stars
      await state.processMissionVictory(
        'echo',
        remainingFuelPercent: 80.0,
        damagePercent: 0.0,
        coinsEarned: 100,
      );
      expect(state.getStarsForLevel('echo'), 3);
      expect(state.totalStars, 3);

      // Second run: 1 star performance on same level
      await state.processMissionVictory(
        'echo',
        remainingFuelPercent: 10.0,
        damagePercent: 40.0,
        coinsEarned: 50,
      );
      // Level stars should remain 3
      expect(state.getStarsForLevel('echo'), 3);
      expect(state.totalStars, 3);
    });
  });

  group('Pilot XP and Ranking Tests', () {
    test('Rank calculations match XP milestones', () async {
      final state = GameState();

      // Initial: Cadet
      expect(state.pilotXp, 0);
      expect(state.pilotRank, 1);
      expect(state.pilotRankKey, 'rank_cadet');
      expect(state.currentRankBaseXp, 0);
      expect(state.nextRankXp, 300);
      expect(state.rankProgress, 0.0);

      // Add 350 XP -> Junior Pilot
      bool rankedUp = await state.addPilotXp(350);
      expect(rankedUp, isTrue);
      expect(state.pilotXp, 350);
      expect(state.pilotRank, 2);
      expect(state.pilotRankKey, 'rank_junior_pilot');
      expect(state.currentRankBaseXp, 300);
      expect(state.nextRankXp, 800);
      expect(state.rankProgress, closeTo(50 / 500, 0.001));

      // Add 500 XP -> 850 XP -> Flight Officer
      rankedUp = await state.addPilotXp(500);
      expect(rankedUp, isTrue);
      expect(state.pilotRank, 3);
      expect(state.pilotRankKey, 'rank_flight_officer');

      // Add 700 XP -> 1550 XP -> Fleet Captain
      rankedUp = await state.addPilotXp(700);
      expect(rankedUp, isTrue);
      expect(state.pilotRank, 4);
      expect(state.pilotRankKey, 'rank_fleet_captain');

      // Add 1000 XP -> 2550 XP -> Space Ace
      rankedUp = await state.addPilotXp(1000);
      expect(rankedUp, isTrue);
      expect(state.pilotRank, 5);
      expect(state.pilotRankKey, 'rank_space_ace');
      expect(state.rankProgress, 1.0);
    });
  });

  group('Save Security HMAC Verification with Progression', () {
    test('HMAC calculates and verifies state with pilotXp, completedLevels, levelStars', () {
      final sig = SaveSecurityManager.computeSignature(
        coins: 500,
        ownedRockets: ['sputnik', 'swift'],
        pilotXp: 1200,
        completedLevels: ['echo', 'wind'],
        levelStarsJson: '{"echo":3,"wind":2}',
      );

      final isValid = SaveSecurityManager.verifySignature(
        coins: 500,
        ownedRockets: ['sputnik', 'swift'],
        pilotXp: 1200,
        completedLevels: ['echo', 'wind'],
        levelStarsJson: '{"echo":3,"wind":2}',
        signature: sig,
      );

      expect(isValid, isTrue);

      // Tampered XP check
      final isTampered = SaveSecurityManager.verifySignature(
        coins: 500,
        ownedRockets: ['sputnik', 'swift'],
        pilotXp: 999999,
        completedLevels: ['echo', 'wind'],
        levelStarsJson: '{"echo":3,"wind":2}',
        signature: sig,
      );

      expect(isTampered, isFalse);
    });

    test('Backward compatibility with legacy v1 signatures', () {
      final legacySig = SaveSecurityManager.computeLegacyV1Signature(
        coins: 200,
        ownedRockets: ['sputnik'],
      );

      final isValid = SaveSecurityManager.verifySignature(
        coins: 200,
        ownedRockets: ['sputnik'],
        pilotXp: 0,
        completedLevels: const [],
        levelStarsJson: '{}',
        signature: legacySig,
      );

      expect(isValid, isTrue);
    });
  });

  group('Widget UI Integration Tests', () {
    testWidgets('MapSelectScreen displays locked state and stars accurately', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = GameState();
      await state.processMissionVictory(
        'echo',
        remainingFuelPercent: 75.0,
        damagePercent: 0.0,
        coinsEarned: 100,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapSelectWidget(
              onMapSelected: (_) {},
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Echo should be unlocked and show 3 stars
      expect(find.text('Каньон Эхо'), findsWidgets);

      // Solar Winds ('wind') should be unlocked now because Echo is completed
      expect(find.text('Солнечные Ветра'), findsWidgets);

      // Deep Core ('core') is locked
      expect(find.text('Глубинное Ядро'), findsWidgets);
      expect(find.text('ТРЕБУЕТСЯ: СОЛНЕЧНЫЕ ВЕТРА'), findsWidgets);
    });

    testWidgets('MainMenuScreen renders Pilot Rank badge and XP progress', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = GameState();
      await state.addPilotXp(400); // Junior Pilot

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

      expect(find.text('РАНГ: МЛАДШИЙ ПИЛОТ'), findsOneWidget);
      expect(find.text('400 XP'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });
  });
}
