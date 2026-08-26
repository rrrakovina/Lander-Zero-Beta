import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lander_zero/game/state/game_state.dart';
import 'package:lander_zero/game/audio/game_audio_manager.dart';
import 'package:lander_zero/ui/widgets/tutorial_controls_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tutorial Controls Overlay and Settings Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      GameAudioManager.isTesting = true;
      await GameState().init(force: true);
    });

    test('GameState showControlHints defaults to true and can be toggled', () async {
      final state = GameState();
      expect(state.showControlHints, isTrue);

      int calls = 0;
      state.addListener(() => calls++);

      await state.setShowControlHints(false);
      expect(state.showControlHints, isFalse);
      expect(calls, equals(1));

      // Check persistence
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('showControlHints'), isFalse);

      await state.setShowControlHints(true);
      expect(state.showControlHints, isTrue);
      expect(calls, equals(2));
    });

    test('Translations include control hints keys', () async {
      final state = GameState();
      await state.setLanguage('ru');
      expect(state.translate('control_hints'), equals('Подсказки управления'));
      expect(state.translate('hint_turn_left'), equals('Поворот влево'));
      expect(state.translate('hint_turn_right'), equals('Поворот вправо'));
      expect(state.translate('hint_main_thrust'), equals('Основная тяга'));

      await state.setLanguage('en');
      expect(state.translate('control_hints'), equals('Control Hints'));
      expect(state.translate('hint_turn_left'), equals('Turn Left'));
      expect(state.translate('hint_turn_right'), equals('Turn Right'));
      expect(state.translate('hint_main_thrust'), equals('Main Thrust'));
    });

    testWidgets('TutorialControlsOverlay renders keycaps and labels when visible', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TutorialControlsOverlay(opacity: 1.0),
          ),
        ),
      );

      // Verify key labels exist
      expect(find.text('A'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
      expect(find.text('W'), findsOneWidget);
      expect(find.text('←'), findsOneWidget);
      expect(find.text('→'), findsOneWidget);
      expect(find.text('↑'), findsOneWidget);
      expect(find.text('S / ↓'), findsOneWidget);
      expect(find.text('ESC'), findsOneWidget);

      // Verify Russian translation labels rendered
      expect(find.text('ПОВОРОТ ВЛЕВО'), findsOneWidget);
      expect(find.text('ПОВОРОТ ВПРАВО'), findsOneWidget);
      expect(find.text('ОСНОВНАЯ ТЯГА'), findsOneWidget);
    });

    testWidgets('TutorialControlsOverlay returns SizedBox.shrink when opacity is 0.0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TutorialControlsOverlay(opacity: 0.0),
          ),
        ),
      );

      expect(find.text('A'), findsNothing);
      expect(find.text('D'), findsNothing);
    });
  });
}