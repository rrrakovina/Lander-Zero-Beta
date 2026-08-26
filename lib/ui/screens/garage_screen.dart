import 'dart:math';
import 'package:flutter/material.dart';
import '../../game/config/game_config.dart';
import '../../game/state/game_state.dart';
import '../widgets/menu_background.dart';
import '../widgets/glass_panel.dart';
import '../painters/rocket_painter.dart';
import '../painters/ship_mesh_renderer.dart';
import '../painters/wardrobe_icon_painter.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
                    Tab(text: state.translate('tab_pilot')),
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
                      // Pilot Wardrobe View
                      _buildPilotTab(state, isRu),
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
        if (rocketId == 'swift') cabinColor = const Color(0xFF00E5FF);
        if (rocketId == 'cyclone') cabinColor = GameConfig.colorWarning;
        if (rocketId == 'needle') cabinColor = const Color(0xFFECEFF1);
        if (rocketId == 'titan') cabinColor = const Color(0xFFFF9100);

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
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
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
                                ),
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
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
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
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
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
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
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
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white30, fontSize: 11)),
              const SizedBox(width: 6),
              Text('${(value * 100).toInt()}%', style: TextStyle(color: color.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
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

  // =========================================================================
  // Pilot Wardrobe Customization Tab
  // =========================================================================
  Widget _buildPilotTab(GameState state, bool isRu) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24.0),
      children: [
        // 1. Live Astronaut Wardrobe Preview Card
        _buildPilotPreviewCard(state, isRu),
        const SizedBox(height: 20),

        // 2. Suit Color Palette Section (100% Free)
        _buildSectionHeader(
          title: state.translate('suit_color'),
          badgeText: state.translate('free_color'),
          badgeColor: const Color(0xFF00E676),
          icon: Icons.palette_rounded,
        ),
        const SizedBox(height: 12),
        _buildSuitColorPalette(state, isRu),
        const SizedBox(height: 24),

        // 3. Helmet Type Selection Section
        _buildSectionHeader(
          title: state.translate('helmet_type'),
          icon: Icons.sports_motorsports_rounded,
        ),
        const SizedBox(height: 12),
        _buildHelmetGrid(state, isRu),
        const SizedBox(height: 24),

        // 4. Suit Model / Decals Section
        _buildSectionHeader(
          title: state.translate('suit_model'),
          icon: Icons.accessibility_new_rounded,
        ),
        const SizedBox(height: 12),
        _buildSuitModelGrid(state, isRu),
      ],
    );
  }

  Widget _buildPilotPreviewCard(GameState state, bool isRu) {
    final callsign = state.nickname.isEmpty ? (isRu ? 'КУРСАНТ-01' : 'CADET-01') : state.nickname;
    final colorName = state.translate('color_${state.suitColor}');
    final helmetName = state.translate('helmet_${state.selectedHelmet}');
    final suitName = state.translate('suit_${state.selectedSuit}');

    return GlassPanel(
      borderColor: GameConfig.colorPrimary.withOpacity(0.35),
      padding: 16,
      child: Row(
        children: [
          // Large Astronaut Dynamic Bust Viewport
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: GameConfig.colorPrimary.withOpacity(0.45),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: GameConfig.colorPrimary.withOpacity(0.15),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AstronautPreviewWidget(
                suitColor: state.suitColor,
                helmetType: state.selectedHelmet,
                suitModel: state.selectedSuit,
              ),
            ),
          ),
          const SizedBox(width: 18),
          // Callsign & Wardrobe Telemetry Badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Callsign Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: GameConfig.colorPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: GameConfig.colorPrimary.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.badge_rounded, color: GameConfig.colorPrimary, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        callsign.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _buildTelemetryBadge(Icons.palette_rounded, colorName, Colors.cyanAccent),
                const SizedBox(height: 6),
                _buildTelemetryBadge(Icons.sports_motorsports_rounded, helmetName, Colors.amberAccent),
                const SizedBox(height: 6),
                _buildTelemetryBadge(Icons.accessibility_new_rounded, suitName, Colors.lightGreenAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryBadge(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    String? badgeText,
    Color? badgeColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: GameConfig.colorPrimary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        if (badgeText != null) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (badgeColor ?? GameConfig.colorPrimary).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: (badgeColor ?? GameConfig.colorPrimary).withOpacity(0.8)),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: badgeColor ?? GameConfig.colorPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSuitColorPalette(GameState state, bool isRu) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: GameState.suitColors.map((colorItem) {
        final id = colorItem['id'] as String;
        final name = state.translate(colorItem['nameKey'] as String);
        final color = colorItem['color'] as Color;
        final accent = colorItem['accent'] as Color;
        final isSelected = state.suitColor == id;

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            await state.setSuitColor(id);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.22) : Colors.black38,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? color : Colors.white12,
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: accent, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 13, color: Colors.black)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHelmetGrid(GameState state, bool isRu) {
    const helmetKeys = ['sphere1', 'cyber_visor', 'miner_helmet', 'swift_aero'];
    return Column(
      children: helmetKeys.map((id) {
        final price = (GameState.helmetConfigs[id]?['price'] as int?) ?? 0;
        final title = state.translate('helmet_$id');
        final desc = state.translate('helmet_${id}_desc');
        final isOwned = state.ownedHelmets.contains(id);
        final isSelected = state.selectedHelmet == id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: _buildWardrobeCard(
            state: state,
            id: id,
            isHelmet: true,
            title: title,
            desc: desc,
            price: price,
            isOwned: isOwned,
            isSelected: isSelected,
            accentColor: Colors.amberAccent,
            onSelect: () async {
              await state.selectHelmet(id);
            },
            onBuy: () async {
              await state.buyHelmet(id, price);
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSuitModelGrid(GameState state, bool isRu) {
    const suitKeys = ['sk1_cadet', 'exo_frame', 'cryo_suit'];
    return Column(
      children: suitKeys.map((id) {
        final price = (GameState.suitConfigs[id]?['price'] as int?) ?? 0;
        final title = state.translate('suit_$id');
        final desc = state.translate('suit_${id}_desc');
        final isOwned = state.ownedSuits.contains(id);
        final isSelected = state.selectedSuit == id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: _buildWardrobeCard(
            state: state,
            id: id,
            isHelmet: false,
            title: title,
            desc: desc,
            price: price,
            isOwned: isOwned,
            isSelected: isSelected,
            accentColor: Colors.lightGreenAccent,
            onSelect: () async {
              await state.selectSuit(id);
            },
            onBuy: () async {
              await state.buySuit(id, price);
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWardrobeCard({
    required GameState state,
    required String id,
    required bool isHelmet,
    required String title,
    required String desc,
    required int price,
    required bool isOwned,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onSelect,
    required VoidCallback onBuy,
  }) {
    final bool canAfford = state.canAfford(price);

    return GlassPanel(
      borderColor: isSelected ? accentColor.withOpacity(0.6) : Colors.white10,
      padding: 14,
      child: Row(
        children: [
          // Monochrome Vector Model Icon Box
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected ? accentColor.withOpacity(0.18) : const Color(0xFF141920),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? accentColor : Colors.white12,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            alignment: Alignment.center,
            child: WardrobeIconWidget(
              id: id,
              type: isHelmet ? WardrobeItemType.helmet : WardrobeItemType.suit,
              isSelected: isSelected,
              accentColor: accentColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Action Button
          SizedBox(
            width: 128,
            height: 44,
            child: isSelected
                ? Container(
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accentColor),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, color: accentColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          state.translate('equipped'),
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                : isOwned
                    ? OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Colors.white24),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: onSelect,
                        child: Text(
                          state.translate('equip'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      )
                    : canAfford
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GameConfig.colorWarning,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: onBuy,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.stars_rounded, color: Colors.black, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$price ${state.translate('buy')}',
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF161B26),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFF5252).withOpacity(0.6)),
                            ),
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.lock_rounded, color: Color(0xFFFF5252), size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$price 🪙',
                                      style: const TextStyle(
                                        color: Color(0xFFFF5252),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
          ),
        ],
      ),
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

class AstronautPreviewWidget extends StatefulWidget {
  final String suitColor;
  final String helmetType;
  final String suitModel;

  const AstronautPreviewWidget({
    super.key,
    required this.suitColor,
    required this.helmetType,
    required this.suitModel,
  });

  @override
  State<AstronautPreviewWidget> createState() => _AstronautPreviewWidgetState();
}

class _AstronautPreviewWidgetState extends State<AstronautPreviewWidget> with SingleTickerProviderStateMixin {
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
        return CustomPaint(
          size: Size.infinite,
          painter: _AstronautPreviewPainter(
            suitColor: widget.suitColor,
            helmetType: widget.helmetType,
            suitModel: widget.suitModel,
            animationTime: _controller.value * 2 * pi,
          ),
        );
      },
    );
  }
}

class _AstronautPreviewPainter extends CustomPainter {
  final String suitColor;
  final String helmetType;
  final String suitModel;
  final double animationTime;

  _AstronautPreviewPainter({
    required this.suitColor,
    required this.helmetType,
    required this.suitModel,
    this.animationTime = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    ShipMeshRenderer.renderPilotPreview(
      canvas: canvas,
      size: size,
      suitColor: suitColor,
      helmetType: helmetType,
      suitModel: suitModel,
      animationTime: animationTime,
    );
  }

  @override
  bool shouldRepaint(covariant _AstronautPreviewPainter oldDelegate) {
    return oldDelegate.suitColor != suitColor ||
        oldDelegate.helmetType != helmetType ||
        oldDelegate.suitModel != suitModel ||
        oldDelegate.animationTime != animationTime;
  }
}
