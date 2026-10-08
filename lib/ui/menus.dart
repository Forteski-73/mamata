import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/components/collectibles.dart';
import '../game/components/obstacle.dart';
import '../game/levels.dart';
import '../game/mamata_game.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../util/format.dart';
import 'widgets.dart';

const String kAppVersion = '1.0.0';

void _show(MamataGame game, String overlay) {
  game.overlays.removeAll(game.overlays.activeOverlays.toList());
  game.overlays.add(overlay);
}

// ====================================================================== menu
class MainMenu extends StatefulWidget {
  const MainMenu({super.key, required this.game});
  final MamataGame game;

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storage = StorageService.instance;
    return ScaledScreen(
      gradient: const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xDD14213D), Color(0x6614213D), Color(0x0014213D)],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(48, 30, 30, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: _c,
              builder: (_, child) => Transform.rotate(
                angle: -0.04 + 0.02 * math.sin(_c.value * math.pi),
                alignment: Alignment.centerLeft,
                child: Transform.scale(scale: 1 + 0.03 * _c.value, alignment: Alignment.centerLeft, child: child),
              ),
              child: const StrokeText('MAMATA', size: 128, color: AppColors.yellow, strokeWidth: 22),
            ),
            const StrokeText('Fuja da Verdade até a Reeleição!', size: 28),
            const SizedBox(height: 26),
            GameButton(
              label: 'JOGAR',
              icon: Icons.play_arrow_rounded,
              width: 300,
              height: 72,
              fontSize: 34,
              onPressed: () => _show(widget.game, 'levels'),
            ),
            const SizedBox(height: 12),
            Row(children: [
              GameButton(
                label: 'COMO JOGAR',
                icon: Icons.help_rounded,
                color: AppColors.blue,
                width: 220,
                height: 54,
                fontSize: 21,
                onPressed: () => _show(widget.game, 'howto'),
              ),
              const SizedBox(width: 12),
              GameButton(
                label: 'AJUSTES',
                icon: Icons.settings_rounded,
                color: AppColors.gray,
                width: 180,
                height: 54,
                fontSize: 21,
                onPressed: () => _show(widget.game, 'settings'),
              ),
            ]),
            const Spacer(),
            Row(children: [
              const Icon(Icons.star_rounded, color: AppColors.yellow, size: 26),
              StrokeText(' ${storage.totalStars}/12', size: 20),
              const SizedBox(width: 20),
              const Icon(Icons.how_to_vote_rounded, color: Colors.white, size: 24),
              StrokeText(' Reeleições: ${storage.reelections}', size: 20),
            ]),
            const SizedBox(height: 8),
            const Text(
              'Obra de ficção e sátira. Personagens, partidos e fatos são fictícios; '
              'qualquer semelhança com a realidade é mera coincidência.',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Roboto'),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================================================================== fases
class LevelSelect extends StatelessWidget {
  const LevelSelect({super.key, required this.game});
  final MamataGame game;

  @override
  Widget build(BuildContext context) {
    final storage = StorageService.instance;
    return ScaledScreen(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(children: [
              RoundIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Voltar', onPressed: () => _show(game, 'menu')),
              const Expanded(child: StrokeText('O MANDATO', size: 44, color: AppColors.yellow)),
              const SizedBox(width: 54),
            ]),
            const SizedBox(height: 6),
            const StrokeText('4 anos de mamata até a reeleição', size: 22),
            const SizedBox(height: 22),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final l in levels)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      child: _LevelCard(
                        level: l,
                        locked: l.number > storage.unlockedLevel,
                        stars: storage.starsFor(l.number),
                        best: storage.bestMoneyFor(l.number),
                        onTap: () => game.startLevel(l.number),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.locked,
    required this.stars,
    required this.best,
    required this.onTap,
  });

  final LevelConfig level;
  final bool locked;
  final int stars;
  final int best;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${level.title}, ${level.subtitle}${locked ? ', bloqueado' : ''}',
      child: GestureDetector(
        onTap: locked
            ? null
            : () {
                AudioService.instance.play(Sfx.click);
                onTap();
              },
        child: Container(
          width: 200,
          height: 330,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.navy, width: 5),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [level.sky.top, level.sky.bottom, level.sky.ground],
              stops: const [0, 0.7, 1],
            ),
            boxShadow: const [BoxShadow(color: Color(0x88000000), offset: Offset(0, 8))],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    StrokeText(level.title.toUpperCase(), size: 40, color: AppColors.yellow),
                    StrokeText(level.subtitle, size: 20),
                    const Spacer(),
                    Icon(
                      level.isFinal ? Icons.how_to_vote_rounded : Icons.account_balance_rounded,
                      size: 72,
                      color: Colors.white,
                      shadows: const [Shadow(color: AppColors.navy, offset: Offset(3, 3))],
                    ),
                    const Spacer(),
                    StarRow(stars: stars, size: 30),
                    const SizedBox(height: 4),
                    StrokeText(best > 0 ? 'Recorde: ${formatMoney(best)}' : 'Sem recorde', size: 15),
                  ],
                ),
              ),
              if (locked)
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xAA000000),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.lock_rounded, color: Colors.white, size: 56),
                      SizedBox(height: 6),
                      StrokeText('Conclua o\nano anterior', size: 18),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ====================================================================== como jogar
class HowToPlay extends StatelessWidget {
  const HowToPlay({super.key, required this.game});
  final MamataGame game;

  @override
  Widget build(BuildContext context) {
    Widget row(Widget icon, String title, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            SizedBox(width: 44, child: Center(child: icon)),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: '$title  ', style: const TextStyle(fontFamily: 'Lilita', fontSize: 19, color: AppColors.navy)),
                  TextSpan(text: text, style: const TextStyle(fontSize: 15, color: Color(0xFF37474F))),
                ]),
              ),
            ),
          ]),
        );
    Icon ic(IconData i, Color c) => Icon(i, color: c, size: 34);
    Widget chip(ObstacleType t) {
      final info = ObstacleInfo.all[t]!;
      return Container(
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE0E0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.navy, width: 2),
        ),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: '${info.name}\n', style: const TextStyle(fontFamily: 'Lilita', fontSize: 15, color: AppColors.red)),
          TextSpan(text: info.hint, style: const TextStyle(fontSize: 12, color: AppColors.navy)),
        ])),
      );
    }

    return ScaledScreen(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Panel(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Column(children: [
            Row(children: [
              RoundIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Voltar', onPressed: () => _show(game, 'menu')),
              const Expanded(child: StrokeText('COMO JOGAR', size: 36, color: AppColors.yellow)),
              const SizedBox(width: 54),
            ]),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Column(children: [
                      row(ic(Icons.visibility_rounded, AppColors.orange), 'A VERDADE',
                          'te persegue. Cada escândalo a aproxima. Se ela te alcançar, acabou a mamata!'),
                      row(ic(Icons.touch_app_rounded, AppColors.blue), 'PULAR',
                          'Toque no lado direito da tela (toque de novo no ar = pulo duplo). Teclado: Espaço.'),
                      row(ic(Icons.south_rounded, AppColors.blue), 'ABAIXAR',
                          'Segure o lado esquerdo da tela. Teclado: seta para baixo.'),
                      row(const Text('R\$', style: TextStyle(fontFamily: 'Lilita', fontSize: 26, color: AppColors.red)),
                          'IMPOSTO', 'Arremesse boletos nos cidadãos (ou esbarre neles) para arrecadar. Teclado: X.'),
                      row(const MoneyIcon(size: 40), 'DINHEIRO', 'Pegue os pacotes. Desvie 60% para ganhar estrela.'),
                      row(const OrangeIcon(size: 38), 'LARANJAS',
                          'Cada laranja assume a culpa por um escândalo — você passa ileso. '
                          'Na CPI/CPMI só o laranjão salva: custa 3 laranjas (com menos, a Verdade te pega)!'),
                      row(ic(Icons.how_to_vote_rounded, AppColors.green), 'OBJETIVO',
                          'Chegue ao fim de cada ano do mandato e, no 4º ano, à urna da Reeleição.'),
                    ]),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('ESCÂNDALOS', style: TextStyle(fontFamily: 'Lilita', fontSize: 22, color: AppColors.navy)),
                      Wrap(children: [for (final t in ObstacleType.values) chip(t)]),
                      const SizedBox(height: 8),
                      const Text('PODERES', style: TextStyle(fontFamily: 'Lilita', fontSize: 22, color: AppColors.navy)),
                      for (final p in PowerUpType.values)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: p.color,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.navy, width: 2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text.rich(TextSpan(children: [
                                TextSpan(
                                    text: '${p.title}: ',
                                    style: const TextStyle(fontFamily: 'Lilita', fontSize: 15, color: AppColors.navy)),
                                TextSpan(text: p.description, style: const TextStyle(fontSize: 13)),
                              ])),
                            ),
                          ]),
                        ),
                      const SizedBox(height: 8),
                      const Text(
                        '★ Estrelas: concluir o ano · no máximo 1 escândalo · desviar 60% do dinheiro.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF37474F)),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ====================================================================== ajustes
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.game});
  final MamataGame game;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final storage = StorageService.instance;

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar progresso?'),
        content: const Text('Fases desbloqueadas, estrelas e recordes serão apagados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Apagar')),
        ],
      ),
    );
    if (ok == true) {
      await storage.resetProgress();
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(content: Text('Progresso apagado.')));
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget toggle(IconData icon, String label, bool value, ValueChanged<bool> onChanged) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Icon(icon, color: AppColors.navy, size: 30),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontFamily: 'Lilita', fontSize: 24, color: AppColors.navy))),
            Switch(value: value, onChanged: onChanged, activeTrackColor: AppColors.greenBtn),
          ]),
        );

    return ScaledScreen(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 20),
        child: Panel(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
          child: Column(children: [
            Row(children: [
              RoundIconButton(
                  icon: Icons.arrow_back_rounded, tooltip: 'Voltar', onPressed: () => _show(widget.game, 'menu')),
              const Expanded(child: StrokeText('AJUSTES', size: 36, color: AppColors.yellow)),
              const SizedBox(width: 54),
            ]),
            const SizedBox(height: 8),
            toggle(Icons.music_note_rounded, 'Música', storage.musicOn, (v) {
              AudioService.instance.setMusicEnabled(v);
              setState(() {});
            }),
            toggle(Icons.volume_up_rounded, 'Efeitos sonoros', storage.sfxOn, (v) {
              storage.sfxOn = v;
              setState(() {});
            }),
            toggle(Icons.vibration_rounded, 'Vibração', storage.vibrationOn, (v) {
              storage.vibrationOn = v;
              setState(() {});
            }),
            const SizedBox(height: 10),
            GameButton(
              label: 'APAGAR PROGRESSO',
              icon: Icons.delete_forever_rounded,
              color: AppColors.red,
              width: 340,
              height: 50,
              fontSize: 20,
              onPressed: _confirmReset,
            ),
            const Spacer(),
            const Text(
              'Privacidade: o Mamata não coleta, não envia e não compartilha nenhum dado pessoal. '
              'O progresso fica salvo apenas neste aparelho.\n'
              'Fonte Lilita One (SIL Open Font License). Versão $kAppVersion',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF546E7A)),
            ),
          ]),
        ),
      ),
    );
  }
}
