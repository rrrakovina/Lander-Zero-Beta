import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lander_zero/game/state/game_state.dart';
import 'package:lander_zero/game/state/achievements_manager.dart';
import 'package:lander_zero/game/state/save_security_manager.dart';
import 'package:lander_zero/game/audio/game_audio_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adversarial Test Suite 1: Nickname Sanitization Fuzzing & Injection Defense', () {
    test('1.1 Empty and pure whitespace strings strictly fallback to default "Pilot"', () {
      final emptyInputs = [
        '',
        ' ',
        '   ',
        '\t',
        '\n',
        '\r',
        '\r\n',
        '\t\t\n\r  \t',
        '       \t\t\t       ',
      ];

      for (final input in emptyInputs) {
        final result = SaveSecurityManager.sanitizeNickname(input);
        expect(result, equals('Pilot'),
            reason: 'Failed to fallback to "Pilot" for input: ${jsonEncode(input)}');
      }
    });

    test('1.2 ASCII Control Characters & C1 Control Codes (0x00-0x1F, 0x7F, 0x80-0x9F) are stripped', () {
      // Test all C0 control characters
      for (int c = 0x00; c <= 0x1F; c++) {
        final char = String.fromCharCode(c);
        final input = 'Hero${char}Pilot';
        final result = SaveSecurityManager.sanitizeNickname(input);
        expect(result, equals('HeroPilot'),
            reason: 'Failed to strip C0 control char 0x${c.toRadixString(16)}');
      }

      // Test DEL (0x7F)
      expect(SaveSecurityManager.sanitizeNickname('Hero\x7FPilot'), equals('HeroPilot'));

      // Test C1 control characters (0x80 - 0x9F)
      for (int c = 0x80; c <= 0x9F; c++) {
        final char = String.fromCharCode(c);
        final input = 'Hero${char}Pilot';
        final result = SaveSecurityManager.sanitizeNickname(input);
        expect(result, equals('HeroPilot'),
            reason: 'Failed to strip C1 control char 0x${c.toRadixString(16)}');
      }
    });

    test('1.3 ANSI Terminal Escape Codes & Command sequences are neutralized', () {
      final escapeSequences = [
        '\x1B[31mRedPilot\x1B[0m',
        '\x1B[2J\x1B[HCommander',
        '\x1B]0;Title\x07Ace',
        '\x1B[?25hFalcon',
        '\x1B[1;32;40mGreenText\x1B[0m',
      ];

      for (final seq in escapeSequences) {
        final result = SaveSecurityManager.sanitizeNickname(seq);
        expect(result.contains('\x1B'), isFalse);
        expect(result.contains('\x07'), isFalse);
        expect(result.isNotEmpty, isTrue);
        expect(result.length, lessThanOrEqualTo(15));
      }
    });

    test('1.4 HTML & JavaScript XSS Injection Payloads are stripped/sanitized', () {
      final xssPayloads = [
        '<script>alert("XSS")</script>',
        '<script src="evil.js"></script>',
        '<img src=x onerror=alert(1)>',
        '<svg/onload=alert("XSS")>',
        '<iframe src="javascript:alert(1)"></iframe>',
        '<body onload=alert("XSS")>',
        '<a href="javascript:alert(1)">Click</a>',
        '<style>@import"evil.css";</style>',
        '"><script>alert(1)</script>',
        '<b><i><u>Formatted</u></i></b>',
        '"><img src=x onerror=prompt(1)>',
        '<input type="text" value="injection">',
      ];

      for (final payload in xssPayloads) {
        final result = SaveSecurityManager.sanitizeNickname(payload);
        expect(result.contains('<'), isFalse, reason: 'Found unstripped "<" in $result for payload $payload');
        expect(result.contains('>'), isFalse, reason: 'Found unstripped ">" in $result for payload $payload');
        expect(result.isNotEmpty, isTrue);
        expect(result.length, lessThanOrEqualTo(15));
      }
    });

    test('1.5 Unicode Zero-Width, Invisible Characters, and Bidirectional Overrides are neutralized', () {
      final invisibleInputs = [
        'Pilot\u200B1', // Zero-width space
        'Pilot\u200C2', // Zero-width non-joiner
        'Pilot\u200D3', // Zero-width joiner
        'Pilot\uFEFF4', // Byte order mark / ZWNBSP
        'Pilot\u202E5', // Right-to-left override
        'Pilot\u200E6', // Left-to-right mark
        'Pilot\u200F7', // Right-to-left mark
        '\u200B\u200C\u200D\uFEFF', // Pure invisible chars
      ];

      for (final input in invisibleInputs) {
        final result = SaveSecurityManager.sanitizeNickname(input);
        expect(result.isNotEmpty, isTrue);
        expect(result.length, lessThanOrEqualTo(15));
        if (input == '\u200B\u200C\u200D\uFEFF') {
          expect(result, equals('Pilot'));
        }
      }
    });

    test('1.6 SQL Injection, Command Injection & Path Traversal strings are sanitized', () {
      final injectionStrings = [
        "' OR '1'='1",
        "admin'--",
        "Robert'); DROP TABLE Students;--",
        "UNION SELECT null, username, password FROM users--",
        "../../../../etc/passwd",
        r"..\..\..\windows\system32\cmd.exe",
        "; rm -rf / ;",
        "| cat /etc/shadow",
        r"$(reboot)",
        "`ping localhost`",
        "%00%0d%0a",
      ];

      for (final injection in injectionStrings) {
        final result = SaveSecurityManager.sanitizeNickname(injection);
        expect(result.isNotEmpty, isTrue);
        expect(result.length, lessThanOrEqualTo(15));
        expect(result.contains("'"), isFalse);
        expect(result.contains(';'), isFalse);
        expect(result.contains('"'), isFalse);
        expect(result.contains(r'$'), isFalse);
        expect(result.contains('`'), isFalse);
        expect(result.contains('|'), isFalse);
      }
    });

    test('1.7 Overly long strings and mega-buffers are truncated to exactly 15 characters without timeout', () {
      final longString100 = 'A' * 100;
      final longString1000 = 'CosmoNavigatorAlphaBetaGammaDelta' * 30;
      final longString50000 = 'X' * 50000;

      final sw = Stopwatch()..start();
      final res100 = SaveSecurityManager.sanitizeNickname(longString100);
      final res1000 = SaveSecurityManager.sanitizeNickname(longString1000);
      final res50000 = SaveSecurityManager.sanitizeNickname(longString50000);
      sw.stop();

      expect(res100.length, equals(15));
      expect(res100, equals('A' * 15));
      expect(res1000.length, equals(15));
      expect(res50000.length, equals(15));
      expect(res50000, equals('X' * 15));
      expect(sw.elapsedMilliseconds, lessThan(1000),
          reason: 'Sanitization took too long on mega-buffers (possible ReDoS)');
    });

    test('1.8 Valid Cyrillic, Latin, digits, spaces, and allowed punctuation (. - _) are preserved', () {
      final validInputs = [
        'Юрий Гагарин',
        'СССР-01',
        'Swift_02.B',
        'Cosmo-Ace.77',
        'Валентина Т.',
        'Red_Leader-1',
        'Lander.Zero_99',
      ];

      for (final input in validInputs) {
        final result = SaveSecurityManager.sanitizeNickname(input);
        expect(result, equals(input),
            reason: 'Valid input was mutated unexpectedly: $input -> $result');
      }
    });

    test('1.9 Invariant properties hold over randomized fuzz inputs', () {
      final characters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789абвгдеёжзийклмнопрстуфхцчшщъыьэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ!@#\$%^&*()_+-=[]{}|;:\'",.<>/?~` \t\n\r\x00\x1F\x7F';
      
      for (int seed = 0; seed < 100; seed++) {
        final buffer = StringBuffer();
        final len = (seed * 37) % 80;
        for (int i = 0; i < len; i++) {
          final charIdx = ((seed + 1) * 31 + i * 17) % characters.length;
          buffer.write(characters[charIdx]);
        }
        final raw = buffer.toString();
        final sanitized = SaveSecurityManager.sanitizeNickname(raw);

        expect(sanitized.isNotEmpty, isTrue, reason: 'Sanitized nickname must never be empty');
        expect(sanitized.length, lessThanOrEqualTo(15), reason: 'Length must be <= 15');
        expect(sanitized.trim(), equals(sanitized), reason: 'Must not have leading/trailing whitespace');
      }
    });
  });

  group('Adversarial Test Suite 2: SaveSecurityManager HMAC Cryptographic Integrity', () {
    test('2.1 Tampering with single bits or characters in HMAC signature invalidates verification', () {
      final originalSig = SaveSecurityManager.computeSignature(
        coins: 1000,
        ownedRockets: ['sputnik', 'swift'],
        engineLevel: 2,
        fuelLevel: 3,
        shieldLevel: 4,
        leaderboardJson: '[]',
      );

      // Verify authentic passes
      expect(
        SaveSecurityManager.verifySignature(
          coins: 1000,
          ownedRockets: ['sputnik', 'swift'],
          engineLevel: 2,
          fuelLevel: 3,
          shieldLevel: 4,
          leaderboardJson: '[]',
          signature: originalSig,
        ),
        isTrue,
      );

      // Mutate every character position in signature
      for (int i = 0; i < originalSig.length; i += 8) {
        final mutatedChar = originalSig[i] == 'a' ? 'b' : 'a';
        final tamperedSig = originalSig.substring(0, i) + mutatedChar + originalSig.substring(i + 1);

        final isValid = SaveSecurityManager.verifySignature(
          coins: 1000,
          ownedRockets: ['sputnik', 'swift'],
          engineLevel: 2,
          fuelLevel: 3,
          shieldLevel: 4,
          leaderboardJson: '[]',
          signature: tamperedSig,
        );
        expect(isValid, isFalse, reason: 'Tampered signature passed verification at index $i');
      }
    });

    test('2.2 Malformed, truncated, null, and empty signatures are rejected safely', () {
      final badSignatures = [
        null,
        '',
        ' ',
        'a',
        '12345678',
        '0' * 63, // 63 chars instead of 64
        '0' * 65, // 65 chars
        'invalid_non_hex_signature_string_that_is_long_enough_to_simulate_hash!',
        '----------------------------------------------------------------',
        "' OR '1'='1",
      ];

      for (final badSig in badSignatures) {
        final isValid = SaveSecurityManager.verifySignature(
          coins: 500,
          ownedRockets: ['sputnik', 'swift'],
          leaderboardJson: '[]',
          signature: badSig,
        );
        expect(isValid, isFalse, reason: 'Bad signature should have been rejected: $badSig');
      }
    });

    test('2.3 Coin tampering (increments, negative, max int, boundary values) fails HMAC', () {
      final sig = SaveSecurityManager.computeSignature(
        coins: 100,
        ownedRockets: ['sputnik', 'swift'],
      );

      final tamperedCoinValues = [
        101, // +1 coin
        99,  // -1 coin
        0,   // reset to 0
        999999, // large injection
        -1, // negative
        -50000,
        0x7FFFFFFF, // 32-bit MAX_INT
      ];

      for (final coinVal in tamperedCoinValues) {
        final isValid = SaveSecurityManager.verifySignature(
          coins: coinVal,
          ownedRockets: ['sputnik', 'swift'],
          signature: sig,
        );
        expect(isValid, isFalse, reason: 'Tampered coin value $coinVal passed HMAC verification!');
      }
    });

    test('2.4 Fleet tampering (injected ships, unearned unlocks, unauthorized IDs) fails HMAC', () {
      final sig = SaveSecurityManager.computeSignature(
        coins: 500,
        ownedRockets: ['sputnik', 'swift'],
      );

      final tamperedFleets = [
        ['sputnik', 'swift', 'cyclone'], // Unpaid ship
        ['sputnik', 'swift', 'titan'],
        ['sputnik', 'swift', 'needle'],
        ['sputnik'], // Missing starter ship
        ['titan'], // Stolen single ship
        ['sputnik', 'swift', 'death_star_9000'], // Invalid ship ID
        <String>[], // Empty fleet
      ];

      for (final fleet in tamperedFleets) {
        final isValid = SaveSecurityManager.verifySignature(
          coins: 500,
          ownedRockets: fleet,
          signature: sig,
        );
        expect(isValid, isFalse, reason: 'Tampered fleet $fleet passed HMAC verification!');
      }
    });

    test('2.5 Upgrade level tampering (clamping limits, forged stats) fails HMAC', () {
      final sig = SaveSecurityManager.computeSignature(
        coins: 200,
        ownedRockets: ['sputnik', 'swift'],
        engineLevel: 1,
        fuelLevel: 1,
        shieldLevel: 1,
      );

      final tamperedUpgrades = [
        {'e': 2, 'f': 1, 's': 1},
        {'e': 1, 'f': 5, 's': 1},
        {'e': 1, 'f': 1, 's': 5},
        {'e': 5, 'f': 5, 's': 5},
        {'e': 99, 'f': 99, 's': 99},
        {'e': 0, 'f': 1, 's': 1},
        {'e': -1, 'f': -1, 's': -1},
      ];

      for (final up in tamperedUpgrades) {
        final isValid = SaveSecurityManager.verifySignature(
          coins: 200,
          ownedRockets: ['sputnik', 'swift'],
          engineLevel: up['e']!,
          fuelLevel: up['f']!,
          shieldLevel: up['s']!,
          signature: sig,
        );
        expect(isValid, isFalse, reason: 'Tampered upgrade $up passed HMAC verification!');
      }
    });

    test('2.6 Leaderboard tampering (injected highscores, modified ranks) fails HMAC', () {
      final sig = SaveSecurityManager.computeSignature(
        coins: 300,
        ownedRockets: ['sputnik', 'swift'],
        leaderboardJson: '[]',
      );

      final tamperedLbJson = [
        '[{"name":"Hacker","map":"core","distance":99999,"coins":99999}]',
        '[{"name":"Pilot","map":"echo","distance":100,"coins":10}]',
        'null',
        '{}',
        'invalid_json',
      ];

      for (final lb in tamperedLbJson) {
        final isValid = SaveSecurityManager.verifySignature(
          coins: 300,
          ownedRockets: ['sputnik', 'swift'],
          leaderboardJson: lb,
          signature: sig,
        );
        expect(isValid, isFalse, reason: 'Tampered leaderboard $lb passed HMAC verification!');
      }
    });

    test('2.7 Achievements signature HMAC verification', () {
      const legitJson = '[{"id":"soft_landing","progress":1,"isUnlocked":true}]';
      final sig = SaveSecurityManager.computeAchievementsSignature(legitJson);

      expect(SaveSecurityManager.verifyAchievementsSignature(legitJson, sig), isTrue);

      // Tampered JSON
      const tamperedJson = '[{"id":"fleet_admiral","progress":1,"isUnlocked":true}]';
      expect(SaveSecurityManager.verifyAchievementsSignature(tamperedJson, sig), isFalse);

      // Bad sig
      expect(SaveSecurityManager.verifyAchievementsSignature(legitJson, 'bad_sig'), isFalse);
      expect(SaveSecurityManager.verifyAchievementsSignature(legitJson, null), isFalse);
      expect(SaveSecurityManager.verifyAchievementsSignature(legitJson, ''), isFalse);
    });
  });

  group('Adversarial Test Suite 3: GameState Graceful Tamper & Corruption Recovery', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      GameAudioManager.isTesting = true;
    });

    test('3.1 Direct coin injection in SharedPreferences triggers graceful recovery to 0 coins', () async {
      final state = GameState();
      await state.init(force: true);
      await state.addCoins(200);
      expect(state.totalCoins, 200);

      final prefs = state.prefs;
      await prefs.setInt('totalCoins', 999999);

      await state.init(force: true);

      expect(state.totalCoins, equals(0));
      expect(state.ownedRockets, equals(['sputnik', 'swift']));
      expect(state.engineLevel, equals(1));
      expect(state.fuelLevel, equals(1));
      expect(state.shieldLevel, equals(1));

      final repairedSig = prefs.getString(SaveSecurityManager.saveSignatureKey);
      expect(repairedSig, isNotNull);
      expect(
        SaveSecurityManager.verifySignature(
          coins: state.totalCoins,
          ownedRockets: state.ownedRockets,
          engineLevel: state.engineLevel,
          fuelLevel: state.fuelLevel,
          shieldLevel: state.shieldLevel,
          leaderboardJson: jsonEncode(state.leaderboard),
          signature: repairedSig,
        ),
        isTrue,
      );
    });

    test('3.2 Direct fleet injection in SharedPreferences triggers graceful recovery to starter fleet', () async {
      final state = GameState();
      await state.init(force: true);

      final prefs = state.prefs;
      await prefs.setStringList('ownedRockets', ['sputnik', 'swift', 'cyclone', 'needle', 'titan']);
      await prefs.setString('selectedRocket', 'titan');

      await state.init(force: true);

      expect(state.ownedRockets, equals(['sputnik', 'swift']));
      expect(state.selectedRocket, equals('sputnik'));
    });

    test('3.3 Corrupted unparseable leaderboard JSON does not crash GameState.init', () async {
      final state = GameState();
      await state.init(force: true);

      final prefs = state.prefs;
      final sig = SaveSecurityManager.computeSignature(
        coins: 0,
        ownedRockets: ['sputnik', 'swift'],
        leaderboardJson: 'broken{json:!!',
      );
      await prefs.setString('leaderboard', 'broken{json:!!');
      await prefs.setString(SaveSecurityManager.saveSignatureKey, sig);

      await state.init(force: true);

      expect(state.leaderboard, isEmpty);
    });

    test('3.4 Empty or null fields in SharedPreferences are handled gracefully', () async {
      SharedPreferences.setMockInitialValues({});

      final state = GameState();
      await state.init(force: true);

      expect(state.totalCoins, equals(0));
      expect(state.ownedRockets, equals(['sputnik', 'swift']));
      expect(state.selectedRocket, equals('sputnik'));
      expect(state.engineLevel, equals(1));
      expect(state.fuelLevel, equals(1));
      expect(state.shieldLevel, equals(1));
      expect(state.leaderboard, isEmpty);
    });

    test('3.5 Legacy save data without signature is migrated smoothly without loss', () async {
      SharedPreferences.setMockInitialValues({
        'totalCoins': 750,
        'ownedRockets': ['sputnik', 'swift', 'cyclone'],
        'selectedRocket': 'cyclone',
        'engineLevel': 3,
        'fuelLevel': 2,
        'shieldLevel': 4,
        'leaderboard': jsonEncode([
          {'name': 'Veteran', 'map': 'wind', 'distance': 350, 'coins': 45}
        ]),
      });

      final state = GameState();
      await state.init(force: true);

      expect(state.totalCoins, equals(750));
      expect(state.ownedRockets, containsAll(['sputnik', 'swift', 'cyclone']));
      expect(state.selectedRocket, equals('cyclone'));
      expect(state.engineLevel, equals(3));
      expect(state.fuelLevel, equals(2));
      expect(state.shieldLevel, equals(4));
      expect(state.leaderboard.length, equals(1));
      expect(state.leaderboard.first['name'], equals('Veteran'));

      final newSig = state.prefs.getString(SaveSecurityManager.saveSignatureKey);
      expect(newSig, isNotNull);
      expect(
        SaveSecurityManager.verifySignature(
          coins: 750,
          ownedRockets: state.ownedRockets,
          engineLevel: 3,
          fuelLevel: 2,
          shieldLevel: 4,
          leaderboardJson: jsonEncode(state.leaderboard),
          signature: newSig,
        ),
        isTrue,
      );
    });

    test('3.6 Nickname loaded from SharedPreferences is sanitized on init', () async {
      SharedPreferences.setMockInitialValues({
        'nickname': '<script>alert("hacked")</script>\x00\x1BCommander-01',
      });

      final state = GameState();
      await state.init(force: true);

      expect(state.nickname, equals('alerthackedComm'));
      expect(state.nickname.length, equals(15));
      expect(state.nickname.contains('<'), isFalse);
      expect(state.nickname.contains('>'), isFalse);
    });
  });

  group('Adversarial Test Suite 4: Achievements Security & Exploit Resistance', () {
    late AchievementsManager manager;
    late GameState state;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      GameAudioManager.isTesting = true;
      state = GameState();
      await state.init(force: true);
      manager = AchievementsManager();
      for (final a in manager.achievements) {
        a.isUnlocked = false;
        a.progress = 0;
      }
    });

    test('4.1 Negative guard: Failed missions (isSuccess: false) NEVER unlock mission achievements', () {
      manager.checkMissionCompletionStats(
        prefs: state.prefs,
        damageTaken: 0.0,
        fuelPercentRemaining: 1.0,
        missionSeconds: 10.0,
        coinsCollected: 100,
        isSuccess: false,
        mapId: 'ice',
        ropeSnapped: false,
      );

      for (final ach in manager.achievements) {
        expect(ach.isUnlocked, isFalse, reason: 'Achievement ${ach.id} unlocked on failed mission!');
      }
    });

    test('4.2 Achievements signature mismatch triggers reset to default locked state', () async {
      manager.unlockById('soft_landing', state.prefs);
      manager.unlockById('eco_pilot', state.prefs);
      await manager.save(state.prefs);

      await state.prefs.setString(SaveSecurityManager.achievementsSignatureKey, 'forged_signature_hex_123');
      await manager.load(state.prefs);

      for (final ach in manager.achievements) {
        expect(ach.isUnlocked, isFalse);
        expect(ach.progress, 0);
      }
    });

    test('4.3 Re-triggering achievements cannot double-award coins', () {
      expect(state.totalCoins, 0);

      for (int i = 0; i < 100; i++) {
        manager.unlockById('speed_rescue', state.prefs);
      }

      expect(state.totalCoins, equals(120));
      expect(manager.achievements.firstWhere((a) => a.id == 'speed_rescue').isUnlocked, isTrue);
    });

    test('4.4 Unlocking all 12 achievements delivers exactly 2300 starReward coins', () {
      expect(state.totalCoins, 0);

      for (final ach in manager.achievements) {
        manager.unlockById(ach.id, state.prefs);
      }

      expect(state.totalCoins, equals(2300));
    });

    test('4.5 Malformed unparseable JSON string in achievements_data is caught safely', () async {
      await state.prefs.setString('achievements_data', '{malformed_json: true}');
      await state.prefs.setString(SaveSecurityManager.achievementsSignatureKey, 'some_sig');

      await manager.load(state.prefs);

      for (final a in manager.achievements) {
        expect(a.isUnlocked, isFalse);
        expect(a.progress, 0);
      }
    });

    test('4.6 newlyUnlocked ValueNotifier fires on first unlock and is silent on duplicate', () {
      Achievement? capturedToast;
      int triggerCount = 0;

      void listener() {
        if (manager.newlyUnlocked.value != null) {
          capturedToast = manager.newlyUnlocked.value;
          triggerCount++;
        }
      }

      manager.newlyUnlocked.addListener(listener);

      manager.unlockById('ice_breaker', state.prefs);
      expect(capturedToast, isNotNull);
      expect(capturedToast?.id, equals('ice_breaker'));
      expect(triggerCount, 1);

      manager.unlockById('ice_breaker', state.prefs);
      expect(triggerCount, 1);

      manager.newlyUnlocked.removeListener(listener);
    });
  });
}
