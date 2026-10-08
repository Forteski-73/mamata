import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamata/game/components/citizen.dart';
import 'package:mamata/game/components/obstacle.dart';
import 'package:mamata/game/levels.dart';
import 'package:mamata/game/mamata_game.dart';
import 'package:mamata/services/storage_service.dart';
import 'package:mamata/util/format.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Registra overlays vazios (os testes não montam a interface Flutter).
void registerOverlays(MamataGame game) {
  for (final name in ['menu', 'levels', 'howto', 'settings', 'intro', 'hud', 'pause', 'gameover', 'complete', 'victory']) {
    game.overlays.addEntry(name, (_, _) => const SizedBox());
  }
}

/// Avança a simulação em passos de 1/60 s.
void simulate(MamataGame game, double seconds, {void Function()? each}) {
  final steps = (seconds * 60).round();
  for (var i = 0; i < steps; i++) {
    each?.call();
    game.update(1 / 60);
  }
}

/// "Bot" simples: pula obstáculos de chão e se abaixa para os voadores.
void autopilot(MamataGame game) {
  final p = game.player;
  var slide = false;
  for (final e in game.entities) {
    if (e is! Obstacle || e.cleared || !e.active) continue;
    final ahead = e.x - (p.x + 52); // distância até a borda frontal do político
    final closing = game.worldSpeed + e.extraSpeed;
    if (e.info.flying) {
      if (p.onGround && ahead < closing * 0.25 && e.x + e.width > p.x - 24) slide = true;
      continue;
    }
    final big = e.height > 120 || e.width > 200;
    if (p.onGround && ahead > 0 && ahead < closing * (e.width > 200 ? 0.12 : (big ? 0.2 : 0.28))) {
      p.endSlide();
      game.jumpPressed();
    } else if (!p.onGround && p.jumps == 1 && big && p.vy > -150 && e.x + e.width > p.x) {
      game.jumpPressed();
    }
  }
  if (slide) {
    game.slidePressed();
  } else {
    game.slideReleased();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.init();
  });

  group('formatMoney', () {
    test('mil e milhões no padrão brasileiro', () {
      expect(formatMoney(850), 'R\$ 850 mil');
      expect(formatMoney(1250), 'R\$ 1,25 mi');
      expect(formatMoney(12500), 'R\$ 12,5 mi');
    });
  });

  group('MamataGame', () {
    final gameTester = FlameTester<MamataGame>(
      () => MamataGame()..also(registerOverlays),
      gameSize: Vector2(1600, 720),
    );

    gameTester.testGameWidget(
      'a Verdade alcança quem não desvia de nada',
      verify: (game, tester) async {
        game.startLevel(2);
        game.beginCountdown();
        simulate(game, 3.2);
        expect(game.phase, GamePhase.playing);
        simulate(game, 60, each: () {
          if (game.phase != GamePhase.playing) return;
          game.oranges = 0; // sem laranjas para garantir os escândalos
        });
        expect(game.hits, greaterThanOrEqualTo(1));
        expect(game.phase, anyOf(GamePhase.caught, GamePhase.ended));
        expect(game.lastResult?.completed, isFalse);
      },
    );

    gameTester.testGameWidget(
      'laranja assume a culpa: escândalo não aproxima a Verdade',
      verify: (game, tester) async {
        game.startLevel(2);
        game.beginCountdown();
        simulate(game, 3.2);
        game.oranges = 2;
        final o = Obstacle(ObstacleType.tcu, MamataGame.playerX + 10);
        await game.world.add(o);
        await tester.pump();
        final gapBefore = game.truthGap;
        simulate(game, 0.1);
        expect(o.cleared, isTrue);
        expect(game.oranges, 1);
        expect(game.orangesUsed, 1);
        expect(game.hits, 0);
        expect(game.truthGap, greaterThanOrEqualTo(gapBefore));
      },
    );

    for (final type in [ObstacleType.cpi, ObstacleType.cpmi]) {
      final name = type.name.toUpperCase();
      for (final start in [3, 5]) {
        gameTester.testGameWidget(
          'com $start laranjas, o laranjão assume a $name e custa 3',
          verify: (game, tester) async {
            game.startLevel(3);
            game.beginCountdown();
            simulate(game, 3.2);
            game.oranges = start;
            await game.world.add(Obstacle(type, MamataGame.playerX + 10));
            await tester.pump();
            simulate(game, 0.1);
            expect(game.oranges, start - 3);
            expect(game.orangesUsed, 3);
            expect(game.hits, 0);
            expect(game.phase, GamePhase.playing);
            expect(game.bannerN.value?.title, 'SEU LARANJA FOI PRESO!');
            expect(game.mugshotN.value, isTrue, reason: 'mostra o rosto do laranjão');
            simulate(game, 2);
            expect(game.mugshotN.value, isFalse, reason: 'a foto some depois de um instante');
          },
        );
      }
      for (final start in [0, 2]) {
        gameTester.testGameWidget(
          'com $start laranjas, bater na $name: a Verdade pega na hora',
          verify: (game, tester) async {
            game.startLevel(3);
            game.beginCountdown();
            simulate(game, 3.2);
            game.oranges = start;
            await game.world.add(Obstacle(type, MamataGame.playerX + 10));
            await tester.pump();
            simulate(game, 0.1);
            expect(game.phase, GamePhase.caught);
            expect(game.oranges, start, reason: 'laranjas insuficientes não são gastas');
            expect(game.lastResult!.title, 'A VERDADE TE PEGOU!');
            expect(game.lastResult!.completed, isFalse);
          },
        );
      }
    }

    gameTester.testGameWidget(
      'outros escândalos continuam custando 1 laranja',
      verify: (game, tester) async {
        game.startLevel(2);
        game.beginCountdown();
        simulate(game, 3.2);
        game.oranges = MamataGame.maxOranges;
        await game.world.add(Obstacle(ObstacleType.tcu, MamataGame.playerX + 10));
        await tester.pump();
        simulate(game, 0.1);
        expect(game.oranges, MamataGame.maxOranges - 1);
      },
    );

    gameTester.testGameWidget(
      'cidadão revoltado arremessa tomate e o acerto conta como escândalo',
      verify: (game, tester) async {
        game.startLevel(1);
        game.beginCountdown();
        simulate(game, 3.2);
        game.oranges = 0;
        final c = Citizen(MamataGame.playerX + 500, game.rnd);
        await game.world.add(c);
        await tester.pump();
        c.markTaxed(retaliate: true);
        simulate(game, Citizen.windup + 0.05);
        final tomatoes = game.entities.whereType<Obstacle>().where((o) => o.type == ObstacleType.tomate);
        expect(tomatoes, isNotEmpty);
        final gapBefore = game.truthGap;
        simulate(game, 1.5);
        expect(game.hits, 1);
        expect(game.truthGap, lessThan(gapBefore));
        expect(game.phase, GamePhase.playing, reason: 'tomate é escândalo comum, não fim de jogo');
      },
    );

    gameTester.testGameWidget(
      'abaixar desvia do tomate',
      verify: (game, tester) async {
        game.startLevel(1);
        game.beginCountdown();
        simulate(game, 3.2);
        await game.world.add(Obstacle(ObstacleType.tomate, MamataGame.playerX + 300));
        await tester.pump();
        game.slidePressed();
        simulate(game, 1.2);
        expect(game.hits, 0);
      },
    );

    for (final level in levels) {
      gameTester.testGameWidget(
        'fase ${level.number} pode ser concluída por um jogador atento',
        verify: (game, tester) async {
          // As fases são aleatórias e o bot é simples: até 3 tentativas.
          for (var attempt = 0; attempt < 3; attempt++) {
            game.startLevel(level.number);
            game.beginCountdown();
            simulate(game, 3.2);
            var t = 0.0;
            while (game.phase == GamePhase.playing && t < 150) {
              autopilot(game);
              game.update(1 / 60);
              t += 1 / 60;
            }
            if (game.phase == GamePhase.finishing) break;
          }
          expect(game.phase, GamePhase.finishing, reason: 'hits=${game.hits} gap=${game.truthGap}');
          simulate(game, 3);
          expect(game.phase, GamePhase.ended);
          expect(game.lastResult!.completed, isTrue);
          expect(game.lastResult!.stars, inInclusiveRange(1, 3));
          expect(game.money, greaterThan(0));
          await tester.pump();
          expect(StorageService.instance.unlockedLevel, greaterThanOrEqualTo(level.number));
          expect(StorageService.instance.starsFor(level.number), game.lastResult!.stars);
        },
      );
    }

    gameTester.testGameWidget(
      'imposto arremessado taxa o cidadão',
      verify: (game, tester) async {
        game.startLevel(1);
        game.beginCountdown();
        simulate(game, 3.2);
        final before = game.money;
        // força um cidadão no caminho do boleto
        game.world.add(Citizen(MamataGame.playerX + 260, game.rnd));
        await tester.pump();
        game.throwTax();
        simulate(game, 1);
        expect(game.taxes, greaterThanOrEqualTo(1));
        expect(game.money, greaterThan(before));
      },
    );
  });
}


extension _Also<T> on T {
  T also(void Function(T) f) {
    f(this);
    return this;
  }
}
