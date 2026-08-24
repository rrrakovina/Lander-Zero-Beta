import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_state.dart';

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
  ];

  Future<void> load(SharedPreferences prefs) async {
    final rawJson = prefs.getString('achievements_data');
    if (rawJson != null) {
      try {
        final List<dynamic> list = jsonDecode(rawJson);
        for (final item in list) {
          final ach = achievements.firstWhere(
            (a) => a.id == item['id'],
            orElse: () => Achievement(id: '', titleRu: '', titleEn: '', descRu: '', descEn: '', starReward: 0, icon: Icons.star),
          );
          if (ach.id.isNotEmpty) {
            ach.updateFromJson(Map<String, dynamic>.from(item));
          }
        }
      } catch (e) {
        debugPrint('Error loading achievements: $e');
      }
    }
  }

  Future<void> save(SharedPreferences prefs) async {
    final list = achievements.map((a) => a.toJson()).toList();
    await prefs.setString('achievements_data', jsonEncode(list));
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

  void checkMissionCompletionStats({
    required SharedPreferences prefs,
    required double damageTaken,
    required double fuelPercentRemaining,
    required double missionSeconds,
    required int coinsCollected,
    required bool isSuccess,
  }) {
    if (!isSuccess) return;

    // 1. Soft Landing (0 урона)
    if (damageTaken <= 0.01) {
      final ach = achievements.firstWhere((a) => a.id == 'soft_landing');
      _unlock(ach, prefs);
    }

    // 2. Eco Pilot (> 50% топлива)
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

    // 5. Cave Veteran (5 миссий)
    final veteranAch = achievements.firstWhere((a) => a.id == 'cave_veteran');
    if (!veteranAch.isUnlocked) {
      veteranAch.progress++;
      if (veteranAch.progress >= veteranAch.maxProgress) {
        _unlock(veteranAch, prefs);
      } else {
        save(prefs);
      }
    }
  }
}
