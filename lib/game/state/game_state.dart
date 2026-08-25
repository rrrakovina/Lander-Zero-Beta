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

  // Гардероб космонавта
  String _suitColor = 'classic_orange';
  String _selectedHelmet = 'sphere1';
  List<String> _ownedHelmets = ['sphere1'];
  String _selectedSuit = 'sk1_cadet';
  List<String> _ownedSuits = ['sk1_cadet'];

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
  String get suitColor => _suitColor;
  String get selectedHelmet => _selectedHelmet;
  List<String> get ownedHelmets => _ownedHelmets;
  String get selectedSuit => _selectedSuit;
  List<String> get ownedSuits => _ownedSuits;
  List<Map<String, dynamic>> get leaderboard => _leaderboard;

  // Каталог 6 цветов скафандра (100% бесплатно)
  static const List<Map<String, dynamic>> suitColors = [
    {
      'id': 'classic_orange',
      'nameKey': 'color_classic_orange',
      'color': Color(0xFFFF5722),
      'accent': Color(0xFFE64A19),
    },
    {
      'id': 'nasa_white',
      'nameKey': 'color_nasa_white',
      'color': Color(0xFFECEFF1),
      'accent': Color(0xFFFFFFFF),
    },
    {
      'id': 'cyber_cyan',
      'nameKey': 'color_cyber_cyan',
      'color': Color(0xFF00E5FF),
      'accent': Color(0xFF00B0FF),
    },
    {
      'id': 'carbon_black',
      'nameKey': 'color_carbon_black',
      'color': Color(0xFF212121),
      'accent': Color(0xFF37474F),
    },
    {
      'id': 'hazmat_yellow',
      'nameKey': 'color_hazmat_yellow',
      'color': Color(0xFFFFD600),
      'accent': Color(0xFFFFAB00),
    },
    {
      'id': 'crimson_interceptor',
      'nameKey': 'color_crimson_interceptor',
      'color': Color(0xFFD50000),
      'accent': Color(0xFFC62828),
    },
  ];

  // Каталог 4 типов шлемов (50-100 монет)
  static const Map<String, Map<String, dynamic>> helmetConfigs = {
    'sphere1': {
      'price': 0,
      'nameKey': 'helmet_sphere1',
      'descKey': 'helmet_sphere1_desc',
    },
    'cyber_visor': {
      'price': 60,
      'nameKey': 'helmet_cyber_visor',
      'descKey': 'helmet_cyber_visor_desc',
    },
    'miner_helmet': {
      'price': 80,
      'nameKey': 'helmet_miner_helmet',
      'descKey': 'helmet_miner_helmet_desc',
    },
    'swift_aero': {
      'price': 100,
      'nameKey': 'helmet_swift_aero',
      'descKey': 'helmet_swift_aero_desc',
    },
  };

  // Каталог 3 моделей костюмов (70-120 монет)
  static const Map<String, Map<String, dynamic>> suitConfigs = {
    'sk1_cadet': {
      'price': 0,
      'nameKey': 'suit_sk1_cadet',
      'descKey': 'suit_sk1_cadet_desc',
    },
    'exo_frame': {
      'price': 90,
      'nameKey': 'suit_exo_frame',
      'descKey': 'suit_exo_frame_desc',
    },
    'cryo_suit': {
      'price': 120,
      'nameKey': 'suit_cryo_suit',
      'descKey': 'suit_cryo_suit_desc',
    },
  };

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
      suitColor: _suitColor,
      selectedHelmet: _selectedHelmet,
      ownedHelmets: _ownedHelmets,
      selectedSuit: _selectedSuit,
      ownedSuits: _ownedSuits,
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
    final storedSuitColor = _prefs.getString('suitColor') ?? 'classic_orange';
    final storedHelmet = _prefs.getString('selectedHelmet') ?? 'sphere1';
    final storedOwnedHelmets = _prefs.getStringList('ownedHelmets') ?? ['sphere1'];
    final storedSuit = _prefs.getString('selectedSuit') ?? 'sk1_cadet';
    final storedOwnedSuits = _prefs.getStringList('ownedSuits') ?? ['sk1_cadet'];
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
      _suitColor = 'classic_orange';
      _selectedHelmet = 'sphere1';
      _ownedHelmets = ['sphere1'];
      _selectedSuit = 'sk1_cadet';
      _ownedSuits = ['sk1_cadet'];

      await _prefs.setInt('totalCoins', _totalCoins);
      await _prefs.setStringList('ownedRockets', _ownedRockets);
      await _prefs.setString('selectedRocket', _selectedRocket);
      await _prefs.setInt('engineLevel', _engineLevel);
      await _prefs.setInt('fuelLevel', _fuelLevel);
      await _prefs.setInt('shieldLevel', _shieldLevel);
      await _prefs.setString('leaderboard', '[]');
      await _prefs.setString('suitColor', _suitColor);
      await _prefs.setString('selectedHelmet', _selectedHelmet);
      await _prefs.setStringList('ownedHelmets', _ownedHelmets);
      await _prefs.setString('selectedSuit', _selectedSuit);
      await _prefs.setStringList('ownedSuits', _ownedSuits);
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

      _suitColor = storedSuitColor;
      _selectedHelmet = storedHelmet;
      _ownedHelmets = List<String>.from(storedOwnedHelmets);
      if (!_ownedHelmets.contains('sphere1')) _ownedHelmets.add('sphere1');
      if (!_ownedHelmets.contains(_selectedHelmet)) _selectedHelmet = 'sphere1';

      _selectedSuit = storedSuit;
      _ownedSuits = List<String>.from(storedOwnedSuits);
      if (!_ownedSuits.contains('sk1_cadet')) _ownedSuits.add('sk1_cadet');
      if (!_ownedSuits.contains(_selectedSuit)) _selectedSuit = 'sk1_cadet';

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
      final loadedSuitColor = storedSuitColor;
      final loadedHelmet = storedHelmet;
      final loadedOwnedHelmets = List<String>.from(storedOwnedHelmets);
      final loadedSuit = storedSuit;
      final loadedOwnedSuits = List<String>.from(storedOwnedSuits);

      final isValid = SaveSecurityManager.verifySignature(
        coins: loadedCoins,
        ownedRockets: loadedFleet,
        engineLevel: loadedEngine,
        fuelLevel: loadedFuel,
        shieldLevel: loadedShield,
        leaderboardJson: storedLb,
        suitColor: loadedSuitColor,
        selectedHelmet: loadedHelmet,
        ownedHelmets: loadedOwnedHelmets,
        selectedSuit: loadedSuit,
        ownedSuits: loadedOwnedSuits,
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

        _suitColor = loadedSuitColor;
        _selectedHelmet = loadedHelmet;
        _ownedHelmets = loadedOwnedHelmets;
        if (!_ownedHelmets.contains('sphere1')) _ownedHelmets.add('sphere1');
        if (!_ownedHelmets.contains(_selectedHelmet)) _selectedHelmet = 'sphere1';

        _selectedSuit = loadedSuit;
        _ownedSuits = loadedOwnedSuits;
        if (!_ownedSuits.contains('sk1_cadet')) _ownedSuits.add('sk1_cadet');
        if (!_ownedSuits.contains(_selectedSuit)) _selectedSuit = 'sk1_cadet';

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
        _suitColor = 'classic_orange';
        _selectedHelmet = 'sphere1';
        _ownedHelmets = ['sphere1'];
        _selectedSuit = 'sk1_cadet';
        _ownedSuits = ['sk1_cadet'];

        await _prefs.setInt('totalCoins', _totalCoins);
        await _prefs.setStringList('ownedRockets', _ownedRockets);
        await _prefs.setString('selectedRocket', _selectedRocket);
        await _prefs.setInt('engineLevel', _engineLevel);
        await _prefs.setInt('fuelLevel', _fuelLevel);
        await _prefs.setInt('shieldLevel', _shieldLevel);
        await _prefs.setString('leaderboard', '[]');
        await _prefs.setString('suitColor', _suitColor);
        await _prefs.setString('selectedHelmet', _selectedHelmet);
        await _prefs.setStringList('ownedHelmets', _ownedHelmets);
        await _prefs.setString('selectedSuit', _selectedSuit);
        await _prefs.setStringList('ownedSuits', _ownedSuits);
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

  // =========================================================================
  // Гардероб космонавта (Wardrobe Management)
  // =========================================================================

  /// Установка цвета скафандра (100% бесплатно в любое время)
  Future<void> setSuitColor(String color) async {
    _suitColor = color;
    await _prefs.setString('suitColor', _suitColor);
    await _saveIntegrity();
    notifyListeners();
  }

  /// Псевдоним для выбора цвета
  Future<void> selectSuitColor(String color) async {
    await setSuitColor(color);
  }

  /// Покупка шлема за монеты
  Future<bool> buyHelmet(String helmetId, int price) async {
    if (_ownedHelmets.contains(helmetId)) {
      await selectHelmet(helmetId);
      return true;
    }
    if (canAfford(price)) {
      _totalCoins -= price;
      _ownedHelmets.add(helmetId);
      _selectedHelmet = helmetId;
      await _prefs.setInt('totalCoins', _totalCoins);
      await _prefs.setStringList('ownedHelmets', _ownedHelmets);
      await _prefs.setString('selectedHelmet', _selectedHelmet);
      await _saveIntegrity();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Выбор купленного шлема
  Future<bool> selectHelmet(String helmetId) async {
    if (_ownedHelmets.contains(helmetId)) {
      _selectedHelmet = helmetId;
      await _prefs.setString('selectedHelmet', _selectedHelmet);
      await _saveIntegrity();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Покупка модели костюма за монеты
  Future<bool> buySuit(String suitId, int price) async {
    if (_ownedSuits.contains(suitId)) {
      await selectSuit(suitId);
      return true;
    }
    if (canAfford(price)) {
      _totalCoins -= price;
      _ownedSuits.add(suitId);
      _selectedSuit = suitId;
      await _prefs.setInt('totalCoins', _totalCoins);
      await _prefs.setStringList('ownedSuits', _ownedSuits);
      await _prefs.setString('selectedSuit', _selectedSuit);
      await _saveIntegrity();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Выбор купленного костюма
  Future<bool> selectSuit(String suitId) async {
    if (_ownedSuits.contains(suitId)) {
      _selectedSuit = suitId;
      await _prefs.setString('selectedSuit', _selectedSuit);
      await _saveIntegrity();
      notifyListeners();
      return true;
    }
    return false;
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
      'tab_pilot': 'ПИЛОТ',
      'suit_color': 'ЦВЕТ СКАФАНДРА',
      'free_color': 'БЕСПЛАТНО',
      'helmet_type': 'ТИП ШЛЕМА',
      'suit_model': 'МОДЕЛЬ КОСТЮМА',
      'pilot_callsign': 'ПОЗЫВНОЙ ПИЛОТА',
      'equip': 'ВЫБРАТЬ',
      'equipped': 'НАДЕТО',
      'buy': 'КУПИТЬ',
      'select': 'ВЫБРАТЬ',
      'selected': 'ВЫБРАНО',
      'color_classic_orange': 'Классический оранжевый',
      'color_nasa_white': 'NASA Белый',
      'color_cyber_cyan': 'Кибер-циан',
      'color_carbon_black': 'Карбоновый черный',
      'color_hazmat_yellow': 'Защитный желтый',
      'color_crimson_interceptor': 'Багровый перехватчик',
      'helmet_sphere1': 'Сфера-1',
      'helmet_sphere1_desc': 'Ретро-купол с панорамным обзором.',
      'helmet_cyber_visor': 'Кибер-Визор',
      'helmet_cyber_visor_desc': 'Угловатый шлем с неоновой щелью визора.',
      'helmet_miner_helmet': 'Шлем Шахтера',
      'helmet_miner_helmet_desc': 'Бронированная стальная решетка и прочный корпус.',
      'helmet_swift_aero': 'Стриж-Аэро',
      'helmet_swift_aero_desc': 'Обтекаемый шлем перехватчика с золотым визором.',
      'suit_sk1_cadet': 'СК-1 Курсант',
      'suit_sk1_cadet_desc': 'Стандартный летный костюм с шевроном миссии.',
      'suit_exo_frame': 'Экзо-Каркас',
      'suit_exo_frame_desc': 'Усиленный наплечный каркас и кислородные трубки.',
      'suit_cryo_suit': 'Крио-Костюм',
      'suit_cryo_suit_desc': 'Термоизоляционные ребра и крио-трубки.',
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
      'tab_pilot': 'PILOT',
      'suit_color': 'SUIT COLOR',
      'free_color': 'FREE',
      'helmet_type': 'HELMET TYPE',
      'suit_model': 'SUIT MODEL',
      'pilot_callsign': 'PILOT CALLSIGN',
      'equip': 'EQUIP',
      'equipped': 'EQUIPPED',
      'buy': 'BUY',
      'select': 'SELECT',
      'selected': 'SELECTED',
      'color_classic_orange': 'Classic Orange',
      'color_nasa_white': 'NASA White',
      'color_cyber_cyan': 'Cyber Cyan',
      'color_carbon_black': 'Carbon Black',
      'color_hazmat_yellow': 'Hazmat Yellow',
      'color_crimson_interceptor': 'Crimson Interceptor',
      'helmet_sphere1': 'Sphere-1',
      'helmet_sphere1_desc': 'Retro bubble dome with panoramic visibility.',
      'helmet_cyber_visor': 'Cyber-Visor',
      'helmet_cyber_visor_desc': 'Angular helmet with narrow neon visor slit.',
      'helmet_miner_helmet': 'Miner Helmet',
      'helmet_miner_helmet_desc': 'Armored steel cross-grate and reinforced casing.',
      'helmet_swift_aero': 'Swift-Aero',
      'helmet_swift_aero_desc': 'Streamlined interceptor helmet with gold-tinted visor.',
      'suit_sk1_cadet': 'SK-1 Cadet',
      'suit_sk1_cadet_desc': 'Standard flight suit with mission patch.',
      'suit_exo_frame': 'Exo-Frame',
      'suit_exo_frame_desc': 'Padded pauldron harness and dual oxygen tubes.',
      'suit_cryo_suit': 'Cryo-Suit',
      'suit_cryo_suit_desc': 'Thermal layered seams with illuminated cryo-piping.',
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
