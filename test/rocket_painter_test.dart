import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lander_zero/ui/painters/rocket_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RocketPainter Unit & Bounds Tests', () {
    test('RocketPainter defines accurate model bounding boxes for all vessels', () {
      final sputnikBounds = RocketPainter.getBounds('sputnik');
      expect(sputnikBounds.width, equals(3.30));
      expect(sputnikBounds.height, equals(2.60));
      expect(sputnikBounds.center.dx, equals(0.0));
      expect(sputnikBounds.center.dy, equals(0.0));

      final cycloneBounds = RocketPainter.getBounds('cyclone');
      expect(cycloneBounds.width, equals(4.40));
      expect(cycloneBounds.height, equals(2.95));
      expect(cycloneBounds.width, greaterThan(4.0)); // Encloses wide landing skis
      expect(cycloneBounds.center.dx, equals(0.0));
      expect(cycloneBounds.center.dy, closeTo(0.075, 0.001));

      final needleBounds = RocketPainter.getBounds('needle');
      expect(needleBounds.width, equals(2.90));
      expect(needleBounds.height, equals(3.05));
      expect(needleBounds.height, greaterThanOrEqualTo(3.0)); // Encloses pointy nose apex and ski feet
      expect(needleBounds.center.dx, equals(0.0));
      expect(needleBounds.center.dy, closeTo(-0.175, 0.001));

      // Fallback for unknown ID defaults to sputnik bounds
      final unknownBounds = RocketPainter.getBounds('unknown_ship');
      expect(unknownBounds, equals(sputnikBounds));
    });

    test('RocketPainter calculateScale guarantees no horizontal clipping for Cyclone', () {
      const testSizes = [
        Size(100, 100),
        Size(120, 120),
        Size(200, 200),
        Size(300, 150),
        Size(150, 300),
      ];

      for (final size in testSizes) {
        final scale = RocketPainter.calculateScale('cyclone', size);
        final bounds = RocketPainter.getBounds('cyclone');
        final renderedWidth = bounds.width * scale;
        final renderedHeight = bounds.height * scale;

        // Rendered dimensions must strictly fit within canvas dimensions with safety margin
        expect(renderedWidth, lessThanOrEqualTo(size.width));
        expect(renderedHeight, lessThanOrEqualTo(size.height));

        // Horizontal margin must be >= 0
        final horizontalMargin = (size.width - renderedWidth) / 2;
        expect(horizontalMargin, greaterThanOrEqualTo(0.0));

        // For square 120x120 canvas, horizontal margin is exactly (120 - 100)/2 = 10px (16.6% padding)
        if (size.width == 120 && size.height == 120) {
          expect(renderedWidth, closeTo(100.0, 0.1));
          expect(horizontalMargin, closeTo(10.0, 0.1));
        }
      }
    });

    test('RocketPainter calculateScale guarantees no vertical clipping for Needle', () {
      const testSizes = [
        Size(100, 100),
        Size(120, 120),
        Size(200, 200),
        Size(300, 150),
        Size(150, 300),
      ];

      for (final size in testSizes) {
        final scale = RocketPainter.calculateScale('needle', size);
        final bounds = RocketPainter.getBounds('needle');
        final renderedWidth = bounds.width * scale;
        final renderedHeight = bounds.height * scale;

        // Rendered dimensions must strictly fit within canvas dimensions with safety margin
        expect(renderedWidth, lessThanOrEqualTo(size.width));
        expect(renderedHeight, lessThanOrEqualTo(size.height));

        // Vertical margin must be >= 0
        final verticalMargin = (size.height - renderedHeight) / 2;
        expect(verticalMargin, greaterThanOrEqualTo(0.0));

        // For square 120x120 canvas, rendered height is exactly (120 / 1.20) = 100px
        if (size.width == 120 && size.height == 120) {
          expect(renderedHeight, closeTo(100.0, 0.1));
          expect(verticalMargin, closeTo(10.0, 0.1));
        }
      }
    });

    test('RocketPainter handles zero, negative, or degenerate canvas size gracefully', () {
      expect(RocketPainter.calculateScale('sputnik', Size.zero), equals(0.0));
      expect(RocketPainter.calculateScale('sputnik', const Size(0, 100)), equals(0.0));
      expect(RocketPainter.calculateScale('sputnik', const Size(100, 0)), equals(0.0));
      expect(RocketPainter.calculateScale('sputnik', const Size(-50, -50)), equals(0.0));
    });

    test('RocketPainter shouldRepaint responds to property mutations', () {
      final base = RocketPainter(rocketId: 'sputnik', animationTime: 0.0);
      final same = RocketPainter(rocketId: 'sputnik', animationTime: 0.0);
      final diffId = RocketPainter(rocketId: 'cyclone', animationTime: 0.0);
      final diffTime = RocketPainter(rocketId: 'sputnik', animationTime: 1.5);
      final diffGlow = RocketPainter(rocketId: 'sputnik', animationTime: 0.0, glowColor: Colors.amber);
      final diffSelected = RocketPainter(rocketId: 'sputnik', animationTime: 0.0, isSelected: true);

      expect(base.shouldRepaint(same), isFalse);
      expect(base.shouldRepaint(diffId), isTrue);
      expect(base.shouldRepaint(diffTime), isTrue);
      expect(base.shouldRepaint(diffGlow), isTrue);
      expect(base.shouldRepaint(diffSelected), isTrue);
    });
  });

  group('RocketPainter Widget Tests', () {
    testWidgets('CustomPaint renders Sputnik-1 with glow and animation without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomPaint(
                size: const Size(120, 120),
                painter: RocketPainter(
                  rocketId: 'sputnik',
                  animationTime: 1.0,
                  glowColor: Colors.cyan,
                  isSelected: true,
                ),
              ),
            ),
          ),
        ),
      );

      final rocketFinder = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is RocketPainter && (w.painter as RocketPainter).rocketId == 'sputnik',
      );
      expect(rocketFinder, findsOneWidget);
    });

    testWidgets('CustomPaint renders Cyclone and Needle without throwing exception', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CustomPaint(
                  size: const Size(150, 150),
                  painter: RocketPainter(
                    rocketId: 'cyclone',
                    animationTime: 0.5,
                    glowColor: Colors.amber,
                    isSelected: false,
                  ),
                ),
                CustomPaint(
                  size: const Size(150, 150),
                  painter: RocketPainter(
                    rocketId: 'needle',
                    animationTime: 0.5,
                    isSelected: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final cycloneFinder = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is RocketPainter && (w.painter as RocketPainter).rocketId == 'cyclone',
      );
      final needleFinder = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is RocketPainter && (w.painter as RocketPainter).rocketId == 'needle',
      );

      expect(cycloneFinder, findsOneWidget);
      expect(needleFinder, findsOneWidget);
    });
  });
}
