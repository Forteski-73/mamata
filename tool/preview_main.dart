// Ponto de entrada só para capturas de tela de teste (não é usado no app).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mamata/game/components/obstacle.dart';
import 'package:mamata/game/mamata_game.dart';
import 'package:mamata/main.dart';
import 'package:mamata/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.instance.init();
  await StorageService.instance.unlockLevel(4);
  final game = MamataGame();
  runApp(MamataApp(game: game));
  final q = Uri.base.queryParameters;
  final scene = q['s'] ?? 'menu';
  final level = int.tryParse(q['l'] ?? '1') ?? 1;
  final secs = double.tryParse(q['t'] ?? '6') ?? 6;
  Timer(const Duration(milliseconds: 1500), () {
    switch (scene) {
      case 'levels':
      case 'howto':
      case 'settings':
        game.overlays.removeAll(game.overlays.activeOverlays.toList());
        game.overlays.add(scene);
      case 'intro':
        game.startLevel(level);
      case 'play':
      case 'caught':
        game.startLevel(level);
        game.beginCountdown();
        final bot = scene == 'play';
        Timer.periodic(const Duration(milliseconds: 30), (t) {
          if (!game.isRunning) return;
          if (bot && game.oranges < 2) game.oranges = 2;
          if (game.traveled > secs * game.speed) {
            if (q['pause'] == '1') game.pauseGame();
            t.cancel();
            return;
          }
          if (!bot) return;
          game.truthGap = q['danger'] == '1' ? 130 : game.truthGap;
          for (final e in game.entities) {
            if (e is Obstacle && !e.cleared) {
              final d = e.x - (game.player.x + 64);
              if (d > 0 && d < 150) {
                if (e.info.flying) {
                  game.slidePressed();
                } else {
                  game.slideReleased();
                  game.jumpPressed();
                  if (e.height > 120) Timer(const Duration(milliseconds: 260), game.jumpPressed);
                }
              }
            }
          }
          if (game.player.sliding) Timer(const Duration(milliseconds: 500), game.slideReleased);
          if (game.traveled % 900 < 20) game.throwTax();
        });
      case 'complete':
        game.startLevel(level);
        game.beginCountdown();
        Timer(const Duration(milliseconds: 3200), () => game.traveled = game.level.length - 1500);
    }
  });
}
