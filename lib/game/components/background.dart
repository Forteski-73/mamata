import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../levels.dart';
import '../mamata_game.dart';
import '../paint_utils.dart';

/// Cenário com paralaxe: céu, Esplanada/Congresso, árvores e outdoors, calçada e rua.
class Background extends Component with HasGameReference<MamataGame> {
  Background() : super(priority: -100);

  static const double skylineTile = 2400;
  static const double midTile = 1700;

  SkyTheme _theme = levels.first.sky;
  Picture? _skyline;
  Picture? _mid;
  double scroll = 0;
  double _t = 0;
  final _rnd = math.Random(7);
  late final List<Offset> _stars = List.generate(
    70,
    (_) => Offset(_rnd.nextDouble() * 2400, _rnd.nextDouble() * 360),
  );
  final List<_Cloud> _clouds = [];

  void setTheme(SkyTheme theme) {
    _theme = theme;
    _skyline = _recordSkyline();
    _mid = _recordMid();
  }

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < 6; i++) {
      _clouds.add(_Cloud(_rnd.nextDouble() * 2000, 40 + _rnd.nextDouble() * 200, 0.6 + _rnd.nextDouble() * 0.8));
    }
    setTheme(_theme);
  }

  @override
  void update(double dt) {
    _t += dt;
    scroll += game.worldSpeed * dt;
    for (final c in _clouds) {
      c.x -= (game.worldSpeed * 0.05 + 12) * dt;
      if (c.x < -300) {
        c.x = game.viewWidth + 200 + _rnd.nextDouble() * 400;
        c.y = 40 + _rnd.nextDouble() * 200;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final w = game.viewWidth;
    const gy = MamataGame.groundY;
    const h = MamataGame.virtualHeight;

    // céu
    final top = game.viewTop - 40;
    canvas.drawRect(
      Rect.fromLTRB(-40, top, w + 40, gy),
      Paint()..shader = Gradient.linear(Offset(0, math.min(0, top)), const Offset(0, gy), [_theme.top, _theme.bottom]),
    );

    if (_theme.night) {
      for (var i = 0; i < _stars.length; i++) {
        final s = _stars[i];
        if (s.dx > w) continue;
        final tw = 0.5 + 0.5 * math.sin(_t * 2 + i);
        canvas.drawCircle(s, 1.2 + tw, fill(Color.fromRGBO(255, 255, 255, 0.4 + 0.6 * tw)));
      }
    }

    // sol / lua
    final sun = Offset(w * 0.78, h * _theme.sunY);
    canvas.drawCircle(
      sun,
      120,
      Paint()..shader = Gradient.radial(sun, 120, [_theme.sunColor.withValues(alpha: 0.6), _theme.sunColor.withValues(alpha: 0)]),
    );
    canvas.drawCircle(sun, 46, fill(_theme.sunColor));
    if (_theme.night) {
      canvas.drawCircle(sun.translate(18, -10), 40, fill(_theme.top.withValues(alpha: 0.9)));
    }

    // nuvens
    for (final c in _clouds) {
      _cloud(canvas, Offset(c.x, c.y), c.s);
    }

    // skyline (Brasília)
    _tiled(canvas, _skyline, skylineTile, scroll * 0.15, w);
    // camada média
    _tiled(canvas, _mid, midTile, scroll * 0.45, w);

    // gramado
    canvas.drawRect(Rect.fromLTWH(0, gy - 26, w, 26), fill(_theme.ground));
    // calçada
    canvas.drawRect(Rect.fromLTWH(0, gy, w, 34), fill(_theme.night ? const Color(0xFF6D6D78) : const Color(0xFFBDBDBD)));
    final off = scroll % 80;
    for (double x = -off; x < w; x += 80) {
      canvas.drawLine(Offset(x, gy), Offset(x - 10, gy + 34), stroke(const Color(0x33000000), 2));
    }
    canvas.drawRect(Rect.fromLTWH(0, gy, w, 4), fill(const Color(0x22000000)));
    // meio-fio
    canvas.drawRect(Rect.fromLTWH(0, gy + 34, w, 10), fill(_theme.night ? const Color(0xFF8E8E99) : const Color(0xFFE0E0E0)));
    // asfalto
    canvas.drawRect(Rect.fromLTWH(0, gy + 44, w, h - gy - 4), fill(_theme.night ? const Color(0xFF26262E) : const Color(0xFF424242)));
    final off2 = scroll % 160;
    for (double x = -off2; x < w; x += 160) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, gy + 80, 80, 8), const Radius.circular(3)),
        fill(const Color(0xFFFFD54F)),
      );
    }
  }

  void _tiled(Canvas canvas, Picture? pic, double tile, double offset, double w) {
    if (pic == null) return;
    final o = offset % tile;
    for (double x = -o; x < w; x += tile) {
      canvas.save();
      canvas.translate(x, 0);
      canvas.drawPicture(pic);
      canvas.restore();
    }
  }

  void _cloud(Canvas c, Offset o, double s) {
    final p = fill(_theme.night ? const Color(0x553F4A80) : const Color(0xDDFFFFFF));
    c.drawCircle(o, 30 * s, p);
    c.drawCircle(o.translate(30 * s, -12 * s), 36 * s, p);
    c.drawCircle(o.translate(64 * s, 0), 28 * s, p);
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(o.dx - 20 * s, o.dy, 100 * s, 26 * s), Radius.circular(13 * s)),
      p,
    );
  }

  // ------------------------------------------------------------------ skyline
  Picture _recordSkyline() {
    final rec = PictureRecorder();
    final c = Canvas(rec);
    const b = MamataGame.groundY - 20; // linha de base
    final col = fill(_theme.skyline);
    final dark = fill(Color.lerp(_theme.skyline, const Color(0xFF000000), 0.18)!);
    final win = fill(_theme.night ? const Color(0xFFFFE082) : Color.lerp(_theme.skyline, const Color(0xFFFFFFFF), 0.25)!);

    // prédios genéricos ao fundo
    final r = math.Random(3);
    for (double x = 0; x < skylineTile; x += 90 + r.nextDouble() * 60) {
      final bh = 60 + r.nextDouble() * 90;
      c.drawRect(Rect.fromLTWH(x, b - bh, 70, bh), fill(Color.lerp(_theme.skyline, _theme.bottom, 0.45)!));
    }

    // Congresso Nacional
    c.drawRect(const Rect.fromLTWH(240, b - 36, 640, 36), col);
    c.drawRect(const Rect.fromLTWH(470, b - 36 - 250, 40, 250), dark);
    c.drawRect(const Rect.fromLTWH(520, b - 36 - 250, 40, 250), dark);
    c.drawRect(const Rect.fromLTWH(505, b - 36 - 170, 20, 12), dark);
    for (double y = b - 276; y < b - 50; y += 14) {
      c.drawRect(Rect.fromLTWH(476, y, 28, 5), win);
      c.drawRect(Rect.fromLTWH(526, y, 28, 5), win);
    }
    // Câmara (cuia virada para cima)
    c.drawArc(const Rect.fromLTWH(300, b - 36 - 80, 160, 80), 0, math.pi, true, col);
    c.drawRect(const Rect.fromLTWH(372, b - 40, 16, 6), col);
    // Senado (cúpula)
    c.drawArc(const Rect.fromLTWH(640, b - 36 - 56, 120, 112), math.pi, math.pi, true, col);
    // rampa
    c.drawPath(
      Path()
        ..moveTo(860, b - 36)
        ..lineTo(980, b)
        ..lineTo(880, b)
        ..close(),
      col,
    );
    // bandeira
    c.drawLine(const Offset(600, b - 36), const Offset(600, b - 150), stroke(_theme.skyline, 4));
    c.drawRect(const Rect.fromLTWH(600, b - 150, 46, 30), fill(const Color(0xFF009C3B)));
    c.drawPath(
      Path()
        ..moveTo(623, b - 147)
        ..lineTo(643, b - 135)
        ..lineTo(623, b - 123)
        ..lineTo(603, b - 135)
        ..close(),
      fill(const Color(0xFFFFDF00)),
    );
    c.drawCircle(const Offset(623, b - 135), 6, fill(const Color(0xFF002776)));

    // Esplanada dos Ministérios
    for (var i = 0; i < 8; i++) {
      final x = 1060.0 + i * 92;
      c.drawRect(Rect.fromLTWH(x, b - 120, 70, 120), col);
      for (double y = b - 112; y < b - 10; y += 12) {
        c.drawRect(Rect.fromLTWH(x + 6, y, 58, 4), win);
      }
    }

    // Catedral
    const cx = 2050.0;
    final rib = stroke(_theme.skyline, 7);
    for (var i = 0; i < 16; i++) {
      final k = i - 7.5;
      final path = Path()
        ..moveTo(cx + k * 7, b)
        ..quadraticBezierTo(cx + k * 2.5, b - 70, cx + k * 9, b - 150);
      c.drawPath(path, rib);
    }
    c.drawLine(const Offset(cx, b - 150), const Offset(cx, b - 190), stroke(_theme.skyline, 4));
    c.drawLine(const Offset(cx - 12, b - 178), const Offset(cx + 12, b - 178), stroke(_theme.skyline, 4));

    return rec.endRecording();
  }

  // ------------------------------------------------------------------ camada média
  Picture _recordMid() {
    final rec = PictureRecorder();
    final c = Canvas(rec);
    const gy = MamataGame.groundY - 26;
    final r = math.Random(11);

    // arbustos
    final bush = fill(Color.lerp(_theme.mid, const Color(0xFF000000), 0.1)!);
    for (double x = 0; x < midTile; x += 60) {
      c.drawCircle(Offset(x, gy + 4), 28 + r.nextDouble() * 10, bush);
    }

    void tree(double x, double s, Color crown) {
      c.drawRect(Rect.fromLTWH(x - 6 * s, gy - 90 * s, 12 * s, 92 * s), fill(const Color(0xFF5D4037)));
      final p = fill(crown);
      c.drawCircle(Offset(x, gy - 110 * s), 46 * s, p);
      c.drawCircle(Offset(x - 40 * s, gy - 90 * s), 34 * s, p);
      c.drawCircle(Offset(x + 40 * s, gy - 92 * s), 36 * s, p);
    }

    void lamp(double x) {
      final pole = stroke(const Color(0xFF37474F), 6);
      c.drawLine(Offset(x, gy), Offset(x, gy - 210), pole);
      c.drawLine(Offset(x, gy - 210), Offset(x + 40, gy - 220), pole);
      c.drawCircle(Offset(x + 42, gy - 214), 9, fill(_theme.night ? const Color(0xFFFFF59D) : const Color(0xFFECEFF1)));
      if (_theme.night) {
        c.drawCircle(
          Offset(x + 42, gy - 210),
          70,
          Paint()
            ..shader = Gradient.radial(
                Offset(x + 42, gy - 210), 70, [const Color(0x55FFF59D), const Color(0x00FFF59D)]),
        );
      }
    }

    void billboard(double x, String text, Color bg) {
      c.drawLine(Offset(x + 30, gy), Offset(x + 30, gy - 120), stroke(const Color(0xFF455A64), 8));
      c.drawLine(Offset(x + 150, gy), Offset(x + 150, gy - 120), stroke(const Color(0xFF455A64), 8));
      cartoonRRect(c, Rect.fromLTWH(x, gy - 210, 180, 96), bg, radius: 6, outline: 4);
      // "santinho" do candidato
      cartoonCircle(c, Offset(x + 34, gy - 168), 20, const Color(0xFFF1C27D), outline: 2);
      c.drawCircle(Offset(x + 27, gy - 172), 4.5, fill(const Color(0xFF111111)));
      c.drawCircle(Offset(x + 41, gy - 172), 4.5, fill(const Color(0xFF111111)));
      c.drawLine(Offset(x + 27, gy - 173), Offset(x + 41, gy - 173), stroke(const Color(0xFF111111), 2));
      c.drawArc(Rect.fromLTWH(x + 25, gy - 168, 18, 10), 0.2, 2.7, false, stroke(const Color(0xFF7B1E1E), 2.5));
      c.drawArc(Rect.fromLTWH(x + 14, gy - 190, 40, 24), 3.4, 2.6, false, stroke(const Color(0xFF9E9E9E), 4));
      Label(text, size: 22, color: const Color(0xFFFFFFFF), strokeWidth: 4)
          .paintCentered(c, Offset(x + 110, gy - 172));
      Label('MAMATA', size: 12, color: const Color(0xFFFFD60A), strokeWidth: 3)
          .paintCentered(c, Offset(x + 110, gy - 140));
    }

    final ipe = _theme.night ? const Color(0xFF8D6E2A) : const Color(0xFFFFD54F);
    final ipeRoxo = _theme.night ? const Color(0xFF5E3A6E) : const Color(0xFFCE93D8);
    tree(120, 1.0, _theme.mid);
    lamp(330);
    billboard(430, 'VOTE 171', const Color(0xFF1565C0));
    tree(740, 0.9, ipe);
    lamp(900);
    tree(1060, 1.1, _theme.mid);
    billboard(1180, 'CONFIA!', const Color(0xFFD62828));
    tree(1500, 0.85, ipeRoxo);
    lamp(1620);

    return rec.endRecording();
  }
}

class _Cloud {
  _Cloud(this.x, this.y, this.s);
  double x, y, s;
}
