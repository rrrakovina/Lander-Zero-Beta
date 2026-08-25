import 'dart:math';
import 'package:flutter/material.dart';
import '../../game/config/game_config.dart';
import '../../game/state/game_state.dart';
import '../../game/audio/game_audio_manager.dart';
import '../widgets/menu_background.dart';
import '../widgets/glass_panel.dart';
import '../painters/map_preview_painter.dart';

class MapBriefingData {
  final String id;
  final String nameRu;
  final String nameEn;
  final String descRu;
  final String descEn;
  final String difficultyRu;
  final String difficultyEn;
  final Color themeColor;
  final IconData icon;
  final String commStatusRu;
  final String commStatusEn;
  final Color commStatusColor;
  final String gravityRu;
  final String gravityEn;
  final String windRu;
  final String windEn;
  final String thermalRu;
  final String thermalEn;
  final String radiationRu;
  final String radiationEn;
  final String seismicRu;
  final String seismicEn;
  final String recCabinRu;
  final String recCabinEn;
  final String hazardsRu;
  final String hazardsEn;
  final String bountyRangeRu;
  final String bountyRangeEn;
  final String missionStoryRu;
  final String missionStoryEn;
  final String missionObjectiveRu;
  final String missionObjectiveEn;

  const MapBriefingData({
    required this.id,
    required this.nameRu,
    required this.nameEn,
    required this.descRu,
    required this.descEn,
    required this.difficultyRu,
    required this.difficultyEn,
    required this.themeColor,
    required this.icon,
    required this.commStatusRu,
    required this.commStatusEn,
    required this.commStatusColor,
    required this.gravityRu,
    required this.gravityEn,
    required this.windRu,
    required this.windEn,
    required this.thermalRu,
    required this.thermalEn,
    required this.radiationRu,
    required this.radiationEn,
    required this.seismicRu,
    required this.seismicEn,
    required this.recCabinRu,
    required this.recCabinEn,
    required this.hazardsRu,
    required this.hazardsEn,
    required this.bountyRangeRu,
    required this.bountyRangeEn,
    required this.missionStoryRu,
    required this.missionStoryEn,
    required this.missionObjectiveRu,
    required this.missionObjectiveEn,
  });

  static const Map<String, MapBriefingData> maps = {
    'echo': MapBriefingData(
      id: 'echo',
      nameRu: 'Каньон Эхо',
      nameEn: 'Echo Canyon',
      descRu: 'Заброшенная научная шахта. Стабильная атмосфера, идеальна для тренировки.',
      descEn: 'Abandoned research shaft. Stable atmosphere, ideal for flight practice.',
      difficultyRu: 'Легко',
      difficultyEn: 'Easy',
      themeColor: Color(0xFF00E676),
      icon: Icons.terrain_rounded,
      commStatusRu: 'СВЯЗЬ: СТАБИЛЬНАЯ',
      commStatusEn: 'COMM STATUS: ACTIVE',
      commStatusColor: Color(0xFF00E676),
      gravityRu: '1.0x (3.5 м/с²)',
      gravityEn: '1.0x (3.5 m/s²)',
      windRu: '0.0 Н (Штиль)',
      windEn: '0.0 N (Calm / None)',
      thermalRu: '+22°C (Умеренная)',
      thermalEn: '+22°C (Temperate)',
      radiationRu: '0.05 мЗв (Фон в норме)',
      radiationEn: '0.05 mSv (Safe Background)',
      seismicRu: 'Класс 0 (Стабильно)',
      seismicEn: 'Class 0 (Stable)',
      recCabinRu: 'Спутник-1 (Сбалансирован)',
      recCabinEn: 'Sputnik-1 (Balanced)',
      hazardsRu: 'Минимум обломков, стабильная гравитация',
      hazardsEn: 'Low debris, stable gravity pull',
      bountyRangeRu: '100 - 300 монет',
      bountyRangeEn: '100 - 300 coins',
      missionStoryRu: 'Каньон Эхо — заброшенная научная шахта на окраине обитаемой зоны. Радар зафиксировал здесь аварийный сигнал с грузового контейнера. Разведка сообщает о стабильной атмосфере и слабом магнитном поле. Идеальная стартовая миссия для отработки навыков маневрирования.',
      missionStoryEn: 'Echo Canyon is an abandoned research shaft on the edge of the habitable zone. Radar detected an emergency signal from a cargo container. Intel reports a stable atmosphere and weak magnetic fields. The perfect starter mission to hone your piloting skills.',
      missionObjectiveRu: 'Спуститься в каньон, прицепить контейнер с ценными материалами с помощью автоматического троса и осторожно доставить его на выходную платформу в правой части пещеры.',
      missionObjectiveEn: 'Descend into the canyon, dock with the valuable material container using the automated tether, and carefully transport it to the exit platform on the far right.',
    ),
    'wind': MapBriefingData(
      id: 'wind',
      nameRu: 'Солнечные Ветра',
      nameEn: 'Solar Winds',
      descRu: 'Расселина с открытым космосом. Мощные плазменные порывы сдувают корабль.',
      descEn: 'Deep rift exposed to space. Violent lateral plasma winds push your craft.',
      difficultyRu: 'Средне',
      difficultyEn: 'Medium',
      themeColor: GameConfig.colorWarning,
      icon: Icons.air_rounded,
      commStatusRu: 'СВЯЗЬ: ПОМЕХИ В КАНАЛЕ',
      commStatusEn: 'COMM STATUS: DEGRADED',
      commStatusColor: GameConfig.colorWarning,
      gravityRu: '1.0x (3.5 м/с²)',
      gravityEn: '1.0x (3.5 m/s²)',
      windRu: '-4.5 Н (Боковой снос влево)',
      windEn: '-4.5 N (Strong lateral left gusts)',
      thermalRu: '-120°C (Криогенная плазма)',
      thermalEn: '-120°C (Cryo Plasma Dust)',
      radiationRu: '18.4 мЗв (Солнечные вспышки)',
      radiationEn: '18.4 mSv (Solar Plasma Flares)',
      seismicRu: 'Класс 1 (Микрометеориты)',
      seismicEn: 'Class 1 (Micro-meteorites)',
      recCabinRu: 'Игла (Маневренность / Мин. лобовое сопротивление)',
      recCabinEn: 'Needle (Agile / Low Drag Profile)',
      hazardsRu: 'Непрерывный боковой снос ветром, ионизированные вспышки',
      hazardsEn: 'Continuous lateral wind drag, ionized solar flare bursts',
      bountyRangeRu: '300 - 600 монет',
      bountyRangeEn: '300 - 600 coins',
      missionStoryRu: 'Эта расселина выходит прямо к открытому космосу и подвергается постоянным выбросам ионизированной плазмы. Мощнейший боковой солнечный ветер непрерывно сдувает любой пролетающий корабль влево. Будьте предельно осторожны при удержании курса!',
      missionStoryEn: 'This crevice is exposed directly to deep space and experiences constant bursts of ionized plasma. A powerful solar wind continuously blows any passing vessel to the left. Exercise extreme caution to hold your course!',
      missionObjectiveRu: 'Оказать сопротивление боковому сносу, найти контейнер в глубине пещеры и эвакуировать его. Потребуется постоянная компенсация траектории правым двигателем.',
      missionObjectiveEn: 'Combat the strong lateral wind, locate the container deep inside, and evacuate it. Requires constant trajectory correction using your right thruster.',
    ),
    'core': MapBriefingData(
      id: 'core',
      nameRu: 'Глубинное Ядро',
      nameEn: 'Deep Core',
      descRu: 'Экстремальная гравитационная аномалия. Повышенный расход топлива.',
      descEn: 'Extreme gravity anomaly. Heavy fuel drain and lethal impact hazards.',
      difficultyRu: 'Сложно',
      difficultyEn: 'Hard',
      themeColor: GameConfig.colorDanger,
      icon: Icons.south_rounded,
      commStatusRu: 'СВЯЗЬ: ДЕСТАБИЛИЗИРОВАНА',
      commStatusEn: 'COMM STATUS: CRITICAL',
      commStatusColor: GameConfig.colorDanger,
      gravityRu: '1.5x (5.3 м/с² - Тяжелое ядро)',
      gravityEn: '1.5x (5.3 m/s² - Heavy Core)',
      windRu: '0.0 Н (Плотный вакуум)',
      windEn: '0.0 N (Dense void)',
      thermalRu: '+850°C (Магматический перегрев)',
      thermalEn: '+850°C (Magma Thermal Venting)',
      radiationRu: '94.2 мЗв (Гамма-излучение ядра)',
      radiationEn: '94.2 mSv (Gamma Core Flux)',
      seismicRu: 'Класс 4 (Тектонические толчки)',
      seismicEn: 'Class 4 (Tectonic Tremors)',
      recCabinRu: 'Ураган (Усиленная броня и тяга)',
      recCabinEn: 'Cyclone (Reinforced Armor & Heavy Thrust)',
      hazardsRu: 'Сокрушительная гравитация, критический урон при столкновении',
      hazardsEn: 'Crushing gravity, catastrophic impact damage risks',
      bountyRangeRu: '600+ монет',
      bountyRangeEn: '600+ coins',
      missionStoryRu: 'Сверхглубокая гравитационная аномалия. Сила тяжести здесь повышена на 50%, что создает колоссальную нагрузку на двигатели. Любое резкое падение приведет к моментальному взрыву кабины. Запасы топлива ограничены, а расход увеличен из-за постоянной работы двигателей.',
      missionStoryEn: 'An ultra-deep gravitational anomaly. Gravity is 50% stronger here, putting colossal load on your thrusters. Any sudden drop will trigger an immediate hull breach. Fuel is highly limited, and consumption is accelerated due to constant burns.',
      missionObjectiveRu: 'Совершить ювелирный спуск в ядро планеты. Подхватить контейнер и вытащить его наверх, борясь с экстремальным притяжением. Каждое столкновение наносит критический урон!',
      missionObjectiveEn: 'Execute a pinpoint landing into the planet\'s core. Hook the cargo and lift it back up, fighting the extreme pull. Every impact deals critical structural damage!',
    ),
    'ice': MapBriefingData(
      id: 'ice',
      nameRu: 'Ледяные Разломы Европы',
      nameEn: 'Europa Ice Chasms',
      descRu: 'Криогенный спутник Юпитера. Сверхнизкое сцепление со льдом и геотермальные гейзеры.',
      descEn: 'Cryogenic Jovian moon. Ultra-low surface friction with active cryo-geysers.',
      difficultyRu: 'Эксперт',
      difficultyEn: 'Expert',
      themeColor: Color(0xFF00E5FF),
      icon: Icons.ac_unit_rounded,
      commStatusRu: 'СВЯЗЬ: ЗАДЕРЖКА СИГНАЛА',
      commStatusEn: 'COMM STATUS: HIGH LATENCY',
      commStatusColor: Color(0xFF00E5FF),
      gravityRu: '0.65x (2.28 м/с²)',
      gravityEn: '0.65x (2.28 m/s²)',
      windRu: 'Крио-гейзеры (Вертикальные выбросы)',
      windEn: 'Cryo-geysers (Vertical plumes)',
      thermalRu: '-170°C (Криогенный холод)',
      thermalEn: '-170°C (Deep Cryo Freeze)',
      radiationRu: '42.0 мЗв (Магнитосфера Юпитера)',
      radiationEn: '42.0 mSv (Jovian Magnetosphere)',
      seismicRu: 'Класс 2 (Ледовые трещины)',
      seismicEn: 'Class 2 (Ice Fractures)',
      recCabinRu: 'Стриж (Маневренность для обхода гейзеров)',
      recCabinEn: 'Swift-02 (High agility for geyser evasion)',
      hazardsRu: 'Скользкий лед (низкое сцепление), падающие сосульки, выбросы пара',
      hazardsEn: 'Slippery ice (low friction), falling icicles, cryo steam bursts',
      bountyRangeRu: '500 - 900 монет',
      bountyRangeEn: '500 - 900 coins',
      missionStoryRu: 'Ледяная кора Европы скрывает подземные океаны. Посадка на ледяную поверхность сопряжена с критически низким сцеплением (корабль долго скользит). Геотермальные гейзеры выбрасывают столбы ледяного пара, подбрасывая корабль вверх.',
      missionStoryEn: 'Europa\'s frozen crust conceals subsurface oceans. Landing on frictionless ice causes extreme drift. High-pressure cryo-geysers erupt from fissures, launching any vessel caught in the plume skyward.',
      missionObjectiveRu: 'Осуществить точную посадку на скользкий лед, перехватить крио-контейнер и эвакуировать его сквозь разломы и гейзерные выбросы.',
      missionObjectiveEn: 'Navigate low-friction icy caverns, evade erupting cryo-geysers, and extract the stranded cryogenic specimen to the upper orbital platform.',
    ),
    'orbit': MapBriefingData(
      id: 'orbit',
      nameRu: 'Орбитальные Обломки',
      nameEn: 'Orbital Debris Salvage',
      descRu: 'Глубокий космос в поясе астероидов. Полная невесомость (0G) и свободный дрейф.',
      descEn: 'Deep space asteroid salvage field. Zero gravity (0G) and frictionless inertia.',
      difficultyRu: 'Мастер',
      difficultyEn: 'Master',
      themeColor: Color(0xFFE040FB),
      icon: Icons.blur_on_rounded,
      commStatusRu: 'СВЯЗЬ: РЕТРАНСЛЯТОР',
      commStatusEn: 'COMM STATUS: RELAY LINK',
      commStatusColor: Color(0xFFE040FB),
      gravityRu: '0.0x (0.0 м/с² - Невесомость)',
      gravityEn: '0.0x (0.0 m/s² - Zero Gravity)',
      windRu: '0.0 Н (Открытый вакуум)',
      windEn: '0.0 N (Hard Vacuum)',
      thermalRu: '-270°C (Космический вакуум)',
      thermalEn: '-270°C (Cosmic Void)',
      radiationRu: '78.5 мЗв (Космические лучи)',
      radiationEn: '78.5 mSv (Cosmic Ray Flux)',
      seismicRu: 'Класс 0 (Вакуум)',
      seismicEn: 'Class 0 (Zero Drift)',
      recCabinRu: 'Квазар (Ионный РСУ для маневров в 0G)',
      recCabinEn: 'Quasar-IX (Ion RCS for 0G maneuvering)',
      hazardsRu: 'Отсутствие гравитации, свободный дрейф, дрейфующие обломки',
      hazardsEn: 'Zero gravity, high momentum drift, floating debris',
      bountyRangeRu: '800 - 1500 монет',
      bountyRangeEn: '800 - 1500 coins',
      missionStoryRu: 'Кладбище орбитальных станций в глубоком вакууме. Гравитационное поле отсутствует полностью. Корабль продолжает двигаться бесконечно по инерции, пока не включены реверсивные двигатели или маневровые РСУ.',
      missionStoryEn: 'A zero-G orbital graveyard of derelict research satellites. With zero gravitational deceleration, every burst of thrust must be actively counter-braked to avoid catastrophic collision.',
      missionObjectiveRu: 'Аккуратно состыковаться с дрейфующим спутником в невесомости, погасить инерцию и доставить модуль в спасательный док.',
      missionObjectiveEn: 'Execute zero-gravity docking with the drifting orbital module, master reverse thruster braking, and safely tow the salvage to the recovery cruiser.',
    ),
    'endless': MapBriefingData(
      id: 'endless',
      nameRu: 'Бесконечный Сектор',
      nameEn: 'Endless Rescue Sector',
      descRu: 'Процедурно генерируемый лабиринт. Бесконечная череда выживших, заправок и опасностей.',
      descEn: 'Procedurally generated labyrinth. Infinite chain of survivor capsules, outposts, and hazards.',
      difficultyRu: 'Выживание',
      difficultyEn: 'Survival',
      themeColor: Color(0xFFFFD700),
      icon: Icons.all_inclusive_rounded,
      commStatusRu: 'СВЯЗЬ: АВТОНОМНЫЙ ПОИСК',
      commStatusEn: 'COMM STATUS: AUTONOMOUS SCAN',
      commStatusColor: Color(0xFFFFD700),
      gravityRu: '1.0x - 1.5x (Динамическая)',
      gravityEn: '1.0x - 1.5x (Dynamic)',
      windRu: 'Переменные порывы ветра',
      windEn: 'Turbulent variable gusts',
      thermalRu: 'Динамический фон',
      thermalEn: 'Dynamic sector flux',
      radiationRu: 'Прогрессирующий фон',
      radiationEn: 'Progressive radiation index',
      seismicRu: 'Класс 1-4 (Нарастающий)',
      seismicEn: 'Class 1-4 (Escalating)',
      recCabinRu: 'Буран-М / Ураган (Тяжелая броня)',
      recCabinEn: 'Titan-V / Cyclone (Reinforced Armor)',
      hazardsRu: 'Непрерывная череда препятствий, увеличивающаяся скорость, нехватка топлива',
      hazardsEn: 'Chained rescues, tightening gaps, fuel starvation risk',
      bountyRangeRu: 'Не ограничено',
      bountyRangeEn: 'Unlimited (1000/res)',
      missionStoryRu: 'Бесконечный неизведанный сектор глубокого космоса. Экстренный сигнал SOS поступает непрерывно от множества изолированных капсул. Продвигайтесь вперед как можно дальше, заправляясь на промежуточных аванпостах.',
      missionStoryEn: 'An infinite uncharted deep-space cavern system. Consecutive survivor beacons are detected ahead. Push as deep as possible while refueling at modular outpost stations.',
      missionObjectiveRu: 'Эвакуировать максимальное число выживших подряд, устанавливая новые рекорды дистанции и спасательного рейтинга.',
      missionObjectiveEn: 'Rescue as many stranded astronauts as possible across infinite cavern chunks, managing fuel reserves and enduring progressive environmental hazards.',
    ),
  };
}

class MapSelectWidget extends StatefulWidget {
  final ValueChanged<String> onMapSelected;
  final VoidCallback onBack;

  const MapSelectWidget({
    super.key,
    required this.onMapSelected,
    required this.onBack,
  });

  @override
  State<MapSelectWidget> createState() => _MapSelectWidgetState();
}

class _MapSelectWidgetState extends State<MapSelectWidget> with SingleTickerProviderStateMixin {
  String? _previewMapId;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = GameState();
    final isRu = state.language == 'ru';

    if (_previewMapId != null) {
      return _buildMapPreviewScreen(state, isRu);
    }

    final mapKeys = ['echo', 'wind', 'core', 'ice', 'orbit', 'endless'];

    return MenuBackground(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () {
                    GameAudioManager().playTap();
                    widget.onBack();
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  state.translate('map_select'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const Spacer(),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: mapKeys.map((key) {
                  final mapData = MapBriefingData.maps[key]!;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: _buildMapCard(
                      context: context,
                      mapData: mapData,
                      isRu: isRu,
                    ),
                  );
                }).toList(),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCard({
    required BuildContext context,
    required MapBriefingData mapData,
    required bool isRu,
  }) {
    final color = mapData.themeColor;
    final name = isRu ? mapData.nameRu : mapData.nameEn;
    final desc = isRu ? mapData.descRu : mapData.descEn;
    final difficulty = isRu ? mapData.difficultyRu : mapData.difficultyEn;
    final gravity = isRu ? mapData.gravityRu : mapData.gravityEn;
    final wind = isRu ? mapData.windRu : mapData.windEn;
    final thermal = isRu ? mapData.thermalRu : mapData.thermalEn;
    final radiation = isRu ? mapData.radiationRu : mapData.radiationEn;
    final bounty = isRu ? mapData.bountyRangeRu : mapData.bountyRangeEn;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          GameAudioManager().playTap();
          setState(() {
            _previewMapId = mapData.id;
          });
        },
        borderRadius: BorderRadius.circular(16),
        hoverColor: color.withOpacity(0.05),
        splashColor: color.withOpacity(0.1),
        child: Container(
          width: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.35), width: 2),
            color: const Color(0xFF16161E).withOpacity(0.92),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(mapData.icon, color: color, size: 28),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withOpacity(0.4)),
                    ),
                    child: Text(
                      difficulty.toUpperCase(),
                      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                desc,
                style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              const Divider(color: Colors.white10),
              const SizedBox(height: 6),
              _buildCardParamRow(
                label: isRu ? 'Гравитация' : 'Gravity',
                value: gravity,
                color: Colors.white,
              ),
              const SizedBox(height: 4),
              _buildCardParamRow(
                label: isRu ? 'Ветровой снос' : 'Wind force',
                value: wind,
                color: mapData.id == 'wind' ? GameConfig.colorWarning : Colors.white,
              ),
              const SizedBox(height: 4),
              _buildCardParamRow(
                label: isRu ? 'Температура' : 'Thermal',
                value: thermal,
                color: mapData.id == 'core' ? GameConfig.colorDanger : (mapData.id == 'ice' ? const Color(0xFF00E5FF) : Colors.white),
              ),
              const SizedBox(height: 4),
              _buildCardParamRow(
                label: isRu ? 'Радиация' : 'Radiation',
                value: radiation,
                color: mapData.id == 'core' ? GameConfig.colorDanger : (mapData.id == 'wind' ? GameConfig.colorWarning : Colors.white),
              ),
              const SizedBox(height: 4),
              _buildCardParamRow(
                label: isRu ? 'Награда' : 'Bounty',
                value: bounty,
                color: GameConfig.colorWarning,
                isBold: true,
              ),
              const SizedBox(height: 10),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isRu ? 'БРИФИНГ' : 'BRIEFING',
                        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, color: color, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardParamRow({
    required String label,
    required String value,
    required Color color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapPreviewScreen(GameState state, bool isRu) {
    final mapData = MapBriefingData.maps[_previewMapId] ?? MapBriefingData.maps['echo']!;
    final themeColor = mapData.themeColor;
    final name = isRu ? mapData.nameRu : mapData.nameEn;
    final difficulty = isRu ? mapData.difficultyRu : mapData.difficultyEn;
    final statusBadge = isRu ? mapData.commStatusRu : mapData.commStatusEn;
    final statusBadgeColor = mapData.commStatusColor;
    final missionStory = isRu ? mapData.missionStoryRu : mapData.missionStoryEn;
    final missionObjective = isRu ? mapData.missionObjectiveRu : mapData.missionObjectiveEn;
    final recCabin = isRu ? mapData.recCabinRu : mapData.recCabinEn;
    final hazards = isRu ? mapData.hazardsRu : mapData.hazardsEn;
    final gravity = isRu ? mapData.gravityRu : mapData.gravityEn;
    final wind = isRu ? mapData.windRu : mapData.windEn;
    final bountyRange = isRu ? mapData.bountyRangeRu : mapData.bountyRangeEn;

    int bestDist = 0;
    for (final entry in state.leaderboard) {
      if (entry['map'] == _previewMapId) {
        final dist = (entry['distance'] as num?)?.toInt() ?? 0;
        if (dist > bestDist) {
          bestDist = dist;
        }
      }
    }
    final String recordText = bestDist > 0
        ? (isRu ? '$bestDist м' : '$bestDist m')
        : (isRu ? 'Нет попыток' : 'No attempts yet');

    return MenuBackground(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () {
                    GameAudioManager().playTap();
                    setState(() {
                      _previewMapId = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  isRu ? 'ПРЕДПРОСМОТР ЛОКАЦИИ' : 'LOCATION PREVIEW',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: GlassPanel(
                      borderColor: themeColor.withOpacity(0.3),
                      padding: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: themeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(mapData.icon, color: themeColor, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: themeColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  difficulty.toUpperCase(),
                                  style: TextStyle(color: themeColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusBadgeColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: statusBadgeColor.withOpacity(0.2)),
                                  ),
                                  child: Text(
                                    statusBadge.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: statusBadgeColor,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildBriefingSubCard(
                                    title: isRu ? 'СВОДКА МИССИИ' : 'MISSION BRIEFING',
                                    themeColor: themeColor,
                                    content: missionStory,
                                  ),
                                  const SizedBox(height: 10),
                                  _buildBriefingSubCard(
                                    title: isRu ? 'ОСНОВНАЯ ЗАДАЧА' : 'PRIMARY OBJECTIVE',
                                    themeColor: themeColor,
                                    content: missionObjective,
                                  ),
                                  const SizedBox(height: 10),
                                  _buildBriefingSubCard(
                                    title: isRu ? 'ТЕЛЕМЕТРИЯ СРЕДЫ И АНОМАЛИЙ' : 'ENVIRONMENTAL HAZARD TELEMETRY',
                                    themeColor: themeColor,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildDiagRow(
                                          icon: Icons.south_rounded,
                                          label: isRu ? 'Гравитационное поле:' : 'Gravity pull:',
                                          value: gravity,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(height: 5),
                                        _buildDiagRow(
                                          icon: Icons.air_rounded,
                                          label: isRu ? 'Ветровые потоки / Тяга:' : 'Wind force / Vector:',
                                          value: wind,
                                          color: mapData.id == 'wind' ? GameConfig.colorWarning : Colors.white70,
                                        ),
                                        const SizedBox(height: 5),
                                        _buildDiagRow(
                                          icon: Icons.thermostat_rounded,
                                          label: isRu ? 'Температурный фон:' : 'Thermal flux / Temp:',
                                          value: isRu ? mapData.thermalRu : mapData.thermalEn,
                                          color: mapData.id == 'core' ? GameConfig.colorDanger : (mapData.id == 'wind' ? const Color(0xFF80D8FF) : Colors.white),
                                        ),
                                        const SizedBox(height: 5),
                                        _buildDiagRow(
                                          icon: Icons.wb_sunny_rounded,
                                          label: isRu ? 'Радиационный / Солн. фон:' : 'Radiation / Solar flux:',
                                          value: isRu ? mapData.radiationRu : mapData.radiationEn,
                                          color: mapData.id == 'core' ? GameConfig.colorDanger : (mapData.id == 'wind' ? GameConfig.colorWarning : Colors.white70),
                                        ),
                                        const SizedBox(height: 5),
                                        _buildDiagRow(
                                          icon: Icons.vibration_rounded,
                                          label: isRu ? 'Сейсмическая активность:' : 'Seismic activity:',
                                          value: isRu ? mapData.seismicRu : mapData.seismicEn,
                                          color: mapData.id == 'core' ? GameConfig.colorDanger : Colors.white70,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildBriefingSubCard(
                                    title: isRu ? 'НАГРАДЫ И БОНУСЫ ЗА МИССИЮ' : 'MISSION REWARDS & CRITERIA',
                                    themeColor: themeColor,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildRewardRow(
                                          icon: Icons.stars_rounded,
                                          label: isRu ? 'Оценочная общая награда:' : 'Estimated total bounty:',
                                          value: bountyRange,
                                          color: GameConfig.colorWarning,
                                          isBold: true,
                                        ),
                                        const SizedBox(height: 5),
                                        _buildRewardRow(
                                          icon: Icons.inventory_2_rounded,
                                          label: isRu ? 'Базовая эвакуация груза:' : 'Base cargo extraction:',
                                          value: '+100 🪙',
                                          color: const Color(0xFF00E676),
                                        ),
                                        const SizedBox(height: 5),
                                        _buildRewardRow(
                                          icon: Icons.shield_rounded,
                                          label: isRu ? 'Без повреждений (Мягкая посадка):' : '0 Damage (Soft Landing):',
                                          value: '+100 🪙',
                                          color: const Color(0xFF00E5FF),
                                        ),
                                        const SizedBox(height: 5),
                                        _buildRewardRow(
                                          icon: Icons.timer_rounded,
                                          label: isRu ? 'Скоростной подъем (< 45 сек):' : 'Speed rescue (< 45s):',
                                          value: '+120 🪙',
                                          color: const Color(0xFFFFD700),
                                        ),
                                        const SizedBox(height: 5),
                                        _buildRewardRow(
                                          icon: Icons.local_gas_station_rounded,
                                          label: isRu ? 'Эко-пилот (> 50% топлива):' : 'Eco-pilot (> 50% fuel):',
                                          value: '+80 🪙',
                                          color: const Color(0xFFE040FB),
                                        ),
                                        const SizedBox(height: 5),
                                        _buildRewardRow(
                                          icon: Icons.monetization_on_rounded,
                                          label: isRu ? 'Сбор кристаллов в полете:' : 'In-flight star-coins:',
                                          value: isRu ? '+10 🪙 за шт.' : '+10 🪙 each',
                                          color: Colors.white70,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildBriefingSubCard(
                                    title: isRu ? 'ТАКТИЧЕСКИЙ АНАЛИЗ' : 'CAVERN DIAGNOSTICS',
                                    themeColor: themeColor,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildDiagRow(
                                          icon: Icons.rocket_launch_rounded,
                                          label: isRu ? 'Реком. кабина:' : 'Rec. module:',
                                          value: recCabin,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(height: 5),
                                        _buildDiagRow(
                                          icon: Icons.warning_amber_rounded,
                                          label: isRu ? 'Опасности:' : 'Hazards:',
                                          value: hazards,
                                          color: statusBadgeColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildBriefingSubCard(
                                    title: isRu ? 'ВАШ РЕКОРД ДИСТАНЦИИ' : 'YOUR BEST DISTANCE',
                                    themeColor: themeColor,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.emoji_events_rounded, color: GameConfig.colorWarning, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          recordText,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(isRu ? 'Сила гравитации' : 'Gravity pull', style: const TextStyle(color: Colors.white30, fontSize: 11)),
                              Text(gravity, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(isRu ? 'Воздушные потоки' : 'Wind forces', style: const TextStyle(color: Colors.white30, fontSize: 11)),
                              Text(wind, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(isRu ? 'Оценочная награда' : 'Est. bounty', style: const TextStyle(color: Colors.white30, fontSize: 11)),
                              Text(bountyRange, style: const TextStyle(color: GameConfig.colorWarning, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              GameAudioManager().playTap();
                              widget.onMapSelected(_previewMapId!);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              foregroundColor: Colors.black,
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 6,
                              shadowColor: themeColor.withOpacity(0.3),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                fontSize: 13,
                              ),
                            ),
                            child: Text(isRu ? 'В ПУТЬ' : 'LAUNCH MISSION'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 6,
                    child: GlassPanel(
                      borderColor: Colors.white10,
                      padding: 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedBuilder(
                          animation: _animController,
                          builder: (context, _) {
                            return CustomPaint(
                              painter: MapPreviewPainter(
                                mapId: _previewMapId!,
                                rocketId: GameState().selectedRocket,
                                animationTime: _animController.value * 2 * pi,
                              ),
                              size: Size.infinite,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBriefingSubCard({
    required String title,
    required Color themeColor,
    String? content,
    Widget? child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: themeColor.withOpacity(0.9),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          content != null
              ? Text(
                  content,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.35,
                  ),
                )
              : (child ?? const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildDiagRow({
    IconData? icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: color.withOpacity(0.7)),
          const SizedBox(width: 5),
        ],
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildRewardRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
