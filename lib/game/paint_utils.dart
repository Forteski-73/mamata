import 'dart:math' as math;

import 'package:flutter/painting.dart';

const String kFont = 'Lilita';

/// Texto pré-diagramado com contorno, para desenhar no Canvas do Flame.
class Label {
  Label(
    String text, {
    double size = 20,
    Color color = const Color(0xFFFFFFFF),
    Color? stroke = const Color(0xFF14213D),
    double strokeWidth = 4,
    double letterSpacing = 0,
  }) {
    final base = TextStyle(
      fontFamily: kFont,
      fontSize: size,
      letterSpacing: letterSpacing,
      height: 1.0,
    );
    _fill = TextPainter(
      text: TextSpan(text: text, style: base.copyWith(color: color)),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    if (stroke != null) {
      _stroke = TextPainter(
        text: TextSpan(
          text: text,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..strokeJoin = StrokeJoin.round
              ..color = stroke,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
    }
  }

  late final TextPainter _fill;
  TextPainter? _stroke;

  Size get size => _fill.size;

  void paintCentered(Canvas canvas, Offset center) {
    final o = center - Offset(_fill.width / 2, _fill.height / 2);
    _stroke?.paint(canvas, o);
    _fill.paint(canvas, o);
  }
}

Paint fill(Color c) => Paint()..color = c;

Paint stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

const Color kOutline = Color(0xFF14213D);

/// Retângulo arredondado com contorno escuro (estilo cartoon).
void cartoonRRect(Canvas c, Rect r, Color color, {double radius = 8, double outline = 3}) {
  final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
  c.drawRRect(rr, fill(color));
  if (outline > 0) c.drawRRect(rr, stroke(kOutline, outline));
}

void cartoonCircle(Canvas c, Offset o, double r, Color color, {double outline = 3}) {
  c.drawCircle(o, r, fill(color));
  if (outline > 0) c.drawCircle(o, r, stroke(kOutline, outline));
}

/// Sombra elíptica no chão.
void groundShadow(Canvas c, Offset center, double w, {double alpha = 0.25}) {
  c.drawOval(
    Rect.fromCenter(center: center, width: w, height: w * 0.18),
    fill(Color.fromRGBO(0, 0, 0, alpha)),
  );
}

/// Desenha um saquinho de dinheiro centrado em [o], com raio aproximado [r].
void drawMoneyBag(Canvas c, Offset o, double r, {Label? label}) {
  final body = Rect.fromCenter(center: o.translate(0, r * 0.15), width: r * 2, height: r * 1.8);
  final neck = Path()
    ..moveTo(o.dx - r * 0.35, o.dy - r * 0.6)
    ..lineTo(o.dx - r * 0.6, o.dy - r * 1.05)
    ..lineTo(o.dx + r * 0.6, o.dy - r * 1.05)
    ..lineTo(o.dx + r * 0.35, o.dy - r * 0.6)
    ..close();
  c.drawPath(neck, fill(const Color(0xFFC8913F)));
  c.drawPath(neck, stroke(kOutline, 2.5));
  c.drawOval(body, fill(const Color(0xFFD9A24A)));
  c.drawOval(body, stroke(kOutline, 2.5));
  c.drawRect(
    Rect.fromLTWH(o.dx - r * 0.42, o.dy - r * 0.72, r * 0.84, r * 0.2),
    fill(const Color(0xFFD62828)),
  );
  c.drawOval(
    Rect.fromLTWH(o.dx - r * 0.7, o.dy - r * 0.35, r * 0.4, r * 0.3),
    fill(const Color(0x55FFFFFF)),
  );
  label?.paintCentered(c, o.translate(0, r * 0.25));
}

/// Desenha uma laranja centrada em [o].
void drawOrange(Canvas c, Offset o, double r) {
  c.drawCircle(o, r, fill(const Color(0xFFFF8C00)));
  c.drawCircle(
    o.translate(-r * 0.3, -r * 0.3),
    r * 0.3,
    fill(const Color(0x66FFE0A0)),
  );
  c.drawCircle(o, r, stroke(kOutline, 2.5));
  final leaf = Path()
    ..moveTo(o.dx, o.dy - r * 0.9)
    ..quadraticBezierTo(o.dx + r * 0.5, o.dy - r * 1.6, o.dx + r * 0.95, o.dy - r * 1.05)
    ..quadraticBezierTo(o.dx + r * 0.45, o.dy - r * 0.75, o.dx, o.dy - r * 0.9);
  c.drawPath(leaf, fill(const Color(0xFF43A047)));
  c.drawPath(leaf, stroke(kOutline, 2));
}

/// Estrela de 5 pontas.
Path starPath(Offset c, double outer, double inner) {
  final p = Path();
  for (var i = 0; i < 10; i++) {
    final r = i.isEven ? outer : inner;
    final a = -math.pi / 2 + i * math.pi / 5;
    final pt = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  return p..close();
}

Color lerpColor(Color a, Color b, double t) => Color.lerp(a, b, t.clamp(0, 1))!;
