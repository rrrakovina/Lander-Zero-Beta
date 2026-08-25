import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_state.dart';
import 'save_security_manager.dart';

class Achievement {
  final String id;
  final String titleRu;
  final String titleEn;
  final String descRu;
  final String descEn;
  final int starReward;
  final IconData icon;
  final int maxProgress;
  int progress;
  bool isUnlocked;

  Achievement({
    required this.id,
    required this.titleRu,
    required this.titleEn,
    required this.descRu,
    required this.descEn,
    required this.starReward,
    required this.icon,
    this.maxProgress = 1,
    this.progress = 0,
    this.isUnlocked = false,
  });

  String getTitle(String lang) => lang == 'ru' ? titleRu : titleEn;
  String getDesc(String lang) => lang == 'ru' ? descRu : descEn;

  Map<String, dynamic> toJson() => {
    'id': id,
    'progress': progress,
    'isUnlocked': isUnlocked,
  };

  void updateFromJson(Map<String, dynamic> json) {
    progress = json['progress'] ?? progress;
    isUnlocked = json['isUnlocked'] ?? isUnlocked;
  }
}

class AchievementsManager {
  static final AchievementsManager _instance = AchievementsManager._internal();
  factory AchievementsManager() => _instance;
  AchievementsManager._internal();

  final ValueNotifier<Achievement?> newlyUnlocked = ValueNotifier(null);

  final List<Achievement> achievements = [
    Achievement(
      id: 'soft_landing',
      titleRu: 'Мягкая посадка',
      titleEn: 'Soft Landing',
      descRu: 'Завершить спасение без повреждений корпуса',
      descEn: 'Complete a rescue mission with 0 hull damage',
      starReward: 100,
      icon: Icons.shield_rounded,
    ),
    Achievement(
      id: 'eco_pilot',
      titleRu: 'Эко-пилот',
      titleEn: 'Eco Pilot',
      descRu: 'Завершить миссию с остатком топлива > 50%',
      descEn: 'Complete mission with > 50% fuel remaining',
      starReward: 80,
      icon: Icons.local_gas_station_rounded,
    ),
    Achievement(
      id: 'speed_rescue',
      titleRu: 'Скоростной подъем',
      titleEn: 'Speed Rescue',
      descRu: 'Завершить миссию быстрее чем за 45 секунд',
      descEn: 'Complete mission in under 45 seconds',
      starReward: 120,
      icon: Icons.timer_rounded,
    ),
    Achievement(
      id: 'treasure_hunter',
      titleRu: 'Кладоискатель',
      titleEn: 'Treasure Hunter',
      descRu: 'Собрать не менее 10 монет/звезд за один вылет',
      descEn: 'Collect at least 10 coins/stars in one flight',
      starReward: 100,
      icon: Icons.stars_rounded,
    ),
    Achievement(
      id: 'cave_veteran',
      titleRu: 'Ветеран пещер',
      titleEn: 'Cave Veteran',
      descRu: 'Завершить 5 успешных спасательных миссий',
      descEn: 'Complete 5 successful rescue missions',
      starReward: 250,
      maxProgress: 5,
      icon: Icons.military_tech_rounded,
    ),
    Achievement(
      id: 'speed_demon',
      titleRu: 'Демон скорости',
      titleEn: 'Speed Demon',
      descRu: 'Развить скорость полета более 11 м/с',
      descEn: 'Reach flight velocity over 11 m/s',
      starReward: 150,
      icon: Icons.speed_rounded,
    ),
    Achievement(
      id: 'titanium_tether',
      titleRu: 'Титановый трос',
      titleEn: 'Titanium Tether',
      descRu: 'Завершить спасение в Солнечных Ветрах без обрыва троса',
      descEn: 'Complete Solar Winds mission without tether snapping',
      starReward: 150,
      icon: Icons.link_rounded,
    ),
    Achievement(
      id: 'zero_fuel_hero',
      titleRu: 'Герой планирования',
      titleEn: 'Zero Fuel Hero',
      descRu: 'Успешно посадить модуль и доставить груз при 0% топлива',
      descEn: 'Successfully land module and deliver cargo at 0% fuel',
      starReward: 200,
      icon: Icons.air_rounded,
    ),
    Achievement(
      id: 'fleet_admiral',
      titleRu: 'Адмирал флота',
      titleEn: 'Fleet Admiral',
      descRu: 'Открыть все 5 кораблей и прокачать все модули до максимума',
      descEn: 'Own all 5 ships and max out all upgrade tracks',
      starReward: 500,
      icon: Icons.workspace_premium_rounded,
    ),
    Achievement(
      id: 'ice_breaker',
      titleRu: 'Ледокол Европы',
      titleEn: 'Ice Breaker',
      descRu: 'Успешно завершить спасение в Ледяных Разломах Европы',
      descEn: 'Complete rescue mission in Ice Chasms of Europa',
      starReward: 150,
      icon: Icons.ac_unit_rounded,
    ),
    Achievement(
      id: 'zero_g_master',
      titleRu: 'Мастер невесомости',
      titleEn: 'Zero-G Master',
      descRu: 'Завершить операцию в Орбитальных Обломках без урона',
      descEn: 'Complete Orbital Debris mission with 0 hull damage',
      starReward: 200,
      icon: Icons.all_inclusive_rounded,
    ),
    Achievement(
      id: 'cosmic_tycoon',
      titleRu: 'Космический магнат',
      titleEn: 'Cosmic Tycoon',
      descRu: 'Накопить 3000 и более звездных монет',
      descEn: 'Accumulate 3000 or more total coins',
      starReward: 300,
      icon: Icons.monetization_on_rounded,
    ),
  ];

  Future<void> load(SharedPreferences prefs) async {
    final rawJson = prefs.getString('achievements_data');
    final signature = prefs.getString(SaveSecurityManager.achievementsSignatureKey);

    if (rawJson != null) {
      if (signature != null) {
        final isValid = SaveSecurityManager.verifyAchievementsSignature(rawJson, signature);
        if (!isValid) {
          debugPrint('[AchievementsSecurity] Tamper detected in achievements data. Resetting.');
          _resetAchievementsToDefault();
          await save(prefs);
          return;
        }
      }

      try {
        final List<dynamic> list = jsonDecode(rawJson);
        for (final item in list) {
          final ach = achievements.firstWhere(
            (a) => a.id == item['id'],
            orElse: () => Achievement(
              id: '',
              titleRu: '',
              titleEn: '',
              descRu: '',
              descEn: '',
              starReward: 0,
              icon: Icons.star,
            ),
          );
          if (ach.id.isNotEmpty) {
            ach.updateFromJson(Map<String, dynamic>.from(item));
          }
        }
        if (signature == null) {
          await save(prefs);
        }
      } catch (e) {
        debugPrint('Error loading achievements: $e');
        _resetAchievementsToDefault();
        await save(prefs);
      }
    } else {
      await save(prefs);
    }
  }

  void _resetAchievementsToDefault() {
    for (final a in achievements) {
      a.isUnlocked = false;
      a.progress = 0;
    }
  }

  Future<void> save(SharedPreferences prefs) async {
    final list = achievements.map((a) => a.toJson()).toList();
    final jsonStr = jsonEncode(list);
    await prefs.setString('achievements_data', jsonStr);
    await SaveSecurityManager.saveAchievementsSignature(prefs, jsonStr);
  }

  void _unlock(Achievement achievement, SharedPreferences prefs) {
    if (!achievement.isUnlocked) {
      achievement.isUnlocked = true;
      achievement.progress = achievement.maxProgress;
      save(prefs);
      
      // Награждаем монетами через GameState
      GameState().addCoins(achievement.starReward);
      
      // Оповещаем UI
      newlyUnlocked.value = achievement;
    }
  }

  /// Unlocks an achievement by its ID
  void unlockById(String achievementId, SharedPreferences prefs) {
    final ach = achievements.firstWhere(
      (a) => a.id == achievementId,
      orElse: () => Achievement(
        id: '',
        titleRu: '',
        titleEn: '',
        descRu: '',
        descEn: '',
        starReward: 0,
        icon: Icons.star,
      ),
    );
    if (ach.id.isNotEmpty) {
      _unlock(ach, prefs);
    }
  }

  /// Check speed achievement (Speed Demon: velocity > 11.0 m/s)
  void checkSpeed(double speed, SharedPreferences prefs) {
    if (speed >= 11.0) {
      final ach = achievements.firstWhere((a) => a.id == 'speed_demon');
      _unlock(ach, prefs);
    }
  }

  /// Check fleet admiral achievement (5 ships owned and all 3 upgrade tracks == 5)
  void checkFleetAdmiral(GameState state, SharedPreferences prefs) {
    final hasAllShips = state.ownedRockets.length >= 5;
    final hasMaxUpgrades = state.engineLevel >= 5 &&
        state.fuelLevel >= 5 &&
        state.shieldLevel >= 5;

    if (hasAllShips && hasMaxUpgrades) {
      final ach = achievements.firstWhere((a) => a.id == 'fleet_admiral');
      _unlock(ach, prefs);
    }
  }

  /// Check coin tycoon achievement (>= 3000 total coins)
  void checkCoins(int totalCoins, SharedPreferences prefs) {
    if (totalCoins >= 3000) {
      final ach = achievements.firstWhere((a) => a.id == 'cosmic_tycoon');
      _unlock(ach, prefs);
    }
  }

  /// Trigger verification at end of rescue mission
  void checkMissionCompletionStats({
    required SharedPreferences prefs,
    required double damageTaken,
    required double fuelPercentRemaining,
    required double missionSeconds,
    required int coinsCollected,
    required bool isSuccess,
    String mapId = 'echo',
    bool ropeSnapped = false,
  }) {
    if (!isSuccess) return;

    // 1. Soft Landing (0 damage)
    if (damageTaken <= 0.01) {
      final ach = achievements.firstWhere((a) => a.id == 'soft_landing');
      _unlock(ach, prefs);
    }

    // 2. Eco Pilot (> 50% fuel remaining)
    if (fuelPercentRemaining >= 0.50) {
      final ach = achievements.firstWhere((a) => a.id == 'eco_pilot');
      _unlock(ach, prefs);
    }

    // 3. Speed Rescue (< 45s)
    if (missionSeconds > 0 && missionSeconds <= 45.0) {
      final ach = achievements.firstWhere((a) => a.id == 'speed_rescue');
      _unlock(ach, prefs);
    }

    // 4. Treasure Hunter (>= 10 coins)
    if (coinsCollected >= 10) {
      final ach = achievements.firstWhere((a) => a.id == 'treasure_hunter');
      _unlock(ach, prefs);
    }

    // 5. Cave Veteran (5 missions)
    final veteranAch = achievements.firstWhere((a) => a.id == 'cave_veteran');
    if (!veteranAch.isUnlocked) {
      veteranAch.progress++;
      if (veteranAch.progress >= veteranAch.maxProgress) {
        _unlock(veteranAch, prefs);
      } else {
        save(prefs);
      }
    }

    // 7. Titanium Tether (Storm run without snap)
    if (mapId == 'wind' && !ropeSnapped) {
      final ach = achievements.firstWhere((a) => a.id == 'titanium_tether');
      _unlock(ach, prefs);
    }

    // 8. Zero Fuel Hero (Glider landing at 0% fuel)
    if (fuelPercentRemaining <= 0.001) {
      final ach = achievements.firstWhere((a) => a.id == 'zero_fuel_hero');
      _unlock(ach, prefs);
    }

    // 10. Ice Breaker (Europa rescue)
    if (mapId == 'ice') {
      final ach = achievements.firstWhere((a) => a.id == 'ice_breaker');
      _unlock(ach, prefs);
    }

    // 11. Zero-G Master (Zero-G no-damage run)
    if (mapId == 'orbit' && damageTaken <= 0.01) {
      final ach = achievements.firstWhere((a) => a.id == 'zero_g_master');
      _unlock(ach, prefs);
    }
  }
}
