import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../util/format.dart';
import 'components/background.dart';
import 'components/citizen.dart';
import 'components/collectibles.dart';
import 'components/effects.dart';
import 'components/entity.dart';
import 'components/finish_line.dart';
import 'components/obstacle.dart';
import 'components/player.dart';
import 'components/tax_projectile.dart';
import 'components/truth.dart';
import 'levels.dart';

enum GamePhase { menu, intro, countdown, playing, caught, finishing, ended }

class BannerMsg {
  BannerMsg(this.title, {this.subtitle, this.color = const Color(0xFFFFD60A)}) : id = _next++;
  static int _next = 0;
  final String title;
  final String? subtitle;
  final Color color;
  final int id;
}

class PowerStatus {
  const PowerStatus(this.label, this.ratio, this.color);
  final String label;
  final double ratio;
  final Color color;
}

class LevelResult {
  LevelResult({
    required this.level,
    required this.completed,
    required this.money,
    required this.moneyAvailable,
    required this.taxes,
    required this.taxMoney,
    required this.orangesUsed,
    required this.hits,
    required this.stars,
    required this.record,
    required this.headline,
  });

  final LevelConfig level;
  final bool completed;
  final int money;
  final int moneyAvailable;
  final int taxes;
  final int taxMoney;
  final int orangesUsed;
  final int hits;
  final int stars;
  final bool record;
  final String headline;

  double get percent => moneyAvailable == 0 ? 0 : money / moneyAvailable;
}

class MamataGame extends FlameGame with KeyboardEvents {
  static const double virtualHeight = 720;
  static const double minVirtualWidth = 1280;
  static const double groundY = 600;
  static const double playerX = 340;
  static const double maxTruthGap = 420;
  static const int maxOranges = 5;

  final math.Random rnd = math.Random();
  final List<Entity> entities = [];

  late final Background background;
  late final Player player;
  late final Truth truth;

  double viewWidth = minVirtualWidth;
  double _viewTop = 0;
  double get viewTop => _viewTop;

  GamePhase phase = GamePhase.menu;
  LevelConfig level = levels.first;

  double traveled = 0;
  double speed = 0;
  double worldSpeed = 0;
  double truthGap = maxTruthGap;
  int oranges = 0;
  int money = 0;
  int moneyAvailable = 0;
  int taxes = 0;
  int taxMoney = 0;
  int orangesUsed = 0;
  int hits = 0;
  double foroTime = 0;
  double emendaTime = 0;

  double _nextSpawnAt = 0;
  double _lastOrangeAt = 0;
  FinishLine? _finish;
  double _countdown = 0;
  int _lastCount = 0;
  double _phaseTimer = 0;
  double _alarmCooldown = 0;
  double _taxCooldown = 0;
  double _shake = 0;
  double _bannerTimer = 0;
  double _hintTimer = 0;
  double _goTimer = 0;
  bool _dangerWarned = false;
  final Set<ObstacleType> _hinted = {};
  LevelResult? lastResult;

  // ---- estado observado pela interface Flutter
  final moneyN = ValueNotifier<int>(0);
  final orangesN = ValueNotifier<int>(0);
  final progressN = ValueNotifier<double>(0);
  final dangerN = ValueNotifier<double>(0);
  final countdownN = ValueNotifier<String?>(null);
  final bannerN = ValueNotifier<BannerMsg?>(null);
  final powerN = ValueNotifier<PowerStatus?>(null);
  final taxCooldownN = ValueNotifier<double>(0);
  final hintsN = ValueNotifier<bool>(false);

  bool get isRunning => phase == GamePhase.playing;

  @override
  Color backgroundColor() => const Color(0xFF0B1033);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    background = Background();
    player = Player();
    truth = Truth();
    await world.addAll([background, player, truth]);
    _applyZoom(size);
    player.reset();
    truth.reset();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _applyZoom(size);
  }

  void _applyZoom(Vector2 s) {
    if (s.x <= 0 || s.y <= 0) return;
    // Garante ao menos 1280x720 visíveis; sobra de altura vira céu acima.
    final zoom = math.min(s.y / virtualHeight, s.x / minVirtualWidth);
    camera.viewfinder.zoom = zoom;
    viewWidth = s.x / zoom;
    _viewTop = -(s.y / zoom - virtualHeight);
    camera.viewfinder.position = Vector2(0, _viewTop);
  }

  // ================================================================ fluxo
  void _setOverlays(List<String> names) {
    overlays.removeAll(overlays.activeOverlays.toList());
    overlays.addAll(names);
  }

  void startLevel(int number) {
    level = levels[number - 1];
    if (paused) resumeEngine();
    _resetRun();
    background.setTheme(level.sky);
    phase = GamePhase.intro;
    _setOverlays(['intro']);
    AudioService.instance.playMusic(Music.menu);
  }

  void beginCountdown() {
    phase = GamePhase.countdown;
    _countdown = 3;
    _lastCount = 4;
    _setOverlays(['hud']);
  }

  void pauseGame() {
    if (phase != GamePhase.playing && phase != GamePhase.countdown) return;
    if (paused) return;
    player.endSlide();
    pauseEngine();
    overlays.add('pause');
    AudioService.instance.pauseMusic();
  }

  void resumeGame() {
    overlays.remove('pause');
    resumeEngine();
    AudioService.instance.resumeMusic();
  }

  void restartLevel() => startLevel(level.number);

  void nextLevel() {
    if (level.number < levels.length) {
      startLevel(level.number + 1);
    } else {
      goToMenu();
    }
  }

  void goToMenu() {
    if (paused) resumeEngine();
    _resetRun();
    phase = GamePhase.menu;
    background.setTheme(levels.first.sky);
    _setOverlays(['menu']);
    AudioService.instance.playMusic(Music.menu);
  }

  void _resetRun() {
    for (final e in List.of(entities)) {
      e.removeFromParent();
    }
    entities.clear();
    for (final c in world.children.where((c) => c is FloatingText || c is Burst || c is TaxProjectile).toList()) {
      c.removeFromParent();
    }
    traveled = 0;
    speed = level.baseSpeed;
    worldSpeed = 0;
    truthGap = maxTruthGap;
    oranges = level.number >= 3 ? 1 : 0;
    money = 0;
    moneyAvailable = 0;
    taxes = 0;
    taxMoney = 0;
    orangesUsed = 0;
    hits = 0;
    foroTime = 0;
    emendaTime = 0;
    _nextSpawnAt = 900;
    _lastOrangeAt = 0;
    _finish = null;
    _phaseTimer = 0;
    _alarmCooldown = 0;
    _taxCooldown = 0;
    _shake = 0;
    _dangerWarned = false;
    _hinted.clear();
    _bannerTimer = 0;
    _goTimer = 0;
    final showHints = level.number == 1 || !StorageService.instance.tutorialSeen;
    _hintTimer = showHints ? 7 : 0;
    lastResult = null;
    player.reset();
    truth.reset();
    moneyN.value = 0;
    orangesN.value = oranges;
    progressN.value = 0;
    dangerN.value = 0;
    countdownN.value = null;
    bannerN.value = null;
    powerN.value = null;
    taxCooldownN.value = 0;
    hintsN.value = false;
  }

  // ================================================================ entrada
  void jumpPressed() {
    if (isRunning) player.jump();
  }

  void slidePressed() {
    if (isRunning) player.startSlide();
  }

  void slideReleased() => player.endSlide();

  void throwTax() {
    if (!isRunning || _taxCooldown > 0) return;
    _taxCooldown = 0.45;
    player.throwAnim = 0.25;
    final y = player.sliding ? groundY - 40 : player.y + 52;
    world.add(TaxProjectile(Vector2(player.x + 60, y)));
    AudioService.instance.play(Sfx.throwTax);
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final k = event.logicalKey;
    final down = event is KeyDownEvent;
    final up = event is KeyUpEvent;
    if (down && (k == LogicalKeyboardKey.space || k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.keyW)) {
      jumpPressed();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.keyS) {
      if (down) slidePressed();
      if (up) slideReleased();
      return KeyEventResult.handled;
    }
    if (down && (k == LogicalKeyboardKey.keyX || k == LogicalKeyboardKey.keyF || k == LogicalKeyboardKey.enter)) {
      throwTax();
      return KeyEventResult.handled;
    }
    if (down && (k == LogicalKeyboardKey.escape || k == LogicalKeyboardKey.keyP)) {
      paused ? resumeGame() : pauseGame();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ================================================================ loop
  @override
  void update(double dt) {
    dt = math.min(dt, 1 / 30);
    switch (phase) {
      case GamePhase.menu:
        worldSpeed = 160;
        player.forcedPose = PlayerPose.run;
      case GamePhase.intro:
        worldSpeed = 0;
        player.forcedPose = null;
      case GamePhase.countdown:
        worldSpeed = 0;
        _updateCountdown(dt);
      case GamePhase.playing:
        _updatePlaying(dt);
      case GamePhase.caught:
        worldSpeed = math.max(0, worldSpeed - 900 * dt);
        _phaseTimer += dt;
        if (_phaseTimer > 1.9) {
          phase = GamePhase.ended;
          _setOverlays(['gameover']);
        }
      case GamePhase.finishing:
        worldSpeed = math.max(0, worldSpeed - 500 * dt);
        _phaseTimer += dt;
        if ((_phaseTimer * 4).floor() != ((_phaseTimer - dt) * 4).floor() && _phaseTimer < 2) {
          _confetti(Vector2(viewWidth * (0.3 + rnd.nextDouble() * 0.6), 120 + rnd.nextDouble() * 200));
        }
        if (_phaseTimer > 2.4) {
          phase = GamePhase.ended;
          _setOverlays([level.isFinal ? 'victory' : 'complete']);
        }
      case GamePhase.ended:
        worldSpeed = 0;
    }

    if (_goTimer > 0) {
      _goTimer -= dt;
      if (_goTimer <= 0) countdownN.value = null;
    }
    if (_bannerTimer > 0) {
      _bannerTimer -= dt;
      if (_bannerTimer <= 0) bannerN.value = null;
    }

    // tremor de câmera
    if (_shake > 0) {
      _shake = math.max(0, _shake - dt);
      final m = _shake * 40;
      camera.viewfinder.position = Vector2((rnd.nextDouble() - 0.5) * m, _viewTop + (rnd.nextDouble() - 0.5) * m);
    } else {
      camera.viewfinder.position = Vector2(0, _viewTop);
    }

    super.update(dt);
  }

  void _updateCountdown(double dt) {
    _countdown -= dt;
    final n = _countdown.ceil();
    if (n != _lastCount && n > 0) {
      _lastCount = n;
      countdownN.value = '$n';
      AudioService.instance.play(Sfx.beep);
    }
    if (_countdown <= 0) {
      phase = GamePhase.playing;
      countdownN.value = 'MAMATA!';
      _goTimer = 0.8;
      AudioService.instance.play(Sfx.go);
      AudioService.instance.playMusic(Music.game);
      if (_hintTimer > 0) hintsN.value = true;
    }
  }

  void _updatePlaying(double dt) {
    final progress = (traveled / level.length).clamp(0.0, 1.0);
    speed = level.baseSpeed + (level.maxSpeed - level.baseSpeed) * progress;
    worldSpeed = speed * (player.stumbleTime > 0 ? 0.55 : 1.0);
    traveled += worldSpeed * dt;

    if (player.stumbleTime <= 0) {
      truthGap = math.min(maxTruthGap, truthGap + level.truthRecovery * dt);
    }

    if (foroTime > 0) foroTime -= dt;
    if (emendaTime > 0) emendaTime -= dt;
    if (_taxCooldown > 0) _taxCooldown -= dt;
    if (_hintTimer > 0) {
      _hintTimer -= dt;
      if (_hintTimer <= 0) hintsN.value = false;
    }

    // geração de conteúdo
    if (traveled >= _nextSpawnAt) {
      final wasObstacle = _spawnSlot();
      final scale = speed / level.baseSpeed;
      var gap = (level.minGap + rnd.nextDouble() * (level.maxGap - level.minGap)) * scale;
      // depois de um escândalo, garante tempo de aterrissar e reagir ao próximo
      if (wasObstacle) gap = math.max(gap, speed * 0.95);
      _nextSpawnAt = traveled + gap;
    }

    // chegada
    final remaining = level.length - traveled;
    if (_finish == null && remaining <= viewWidth) {
      _finish = FinishLine(playerX + 32 - 150 + remaining, level.finishLabel, reelection: level.isFinal)
        ..active = false;
      world.add(_finish!);
    }
    if (_finish != null && _finish!.x + 150 <= player.x + 32) {
      _completeLevel();
      return;
    }

    // colisões
    final pr = player.hitbox;
    for (final e in List.of(entities)) {
      if (!e.active) continue;
      if (e.hitbox.overlaps(pr)) e.onPlayerContact();
      if (phase != GamePhase.playing) return;
    }

    // perigo
    final danger = 1 - truthGap / maxTruthGap;
    if (truthGap < 150) {
      _alarmCooldown -= dt;
      if (_alarmCooldown <= 0) {
        _alarmCooldown = 1.4;
        AudioService.instance.play(Sfx.alarm);
      }
      if (!_dangerWarned) {
        _dangerWarned = true;
        _banner('A VERDADE ESTÁ CHEGANDO!', subtitle: 'Fuja sem tropeçar!', color: const Color(0xFFFF5252));
      }
    } else if (truthGap > 260) {
      _dangerWarned = false;
    }

    // notifica a interface (valores quantizados para evitar rebuilds à toa)
    final p = (progress * 400).round() / 400;
    if (p != progressN.value) progressN.value = p;
    final d = (danger * 50).round() / 50;
    if (d != dangerN.value) dangerN.value = d;
    final cd = (_taxCooldown / 0.45 * 10).ceil() / 10;
    if (cd != taxCooldownN.value) taxCooldownN.value = math.max(0, cd);
    _updatePowerStatus();
  }

  void _updatePowerStatus() {
    PowerStatus? s;
    if (foroTime > 0) {
      s = PowerStatus('FORO PRIVILEGIADO', foroTime / 6, PowerUpType.foro.color);
    } else if (emendaTime > 0) {
      s = PowerStatus('EMENDA PARLAMENTAR', emendaTime / 8, PowerUpType.emenda.color);
    }
    final cur = powerN.value;
    if (s == null && cur == null) return;
    if (s != null && cur != null && s.label == cur.label && (s.ratio * 40).round() == (cur.ratio * 40).round()) return;
    powerN.value = s;
  }

  // ================================================================ geração
  /// Gera o conteúdo de um trecho. Retorna `true` se gerou um obstáculo.
  bool _spawnSlot() {
    final x = viewWidth + 80;
    final remaining = level.length - traveled;
    if (remaining < viewWidth + 500) return false;

    if (traveled > 1400 && rnd.nextDouble() < level.obstacleChance) {
      _spawnObstacle(level.obstacles[rnd.nextInt(level.obstacles.length)], x);
      return true;
    }
    if (traveled - _lastOrangeAt > 3400) {
      _spawnOrange(x, air: rnd.nextBool());
      return false;
    }
    final r = rnd.nextDouble();
    if (r < 0.42) {
      _spawnMoneyRow(x);
    } else if (r < 0.70) {
      _spawnCitizens(x);
    } else if (r < 0.86) {
      _spawnOrange(x, air: rnd.nextDouble() < 0.4);
    } else {
      _spawnPowerUp(x);
    }
    return false;
  }

  List<ObstacleType> get _newObstacleTypes {
    if (level.number == 1) return level.obstacles;
    final prev = levels[level.number - 2].obstacles;
    return level.obstacles.where((t) => !prev.contains(t)).toList();
  }

  void _spawnObstacle(ObstacleType type, double x) {
    final o = Obstacle(type, x);
    world.add(o);
    if (!_hinted.contains(type) && _newObstacleTypes.contains(type)) {
      _hinted.add(type);
      _banner(o.info.name.toUpperCase(), subtitle: o.info.hint, color: const Color(0xFF80D8FF));
    }
    if (o.extraSpeed > 0) return; // obstáculos móveis não carregam recompensas
    final cx = x + o.width / 2;
    final r = rnd.nextDouble();
    if (r < 0.55) {
      // arco de dinheiro por cima
      for (var i = -2; i <= 2; i++) {
        final bx = cx + i * 56 - 20;
        final by = groundY - o.height - 70 - (2 - i.abs()) * 34 - 44;
        _addMoney(Vector2(bx, by));
      }
    } else if (r < 0.7) {
      world.add(OrangeFruit(Vector2(cx - 20, groundY - o.height - 120)));
      _lastOrangeAt = traveled;
    }
  }

  void _addMoney(Vector2 pos, {int value = 50}) {
    world.add(MoneyBag(pos, value: value));
    moneyAvailable += value;
  }

  void _spawnMoneyRow(double x) {
    final pattern = rnd.nextInt(3);
    for (var i = 0; i < 5; i++) {
      final bx = x + i * 56;
      final by = switch (pattern) {
        0 => groundY - 64,
        1 => groundY - 230,
        _ => groundY - 110 - math.sin(i / 4 * math.pi) * 120,
      };
      _addMoney(Vector2(bx, by));
    }
  }

  void _spawnCitizens(double x) {
    final n = 1 + (rnd.nextDouble() < 0.4 ? 1 : 0);
    for (var i = 0; i < n; i++) {
      world.add(Citizen(x + i * 110, rnd));
      moneyAvailable += (level.taxValue * 1.5).round();
    }
  }

  void _spawnOrange(double x, {bool air = false}) {
    world.add(OrangeFruit(Vector2(x, air ? groundY - 220 : groundY - 70)));
    _lastOrangeAt = traveled;
  }

  void _spawnPowerUp(double x) {
    final r = rnd.nextDouble();
    final danger = truthGap < 250;
    final PowerUpType type;
    if (danger && r < 0.5) {
      type = PowerUpType.fakeNews;
    } else if (r < 0.28) {
      type = PowerUpType.foro;
    } else if (r < 0.52) {
      type = PowerUpType.fakeNews;
    } else if (r < 0.78) {
      type = PowerUpType.emenda;
    } else {
      type = PowerUpType.mala;
    }
    world.add(PowerUp(type, Vector2(x, groundY - 170)));
    if (type == PowerUpType.mala) moneyAvailable += 500;
  }

  // ================================================================ eventos
  void addMoney(int value) {
    money += value;
    moneyN.value = money;
  }

  void collectMoney(MoneyBag bag) {
    addMoney(bag.value);
    AudioService.instance.play(Sfx.coin);
    final c = bag.position + bag.size / 2;
    world.add(Burst(
      origin: c,
      colors: const [Color(0xFF66BB6A), Color(0xFFFFD60A), Color(0xFFFFFFFF)],
      count: 8,
      speed: 180,
      gravity: 300,
      size: 4,
      life: 0.4,
    ));
    world.add(FloatingText('+${bag.value}', c.clone()..y -= 20,
        color: const Color(0xFF9CFF57), size: 18, life: 0.6, rise: 90));
  }

  void collectOrange(OrangeFruit o) {
    AudioService.instance.play(Sfx.orange);
    final c = o.position + o.size / 2;
    if (oranges < maxOranges) {
      oranges++;
      orangesN.value = oranges;
      world.add(FloatingText('+1 LARANJA', c.clone()..y -= 30, color: const Color(0xFFFFA726), size: 22));
    } else {
      addMoney(30);
      world.add(FloatingText('LARANJAL CHEIO! +30', c.clone()..y -= 30, color: const Color(0xFFFFA726), size: 20));
    }
    world.add(Burst(
      origin: c,
      colors: const [Color(0xFFFF8C00), Color(0xFFFFCC80), Color(0xFF43A047)],
      count: 12,
      speed: 220,
      gravity: 400,
      life: 0.5,
    ));
  }

  void collectPowerUp(PowerUp p) {
    AudioService.instance.play(Sfx.powerup);
    final c = p.position + p.size / 2;
    switch (p.type) {
      case PowerUpType.foro:
        foroTime = 6;
        _banner('FORO PRIVILEGIADO!', subtitle: 'Nenhum escândalo te atinge', color: p.type.color);
      case PowerUpType.emenda:
        emendaTime = 8;
        _banner('EMENDA PARLAMENTAR!', subtitle: 'O dinheiro vem até você', color: const Color(0xFFE1BEE7));
      case PowerUpType.fakeNews:
        truthGap = maxTruthGap;
        _banner('FAKE NEWS!', subtitle: 'A Verdade se perdeu no grupo da família', color: const Color(0xFFFF8A80));
      case PowerUpType.mala:
        addMoney(500);
        world.add(FloatingText('+R\$ 500 mil', c.clone()..y -= 30, color: const Color(0xFF9CFF57), size: 28));
    }
    world.add(Burst(origin: c, colors: [p.type.color, const Color(0xFFFFFFFF)], count: 20, speed: 320, gravity: 200));
  }

  void taxCitizen(Citizen c, {required bool ranged}) {
    final value = ranged ? (level.taxValue * 1.5).round() : level.taxValue;
    c.markTaxed();
    addMoney(value);
    taxes++;
    taxMoney += value;
    AudioService.instance.play(Sfx.tax);
    final name = kTaxNames[rnd.nextInt(kTaxNames.length)];
    final pos = Vector2(c.x + c.width / 2, c.y - 10);
    world.add(FloatingText('+R\$ $value mil', pos.clone(), color: const Color(0xFF9CFF57), size: 22, life: 1.1));
    world.add(FloatingText(name.toUpperCase(), pos.clone()..y += 26, color: const Color(0xFFFFFFFF), size: 16, life: 1.1));
    world.add(Burst(
      origin: pos,
      colors: const [Color(0xFFFFD60A), Color(0xFFFFF59D)],
      count: 10,
      speed: 240,
      gravity: 700,
      life: 0.7,
    ));
  }

  void onObstacleHit(Obstacle o) {
    final center = Vector2(player.x + 32, player.y + 30);
    if (foroTime > 0) {
      o.smash();
      AudioService.instance.play(Sfx.shield);
      addMoney(20);
      world.add(FloatingText('FORO PRIVILEGIADO!', center.clone()..y -= 40, color: const Color(0xFFFFD60A), size: 20));
      return;
    }
    if (player.invulnerable > 0) {
      o.ghost = true;
      return;
    }
    if (oranges > 0) {
      oranges--;
      orangesUsed++;
      orangesN.value = oranges;
      o.ghost = true;
      player.invulnerable = 0.5;
      AudioService.instance.play(Sfx.shield);
      AudioService.instance.vibrate();
      world.add(FloatingText('A LARANJA ASSUMIU A CULPA!', center.clone()..y -= 50,
          color: const Color(0xFFFFA726), size: 22, life: 1.3));
      world.add(Burst(
        origin: center,
        colors: const [Color(0xFFFF8C00), Color(0xFFFFCC80)],
        count: 18,
        speed: 300,
        gravity: 600,
        size: 6,
      ));
      return;
    }
    // escândalo!
    hits++;
    truthGap -= level.hitPenalty;
    player.stumble();
    _shake = 0.35;
    AudioService.instance.play(Sfx.hit);
    AudioService.instance.vibrate(heavy: true);
    _banner(o.info.headline, subtitle: 'A Verdade se aproximou!', color: const Color(0xFFFF5252));
    world.add(Burst(
      origin: center,
      colors: const [Color(0xFFFFFFFF), Color(0xFFFF5252), Color(0xFFFFD60A)],
      count: 16,
      speed: 300,
      gravity: 500,
    ));
    if (truthGap <= 0) _caught();
  }

  void _banner(String title, {String? subtitle, Color color = const Color(0xFFFFD60A)}) {
    bannerN.value = BannerMsg(title, subtitle: subtitle, color: color);
    _bannerTimer = 2.2;
  }

  void _confetti(Vector2 at) {
    world.add(Burst(
      origin: at,
      colors: const [
        Color(0xFF009C3B),
        Color(0xFFFFDF00),
        Color(0xFF002776),
        Color(0xFFFFFFFF),
        Color(0xFFFF5252),
      ],
      count: 40,
      speed: 520,
      gravity: 500,
      size: 6,
      life: 1.8,
      squares: true,
      drag: 1.2,
    ));
  }

  void dust(Vector2 at) {
    world.add(Burst(
      origin: at,
      colors: const [Color(0xAAFFFFFF), Color(0x88BDBDBD)],
      count: 6,
      speed: 120,
      gravity: -40,
      size: 6,
      life: 0.4,
      spreadAngle: 1.6,
      direction: -math.pi * 0.85,
    ));
  }

  void puff(Vector2 at) {
    world.add(Burst(
      origin: at,
      colors: const [Color(0xCCFFFFFF)],
      count: 8,
      speed: 160,
      gravity: 0,
      size: 7,
      life: 0.35,
      direction: math.pi / 2,
      spreadAngle: 2.4,
    ));
  }

  // ================================================================ fim de fase
  void _caught() {
    phase = GamePhase.caught;
    _phaseTimer = 0;
    truthGap = 0;
    player.forcedPose = PlayerPose.caught;
    player.sliding = false;
    hintsN.value = false;
    bannerN.value = null;
    AudioService.instance.stopMusic();
    AudioService.instance.play(Sfx.caught);
    AudioService.instance.vibrate(heavy: true);
    _shake = 0.6;
    final headline = kCaughtHeadlines[rnd.nextInt(kCaughtHeadlines.length)].replaceAll('{m}', formatMoney(money));
    lastResult = LevelResult(
      level: level,
      completed: false,
      money: money,
      moneyAvailable: moneyAvailable,
      taxes: taxes,
      taxMoney: taxMoney,
      orangesUsed: orangesUsed,
      hits: hits,
      stars: 0,
      record: false,
      headline: headline,
    );
    overlays.remove('hud');
  }

  Future<void> _completeLevel() async {
    phase = GamePhase.finishing;
    _phaseTimer = 0;
    player.forcedPose = PlayerPose.cheer;
    player.sliding = false;
    hintsN.value = false;
    bannerN.value = null;
    progressN.value = 1;
    AudioService.instance.stopMusic();
    AudioService.instance.play(Sfx.levelComplete);
    _confetti(Vector2(playerX + 200, 200));

    var stars = 1;
    if (hits <= 1) stars++;
    if (moneyAvailable > 0 && money >= moneyAvailable * 0.6) stars++;
    final storage = StorageService.instance;
    lastResult = LevelResult(
      level: level,
      completed: true,
      money: money,
      moneyAvailable: moneyAvailable,
      taxes: taxes,
      taxMoney: taxMoney,
      orangesUsed: orangesUsed,
      hits: hits,
      stars: stars,
      record: money > storage.bestMoneyFor(level.number),
      headline: '',
    );
    overlays.remove('hud');
    await storage.saveResult(level.number, stars, money);
    await storage.unlockLevel(math.min(levels.length, level.number + 1));
    if (level.number == 1) storage.tutorialSeen = true;
    if (level.isFinal) await storage.addReelection();
  }

  /// Usado pelo ciclo de vida do app: pausa ao ir para segundo plano.
  void onAppBackgrounded() {
    if (phase == GamePhase.playing || phase == GamePhase.countdown) {
      pauseGame();
    } else {
      AudioService.instance.pauseMusic();
    }
  }

  void onAppResumed() {
    if (!paused) AudioService.instance.resumeMusic();
  }
}
