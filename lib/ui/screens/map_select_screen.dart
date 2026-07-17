import 'dart:math';
import 'package:flutter/material.dart';
import '../../game/config/game_config.dart';
import '../../game/state/game_state.dart';
import '../widgets/menu_background.dart';
import '../widgets/glass_panel.dart';
import '../painters/map_preview_painter.dart';

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

    return MenuBackground(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: widget.onBack,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMapCard(
                  context: context,
                  mapId: 'echo',
                  name: state.translate('map_echo'),
                  desc: state.translate('map_echo_desc'),
                  difficulty: isRu ? 'Легко' : 'Easy',
                  gravity: '1.0x',
                  wind: isRu ? 'Нет' : 'None',
                  color: const Color(0xFF00E676),
                  icon: Icons.terrain_rounded,
                ),
                const SizedBox(width: 16),
                _buildMapCard(
                  context: context,
                  mapId: 'wind',
                  name: state.translate('map_wind'),
                  desc: state.translate('map_wind_desc'),
                  difficulty: isRu ? 'Средне' : 'Medium',
                  gravity: '1.0x',
                  wind: isRu ? 'Сильный (влево)' : 'Strong (left)',
                  color: GameConfig.colorWarning,
                  icon: Icons.air_rounded,
                ),
                const SizedBox(width: 16),
                _buildMapCard(
                  context: context,
                  mapId: 'core',
                  name: state.translate('map_core'),
                  desc: state.translate('map_core_desc'),
                  difficulty: isRu ? 'Сложно' : 'Hard',
                  gravity: '1.5x',
                  wind: isRu ? 'Нет' : 'None',
                  color: GameConfig.colorDanger,
                  icon: Icons.south_rounded,
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCard({
    required BuildContext context,
    required String mapId,
    required String name,
    required String desc,
    required String difficulty,
    required String gravity,
    required String wind,
    required Color color,
    required IconData icon,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _previewMapId = mapId;
          });
        },
        borderRadius: BorderRadius.circular(16),
        hoverColor: color.withOpacity(0.05),
        splashColor: color.withOpacity(0.1),
        child: Container(
          width: 245,
          height: 370,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
            color: const Color(0xFF16161E).withOpacity(0.9),
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  difficulty.toUpperCase(),
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                desc,
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
              ),
              const Spacer(),
              const Divider(color: Colors.white10),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Gravity', style: TextStyle(color: Colors.white30, fontSize: 13)),
                  Text(gravity, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Wind force', style: TextStyle(color: Colors.white30, fontSize: 13)),
                  Text(wind, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              Center(
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: color.withOpacity(0.6),
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapPreviewScreen(GameState state, bool isRu) {
    String name = '';
    String difficulty = '';
    String gravity = '';
    String wind = '';
    Color themeColor = GameConfig.colorPrimary;
    IconData icon = Icons.terrain_rounded;
    String missionStory = '';
    String missionObjective = '';

    if (_previewMapId == 'echo') {
      name = state.translate('map_echo');
      difficulty = isRu ? 'Легко' : 'Easy';
      gravity = '1.0x (Normal)';
      wind = isRu ? 'Нет' : 'None';
      themeColor = const Color(0xFF00E676);
      icon = Icons.terrain_rounded;
      missionStory = isRu
          ? 'Каньон Эхо — заброшенная научная шахта на окраине обитаемой зоны. Радар зафиксировал здесь аварийный сигнал с грузового контейнера. Разведка сообщает о стабильной атмосфере и слабом магнитном полем. Идеальная стартовая миссия для отработки навыков маневрирования.'
          : 'Echo Canyon is an abandoned research shaft on the edge of the habitable zone. Radar detected an emergency signal from a cargo container. Intel reports a stable atmosphere and weak magnetic fields. The perfect starter mission to hone your piloting skills.';
      missionObjective = isRu
          ? 'Спуститься в каньон, прицепить контейнер с ценными материалами с помощью автоматического троса и осторожно доставить его на выходную платформу в правой части пещеры.'
          : 'Descend into the canyon, dock with the valuable material container using the automated tether, and carefully transport it to the exit platform on the far right.';
    } else if (_previewMapId == 'wind') {
      name = state.translate('map_wind');
      difficulty = isRu ? 'Средне' : 'Medium';
      gravity = '1.0x (Normal)';
      wind = isRu ? 'Сильный космический ветер (влево)' : 'Strong solar wind (left)';
      themeColor = GameConfig.colorWarning;
      icon = Icons.air_rounded;
      missionStory = isRu
          ? 'Эта расселина выходит прямо к открытому космосу и подвергается постоянным выбросам ионизированной плазмы. Мощнейший боковой солнечный ветер непрерывно сдувает любой пролетающий корабль влево. Будьте предельно осторожны при удержании курса!'
          : 'This crevice is exposed directly to deep space and experiences constant bursts of ionized plasma. A powerful solar wind continuously blows any passing vessel to the left. Exercise extreme caution to hold your course!';
      missionObjective = isRu
          ? 'Оказать сопротивление боковому сносу, найти контейнер в глубине пещеры и эвакуировать его. Потребуется постоянная компенсация траектории правым двигателем.'
          : 'Combat the strong lateral wind, locate the container deep inside, and evacuate it. Requires constant trajectory correction using your right thruster.';
    } else if (_previewMapId == 'core') {
      name = state.translate('map_core');
      difficulty = isRu ? 'Сложно' : 'Hard';
      gravity = '1.5x (Heavy Core)';
      wind = isRu ? 'Нет' : 'None';
      themeColor = GameConfig.colorDanger;
      icon = Icons.south_rounded;
      missionStory = isRu
          ? 'Сверхглубокая гравитационная аномалия. Сила тяжести здесь повышена на 50%, что создает колоссальную нагрузку на двигатели. Любое резкое падение приведет к моментальному взрыву кабины. Запасы топлива ограничены, а расход увеличен из-за постоянной работы двигателей.'
          : 'An ultra-deep gravitational anomaly. Gravity is 50% stronger here, putting colossal load on your thrusters. Any sudden drop will trigger an immediate hull breach. Fuel is highly limited, and consumption is accelerated due to constant burns.';
      missionObjective = isRu
          ? 'Совершить ювелирный спуск в ядро планеты. Подхватить контейнер и вытащить его наверх, борясь с экстремальным притяжением. Каждое столкновение наносит критический урон!'
          : 'Execute a pinpoint landing into the planet\'s core. Hook the cargo and lift it back up, fighting the extreme pull. Every impact deals critical structural damage!';
    }

    String statusBadge = '';
    Color statusBadgeColor = Colors.green;
    String recCabin = '';
    String hazards = '';
    String estimatedBounty = '';

    if (_previewMapId == 'echo') {
      statusBadge = isRu ? 'СВЯЗЬ: СТАБИЛЬНАЯ' : 'COMM STATUS: ACTIVE';
      statusBadgeColor = const Color(0xFF00E676);
      recCabin = isRu ? 'Спутник-1 (рекомендуется)' : 'Sputnik-1 (recommended)';
      hazards = isRu ? 'Аномалии отсутствуют' : 'None detected';
      estimatedBounty = isRu ? '100 - 300 монет' : '100 - 300 coins';
    } else if (_previewMapId == 'wind') {
      statusBadge = isRu ? 'СВЯЗЬ: ПОМЕХИ В КАНАЛЕ' : 'COMM STATUS: DEGRADED';
      statusBadgeColor = GameConfig.colorWarning;
      recCabin = isRu ? 'Игла (рекомендуется)' : 'Needle (recommended)';
      hazards = isRu ? 'Сильные порывы ветра влево' : 'Strong solar wind gusts left';
      estimatedBounty = isRu ? '300 - 600 монет' : '300 - 600 coins';
    } else if (_previewMapId == 'core') {
      statusBadge = isRu ? 'СВЯЗЬ: ДЕСТАБИЛИЗИРОВАНА' : 'COMM STATUS: CRITICAL';
      statusBadgeColor = GameConfig.colorDanger;
      recCabin = isRu ? 'Ураган (рекомендуется)' : 'Cyclone (recommended)';
      hazards = isRu ? 'Тяжелое ядро, высокий урон' : 'High gravity core, high impacts';
      estimatedBounty = isRu ? '600+ монет' : '600+ coins';
    }

    // Считываем личный рекорд
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
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: GlassPanel(
                      borderColor: themeColor.withOpacity(0.3),
                      padding: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Header (Location Title)
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: themeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(icon, color: themeColor, size: 24),
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
                          // Sub-header (Difficulty Tag + Comm Status Badge)
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
                          const SizedBox(height: 16),
                          // 2. Scrollable Body
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Story Card
                                  _buildBriefingSubCard(
                                    title: isRu ? 'СВОДКА МИССИИ' : 'MISSION BRIEFING',
                                    themeColor: themeColor,
                                    content: missionStory,
                                  ),
                                  const SizedBox(height: 12),
                                  // Objective Card
                                  _buildBriefingSubCard(
                                    title: isRu ? 'ОСНОВНАЯ ЗАДАЧА' : 'PRIMARY OBJECTIVE',
                                    themeColor: themeColor,
                                    content: missionObjective,
                                  ),
                                  const SizedBox(height: 12),
                                  // Diagnostics Card
                                  _buildBriefingSubCard(
                                    title: isRu ? 'ТАКТИЧЕСКИЙ АНАЛИЗ' : 'CAVERN DIAGNOSTICS',
                                    themeColor: themeColor,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildDiagRow(
                                          label: isRu ? 'Реком. кабина:' : 'Rec. module:',
                                          value: recCabin,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(height: 6),
                                        _buildDiagRow(
                                          label: isRu ? 'Опасности:' : 'Hazards:',
                                          value: hazards,
                                          color: statusBadgeColor,
                                        ),
                                        const SizedBox(height: 6),
                                        _buildDiagRow(
                                          label: isRu ? 'Награда:' : 'Est. bounty:',
                                          value: estimatedBounty,
                                          color: GameConfig.colorWarning,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Record Card
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
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 8),
                          // 3. Pinned Bottom Metrics
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(isRu ? 'Сила гравитации' : 'Gravity pull', style: const TextStyle(color: Colors.white30, fontSize: 11)),
                              Text(gravity, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(isRu ? 'Воздушные потоки' : 'Wind forces', style: const TextStyle(color: Colors.white30, fontSize: 11)),
                              Text(wind, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // 4. Launch Button
                          ElevatedButton(
                            onPressed: () => widget.onMapSelected(_previewMapId!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              foregroundColor: Colors.black,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
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
                  const SizedBox(width: 24),
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
              color: themeColor.withOpacity(0.8),
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
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white30, fontSize: 10),
        ),
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
}
