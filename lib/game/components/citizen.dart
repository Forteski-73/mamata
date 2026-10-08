import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../services/audio_service.dart';
import '../levels.dart';
import '../mamata_game.dart';
import '../paint_utils.dart';
import 'entity.dart';
import 'obstacle.dart';

/// Cidadão comum caminhando pela calçada — alvo dos impostos.
class Citizen extends Entity {
  Citizen(double x, math.Random rnd)
      : shirt = _shirts[rnd.nextInt(_shirts.length)],
        skin = _skins[rnd.nextInt(_skins.length)],
        hair = _hairs[rnd.nextInt(_hairs.length)],
        hasBag = rnd.nextBool(),
        super(size: Vector2(48, 100), priority: 1) {
    position = Vector2(x, MamataGame.groundY - size.y);
    extraSpeed = 50;
  }

  static const _shirts = [
    Color(0xFFFFEB3B),
    Color(0xFF29B6F6),
    Color(0xFFEF5350),
    Color(0xFF66BB6A),
    Color(0xFFAB47BC),
    Color(0xFFFF7043),
  ];
  static const _skins = [Color(0xFFF1C27D), Color(0xFFC68642), Color(0xFF8D5524), Color(0xFFE0AC69)];
  static const _hairs = [Color(0xFF3E2723), Color(0xFF212121), Color(0xFFFFCA28), Color(0xFF6D4C41)];

  final Color shirt;
  final Color skin;
  final Color hair;
  final bool hasBag;

  bool taxed = false;
  double _taxedT = 0;

  /// Se vai revidar com um tomate (senão o cidadão só fica triste).
  bool revolted = false;
  bool _thrown = false;
  static const double windup = 0.55;

  @override
  Rect get hitbox => toRect().deflate(4);

  @override
  void onPlayerContact() {
    if (taxed) return;
    game.taxCitizen(this, ranged: false);
  }

  void markTaxed({bool retaliate = false}) {
    revolted = retaliate;
    taxed = true;
    active = false;
    extraSpeed = -40; // sai andando desolado
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (taxed) _taxedT += dt;
    if (revolted && !_thrown && _taxedT >= windup) {
      _thrown = true;
      // só arremessa se o político ainda estiver à frente (à esquerda)
      if (game.isRunning && x > game.player.x + 140) {
        game.world.add(Obstacle(ObstacleType.tomate, x - 20));
        AudioService.instance.play(Sfx.throwTax);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    groundShadow(canvas, Offset(width / 2, height), 46);
    final s = math.sin(age * 10);
    for (final dir in [1.0, -1.0]) {
      canvas.save();
      canvas.translate(24, 66);
      canvas.rotate(s * 0.45 * dir);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-5, 0, 10, 32), const Radius.circular(4)),
          fill(dir > 0 ? const Color(0xFF1565C0) : const Color(0xFF0D47A1)));
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-8, 28, 14, 7), const Radius.circular(3)),
          fill(const Color(0xFF424242)));
      canvas.restore();
    }
    cartoonRRect(canvas, const Rect.fromLTWH(10, 32, 28, 38), shirt, radius: 9);
    // braços
    canvas.drawLine(const Offset(14, 40), Offset(8 - s * 4, 62), stroke(skin, 7));
    if (revolted && !_thrown) {
      // braço erguido segurando o tomate
      final k = (_taxedT / windup).clamp(0.0, 1.0);
      final hand = Offset(36 + k * 8, 34 - 30 * k);
      canvas.drawLine(const Offset(34, 40), hand, stroke(skin, 7));
      cartoonCircle(canvas, hand, 8, const Color(0xFFE53935), outline: 2);
    } else if (revolted) {
      // punho cerrado sacudindo
      final shake = math.sin(_taxedT * 25) * 4;
      canvas.drawLine(const Offset(34, 40), Offset(42, 18 + shake), stroke(skin, 7));
      cartoonCircle(canvas, Offset(42, 16 + shake), 5, skin, outline: 2);
    } else {
      canvas.drawLine(const Offset(34, 40), Offset(40 + s * 4, 62), stroke(skin, 7));
    }
    if (hasBag && !taxed) {
      cartoonRRect(canvas, Rect.fromLTWH(34 + s * 4, 58, 14, 14), const Color(0xFFFFFFFF), radius: 2, outline: 2);
    }
    // cabeça
    cartoonCircle(canvas, const Offset(24, 18), 14, skin);
    canvas.drawArc(const Rect.fromLTWH(10, 4, 28, 22), math.pi, math.pi, true, fill(hair));
    // olhando para a esquerda (direção do jogador)
    if (revolted) {
      // cara de bravo: sobrancelhas em V, bochechas vermelhas, boca gritando
      canvas.drawCircle(const Offset(14, 23), 4, fill(const Color(0x88FF5252)));
      canvas.drawCircle(const Offset(32, 23), 4, fill(const Color(0x88FF5252)));
      canvas.drawLine(const Offset(13, 12), const Offset(20, 15), stroke(kOutline, 2.5));
      canvas.drawLine(const Offset(30, 12), const Offset(23, 15), stroke(kOutline, 2.5));
      canvas.drawCircle(const Offset(17, 18), 2.2, fill(kOutline));
      canvas.drawCircle(const Offset(26, 18), 2.2, fill(kOutline));
      canvas.drawOval(const Rect.fromLTWH(17, 22, 9, 6), fill(const Color(0xFF7B1E1E)));
    } else if (taxed) {
      // olhos tristes e lágrima
      canvas.drawLine(const Offset(14, 15), const Offset(19, 17), stroke(kOutline, 2));
      canvas.drawLine(const Offset(24, 17), const Offset(29, 15), stroke(kOutline, 2));
      canvas.drawArc(const Rect.fromLTWH(15, 23, 10, 7), math.pi, math.pi, false, stroke(kOutline, 2));
      final tt = (_taxedT * 2) % 1;
      canvas.drawCircle(Offset(15, 20 + tt * 14), 2.5, fill(Color.fromRGBO(100, 181, 246, 1 - tt)));
      // bolsos vazios
      canvas.drawRect(const Rect.fromLTWH(10, 58, 8, 8), fill(const Color(0xFFFFFFFF)));
      canvas.drawRect(const Rect.fromLTWH(30, 58, 8, 8), fill(const Color(0xFFFFFFFF)));
    } else {
      canvas.drawCircle(const Offset(17, 17), 2.5, fill(kOutline));
      canvas.drawCircle(const Offset(27, 17), 2.5, fill(kOutline));
      canvas.drawArc(const Rect.fromLTWH(15, 20, 10, 7), 0, math.pi, false, stroke(kOutline, 2));
    }
  }
}
