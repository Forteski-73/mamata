import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../paint_utils.dart';
import 'entity.dart';

/// Pacote de dinheiro desviado.
class MoneyBag extends Entity {
  MoneyBag(Vector2 pos, {this.value = 50}) : super(position: pos, size: Vector2(40, 44), priority: 3);

  final int value;
  bool _collected = false;
  double _t = 0;
  static final _label = Label('R\$', size: 16, color: const Color(0xFFFFD60A), strokeWidth: 3);

  @override
  Rect get hitbox => toRect().inflate(6);

  @override
  void onPlayerContact() {
    if (_collected) return;
    _collected = true;
    active = false;
    game.collectMoney(this);
    removeFromParent();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    // ímã da Emenda Parlamentar
    if (game.emendaTime > 0 && active) {
      final p = game.player;
      final target = Vector2(p.x + 32, p.y + p.height / 2);
      final me = position + size / 2;
      final d = target - me;
      if (d.length < 420) {
        position += d.normalized() * math.min(d.length, 900 * dt);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final bob = math.sin(_t * 5 + x * 0.01) * 3;
    drawMoneyBag(canvas, Offset(20, 24 + bob), 16, label: _label);
    // brilho
    final s = (math.sin(_t * 4 + x) + 1) / 2;
    canvas.drawPath(starPath(Offset(34, 6 + bob), 4 + 3 * s, 1.5), fill(Color.fromRGBO(255, 255, 255, s)));
  }
}

/// Laranja: escudo que "assume a culpa" de um escândalo.
class OrangeFruit extends Entity {
  OrangeFruit(Vector2 pos) : super(position: pos, size: Vector2(40, 40), priority: 3);

  double _t = 0;

  @override
  Rect get hitbox => toRect().inflate(6);

  @override
  void onPlayerContact() {
    if (!active) return;
    active = false;
    game.collectOrange(this);
    removeFromParent();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final bob = math.sin(_t * 4) * 4;
    canvas.drawCircle(
      Offset(20, 22 + bob),
      28,
      Paint()..shader = Gradient.radial(Offset(20, 22 + bob), 28, [const Color(0x66FFB74D), const Color(0x00FFB74D)]),
    );
    drawOrange(canvas, Offset(20, 22 + bob), 15);
  }
}

enum PowerUpType {
  foro('FORO', 'Foro Privilegiado', 'Imune a escândalos por 6s'),
  fakeNews('FAKE', 'Fake News', 'Empurra a Verdade para longe'),
  emenda('EMENDA', 'Emenda Parlamentar', 'Atrai o dinheiro por 8s'),
  mala('MALA', 'Mala de Dinheiro', '+R\$ 500 mil de uma vez');

  const PowerUpType(this.badge, this.title, this.description);
  final String badge;
  final String title;
  final String description;

  Color get color => switch (this) {
        PowerUpType.foro => const Color(0xFFFFC107),
        PowerUpType.fakeNews => const Color(0xFFE53935),
        PowerUpType.emenda => const Color(0xFF8E24AA),
        PowerUpType.mala => const Color(0xFF2E7D32),
      };
}

class PowerUp extends Entity {
  PowerUp(this.type, Vector2 pos) : super(position: pos, size: Vector2(60, 60), priority: 3);

  final PowerUpType type;
  double _t = 0;
  late final Label _label = Label(type.badge, size: type.badge.length > 4 ? 11 : 14, strokeWidth: 3);

  @override
  Rect get hitbox => toRect().inflate(4);

  @override
  void onPlayerContact() {
    if (!active) return;
    active = false;
    game.collectPowerUp(this);
    removeFromParent();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final c = Offset(30, 30 + math.sin(_t * 4) * 4);
    // brilho girando
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(_t * 1.5);
    for (var i = 0; i < 8; i++) {
      canvas.rotate(math.pi / 4);
      canvas.drawLine(const Offset(0, 24), const Offset(0, 40), stroke(type.color.withValues(alpha: 0.5), 5));
    }
    canvas.restore();
    cartoonCircle(canvas, c, 24, type.color);
    canvas.drawCircle(c, 18, stroke(const Color(0x88FFFFFF), 2));
    switch (type) {
      case PowerUpType.foro:
        canvas.drawPath(
          Path()
            ..moveTo(c.dx - 10, c.dy - 12)
            ..lineTo(c.dx + 10, c.dy - 12)
            ..lineTo(c.dx + 10, c.dy)
            ..quadraticBezierTo(c.dx + 10, c.dy + 10, c.dx, c.dy + 14)
            ..quadraticBezierTo(c.dx - 10, c.dy + 10, c.dx - 10, c.dy)
            ..close(),
          fill(const Color(0xFFFFF8E1)),
        );
      case PowerUpType.fakeNews:
        canvas.drawRect(Rect.fromCenter(center: c, width: 26, height: 20), fill(const Color(0xFFFFFFFF)));
        for (var i = 0; i < 3; i++) {
          canvas.drawLine(Offset(c.dx - 9, c.dy - 4 + i * 5.0), Offset(c.dx + 9, c.dy - 4 + i * 5.0),
              stroke(const Color(0xFF9E9E9E), 2));
        }
      case PowerUpType.emenda:
        canvas.drawArc(Rect.fromCenter(center: c.translate(0, 2), width: 22, height: 22), math.pi, math.pi, false,
            stroke(const Color(0xFFFFFFFF), 6));
        canvas.drawLine(c.translate(-11, 2), c.translate(-11, 10), stroke(const Color(0xFFE53935), 6));
        canvas.drawLine(c.translate(11, 2), c.translate(11, 10), stroke(const Color(0xFFE53935), 6));
      case PowerUpType.mala:
        cartoonRRect(canvas, Rect.fromCenter(center: c.translate(0, 2), width: 26, height: 18), const Color(0xFF8D5524),
            radius: 3, outline: 2);
        canvas.drawRect(Rect.fromCenter(center: c.translate(0, -9), width: 10, height: 4), fill(kOutline));
    }
    _label.paintCentered(canvas, c.translate(0, 30));
  }
}
