import 'package:flutter/material.dart';
import '../../game/audio/game_audio_manager.dart';
import '../../game/config/game_config.dart';
import '../../game/state/achievements_manager.dart';
import '../../game/state/game_state.dart';

class AchievementsDialog extends StatelessWidget {
  const AchievementsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final state = GameState();
    final lang = state.language;
    final achievements = AchievementsManager().achievements;
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 600),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: GameConfig.colorPrimary.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: GameConfig.colorPrimary.withOpacity(0.25),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: GameConfig.colorWarning.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: GameConfig.colorWarning.withOpacity(0.6)),
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: GameConfig.colorWarning, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang == 'ru' ? 'ДОСТИЖЕНИЯ' : 'ACHIEVEMENTS',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          lang == 'ru'
                              ? 'Разблокировано: $unlockedCount из ${achievements.length}'
                              : 'Unlocked: $unlockedCount of ${achievements.length}',
                          style: TextStyle(
                            color: GameConfig.colorPrimary.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () {
                      GameAudioManager().playTap();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),

            // List of achievements
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: achievements.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final ach = achievements[index];
                  final isUnlocked = ach.isUnlocked;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? GameConfig.colorPrimary.withOpacity(0.08)
                          : Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isUnlocked
                            ? GameConfig.colorPrimary.withOpacity(0.4)
                            : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isUnlocked
                                ? GameConfig.colorWarning.withOpacity(0.2)
                                : Colors.white10,
                            border: Border.all(
                              color: isUnlocked ? GameConfig.colorWarning : Colors.white24,
                            ),
                          ),
                          child: Icon(
                            isUnlocked
                                ? ach.icon
                                : Icons.lock_outline_rounded,
                            color: isUnlocked ? GameConfig.colorWarning : Colors.white38,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ach.getTitle(lang),
                                style: TextStyle(
                                  color: isUnlocked ? Colors.white : Colors.white54,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ach.getDesc(lang),
                                style: TextStyle(
                                  color: isUnlocked ? Colors.white70 : Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                              if (!isUnlocked && ach.maxProgress > 1) ...[
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: (ach.progress / ach.maxProgress).clamp(0.0, 1.0),
                                    backgroundColor: Colors.white10,
                                    valueColor: const AlwaysStoppedAnimation(GameConfig.colorPrimary),
                                    minHeight: 4,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${ach.progress} / ${ach.maxProgress}',
                                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: isUnlocked
                                ? GameConfig.colorPrimary.withOpacity(0.15)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isUnlocked
                                  ? GameConfig.colorPrimary.withOpacity(0.4)
                                  : Colors.white12,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.stars_rounded,
                                color: isUnlocked ? GameConfig.colorWarning : Colors.white38,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+${ach.starReward}',
                                style: TextStyle(
                                  color: isUnlocked ? Colors.white : Colors.white38,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
