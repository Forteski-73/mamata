import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/paint_utils.dart' as pu;

/// Foto de fichamento do "laranjão" preso no lugar do político.
class MugshotCard extends StatelessWidget {
  const MugshotCard({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final height = width * 1.2;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: Transform.rotate(
              angle: -0.05,
              child: Container(
                padding: EdgeInsets.all(width * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 12, offset: Offset(0, 8))],
                ),
                child: ClipRect(child: CustomPaint(painter: _MugshotPainter())),
              ),
            ),
          ),
          // flash da câmera da PF
          Positioned.fill(
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 1, end: 0),
                duration: const Duration(milliseconds: 450),
                builder: (_, v, _) => Container(color: Colors.white.withValues(alpha: v * 0.9)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MugshotPainter extends CustomPainter {
  void _text(Canvas c, String text, Offset center, double size, Color color, {Color? stroke}) {
    final style = TextStyle(fontFamily: pu.kFont, fontSize: size, height: 1);
    if (stroke != null) {
      final s = TextPainter(
        text: TextSpan(
          text: text,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = size * 0.18
              ..color = stroke,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      s.paint(c, center - Offset(s.width / 2, s.height / 2));
    }
    final f = TextPainter(
      text: TextSpan(text: text, style: style.copyWith(color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    f.paint(c, center - Offset(f.width / 2, f.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final outline = pu.stroke(pu.kOutline, w * 0.014);

    // parede de fichamento com régua de altura
    canvas.drawRect(Offset.zero & size, pu.fill(const Color(0xFF8FA3B8)));
    for (var i = 0; i < 8; i++) {
      final y = h * (0.08 + i * 0.1);
      canvas.drawLine(Offset(0, y), Offset(w, y), pu.stroke(const Color(0x66FFFFFF), i.isEven ? 2.5 : 1.2));
      if (i.isEven) {
        _text(canvas, '1,${(9 - i).toString()}0', Offset(w * 0.08, y - h * 0.025), w * 0.045, const Color(0xCCFFFFFF));
      }
    }

    // ombros com uniforme listrado de presidiário
    final body = Path()
      ..moveTo(w * 0.08, h)
      ..quadraticBezierTo(w * 0.12, h * 0.62, w * 0.5, h * 0.6)
      ..quadraticBezierTo(w * 0.88, h * 0.62, w * 0.92, h)
      ..close();
    canvas.save();
    canvas.clipPath(body);
    canvas.drawRect(Offset.zero & size, pu.fill(Colors.white));
    for (var y = h * 0.6; y < h; y += h * 0.055) {
      canvas.drawRect(Rect.fromLTWH(0, y, w, h * 0.0275), pu.fill(const Color(0xFF1B1B1B)));
    }
    canvas.restore();
    canvas.drawPath(body, outline);

    // cabeça: uma laranja enorme
    final head = Offset(w * 0.5, h * 0.4);
    final r = w * 0.26;
    canvas.drawCircle(head, r, pu.fill(const Color(0xFFFF8C00)));
    final rnd = math.Random(171);
    for (var i = 0; i < 40; i++) {
      final a = rnd.nextDouble() * math.pi * 2;
      final d = rnd.nextDouble() * r * 0.9;
      canvas.drawCircle(head + Offset(math.cos(a) * d, math.sin(a) * d), w * 0.006, pu.fill(const Color(0x55B85C00)));
    }
    canvas.drawCircle(head + Offset(-r * 0.4, -r * 0.45), r * 0.22, pu.fill(const Color(0x55FFE0A0)));
    canvas.drawCircle(head, r, outline);
    // cabinho e folha
    canvas.drawLine(head + Offset(0, -r), head + Offset(r * 0.05, -r * 1.15), pu.stroke(const Color(0xFF5D4037), w * 0.02));
    final leaf = Path()
      ..moveTo(head.dx + r * 0.05, head.dy - r * 1.1)
      ..quadraticBezierTo(head.dx + r * 0.5, head.dy - r * 1.5, head.dx + r * 0.8, head.dy - r * 1.05)
      ..quadraticBezierTo(head.dx + r * 0.4, head.dy - r * 0.95, head.dx + r * 0.05, head.dy - r * 1.1);
    canvas.drawPath(leaf, pu.fill(const Color(0xFF43A047)));
    canvas.drawPath(leaf, pu.stroke(pu.kOutline, w * 0.008));

    // rosto de bandidão
    final browL = Path()
      ..moveTo(head.dx - r * 0.62, head.dy - r * 0.38)
      ..lineTo(head.dx - r * 0.12, head.dy - r * 0.18);
    final browR = Path()
      ..moveTo(head.dx + r * 0.62, head.dy - r * 0.38)
      ..lineTo(head.dx + r * 0.12, head.dy - r * 0.18);
    canvas.drawPath(browL, pu.stroke(const Color(0xFF1B1B1B), w * 0.035));
    canvas.drawPath(browR, pu.stroke(const Color(0xFF1B1B1B), w * 0.035));
    // olho esquerdo apertado, direito encarando
    canvas.drawLine(head + Offset(-r * 0.48, -r * 0.05), head + Offset(-r * 0.2, -r * 0.02),
        pu.stroke(const Color(0xFF1B1B1B), w * 0.018));
    canvas.drawCircle(head + Offset(r * 0.34, -r * 0.04), r * 0.13, pu.fill(Colors.white));
    canvas.drawCircle(head + Offset(r * 0.32, -r * 0.02), r * 0.07, pu.fill(const Color(0xFF1B1B1B)));
    // cicatriz
    final scar = head + Offset(-r * 0.62, r * 0.12);
    canvas.drawLine(scar, scar + Offset(r * 0.28, r * 0.32), pu.stroke(const Color(0xFF9E3D00), w * 0.012));
    for (var i = 0; i < 3; i++) {
      final p = scar + Offset(r * 0.07 * (i + 1), r * 0.08 * (i + 1));
      canvas.drawLine(p + Offset(-r * 0.06, r * 0.04), p + Offset(r * 0.06, -r * 0.04),
          pu.stroke(const Color(0xFF9E3D00), w * 0.008));
    }
    // barba por fazer
    for (var i = 0; i < 26; i++) {
      final a = math.pi * (0.15 + 0.7 * rnd.nextDouble());
      final d = r * (0.55 + 0.35 * rnd.nextDouble());
      canvas.drawCircle(head + Offset(math.cos(a) * d, math.sin(a) * d), w * 0.006, pu.fill(const Color(0x993E2723)));
    }
    // boca torta com dente de ouro e palito
    final mouth = Path()
      ..moveTo(head.dx - r * 0.3, head.dy + r * 0.45)
      ..quadraticBezierTo(head.dx, head.dy + r * 0.35, head.dx + r * 0.32, head.dy + r * 0.38);
    canvas.drawPath(mouth, pu.stroke(const Color(0xFF4E1A00), w * 0.02));
    canvas.drawRect(Rect.fromLTWH(head.dx + r * 0.02, head.dy + r * 0.38, r * 0.1, r * 0.1), pu.fill(const Color(0xFFFFD60A)));
    canvas.drawLine(head + Offset(r * 0.3, r * 0.38), head + Offset(r * 0.72, r * 0.26), pu.stroke(const Color(0xFFD7B57A), w * 0.012));

    // placa de identificação
    final plate = Rect.fromLTWH(w * 0.18, h * 0.72, w * 0.64, h * 0.2);
    canvas.drawLine(Offset(plate.left + w * 0.05, plate.top), Offset(w * 0.3, h * 0.66), pu.stroke(const Color(0xFF9E9E9E), 2));
    canvas.drawLine(Offset(plate.right - w * 0.05, plate.top), Offset(w * 0.7, h * 0.66), pu.stroke(const Color(0xFF9E9E9E), 2));
    canvas.drawRRect(RRect.fromRectAndRadius(plate, Radius.circular(w * 0.02)), pu.fill(const Color(0xFF1B1B1B)));
    _text(canvas, 'LARANJÃO', plate.center - Offset(0, plate.height * 0.18), w * 0.09, Colors.white);
    _text(canvas, 'Nº 171 · POLÍCIA FEDERAL', plate.center + Offset(0, plate.height * 0.26), w * 0.04, const Color(0xFFFFD60A));

    // carimbo PRESO
    canvas.save();
    canvas.translate(w * 0.78, h * 0.12);
    canvas.rotate(0.35);
    final stamp = Rect.fromCenter(center: Offset.zero, width: w * 0.38, height: h * 0.1);
    canvas.drawRRect(RRect.fromRectAndRadius(stamp, Radius.circular(w * 0.02)), pu.stroke(const Color(0xDDD62828), w * 0.014));
    _text(canvas, 'PRESO', Offset.zero, w * 0.085, const Color(0xDDD62828));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
