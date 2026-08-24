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
            width: 154,
            height: 54,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: isMax
                  ? Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2430),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12, width: 1),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified_rounded, color: GameConfig.colorPrimary, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            state.translate('max_level'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  : canAfford
                      ? Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color, color.withOpacity(0.85)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.45),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () async {
                              await state.upgradeStat(statKey);
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  state.translate('buy').toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF0F0F13),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.stars_rounded, color: Color(0xFF1E1E1E), size: 15),
                                    const SizedBox(width: 4),
                                    Text(
                                      costText,
                                      style: const TextStyle(
                                        color: Color(0xFF0F0F13),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF161B26),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFFF5252).withOpacity(0.65),
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33FF5252),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                state.translate('buy').toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFFF1F5F9),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 15),
                                  const SizedBox(width: 4),
                                  Text(
                                    costText,
                                    style: const TextStyle(
                                      color: Color(0xFFFF5252),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
                  const SizedBox(height: 16),
                  // 4. Action Button
                  SizedBox(
                    height: 48,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: isSelected
                          ? Container(
                              decoration: BoxDecoration(
                                color: cabinColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: cabinColor.withOpacity(0.6),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: cabinColor.withOpacity(0.15),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded, color: cabinColor, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    state.translate('selected').toUpperCase(),
                                    style: TextStyle(
                                      color: cabinColor,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : isOwned
                              ? Ink(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [GameConfig.colorPrimary, Color(0xFF00B0FF)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: GameConfig.colorPrimary.withOpacity(0.45),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () async {
                                      await state.selectRocket(rocketId);
                                    },
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.rocket_launch_rounded, color: Color(0xFF0F0F13), size: 16),
                                          const SizedBox(width: 6),
                                          Text(
                                            state.translate('select').toUpperCase(),
                                            style: const TextStyle(
                                              color: Color(0xFF0F0F13),
                                              fontWeight: FontWeight.w900,
                                              fontSize: 13,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : canAfford
                                  ? Ink(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFFFFE082), width: 1.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFFB300).withOpacity(0.45),
                                            blurRadius: 12,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () async {
                                          await state.buyRocket(rocketId);
                                        },
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                state.translate('buy').toUpperCase(),
                                                style: const TextStyle(
                                                  color: Color(0xFF0F0F13),
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 13,
                                                  letterSpacing: 1.1,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.stars_rounded,
                                                color: Color(0xFF1E1E1E),
                                                size: 18,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$price',
                                                style: const TextStyle(
                                                  color: Color(0xFF0F0F13),
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF181F2A),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(0xFFFF5252).withOpacity(0.65),
                                          width: 1.5,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x33FF5252),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            state.translate('buy').toUpperCase(),
                                            style: const TextStyle(
                                              color: Color(0xFFF1F5F9),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.stars_rounded,
                                            color: Color(0xFFFFD700),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$price',
                                            style: const TextStyle(
                                              color: Color(0xFFFF5252),
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
      duration: const Duration(seconds: 3),
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
        final double angle = sin(_controller.value * 2 * pi) * 0.035;
        final double hoverOffset = cos(_controller.value * 2 * pi) * 3.5;

        return Container(
          decoration: BoxDecoration(
            color: widget.cabinColor.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected ? widget.cabinColor.withOpacity(0.6) : widget.cabinColor.withOpacity(0.18),
              width: widget.isSelected ? 2.0 : 1.0,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.cabinColor.withOpacity(0.15),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                    child: Transform.translate(
                      offset: Offset(0, hoverOffset),
                      child: Transform.rotate(
                        angle: angle,
                        child: CustomPaint(
                          painter: RocketPainter(
                            rocketId: widget.rocketId,
                            animationTime: _controller.value * 2 * pi,
                            glowColor: widget.isSelected ? widget.cabinColor : null,
                            isSelected: widget.isSelected,
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
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: widget.cabinColor.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 12, color: Colors.black),
                          const SizedBox(width: 4),
                          Text(
                            widget.selectedText,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
