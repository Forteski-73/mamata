import 'package:flutter/material.dart';

import '../game/paint_utils.dart' as pu;
import '../services/audio_service.dart';

class AppColors {
  static const navy = Color(0xFF14213D);
  static const navyLight = Color(0xFF1F3366);
  static const yellow = Color(0xFFFFD60A);
  static const green = Color(0xFF009C3B);
  static const greenBtn = Color(0xFF2EB82E);
  static const blue = Color(0xFF1E88E5);
  static const red = Color(0xFFE53935);
  static const orange = Color(0xFFFF8C00);
  static const paper = Color(0xFFFFF8E7);
  static const gray = Color(0xFF607D8B);
}

/// Texto com contorno grosso, estilo cartoon.
class StrokeText extends StatelessWidget {
  const StrokeText(
    this.text, {
    super.key,
    this.size = 24,
    this.color = Colors.white,
    this.strokeColor = AppColors.navy,
    this.strokeWidth,
    this.align = TextAlign.center,
    this.letterSpacing = 0,
  });

  final String text;
  final double size;
  final Color color;
  final Color strokeColor;
  final double? strokeWidth;
  final TextAlign align;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontFamily: pu.kFont, fontSize: size, height: 1.05, letterSpacing: letterSpacing);
    return Stack(
      children: [
        Text(
          text,
          textAlign: align,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth ?? size * 0.18
              ..strokeJoin = StrokeJoin.round
              ..color = strokeColor,
          ),
        ),
        Text(text, textAlign: align, style: style.copyWith(color: color)),
      ],
    );
  }
}

/// Botão "gordinho" com sombra e animação de clique.
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.greenBtn,
    this.icon,
    this.width,
    this.height = 64,
    this.fontSize = 26,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;
  final double? width;
  final double height;
  final double fontSize;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final color = enabled ? widget.color : Colors.grey;
    final dark = Color.lerp(color, Colors.black, 0.35)!;
    const depth = 6.0;
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled
            ? (_) {
                setState(() => _down = false);
                AudioService.instance.play(Sfx.click);
                widget.onPressed!();
              }
            : null,
        child: SizedBox(
          width: widget.width,
          height: widget.height + depth,
          child: Stack(
            children: [
              Positioned.fill(
                top: depth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: dark,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.navy, width: 3),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 60),
                left: 0,
                right: 0,
                top: _down ? depth : 0,
                height: widget.height,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color.lerp(color, Colors.white, 0.25)!, color],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.navy, width: 3),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: Colors.white, size: widget.fontSize * 1.1,
                            shadows: const [Shadow(color: AppColors.navy, offset: Offset(2, 2))]),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: StrokeText(widget.label, size: widget.fontSize),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botão redondo só com ícone.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = AppColors.navyLight,
    this.size = 54,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        onTap: () {
          AudioService.instance.play(Sfx.click);
          onPressed();
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.navy, width: 3),
            boxShadow: const [BoxShadow(color: Color(0x66000000), offset: Offset(0, 4))],
          ),
          child: Icon(icon, color: Colors.white, size: size * 0.55),
        ),
      ),
    );
  }
}

/// Painel com borda grossa.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.color = AppColors.paper,
    this.padding = const EdgeInsets.all(24),
    this.width,
  });

  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.navy, width: 5),
        boxShadow: const [BoxShadow(color: Color(0x88000000), offset: Offset(0, 10), blurRadius: 0)],
      ),
      child: child,
    );
  }
}

/// Área de design fixa (960x540) que escala para qualquer tela.
class ScaledScreen extends StatelessWidget {
  const ScaledScreen({super.key, required this.child, this.dim = const Color(0x99000000), this.gradient});

  final Widget child;
  final Color? dim;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: gradient == null ? dim : null, gradient: gradient),
      child: SafeArea(
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(width: 960, height: 540, child: child),
          ),
        ),
      ),
    );
  }
}

class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.size = 28, this.max = 3});

  final int stars;
  final double size;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < max; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size * 0.06),
            child: Icon(
              Icons.star_rounded,
              size: size,
              color: i < stars ? AppColors.yellow : Colors.black26,
              shadows: i < stars ? const [Shadow(color: AppColors.navy, offset: Offset(1.5, 1.5))] : null,
            ),
          ),
      ],
    );
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.kind);
  final String kind;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2 + size.height * 0.06);
    final r = size.shortestSide * 0.36;
    if (kind == 'orange') {
      pu.drawOrange(canvas, c, r);
    } else {
      pu.drawMoneyBag(canvas, c, r);
    }
  }

  @override
  bool shouldRepaint(covariant _IconPainter old) => old.kind != kind;
}

class OrangeIcon extends StatelessWidget {
  const OrangeIcon({super.key, this.size = 32});
  final double size;
  @override
  Widget build(BuildContext context) =>
      SizedBox.square(dimension: size, child: CustomPaint(painter: _IconPainter('orange')));
}

class MoneyIcon extends StatelessWidget {
  const MoneyIcon({super.key, this.size = 32});
  final double size;
  @override
  Widget build(BuildContext context) =>
      SizedBox.square(dimension: size, child: CustomPaint(painter: _IconPainter('money')));
}
