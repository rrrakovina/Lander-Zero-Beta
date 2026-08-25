import 'dart:math';
import 'package:flutter/material.dart';
import '../../game/config/game_config.dart';
import '../painters/cyber_grid_painter.dart';

class MenuBackground extends StatefulWidget {
  final Widget child;
  final bool showSteam;

  const MenuBackground({
    super.key,
    required this.child,
    this.showSteam = true,
  });

  @override
  State<MenuBackground> createState() => _MenuBackgroundState();
}

class _MenuBackgroundState extends State<MenuBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  final List<SteamParticle> _particles = [];
  final Random _random = Random(777);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Initialize steam particles
    for (int i = 0; i < 35; i++) {
      _particles.add(SteamParticle.random(_random));
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameConfig.colorBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Color(0xFF1E1F30),
              Color(0xFF0D0E14),
            ],
            center: Alignment.center,
            radius: 1.25,
          ),
        ),
        child: Stack(
          children: [
            // 1. Multi-layer Cosmic Parallax Starfield & Nebulae
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: CosmicParallaxPainter(
                      time: _animController.value * 2 * pi,
                    ),
                  );
                },
              ),
            ),

            // 2. Cyber Grid Layer
            Positioned.fill(
              child: Opacity(
                opacity: 0.07,
                child: CustomPaint(
                  painter: CyberGridPainter(),
                ),
              ),
            ),

            // 3. Docking Bay Steam / Vapor Emitters
            if (widget.showSteam)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _animController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: DockingSteamPainter(
                          particles: _particles,
                          animValue: _animController.value,
                        ),
                      );
                    },
                  ),
                ),
              ),

            // 4. Foreground Content
            SafeArea(
              child: SizedBox.expand(
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SteamParticle {
  double x; // 0.0 to 1.0
  double y; // 0.0 to 1.0
  double size;
  double speedY;
  double driftX;
  double opacity;
  double phase;

  SteamParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedY,
    required this.driftX,
    required this.opacity,
    required this.phase,
  });

  factory SteamParticle.random(Random r) {
    return SteamParticle(
      x: r.nextDouble(),
      y: 0.5 + r.nextDouble() * 0.5,
      size: 16.0 + r.nextDouble() * 28.0,
      speedY: 0.03 + r.nextDouble() * 0.05,
      driftX: (r.nextDouble() - 0.5) * 0.02,
      opacity: 0.08 + r.nextDouble() * 0.12,
      phase: r.nextDouble() * 2 * pi,
    );
  }

  void update(double dt) {
    y -= speedY * dt;
    x += driftX * dt;
    if (y < 0.2) {
      y = 1.0 + Random().nextDouble() * 0.1;
      x = Random().nextDouble();
    }
  }
}

class DockingSteamPainter extends CustomPainter {
  final List<SteamParticle> particles;
  final double animValue;

  DockingSteamPainter({required this.particles, required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      p.update(0.016);
      final px = (p.x * size.width) % size.width;
      final py = p.y * size.height;
      final currentSize = p.size * (1.0 + (1.0 - p.y) * 0.8);
      final currentOpacity = (p.opacity * (p.y - 0.2) * (sin(animValue * 2 * pi + p.phase).abs() * 0.4 + 0.6))
          .clamp(0.0, 0.25);

      paint.color = const Color(0xFF00E5FF).withOpacity(currentOpacity);
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, currentSize * 0.4);

      canvas.drawCircle(Offset(px, py), currentSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DockingSteamPainter oldDelegate) => true;
}

class CosmicParallaxPainter extends CustomPainter {
  final double time;

  CosmicParallaxPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final rand = Random(42);
    final starPaint = Paint()..style = PaintingStyle.fill;

    // Distant Stars Layer (slow drift)
    for (int i = 0; i < 40; i++) {
      final baseDx = rand.nextDouble() * size.width;
      final baseDy = rand.nextDouble() * size.height;
      final starSize = 0.8 + rand.nextDouble() * 1.5;
      final twinkle = 0.3 + 0.7 * sin(time * 2.0 + i).abs();
      final dx = (baseDx + sin(time * 0.05 + i) * 8.0) % size.width;
      final dy = (baseDy + cos(time * 0.05 + i) * 8.0) % size.height;

      starPaint.color = Colors.white.withOpacity(twinkle * 0.6);
      canvas.drawCircle(Offset(dx, dy), starSize, starPaint);
    }

    // Cyan / Purple Cosmic Nebula Clouds
    final nebulaPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50.0);

    nebulaPaint.color = const Color(0xFF00B0FF).withOpacity(0.04 + 0.02 * sin(time * 0.5));
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 90.0, nebulaPaint);

    nebulaPaint.color = const Color(0xFF7C4DFF).withOpacity(0.035 + 0.015 * cos(time * 0.4));
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.7), 110.0, nebulaPaint);
  }

  @override
  bool shouldRepaint(covariant CosmicParallaxPainter oldDelegate) => true;
}
