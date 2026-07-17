import 'package:flutter/material.dart';
import '../../game/config/game_config.dart';
import '../../game/state/game_state.dart';
import '../widgets/menu_background.dart';
import '../widgets/glass_panel.dart';

class LeaderboardWidget extends StatelessWidget {
  final VoidCallback onBack;
  const LeaderboardWidget({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final state = GameState();
    final isRu = state.language == 'ru';
    final lb = state.leaderboard;

    return MenuBackground(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: onBack,
                ),
                const SizedBox(width: 8),
                Text(
                  state.translate('leaderboard_title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Leaderboard content
            Expanded(
              child: GlassPanel(
                borderColor: Colors.white10,
                padding: 0,
                child: lb.isEmpty
                    ? Center(
                        child: Text(
                          state.translate('no_records'),
                          style: const TextStyle(color: Colors.white30, fontSize: 14),
                        ),
                      )
                    : Column(
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            color: Colors.black26,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 50,
                                  child: Text(isRu ? 'Ранг' : 'Rank',
                                      style: const TextStyle(
                                          color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                Expanded(
                                  child: Text(isRu ? 'Пилот' : 'Pilot',
                                      style: const TextStyle(
                                          color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: Text(isRu ? 'Пещера' : 'Cave',
                                      style: const TextStyle(
                                          color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                SizedBox(
                                  width: 100,
                                  child: Text(isRu ? 'Дистанция' : 'Distance',
                                      style: const TextStyle(
                                          color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.right),
                                ),
                                const SizedBox(width: 24),
                                SizedBox(
                                  width: 100,
                                  child: Text(isRu ? 'Монеты' : 'Coins',
                                      style: const TextStyle(
                                          color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.right),
                                ),
                              ],
                            ),
                          ),
                          // List
                          Expanded(
                            child: ListView.separated(
                              itemCount: lb.length,
                              separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                              itemBuilder: (context, index) {
                                final row = lb[index];
                                final rank = index + 1;
                                final pilot = row['name'] ?? 'Pilot';
                                final mapId = row['map'] ?? 'echo';
                                final distance = row['distance'] ?? 0;
                                final coins = row['coins'] ?? 0;

                                String mapName = 'Echo Canyon';
                                if (mapId == 'wind') mapName = 'Solar Winds';
                                if (mapId == 'core') mapName = 'Deep Core';
                                if (isRu) {
                                  if (mapId == 'echo') mapName = 'Каньон Эхо';
                                  if (mapId == 'wind') mapName = 'Солнечные Ветры';
                                  if (mapId == 'core') mapName = 'Глубокое Ядро';
                                }

                                Color rankColor = Colors.white70;
                                Widget? rankIcon;
                                if (rank == 1) {
                                  rankColor = const Color(0xFFFFD700);
                                  rankIcon = const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 18);
                                } else if (rank == 2) {
                                  rankColor = const Color(0xFFC0C0C0);
                                  rankIcon = const Icon(Icons.emoji_events_rounded, color: Color(0xFFC0C0C0), size: 18);
                                } else if (rank == 3) {
                                  rankColor = const Color(0xFFCD7F32);
                                  rankIcon = const Icon(Icons.emoji_events_rounded, color: Color(0xFFCD7F32), size: 18);
                                }

                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 50,
                                        child: rankIcon ??
                                            Text(
                                              '#$rank',
                                              style: TextStyle(
                                                color: rankColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          pilot,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          mapName,
                                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: Text(
                                          '$distance ${state.translate('stats_meters')}',
                                          style: const TextStyle(
                                            color: GameConfig.colorPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      SizedBox(
                                        width: 100,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            const Icon(Icons.stars_rounded,
                                                color: GameConfig.colorWarning, size: 14),
                                            const SizedBox(width: 6),
                                            Text(
                                              '$coins',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
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
            ),
          ],
        ),
      ),
    );
  }
}
