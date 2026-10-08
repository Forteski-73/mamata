import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/mamata_game.dart';
import '../util/format.dart';
import 'mugshot.dart';
import 'widgets.dart';

/// HUD + zona de toque: esquerda segura = abaixar, direita = pular.
class Hud extends StatelessWidget {
  const Hud({super.key, required this.game});

  final MamataGame game;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final s = (box.maxHeight / 400).clamp(0.75, 1.6);
      final slideZone = box.maxWidth * 0.38;
      return Stack(
        children: [
          // zona de toque (por baixo de tudo)
          Positioned.fill(child: _TouchZone(game: game, slideZoneWidth: slideZone)),

          // vinheta de perigo
          Positioned.fill(
            child: IgnorePointer(
              child: ValueListenableBuilder<double>(
                valueListenable: game.dangerN,
                builder: (_, d, _) {
                  final a = ((d - 0.55) / 0.45).clamp(0.0, 1.0);
                  if (a <= 0) return const SizedBox.shrink();
                  return _DangerVignette(intensity: a);
                },
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(10 * s),
              child: Stack(
                children: [
                  // topo esquerdo: dinheiro e laranjas
                  Positioned(
                    left: 0,
                    top: 0,
                    child: IgnorePointer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Chip(
                            scale: s,
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              MoneyIcon(size: 30 * s),
                              SizedBox(width: 6 * s),
                              ValueListenableBuilder<int>(
                                valueListenable: game.moneyN,
                                builder: (_, m, _) =>
                                    StrokeText(formatMoney(m), size: 20 * s, color: const Color(0xFF9CFF57)),
                              ),
                            ]),
                          ),
                          SizedBox(height: 6 * s),
                          _Chip(
                            scale: s,
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              OrangeIcon(size: 28 * s),
                              SizedBox(width: 6 * s),
                              ValueListenableBuilder<int>(
                                valueListenable: game.orangesN,
                                builder: (_, o, _) => StrokeText('x$o', size: 20 * s, color: const Color(0xFFFFB74D)),
                              ),
                            ]),
                          ),
                          SizedBox(height: 6 * s),
                          ValueListenableBuilder<PowerStatus?>(
                            valueListenable: game.powerN,
                            builder: (_, p, _) => p == null ? const SizedBox.shrink() : _PowerChip(status: p, scale: s),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // topo central: progresso + verdade
                  Align(
                    alignment: Alignment.topCenter,
                    child: IgnorePointer(
                      child: SizedBox(
                        width: math.min(box.maxWidth * 0.42, 420 * s),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ProgressBar(game: game, scale: s),
                            SizedBox(height: 6 * s),
                            _TruthMeter(game: game, scale: s),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // topo direito: pausa
                  Positioned(
                    right: 0,
                    top: 0,
                    child: RoundIconButton(
                      icon: Icons.pause_rounded,
                      size: 48 * s,
                      tooltip: 'Pausar',
                      onPressed: game.pauseGame,
                    ),
                  ),

                  // botão de imposto
                  Positioned(
                    right: 6 * s,
                    bottom: 6 * s,
                    child: _TaxButton(game: game, scale: s),
                  ),

                  // dicas de controle
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: game.hintsN,
                        builder: (_, show, _) => AnimatedOpacity(
                          opacity: show ? 1 : 0,
                          duration: const Duration(milliseconds: 400),
                          child: _Hints(scale: s, slideZone: slideZone - 20 * s),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // banner central
          Positioned(
            left: 0,
            right: 0,
            top: box.maxHeight * 0.24,
            child: IgnorePointer(
              child: ValueListenableBuilder<BannerMsg?>(
                valueListenable: game.bannerN,
                builder: (_, b, _) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: b == null
                      ? const SizedBox.shrink()
                      : Column(
                          key: ValueKey(b.id),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StrokeText(b.title, size: 30 * s, color: b.color),
                            if (b.subtitle != null) ...[
                              SizedBox(height: 4 * s),
                              StrokeText(b.subtitle!, size: 17 * s),
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ),

          // foto do laranjão preso
          Align(
            alignment: const Alignment(0.72, -0.05),
            child: IgnorePointer(
              child: ValueListenableBuilder<bool>(
                valueListenable: game.mugshotN,
                builder: (_, show, _) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: show
                      ? MugshotCard(key: const ValueKey('mugshot'), width: box.maxHeight * 0.38)
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),

          // contagem regressiva
          Center(
            child: IgnorePointer(
              child: ValueListenableBuilder<String?>(
                valueListenable: game.countdownN,
                builder: (_, c, _) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: Tween(begin: 2.2, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: c == null
                      ? const SizedBox.shrink()
                      : StrokeText(c, key: ValueKey(c), size: 90 * s, color: AppColors.yellow),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _TouchZone extends StatefulWidget {
  const _TouchZone({required this.game, required this.slideZoneWidth});
  final MamataGame game;
  final double slideZoneWidth;

  @override
  State<_TouchZone> createState() => _TouchZoneState();
}

class _TouchZoneState extends State<_TouchZone> {
  final Set<int> _slidePointers = {};

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) {
        if (e.localPosition.dx < widget.slideZoneWidth) {
          _slidePointers.add(e.pointer);
          widget.game.slidePressed();
        } else {
          widget.game.jumpPressed();
        }
      },
      onPointerUp: (e) => _release(e.pointer),
      onPointerCancel: (e) => _release(e.pointer),
      child: const SizedBox.expand(),
    );
  }

  void _release(int pointer) {
    if (_slidePointers.remove(pointer) && _slidePointers.isEmpty) {
      widget.game.slideReleased();
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.child, required this.scale});
  final Widget child;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 4 * scale),
      decoration: BoxDecoration(
        color: const Color(0xAA14213D),
        borderRadius: BorderRadius.circular(30 * scale),
        border: Border.all(color: const Color(0x55FFFFFF), width: 2),
      ),
      child: child,
    );
  }
}

class _PowerChip extends StatelessWidget {
  const _PowerChip({required this.status, required this.scale});
  final PowerStatus status;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return _Chip(
      scale: scale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          StrokeText(status.label, size: 13 * scale, color: status.color),
          SizedBox(height: 3 * scale),
          SizedBox(
            width: 120 * scale,
            height: 6 * scale,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: status.ratio.clamp(0, 1),
                backgroundColor: Colors.white24,
                color: status.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.game, required this.scale});
  final MamataGame game;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            StrokeText('${game.level.title.toUpperCase()} · ${game.level.subtitle}', size: 14 * s),
            StrokeText(game.level.finishLabel, size: 14 * s, color: AppColors.yellow),
          ],
        ),
        SizedBox(height: 4 * s),
        SizedBox(
          height: 18 * s,
          child: ValueListenableBuilder<double>(
            valueListenable: game.progressN,
            builder: (_, p, _) => LayoutBuilder(builder: (context, c) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xAA14213D),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: p.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.green, AppColors.yellow]),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (c.maxWidth - 22 * s) * p.clamp(0.0, 1.0),
                    top: -6 * s,
                    child: Container(
                      width: 22 * s,
                      height: 30 * s,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2A44),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(Icons.directions_run_rounded, size: 16 * s, color: Colors.white),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _TruthMeter extends StatelessWidget {
  const _TruthMeter({required this.game, required this.scale});
  final MamataGame game;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return ValueListenableBuilder<double>(
      valueListenable: game.dangerN,
      builder: (_, d, _) {
        final color = Color.lerp(const Color(0xFF66BB6A), const Color(0xFFFF1744), d)!;
        final meters = (game.truthGap.clamp(0, 9999) / 40).round();
        return Row(
          children: [
            Icon(Icons.visibility_rounded, color: AppColors.yellow, size: 18 * s,
                shadows: const [Shadow(color: AppColors.navy, blurRadius: 2)]),
            SizedBox(width: 4 * s),
            StrokeText('VERDADE', size: 13 * s, color: AppColors.yellow),
            SizedBox(width: 6 * s),
            Expanded(
              child: Container(
                height: 10 * s,
                decoration: BoxDecoration(
                  color: const Color(0xAA14213D),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white70, width: 1.5),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: d.clamp(0.02, 1.0),
                  child: Container(
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
            SizedBox(width: 6 * s),
            StrokeText('${meters}m', size: 13 * s, color: color),
          ],
        );
      },
    );
  }
}

class _TaxButton extends StatelessWidget {
  const _TaxButton({required this.game, required this.scale});
  final MamataGame game;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final size = 92 * scale;
    return Semantics(
      button: true,
      label: 'Cobrar imposto',
      child: Listener(
        onPointerDown: (_) => game.throwTax(),
        child: ValueListenableBuilder<double>(
          valueListenable: game.taxCooldownN,
          builder: (_, cd, _) => SizedBox.square(
            dimension: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(colors: [Color(0xFFFF6F61), Color(0xFFC62828)]),
                    border: Border.all(color: AppColors.navy, width: 4),
                    boxShadow: const [BoxShadow(color: Color(0x88000000), offset: Offset(0, 5))],
                  ),
                ),
                if (cd > 0)
                  SizedBox.square(
                    dimension: size - 8,
                    child: CircularProgressIndicator(
                      value: 1 - cd,
                      strokeWidth: 5 * scale,
                      color: Colors.white70,
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StrokeText('R\$', size: 30 * scale, color: AppColors.yellow),
                    StrokeText('IMPOSTO', size: 13 * scale),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hints extends StatelessWidget {
  const _Hints({required this.scale, required this.slideZone});
  final double scale;
  final double slideZone;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    Widget hint(IconData icon, String title, String sub) => Container(
          padding: EdgeInsets.all(10 * s),
          decoration: BoxDecoration(
            color: const Color(0x8814213D),
            borderRadius: BorderRadius.circular(16 * s),
            border: Border.all(color: Colors.white54, width: 2),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.white, size: 34 * s),
            StrokeText(title, size: 18 * s, color: AppColors.yellow),
            StrokeText(sub, size: 13 * s),
          ]),
        );
    return Stack(children: [
      Positioned(
        left: 0,
        top: 150 * s,
        width: slideZone,
        child: Center(child: hint(Icons.touch_app_rounded, 'SEGURE AQUI', 'para abaixar')),
      ),
      Positioned(
        right: 140 * s,
        top: 150 * s,
        child: hint(Icons.touch_app_rounded, 'TOQUE AQUI', 'pula (2x = pulo duplo)'),
      ),
      Positioned(
        right: 0,
        bottom: 110 * s,
        child: StrokeText('Taxe os cidadãos! ↓', size: 14 * s, color: const Color(0xFF9CFF57)),
      ),
    ]);
  }
}

class _DangerVignette extends StatefulWidget {
  const _DangerVignette({required this.intensity});
  final double intensity;

  @override
  State<_DangerVignette> createState() => _DangerVignetteState();
}

class _DangerVignetteState extends State<_DangerVignette> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 1.1,
            colors: [
              Colors.transparent,
              Colors.transparent,
              const Color(0xFFFF1744).withValues(alpha: widget.intensity * (0.25 + 0.25 * _c.value)),
            ],
            stops: const [0, 0.6, 1],
          ),
        ),
      ),
    );
  }
}
