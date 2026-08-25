import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lander_zero/game/state/game_state.dart';
import 'package:lander_zero/game/state/save_security_manager.dart';
import 'package:lander_zero/game/audio/game_audio_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SaveSecurityManager & Cryptographic HMAC Verification Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      GameAudioManager.isTesting = true;
      await GameState().init(force: true);
    });

    test('computeSignature generates deterministic HMAC-SHA256 hash', () {
      final sig1 = SaveSecurityManager.computeSignature(
        coins: 500,
        ownedRockets: ['sputnik', 'swift'],
        engineLevel: 2,
        fuelLevel: 3,
        shieldLevel: 1,
        leaderboardJson: '[]',
      );

      final sig2 = SaveSecurityManager.computeSignature(
        coins: 500,
        ownedRockets: ['sputnik', 'swift'],
        engineLevel: 2,
        fuelLevel: 3,
        shieldLevel: 1,
        leaderboardJson: '[]',
      );

      expect(sig1.isNotEmpty, isTrue);
      expect(sig1, equals(sig2));
      expect(sig1.length, 64); // SHA-256 hex string is 64 characters
    });

    test('Fleet order does not affect signature determinism (normalization)', () {
      final sigA = SaveSecurityManager.computeSignature(
        coins: 300,
        ownedRockets: ['swift', 'sputnik', 'titan'],
      );

      final sigB = SaveSecurityManager.computeSignature(
        coins: 300,
        ownedRockets: ['sputnik', 'titan', 'swift'],
      );

      expect(sigA, equals(sigB));
    });

    test('verifySignature returns true for authentic payload and false for modified payload', () {
      final sig = SaveSecurityManager.computeSignature(
        coins: 1000,
        ownedRockets: ['sputnik', 'swift'],
      );

      final valid = SaveSecurityManager.verifySignature(
        coins: 1000,
        ownedRockets: ['sputnik', 'swift'],
        signature: sig,
      );
      expect(valid, isTrue);

      final tampered = SaveSecurityManager.verifySignature(
        coins: 999999, // Injected coins
        ownedRockets: ['sputnik', 'swift'],
        signature: sig,
      );
      expect(tampered, isFalse);
    });

    test('computeHmac and verifyHmac contract aliases work identically', () {
      final sig = SaveSecurityManager.computeHmac(
        coins: 250,
        ownedRockets: ['sputnik', 'swift'],
        leaderboardJson: '[]',
      );

      final isValid = SaveSecurityManager.verifyHmac(
        coins: 250,
        ownedRockets: ['sputnik', 'swift'],
        leaderboardJson: '[]',
        signature: sig,
      );
      expect(isValid, isTrue);

      final isInvalid = SaveSecurityManager.verifyHmac(
        coins: 500,
        ownedRockets: ['sputnik', 'swift'],
        leaderboardJson: '[]',
        signature: sig,
      );
      expect(isInvalid, isFalse);
    });
  });

  group('GameState HMAC Tamper Recovery Unit Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      GameAudioManager.isTesting = true;
      await GameState().init(force: true);
    });

    test('Fresh install initializes starter ships [sputnik, swift] and valid HMAC', () async {
      final state = GameState();
      expect(state.ownedRockets, equals(['sputnik', 'swift']));
      expect(state.totalCoins, equals(0));
      expect(state.selectedRocket, equals('sputnik'));

      final prefs = state.prefs;
      final storedSig = prefs.getString(SaveSecurityManager.saveSignatureKey);
      expect(storedSig, isNotNull);

      // Verify that stored signature matches state
      final isValid = SaveSecurityManager.verifySignature(
        coins: state.totalCoins,
        ownedRockets: state.ownedRockets,
        engineLevel: state.engineLevel,
        fuelLevel: state.fuelLevel,
        shieldLevel: state.shieldLevel,
        leaderboardJson: jsonEncode(state.leaderboard),
        signature: storedSig,
      );
      expect(isValid, isTrue);
    });

    test('Coin tampering in SharedPreferences is detected and resets state safely', () async {
      final state = GameState();
      await state.addCoins(500);
      expect(state.totalCoins, 500);

      final prefs = state.prefs;
      // Adversary attempts to inject 999999 coins directly in prefs without computing HMAC
      await prefs.setInt('totalCoins', 999999);

      // Re-initialize GameState (simulating app restart)
      await state.init(force: true);

      // Tamper recovery should restore safe baseline without throwing exception
      expect(state.totalCoins, equals(0));
      expect(state.ownedRockets, equals(['sputnik', 'swift']));
      expect(state.engineLevel, equals(1));
    });

    test('Unauthorized ship unlock in SharedPreferences is detected and reset', () async {
      final state = GameState();
      final prefs = state.prefs;

      // Adversary attempts to inject all ships into ownedRockets without paying
      await prefs.setStringList('ownedRockets', ['sputnik', 'swift', 'cyclone', 'needle', 'titan']);

      // Re-initialize GameState
      await state.init(force: true);

      // Should be reset to starter baseline
      expect(state.ownedRockets, equals(['sputnik', 'swift']));
      expect(state.selectedRocket, equals('sputnik'));
    });

    test('Leaderboard forgery in SharedPreferences is detected and reset', () async {
      final state = GameState();
      final prefs = state.prefs;

      // Adversary fabricates fake high score in leaderboard
      await prefs.setString('leaderboard', jsonEncode([
        {'name': 'Hacker', 'map': 'core', 'distance': 999999, 'coins': 99999}
      ]));

      // Re-initialize GameState
      await state.init(force: true);

      // Tamper recovery clears fabricated leaderboard
      expect(state.leaderboard, isEmpty);
    });
  });

  group('Nickname Sanitization Unit Tests', () {
    test('Strips control characters and newlines', () {
      const malicious = "Pilot\x00\x1F\x7F\n\r";
      final clean = SaveSecurityManager.sanitizeNickname(malicious);
      expect(clean, equals('Pilot'));
    });

    test('Enforces 15 character maximum length', () {
      const overlyLong = "CommanderSuperAstronaut12345";
      final clean = SaveSecurityManager.sanitizeNickname(overlyLong);
      expect(clean.length, 15);
      expect(clean, equals('CommanderSuperA'));
    });

    test('Allows Russian Cyrillic characters and spaces', () {
      const cyrillicName = "Юрий Гагарин";
      final clean = SaveSecurityManager.sanitizeNickname(cyrillicName);
      expect(clean, equals('Юрий Гагарин'));
    });

    test('Allows valid punctuation (dot, dash, underscore, hash)', () {
      const formatted = "Red-Leader_01.X";
      final clean = SaveSecurityManager.sanitizeNickname(formatted);
      expect(clean, equals('Red-Leader_01.X'));
    });

    test('Falls back to safe default if string is completely empty or stripped', () {
      expect(SaveSecurityManager.sanitizeNickname(''), equals('Pilot'));
      expect(SaveSecurityManager.sanitizeNickname('   '), equals('Pilot'));
      expect(SaveSecurityManager.sanitizeNickname('<script>'), equals('Pilot'));
    });

    test('GameState.setNickname uses sanitization automatically', () async {
      final state = GameState();
      await state.init(force: true);

      await state.setNickname("  \x00\x07Major-Tom\n  ");
      expect(state.nickname, equals('Major-Tom'));
    });
  });
}
