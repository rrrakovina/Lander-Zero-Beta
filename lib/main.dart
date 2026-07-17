import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'game/state/game_state.dart';
import 'game/audio/game_audio_manager.dart';
import 'ui/screens/nick_entry_screen.dart';
import 'ui/screens/main_menu_screen.dart';
import 'ui/screens/garage_screen.dart';
import 'ui/screens/map_select_screen.dart';
import 'ui/screens/leaderboard_screen.dart';
import 'ui/screens/game_screen.dart';

enum ScreenState {
  nickEntry,
  mainMenu,
  garage,
  mapSelect,
  leaderboard,
  playing,
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализируем синглтон GameState
  await GameState().init();

  // Инициализируем GameAudioManager и запускаем фоновую музыку
  await GameAudioManager().init();
  GameAudioManager().playBgm();

  if (!kIsWeb) {
    try {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } catch (e) {
      if (kDebugMode) {
        print('SystemChrome is not supported on this platform: $e');
      }
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lander Zero',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
      ),
      home: const MainScreenController(),
    );
  }
}

class MainScreenController extends StatefulWidget {
  const MainScreenController({super.key});

  @override
  State<MainScreenController> createState() => _MainScreenControllerState();
}

class _MainScreenControllerState extends State<MainScreenController> {
  ScreenState _screen = ScreenState.mainMenu;
  String _selectedMap = 'echo';

  @override
  void initState() {
    super.initState();
    if (GameState().nickname.isEmpty) {
      _screen = ScreenState.nickEntry;
    } else {
      _screen = ScreenState.mainMenu;
    }
  }

  void _navigateTo(ScreenState screen) {
    setState(() {
      _screen = screen;
    });
  }

  void _startGame(String mapId) {
    setState(() {
      _selectedMap = mapId;
      _screen = ScreenState.playing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GameState(),
      builder: (context, _) {
        switch (_screen) {
          case ScreenState.nickEntry:
            return NickEntryWidget(
              onFinished: () => _navigateTo(ScreenState.mainMenu),
            );
          case ScreenState.mainMenu:
            return MainMenuWidget(
              onPlay: () => _navigateTo(ScreenState.mapSelect),
              onGarage: () => _navigateTo(ScreenState.garage),
              onLeaderboard: () => _navigateTo(ScreenState.leaderboard),
            );
          case ScreenState.garage:
            return GarageWidget(
              onBack: () => _navigateTo(ScreenState.mainMenu),
            );
          case ScreenState.mapSelect:
            return MapSelectWidget(
              onMapSelected: (mapId) => _startGame(mapId),
              onBack: () => _navigateTo(ScreenState.mainMenu),
            );
          case ScreenState.leaderboard:
            return LeaderboardWidget(
              onBack: () => _navigateTo(ScreenState.mainMenu),
            );
          case ScreenState.playing:
            return GameScreen(
              mapId: _selectedMap,
              onExit: () => _navigateTo(ScreenState.mainMenu),
            );
        }
      },
    );
  }
}
