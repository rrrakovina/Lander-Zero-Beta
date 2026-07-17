import 'package:flame_audio/flame_audio.dart';
import '../state/game_state.dart';

class GameAudioManager {
  static final GameAudioManager _instance = GameAudioManager._internal();
  factory GameAudioManager() => _instance;
  GameAudioManager._internal();

  // Флаг для пропуска обращений к звуковому движку в юнит-тестах
  static bool isTesting = false;

  AudioPlayer? _thrustPlayer;

  Future<void> init() async {
    if (isTesting) return;
    try {
      // Предзагрузка звуковых эффектов для быстрого воспроизведения без задержек
      await FlameAudio.audioCache.loadAll([
        'coin.wav',
        'collision.wav',
        'dock.wav',
        'victory.wav',
        'defeat.wav',
        'thrust.wav',
      ]);
    } catch (e) {
      // Игнорируем в случае сбоев
    }
  }

  void playBgm() {
    if (isTesting) return;
    try {
      final state = GameState();
      if (state.musicVolume > 0) {
        FlameAudio.bgm.play('bg_music.wav', volume: state.musicVolume);
      }
    } catch (e) {
      // Игнорируем
    }
  }

  void stopBgm() {
    if (isTesting) return;
    try {
      FlameAudio.bgm.stop();
    } catch (e) {
      // Игнорируем
    }
  }

  void updateBgmVolume() {
    if (isTesting) return;
    try {
      final state = GameState();
      if (state.musicVolume > 0) {
        if (FlameAudio.bgm.isPlaying) {
          FlameAudio.bgm.audioPlayer.setVolume(state.musicVolume);
        } else {
          FlameAudio.bgm.play('bg_music.wav', volume: state.musicVolume);
        }
      } else {
        if (FlameAudio.bgm.isPlaying) {
          FlameAudio.bgm.stop();
        }
      }
    } catch (e) {
      // Игнорируем
    }
  }

  void playSfx(String name) {
    if (isTesting) return;
    try {
      final state = GameState();
      if (state.sfxVolume > 0) {
        FlameAudio.play(name, volume: state.sfxVolume);
      }
    } catch (e) {
      // Игнорируем
    }
  }

  void startThrustLoop() async {
    if (isTesting) return;
    try {
      final state = GameState();
      if (state.sfxVolume > 0 && _thrustPlayer == null) {
        _thrustPlayer = await FlameAudio.loop('thrust.wav', volume: state.sfxVolume * 0.4);
      }
    } catch (e) {
      // Игнорируем
    }
  }

  void stopThrustLoop() async {
    if (isTesting) return;
    try {
      if (_thrustPlayer != null) {
        await _thrustPlayer!.stop();
        _thrustPlayer = null;
      }
    } catch (e) {
      // Игнорируем
    }
  }
}
