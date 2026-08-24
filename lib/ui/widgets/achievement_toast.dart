import 'dart:async';
import 'package:flutter/material.dart';
import '../../game/config/game_config.dart';
import '../../game/state/achievements_manager.dart';
import '../../game/state/game_state.dart';

class AchievementToastOverlay extends StatefulWidget {
  final Widget child;

  const AchievementToastOverlay({super.key, required this.child});

  @override
  State<AchievementToastOverlay> createState() => _AchievementToastOverlayState();
}

class _AchievementToastOverlayState extends State<AchievementToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Achievement? _currentAchievement;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    AchievementsManager().newlyUnlocked.addListener(_onNewAchievement);
  }

  @override
  void dispose() {
    AchievementsManager().newlyUnlocked.removeListener(_onNewAchievement);
    _dismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _onNewAchievement() {
    final ach = AchievementsManager().newlyUnlocked.value;
    if (ach != null && mounted) {
      _dismissTimer?.cancel();
      setState(() {
        _currentAchievement = ach;
      });
      _animController.forward();

      _dismissTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          _animController.reverse().then((_) {
            if (mounted) {
              setState(() {
                _currentAchievement = null;
              });
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = GameState();
    final lang = state.language;

    return Stack(
      children: [
        widget.child,
        if (_currentAchievement != null)
          Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: Center(
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: const BoxConstraints(maxWidth: 420),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: GameConfig.colorWarning,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: GameConfig.colorWarning.withOpacity(0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: GameConfig.colorWarning.withOpacity(0.2),
                            border: Border.all(color: GameConfig.colorWarning),
                          ),
                          child: Icon(
                            _currentAchievement!.icon,
                            color: GameConfig.colorWarning,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                lang == 'ru' ? '🏆 ДОСТИЖЕНИЕ РАЗБЛОКИРОВАНО!' : '🏆 ACHIEVEMENT UNLOCKED!',
                                style: const TextStyle(
                                  color: GameConfig.colorWarning,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _currentAchievement!.getTitle(lang),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _currentAchievement!.getDesc(lang),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 11,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: GameConfig.colorPrimary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: GameConfig.colorPrimary.withOpacity(0.6)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.stars_rounded, color: GameConfig.colorWarning, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '+${_currentAchievement!.starReward}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
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
    );
  }
}
