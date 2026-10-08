import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/mamata_game.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';
import 'ui/dialogs.dart';
import 'ui/hud.dart';
import 'ui/menus.dart';
import 'ui/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();
  await StorageService.instance.init();
  runApp(const MamataApp());
}

class MamataApp extends StatelessWidget {
  const MamataApp({super.key, this.game});

  /// Permite injetar a instância do jogo (testes e capturas de tela).
  final MamataGame? game;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mamata',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.green),
        useMaterial3: true,
      ),
      home: GameScreen(game: game),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.game});

  final MamataGame? game;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final MamataGame _game = widget.game ?? MamataGame();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AudioService.instance.init().then((_) => AudioService.instance.playMusic(Music.menu));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _game.onAppBackgrounded();
      case AppLifecycleState.resumed:
        _game.onAppResumed();
      case AppLifecycleState.detached:
        break;
    }
  }

  /// Botão "voltar" do Android.
  void _onBack() {
    final active = _game.overlays.activeOverlays;
    if (active.contains('pause')) {
      _game.resumeGame();
    } else if (active.contains('hud')) {
      _game.pauseGame();
    } else if (active.contains('menu')) {
      SystemNavigator.pop();
    } else if (active.contains('intro')) {
      _game.goToMenu();
    } else if (active.any((o) => o == 'levels' || o == 'howto' || o == 'settings')) {
      _game.overlays.removeAll(active.toList());
      _game.overlays.add('menu');
    } else if (active.any((o) => o == 'gameover' || o == 'complete' || o == 'victory')) {
      _game.goToMenu();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: GameWidget<MamataGame>(
          game: _game,
          initialActiveOverlays: const ['menu'],
          loadingBuilder: (_) => const ColoredBox(
            color: AppColors.navy,
            child: Center(child: StrokeText('MAMATA', size: 64, color: AppColors.yellow)),
          ),
          overlayBuilderMap: {
            'menu': (_, g) => MainMenu(game: g),
            'levels': (_, g) => LevelSelect(game: g),
            'howto': (_, g) => HowToPlay(game: g),
            'settings': (_, g) => SettingsScreen(game: g),
            'intro': (_, g) => LevelIntro(game: g),
            'hud': (_, g) => Hud(game: g),
            'pause': (_, g) => PauseMenu(game: g),
            'gameover': (_, g) => GameOverScreen(game: g),
            'complete': (_, g) => LevelComplete(game: g),
            'victory': (_, g) => VictoryScreen(game: g),
          },
        ),
      ),
    );
  }
}
