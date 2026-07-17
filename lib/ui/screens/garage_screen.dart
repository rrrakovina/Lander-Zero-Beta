import 'dart:math';
import 'package:flutter/material.dart';
import '../../game/config/game_config.dart';
import '../../game/state/game_state.dart';
import '../widgets/menu_background.dart';
import '../widgets/glass_panel.dart';
import '../painters/rocket_painter.dart';

class GarageWidget extends StatefulWidget {
  final VoidCallback onBack;
  const GarageWidget({super.key, required this.onBack});

  @override
  State<GarageWidget> createState() => _GarageWidgetState();
}

class _GarageWidgetState extends State<GarageWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GameState(),
      builder: (context, child) {
        final state = GameState();
        final isRu = state.language == 'ru';

        return MenuBackground(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Top Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                          onPressed: widget.onBack,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          state.translate('garage'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    // Coins Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: GameConfig.colorWarning.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: GameConfig.colorWarning, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${state.totalCoins}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tab Bar
                TabBar(
                  controller: _tabController,
                  indicatorColor: GameConfig.colorPrimary,
                  labelColor: GameConfig.colorPrimary,
                  unselectedLabelColor: Colors.white38,
                  dividerColor: Colors.white10,
                  tabs: [
                    Tab(text: state.translate('tab_upgrades')),
                    Tab(text: state.translate('tab_cabins')),
                  ],
                ),
                const SizedBox(height: 20),
                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Upgrades View
                      _buildUpgradesTab(state, isRu),
                      // Cabins View
                      _buildCabinsTab(state, isRu),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUpgradesTab(GameState state, bool isRu) {
    return ListView(
      children: [
        _buildUpgradeItem(
          state: state,
          statKey: 'engine',
          title: state.translate('engine'),
          desc: isRu ? 'Увеличивает мощность тяги двигателей.' : 'Increases rocket thruster power.',
          level: state.engineLevel,
          icon: Icons.bolt_rounded,
          color: GameConfig.colorPrimary,
        ),
        const SizedBox(height: 16),
        _buildUpgradeItem(
          state: state,
          statKey: 'fuel',
          title: state.translate('fuel'),
          desc: isRu ? 'Увеличивает объем топливных баков.' : 'Increases fuel tank volume capacity.',
          level: state.fuelLevel,
          icon: Icons.local_gas_station_rounded,
          color: GameConfig.colorWarning,
        ),
        const SizedBox(height: 16),
        _buildUpgradeItem(
          state: state,
          statKey: 'shield',
          title: state.translate('shield'),
          desc: isRu ? 'Увеличивает прочность обшивки модуля.' : 'Increases landing frame impact resistance.',
          level: state.shieldLevel,
          icon: Icons.shield_rounded,
          color: GameConfig.colorDanger,
        ),
      ],
    );
  }

  Widget _buildUpgradeItem({
    required GameState state,
    required String statKey,
    required String title,
    required String desc,
    required int level,
    required IconData icon,
    required Color color,
  }) {
    final bool isMax = level >= 5;
    final int cost = 150 * (1 << (level - 1));
    final bool canAfford = state.canAfford(cost);
    final String costText = isMax ? state.translate('max_level') : '$cost';

    return GlassPanel(
      borderColor: Colors.white10,
      padding: 16,
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          // Info and Progress slots
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${state.translate('level')} $level / 5',
                      style: TextStyle(
                        color: isMax ? GameConfig.colorPrimary : Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(color: Colors.white30, fontSize: 13),
                ),
                const SizedBox(height: 12),
                // Progress slots indicator (5 blocks)
                Row(
                  children: List.generate(5, (index) {
                    final isFilled = index < level;
                    return Expanded(
                      child: Container(
                        height: 10,
                        margin: EdgeInsets.only(right: index == 4 ? 0 : 4),
                        decoration: BoxDecoration(
                          color: isFilled ? color : Colors.white10,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: isFilled
                              ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4, spreadRadius: 1)]
                              : null,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Upgrade Button
          SizedBox(
            width: 150,
            height: 55,
            child: ElevatedButton(
              onPressed: (isMax || !canAfford)
                  ? null
                  : () async {
                      await state.upgradeStat(statKey);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isMax ? Colors.white12 : (canAfford ? color : Colors.white10),
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white10,
                disabledForegroundColor: Colors.white24,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: isMax ? BorderSide.none : BorderSide(color: canAfford ? Colors.transparent : Colors.white10),
                ),
              ),
              child: isMax
                  ? Text(
                      state.translate('max_level'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          state.translate('buy').toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.stars_rounded, color: GameConfig.colorWarning, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              costText,
                              style: TextStyle(
                                color: canAfford ? Colors.black87 : GameConfig.colorDanger,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCabinsTab(GameState state, bool isRu) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: GameState.rocketConfigs.keys.map((rocketId) {
        final config = GameState.rocketConfigs[rocketId]!;
        final bool isOwned = state.ownedRockets.contains(rocketId);
        final bool isSelected = state.selectedRocket == rocketId;
        final int price = config['price'] as int;
        final bool canAfford = state.canAfford(price);

        final double baseThrust = (config['baseThrust'] as double);
        final double baseFuel = (config['baseFuel'] as double);
        final double baseShield = (config['baseShield'] as double);

        Color cabinColor = GameConfig.colorPrimary;
        if (rocketId == 'cyclone') cabinColor = GameConfig.colorWarning;
        if (rocketId == 'needle') cabinColor = const Color(0xFFECEFF1);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: GlassPanel(
              borderColor: isSelected ? cabinColor.withOpacity(0.6) : Colors.white10,
              padding: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Visual Indicator (Large preview frame with floating animation)
                  Expanded(
                    flex: 5,
                    child: CabinPreviewWidget(
                      rocketId: rocketId,
                      cabinColor: cabinColor,
                      isSelected: isSelected,
                      selectedText: state.translate('selected').toUpperCase(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 2. Name & Description
                  Text(
                    isRu ? config['nameRu'] : config['nameEn'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? cabinColor : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 42,
                    child: Text(
                      isRu ? config['descRu'] : config['descEn'],
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.3),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 3. Specs list (vertical layout)
                  Column(
                    children: [
                      _buildVerticalSpec(
                        label: state.translate('engine'),
                        value: baseThrust / 45.0,
                        color: GameConfig.colorPrimary,
                      ),
                      const SizedBox(height: 10),
                      _buildVerticalSpec(
                        label: state.translate('fuel'),
                        value: baseFuel / 200.0,
                        color: GameConfig.colorWarning,
                      ),
                      const SizedBox(height: 10),
                      _buildVerticalSpec(
                        label: state.translate('shield'),
                        value: baseShield / 200.0,
                        color: GameConfig.colorDanger,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 4. Action Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSelected
                          ? null
                          : () async {
                              if (isOwned) {
                                  await state.selectRocket(rocketId);
                              } else {
                                  await state.buyRocket(rocketId);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? Colors.white10
                            : (isOwned
                                ? GameConfig.colorPrimary
                                : (canAfford ? GameConfig.colorWarning : Colors.white10)),
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.white10,
                        disabledForegroundColor: Colors.white24,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isSelected
                          ? Text(
                              state.translate('selected').toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            )
                          : (isOwned
                              ? Text(
                                  state.translate('select').toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      state.translate('buy').toUpperCase(),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.stars_rounded, color: Colors.black87, size: 16),
                                    const SizedBox(width: 2),
                                    Text(
                                      '$price',
                                      style: TextStyle(
                                        color: canAfford ? Colors.black87 : GameConfig.colorDanger,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                )),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVerticalSpec({
    required String label,
    required double value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white30, fontSize: 11)),
            Text('${(value * 100).toInt()}%', style: TextStyle(color: color.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class CabinPreviewWidget extends StatefulWidget {
  final String rocketId;
  final Color cabinColor;
  final bool isSelected;
  final String selectedText;

  const CabinPreviewWidget({
    super.key,
    required this.rocketId,
    required this.cabinColor,
    required this.isSelected,
    required this.selectedText,
  });

  @override
  State<CabinPreviewWidget> createState() => _CabinPreviewWidgetState();
}

class _CabinPreviewWidgetState extends State<CabinPreviewWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Плавное колебание за 3 секунды
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double angle = sin(_controller.value * 2 * pi) * 0.04; // Мягкий крен
        final double hoverOffset = cos(_controller.value * 2 * pi) * 5.0; // Левитация
        
        return Container(
          decoration: BoxDecoration(
            color: widget.cabinColor.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected ? widget.cabinColor.withOpacity(0.5) : widget.cabinColor.withOpacity(0.15),
              width: widget.isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Transform.translate(
                    offset: Offset(0, hoverOffset),
                    child: Transform.rotate(
                      angle: angle,
                      child: CustomPaint(
                        painter: RocketPainter(
                          rocketId: widget.rocketId,
                          animationTime: _controller.value * 2 * pi,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.cabinColor,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: widget.cabinColor.withOpacity(0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      widget.selectedText,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
