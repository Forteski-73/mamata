import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../mamata_game.dart';
import '../paint_utils.dart';
import 'entity.dart';

/// Pórtico de chegada da fase (na última fase, a urna da Reeleição).
class FinishLine extends Entity {
  FinishLine(double x, String text, {required this.reelection})
      : _label = Label(text, size: reelection ? 34 : 26, color: const Color(0xFFFFD60A), strokeWidth: 6),
        super(size: Vector2(reelection ? 420 : 300, 330), priority: 1) {
    position = Vector2(x, MamataGame.groundY - size.y);
  }

  final bool reelection;
  final Label _label;
  static final _urna = Label('URNA', size: 14, color: const Color(0xFF263238), stroke: null);
  static final _confirma = Label('CONFIRMA', size: 10, stroke: null);
  static final _sub = Label('rumo à Reeleição', size: 14, strokeWidth: 3);

  bool crossed = false;

  @override
  Rect get hitbox => Rect.zero;

  @override
  void onPlayerContact() {}

  @override
  void render(Canvas canvas) {
    const archW = 300.0;
    final h = height;
    // postes
    for (final px in [10.0, archW - 30]) {
      cartoonRRect(canvas, Rect.fromLTWH(px, 40, 20, h - 40), const Color(0xFFECEFF1), radius: 4);
      for (var i = 0; i < 6; i++) {
        canvas.drawRect(Rect.fromLTWH(px + 3, 60.0 + i * 44, 14, 20),
            fill(i.isEven ? const Color(0xFF009C3B) : const Color(0xFFFFDF00)));
      }
    }
    // faixa
    final wave = math.sin(age * 4) * 3;
    final banner = Rect.fromLTWH(0, 20 + wave, archW, 74);
    cartoonRRect(canvas, banner, const Color(0xFF002776), radius: 10, outline: 4);
    // xadrez
    for (var i = 0; i < 20; i++) {
      canvas.drawRect(Rect.fromLTWH(6 + i * 14.4, banner.bottom - 14, 14.4, 7),
          fill(i.isEven ? const Color(0xFFFFFFFF) : kOutline));
      canvas.drawRect(Rect.fromLTWH(6 + i * 14.4, banner.bottom - 7, 14.4, 5),
          fill(i.isOdd ? const Color(0xFFFFFFFF) : kOutline));
    }
    _label.paintCentered(canvas, Offset(archW / 2, banner.top + 26));
    if (!reelection) _sub.paintCentered(canvas, Offset(archW / 2, banner.top + 50));

    // bandeirinhas (festa)
    for (var i = 0; i < 9; i++) {
      final bx = 30.0 + i * 30;
      final by = banner.bottom + 10 + math.sin(i + age * 3) * 2;
      final p = Path()
        ..moveTo(bx, by)
        ..lineTo(bx + 20, by)
        ..lineTo(bx + 10, by + 16)
        ..close();
      const colors = [Color(0xFF009C3B), Color(0xFFFFDF00), Color(0xFF002776), Color(0xFFFFFFFF)];
      canvas.drawPath(p, fill(colors[i % 4]));
    }

    if (reelection) {
      // urna eletrônica gigante
      final u = Rect.fromLTWH(320, h - 150, 96, 150);
      cartoonRRect(canvas, Rect.fromLTWH(u.left + 30, u.top + 60, 30, u.height - 60), const Color(0xFF616161),
          radius: 2);
      cartoonRRect(canvas, Rect.fromLTWH(u.left, u.top, u.width, 76), const Color(0xFFD7CCC8), radius: 8);
      cartoonRRect(canvas, Rect.fromLTWH(u.left + 8, u.top + 8, 48, 34), const Color(0xFF263238), radius: 3, outline: 2);
      _confirma.paintCentered(canvas, Offset(u.left + 32, u.top + 25));
      for (var r = 0; r < 4; r++) {
        for (var col = 0; col < 3; col++) {
          canvas.drawRect(Rect.fromLTWH(u.left + 62 + col * 10, u.top + 10 + r * 9, 7, 6), fill(kOutline));
        }
      }
      cartoonRRect(canvas, Rect.fromLTWH(u.left + 10, u.top + 50, 24, 14), const Color(0xFF43A047),
          radius: 2, outline: 2);
      _urna.paintCentered(canvas, Offset(u.left + 64, u.top + 58));
    }
  }
}
