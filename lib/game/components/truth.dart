import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../mamata_game.dart';
import '../paint_utils.dart';

/// "A Verdade": uma muralha de luz com um olho que tudo vê, perseguindo o político.
class Truth extends Component with HasGameReference<MamataGame> {
  Truth() : super(priority: 20);

  double displayGap = 600;
  double _t = 0;
  double _blink = 0;
  double _nextBlink = 3;
  double fade = 1;
  final _rnd = math.Random();
  final List<_Spark> _sparks = [];
  final _title = Label('A VERDADE', size: 30, color: const Color(0xFFFFD60A), stroke: const Color(0xFF14213D), strokeWidth: 6);

  void reset() {
    displayGap = game.truthGap + 200;
    fade = 1;
    _sparks.clear();
  }

  double get frontX => MamataGame.playerX - displayGap;

  @override
  void update(double dt) {
    _t += dt;
    var target = game.truthGap;
    if (game.phase == GamePhase.caught) target = -140;
    if (game.phase == GamePhase.menu) target = 520;
    final k = game.phase == GamePhase.caught ? 4.0 : 2.5;
    displayGap += (target - displayGap) * math.min(1, dt * k);
    if (game.phase == GamePhase.finishing || game.phase == GamePhase.ended) {
      fade = math.max(0, fade - dt * 0.8);
      displayGap += 300 * dt;
    }

    _nextBlink -= dt;
    if (_nextBlink <= 0) {
      _blink = 0.18;
      _nextBlink = 2 + _rnd.nextDouble() * 3;
    }
    if (_blink > 0) _blink -= dt;

    if (_sparks.length < 40 && fade > 0) {
      _sparks.add(_Spark(
        x: frontX - 30 + _rnd.nextDouble() * 40,
        y: _rnd.nextDouble() * MamataGame.virtualHeight,
        vx: 40 + _rnd.nextDouble() * 120,
        vy: -20 + _rnd.nextDouble() * 40,
        life: 0.6 + _rnd.nextDouble() * 0.8,
      ));
    }
    for (final s in _sparks) {
      s.x += s.vx * dt;
      s.y += s.vy * dt;
      s.age += dt;
    }
    _sparks.removeWhere((s) => s.age >= s.life);
  }

  @override
  void render(Canvas canvas) {
    if (fade <= 0) return;
    final fx = frontX;
    if (fx < -260) return;
    const h = MamataGame.virtualHeight;

    // brilho externo
    canvas.drawRect(
      Rect.fromLTRB(fx - 40, 0, fx + 170, h),
      Paint()
        ..shader = Gradient.linear(
          Offset(fx - 40, 0),
          Offset(fx + 170, 0),
          [Color.fromRGBO(255, 236, 160, 0.55 * fade), const Color(0x00FFECA0)],
        ),
    );

    // corpo ondulado
    final body = Path()..moveTo(-50, 0);
    for (double y = 0; y <= h; y += 24) {
      final wobble = math.sin(y * 0.018 + _t * 4) * 16 + math.sin(y * 0.05 - _t * 7) * 6;
      body.lineTo(fx + wobble, y);
    }
    body
      ..lineTo(-50, h)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = Gradient.linear(
          Offset(fx - 320, 0),
          Offset(fx + 10, 0),
          [
            Color.fromRGBO(255, 214, 10, 0.95 * fade),
            Color.fromRGBO(255, 248, 220, 0.97 * fade),
            Color.fromRGBO(255, 255, 255, 0.98 * fade),
          ],
          [0, 0.6, 1],
        ),
    );
    canvas.drawPath(body, stroke(Color.fromRGBO(255, 190, 0, 0.8 * fade), 4));

    // raios girando atrás do olho
    final eye = Offset(fx - 110, 330 + math.sin(_t * 2) * 10);
    for (var i = 0; i < 12; i++) {
      final a = _t * 0.6 + i * math.pi / 6;
      final p1 = eye + Offset(math.cos(a), math.sin(a)) * 70;
      final p2 = eye + Offset(math.cos(a), math.sin(a)) * 150;
      canvas.drawLine(p1, p2, stroke(Color.fromRGBO(255, 190, 0, 0.35 * fade), 6));
    }

    // olho que tudo vê
    final open = _blink > 0 ? 0.1 : 1.0;
    final eyePath = Path()
      ..moveTo(eye.dx - 62, eye.dy)
      ..quadraticBezierTo(eye.dx, eye.dy - 56 * open, eye.dx + 62, eye.dy)
      ..quadraticBezierTo(eye.dx, eye.dy + 56 * open, eye.dx - 62, eye.dy)
      ..close();
    canvas.drawPath(eyePath, fill(Color.fromRGBO(255, 255, 255, fade)));
    if (open > 0.5) {
      final player = game.player;
      final look = Offset(player.x + 32, player.y + 30) - eye;
      final dir = look / math.max(1, look.distance);
      final iris = eye + dir * 16;
      canvas.save();
      canvas.clipPath(eyePath);
      canvas.drawCircle(iris, 25, fill(Color.fromRGBO(30, 136, 229, fade)));
      final danger = (1 - (game.truthGap / 300)).clamp(0.0, 1.0);
      canvas.drawCircle(iris, 11 + 5 * danger, fill(Color.fromRGBO(10, 10, 20, fade)));
      canvas.drawCircle(iris + const Offset(-8, -8), 6, fill(Color.fromRGBO(255, 255, 255, 0.9 * fade)));
      canvas.restore();
    }
    canvas.drawPath(eyePath, stroke(Color.fromRGBO(20, 33, 61, fade), 5));

    canvas.save();
    canvas.translate(eye.dx, eye.dy - 110);
    canvas.rotate(math.sin(_t * 2) * 0.05);
    _title.paintCentered(canvas, Offset.zero);
    canvas.restore();

    // balança da justiça
    final sc = Offset(eye.dx, eye.dy + 120);
    final tilt = math.sin(_t * 2.2) * 0.2;
    final gold = stroke(Color.fromRGBO(140, 95, 0, fade), 4);
    canvas.drawLine(sc, sc + const Offset(0, -40), gold);
    final l = sc + Offset(-40, -40 + tilt * 40);
    final r = sc + Offset(40, -40 - tilt * 40);
    canvas.drawLine(l, r, gold);
    for (final pan in [l, r]) {
      canvas.drawLine(pan, pan + const Offset(-12, 22), gold);
      canvas.drawLine(pan, pan + const Offset(12, 22), gold);
      canvas.drawArc(Rect.fromCenter(center: pan + const Offset(0, 22), width: 30, height: 14), 0, math.pi, true,
          fill(Color.fromRGBO(140, 95, 0, fade)));
    }

    // faíscas
    for (final s in _sparks) {
      final a = (1 - s.age / s.life) * fade;
      canvas.drawCircle(Offset(s.x, s.y), 3, fill(Color.fromRGBO(255, 230, 120, a)));
    }
  }
}

class _Spark {
  _Spark({required this.x, required this.y, required this.vx, required this.vy, required this.life});
  double x, y, vx, vy, life;
  double age = 0;
}
