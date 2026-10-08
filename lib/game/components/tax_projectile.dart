import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../mamata_game.dart';
import '../paint_utils.dart';
import 'citizen.dart';

/// Boleto de imposto arremessado pelo político.
class TaxProjectile extends PositionComponent with HasGameReference<MamataGame> {
  TaxProjectile(Vector2 pos) : super(position: pos, size: Vector2(34, 22), anchor: Anchor.center, priority: 12);

  double _t = 0;
  static final _label = Label('IMPOSTO', size: 7, color: const Color(0xFFD62828), stroke: null);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    x += 820 * dt;
    y += math.sin(_t * 12) * 30 * dt;
    angle = math.sin(_t * 14) * 0.3;
    if (_t > 1.6 || x > game.viewWidth + 60) {
      removeFromParent();
      return;
    }
    final r = toRect().inflate(14);
    for (final e in List.of(game.entities)) {
      if (e is Citizen && !e.taxed && e.hitbox.overlaps(r)) {
        game.taxCitizen(e, ranged: true);
        removeFromParent();
        return;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    cartoonRRect(canvas, size.toRect(), const Color(0xFFFFFFFF), radius: 2, outline: 2);
    for (var i = 0; i < 6; i++) {
      canvas.drawLine(Offset(5.0 + i * 4, 14), Offset(5.0 + i * 4, 19), stroke(kOutline, i.isEven ? 2 : 1));
    }
    _label.paintCentered(canvas, const Offset(17, 7));
  }
}
