import 'dart:math';
import 'package:flutter/material.dart';
import '../../game/config/game_config.dart';
import '../../game/state/game_state.dart';
import '../../game/state/save_security_manager.dart';
import '../../game/audio/game_audio_manager.dart';
import '../widgets/menu_background.dart';
import '../widgets/glass_panel.dart';
import '../painters/rocket_painter.dart';

/// Flight Cadet ID Terminal with retro-futuristic badge layout,
/// animated laser scanline, callsign sanitization, and starter ship selector.
class NickEntryWidget extends StatefulWidget {
  final VoidCallback onFinished;
  const NickEntryWidget({super.key, required this.onFinished});

  @override
  State<NickEntryWidget> createState() => _NickEntryWidgetState();
}

class _NickEntryWidgetState extends State<NickEntryWidget> with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  String _error = '';
  String _selectedStarter = 'sputnik';
  late final AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    final state = GameState();
    if (state.selectedRocket.isNotEmpty && (state.selectedRocket == 'sputnik' || state.selectedRocket == 'swift')) {
      _selectedStarter = state.selectedRocket;
    }
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _scanController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _submit() async {
    final rawText = _controller.text;
    if (rawText.trim().isEmpty) {
      setState(() {
        _error = GameState().translate('error_empty_nick');
      });
      return;
    }
    final sanitizedName = SaveSecurityManager.sanitizeNickname(rawText);
    final state = GameState();
    await state.setNickname(sanitizedName);
    await state.selectRocket(_selectedStarter);
    GameAudioManager().playSfx('dock.wav');
    widget.onFinished();
  }

  void _toggleLanguage() async {
    final state = GameState();
    final newLang = state.language == 'ru' ? 'en' : 'ru';
    await state.setLanguage(newLang);
    setState(() {
      _error = '';
    });
    GameAudioManager().playSfx('coin.wav');
  }

  String _generateCadetBadgeId(String name) {
    final raw = name.isEmpty ? 'CADET' : name;
    final hash = (raw.codeUnits.fold(0, (a, b) => a + b) * 37 + 101) % 900 + 100;
    return 'CADET-ID #$hash-LZ';
  }

  @override
  Widget build(BuildContext context) {
    final state = GameState();
    final isRu = state.language == 'ru';
    final badgeId = _generateCadetBadgeId(_controller.text);

    return MenuBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Terminal Title & Lang
              Container(
                width: 580,
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: GameConfig.colorPrimary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: GameConfig.colorPrimary.withOpacity(0.5)),
                          ),
                          child: const Icon(Icons.terminal_rounded, color: GameConfig.colorPrimary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isRu ? 'ТЕРМИНАЛ РЕГИСТРАЦИИ КАДЕТА' : 'FLIGHT CADET TERMINAL',
                              style: const TextStyle(
                                color: GameConfig.colorPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                              ),
                            ),
                            Text(
                              isRu ? 'СПАСАТЕЛЬНЫЙ ДИВИЗИОН // LZ-2026' : 'RESCUE DIVISION // LZ-2026',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: _toggleLanguage,
                      icon: const Icon(Icons.language, size: 16),
                      label: Text(
                        isRu ? 'EN' : 'RU',
                        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GameConfig.colorPrimary,
                        side: BorderSide(color: GameConfig.colorPrimary.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ],
                ),
              ),

              // Main ID Badge Card
              Stack(
                children: [
                  GlassPanel(
                    borderColor: GameConfig.colorPrimary.withOpacity(0.4),
                    borderRadius: 16,
                    padding: 24,
                    child: SizedBox(
                      width: 580,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badge Header Info
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Pilot Photo / Insignia Box
                              Container(
                                width: 90,
                                height: 110,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: GameConfig.colorPrimary.withOpacity(0.6), width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: GameConfig.colorPrimary.withOpacity(0.15),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_rounded,
                                      size: 56,
                                      color: GameConfig.colorPrimary.withOpacity(0.8),
                                    ),
                                    Positioned(
                                      bottom: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: GameConfig.colorPrimary.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isRu ? 'ФОТО' : 'PHOTO',
                                          style: const TextStyle(
                                            color: GameConfig.colorPrimary,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 18),
                              // Cadet Credentials
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          badgeId,
                                          style: const TextStyle(
                                            color: GameConfig.colorPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00E676).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: const Color(0xFF00E676).withOpacity(0.5)),
                                          ),
                                          child: Text(
                                            isRu ? 'ДОПУСК: КЛАСС-1' : 'CLEARANCE: LVL-1',
                                            style: const TextStyle(
                                              color: Color(0xFF00E676),
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      isRu ? 'ОРБИТАЛЬНАЯ СПАСАТЕЛЬНАЯ СЛУЖБА' : 'UNITED COSMIC RESCUE SERVICE',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      isRu ? 'ПОЗЫВНОЙ ПИЛОТА / CALLSIGN:' : 'PILOT CALLSIGN / DESIGNATION:',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: _controller,
                                      maxLength: 15,
                                      cursorColor: GameConfig.colorPrimary,
                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                      decoration: InputDecoration(
                                        hintText: isRu ? 'Кадет' : 'Cadet',
                                        hintStyle: const TextStyle(color: Colors.white24),
                                        counterStyle: const TextStyle(color: Colors.white30, fontSize: 10),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        fillColor: Colors.black54,
                                        filled: true,
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(color: GameConfig.colorPrimary, width: 1.8),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(color: Colors.white24),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onChanged: (_) {
                                        setState(() {
                                          if (_error.isNotEmpty) _error = '';
                                        });
                                      },
                                      onSubmitted: (_) => _submit(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          if (_error.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              _error,
                              style: const TextStyle(color: GameConfig.colorDanger, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],

                          const SizedBox(height: 16),
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 12),

                          // Starter Ship Selector Section
                          Text(
                            isRu ? 'ВЫБЕРИТЕ СТАРТОВЫЙ КОРАБЛЬ (0 МОНЕТ):' : 'SELECT STARTER VESSEL (0 COINS):',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStarterShipCard(
                                  shipId: 'sputnik',
                                  name: isRu ? 'Спутник-1' : 'Sputnik-1',
                                  subname: 'СССР-01',
                                  desc: isRu ? 'Сбалансированная тяга и щиты' : 'Balanced thrust & shield',
                                  accentColor: GameConfig.colorPrimary,
                                  isRu: isRu,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildStarterShipCard(
                                  shipId: 'swift',
                                  name: isRu ? 'Стриж' : 'Swift-02',
                                  subname: 'SWIFT-02',
                                  desc: isRu ? 'Высокая скорость, легкий корпус' : 'High agility, light hull',
                                  accentColor: const Color(0xFF00E5FF),
                                  isRu: isRu,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Submit Action Button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _submit,
                              borderRadius: BorderRadius.circular(10),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      GameConfig.colorPrimary,
                                      Color(0xFF00B0FF),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: GameConfig.colorPrimary.withOpacity(0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  height: 52,
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.verified_user_rounded, color: Colors.black, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        (isRu ? 'ПОДТВЕРДИТЬ РЕГИСТРАЦИЮ' : 'INITIALIZE FLIGHT CLEARANCE').toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                          fontSize: 14,
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
                    ),
                  ),

                  // Animated Laser Scanline Effect
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _scanController,
                        builder: (context, _) {
                          final double scanY = _scanController.value;
                          return CustomPaint(
                            painter: LaserScanlinePainter(scanProgress: scanY),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStarterShipCard({
    required String shipId,
    required String name,
    required String subname,
    required String desc,
    required Color accentColor,
    required bool isRu,
  }) {
    final isSelected = _selectedStarter == shipId;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedStarter = shipId;
          });
          GameAudioManager().playSfx('dock.wav');
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? accentColor.withOpacity(0.12) : Colors.black45,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? accentColor : Colors.white24,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.25),
                      blurRadius: 12,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CustomPaint(
                  painter: RocketPainter(
                    rocketId: shipId,
                    animationTime: 0.0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded, color: accentColor, size: 16),
                      ],
                    ),
                    Text(
                      subname,
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// CustomPainter rendering a futuristic laser scanline across the cadet badge.
class LaserScanlinePainter extends CustomPainter {
  final double scanProgress;
  LaserScanlinePainter({required this.scanProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final double y = scanProgress * size.height;

    // Laser beam trail gradient
    final Rect trailRect = Rect.fromLTWH(0, max(0, y - 24), size.width, 24);
    final trailPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          GameConfig.colorPrimary.withOpacity(0.12),
        ],
      ).createShader(trailRect);
    canvas.drawRect(trailRect, trailPaint);

    // Glowing laser horizontal beam
    final beamGlowPaint = Paint()
      ..color = GameConfig.colorPrimary.withOpacity(0.5)
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawLine(Offset(0, y), Offset(size.width, y), beamGlowPaint);

    final beamCorePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), beamCorePaint);
  }

  @override
  bool shouldRepaint(covariant LaserScanlinePainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress;
  }
}
