import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../services/audio_service.dart';
import '../mamata_game.dart';
import '../paint_utils.dart';

enum PlayerPose { idle, run, jump, slide, stumble, caught, cheer }

/// O político: corre, pula (duplo), desliza e cobra impostos.
class Player extends PositionComponent with HasGameReference<MamataGame> {
  Player() : super(size: Vector2(64, 112), priority: 10);

  static const double gravity = 3000;
  static const double jumpVelocity = -1150;
  static const double doubleJumpVelocity = -980;

  double vy = 0;
  int jumps = 0;
  bool sliding = false;
  bool _slideHeld = false;
  double _slideMin = 0;
  double stumbleTime = 0;
  double invulnerable = 0;
  double runPhase = 0;
  double _time = 0;
  double throwAnim = 0;
  double _jumpBuffer = 0;
  PlayerPose? forcedPose;

  bool get onGround => y >= MamataGame.groundY - height - 0.5;

  void reset() {
    position = Vector2(MamataGame.playerX, MamataGame.groundY - height);
    vy = 0;
    jumps = 0;
    sliding = false;
    _slideHeld = false;
    _jumpBuffer = 0;
    stumbleTime = 0;
    invulnerable = 0;
    throwAnim = 0;
    forcedPose = null;
  }

  Rect get hitbox {
    if (sliding) {
      return Rect.fromLTWH(x - 18, MamataGame.groundY - 50, 92, 48);
    }
    return Rect.fromLTWH(x + 14, y + 8, 38, height - 10);
  }

  PlayerPose get pose {
    if (forcedPose != null) return forcedPose!;
    if (!game.isRunning && game.phase != GamePhase.finishing) return PlayerPose.idle;
    if (stumbleTime > 0) return PlayerPose.stumble;
    if (sliding) return PlayerPose.slide;
    if (!onGround) return PlayerPose.jump;
    return PlayerPose.run;
  }

  void jump() {
    if (stumbleTime > 0.25) {
      _jumpBuffer = 0.15;
      return;
    }
    if (onGround) {
      vy = jumpVelocity;
      jumps = 1;
      sliding = false;
      AudioService.instance.play(Sfx.jump);
      game.dust(Vector2(x + 30, MamataGame.groundY));
    } else if (jumps < 2) {
      vy = doubleJumpVelocity;
      jumps = 2;
      AudioService.instance.play(Sfx.doubleJump);
      game.puff(Vector2(x + 30, y + height));
    } else {
      // toque um pouco antes de aterrissar: pula assim que tocar o chão
      _jumpBuffer = 0.15;
    }
  }

  void startSlide() {
    _slideHeld = true;
    if (onGround) {
      if (!sliding) {
        sliding = true;
        _slideMin = 0.35;
        AudioService.instance.play(Sfx.slide);
      }
    } else {
      vy = math.max(vy, 1500); // mergulho rápido
    }
  }

  void endSlide() => _slideHeld = false;

  void stumble() {
    stumbleTime = 0.6;
    invulnerable = 1.2;
    sliding = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (invulnerable > 0) invulnerable -= dt;
    if (stumbleTime > 0) stumbleTime -= dt;
    if (throwAnim > 0) throwAnim -= dt;
    if (_jumpBuffer > 0) _jumpBuffer -= dt;
    final running = game.isRunning || game.phase == GamePhase.finishing;
    if (game.worldSpeed > 0 || game.phase == GamePhase.finishing) {
      runPhase += dt * (math.max(game.worldSpeed, 260) / 38);
    }

    if (game.phase == GamePhase.caught) return;

    // física vertical
    vy += gravity * dt;
    y += vy * dt;
    final floor = MamataGame.groundY - height;
    if (y >= floor) {
      if (jumps > 0 && vy > 400) game.dust(Vector2(x + 30, MamataGame.groundY));
      y = floor;
      vy = 0;
      jumps = 0;
      if (_jumpBuffer > 0 && running && stumbleTime <= 0.25) {
        _jumpBuffer = 0;
        jump();
      } else if (_slideHeld && !sliding && running) {
        sliding = true;
        _slideMin = 0.35;
        AudioService.instance.play(Sfx.slide);
      }
    }

    if (sliding) {
      _slideMin -= dt;
      if (!_slideHeld && _slideMin <= 0) sliding = false;
    }

    if (game.phase == GamePhase.finishing) {
      x += 260 * dt;
    }
  }

  // ------------------------------------------------------------------ render
  static final _suit = fill(const Color(0xFF1F2A44));
  static final _suitDark = fill(const Color(0xFF141C30));
  static final _skin = fill(const Color(0xFFF1C27D));
  static final _skinDark = fill(const Color(0xFFD9A066));
  static final _white = fill(const Color(0xFFFFFFFF));
  static final _tie = fill(const Color(0xFFD62828));
  static final _black = fill(const Color(0xFF111111));
  static final _hair = fill(const Color(0xFFB0B0B0));
  static final _case = fill(const Color(0xFF8D5524));
  static final _cash = fill(const Color(0xFF2E7D32));
  static final _outline = stroke(kOutline, 2.5);

  @override
  void render(Canvas canvas) {
    final p = pose;
    // pisca quando invulnerável após um escândalo
    if (invulnerable > 0 && stumbleTime <= 0 && game.foroTime <= 0) {
      if ((_time * 14).floor().isEven) return;
    }

    // sombra
    final shadowScale = (1 - (MamataGame.groundY - height - y).abs() / 400).clamp(0.3, 1.0);
    canvas.save();
    canvas.translate(0, MamataGame.groundY - y);
    groundShadow(canvas, Offset(width / 2 + (p == PlayerPose.slide ? 0 : 4), -2), 70 * shadowScale);
    canvas.restore();

    // luz de contorno à noite, para legibilidade
    if (game.level.sky.night) {
      canvas.drawCircle(
        Offset(width / 2, height / 2),
        70,
        Paint()
          ..shader = Gradient.radial(
            Offset(width / 2, height / 2),
            70,
            [const Color(0x40FFF3B0), const Color(0x00FFF3B0)],
          ),
      );
    }

    // aura do foro privilegiado
    if (game.foroTime > 0) {
      final pulse = 0.75 + 0.25 * math.sin(_time * 10);
      canvas.drawCircle(
        Offset(width / 2, height / 2),
        78 * pulse,
        Paint()
          ..shader = Gradient.radial(
            Offset(width / 2, height / 2),
            78 * pulse,
            [const Color(0x88FFD700), const Color(0x00FFD700)],
          ),
      );
    }

    canvas.save();
    switch (p) {
      case PlayerPose.slide:
        canvas.translate(54, height);
        canvas.rotate(-1.22);
        canvas.translate(-32, -height);
      case PlayerPose.stumble:
        canvas.translate(32, height);
        canvas.rotate(0.35 * math.sin(stumbleTime * 20));
        canvas.translate(-32, -height);
      case PlayerPose.jump:
        canvas.translate(32, height / 2);
        canvas.rotate(jumps == 2 ? (1 - (vy.abs() / 1000).clamp(0, 1)) * 0.25 : -0.06);
        canvas.translate(-32, -height / 2);
      default:
        break;
    }
    _drawBody(canvas, p);
    canvas.restore();

    // laranjas orbitando = proteção disponível
    final n = math.min(game.oranges, 3);
    for (var i = 0; i < n; i++) {
      final a = _time * 3 + i * (math.pi * 2 / n);
      final o = Offset(width / 2 + math.cos(a) * 44, height * 0.45 + math.sin(a) * 18);
      drawOrange(canvas, o, 7);
    }

    // estrelinhas de tontura
    if (p == PlayerPose.stumble || p == PlayerPose.caught) {
      for (var i = 0; i < 3; i++) {
        final a = _time * 6 + i * 2.1;
        final o = Offset(34 + math.cos(a) * 22, -6 + math.sin(a) * 6);
        canvas.drawPath(starPath(o, 7, 3), fill(const Color(0xFFFFD60A)));
      }
    }

    // suor quando a Verdade está perto
    if (game.truthGap < 170 && p != PlayerPose.slide) {
      final t = (_time * 2.5) % 1;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(20 - t * 8, 10 + t * 26), width: 6, height: 9),
        fill(Color.fromRGBO(120, 200, 255, 1 - t)),
      );
    }
  }

  void _leg(Canvas c, Offset hip, double angle, {bool back = false}) {
    c.save();
    c.translate(hip.dx, hip.dy);
    c.rotate(angle);
    final leg = RRect.fromRectAndRadius(const Rect.fromLTWH(-6.5, 0, 13, 28), const Radius.circular(5));
    c.drawRRect(leg, back ? _suitDark : _suit);
    c.drawRRect(leg, _outline);
    final shoe = RRect.fromRectAndRadius(const Rect.fromLTWH(-7, 24, 19, 9), const Radius.circular(4));
    c.drawRRect(shoe, _black);
    c.restore();
  }

  void _arm(Canvas c, Offset shoulder, double angle, {bool briefcase = false, bool back = false, bool boleto = false}) {
    c.save();
    c.translate(shoulder.dx, shoulder.dy);
    c.rotate(angle);
    final arm = RRect.fromRectAndRadius(const Rect.fromLTWH(-5, 0, 10, 26), const Radius.circular(5));
    c.drawRRect(arm, back ? _suitDark : _suit);
    c.drawRRect(arm, _outline);
    c.drawCircle(const Offset(0, 28), 5.5, _skin);
    c.drawCircle(const Offset(0, 28), 5.5, _outline);
    if (briefcase) {
      c.save();
      c.translate(0, 30);
      c.rotate(-angle);
      final r = RRect.fromRectAndRadius(const Rect.fromLTWH(-14, 0, 28, 20), const Radius.circular(3));
      // notas saindo da mala
      c.drawRect(const Rect.fromLTWH(-10, -4, 9, 6), _cash);
      c.drawRect(const Rect.fromLTWH(1, -5, 9, 7), _cash);
      c.drawRRect(r, _case);
      c.drawRRect(r, _outline);
      c.drawRect(const Rect.fromLTWH(-3, 7, 6, 4), fill(const Color(0xFFFFD60A)));
      c.restore();
    }
    if (boleto) {
      c.save();
      c.translate(0, 30);
      c.drawRect(const Rect.fromLTWH(-2, -8, 18, 12), _white);
      c.drawRect(const Rect.fromLTWH(-2, -8, 18, 12), stroke(kOutline, 1.5));
      c.restore();
    }
    c.restore();
  }

  void _drawBody(Canvas c, PlayerPose p) {
    final s = math.sin(runPhase);
    double frontLeg = 0, backLeg = 0, frontArm = 0, backArm = 0;
    var bob = 0.0;
    switch (p) {
      case PlayerPose.run:
        frontLeg = s * 0.75;
        backLeg = -s * 0.75;
        frontArm = -s * 0.9;
        backArm = s * 0.7;
        bob = -(math.cos(runPhase * 2).abs()) * 3;
      case PlayerPose.jump:
        frontLeg = -0.9;
        backLeg = 0.5;
        frontArm = -2.4;
        backArm = 0.9;
      case PlayerPose.slide:
        frontLeg = -0.3;
        backLeg = -0.1;
        frontArm = -2.8;
        backArm = 0.4;
      case PlayerPose.stumble:
        frontLeg = 0.4;
        backLeg = -0.3;
        frontArm = -2.6;
        backArm = 2.6;
      case PlayerPose.caught:
        frontLeg = 0.05;
        backLeg = -0.05;
        frontArm = math.pi - 0.25;
        backArm = math.pi + 0.25;
      case PlayerPose.cheer:
        final w = math.sin(_time * 12) * 0.3;
        frontLeg = s * 0.6;
        backLeg = -s * 0.6;
        frontArm = math.pi - 0.4 + w;
        backArm = math.pi + 0.4 - w;
      case PlayerPose.idle:
        bob = math.sin(_time * 3) * 1.2;
        frontArm = 0.15;
        backArm = -0.1;
    }
    if (throwAnim > 0 && p != PlayerPose.caught && p != PlayerPose.cheer) {
      frontArm = -1.6 + (0.25 - throwAnim) * 4;
    }

    c.save();
    c.translate(0, bob);

    _arm(c, const Offset(24, 46), backArm, briefcase: p != PlayerPose.caught && p != PlayerPose.cheer, back: true);
    _leg(c, const Offset(27, 80), backLeg, back: true);

    // tronco + barriga
    final torso = RRect.fromRectAndRadius(const Rect.fromLTRB(14, 38, 50, 84), const Radius.circular(12));
    c.drawRRect(torso, _suit);
    c.drawOval(const Rect.fromLTRB(22, 50, 58, 86), _suit);
    c.drawRRect(torso, _outline);
    c.drawArc(const Rect.fromLTRB(22, 50, 58, 86), -1.2, 2.6, false, _outline);
    final shirt = Path()
      ..moveTo(28, 38)
      ..lineTo(42, 38)
      ..lineTo(36, 58)
      ..close();
    c.drawPath(shirt, _white);
    final tie = Path()
      ..moveTo(34, 40)
      ..lineTo(38, 40)
      ..lineTo(40, 58 + math.sin(runPhase * 2) * 1.5)
      ..lineTo(36, 64)
      ..lineTo(32, 58)
      ..close();
    c.drawPath(tie, _tie);
    c.drawPath(tie, stroke(kOutline, 1.5));
    // broche da bandeira
    c.drawCircle(const Offset(46, 46), 2.5, fill(const Color(0xFF009C3B)));

    _leg(c, const Offset(37, 80), frontLeg);

    // cabeça
    const head = Offset(36, 22);
    c.drawCircle(const Offset(24, 25), 5, _skinDark);
    c.drawCircle(head, 17, _skin);
    c.drawCircle(head, 17, _outline);
    // cabelo lateral grisalho
    c.drawArc(const Rect.fromLTRB(19, 8, 39, 36), 1.9, 2.3, false, stroke(const Color(0xFFB0B0B0), 6));
    c.drawOval(const Rect.fromLTRB(36, 8, 44, 13), fill(const Color(0x88FFFFFF)));
    // óculos escuros
    final glasses = RRect.fromRectAndRadius(const Rect.fromLTRB(37, 16, 53, 25), const Radius.circular(3));
    c.drawRRect(glasses, _black);
    c.drawLine(const Offset(26, 19), const Offset(38, 19), stroke(const Color(0xFF111111), 2));
    c.drawLine(const Offset(41, 18), const Offset(45, 18), stroke(const Color(0x66FFFFFF), 1.5));
    // nariz, bigode, boca
    c.drawCircle(const Offset(52, 27), 3.5, _skinDark);
    c.drawOval(const Rect.fromLTRB(40, 29, 54, 34), _hair);
    if (p == PlayerPose.caught || p == PlayerPose.stumble) {
      c.drawOval(const Rect.fromLTRB(43, 34, 50, 40), _black);
    } else {
      c.drawArc(const Rect.fromLTRB(40, 30, 52, 39), 0.3, 2.2, false, stroke(const Color(0xFF7B1E1E), 2));
    }

    _arm(c, const Offset(40, 46), frontArm, boleto: throwAnim > 0.12);
    c.restore();
  }
}
