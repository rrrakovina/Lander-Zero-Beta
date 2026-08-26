import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lander_zero/game/audio/game_audio_manager.dart';
import 'package:lander_zero/game/state/game_state.dart';
import 'package:lander_zero/game/state/save_security_manager.dart';
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
          height: 1800,
          child: GarageWidget(
            onBack: onBack ?? () {},
          ),
        ),
      ),
    );
  }

  Future<void> switchToPilotTab(WidgetTester tester, {String tabText = 'ПИЛОТ'}) async {
    await tester.tap(find.text(tabText));
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('GameState Pilot Wardrobe Defaults & Catalog Tests', () {
    test('Fresh install initializes default wardrobe parameters', () {
      final state = GameState();

      expect(state.suitColor, equals('classic_orange'));
      expect(state.selectedHelmet, equals('sphere1'));
      expect(state.ownedHelmets, contains('sphere1'));
      expect(state.ownedHelmets.length, equals(1));
      expect(state.selectedSuit, equals('sk1_cadet'));
      expect(state.ownedSuits, contains('sk1_cadet'));
      expect(state.ownedSuits.length, equals(1));
    });

    test('Catalog configurations contain all required models and prices', () {
      // 6 Free Suit Colors
      expect(GameState.suitColors.length, equals(6));
      final colorIds = GameState.suitColors.map((c) => c['id']).toList();
      expect(colorIds, containsAll([
        'classic_orange',
        'nasa_white',
        'cyber_cyan',
        'carbon_black',
        'hazmat_yellow',
        'crimson_interceptor',
      ]));

      // 4 Helmet Types & Prices (Sphere-1 free, Cyber-Visor 60, Miner Helmet 80, Swift-Aero 100)
      expect(GameState.helmetConfigs.length, equals(4));
      expect(GameState.helmetConfigs['sphere1']?['price'], equals(0));
      expect(GameState.helmetConfigs['cyber_visor']?['price'], equals(60));
      expect(GameState.helmetConfigs['miner_helmet']?['price'], equals(80));
      expect(GameState.helmetConfigs['swift_aero']?['price'], equals(100));

      // 3 Suit Models & Prices (SK-1 Cadet free, Exo-Frame 90, Cryo-Suit 120)
      expect(GameState.suitConfigs.length, equals(3));
      expect(GameState.suitConfigs['sk1_cadet']?['price'], equals(0));
      expect(GameState.suitConfigs['exo_frame']?['price'], equals(90));
      expect(GameState.suitConfigs['cryo_suit']?['price'], equals(120));
    });
  });

  group('Free Suit Color Swapping & Persistence Tests', () {
    test('Changing suit color is strictly 100% free and deducts 0 coins', () async {
      final state = GameState();
      await state.addCoins(100);
      expect(state.totalCoins, equals(100));

      for (final colorEntry in GameState.suitColors) {
        final colorId = colorEntry['id'] as String;
        await state.setSuitColor(colorId);

        expect(state.suitColor, equals(colorId));
        expect(state.totalCoins, equals(100), reason: 'Color swapping must never cost coins');
      }
    });

    test('Suit color persists across reload and re-initialization', () async {
      final state = GameState();
      await state.setSuitColor('cyber_cyan');
      expect(state.suitColor, equals('cyber_cyan'));

      // Re-init with existing preferences
      await GameState().init(force: true);
      expect(GameState().suitColor, equals('cyber_cyan'));
    });
  });

  group('Helmet Purchase, Selection & Economy Tests', () {
    test('Insufficient coins reject helmet purchase without balance deduction', () async {
      final state = GameState();
      await state.addCoins(40); // 40 < 60
      expect(state.totalCoins, equals(40));

      final success = await state.buyHelmet('cyber_visor', 60);
      expect(success, isFalse);
      expect(state.totalCoins, equals(40));
      expect(state.ownedHelmets, isNot(contains('cyber_visor')));
      expect(state.selectedHelmet, equals('sphere1'));
    });

    test('Sufficient coins allow sequential helmet purchases and auto-equip', () async {
      final state = GameState();
      await state.addCoins(250);

      // 1. Buy Cyber-Visor (60)
      final buyCyber = await state.buyHelmet('cyber_visor', 60);
      expect(buyCyber, isTrue);
      expect(state.totalCoins, equals(190));
      expect(state.ownedHelmets, contains('cyber_visor'));
      expect(state.selectedHelmet, equals('cyber_visor'));

      // 2. Buy Miner Helmet (80)
      final buyMiner = await state.buyHelmet('miner_helmet', 80);
      expect(buyMiner, isTrue);
      expect(state.totalCoins, equals(110));
      expect(state.ownedHelmets, contains('miner_helmet'));
      expect(state.selectedHelmet, equals('miner_helmet'));

      // 3. Buy Swift-Aero (100)
      final buySwift = await state.buyHelmet('swift_aero', 100);
      expect(buySwift, isTrue);
      expect(state.totalCoins, equals(10));
      expect(state.ownedHelmets, contains('swift_aero'));
      expect(state.selectedHelmet, equals('swift_aero'));

      // 4. Re-selecting already owned Sphere-1 costs 0 coins
      final selectSphere = await state.selectHelmet('sphere1');
      expect(selectSphere, isTrue);
      expect(state.selectedHelmet, equals('sphere1'));
      expect(state.totalCoins, equals(10));
    });

    test('Selecting unowned helmet fails without state corruption', () async {
      final state = GameState();
      final success = await state.selectHelmet('swift_aero');
      expect(success, isFalse);
      expect(state.selectedHelmet, equals('sphere1'));
    });

    test('Re-buying already owned helmet equips it without double-charging', () async {
      final state = GameState();
      await state.addCoins(200);
      await state.buyHelmet('cyber_visor', 60);
      expect(state.totalCoins, equals(140));

      await state.selectHelmet('sphere1');
      expect(state.selectedHelmet, equals('sphere1'));

      // Re-buy cyber_visor
      final rebought = await state.buyHelmet('cyber_visor', 60);
      expect(rebought, isTrue);
      expect(state.selectedHelmet, equals('cyber_visor'));
      expect(state.totalCoins, equals(140), reason: 'Must not double charge owned helmet');
    });
  });

  group('Suit Model Purchase, Selection & Economy Tests', () {
    test('Insufficient coins reject suit purchase', () async {
      final state = GameState();
      await state.addCoins(50); // 50 < 90

      final success = await state.buySuit('exo_frame', 90);
      expect(success, isFalse);
      expect(state.totalCoins, equals(50));
      expect(state.ownedSuits, isNot(contains('exo_frame')));
      expect(state.selectedSuit, equals('sk1_cadet'));
    });

    test('Sufficient coins allow purchasing all suit models', () async {
      final state = GameState();
      await state.addCoins(250);

      // 1. Buy Exo-Frame (90)
      final buyExo = await state.buySuit('exo_frame', 90);
      expect(buyExo, isTrue);
      expect(state.totalCoins, equals(160));
      expect(state.ownedSuits, contains('exo_frame'));
      expect(state.selectedSuit, equals('exo_frame'));

      // 2. Buy Cryo-Suit (120)
      final buyCryo = await state.buySuit('cryo_suit', 120);
      expect(buyCryo, isTrue);
      expect(state.totalCoins, equals(40));
      expect(state.ownedSuits, contains('cryo_suit'));
      expect(state.selectedSuit, equals('cryo_suit'));

      // 3. Re-select SK-1 Cadet (0 coins)
      final selectSk1 = await state.selectSuit('sk1_cadet');
      expect(selectSk1, isTrue);
      expect(state.selectedSuit, equals('sk1_cadet'));
      expect(state.totalCoins, equals(40));
    });

    test('Selecting unowned suit returns false', () async {
      final state = GameState();
      final success = await state.selectSuit('cryo_suit');
      expect(success, isFalse);
      expect(state.selectedSuit, equals('sk1_cadet'));
    });
  });

  group('HMAC Security & Wardrobe Tamper Recovery Tests', () {
    test('HMAC signature incorporates wardrobe state deterministically', () {
      final sig1 = SaveSecurityManager.computeSignature(
        coins: 100,
        ownedRockets: ['sputnik', 'swift'],
        suitColor: 'classic_orange',
        selectedHelmet: 'sphere1',
        ownedHelmets: ['sphere1'],
        selectedSuit: 'sk1_cadet',
        ownedSuits: ['sk1_cadet'],
      );

      final sig2 = SaveSecurityManager.computeSignature(
        coins: 100,
        ownedRockets: ['sputnik', 'swift'],
        suitColor: 'classic_orange',
        selectedHelmet: 'sphere1',
        ownedHelmets: ['sphere1'],
        selectedSuit: 'sk1_cadet',
        ownedSuits: ['sk1_cadet'],
      );

      expect(sig1, equals(sig2));

      // Different suit color -> different signature
      final sigColor = SaveSecurityManager.computeSignature(
        coins: 100,
        ownedRockets: ['sputnik', 'swift'],
        suitColor: 'cyber_cyan',
        selectedHelmet: 'sphere1',
        ownedHelmets: ['sphere1'],
        selectedSuit: 'sk1_cadet',
        ownedSuits: ['sk1_cadet'],
      );
      expect(sigColor, isNot(equals(sig1)));

      // Different helmet -> different signature
      final sigHelmet = SaveSecurityManager.computeSignature(
        coins: 100,
        ownedRockets: ['sputnik', 'swift'],
        suitColor: 'classic_orange',
        selectedHelmet: 'cyber_visor',
        ownedHelmets: ['sphere1', 'cyber_visor'],
        selectedSuit: 'sk1_cadet',
        ownedSuits: ['sk1_cadet'],
      );
      expect(sigHelmet, isNot(equals(sig1)));
    });

    test('Tampering with owned helmets in SharedPreferences triggers safe reset', () async {
      final state = GameState();
      await state.addCoins(500);
      await state.buyHelmet('cyber_visor', 60);
      expect(state.ownedHelmets, contains('cyber_visor'));

      final prefs = await SharedPreferences.getInstance();
      // Manually forge unpurchased swift_aero into SharedPreferences without updating HMAC
      await prefs.setStringList('ownedHelmets', ['sphere1', 'cyber_visor', 'swift_aero']);
      await prefs.setString('selectedHelmet', 'swift_aero');

      // Re-initialize GameState -> should detect HMAC mismatch and reset to safe starter baseline
      await GameState().init(force: true);

      expect(GameState().totalCoins, equals(0), reason: 'Tampered state must reset coins');
      expect(GameState().ownedHelmets, equals(['sphere1']), reason: 'Tampered helmets must reset');
      expect(GameState().selectedHelmet, equals('sphere1'));
      expect(GameState().ownedRockets, equals(['sputnik', 'swift']));
    });

    test('Tampering with owned suits in SharedPreferences triggers safe reset', () async {
      final state = GameState();
      await state.addCoins(300);
      await state.buySuit('exo_frame', 90);

      final prefs = await SharedPreferences.getInstance();
      // Manually forge cryo_suit into preferences
      await prefs.setStringList('ownedSuits', ['sk1_cadet', 'exo_frame', 'cryo_suit']);
      await prefs.setString('selectedSuit', 'cryo_suit');

      await GameState().init(force: true);

      expect(GameState().totalCoins, equals(0));
      expect(GameState().ownedSuits, equals(['sk1_cadet']));
      expect(GameState().selectedSuit, equals('sk1_cadet'));
    });

    test('Legitimate save with valid HMAC loads custom wardrobe state cleanly', () async {
      final state = GameState();
      await state.addCoins(1000);
      await state.setSuitColor('crimson_interceptor');
      await state.buyHelmet('cyber_visor', 60);
      await state.buySuit('exo_frame', 90);

      // Re-initialize GameState
      await GameState().init(force: true);

      expect(GameState().totalCoins, equals(850));
      expect(GameState().suitColor, equals('crimson_interceptor'));
      expect(GameState().selectedHelmet, equals('cyber_visor'));
      expect(GameState().ownedHelmets, containsAll(['sphere1', 'cyber_visor']));
      expect(GameState().selectedSuit, equals('exo_frame'));
      expect(GameState().ownedSuits, containsAll(['sk1_cadet', 'exo_frame']));
    });
  });

  group('GarageScreen Pilot Tab UI & Widget Interaction Tests', () {
    testWidgets('GarageScreen renders 3 tabs including PILOT tab', (tester) async {
      tester.view.physicalSize = const Size(1280, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createGarageScreen());
      for (int i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('МОДЕРНИЗАЦИЯ'), findsOneWidget);
      expect(find.text('КАБИНЫ'), findsOneWidget);
      expect(find.text('ПИЛОТ'), findsOneWidget);
    });

    testWidgets('Switching to PILOT tab renders swatches, helmet cards, suit cards, and preview', (tester) async {
      tester.view.physicalSize = const Size(1280, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createGarageScreen());
      for (int i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      await switchToPilotTab(tester);

      // Section titles
      expect(find.text('ЦВЕТ СКАФАНДРА'), findsOneWidget);
      expect(find.text('ТИП ШЛЕМА'), findsOneWidget);
      expect(find.text('МОДЕЛЬ КОСТЮМА'), findsOneWidget);

      // Helmet items
      expect(find.text('Сфера-1'), findsAtLeastNWidgets(1));
      expect(find.text('Кибер-Визор'), findsOneWidget);
      expect(find.text('Шлем Шахтера'), findsOneWidget);
      expect(find.text('Стриж-Аэро'), findsOneWidget);

      // Suit model items
      expect(find.text('СК-1 Курсант'), findsAtLeastNWidgets(1));
      expect(find.text('Экзо-Каркас'), findsOneWidget);
      expect(find.text('Крио-Костюм'), findsOneWidget);
    });

    testWidgets('Tapping color swatch in PILOT tab updates suit color immediately', (tester) async {
      tester.view.physicalSize = const Size(1280, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final state = GameState();
      await tester.pumpWidget(createGarageScreen());
      for (int i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      await switchToPilotTab(tester);

      // Find color swatch for Cyber Cyan
      final cyanColor = find.text('Кибер-циан');
      expect(cyanColor, findsOneWidget);

      await tester.tap(cyanColor);
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(state.suitColor, equals('cyber_cyan'));
    });

    testWidgets('Purchasing Cyber-Visor helmet in UI deducts coins and equips helmet', (tester) async {
      tester.view.physicalSize = const Size(1280, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final state = GameState();
      await state.addCoins(200);

      await tester.pumpWidget(createGarageScreen());
      for (int i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      await switchToPilotTab(tester);

      // Find Cyber-Visor buy button with '60 КУПИТЬ'
      final cyberBuyButton = find.textContaining('60');
      expect(cyberBuyButton, findsOneWidget);

      await tester.tap(cyberBuyButton);
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(state.ownedHelmets, contains('cyber_visor'));
      expect(state.selectedHelmet, equals('cyber_visor'));
      expect(state.totalCoins, equals(140));
    });

    testWidgets('PILOT tab translates cleanly to English mode', (tester) async {
      tester.view.physicalSize = const Size(1280, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final state = GameState();
      await state.setLanguage('en');

      await tester.pumpWidget(createGarageScreen());
      for (int i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('PILOT'), findsOneWidget);
      await switchToPilotTab(tester, tabText: 'PILOT');

      expect(find.text('SUIT COLOR'), findsOneWidget);
      expect(find.text('HELMET TYPE'), findsOneWidget);
      expect(find.text('SUIT MODEL'), findsOneWidget);

      expect(find.text('Sphere-1'), findsAtLeastNWidgets(1));
      expect(find.text('Cyber-Visor'), findsOneWidget);
      expect(find.text('Miner Helmet'), findsOneWidget);
      expect(find.text('Swift-Aero'), findsOneWidget);

      expect(find.text('SK-1 Cadet'), findsAtLeastNWidgets(1));
      expect(find.text('Exo-Frame'), findsOneWidget);
      expect(find.text('Cryo-Suit'), findsOneWidget);
    });
  });
}
