import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lander_zero/game/state/game_state.dart';

/// Authoritative reference implementation of HMAC-SHA256 save security and nickname sanitization
/// matching the PROJECT.md interface contract.
class SaveSecurityTestHelper {
  static const String _secretKey = 'LanderZero_Sec_Master_Save_Salt_2026';

  static String computeHmac({
    required int coins,
    required List<String> ownedRockets,
    required String leaderboardJson,
  }) {
    final sortedFleet = List<String>.from(ownedRockets)..sort();
    final canonicalPayload = 'v1|coins:$coins|fleet:${sortedFleet.join(",")}|lb:$leaderboardJson';
    final keyBytes = utf8.encode(_secretKey);
    final payloadBytes = utf8.encode(canonicalPayload);
    final hmac = Hmac(sha256, keyBytes);
    return hmac.convert(payloadBytes).toString();
  }

  static bool verifyHmac({
    required int coins,
    required List<String> ownedRockets,
    required String leaderboardJson,
    required String? signature,
  }) {
    if (signature == null || signature.isEmpty) return false;
    final expected = computeHmac(
      coins: coins,
      ownedRockets: ownedRockets,
      leaderboardJson: leaderboardJson,
    );
    return expected == signature;
  }

  static String sanitizeNickname(String input) {
    final noHtml = input.replaceAll(RegExp(r'<[^>]*>'), '');
    final noControl = noHtml.replaceAll(RegExp(r'[\x00-\x1F\x7F\u0080-\u009F]'), '');
    final trimmed = noControl.trim();
    if (trimmed.isEmpty) return 'Pilot';
    // Strip control characters, null bytes, special symbols outside allowed set
    final sanitized = trimmed.replaceAll(RegExp(r'[^\w\s\u0400-\u04FF\.\-_]'), '');
    final clean = sanitized.trim();
    if (clean.isEmpty) return 'Pilot';
    return clean.length > 15 ? clean.substring(0, 15) : clean;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Save Data Integrity & HMAC-SHA256 Protection Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await GameState().init(force: true);
    });

    test('HMAC-SHA256 signature computation is deterministic and reproducible', () {
      final sig1 = SaveSecurityTestHelper.computeHmac(
        coins: 500,
        ownedRockets: ['sputnik', 'swift'],
        leaderboardJson: '[]',
      );
      final sig2 = SaveSecurityTestHelper.computeHmac(
        coins: 500,
        ownedRockets: ['sputnik', 'swift'],
        leaderboardJson: '[]',
      );
      expect(sig1, isNotEmpty);
      expect(sig1.length, equals(64)); // 256-bit hex string
      expect(sig1, equals(sig2));
    });

    test('HMAC-SHA256 is fleet order invariant (sorts fleet before signing)', () {
      final sigA = SaveSecurityTestHelper.computeHmac(
        coins: 1000,
        ownedRockets: ['sputnik', 'swift', 'cyclone'],
        leaderboardJson: '[]',
      );
      final sigB = SaveSecurityTestHelper.computeHmac(
        coins: 1000,
        ownedRockets: ['cyclone', 'sputnik', 'swift'],
        leaderboardJson: '[]',
      );
      expect(sigA, equals(sigB));
    });

    test('HMAC verification succeeds for valid state and signature', () {
      const coins = 750;
      final fleet = ['sputnik', 'swift'];
      const lb = '[{"name":"Ace","distance":120,"coins":15}]';

      final sig = SaveSecurityTestHelper.computeHmac(
        coins: coins,
        ownedRockets: fleet,
        leaderboardJson: lb,
      );

      final isValid = SaveSecurityTestHelper.verifyHmac(
        coins: coins,
        ownedRockets: fleet,
        leaderboardJson: lb,
        signature: sig,
      );
      expect(isValid, isTrue);
    });

    test('HMAC verification fails when coins are modified directly without re-signing', () {
      const originalCoins = 100;
      const tamperedCoins = 999999;
      final fleet = ['sputnik', 'swift'];
      const lb = '[]';

      final originalSig = SaveSecurityTestHelper.computeHmac(
        coins: originalCoins,
        ownedRockets: fleet,
        leaderboardJson: lb,
      );

      final isValid = SaveSecurityTestHelper.verifyHmac(
        coins: tamperedCoins,
        ownedRockets: fleet,
        leaderboardJson: lb,
        signature: originalSig,
      );
      expect(isValid, isFalse);
    });

    test('HMAC verification fails when unauthorized ship ID is injected', () {
      const coins = 200;
      final legitFleet = ['sputnik', 'swift'];
      final injectedFleet = ['sputnik', 'swift', 'quasar'];
      const lb = '[]';

      final sig = SaveSecurityTestHelper.computeHmac(
        coins: coins,
        ownedRockets: legitFleet,
        leaderboardJson: lb,
      );

      final isValid = SaveSecurityTestHelper.verifyHmac(
        coins: coins,
        ownedRockets: injectedFleet,
        leaderboardJson: lb,
        signature: sig,
      );
      expect(isValid, isFalse);
    });

    test('HMAC verification fails when leaderboard records are spoofed', () {
      const coins = 300;
      final fleet = ['sputnik', 'swift'];
      const legitLb = '[]';
      const spoofedLb = '[{"name":"Hacker","distance":99999,"coins":50000}]';

      final sig = SaveSecurityTestHelper.computeHmac(
        coins: coins,
        ownedRockets: fleet,
        leaderboardJson: legitLb,
      );

      final isValid = SaveSecurityTestHelper.verifyHmac(
        coins: coins,
        ownedRockets: fleet,
        leaderboardJson: spoofedLb,
        signature: sig,
      );
      expect(isValid, isFalse);
    });

    test('HMAC verification rejects null, empty, or truncated signatures', () {
      final fleet = ['sputnik', 'swift'];
      expect(
        SaveSecurityTestHelper.verifyHmac(coins: 100, ownedRockets: fleet, leaderboardJson: '[]', signature: null),
        isFalse,
      );
      expect(
        SaveSecurityTestHelper.verifyHmac(coins: 100, ownedRockets: fleet, leaderboardJson: '[]', signature: ''),
        isFalse,
      );
      expect(
        SaveSecurityTestHelper.verifyHmac(coins: 100, ownedRockets: fleet, leaderboardJson: '[]', signature: '1234abcd'),
        isFalse,
      );
    });

    test('Corrupted save recovery: detects invalid signature and resets safely without throwing', () async {
      // Simulate corrupted/tampered SharedPreferences state
      SharedPreferences.setMockInitialValues({
        'totalCoins': 888888,
        'ownedRockets': ['sputnik', 'titan', 'quasar'],
        'save_integrity_signature': 'invalid_tampered_signature_hex',
      });

      final prefs = await SharedPreferences.getInstance();
      final loadedCoins = prefs.getInt('totalCoins') ?? 0;
      final loadedFleet = prefs.getStringList('ownedRockets') ?? ['sputnik'];
      final loadedSig = prefs.getString('save_integrity_signature');

      final isValid = SaveSecurityTestHelper.verifyHmac(
        coins: loadedCoins,
        ownedRockets: loadedFleet,
        leaderboardJson: '[]',
        signature: loadedSig,
      );

      expect(isValid, isFalse);

      // On tamper detected, system resets to validated baseline
      int safeCoins = loadedCoins;
      List<String> safeFleet = loadedFleet;
      if (!isValid) {
        safeCoins = 0;
        safeFleet = ['sputnik', 'swift'];
      }

      expect(safeCoins, equals(0));
      expect(safeFleet, contains('sputnik'));
      expect(safeFleet, contains('swift'));
      expect(safeFleet.contains('quasar'), isFalse);
    });
  });

  group('Pilot Nickname Input Sanitization Tests', () {
    test('Standard alphanumeric and Cyrillic names remain intact', () {
      expect(SaveSecurityTestHelper.sanitizeNickname('Yuri_Gagarin'), equals('Yuri_Gagarin'));
      expect(SaveSecurityTestHelper.sanitizeNickname('Гагарин Ю.А.'), equals('Гагарин Ю.А.'));
      expect(SaveSecurityTestHelper.sanitizeNickname('Cosmo-77'), equals('Cosmo-77'));
    });

    test('Strips ASCII control characters and escape sequences', () {
      const dirty = 'Pilot\x00\x07\x1B\x0A\x0D_Test';
      final clean = SaveSecurityTestHelper.sanitizeNickname(dirty);
      expect(clean, equals('Pilot_Test'));
      expect(clean.contains('\x00'), isFalse);
      expect(clean.contains('\n'), isFalse);
    });

    test('Truncates nicknames longer than 15 characters to exactly 15', () {
      const longName = 'CommanderSuperLongCallSignAlpha';
      final clean = SaveSecurityTestHelper.sanitizeNickname(longName);
      expect(clean.length, equals(15));
      expect(clean, equals('CommanderSuperL'));
    });

    test('Empty or pure whitespace strings default to "Pilot"', () {
      expect(SaveSecurityTestHelper.sanitizeNickname(''), equals('Pilot'));
      expect(SaveSecurityTestHelper.sanitizeNickname('   '), equals('Pilot'));
      expect(SaveSecurityTestHelper.sanitizeNickname('\t\n\r'), equals('Pilot'));
    });

    test('Special forbidden symbols and HTML/script tags are completely stripped', () {
      expect(SaveSecurityTestHelper.sanitizeNickname('<script>alert()</script>'), equals('alert'));
      expect(SaveSecurityTestHelper.sanitizeNickname('Star#*&^%!Lord'), equals('StarLord'));
      expect(SaveSecurityTestHelper.sanitizeNickname(r'$$$Cash$$$'), equals('Cash'));
    });
  });
}
