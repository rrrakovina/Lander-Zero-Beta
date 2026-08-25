import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages cryptographic HMAC-SHA256 checksumming, save verification,
/// tamper/corruption recovery, and nickname sanitization for Lander Zero.
class SaveSecurityManager {
  static const String _masterSecretKey =
      'LanderZero_Sec_Master_Integrity_Salt_2026!#AtmosphericSpaceRescue';
  static const String saveSignatureKey = 'save_integrity_signature';
  static const String achievementsSignatureKey = 'achievements_integrity_signature';

  /// Generates canonical payload string for core game state save data
  static String buildSavePayload({
    required int coins,
    required List<String> ownedRockets,
    int engineLevel = 1,
    int fuelLevel = 1,
    int shieldLevel = 1,
    String leaderboardJson = '[]',
    String suitColor = 'classic_orange',
    String selectedHelmet = 'sphere1',
    List<String> ownedHelmets = const ['sphere1'],
    String selectedSuit = 'sk1_cadet',
    List<String> ownedSuits = const ['sk1_cadet'],
  }) {
    final normalizedFleet = [...ownedRockets]..sort();
    final normalizedHelmets = [...ownedHelmets]..sort();
    final normalizedSuits = [...ownedSuits]..sort();
    return 'v1|coins:$coins|fleet:${normalizedFleet.join(",")}|upgrades:$engineLevel,$fuelLevel,$shieldLevel|lb:$leaderboardJson|wardrobe:$suitColor,$selectedHelmet,${normalizedHelmets.join(",")},$selectedSuit,${normalizedSuits.join(",")}';
  }

  /// Computes HMAC-SHA256 signature for given save data
  static String computeSignature({
    required int coins,
    required List<String> ownedRockets,
    int engineLevel = 1,
    int fuelLevel = 1,
    int shieldLevel = 1,
    String leaderboardJson = '[]',
    String suitColor = 'classic_orange',
    String selectedHelmet = 'sphere1',
    List<String> ownedHelmets = const ['sphere1'],
    String selectedSuit = 'sk1_cadet',
    List<String> ownedSuits = const ['sk1_cadet'],
  }) {
    final payload = buildSavePayload(
      coins: coins,
      ownedRockets: ownedRockets,
      engineLevel: engineLevel,
      fuelLevel: fuelLevel,
      shieldLevel: shieldLevel,
      leaderboardJson: leaderboardJson,
      suitColor: suitColor,
      selectedHelmet: selectedHelmet,
      ownedHelmets: ownedHelmets,
      selectedSuit: selectedSuit,
      ownedSuits: ownedSuits,
    );
    final keyBytes = utf8.encode(_masterSecretKey);
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(utf8.encode(payload));
    return digest.toString();
  }

  /// Alias matching interface contract computeHmac
  static String computeHmac({
    required int coins,
    required List<String> ownedRockets,
    required String leaderboardJson,
    int engineLevel = 1,
    int fuelLevel = 1,
    int shieldLevel = 1,
    String suitColor = 'classic_orange',
    String selectedHelmet = 'sphere1',
    List<String> ownedHelmets = const ['sphere1'],
    String selectedSuit = 'sk1_cadet',
    List<String> ownedSuits = const ['sk1_cadet'],
  }) {
    return computeSignature(
      coins: coins,
      ownedRockets: ownedRockets,
      engineLevel: engineLevel,
      fuelLevel: fuelLevel,
      shieldLevel: shieldLevel,
      leaderboardJson: leaderboardJson,
      suitColor: suitColor,
      selectedHelmet: selectedHelmet,
      ownedHelmets: ownedHelmets,
      selectedSuit: selectedSuit,
      ownedSuits: ownedSuits,
    );
  }

  /// Verifies if the provided signature matches the state
  static bool verifySignature({
    required int coins,
    required List<String> ownedRockets,
    int engineLevel = 1,
    int fuelLevel = 1,
    int shieldLevel = 1,
    String leaderboardJson = '[]',
    String suitColor = 'classic_orange',
    String selectedHelmet = 'sphere1',
    List<String> ownedHelmets = const ['sphere1'],
    String selectedSuit = 'sk1_cadet',
    List<String> ownedSuits = const ['sk1_cadet'],
    required String? signature,
  }) {
    if (signature == null || signature.isEmpty) return false;
    final expected = computeSignature(
      coins: coins,
      ownedRockets: ownedRockets,
      engineLevel: engineLevel,
      fuelLevel: fuelLevel,
      shieldLevel: shieldLevel,
      leaderboardJson: leaderboardJson,
      suitColor: suitColor,
      selectedHelmet: selectedHelmet,
      ownedHelmets: ownedHelmets,
      selectedSuit: selectedSuit,
      ownedSuits: ownedSuits,
    );
    return expected == signature;
  }

  /// Alias matching interface contract verifyHmac
  static bool verifyHmac({
    required int coins,
    required List<String> ownedRockets,
    required String leaderboardJson,
    required String? signature,
    int engineLevel = 1,
    int fuelLevel = 1,
    int shieldLevel = 1,
    String suitColor = 'classic_orange',
    String selectedHelmet = 'sphere1',
    List<String> ownedHelmets = const ['sphere1'],
    String selectedSuit = 'sk1_cadet',
    List<String> ownedSuits = const ['sk1_cadet'],
  }) {
    return verifySignature(
      coins: coins,
      ownedRockets: ownedRockets,
      engineLevel: engineLevel,
      fuelLevel: fuelLevel,
      shieldLevel: shieldLevel,
      leaderboardJson: leaderboardJson,
      suitColor: suitColor,
      selectedHelmet: selectedHelmet,
      ownedHelmets: ownedHelmets,
      selectedSuit: selectedSuit,
      ownedSuits: ownedSuits,
      signature: signature,
    );
  }

  /// Computes HMAC-SHA256 signature for achievements payload
  static String computeAchievementsSignature(String achievementsJson) {
    final payload = 'v1|ach:$achievementsJson';
    final keyBytes = utf8.encode('${_masterSecretKey}_Achievements');
    final hmac = Hmac(sha256, keyBytes);
    return hmac.convert(utf8.encode(payload)).toString();
  }

  /// Verifies HMAC-SHA256 signature for achievements payload
  static bool verifyAchievementsSignature(String achievementsJson, String? signature) {
    if (signature == null || signature.isEmpty) return false;
    final expected = computeAchievementsSignature(achievementsJson);
    return expected == signature;
  }

  /// Strips ASCII control characters, non-printable characters, HTML/control symbols,
  /// trims whitespace, and enforces length constraint of 1 to 15 valid characters.
  /// If empty after sanitization, falls back to a safe default 'Pilot'.
  static String sanitizeNickname(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return 'Pilot';

    // Strip HTML/XML tags first
    final noHtml = trimmed.replaceAll(RegExp(r'<[^>]*>'), '');

    // Remove control characters (0x00 - 0x1F, 0x7F, 0x80 - 0x9F)
    final noControl = noHtml.replaceAll(RegExp(r'[\x00-\x1F\x7F\u0080-\u009F]'), '');

    // Allow alphanumeric latin, cyrillic, spaces, and safe punctuation (. - _)
    final sanitized = noControl.replaceAll(RegExp(r'[^\w\s\u0400-\u04FF\.\-_]'), '');
    final cleanResult = sanitized.trim();
    if (cleanResult.isEmpty) return 'Pilot';

    if (cleanResult.length > 15) {
      return cleanResult.substring(0, 15);
    }
    return cleanResult;
  }

  /// Persists the master integrity signature into SharedPreferences
  static Future<void> saveSignature(
    SharedPreferences prefs, {
    required int coins,
    required List<String> ownedRockets,
    required int engineLevel,
    required int fuelLevel,
    required int shieldLevel,
    required String leaderboardJson,
    String suitColor = 'classic_orange',
    String selectedHelmet = 'sphere1',
    List<String> ownedHelmets = const ['sphere1'],
    String selectedSuit = 'sk1_cadet',
    List<String> ownedSuits = const ['sk1_cadet'],
  }) async {
    final sig = computeSignature(
      coins: coins,
      ownedRockets: ownedRockets,
      engineLevel: engineLevel,
      fuelLevel: fuelLevel,
      shieldLevel: shieldLevel,
      leaderboardJson: leaderboardJson,
      suitColor: suitColor,
      selectedHelmet: selectedHelmet,
      ownedHelmets: ownedHelmets,
      selectedSuit: selectedSuit,
      ownedSuits: ownedSuits,
    );
    await prefs.setString(saveSignatureKey, sig);
  }

  /// Persists achievements signature into SharedPreferences
  static Future<void> saveAchievementsSignature(
    SharedPreferences prefs,
    String achievementsJson,
  ) async {
    final sig = computeAchievementsSignature(achievementsJson);
    await prefs.setString(achievementsSignatureKey, sig);
  }
}
