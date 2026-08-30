import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:lander_zero/game/lander_zero_game.dart';
import 'package:lander_zero/game/audio/game_audio_manager.dart';
import 'package:lander_zero/game/state/game_state.dart';
import 'package:lander_zero/game/components/rope.dart';
import 'package:lander_zero/ui/widgets/interactive_tutorial_guide.dart';
import 'package:lander_zero/ui/screens/game_screen.dart';

Widget createTestApp(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Stack(
        children: [
          child,
        ],
      ),
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

  group('Suite 1: Interactive Tutorial (FTUE State Machine) Transitions', () {
    test('Echo Canyon starts in Step 1 (Lift off) when tutorial is not completed', () async {
      final state = GameState();
      expect(state.tutorialCompleted, isFalse);

      final game = LanderZeroGame(mapId: 'echo');
      await game.onLoad();

      expect(game.tutorialStep, equals(1));
    });

    test('FTUE State Machine progresses through all 5 steps on player progress', () async {
      final game = LanderZeroGame(mapId: 'echo');
      await game.onLoad();
      game.world.gravity.setZero();
      game.cave.world = game.world;
      game.cave.createBody();
      game.lander.world = game.world;
      game.lander.body = game.lander.createBody();
      game.cargoCapsule.world = game.world;
      game.cargoCapsule.body = game.cargoCapsule.createBody();

      expect(game.tutorialStep, equals(1));

      // 1. Lift off -> Move up by > 1.2m
      game.lander.body.setTransform(Vector2(game.cave.startPlatform.x, game.cave.startPlatform.y - 4.0), 0);
      game.update(0.05);
      expect(game.tutorialStep, equals(2), reason: 'Lander lifted off -> should advance to Step 2 (Maneuvering)');

      // 2. Maneuvering -> Move horizontally by > 6.0m
      game.lander.body.setTransform(Vector2(game.cave.startPlatform.x + 8.0, game.cave.startPlatform.y - 4.0), 0);
      game.update(0.05);
      expect(game.tutorialStep, equals(3), reason: 'Lander flew towards valley -> should advance to Step 3 (Docking)');

      // 3. Docking -> Connect cargo rope
      final rope = Rope(lander: game.lander, capsule: game.cargoCapsule);
      game.rope = rope;
      game.update(0.05);
      expect(game.tutorialStep, equals(4), reason: 'Cargo docked -> should advance to Step 4 (Transport)');

      // 4. Transport -> Approach exit platform within 10m
      game.lander.body.setTransform(Vector2(game.cave.exitPlatform.x - 5.0, game.cave.exitPlatform.y - 4.0), 0);
      game.update(0.05);
      expect(game.tutorialStep, equals(5), reason: 'Approached landing bay -> should advance to Step 5 (Landing)');
    });

    test('Skip tutorial immediately deactivates state machine and saves tutorialCompleted', () async {
      final state = GameState();
      final game = LanderZeroGame(mapId: 'echo');
      await game.onLoad();

      expect(game.tutorialStep, equals(1));

      game.skipTutorial();
      expect(game.tutorialStep, equals(0));
      expect(state.tutorialCompleted, isTrue);
    });
  });

  group('Suite 2: Crash Telemetry & Diagnostic Detection', () {
    test('Detects fuel exhaustion when fuel reaches 0 and speed settles', () async {
      final game = LanderZeroGame(mapId: 'echo');
      await game.onLoad();
      game.world.gravity.setZero();
      game.cave.world = game.world;
      game.cave.createBody();
      game.lander.world = game.world;
      game.lander.body = game.lander.createBody();
      game.cargoCapsule.world = game.world;
      game.cargoCapsule.body = game.cargoCapsule.createBody();

      game.lander.fuel = 0.0;
      game.lander.body.linearVelocity.setZero();

      game.update(0.05);

      expect(game.runStateNotifier.value, equals(GameRunState.lost));
      expect(game.lastCrashReason, equals(CrashReason.fuelExhausted));
    });

    test('Detects excessive landing tilt angle on touchdown near exit', () async {
      final game = LanderZeroGame(mapId: 'echo');
      await game.onLoad();
      game.world.gravity.setZero();
      game.cave.world = game.world;
      game.cave.createBody();
      game.lander.world = game.world;
      game.lander.body = game.lander.createBody();

      // Position lander at exit platform with steep tilt angle (25 degrees ~ 0.44 rad)
      game.lander.body.setTransform(Vector2(game.cave.exitPlatform.x, game.cave.exitPlatform.y), 0.44);
      game.lander.shield = 0.0; // terminal damage

      game.onCollisionImpact(game.cave.exitPlatform, 12.0);

      expect(game.lastCrashReason, equals(CrashReason.excessAngle));
      expect(game.lastImpactAngle, closeTo(25.2, 0.5));
    });

    test('Detects excessive impact speed on touchdown near exit', () async {
      final game = LanderZeroGame(mapId: 'echo');
      await game.onLoad();
      game.world.gravity.setZero();
      game.cave.world = game.world;
      game.cave.createBody();
      game.lander.world = game.world;
      game.lander.body = game.lander.createBody();

      // Position lander at exit platform with straight angle and high velocity (9.5 m/s)
      game.lander.body.setTransform(Vector2(game.cave.exitPlatform.x, game.cave.exitPlatform.y), 0.05);
      game.lander.body.linearVelocity = Vector2(0, 9.5);
      game.lander.shield = 0.0; // terminal damage

      game.onCollisionImpact(game.cave.exitPlatform, 12.0);

      expect(game.lastCrashReason, equals(CrashReason.excessSpeed));
      expect(game.lastImpactSpeed, closeTo(9.5, 0.1));
    });

    test('Detects terrain rock hull breach when crashed far from platforms', () async {
      final game = LanderZeroGame(mapId: 'echo');
      await game.onLoad();
      game.world.gravity.setZero();
      game.cave.world = game.world;
      game.cave.createBody();
      game.lander.world = game.world;
      game.lander.body = game.lander.createBody();

      // Position lander in middle of canyon wall
      game.lander.body.setTransform(Vector2(-10.0, -2.0), 0.1);
      game.lander.shield = 0.0;

      game.onCollisionImpact(Vector2(-10.0, -2.0), 15.0);

      expect(game.lastCrashReason, equals(CrashReason.hullBreached));
    });
  });

  group('Suite 3: UI Widget Rendering for Tutorial & Crash Telemetry', () {
    testWidgets('InteractiveTutorialGuide renders steps, keycaps and skip button cleanly', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool skipped = false;

      await tester.pumpWidget(createTestApp(
        InteractiveTutorialGuide(
          step: 1,
          onSkip: () => skipped = true,
        ),
      ));
      await tester.pump();

      expect(find.text('ШАГ 1/5: ВЗЛЕТ'), findsOneWidget);
      expect(find.text('ПРОПУСТИТЬ ОБУЧЕНИЕ [ESC]'), findsOneWidget);

      // Tap skip button
      await tester.tap(find.text('ПРОПУСТИТЬ ОБУЧЕНИЕ [ESC]'));
      expect(skipped, isTrue);
    });

    testWidgets('PostRunStatsOverlay renders Crash Telemetry diagnostic card and restart shortcut on defeat', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final game = LanderZeroGame(mapId: 'echo');
      await game.onLoad();
      game.lastCrashReason = CrashReason.excessSpeed;
      game.lastImpactSpeed = 8.4;

      bool restarted = false;
      bool exited = false;

      await tester.pumpWidget(createTestApp(
        PostRunStatsOverlay(
          game: game,
          runState: GameRunState.lost,
          onExit: () => exited = true,
          onRestart: () => restarted = true,
        ),
      ));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('БОРТОВОЙ САМОПИСЕЦ // ПРИЧИНА КРУШЕНИЯ'), findsOneWidget);
      expect(find.textContaining('8.4 М/С'), findsOneWidget);
      expect(find.textContaining('СОВЕТ:'), findsOneWidget);

      // Tap quick restart button
      await tester.tap(find.textContaining('БЫСТРЫЙ ПЕРЕЗАПУСК'));
      expect(restarted, isTrue);

      // Tap exit to menu button
      await tester.tap(find.text('В ГЛАВНОЕ МЕНЮ'));
      expect(exited, isTrue);
    });
  });
}

