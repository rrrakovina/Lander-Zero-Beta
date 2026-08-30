import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lander_zero/game/audio/game_audio_manager.dart';
import 'package:lander_zero/game/lander_zero_game.dart';
import 'package:lander_zero/game/state/game_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GameAudioManager.isTesting = true;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GameState().init(force: true);
  });

  group('Web Standards & Russian WASD Keyboard Input Tests', () {
    test('Cyrillic Ф and Physical keyA activate left thruster', () async {
      final game = LanderZeroGame(mapId: 'echo');
      await game.onLoad();
      game.runStateNotifier.value = GameRunState.playing;

      // Cyrillic Ф key down
      final eventCyrillicF = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyA,
        logicalKey: LogicalKeyboardKey(0x0444), // Cyrillic Small Letter Ef
        character: 'ф',
        timeStamp: Duration.zero,
      );

      final result1 = game.onKeyEvent(eventCyrillicF, {LogicalKeyboardKey(0x0444)});
      expect(result1, equals(KeyEventResult.handled));
      expect(game.lander.leftThrustActive, isTrue);

      // Key up
      final eventCyrillicFUp = const KeyUpEvent(
        physicalKey: PhysicalKeyboardKey.keyA,
        logicalKey: LogicalKeyboardKey(0x0444),
        timeStamp: Duration.zero,
      );
      game.onKeyEvent(eventCyrillicFUp, {});
      expect(game.lander.leftThrustActive, isFalse);
    });

    test('Cyrillic В and Physical keyD activate right thruster', () async {
      final game = LanderZeroGame(mapId: 'echo');
      await game.onLoad();
      game.runStateNotifier.value = GameRunState.playing;

      final eventCyrillicV = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyD,
        logicalKey: LogicalKeyboardKey(0x0432), // Cyrillic Small Letter Ve
        character: 'в',
        timeStamp: Duration.zero,
      );

      final result = game.onKeyEvent(eventCyrillicV, {LogicalKeyboardKey(0x0432)});
      expect(result, equals(KeyEventResult.handled));
      expect(game.lander.rightThrustActive, isTrue);
    });

    test('Cyrillic Ц and Physical keyW activate main dual thrusters', () async {
      final game = LanderZeroGame(mapId: 'echo');
      await game.onLoad();
      game.runStateNotifier.value = GameRunState.playing;

      final eventCyrillicTs = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyW,
        logicalKey: LogicalKeyboardKey(0x0446), // Cyrillic Small Letter Tse
        character: 'ц',
        timeStamp: Duration.zero,
      );

      final result = game.onKeyEvent(eventCyrillicTs, {LogicalKeyboardKey(0x0446)});
      expect(result, equals(KeyEventResult.handled));
      expect(game.lander.leftThrustActive, isTrue);
      expect(game.lander.rightThrustActive, isTrue);
    });

    test('Cyrillic К and Physical keyR trigger quick restart callback', () {
      bool restartTriggered = false;
      final game = LanderZeroGame(
        mapId: 'echo',
        onRestartRequested: () => restartTriggered = true,
      );
      game.runStateNotifier.value = GameRunState.playing;

      final eventCyrillicK = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyR,
        logicalKey: LogicalKeyboardKey(0x043A), // Cyrillic Small Letter Ka
        character: 'к',
        timeStamp: Duration.zero,
      );

      final result = game.onKeyEvent(eventCyrillicK, {LogicalKeyboardKey(0x043A)});
      expect(result, equals(KeyEventResult.handled));
      expect(restartTriggered, isTrue);
    });
  });
}
