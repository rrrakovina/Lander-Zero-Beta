import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../audio/game_audio_manager.dart';

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
  String _selectedRocket = 'sputnik'; // 'sputnik', 'cyclone', 'needle'
  List<String> _ownedRockets = ['sputnik'];
  
  // Уровни прокачки (1-5)
  int _engineLevel = 1;
  int _fuelLevel = 1;
  int _shieldLevel = 1;

  // Таблица рекордов: список заездов. Каждый элемент: {'name': name, 'map': map, 'distance': d, 'coins': c}
  List<Map<String, dynamic>> _leaderboard = [];

  bool get initialized => _initialized;
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

  // Характеристики ракет
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
      'descRu': 'Легкий перехватчик. Маневренный и экономичный, но очень хрупкий.',
      'descEn': 'Sleek speedster. Fast and efficient, but extremely fragile.',
      'price': 1500,
      'baseThrust': 35.0,
      'baseFuel': 130.0,
      'baseShield': 60.0,
      'mass': 0.6,
    },
  };

  // Инициализация загрузки из SharedPreferences
  Future<void> init({bool force = false}) async {
    if (_initialized && !force) return;
    _prefs = await SharedPreferences.getInstance();

    _nickname = _prefs.getString('nickname') ?? '';
    _language = _prefs.getString('language') ?? 'ru';
    _musicVolume = _prefs.getDouble('musicVolume') ?? 0.7;
    _sfxVolume = _prefs.getDouble('sfxVolume') ?? 0.8;
    _totalCoins = _prefs.getInt('totalCoins') ?? 0;
    _selectedRocket = _prefs.getString('selectedRocket') ?? 'sputnik';
    _ownedRockets = _prefs.getStringList('ownedRockets') ?? ['sputnik'];
    _engineLevel = _prefs.getInt('engineLevel') ?? 1;
    _fuelLevel = _prefs.getInt('fuelLevel') ?? 1;
    _shieldLevel = _prefs.getInt('shieldLevel') ?? 1;

    final lbString = _prefs.getString('leaderboard') ?? '[]';
    try {
      final List<dynamic> decoded = jsonDecode(lbString);
      _leaderboard = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      _leaderboard = [];
    }

    _initialized = true;
    notifyListeners();
  }

  // Запись ника
  Future<void> setNickname(String name) async {
    _nickname = name.trim();
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
    // Если эффекты были заглушены, принудительно гасим цикличный звук двигателя
    if (_sfxVolume == 0.0) {
      GameAudioManager().stopThrustLoop();
    }
  }

  // Начисление монет
  Future<void> addCoins(int amount) async {
    _totalCoins += amount;
    await _prefs.setInt('totalCoins', _totalCoins);
    notifyListeners();
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
      notifyListeners();
      return true;
    }
    return false;
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

      notifyListeners();
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
    _leaderboard.sort((a, b) => b['distance'].compareTo(a['distance']));
    
    // Оставляем только топ-10
    if (_leaderboard.length > 10) {
      _leaderboard = _leaderboard.sublist(0, 10);
    }

    await _prefs.setString('leaderboard', jsonEncode(_leaderboard));
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
    }
  };

  // Метод перевода
  String translate(String key) {
    return _translations[_language]?[key] ?? key;
  }
}
