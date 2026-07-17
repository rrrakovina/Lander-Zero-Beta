import 'package:flutter/material.dart';
import '../../game/config/game_config.dart';
import '../painters/cyber_grid_painter.dart';

class MenuBackground extends StatelessWidget {
  final Widget child;

  const MenuBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameConfig.colorBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Color(0xFF1B1B2A),
              Color(0xFF0F0F13),
            ],
            center: Alignment.center,
            radius: 1.2,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.08,
                child: CustomPaint(
                  painter: CyberGridPainter(),
                ),
              ),
            ),
            SafeArea(
              child: SizedBox.expand(
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
