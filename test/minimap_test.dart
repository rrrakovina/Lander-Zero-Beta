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
      expect(MinimapWidget.maxWorldY, equals(24.0));
      expect(MinimapWidget.maxWorldX - MinimapWidget.minWorldX, equals(72.0));
      expect(MinimapWidget.maxWorldY - MinimapWidget.minWorldY, equals(54.0));
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
      // Core start platform (-14.0)
      expect(MinimapWidget.projectX(-14.0, width), closeTo((22.0 / 72.0) * width, 0.001));
      // Core exit platform (14.0)
      expect(MinimapWidget.projectX(14.0, width), closeTo((50.0 / 72.0) * width, 0.001));
    });

    test('projectY accurately maps boundary, platforms, and ceiling peaks without clipping', () {
      // Top boundary (deepest ceiling headroom)
      expect(MinimapWidget.projectY(-30.0, height), closeTo(0.0, 0.001));
      // Bottom boundary (deepest floor)
      expect(MinimapWidget.projectY(24.0, height), closeTo(height, 0.001));
      // Midpoint
      expect(MinimapWidget.projectY(-3.0, height), closeTo(height / 2, 0.001));

      // Core ceiling (peaking at y = -26.0) must be inside canvas without clipping
      final coreCeilingY = MinimapWidget.projectY(-26.0, height);
      expect(coreCeilingY, greaterThan(0.0));
      expect(coreCeilingY, closeTo((4.0 / 54.0) * height, 0.001));

      // Echo cargo platform (y = 8.0)
      final cargoPlatformY = MinimapWidget.projectY(8.0, height);
      expect(cargoPlatformY, lessThan(height));
      expect(cargoPlatformY, closeTo((38.0 / 54.0) * height, 0.001));

      // Deep Core cargo platform (y = 14.0)
      final coreCargoY = MinimapWidget.projectY(14.0, height);
      expect(coreCargoY, lessThan(height));
      expect(coreCargoY, closeTo((44.0 / 54.0) * height, 0.001));
    });

    test('projectOffset transforms Vector2 to Offset correctly', () {
      const size = Size(width, height);
      final originOffset = MinimapWidget.projectOffset(Vector2(0.0, -3.0), size);
      expect(originOffset.dx, closeTo(72.0, 0.001));
      expect(originOffset.dy, closeTo(46.0, 0.001));

      final cornerOffset = MinimapWidget.projectOffset(Vector2(-36.0, -30.0), size);
      expect(cornerOffset.dx, closeTo(0.0, 0.001));
      expect(cornerOffset.dy, closeTo(0.0, 0.001));

      final maxCornerOffset = MinimapWidget.projectOffset(Vector2(36.0, 24.0), size);
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
      expect(MinimapWidget.projectY(24.0, customHeight), closeTo(customHeight, 0.001));
      expect(MinimapWidget.projectY(-3.0, customHeight), closeTo(100.0, 0.001));
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

  group('Minimap Tether and Platform Logic Tests across all 5 Maps', () {
    test('isTethered accurately reflects game.rope state', () {
      final game = LanderZeroGame(mapId: 'echo');
      expect(MinimapWidget.isTethered(game), isFalse);
    });

    test('Platforms for all 5 maps fall strictly within minimap bounds', () {
      for (final mapId in ['echo', 'core', 'wind', 'ice', 'orbit']) {
        final cave = Cave(mapId: mapId);

        // Start platform
        expect(cave.startPlatform.x, greaterThanOrEqualTo(MinimapWidget.minWorldX), reason: '$mapId startPlatform.x');
        expect(cave.startPlatform.x, lessThanOrEqualTo(MinimapWidget.maxWorldX), reason: '$mapId startPlatform.x');
        expect(cave.startPlatform.y, greaterThanOrEqualTo(MinimapWidget.minWorldY), reason: '$mapId startPlatform.y');
        expect(cave.startPlatform.y, lessThanOrEqualTo(MinimapWidget.maxWorldY), reason: '$mapId startPlatform.y');

        // Cargo platform
        expect(cave.cargoPlatform.x, greaterThanOrEqualTo(MinimapWidget.minWorldX), reason: '$mapId cargoPlatform.x');
        expect(cave.cargoPlatform.x, lessThanOrEqualTo(MinimapWidget.maxWorldX), reason: '$mapId cargoPlatform.x');
        expect(cave.cargoPlatform.y, greaterThanOrEqualTo(MinimapWidget.minWorldY), reason: '$mapId cargoPlatform.y');
        expect(cave.cargoPlatform.y, lessThanOrEqualTo(MinimapWidget.maxWorldY), reason: '$mapId cargoPlatform.y');

        // Exit platform
        expect(cave.exitPlatform.x, greaterThanOrEqualTo(MinimapWidget.minWorldX), reason: '$mapId exitPlatform.x');
        expect(cave.exitPlatform.x, lessThanOrEqualTo(MinimapWidget.maxWorldX), reason: '$mapId exitPlatform.x');
        expect(cave.exitPlatform.y, greaterThanOrEqualTo(MinimapWidget.minWorldY), reason: '$mapId exitPlatform.y');
        expect(cave.exitPlatform.y, lessThanOrEqualTo(MinimapWidget.maxWorldY), reason: '$mapId exitPlatform.y');
      }
    });

    test('Europa Ice Rift branchPoints fall within minimap bounds', () {
      final caveIce = Cave(mapId: 'ice');
      final world = Forge2DWorld();
      caveIce.world = world;
      caveIce.createBody();

      expect(caveIce.branchPoints.isNotEmpty, isTrue);
      for (final bp in caveIce.branchPoints) {
        expect(bp.x, greaterThanOrEqualTo(MinimapWidget.minWorldX));
        expect(bp.x, lessThanOrEqualTo(MinimapWidget.maxWorldX));
        expect(bp.y, greaterThanOrEqualTo(MinimapWidget.minWorldY));
        expect(bp.y, lessThanOrEqualTo(MinimapWidget.maxWorldY));
      }
    });

    test('Orbital Debris perimeter beacons fall within minimap bounds', () {
      final caveOrbit = Cave(mapId: 'orbit');
      expect(caveOrbit.perimeterBeacons.length, equals(4));
      for (final beacon in caveOrbit.perimeterBeacons) {
        expect(beacon.x, greaterThanOrEqualTo(MinimapWidget.minWorldX));
        expect(beacon.x, lessThanOrEqualTo(MinimapWidget.maxWorldX));
        expect(beacon.y, greaterThanOrEqualTo(MinimapWidget.minWorldY));
        expect(beacon.y, lessThanOrEqualTo(MinimapWidget.maxWorldY));
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

    testWidgets('MinimapWidget mounts across all 5 map designs without exceptions', (tester) async {
      for (final mapId in ['echo', 'core', 'wind', 'ice', 'orbit']) {
        final game = LanderZeroGame(mapId: mapId);

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

        expect(find.byType(MinimapWidget), findsOneWidget);
      }
    });
  });
}
