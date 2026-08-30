import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lander_zero/game/state/game_state.dart';
import 'package:lander_zero/game/audio/game_audio_manager.dart';
import 'package:lander_zero/ui/screens/garage_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    GameAudioManager.isTesting = true;
    await GameState().init(force: true);
  });

  Widget createGarageScreen({VoidCallback? onBack}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 1280,
          height: 800,
          child: GarageWidget(
            onBack: onBack ?? () {},
          ),
        ),
      ),
    );
  }

  Future<void> switchToCabinsTab(WidgetTester tester, {String tabText = 'КАБИНЫ'}) async {
    await tester.tap(find.text(tabText));
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('GarageWidget Screen & Action Buttons Tests', () {
    testWidgets('Renders top bar with title, back button, coins counter, and tabs', (tester) async {
      await tester.pumpWidget(createGarageScreen());
      await tester.pump();

      // Top bar title in Russian (default)
      expect(find.text('ГАРАЖ'), findsOneWidget);

      // Back button
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      // Coins counter
      expect(find.text('0'), findsWidgets);

      // Tab bar tabs
      expect(find.text('МОДЕРНИЗАЦИЯ'), findsOneWidget);
      expect(find.text('КАБИНЫ'), findsOneWidget);
    });

    testWidgets('Upgrades tab displays upgrade items and handles stat upgrades', (tester) async {
      final state = GameState();
      await tester.pumpWidget(createGarageScreen());
      await tester.pump();

      // Stat titles
      expect(find.text('ТЯГА'), findsOneWidget);
      expect(find.text('ТОПЛИВО'), findsOneWidget);
      expect(find.text('ЩИТ'), findsOneWidget);

      // Action button "КУПИТЬ" and price 150
      expect(find.text('КУПИТЬ'), findsWidgets);
      expect(find.text('150'), findsWidgets);

      // Add coins to afford upgrade
      await state.addCoins(500);
      await tester.pump();

      // Tap first upgrade button (Engine)
      final buyButtons = find.text('КУПИТЬ');
      expect(buyButtons, findsWidgets);
      await tester.tap(buyButtons.first);
      for (int i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(state.engineLevel, equals(2));
      expect(state.totalCoins, equals(350));
    });

    testWidgets('Cabins tab displays all vessels with preview cards and action buttons', (tester) async {
      await tester.pumpWidget(createGarageScreen());
      await tester.pump();

      // Switch to Cabins tab
      await switchToCabinsTab(tester);

      // Vessel names
      expect(find.text('Спутник-11'), findsOneWidget);
      expect(find.text('Стриж-28'), findsOneWidget);
      expect(find.text('Ураган-47'), findsOneWidget);
      expect(find.text('Игла-52'), findsOneWidget);
      expect(find.text('Буран-67'), findsOneWidget);

      // Preview cards
      expect(find.byType(CabinPreviewWidget), findsNWidgets(5));

      // Initial state: Sputnik and Swift are owned, Cyclone (800), Needle (1500), Titan (2200) are unowned
      expect(find.text('ВЫБРАНО'), findsWidgets);
      expect(find.text('800'), findsOneWidget);
      expect(find.text('1500'), findsOneWidget);
      expect(find.text('2200'), findsOneWidget);
    });

    testWidgets('Purchasing a vessel updates button styling and active vessel', (tester) async {
      final state = GameState();
      await state.addCoins(2000);

      await tester.pumpWidget(createGarageScreen());
      await tester.pump();

      // Switch to Cabins tab
      await switchToCabinsTab(tester);

      // Tap Buy button for Cyclone
      final cycloneBuy = find.text('800');
      expect(cycloneBuy, findsOneWidget);
      await tester.tap(cycloneBuy);
      for (int i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Cyclone should now be owned and selected
      expect(state.ownedRockets, contains('cyclone'));
      expect(state.selectedRocket, equals('cyclone'));
      expect(state.totalCoins, equals(1200));

      // Re-select Sputnik-11
      final selectSputnik = find.text('ВЫБРАТЬ');
      expect(selectSputnik, findsWidgets);
      await tester.tap(selectSputnik.first);
      for (int i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(state.selectedRocket, equals('sputnik'));
    });

    testWidgets('GarageWidget responds properly to language switching', (tester) async {
      final state = GameState();
      await state.setLanguage('en');

      await tester.pumpWidget(createGarageScreen());
      await tester.pump();

      expect(find.text('GARAGE'), findsOneWidget);
      expect(find.text('UPGRADES'), findsOneWidget);
      expect(find.text('ROCKETS'), findsOneWidget);

      // Switch to cabins tab in English
      await switchToCabinsTab(tester, tabText: 'ROCKETS');

      expect(find.text('Sputnik-11'), findsOneWidget);
      expect(find.text('Swift-28'), findsOneWidget);
      expect(find.text('Cyclone-47'), findsOneWidget);
      expect(find.text('Needle-52'), findsOneWidget);
      expect(find.text('Titan-67'), findsOneWidget);
      expect(find.text('SELECTED'), findsWidgets);
      expect(find.text('BUY'), findsWidgets);
    });

    testWidgets('Back button triggers onBack callback', (tester) async {
      bool backTapped = false;
      await tester.pumpWidget(createGarageScreen(onBack: () => backTapped = true));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pump();

      expect(backTapped, isTrue);
    });
  });
}
