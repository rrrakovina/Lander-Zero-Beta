import 'package:flutter/material.dart';
import '../../game/config/game_config.dart';
import '../../game/state/game_state.dart';
import '../widgets/glass_panel.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GameState(),
      builder: (context, _) {
        final state = GameState();
        final isRu = state.language == 'ru';

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: GlassPanel(
            borderColor: GameConfig.colorPrimary.withOpacity(0.4),
            borderRadius: 16,
            padding: 24,
            child: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.settings_rounded, color: GameConfig.colorPrimary, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            state.translate('settings'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white60),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 16),

                  // Громкость музыки
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            state.translate('volume_music'),
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          Text(
                            '${(state.musicVolume * 100).toInt()}%',
                            style: const TextStyle(color: GameConfig.colorPrimary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.music_note_rounded, color: Colors.white30, size: 20),
                          Expanded(
                            child: Slider(
                              value: state.musicVolume,
                              onChanged: (vol) => state.setMusicVolume(vol),
                              activeColor: GameConfig.colorPrimary,
                              inactiveColor: Colors.white10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Громкость эффектов
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            state.translate('volume_sfx'),
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          Text(
                            '${(state.sfxVolume * 100).toInt()}%',
                            style: const TextStyle(color: GameConfig.colorWarning, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.volume_up_rounded, color: Colors.white30, size: 20),
                          Expanded(
                            child: Slider(
                              value: state.sfxVolume,
                              onChanged: (vol) => state.setSfxVolume(vol),
                              activeColor: GameConfig.colorWarning,
                              inactiveColor: Colors.white10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 20),

                  // Выбор языка
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Language / Язык:',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      ToggleButtons(
                        isSelected: [!isRu, isRu],
                        onPressed: (index) {
                          state.setLanguage(index == 1 ? 'ru' : 'en');
                        },
                        borderRadius: BorderRadius.circular(8),
                        borderColor: Colors.white24,
                        selectedBorderColor: GameConfig.colorPrimary,
                        fillColor: GameConfig.colorPrimary.withOpacity(0.1),
                        selectedColor: GameConfig.colorPrimary,
                        color: Colors.white60,
                        constraints: const BoxConstraints(minWidth: 60, minHeight: 36),
                        children: const [
                          Text('EN', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('RU', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Кнопка закрытия
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GameConfig.colorPrimary,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      state.translate('close').toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
