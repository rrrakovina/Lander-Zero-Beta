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
        'ui_tap.wav',
        'ui_purchase.wav',
        'ui_decline.wav',
        'ui_swoosh.wav',
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
        FlameAudio.bgm.play('bg_music.wav', volume: state.musicVolume).catchError((_) {});
      }
    } catch (e) {
      // Игнорируем
    }
  }

  void stopBgm() {
    if (isTesting) return;
    try {
      FlameAudio.bgm.stop().catchError((_) {});
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
          FlameAudio.bgm.audioPlayer.setVolume(state.musicVolume).catchError((_) {});
        } else {
          FlameAudio.bgm.play('bg_music.wav', volume: state.musicVolume).catchError((_) {});
        }
      } else {
        if (FlameAudio.bgm.isPlaying) {
          FlameAudio.bgm.stop().catchError((_) {});
        }
      }
    } catch (e) {
      // Игнорируем
    }
  }

  void playSfx(String name, {double volumeMultiplier = 1.0}) {
    if (isTesting) return;
    try {
      final state = GameState();
      final volume = (state.sfxVolume * volumeMultiplier).clamp(0.0, 1.0);
      if (volume > 0) {
        FlameAudio.play(name, volume: volume).catchError((_) => AudioPlayer());
      }
    } catch (e) {
      // Игнорируем
    }
  }

  /// 1. Стандартное нажатие на кнопку (мягкий демпфированный акустический щелчок)
  void playTap({double volumeMultiplier = 1.0}) => playSfx('ui_tap.wav', volumeMultiplier: volumeMultiplier);

  /// 2. Подтверждение покупки / апгрейда / выбора (теплый гармонический перезвон)
  void playPurchase({double volumeMultiplier = 1.0}) => playSfx('ui_purchase.wav', volumeMultiplier: volumeMultiplier);

  /// 3. Отклонение / ошибка валидации / нехватка монет (низкочастотный приглушенный гул)
  void playDecline({double volumeMultiplier = 1.0}) => playSfx('ui_decline.wav', volumeMultiplier: volumeMultiplier);

  /// 4. Переключение вкладок / навигация (мягкий пневматический шелест воздуха)
  void playSwoosh({double volumeMultiplier = 1.0}) => playSfx('ui_swoosh.wav', volumeMultiplier: volumeMultiplier);

  /// 5. Скользящее касание / отражение щитом (смягченный металлический звон)
  void playShieldDeflect({double volumeMultiplier = 1.0}) => playSfx('collision.wav', volumeMultiplier: volumeMultiplier * 0.6);

  bool _isThrustPlaying = false;

  void startThrustLoop() async {
    if (isTesting) return;
    if (_isThrustPlaying) return; // Не запускаем повторно
    try {
      final state = GameState();
      if (state.sfxVolume > 0 && _thrustPlayer == null) {
        _isThrustPlaying = true;
        _thrustPlayer = await FlameAudio.loop('thrust.wav', volume: state.sfxVolume * 0.4);
      }
    } catch (e) {
      _isThrustPlaying = false;
    }
  }

  void stopThrustLoop() async {
    if (isTesting) return;
    _isThrustPlaying = false;
    try {
      if (_thrustPlayer != null) {
        await _thrustPlayer!.stop();
        await _thrustPlayer!.dispose();
        _thrustPlayer = null;
      }
    } catch (e) {
      _thrustPlayer = null;
    }
  }

  /// Остановка игровых звуков (вызывается при выходе из игрового экрана)
  /// BGM не останавливается — фоновая музыка играет постоянно
  void disposeGameSounds() {
    stopThrustLoop();
  }
}
