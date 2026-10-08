import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../paint_utils.dart';

/// Texto que sobe e some (ex.: "+R$ 50 mil").
class FloatingText extends PositionComponent {
  FloatingText(
    String text,
    Vector2 pos, {
    Color color = const Color(0xFFFFFFFF),
    double size = 22,
    this.life = 1.0,
    this.rise = 70,
  })  : _label = Label(text, size: size, color: color, strokeWidth: size * 0.22),
        super(position: pos, priority: 40);

  final Label _label;
  final double life;
  final double rise;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
    y -= rise * dt;
    if (_t >= life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final k = _t / life;
    final scale = k < 0.15 ? 0.6 + k / 0.15 * 0.5 : (k < 0.3 ? 1.1 - (k - 0.15) / 0.15 * 0.1 : 1.0);
    final alpha = k > 0.7 ? (1 - (k - 0.7) / 0.3) : 1.0;
    canvas.saveLayer(null, Paint()..color = Color.fromRGBO(255, 255, 255, alpha.clamp(0, 1)));
    canvas.scale(scale);
    _label.paintCentered(canvas, Offset.zero);
    canvas.restore();
  }
}

class _Bit {
  _Bit(this.x, this.y, this.vx, this.vy, this.color, this.size, this.life, this.square, this.spin);
  double x, y, vx, vy;
  final Color color;
  final double size;
  final double life;
  final bool square;
  final double spin;
  double age = 0;
}

/// Sistema de partículas leve (explosões, poeira, confete).
class Burst extends Component {
  Burst({
    required Vector2 origin,
    required List<Color> colors,
    int count = 16,
    double speed = 260,
    double gravity = 900,
    double size = 5,
    double life = 0.8,
    bool squares = false,
    double spreadAngle = math.pi * 2,
    double direction = -math.pi / 2,
    this.drag = 0,
  })  : _gravity = gravity,
        super(priority: 35) {
    final rnd = math.Random();
    for (var i = 0; i < count; i++) {
      final a = direction + (rnd.nextDouble() - 0.5) * spreadAngle;
      final v = speed * (0.4 + rnd.nextDouble() * 0.6);
      _bits.add(_Bit(
        origin.x,
        origin.y,
        math.cos(a) * v,
        math.sin(a) * v,
        colors[rnd.nextInt(colors.length)],
        size * (0.6 + rnd.nextDouble() * 0.8),
        life * (0.6 + rnd.nextDouble() * 0.4),
        squares,
        (rnd.nextDouble() - 0.5) * 20,
      ));
    }
  }

  final List<_Bit> _bits = [];
  final double _gravity;
  final double drag;

  /// Deslocamento horizontal aplicado a todos (para acompanhar a rolagem).
  double scrollSpeed = 0;

  @override
  void update(double dt) {
    for (final b in _bits) {
      b.age += dt;
      b.vy += _gravity * dt;
      if (drag > 0) {
        b.vx *= 1 - drag * dt;
        b.vy *= 1 - drag * dt;
      }
      b.x += (b.vx - scrollSpeed) * dt;
      b.y += b.vy * dt;
    }
    _bits.removeWhere((b) => b.age >= b.life);
    if (_bits.isEmpty) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    for (final b in _bits) {
      final a = (1 - b.age / b.life).clamp(0.0, 1.0);
      final p = fill(b.color.withValues(alpha: a));
      if (b.square) {
        canvas.save();
        canvas.translate(b.x, b.y);
        canvas.rotate(b.age * b.spin);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: b.size * 1.6, height: b.size), p);
        canvas.restore();
      } else {
        canvas.drawCircle(Offset(b.x, b.y), b.size * (0.5 + a * 0.5), p);
      }
    }
  }
}
