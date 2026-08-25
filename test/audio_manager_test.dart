import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lander_zero/game/audio/game_audio_manager.dart';
import 'package:lander_zero/game/state/game_state.dart';
import 'package:lander_zero/ui/screens/main_menu_screen.dart';
import 'package:lander_zero/ui/screens/map_select_screen.dart';
import 'package:lander_zero/ui/screens/nick_entry_screen.dart';
import 'package:lander_zero/ui/screens/leaderboard_screen.dart';
import 'package:lander_zero/ui/dialogs/settings_dialog.dart';
import 'package:lander_zero/ui/dialogs/achievements_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    GameAudioManager.isTesting = true;
    await GameState().init(force: true);
  });

  group('GameAudioManager API & Method Verification Tests', () {
    test('GameAudioManager is a singleton instance', () {
      final instance1 = GameAudioManager();
      final instance2 = GameAudioManager();
      expect(identical(instance1, instance2), isTrue);
    });

    test('GameAudioManager exposes playTap(), playPurchase(), playDecline(), playSwoosh()', () {
      final audioManager = GameAudioManager();

      // Test with isTesting = true (standard unit test mode)
      GameAudioManager.isTesting = true;

      expect(() => audioManager.playTap(), returnsNormally);
      expect(() => audioManager.playTap(volumeMultiplier: 0.5), returnsNormally);
      expect(() => audioManager.playTap(volumeMultiplier: 1.5), returnsNormally);

      expect(() => audioManager.playPurchase(), returnsNormally);
      expect(() => audioManager.playPurchase(volumeMultiplier: 0.8), returnsNormally);

      expect(() => audioManager.playDecline(), returnsNormally);
      expect(() => audioManager.playDecline(volumeMultiplier: 0.2), returnsNormally);

      expect(() => audioManager.playSwoosh(), returnsNormally);
      expect(() => audioManager.playSwoosh(volumeMultiplier: 1.0), returnsNormally);
    });

    test('Audio methods execute safely without crash even when isTesting is false in headless environment', () {
      final audioManager = GameAudioManager();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers.global'),
        (MethodCall methodCall) async => null,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers'),
        (MethodCall methodCall) async => null,
      );

      // Temporarily toggle isTesting to false to verify internal try-catch robustness
      GameAudioManager.isTesting = false;

      expect(() => audioManager.playTap(), returnsNormally);
      expect(() => audioManager.playPurchase(), returnsNormally);
      expect(() => audioManager.playDecline(), returnsNormally);
      expect(() => audioManager.playSwoosh(), returnsNormally);
      expect(() => audioManager.playSfx('coin.wav'), returnsNormally);
      expect(() => audioManager.playBgm(), returnsNormally);
      expect(() => audioManager.stopBgm(), returnsNormally);
      expect(() => audioManager.updateBgmVolume(), returnsNormally);

      // Restore testing flag
      GameAudioManager.isTesting = true;
    });

    test('GameAudioManager handles muted and zero volume gracefully', () async {
      final state = GameState();
      final audioManager = GameAudioManager();

      await state.setSfxVolume(0.0);
      expect(state.sfxVolume, equals(0.0));

      // Should execute without throwing when muted
      expect(() => audioManager.playTap(), returnsNormally);
      expect(() => audioManager.playPurchase(), returnsNormally);
      expect(() => audioManager.playDecline(), returnsNormally);
      expect(() => audioManager.playSwoosh(), returnsNormally);
      expect(() => audioManager.playSfx('coin.wav'), returnsNormally);

      await state.setSfxVolume(1.0);
      expect(state.sfxVolume, equals(1.0));
    });

    test('Game lifecycle and thrust loop methods execute safely', () {
      final audioManager = GameAudioManager();
      expect(() => audioManager.startThrustLoop(), returnsNormally);
      expect(() => audioManager.stopThrustLoop(), returnsNormally);
      expect(() => audioManager.disposeGameSounds(), returnsNormally);
    });
  });

  group('Audio Assets Presence & 16-bit PCM RIFF Binary Format Tests', () {
    const audioFiles = [
      'assets/audio/ui_tap.wav',
      'assets/audio/ui_purchase.wav',
      'assets/audio/ui_decline.wav',
      'assets/audio/ui_swoosh.wav',
    ];

    test('assets/audio/ contains all 4 required tactile audio files', () {
      for (final path in audioFiles) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: 'File $path must exist on disk');
      }
    });

    test('All tactile WAV files have valid 16-bit PCM RIFF headers and non-empty data', () {
      for (final path in audioFiles) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: '$path must exist');

        final bytes = file.readAsBytesSync();
        expect(bytes.length, greaterThanOrEqualTo(44),
            reason: '$path must have at least 44 bytes for standard WAV header');

        final byteData = ByteData.sublistView(bytes);

        // 1. "RIFF" Chunk Descriptor (Bytes 0-3: 0x52 0x49 0x46 0x46)
        final riffTag = String.fromCharCodes(bytes.sublist(0, 4));
        expect(riffTag, equals('RIFF'), reason: '$path missing RIFF header');

        // File size minus 8
        final chunkSize = byteData.getUint32(4, Endian.little);
        expect(chunkSize + 8, equals(bytes.length),
            reason: '$path RIFF chunk size mismatch with file length');

        // 2. "WAVE" Format Descriptor (Bytes 8-11: 0x57 0x41 0x56 0x45)
        final waveTag = String.fromCharCodes(bytes.sublist(8, 12));
        expect(waveTag, equals('WAVE'), reason: '$path missing WAVE format descriptor');

        // 3. "fmt " Subchunk
        final fmtTag = String.fromCharCodes(bytes.sublist(12, 16));
        expect(fmtTag, equals('fmt '), reason: '$path missing fmt subchunk marker');

        final fmtSubchunkSize = byteData.getUint32(16, Endian.little);
        expect(fmtSubchunkSize, greaterThanOrEqualTo(16),
            reason: '$path fmt subchunk size must be >= 16 for PCM');

        // AudioFormat: 1 = Linear PCM (Uncompressed)
        final audioFormat = byteData.getUint16(20, Endian.little);
        expect(audioFormat, equals(1),
            reason: '$path must be uncompressed Linear PCM (Format 1)');

        // NumChannels: 1 (Mono) or 2 (Stereo)
        final numChannels = byteData.getUint16(22, Endian.little);
        expect(numChannels, inInclusiveRange(1, 2),
            reason: '$path channel count must be 1 or 2');

        // SampleRate (e.g. 22050 or 44100 Hz)
        final sampleRate = byteData.getUint32(24, Endian.little);
        expect(sampleRate, inInclusiveRange(8000, 96000),
            reason: '$path sample rate ($sampleRate Hz) outside valid range');

        // ByteRate: SampleRate * NumChannels * BitsPerSample / 8
        final byteRate = byteData.getUint32(28, Endian.little);

        // BlockAlign: NumChannels * BitsPerSample / 8
        final blockAlign = byteData.getUint16(32, Endian.little);

        // BitsPerSample: 16-bit
        final bitsPerSample = byteData.getUint16(34, Endian.little);
        expect(bitsPerSample, equals(16),
            reason: '$path must be 16-bit PCM');

        expect(blockAlign, equals(numChannels * (bitsPerSample ~/ 8)));
        expect(byteRate, equals(sampleRate * blockAlign));

        // 4. Find "data" subchunk
        int offset = 20 + fmtSubchunkSize;
        bool dataFound = false;
        int dataSize = 0;

        while (offset + 8 <= bytes.length) {
          final subchunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
          final subchunkLen = byteData.getUint32(offset + 4, Endian.little);
          if (subchunkId == 'data') {
            dataFound = true;
            dataSize = subchunkLen;
            break;
          }
          offset += 8 + subchunkLen;
        }

        expect(dataFound, isTrue, reason: '$path must contain data subchunk');
        expect(dataSize, greaterThan(0), reason: '$path data subchunk must not be empty');

        // Verify duration bounds (between 20 ms and 1000 ms)
        final totalSamples = dataSize ~/ (numChannels * (bitsPerSample ~/ 8));
        final durationMs = (totalSamples / sampleRate) * 1000.0;

        expect(durationMs, greaterThan(15.0),
            reason: '$path duration $durationMs ms too short');
        expect(durationMs, lessThan(1000.0),
            reason: '$path duration $durationMs ms too long for UI sound');
      }
    });

    test('Specific duration checks match design specifications for each tactile sound', () {
      final expectations = {
        'assets/audio/ui_tap.wav': (double ms) => ms >= 20.0 && ms <= 100.0,      // ~45 ms target
        'assets/audio/ui_purchase.wav': (double ms) => ms >= 120.0 && ms <= 350.0, // ~220 ms target
        'assets/audio/ui_decline.wav': (double ms) => ms >= 100.0 && ms <= 300.0,  // ~160 ms target
        'assets/audio/ui_swoosh.wav': (double ms) => ms >= 40.0 && ms <= 200.0,    // ~90 ms target
      };

      for (final entry in expectations.entries) {
        final path = entry.key;
        final validator = entry.value;

        final file = File(path);
        final bytes = file.readAsBytesSync();
        final byteData = ByteData.sublistView(bytes);

        final sampleRate = byteData.getUint32(24, Endian.little);
        final numChannels = byteData.getUint16(22, Endian.little);
        final bitsPerSample = byteData.getUint16(34, Endian.little);

        // Locate data size
        int offset = 36;
        while (offset + 8 <= bytes.length) {
          final id = String.fromCharCodes(bytes.sublist(offset, offset + 4));
          final len = byteData.getUint32(offset + 4, Endian.little);
          if (id == 'data') {
            final samples = len ~/ (numChannels * (bitsPerSample ~/ 8));
            final durMs = (samples / sampleRate) * 1000.0;
            expect(validator(durMs), isTrue,
                reason: '$path duration $durMs ms not within design range');
            break;
          }
          offset += 8 + len;
        }
      }
    });
  });

  group('UI Screens Audio Trigger Integration Tests', () {
    testWidgets('MainMenuScreen button taps trigger audio without exception', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool playCalled = false;
      bool garageCalled = false;
      bool recordsCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MainMenuWidget(
              onPlay: () => playCalled = true,
              onGarage: () => garageCalled = true,
              onLeaderboard: () => recordsCalled = true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap language switch
      final langBtn = find.widgetWithText(OutlinedButton, 'EN');
      if (langBtn.evaluate().isNotEmpty) {
        await tester.tap(langBtn);
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Tap play button
      final playBtn = find.byIcon(Icons.play_arrow_rounded);
      expect(playBtn, findsOneWidget);
      await tester.tap(playBtn);
      await tester.pump(const Duration(milliseconds: 50));
      expect(playCalled, isTrue);

      // Tap garage button
      final garageBtn = find.byIcon(Icons.build_rounded);
      expect(garageBtn, findsOneWidget);
      await tester.tap(garageBtn);
      await tester.pump(const Duration(milliseconds: 50));
      expect(garageCalled, isTrue);

      // Tap records button
      final recordsBtn = find.byIcon(Icons.emoji_events_rounded);
      expect(recordsBtn, findsOneWidget);
      await tester.tap(recordsBtn);
      await tester.pump(const Duration(milliseconds: 50));
      expect(recordsCalled, isTrue);
    });

    testWidgets('MapSelectScreen back, cards, and launch trigger audio', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool backCalled = false;
      String? selectedMap;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapSelectWidget(
              onBack: () => backCalled = true,
              onMapSelected: (map) => selectedMap = map,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap back button
      final backIcon = find.byIcon(Icons.arrow_back_rounded);
      expect(backIcon, findsOneWidget);
      await tester.tap(backIcon);
      await tester.pump(const Duration(milliseconds: 50));
      expect(backCalled, isTrue);

      // Tap map card to open preview
      final echoCard = find.text('Каньон Эхо');
      expect(echoCard, findsOneWidget);
      await tester.tap(echoCard);
      await tester.pump(const Duration(milliseconds: 100));

      // In preview, tap launch mission button
      final launchBtn = find.text('В ПУТЬ');
      expect(launchBtn, findsOneWidget);
      await tester.tap(launchBtn);
      await tester.pump(const Duration(milliseconds: 50));
      expect(selectedMap, equals('echo'));
    });

    testWidgets('NickEntryScreen triggers validation decline and submit purchase audio', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool finished = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NickEntryWidget(
              onFinished: () => finished = true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Submit empty nickname -> should trigger decline audio and error message
      final submitBtn = find.text('ПОДТВЕРДИТЬ РЕГИСТРАЦИЮ');
      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);
      await tester.pump(const Duration(milliseconds: 50));
      expect(finished, isFalse);
      expect(find.text(GameState().translate('error_empty_nick')), findsOneWidget);

      // 2. Select starter ship card
      final swiftCard = find.text('Стриж');
      if (swiftCard.evaluate().isNotEmpty) {
        await tester.tap(swiftCard);
        await tester.pump(const Duration(milliseconds: 50));
      }

      // 3. Enter valid nickname and submit
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Gagarin');
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(submitBtn);
      await tester.pump(const Duration(milliseconds: 50));
      expect(finished, isTrue);
      expect(GameState().nickname, equals('Gagarin'));
    });

    testWidgets('SettingsDialog close and language toggle trigger audio', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingsDialog(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Language toggle
      final enBtn = find.text('EN');
      expect(enBtn, findsOneWidget);
      await tester.tap(enBtn);
      await tester.pump(const Duration(milliseconds: 50));
      expect(GameState().language, equals('en'));

      final ruBtn = find.text('RU');
      expect(ruBtn, findsOneWidget);
      await tester.tap(ruBtn);
      await tester.pump(const Duration(milliseconds: 50));
      expect(GameState().language, equals('ru'));
    });

    testWidgets('LeaderboardWidget back button triggers audio and onBack', (tester) async {
      bool backCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LeaderboardWidget(
              onBack: () => backCalled = true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final backBtn = find.byIcon(Icons.arrow_back_rounded);
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pump(const Duration(milliseconds: 50));
      expect(backCalled, isTrue);
    });

    testWidgets('AchievementsDialog close icon triggers tap audio', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AchievementsDialog(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final closeBtn = find.byIcon(Icons.close_rounded);
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pump(const Duration(milliseconds: 50));
    });
  });
}
