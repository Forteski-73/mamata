import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/components/obstacle.dart';
import '../game/levels.dart';
import '../game/mamata_game.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../util/format.dart';
import 'widgets.dart';

// ====================================================================== introdução da fase
class LevelIntro extends StatelessWidget {
  const LevelIntro({super.key, required this.game});
  final MamataGame game;

  @override
  Widget build(BuildContext context) {
    final l = game.level;
    final prev = l.number > 1 ? levels[l.number - 2].obstacles : const <ObstacleType>[];
    final news = l.obstacles.where((t) => !prev.contains(t)).toList();
    final meters = (l.length / kMetersFactor).round();
    return ScaledScreen(
      child: Center(
        child: _PopIn(
          child: Panel(
            width: 640,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              StrokeText(l.title.toUpperCase(), size: 64, color: AppColors.yellow, strokeWidth: 12),
              StrokeText(l.subtitle, size: 30),
              const SizedBox(height: 12),
              Text(
                l.description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Color(0xFF37474F), height: 1.3),
              ),
              const SizedBox(height: 12),
              if (news.isNotEmpty) ...[
                const Text('NOVOS ESCÂNDALOS',
                    style: TextStyle(fontFamily: 'Lilita', fontSize: 18, color: AppColors.red)),
                const SizedBox(height: 4),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final t in news)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE0E0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.navy, width: 2),
                        ),
                        child: Text(
                          '${ObstacleInfo.all[t]!.name} · ${ObstacleInfo.all[t]!.hint}',
                          style: const TextStyle(fontSize: 14, color: AppColors.navy, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              Text('Distância: $meters m  ·  Chegada: ${l.finishLabel}',
                  style: const TextStyle(fontFamily: 'Lilita', fontSize: 16, color: AppColors.navy)),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                GameButton(
                  label: 'VOLTAR',
                  color: AppColors.gray,
                  width: 150,
                  height: 56,
                  fontSize: 22,
                  onPressed: game.goToMenu,
                ),
                const SizedBox(width: 16),
                GameButton(
                  label: l.number == 1 ? 'TOMAR POSSE' : 'COMEÇAR',
                  icon: Icons.play_arrow_rounded,
                  width: 280,
                  height: 56,
                  fontSize: 26,
                  onPressed: game.beginCountdown,
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

// ====================================================================== pausa
class PauseMenu extends StatefulWidget {
  const PauseMenu({super.key, required this.game});
  final MamataGame game;

  @override
  State<PauseMenu> createState() => _PauseMenuState();
}

class _PauseMenuState extends State<PauseMenu> {
  @override
  Widget build(BuildContext context) {
    final storage = StorageService.instance;
    final game = widget.game;
    return ScaledScreen(
      child: Center(
        child: Panel(
          width: 420,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const StrokeText('PAUSADO', size: 48, color: AppColors.yellow),
            const SizedBox(height: 4),
            const Text('A Verdade também tirou um cafezinho.',
                style: TextStyle(fontSize: 16, color: Color(0xFF546E7A))),
            const SizedBox(height: 18),
            GameButton(label: 'CONTINUAR', icon: Icons.play_arrow_rounded, width: 300, onPressed: game.resumeGame),
            const SizedBox(height: 10),
            GameButton(
              label: 'REINICIAR',
              icon: Icons.replay_rounded,
              color: AppColors.blue,
              width: 300,
              height: 52,
              fontSize: 22,
              onPressed: game.restartLevel,
            ),
            const SizedBox(height: 10),
            GameButton(
              label: 'MENU',
              icon: Icons.home_rounded,
              color: AppColors.gray,
              width: 300,
              height: 52,
              fontSize: 22,
              onPressed: game.goToMenu,
            ),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              RoundIconButton(
                icon: storage.musicOn ? Icons.music_note_rounded : Icons.music_off_rounded,
                tooltip: 'Música',
                color: storage.musicOn ? AppColors.greenBtn : AppColors.gray,
                onPressed: () {
                  storage.musicOn = !storage.musicOn;
                  if (!storage.musicOn) AudioService.instance.stopMusic();
                  if (storage.musicOn) AudioService.instance.playMusic(Music.game);
                  AudioService.instance.pauseMusic();
                  setState(() {});
                },
              ),
              const SizedBox(width: 16),
              RoundIconButton(
                icon: storage.sfxOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                tooltip: 'Efeitos',
                color: storage.sfxOn ? AppColors.greenBtn : AppColors.gray,
                onPressed: () {
                  storage.sfxOn = !storage.sfxOn;
                  setState(() {});
                },
              ),
              const SizedBox(width: 16),
              RoundIconButton(
                icon: storage.vibrationOn ? Icons.vibration_rounded : Icons.mobile_off_rounded,
                tooltip: 'Vibração',
                color: storage.vibrationOn ? AppColors.greenBtn : AppColors.gray,
                onPressed: () {
                  storage.vibrationOn = !storage.vibrationOn;
                  setState(() {});
                },
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ====================================================================== pego pela verdade
class GameOverScreen extends StatelessWidget {
  const GameOverScreen({super.key, required this.game});
  final MamataGame game;

  @override
  Widget build(BuildContext context) {
    final r = game.lastResult!;
    return ScaledScreen(
      child: Center(
        child: _PopIn(
          child: Transform.rotate(
            angle: -0.02,
            child: Container(
              width: 620,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F0E1),
                border: Border.all(color: AppColors.navy, width: 4),
                boxShadow: const [BoxShadow(color: Color(0x99000000), offset: Offset(0, 12))],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('JORNAL DA VERDADE',
                    style: TextStyle(
                        fontFamily: 'serif', fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF111111))),
                Container(height: 3, color: const Color(0xFF111111), margin: const EdgeInsets.symmetric(vertical: 4)),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('EDIÇÃO EXTRA · ${r.level.title.toUpperCase()} DO MANDATO',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF444444))),
                  const Text('R\$ 0,00', style: TextStyle(fontSize: 12, color: Color(0xFF444444))),
                ]),
                Container(height: 1.5, color: const Color(0xFF111111), margin: const EdgeInsets.symmetric(vertical: 6)),
                const SizedBox(height: 4),
                StrokeText(r.title, size: 40, color: AppColors.red),
                const SizedBox(height: 8),
                Text(
                  r.headline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF222222)),
                ),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _Stat('Desviado', formatMoney(r.money)),
                  _Stat('Impostos', '${r.taxes}'),
                  _Stat('Laranjas usadas', '${r.orangesUsed}'),
                  _Stat('Escândalos', '${r.hits}'),
                ]),
                const SizedBox(height: 18),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  GameButton(
                    label: 'MENU',
                    icon: Icons.home_rounded,
                    color: AppColors.gray,
                    width: 170,
                    height: 56,
                    fontSize: 22,
                    onPressed: game.goToMenu,
                  ),
                  const SizedBox(width: 16),
                  GameButton(
                    label: 'TENTAR DE NOVO',
                    icon: Icons.replay_rounded,
                    width: 300,
                    height: 56,
                    fontSize: 24,
                    onPressed: game.restartLevel,
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.dark = true});
  final String label;
  final String value;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label.toUpperCase(),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: dark ? const Color(0xFF555555) : Colors.white70)),
      Text(value, style: TextStyle(fontFamily: 'Lilita', fontSize: 24, color: dark ? AppColors.navy : Colors.white)),
    ]);
  }
}

// ====================================================================== fim de ano
class LevelComplete extends StatelessWidget {
  const LevelComplete({super.key, required this.game});
  final MamataGame game;

  @override
  Widget build(BuildContext context) {
    final r = game.lastResult!;
    return ScaledScreen(
      child: Center(
        child: _PopIn(
          child: Panel(
            width: 640,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              StrokeText('FIM DO ${r.level.title.toUpperCase()}!', size: 56, color: AppColors.yellow, strokeWidth: 10),
              const Text('A Verdade ficou para trás... por enquanto.',
                  style: TextStyle(fontSize: 17, color: Color(0xFF546E7A))),
              const SizedBox(height: 8),
              _AnimatedStars(stars: r.stars),
              if (r.record)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.navy, width: 3),
                  ),
                  child: const StrokeText('NOVO RECORDE!', size: 18),
                ),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _Stat('Desviado', formatMoney(r.money)),
                _Stat('Aproveitamento', '${(r.percent * 100).round()}%'),
                _Stat('Impostos', '${r.taxes} (${formatMoney(r.taxMoney)})'),
                _Stat('Escândalos', '${r.hits}'),
              ]),
              const SizedBox(height: 18),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                RoundIconButton(icon: Icons.home_rounded, tooltip: 'Menu', color: AppColors.gray, onPressed: game.goToMenu),
                const SizedBox(width: 12),
                RoundIconButton(
                    icon: Icons.replay_rounded, tooltip: 'Repetir', color: AppColors.blue, onPressed: game.restartLevel),
                const SizedBox(width: 16),
                GameButton(
                  label: 'PRÓXIMO ANO',
                  icon: Icons.arrow_forward_rounded,
                  width: 300,
                  height: 58,
                  fontSize: 26,
                  onPressed: game.nextLevel,
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

// ====================================================================== reeleito!
class VictoryScreen extends StatelessWidget {
  const VictoryScreen({super.key, required this.game});
  final MamataGame game;

  @override
  Widget build(BuildContext context) {
    final r = game.lastResult!;
    final storage = StorageService.instance;
    return ScaledScreen(
      dim: const Color(0x8814213D),
      child: Center(
        child: _PopIn(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const _Pulse(child: StrokeText('REELEITO!', size: 120, color: AppColors.yellow, strokeWidth: 20)),
            const StrokeText('Mais 4 anos de mamata garantidos!', size: 30),
            const SizedBox(height: 14),
            _AnimatedStars(stars: r.stars),
            const SizedBox(height: 10),
            Panel(
              color: const Color(0xEE14213D),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _Stat('Desviado no ano 4', formatMoney(r.money), dark: false),
                const SizedBox(width: 30),
                _Stat('Recorde do mandato', formatMoney(storage.totalBestMoney), dark: false),
                const SizedBox(width: 30),
                _Stat('Estrelas', '${storage.totalStars}/12', dark: false),
                const SizedBox(width: 30),
                _Stat('Reeleições', '${storage.reelections}', dark: false),
              ]),
            ),
            const SizedBox(height: 18),
            Row(mainAxisSize: MainAxisSize.min, children: [
              GameButton(
                label: 'MENU',
                icon: Icons.home_rounded,
                color: AppColors.gray,
                width: 170,
                height: 56,
                fontSize: 22,
                onPressed: game.goToMenu,
              ),
              const SizedBox(width: 16),
              GameButton(
                label: 'NOVO MANDATO',
                icon: Icons.how_to_vote_rounded,
                width: 300,
                height: 56,
                fontSize: 24,
                onPressed: () => game.startLevel(1),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ====================================================================== animações
class _PopIn extends StatelessWidget {
  const _PopIn({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Opacity(
        opacity: v.clamp(0, 1),
        child: Transform.scale(scale: 0.6 + 0.4 * v, child: child),
      ),
      child: child,
    );
  }
}

class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});
  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Transform.scale(
          scale: 1 + 0.05 * _c.value,
          child: Transform.rotate(angle: 0.03 * math.sin(_c.value * math.pi * 2), child: child),
        ),
        child: widget.child,
      );
}

class _AnimatedStars extends StatelessWidget {
  const _AnimatedStars({required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 500 + i * 300),
            curve: Interval(i * 0.25, 1, curve: Curves.elasticOut),
            builder: (_, v, _) => Transform.scale(
              scale: i < stars ? v : 1,
              child: Icon(
                Icons.star_rounded,
                size: i == 1 ? 72 : 58,
                color: i < stars ? AppColors.yellow : Colors.black26,
                shadows: i < stars ? const [Shadow(color: AppColors.navy, offset: Offset(3, 3))] : null,
              ),
            ),
          ),
      ],
    );
  }
}
