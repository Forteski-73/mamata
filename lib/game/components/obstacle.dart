import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../levels.dart';
import '../mamata_game.dart';
import '../paint_utils.dart';
import 'entity.dart';

/// Metadados de cada escândalo.
class ObstacleInfo {
  const ObstacleInfo({
    required this.name,
    required this.size,
    required this.headline,
    required this.hint,
    this.flying = false,
    this.extraSpeed = 0,
    this.bottomOffset,
    this.fatal = false,
  });

  final String name;
  final Vector2 size;
  final String headline;
  final String hint;
  final bool flying;
  final double extraSpeed;

  /// Altura da borda inferior em relação ao chão (padrão: chão ou altura de voo).
  final double? bottomOffset;

  /// Bater sem proteção encerra o mandato na hora.
  final bool fatal;

  static final Map<ObstacleType, ObstacleInfo> all = {
    ObstacleType.cpi: ObstacleInfo(
      name: 'CPI',
      size: Vector2(120, 84),
      headline: 'CONVOCADO PELA CPI!',
      hint: 'Pule! Sem 3 laranjas = fim de jogo',
      fatal: true,
    ),
    ObstacleType.jornalista: ObstacleInfo(
      name: 'Jornalista',
      size: Vector2(62, 118),
      headline: 'FLAGRADO PELA IMPRENSA!',
      hint: 'Pule por cima',
      extraSpeed: 60,
    ),
    ObstacleType.drone: ObstacleInfo(
      name: 'Drone da Imprensa',
      size: Vector2(104, 46),
      headline: 'FILMADO PELO DRONE!',
      hint: 'Segure para abaixar',
      flying: true,
      extraSpeed: 40,
    ),
    ObstacleType.tcu: ObstacleInfo(
      name: 'Auditoria do TCU',
      size: Vector2(86, 168),
      headline: 'CONTAS REPROVADAS PELO TCU!',
      hint: 'Pulo duplo',
    ),
    ObstacleType.cpmi: ObstacleInfo(
      name: 'CPMI',
      size: Vector2(250, 96),
      headline: 'CONVOCADO PELA CPMI!',
      hint: 'Pulo duplo! Sem 3 laranjas = fim',
      fatal: true,
    ),
    ObstacleType.pf: ObstacleInfo(
      name: 'Polícia Federal',
      size: Vector2(184, 92),
      headline: 'A PF BATEU NA PORTA!',
      hint: 'Pule — vem rápido!',
      extraSpeed: 170,
    ),
    ObstacleType.delacao: ObstacleInfo(
      name: 'Delação Premiada',
      size: Vector2(78, 54),
      headline: 'DELATADO PELO EX-ASSESSOR!',
      hint: 'Segure para abaixar',
      flying: true,
      extraSpeed: 150,
    ),
    ObstacleType.mandado: ObstacleInfo(
      name: 'Mandado de Busca',
      size: Vector2(76, 150),
      headline: 'MANDADO DE BUSCA E APREENSÃO!',
      hint: 'Pulo duplo',
    ),
    ObstacleType.tomate: ObstacleInfo(
      name: 'Tomate do Povo',
      size: Vector2(30, 30),
      headline: 'TOMATADA DO POVO!',
      hint: 'Cidadão revoltado: abaixe-se',
      flying: true,
      extraSpeed: 380,
      bottomOffset: 84,
    ),
  };
}

class Obstacle extends Entity {
  Obstacle(this.type, double x)
      : info = ObstacleInfo.all[type]!,
        super(priority: 2) {
    size = info.size.clone();
    extraSpeed = info.extraSpeed;
    final bottom = MamataGame.groundY - (info.bottomOffset ?? (info.flying ? 76 : 0));
    position = Vector2(x, bottom - size.y);
    _baseY = position.y;
  }

  final ObstacleType type;
  final ObstacleInfo info;
  late final double _baseY;

  /// Já resolvido (atravessado com laranja, esmagado ou causou dano).
  bool cleared = false;
  bool smashed = false;
  bool ghost = false;
  double _smashT = 0;

  static final _labels = <String, Label>{};
  static Label _label(String text, double size, {Color color = const Color(0xFFFFFFFF)}) =>
      _labels.putIfAbsent('$text|$size|${color.toARGB32()}',
          () => Label(text, size: size, color: color, strokeWidth: 3.5));

  @override
  Rect get hitbox {
    final r = toRect();
    switch (type) {
      case ObstacleType.jornalista:
        return Rect.fromLTRB(r.left + 12, r.top + 10, r.right - 10, r.bottom);
      case ObstacleType.pf:
        return Rect.fromLTRB(r.left + 10, r.top + 22, r.right - 10, r.bottom);
      case ObstacleType.drone:
      case ObstacleType.delacao:
        return r.deflate(4);
      case ObstacleType.tomate:
        return r.deflate(3);
      default:
        return Rect.fromLTRB(r.left + 8, r.top + 6, r.right - 8, r.bottom);
    }
  }

  @override
  void onPlayerContact() {
    if (cleared) return;
    cleared = true;
    game.onObstacleHit(this);
  }

  void smash() {
    smashed = true;
    active = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (type == ObstacleType.drone) {
      y = _baseY + math.sin(age * 5) * 5;
    } else if (type == ObstacleType.delacao) {
      y = _baseY + math.sin(age * 7) * 7;
    }
    if (smashed) {
      _smashT += dt;
      y -= 600 * dt;
      x += 300 * dt;
      if (_smashT > 1.2) removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (smashed) {
      canvas.translate(width / 2, height / 2);
      canvas.rotate(_smashT * 8);
      canvas.translate(-width / 2, -height / 2);
    }
    if (ghost) {
      canvas.saveLayer(null, Paint()..color = const Color(0x77FFFFFF));
    }
    if (!info.flying) {
      groundShadow(canvas, Offset(width / 2, MamataGame.groundY - y), width * 1.05);
    }
    switch (type) {
      case ObstacleType.cpi:
        _drawTable(canvas, 'CPI', const Color(0xFF1565C0));
      case ObstacleType.cpmi:
        _drawTable(canvas, 'CPMI', const Color(0xFF6A1B9A));
      case ObstacleType.jornalista:
        _drawJournalist(canvas);
      case ObstacleType.drone:
        _drawDrone(canvas);
      case ObstacleType.tcu:
        _drawPapers(canvas);
      case ObstacleType.pf:
        _drawPoliceCar(canvas);
      case ObstacleType.delacao:
        _drawEnvelope(canvas);
      case ObstacleType.mandado:
        _drawWarrant(canvas);
      case ObstacleType.tomate:
        _drawTomato(canvas);
    }
    if (ghost) canvas.restore();
  }

  void _drawTable(Canvas c, String text, Color cloth) {
    final w = width, h = height;
    // pernas
    c.drawRect(Rect.fromLTWH(10, h * 0.45, 8, h * 0.55), fill(const Color(0xFF5D4037)));
    c.drawRect(Rect.fromLTWH(w - 18, h * 0.45, 8, h * 0.55), fill(const Color(0xFF5D4037)));
    // microfones
    for (var i = 0; i < (w / 60).floor(); i++) {
      final mx = 24.0 + i * 60;
      c.drawLine(Offset(mx, 18), Offset(mx + 8, 0), stroke(kOutline, 3));
      c.drawCircle(Offset(mx + 8, 0), 5, fill(const Color(0xFF333333)));
    }
    // toalha
    cartoonRRect(c, Rect.fromLTWH(0, 16, w, h * 0.62), cloth, radius: 6);
    c.drawRect(Rect.fromLTWH(3, 16 + h * 0.62 - 10, w - 6, 7), fill(const Color(0xFFFFD60A)));
    _label(text, 30).paintCentered(c, Offset(w / 2, 16 + h * 0.28));
    // placa "INVESTIGAÇÃO"
    if (type == ObstacleType.cpmi) {
      _label('INVESTIGAÇÃO', 14, color: const Color(0xFFFFD60A)).paintCentered(c, Offset(w / 2, 16 + h * 0.48));
    }
  }

  void _drawJournalist(Canvas c) {
    final s = math.sin(age * 9);
    // pernas
    c.save();
    c.translate(30, 80);
    c.rotate(s * 0.4);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-5, 0, 10, 36), const Radius.circular(4)),
        fill(const Color(0xFF37474F)));
    c.restore();
    c.save();
    c.translate(30, 80);
    c.rotate(-s * 0.4);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-5, 0, 10, 36), const Radius.circular(4)),
        fill(const Color(0xFF455A64)));
    c.restore();
    // corpo
    cartoonRRect(c, const Rect.fromLTWH(14, 36, 34, 48), const Color(0xFF00897B), radius: 10);
    _label('TV', 14, color: const Color(0xFFFFD60A)).paintCentered(c, const Offset(31, 54));
    // cabeça
    cartoonCircle(c, const Offset(30, 22), 15, const Color(0xFFC68642));
    c.drawArc(const Rect.fromLTWH(15, 6, 30, 24), math.pi, math.pi, true, fill(const Color(0xFF3E2723)));
    c.drawCircle(const Offset(22, 22), 2.5, fill(kOutline));
    // câmera
    cartoonRRect(c, const Rect.fromLTWH(-8, 40, 26, 18), const Color(0xFF263238), radius: 3, outline: 2);
    c.drawCircle(const Offset(-6, 49), 6, fill(const Color(0xFF90CAF9)));
    // flash
    if ((age * 3) % 1 < 0.12) {
      c.drawCircle(
        const Offset(-10, 49),
        40,
        Paint()
          ..shader = Gradient.radial(const Offset(-10, 49), 40, [const Color(0xFFFFFFFF), const Color(0x00FFFFFF)]),
      );
    }
    // microfone
    c.drawLine(const Offset(44, 56), const Offset(58, 40), stroke(kOutline, 3));
    cartoonCircle(c, const Offset(58, 38), 6, const Color(0xFFE53935), outline: 2);
  }

  void _drawDrone(Canvas c) {
    final w = width;
    // hélices
    for (final px in [10.0, w - 10]) {
      c.drawLine(Offset(px, 14), Offset(px, 4), stroke(kOutline, 3));
      final spin = math.sin(age * 60) * 18;
      c.drawLine(Offset(px - spin, 2), Offset(px + spin, 2), stroke(const Color(0xFF424242), 4));
    }
    c.drawLine(Offset(10, 14), Offset(w - 10, 14), stroke(kOutline, 4));
    cartoonRRect(c, Rect.fromLTWH(w * 0.22, 10, w * 0.56, 26), const Color(0xFFECEFF1), radius: 10);
    cartoonCircle(c, Offset(w / 2, 38), 9, const Color(0xFF263238), outline: 2);
    c.drawCircle(Offset(w / 2, 38), 4, fill(const Color(0xFFFF1744)));
    _label('TV', 13, color: const Color(0xFFE53935)).paintCentered(c, Offset(w / 2, 23));
    // luz piscando
    if ((age * 4) % 1 < 0.5) c.drawCircle(Offset(w * 0.3, 16), 3, fill(const Color(0xFFFF1744)));
  }

  void _drawPapers(Canvas c) {
    final w = width, h = height;
    const colors = [Color(0xFFFFFFFF), Color(0xFFFFF59D), Color(0xFFE3F2FD)];
    var y = h;
    var i = 0;
    while (y > 22) {
      final ph = 14.0;
      final off = math.sin(i * 1.7) * 5;
      cartoonRRect(c, Rect.fromLTWH(4 + off, y - ph, w - 8, ph), colors[i % 3], radius: 2, outline: 2);
      y -= ph;
      i++;
    }
    cartoonRRect(c, Rect.fromLTWH(0, h * 0.35, w, 40), const Color(0xFF2E7D32), radius: 6);
    _label('TCU', 24).paintCentered(c, Offset(w / 2, h * 0.35 + 14));
    _label('AUDITORIA', 10).paintCentered(c, Offset(w / 2, h * 0.35 + 32));
    // carimbo
    c.save();
    c.translate(w / 2, 12);
    c.rotate(-0.2);
    _label('REPROVADO', 12, color: const Color(0xFFE53935)).paintCentered(c, Offset.zero);
    c.restore();
  }

  void _drawPoliceCar(Canvas c) {
    final w = width, h = height;
    // carroceria
    final body = Path()
      ..moveTo(6, h - 18)
      ..lineTo(6, h * 0.5)
      ..lineTo(w * 0.22, h * 0.5)
      ..lineTo(w * 0.32, h * 0.22)
      ..lineTo(w * 0.75, h * 0.22)
      ..lineTo(w * 0.85, h * 0.5)
      ..lineTo(w - 4, h * 0.55)
      ..lineTo(w - 4, h - 18)
      ..close();
    c.drawPath(body, fill(const Color(0xFF1A1A1A)));
    c.drawRect(Rect.fromLTWH(6, h * 0.6, w - 10, 14), fill(const Color(0xFFFFFFFF)));
    c.drawPath(body, stroke(kOutline, 3));
    // janelas
    final win = Path()
      ..moveTo(w * 0.27, h * 0.5)
      ..lineTo(w * 0.35, h * 0.28)
      ..lineTo(w * 0.72, h * 0.28)
      ..lineTo(w * 0.8, h * 0.5)
      ..close();
    c.drawPath(win, fill(const Color(0xFF90CAF9)));
    c.drawLine(Offset(w * 0.53, h * 0.28), Offset(w * 0.53, h * 0.5), stroke(kOutline, 3));
    _label('POLÍCIA FEDERAL', 11, color: const Color(0xFF1A1A1A)).paintCentered(c, Offset(w / 2, h * 0.6 + 7));
    // sirene
    final on = (age * 6).floor().isEven;
    cartoonRRect(c, Rect.fromLTWH(w * 0.42, h * 0.08, 14, 10), on ? const Color(0xFFFF1744) : const Color(0xFF7F0000),
        radius: 2, outline: 2);
    cartoonRRect(c, Rect.fromLTWH(w * 0.42 + 14, h * 0.08, 14, 10),
        on ? const Color(0xFF0D47A1) : const Color(0xFF448AFF), radius: 2, outline: 2);
    if (on) {
      c.drawCircle(
        Offset(w * 0.42 + 7, h * 0.12),
        36,
        Paint()
          ..shader = Gradient.radial(
              Offset(w * 0.42 + 7, h * 0.12), 36, [const Color(0x88FF1744), const Color(0x00FF1744)]),
      );
    }
    // rodas
    for (final wx in [w * 0.2, w * 0.8]) {
      c.save();
      c.translate(wx, h - 16);
      c.rotate(-age * 18);
      cartoonCircle(c, Offset.zero, 16, const Color(0xFF212121));
      c.drawCircle(Offset.zero, 7, fill(const Color(0xFFBDBDBD)));
      c.drawLine(const Offset(-7, 0), const Offset(7, 0), stroke(const Color(0xFF616161), 2));
      c.restore();
    }
    // farol (vem em direção ao jogador, à esquerda)
    c.drawCircle(Offset(10, h * 0.55), 5, fill(const Color(0xFFFFF59D)));
  }

  void _drawEnvelope(Canvas c) {
    final w = width, h = height;
    c.save();
    c.translate(w / 2, h / 2);
    c.rotate(math.sin(age * 8) * 0.15);
    c.translate(-w / 2, -h / 2);
    // asas
    final flap = math.sin(age * 22) * 10;
    for (final side in [-1.0, 1.0]) {
      final wing = Path()
        ..moveTo(w / 2 + side * 10, h * 0.3)
        ..quadraticBezierTo(w / 2 + side * 34, -14 + flap, w / 2 + side * 46, 4 + flap)
        ..quadraticBezierTo(w / 2 + side * 30, h * 0.25, w / 2 + side * 10, h * 0.4)
        ..close();
      c.drawPath(wing, fill(const Color(0xFFFFFFFF)));
      c.drawPath(wing, stroke(kOutline, 2));
    }
    cartoonRRect(c, Rect.fromLTWH(0, 8, w, h - 8), const Color(0xFFFFF8E1), radius: 3);
    final v = Path()
      ..moveTo(0, 8)
      ..lineTo(w / 2, h * 0.6)
      ..lineTo(w, 8);
    c.drawPath(v, stroke(kOutline, 2.5));
    c.drawCircle(Offset(w / 2, h * 0.6), 7, fill(const Color(0xFFD62828)));
    _label('DELAÇÃO', 12, color: const Color(0xFFD62828)).paintCentered(c, Offset(w / 2, h - 8));
    c.restore();
  }

  void _drawWarrant(Canvas c) {
    final w = width, h = height;
    // cavalete
    c.drawLine(Offset(w * 0.2, h * 0.5), Offset(w * 0.05, h), stroke(const Color(0xFF5D4037), 6));
    c.drawLine(Offset(w * 0.8, h * 0.5), Offset(w * 0.95, h), stroke(const Color(0xFF5D4037), 6));
    cartoonRRect(c, Rect.fromLTWH(0, 0, w, h * 0.72), const Color(0xFFFFFDE7), radius: 4);
    c.drawRect(Rect.fromLTWH(0, 0, w, 20), fill(const Color(0xFF283593)));
    _label('JUSTIÇA', 12).paintCentered(c, Offset(w / 2, 10));
    _label('MANDADO', 15, color: const Color(0xFF283593)).paintCentered(c, Offset(w / 2, 34));
    _label('DE BUSCA', 12, color: const Color(0xFF283593)).paintCentered(c, Offset(w / 2, 52));
    for (var i = 0; i < 4; i++) {
      c.drawLine(Offset(10, 66.0 + i * 8), Offset(w - 10, 66.0 + i * 8), stroke(const Color(0xFFB0BEC5), 2));
    }
    c.drawRect(Rect.fromLTWH(0, 0, w, h * 0.72), stroke(kOutline, 3));
    // martelo do juiz
    c.save();
    c.translate(w * 0.72, h * 0.62);
    c.rotate(-0.6 + math.sin(age * 6).abs() * 0.4);
    c.drawLine(Offset.zero, const Offset(0, -26), stroke(const Color(0xFF6D4C41), 4));
    cartoonRRect(c, const Rect.fromLTWH(-12, -36, 24, 12), const Color(0xFF8D6E63), radius: 3, outline: 2);
    c.restore();
  }

  void _drawTomato(Canvas c) {
    c.save();
    c.translate(width / 2, height / 2);
    c.drawCircle(const Offset(12, 0), 10, fill(const Color(0x55E53935))); // rastro
    c.rotate(-age * 14);
    cartoonCircle(c, Offset.zero, 14, const Color(0xFFE53935), outline: 2.5);
    c.drawCircle(const Offset(-5, -5), 4, fill(const Color(0x88FFFFFF)));
    final leaf = Path()
      ..moveTo(0, -14)
      ..lineTo(-6, -19)
      ..lineTo(0, -16)
      ..lineTo(6, -19)
      ..close();
    c.drawPath(leaf, fill(const Color(0xFF2E7D32)));
    c.restore();
  }

}
