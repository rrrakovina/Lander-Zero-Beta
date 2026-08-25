import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../audio/game_audio_manager.dart';
import 'achievements_manager.dart';
import 'save_security_manager.dart';

class GameState extends ChangeNotifier {
  static final GameState _instance = GameState._internal();
  factory GameState() => _instance;
  GameState._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  // Данные прогресса
  String _nickname = '';
  String _language = 'ru'; // 'ru' или 'en'
  double _musicVolume = 0.7;
  double _sfxVolume = 0.8;
  int _totalCoins = 0;
  String _selectedRocket = 'sputnik';
  List<String> _ownedRockets = ['sputnik', 'swift'];
  
  // Уровни прокачки (1-5)
  int _engineLevel = 1;
  int _fuelLevel = 1;
  int _shieldLevel = 1;

  // Таблица рекордов: список заездов. Каждый элемент: {'name': name, 'map': map, 'distance': d, 'coins': c}
  List<Map<String, dynamic>> _leaderboard = [];

  bool get initialized => _initialized;
  SharedPreferences get prefs => _prefs;
  String get nickname => _nickname;
  String get language => _language;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;
  int get totalCoins => _totalCoins;
  String get selectedRocket => _selectedRocket;
  List<String> get ownedRockets => _ownedRockets;
  int get engineLevel => _engineLevel;
  int get fuelLevel => _fuelLevel;
  int get shieldLevel => _shieldLevel;
  List<Map<String, dynamic>> get leaderboard => _leaderboard;

  // Характеристики 5 кораблей флота
  static const Map<String, Map<String, dynamic>> rocketConfigs = {
    'sputnik': {
      'nameRu': 'Спутник-1',
      'nameEn': 'Sputnik-1',
      'descRu': 'Базовая кабина. Хорошо сбалансирована.',
      'descEn': 'Starter cabin. Well balanced.',
      'price': 0,
      'baseThrust': 32.0,
      'baseFuel': 150.0,
      'baseShield': 100.0,
      'mass': 1.0,
    },
    'swift': {
      'nameRu': 'Стриж',
      'nameEn': 'Swift-02',
      'descRu': 'Скоростной перехватчик. Высокая тяга, легкий корпус, малый щит.',
      'descEn': 'High-speed interceptor. Agile and lightweight, low shielding.',
      'price': 0,
      'baseThrust': 38.0,
      'baseFuel': 140.0,
      'baseShield': 70.0,
      'mass': 0.75,
    },
    'cyclone': {
      'nameRu': 'Ураган',
      'nameEn': 'Cyclone',
      'descRu': 'Тяжелый грузовик. Очень прочный, мощная тяга, но прожорлив.',
      'descEn': 'Heavy cargo ship. High shield and thrust, but heavy and thirsty.',
      'price': 800,
      'baseThrust': 42.0,
      'baseFuel': 180.0,
      'baseShield': 180.0,
      'mass': 1.6,
    },
    'needle': {
      'nameRu': 'Игла',
      'nameEn': 'Needle',
      'descRu': 'Высокотехнологичный ионный перехватчик «Квазар». Маневренный и экономичный.',
      'descEn': 'High-tech Quasar ion RCS maneuvering vessel. Sleek and agile.',
      'price': 1500,
      'baseThrust': 38.0,
      'baseFuel': 150.0,
      'baseShield': 80.0,
      'mass': 0.7,
    },
    'titan': {
      'nameRu': 'Буран-М',
      'nameEn': 'Titan-V',
      'descRu': 'Тяжелый трехсопловый бронекатер. Максимальный щит и стабильность.',
      'descEn': 'Heavy triple-thruster armored rescue ship. Maximum shield.',
      'price': 2200,
      'baseThrust': 46.0,
      'baseFuel': 220.0,
      'baseShield': 250.0,
      'mass': 2.0,
    },
  };

  // Вспомогательный метод сохранения HMAC сигнатуры
  Future<void> _saveIntegrity() async {
    await SaveSecurityManager.saveSignature(
      _prefs,
      coins: _totalCoins,
      ownedRockets: _ownedRockets,
      engineLevel: _engineLevel,
      fuelLevel: _fuelLevel,
      shieldLevel: _shieldLevel,
      leaderboardJson: jsonEncode(_leaderboard),
    );
  }

  // Инициализация загрузки из SharedPreferences с проверкой целостности HMAC
  Future<void> init({bool force = false}) async {
    if (_initialized && !force) return;
    _prefs = await SharedPreferences.getInstance();

    final storedNick = _prefs.getString('nickname');
    _nickname = storedNick != null ? SaveSecurityManager.sanitizeNickname(storedNick) : '';
    _language = _prefs.getString('language') ?? 'ru';
    _musicVolume = _prefs.getDouble('musicVolume') ?? 0.7;
    _sfxVolume = _prefs.getDouble('sfxVolume') ?? 0.8;

    final storedCoins = _prefs.getInt('totalCoins');
    final storedFleet = _prefs.getStringList('ownedRockets');
    final storedEngine = _prefs.getInt('engineLevel');
    final storedFuel = _prefs.getInt('fuelLevel');
    final storedShield = _prefs.getInt('shieldLevel');
    final storedLb = _prefs.getString('leaderboard') ?? '[]';
    final storedSig = _prefs.getString(SaveSecurityManager.saveSignatureKey);

    if (storedCoins == null && storedFleet == null && storedSig == null) {
      // 1. Fresh install baseline
      _totalCoins = 0;
      _ownedRockets = ['sputnik', 'swift'];
      _selectedRocket = 'sputnik';
      _engineLevel = 1;
      _fuelLevel = 1;
      _shieldLevel = 1;
      _leaderboard = [];

      await _prefs.setInt('totalCoins', _totalCoins);
      await _prefs.setStringList('ownedRockets', _ownedRockets);
      await _prefs.setString('selectedRocket', _selectedRocket);
      await _prefs.setInt('engineLevel', _engineLevel);
      await _prefs.setInt('fuelLevel', _fuelLevel);
      await _prefs.setInt('shieldLevel', _shieldLevel);
      await _prefs.setString('leaderboard', '[]');
      await _saveIntegrity();
    } else if (storedSig == null) {
      // 2. Migration from legacy save without signature
      _totalCoins = storedCoins ?? 0;
      _ownedRockets = List<String>.from(storedFleet ?? ['sputnik', 'swift']);
      if (!_ownedRockets.contains('sputnik')) _ownedRockets.add('sputnik');
      if (!_ownedRockets.contains('swift')) _ownedRockets.add('swift');

      _selectedRocket = _prefs.getString('selectedRocket') ?? 'sputnik';
      if (!_ownedRockets.contains(_selectedRocket)) _selectedRocket = 'sputnik';

      _engineLevel = (storedEngine ?? 1).clamp(1, 5);
      _fuelLevel = (storedFuel ?? 1).clamp(1, 5);
      _shieldLevel = (storedShield ?? 1).clamp(1, 5);

      try {
        final List<dynamic> decoded = jsonDecode(storedLb);
        _leaderboard = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        _leaderboard = [];
      }

      await _saveIntegrity();
    } else {
      // 3. Existing save with HMAC signature -> verify cryptographic integrity
      final loadedCoins = storedCoins ?? 0;
      final loadedFleet = storedFleet ?? ['sputnik', 'swift'];
      final loadedEngine = storedEngine ?? 1;
      final loadedFuel = storedFuel ?? 1;
      final loadedShield = storedShield ?? 1;

      final isValid = SaveSecurityManager.verifySignature(
        coins: loadedCoins,
        ownedRockets: loadedFleet,
        engineLevel: loadedEngine,
        fuelLevel: loadedFuel,
        shieldLevel: loadedShield,
        leaderboardJson: storedLb,
        signature: storedSig,
      );

      if (isValid) {
        // Legitimate save
        _totalCoins = loadedCoins;
        _ownedRockets = List<String>.from(loadedFleet);
        if (!_ownedRockets.contains('sputnik')) _ownedRockets.add('sputnik');
        if (!_ownedRockets.contains('swift')) _ownedRockets.add('swift');

        _selectedRocket = _prefs.getString('selectedRocket') ?? 'sputnik';
        if (!_ownedRockets.contains(_selectedRocket)) _selectedRocket = 'sputnik';

        _engineLevel = loadedEngine.clamp(1, 5);
        _fuelLevel = loadedFuel.clamp(1, 5);
        _shieldLevel = loadedShield.clamp(1, 5);

        try {
          final List<dynamic> decoded = jsonDecode(storedLb);
          _leaderboard = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        } catch (e) {
          _leaderboard = [];
        }
      } else {
        // Tamper / corruption detected -> Graceful recovery to safe baseline
        debugPrint('[SaveSecurityManager] Save data tampering or corruption detected. Resetting to legitimate baseline.');
        _totalCoins = 0;
        _ownedRockets = ['sputnik', 'swift'];
        _selectedRocket = 'sputnik';
        _engineLevel = 1;
        _fuelLevel = 1;
        _shieldLevel = 1;
        _leaderboard = [];

        await _prefs.setInt('totalCoins', _totalCoins);
        await _prefs.setStringList('ownedRockets', _ownedRockets);
        await _prefs.setString('selectedRocket', _selectedRocket);
        await _prefs.setInt('engineLevel', _engineLevel);
        await _prefs.setInt('fuelLevel', _fuelLevel);
        await _prefs.setInt('shieldLevel', _shieldLevel);
        await _prefs.setString('leaderboard', '[]');
        await _saveIntegrity();
      }
    }

    await AchievementsManager().load(_prefs);

    _initialized = true;
    notifyListeners();
  }

  // Запись ника с санитизацией
  Future<void> setNickname(String name) async {
    _nickname = SaveSecurityManager.sanitizeNickname(name);
    await _prefs.setString('nickname', _nickname);
    notifyListeners();
  }

  // Переключение языка
  Future<void> setLanguage(String lang) async {
    _language = lang;
    await _prefs.setString('language', _language);
    notifyListeners();
  }

  // Изменение громкости музыки
  Future<void> setMusicVolume(double vol) async {
    _musicVolume = vol.clamp(0.0, 1.0);
    await _prefs.setDouble('musicVolume', _musicVolume);
    notifyListeners();
    GameAudioManager().updateBgmVolume();
  }

  // Изменение громкости звуковых эффектов
  Future<void> setSfxVolume(double vol) async {
    _sfxVolume = vol.clamp(0.0, 1.0);
    await _prefs.setDouble('sfxVolume', _sfxVolume);
    notifyListeners();
    if (_sfxVolume == 0.0) {
      GameAudioManager().stopThrustLoop();
    }
  }

  // Начисление монет
  Future<void> addCoins(int amount) async {
    _totalCoins += amount;
    await _prefs.setInt('totalCoins', _totalCoins);
    await _saveIntegrity();
    notifyListeners();
    AchievementsManager().checkCoins(_totalCoins, _prefs);
  }

  // Списание монет (проверка баланса)
  bool canAfford(int amount) {
    return _totalCoins >= amount;
  }

  // Покупка ракеты
  Future<bool> buyRocket(String rocketId) async {
    if (_ownedRockets.contains(rocketId)) return true;
    final int price = (rocketConfigs[rocketId]?['price'] as int?) ?? 0;
    if (canAfford(price)) {
      _totalCoins -= price;
      _ownedRockets.add(rocketId);
      _selectedRocket = rocketId;
      await _prefs.setInt('totalCoins', _totalCoins);
      await _prefs.setStringList('ownedRockets', _ownedRockets);
      await _prefs.setString('selectedRocket', _selectedRocket);
      await _saveIntegrity();
      notifyListeners();
      AchievementsManager().checkFleetAdmiral(this, _prefs);
      return true;
    }
    return false;
  }

  // Разблокировка ракеты (без списания монет, напр. по достижению)
  Future<bool> unlockRocket(String rocketId) async {
    if (!_ownedRockets.contains(rocketId)) {
      _ownedRockets.add(rocketId);
      await _prefs.setStringList('ownedRockets', _ownedRockets);
      await _saveIntegrity();
      notifyListeners();
      AchievementsManager().checkFleetAdmiral(this, _prefs);
      return true;
    }
    return true;
  }

  // Смена выбранной ракеты
  Future<void> selectRocket(String rocketId) async {
    if (_ownedRockets.contains(rocketId)) {
      _selectedRocket = rocketId;
      await _prefs.setString('selectedRocket', _selectedRocket);
      notifyListeners();
    }
  }

  // Прокачка параметров
  Future<bool> upgradeStat(String stat) async {
    if (stat != 'engine' && stat != 'fuel' && stat != 'shield') {
      return false;
    }

    int currentLvl = 1;
    if (stat == 'engine') currentLvl = _engineLevel;
    if (stat == 'fuel') currentLvl = _fuelLevel;
    if (stat == 'shield') currentLvl = _shieldLevel;

    if (currentLvl >= 5) return false;

    // Стоимость: L2=150, L3=300, L4=600, L5=1200
    final cost = 150 * (1 << (currentLvl - 1));

    if (canAfford(cost)) {
      _totalCoins -= cost;
      await _prefs.setInt('totalCoins', _totalCoins);

      if (stat == 'engine') {
        _engineLevel++;
        await _prefs.setInt('engineLevel', _engineLevel);
      } else if (stat == 'fuel') {
        _fuelLevel++;
        await _prefs.setInt('fuelLevel', _fuelLevel);
      } else if (stat == 'shield') {
        _shieldLevel++;
        await _prefs.setInt('shieldLevel', _shieldLevel);
      }

      await _saveIntegrity();
      notifyListeners();
      AchievementsManager().checkFleetAdmiral(this, _prefs);
      return true;
    }
    return false;
  }

  // Сохранение рекорда
  Future<void> addRecord(double distance, int coins, String mapName) async {
    final record = {
      'name': _nickname.isEmpty ? 'Pilot' : _nickname,
      'map': mapName,
      'distance': distance.toInt(),
      'coins': coins,
      'date': DateTime.now().toIso8601String().substring(0, 10),
    };
    
    _leaderboard.add(record);
    // Сортировка по дистанции (по убыванию)
    _leaderboard.sort((a, b) => (b['distance'] as int).compareTo(a['distance'] as int));
    
    // Оставляем только топ-10
    if (_leaderboard.length > 10) {
      _leaderboard = _leaderboard.sublist(0, 10);
    }

    await _prefs.setString('leaderboard', jsonEncode(_leaderboard));
    await _saveIntegrity();
    notifyListeners();
  }

  // Переводы для локализации
  static const Map<String, Map<String, String>> _translations = {
    'ru': {
      'title': 'LANDER ZERO: СПАСЕНИЕ',
      'play': 'ИГРАТЬ',
      'garage': 'ГАРАЖ',
      'records': 'РЕКОРДЫ',
      'enter_nick': 'ВВЕДИТЕ НИКНЕЙМ',
      'start': 'СТАРТ',
      'fuel': 'ТОПЛИВО',
      'shield': 'ЩИТ',
      'engine': 'ТЯГА',
      'level': 'УРОВЕНЬ',
      'max_level': 'МАКС. УРОВЕНЬ',
      'upgrade_cost': 'Стоимость прокачки',
      'tab_upgrades': 'МОДЕРНИЗАЦИЯ',
      'tab_cabins': 'КАБИНЫ',
      'buy': 'КУПИТЬ',
      'select': 'ВЫБРАТЬ',
      'selected': 'ВЫБРАНО',
      'map_select': 'ВЫБОР КАРТЫ',
      'map_echo': 'Каньон Эхо',
      'map_echo_desc': 'Спокойная пещера. Нормальная гравитация.',
      'map_wind': 'Солнечные Ветры',
      'map_wind_desc': 'Боковой космический ветер сдувает влево.',
      'map_core': 'Глубокое Ядро',
      'map_core_desc': 'Сильная гравитация (1.5x). Опасный спуск.',
      'esc_paused': 'ИГРА ПРИОСТАНОВЛЕНА',
      'resume': 'ПРОДОЛЖИТЬ',
      'restart': 'НАЧАТЬ ЗАНОВО',
      'exit_menu': 'В ГЛАВНОЕ МЕНЮ',
      'victory': 'МИССИЯ ВЫПОЛНЕНА',
      'victory_desc': 'Груз благополучно доставлен к выходному шлюзу.',
      'defeat': 'КРАХ МОДУЛЯ',
      'defeat_desc': 'Модуль разрушен или закончилось топливо.',
      'stats_time': 'Время полета',
      'stats_dist': 'Дистанция',
      'stats_coins': 'Собрано монет',
      'stats_damage': 'Получено урона',
      'stats_reward': 'Награда',
      'stats_sec': 'сек',
      'stats_meters': 'м',
      'menu_coins': 'Баланс монет',
      'leaderboard_title': 'ТАБЛИЦА РЕКОРДОВ',
      'no_records': 'Рекордов пока нет. Будь первым!',
      'docked_alert': 'ГРУЗ ЗАФИКСИРОВАН! ДОСТАВЬТЕ ЕГО К ВЫХОДНОМУ ШЛЮЗУ!',
      'exit_gate_alert': 'ВЫХОДНОЙ ШЛЮЗ БЛИЗКО! ПРИЗЕМЛИТЕСЬ НА ОРАНЖЕВУЮ ПЛАТФОРМУ.',
      'settings': 'НАСТРОЙКИ',
      'volume_music': 'Музыка',
      'volume_sfx': 'Эффекты',
      'close': 'ЗАКРЫТЬ',
      'cargo_nearby': 'ПРИБЛИЖЕНИЕ К ГРУЗУ. СБЛИЗЬТЕСЬ ДЛЯ ЗАЦЕПА',
      'approach_speed_alert': 'СЛИШКОМ БЫСТРОЕ СБЛИЖЕНИЕ С ГРУЗОМ!',
      'align_landing_alert': 'ВЫРОВНЯЙТЕ КОРАБЛЬ ДЛЯ ПОСАДКИ!',
      'thrust_left': 'ТЯГА СЛЕВА (A / ←)',
      'thrust_right': 'ТЯГА СПРАВА (D / →)',
      'error_empty_nick': 'Никнейм не может быть пустым',
      'rope_snapped': 'ВНИМАНИЕ: ТРОС ОБОРВАН ОТ НАТЯЖЕНИЯ!',
      'cargo_released': 'ГРУЗ ОТЦЕПЛЕН',
      'cargo_release': 'СБРОСИТЬ ГРУЗ (S / ↓)',
    },
    'en': {
      'title': 'LANDER ZERO: RESCUE OPS',
      'play': 'PLAY',
      'garage': 'GARAGE',
      'records': 'HIGHSCORES',
      'enter_nick': 'ENTER NICKNAME',
      'start': 'START',
      'fuel': 'FUEL',
      'shield': 'SHIELD',
      'engine': 'THRUST',
      'level': 'LEVEL',
      'max_level': 'MAX LEVEL',
      'upgrade_cost': 'Upgrade Cost',
      'tab_upgrades': 'UPGRADES',
      'tab_cabins': 'ROCKETS',
      'buy': 'BUY',
      'select': 'SELECT',
      'selected': 'SELECTED',
      'map_select': 'SELECT MAP',
      'map_echo': 'Echo Canyon',
      'map_echo_desc': 'Quiet cave. Normal gravity.',
      'map_wind': 'Solar Winds',
      'map_wind_desc': 'Strong cross-wind blowing to the left.',
      'map_core': 'Deep Core',
      'map_core_desc': 'Heavy gravity (1.5x). Dangerous descent.',
      'esc_paused': 'GAME PAUSED',
      'resume': 'RESUME',
      'restart': 'RETRY MISSION',
      'exit_menu': 'EXIT TO MENU',
      'victory': 'MISSION SUCCESSFUL',
      'victory_desc': 'The cargo has been evacuated to the shuttle bay.',
      'defeat': 'MODULE CRITICAL',
      'defeat_desc': 'Lander took terminal damage or ran out of fuel.',
      'stats_time': 'Flight Time',
      'stats_dist': 'Distance',
      'stats_coins': 'Coins Collected',
      'stats_damage': 'Damage Taken',
      'stats_reward': 'Total Reward',
      'stats_sec': 's',
      'stats_meters': 'm',
      'menu_coins': 'Coins Balance',
      'leaderboard_title': 'LEADERBOARD',
      'no_records': 'No records yet. Be the first!',
      'docked_alert': 'CARGO SECURED! DELIVER TO ORANGE EXIT SHAFT!',
      'exit_gate_alert': 'EXIT GATES CLOSE! LAND GENTLY ON ORANGE PLATFORM.',
      'settings': 'SETTINGS',
      'volume_music': 'Music',
      'volume_sfx': 'SFX',
      'close': 'CLOSE',
      'cargo_nearby': 'CARGO NEARBY. GET CLOSER TO DOCK',
      'approach_speed_alert': 'APPROACH VELOCITY TOO HIGH!',
      'align_landing_alert': 'ALIGN SHIP FOR LANDING!',
      'thrust_left': 'LEFT THRUST (A / ←)',
      'thrust_right': 'RIGHT THRUST (D / →)',
      'error_empty_nick': 'Nickname cannot be empty',
      'rope_snapped': 'WARNING: TENSION TOO HIGH, TETHER SNAPPED!',
      'cargo_released': 'CARGO UNHOOKED',
      'cargo_release': 'RELEASE CARGO (S / ↓)',
    }
  };

  // Метод перевода
  String translate(String key) {
    return _translations[_language]?[key] ?? key;
  }
}
