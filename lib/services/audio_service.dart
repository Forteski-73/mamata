import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'storage_service.dart';

enum Sfx {
  jump('jump.wav', 0.6),
  doubleJump('double_jump.wav', 0.6),
  coin('coin.wav', 0.45),
  orange('orange.wav', 0.7),
  shield('shield.wav', 0.8),
  hit('hit.wav', 0.9),
  tax('tax.wav', 0.6),
  throwTax('throw.wav', 0.5),
  powerup('powerup.wav', 0.7),
  slide('slide.wav', 0.5),
  click('click.wav', 0.6),
  alarm('alarm.wav', 0.5),
  beep('beep.wav', 0.6),
  go('go.wav', 0.6),
  caught('caught.wav', 0.9),
  levelComplete('level_complete.wav', 0.9);

  const Sfx(this.file, this.volume);
  final String file;
  final double volume;
}

enum Music {
  menu('music_menu.wav', 0.45),
  game('music_game.wav', 0.4);

  const Music(this.file, this.volume);
  final String file;
  final double volume;
}

/// Áudio centralizado: efeitos com pool (baixa latência) e música de fundo.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final Map<Sfx, AudioPool> _pools = {};
  Music? _current;
  bool _ready = false;

  StorageService get _storage => StorageService.instance;

  Future<void> init() async {
    try {
      FlameAudio.bgm.initialize();
      await FlameAudio.audioCache.loadAll([
        for (final s in Sfx.values) s.file,
        for (final m in Music.values) m.file,
      ]);
      for (final s in Sfx.values) {
        _pools[s] = await FlameAudio.createPool(
          s.file,
          maxPlayers: s == Sfx.coin ? 4 : 2,
        );
      }
      _ready = true;
    } catch (e) {
      debugPrint('Audio indisponível: $e');
    }
  }

  void play(Sfx sfx) {
    if (!_ready || !_storage.sfxOn) return;
    try {
      _pools[sfx]?.start(volume: sfx.volume);
    } catch (_) {}
  }

  void playMusic(Music music) {
    if (!_ready || !_storage.musicOn) {
      _current = music;
      return;
    }
    if (_current == music && FlameAudio.bgm.isPlaying) return;
    _current = music;
    try {
      FlameAudio.bgm.play(music.file, volume: music.volume);
    } catch (_) {}
  }

  void stopMusic() {
    try {
      FlameAudio.bgm.stop();
    } catch (_) {}
  }

  void pauseMusic() {
    try {
      FlameAudio.bgm.pause();
    } catch (_) {}
  }

  void resumeMusic() {
    if (!_storage.musicOn) return;
    try {
      FlameAudio.bgm.resume();
    } catch (_) {}
  }

  void setMusicEnabled(bool on) {
    _storage.musicOn = on;
    if (on) {
      final m = _current ?? Music.menu;
      _current = null;
      playMusic(m);
    } else {
      stopMusic();
    }
  }

  void vibrate({bool heavy = false}) {
    if (!_storage.vibrationOn || kIsWeb) return;
    heavy ? HapticFeedback.heavyImpact() : HapticFeedback.lightImpact();
  }
}
