import 'package:flutter/material.dart';
import '../../game/config/game_config.dart';
import '../../game/state/game_state.dart';
import '../widgets/menu_background.dart';
import '../widgets/glass_panel.dart';

class NickEntryWidget extends StatefulWidget {
  final VoidCallback onFinished;
  const NickEntryWidget({super.key, required this.onFinished});

  @override
  State<NickEntryWidget> createState() => _NickEntryWidgetState();
}

class _NickEntryWidgetState extends State<NickEntryWidget> {
  final _controller = TextEditingController();
  String _error = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() {
        _error = GameState().translate('error_empty_nick');
      });
      return;
    }
    await GameState().setNickname(name);
    widget.onFinished();
  }

  void _toggleLanguage() async {
    final state = GameState();
    final newLang = state.language == 'ru' ? 'en' : 'ru';
    await state.setLanguage(newLang);
    setState(() {
      _error = ''; // Сброс ошибки при смене языка
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = GameState();
    final isRu = state.language == 'ru';

    return MenuBackground(
      child: Center(
        child: SingleChildScrollView(
          child: GlassPanel(
            borderColor: GameConfig.colorPrimary.withOpacity(0.5),
            borderRadius: 16,
            padding: 30,
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Кнопка переключения языка в правом верхнем углу панели
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: _toggleLanguage,
                      icon: const Icon(Icons.language, size: 18),
                      label: Text(
                        isRu ? 'EN' : 'RU',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GameConfig.colorPrimary,
                        side: BorderSide(
                          color: GameConfig.colorPrimary.withOpacity(0.5),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.rocket_launch_rounded,
                    color: GameConfig.colorPrimary,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.translate('title'),
                    style: const TextStyle(
                      color: GameConfig.colorPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.translate('enter_nick'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _controller,
                    maxLength: 15,
                    cursorColor: GameConfig.colorPrimary,
                    style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 1),
                    decoration: InputDecoration(
                      hintText: isRu ? 'Кадет' : 'Cadet',
                      hintStyle: const TextStyle(color: Colors.white24),
                      counterStyle: const TextStyle(color: Colors.white30),
                      fillColor: Colors.black26,
                      filled: true,
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: GameConfig.colorPrimary, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white24),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error,
                      style: const TextStyle(color: GameConfig.colorDanger, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GameConfig.colorPrimary,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontSize: 16,
                      ),
                    ),
                    child: Text(state.translate('start')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
