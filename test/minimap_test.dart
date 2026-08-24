import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:lander_zero/game/lander_zero_game.dart';
import 'package:lander_zero/game/components/cave.dart';
import 'package:lander_zero/ui/widgets/minimap_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Minimap Coordinate Projection Unit Tests', () {
    const double width = 144.0;
    const double height = 92.0;

    test('Calibrated world bounds constants are defined correctly', () {
      expect(MinimapWidget.minWorldX, equals(-36.0));
      expect(MinimapWidget.maxWorldX, equals(36.0));
      expect(MinimapWidget.minWorldY, equals(-30.0));
      expect(MinimapWidget.maxWorldY, equals(16.0));
      expect(MinimapWidget.maxWorldX - MinimapWidget.minWorldX, equals(72.0));
      expect(MinimapWidget.maxWorldY - MinimapWidget.minWorldY, equals(46.0));
    });

    test('projectX accurately maps boundary and intermediate horizontal coordinates', () {
      // Left boundary
      expect(MinimapWidget.projectX(-36.0, width), closeTo(0.0, 0.001));
      // Right boundary
      expect(MinimapWidget.projectX(36.0, width), closeTo(width, 0.001));
      // Center
      expect(MinimapWidget.projectX(0.0, width), closeTo(width / 2, 0.001));
      // Quarter points
      expect(MinimapWidget.projectX(-18.0, width), closeTo(width * 0.25, 0.001));
      expect(MinimapWidget.projectX(18.0, width), closeTo(width * 0.75, 0.001));

      // Key cave platform positions
      // Echo start platform (-28.0)
      expect(MinimapWidget.projectX(-28.0, width), closeTo((8.0 / 72.0) * width, 0.001));
      // Echo exit platform (25.0)
      expect(MinimapWidget.projectX(25.0, width), closeTo((61.0 / 72.0) * width, 0.001));
      // Wind exit platform (28.0)
      expect(MinimapWidget.projectX(28.0, width), closeTo((64.0 / 72.0) * width, 0.001));
      // Core start platform (-26.0)
      expect(MinimapWidget.projectX(-26.0, width), closeTo((10.0 / 72.0) * width, 0.001));
    });

    test('projectY accurately maps boundary, platforms, and ceiling peaks without clipping', () {
      // Top boundary (deepest ceiling headroom)
      expect(MinimapWidget.projectY(-30.0, height), closeTo(0.0, 0.001));
      // Bottom boundary (deepest floor)
      expect(MinimapWidget.projectY(16.0, height), closeTo(height, 0.001));
      // Midpoint
      expect(MinimapWidget.projectY(-7.0, height), closeTo(height / 2, 0.001));

      // Core exit platform ceiling (peaking at y = -27.0) must be inside canvas without clipping
      final coreCeilingY = MinimapWidget.projectY(-27.0, height);
      expect(coreCeilingY, greaterThan(0.0));
      expect(coreCeilingY, closeTo((3.0 / 46.0) * height, 0.001));

      // Echo cargo platform (y = 8.0)
      final cargoPlatformY = MinimapWidget.projectY(8.0, height);
      expect(cargoPlatformY, lessThan(height));
      expect(cargoPlatformY, closeTo((38.0 / 46.0) * height, 0.001));

      // Deepest floor depression (y = 14.0)
      final floorDepressionY = MinimapWidget.projectY(14.0, height);
      expect(floorDepressionY, lessThan(height));
      expect(floorDepressionY, closeTo((44.0 / 46.0) * height, 0.001));
    });

    test('projectOffset transforms Vector2 to Offset correctly', () {
      const size = Size(width, height);
      final originOffset = MinimapWidget.projectOffset(Vector2(0.0, -7.0), size);
      expect(originOffset.dx, closeTo(72.0, 0.001));
      expect(originOffset.dy, closeTo(46.0, 0.001));

      final cornerOffset = MinimapWidget.projectOffset(Vector2(-36.0, -30.0), size);
      expect(cornerOffset.dx, closeTo(0.0, 0.001));
      expect(cornerOffset.dy, closeTo(0.0, 0.001));

      final maxCornerOffset = MinimapWidget.projectOffset(Vector2(36.0, 16.0), size);
      expect(maxCornerOffset.dx, closeTo(width, 0.001));
      expect(maxCornerOffset.dy, closeTo(height, 0.001));
    });

    test('projectX and projectY scale linearly with custom canvas dimensions', () {
      const double customWidth = 300.0;
      const double customHeight = 200.0;

      expect(MinimapWidget.projectX(-36.0, customWidth), closeTo(0.0, 0.001));
      expect(MinimapWidget.projectX(36.0, customWidth), closeTo(customWidth, 0.001));
      expect(MinimapWidget.projectX(0.0, customWidth), closeTo(150.0, 0.001));

      expect(MinimapWidget.projectY(-30.0, customHeight), closeTo(0.0, 0.001));
      expect(MinimapWidget.projectY(16.0, customHeight), closeTo(customHeight, 0.001));
      expect(MinimapWidget.projectY(-7.0, customHeight), closeTo(100.0, 0.001));
    });
  });

  group('Minimap Lander Heading Orientation Trigonometry Tests', () {
    test('calculateHeadingVector points straight up when angle is 0', () {
      final heading = MinimapWidget.calculateHeadingVector(0.0, 8.0);
      expect(heading.dx, closeTo(0.0, 0.0001));
      expect(heading.dy, closeTo(-8.0, 0.0001));
    });

    test('calculateHeadingVector points right when angle is pi/2', () {
      final heading = MinimapWidget.calculateHeadingVector(pi / 2, 8.0);
      expect(heading.dx, closeTo(8.0, 0.0001));
      expect(heading.dy, closeTo(0.0, 0.0001));
    });

    test('calculateHeadingVector points down when angle is pi', () {
      final heading = MinimapWidget.calculateHeadingVector(pi, 8.0);
      expect(heading.dx, closeTo(0.0, 0.0001));
      expect(heading.dy, closeTo(8.0, 0.0001));
    });

    test('calculateHeadingVector points left when angle is -pi/2', () {
      final heading = MinimapWidget.calculateHeadingVector(-pi / 2, 8.0);
      expect(heading.dx, closeTo(-8.0, 0.0001));
      expect(heading.dy, closeTo(0.0, 0.0001));
    });

    test('calculateHeadingVector diagonal 45 degree angle math', () {
      final heading = MinimapWidget.calculateHeadingVector(pi / 4, 10.0);
      final expectedComponent = 10.0 * (sqrt(2) / 2);
      expect(heading.dx, closeTo(expectedComponent, 0.0001));
      expect(heading.dy, closeTo(-expectedComponent, 0.0001));
    });

    test('calculateHeadingVector uses default length of 7.5 when unspecified', () {
      final heading = MinimapWidget.calculateHeadingVector(0.0);
      expect(heading.dx, closeTo(0.0, 0.0001));
      expect(heading.dy, closeTo(-7.5, 0.0001));
    });
  });

  group('Minimap Tether and Platform Logic Tests', () {
    test('isTethered accurately reflects game.rope state', () {
      final game = LanderZeroGame(mapId: 'echo');
      expect(MinimapWidget.isTethered(game), isFalse);
    });

    test('Platforms for Echo, Wind, and Core fall within minimap bounds', () {
      for (final mapId in ['echo', 'wind', 'core']) {
        final cave = Cave(mapId: mapId);

        // Start platform
        expect(cave.startPlatform.x, greaterThanOrEqualTo(MinimapWidget.minWorldX));
        expect(cave.startPlatform.x, lessThanOrEqualTo(MinimapWidget.maxWorldX));
        expect(cave.startPlatform.y, greaterThanOrEqualTo(MinimapWidget.minWorldY));
        expect(cave.startPlatform.y, lessThanOrEqualTo(MinimapWidget.maxWorldY));

        // Cargo platform
        expect(cave.cargoPlatform.x, greaterThanOrEqualTo(MinimapWidget.minWorldX));
        expect(cave.cargoPlatform.x, lessThanOrEqualTo(MinimapWidget.maxWorldX));
        expect(cave.cargoPlatform.y, greaterThanOrEqualTo(MinimapWidget.minWorldY));
        expect(cave.cargoPlatform.y, lessThanOrEqualTo(MinimapWidget.maxWorldY));

        // Exit platform
        expect(cave.exitPlatform.x, greaterThanOrEqualTo(MinimapWidget.minWorldX));
        expect(cave.exitPlatform.x, lessThanOrEqualTo(MinimapWidget.maxWorldX));
        expect(cave.exitPlatform.y, greaterThanOrEqualTo(MinimapWidget.minWorldY));
        expect(cave.exitPlatform.y, lessThanOrEqualTo(MinimapWidget.maxWorldY));
      }
    });
  });

  group('MinimapWidget Widget & Rendering Tests', () {
    testWidgets('MinimapWidget renders tactical container and radar labels', (tester) async {
      final game = LanderZeroGame(mapId: 'echo');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MinimapWidget(
              game: game,
              width: 144.0,
              height: 92.0,
            ),
          ),
        ),
      );

      // Verify radar tactical labels
      expect(find.text('RADAR'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
      expect(find.byType(MinimapWidget), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MinimapWidget),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('MinimapWidget respects custom dimensions', (tester) async {
      final game = LanderZeroGame(mapId: 'wind');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MinimapWidget(
              game: game,
              width: 200.0,
              height: 120.0,
            ),
          ),
        ),
      );

      final containerFinder = find.descendant(
        of: find.byType(MinimapWidget),
        matching: find.byType(Container),
      );
      expect(containerFinder, findsWidgets);

      final RenderBox renderBox = tester.renderObject(find.byType(MinimapWidget));
      expect(renderBox.size.width, equals(200.0));
      expect(renderBox.size.height, equals(120.0));
    });

    testWidgets('MinimapWidget reacts to statsNotifier updates', (tester) async {
      final game = LanderZeroGame(mapId: 'core');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MinimapWidget(
              game: game,
              width: 160.0,
              height: 100.0,
            ),
          ),
        ),
      );

      expect(find.byType(MinimapWidget), findsOneWidget);

      // Trigger stats update
      game.statsNotifier.value = {
        'coins': 12,
        'distance': 45.0,
        'alert': 'DOCK SUCCESSFUL',
        'fuel': 0.75,
        'maxFuel': 1.0,
        'shield': 0.85,
        'maxShield': 1.0,
        'hasRope': true,
      };
      await tester.pump();

      expect(find.byType(MinimapWidget), findsOneWidget);
    });
  });
}
