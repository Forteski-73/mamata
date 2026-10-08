import 'package:shared_preferences/shared_preferences.dart';

/// Progresso do jogador e preferências, persistidos localmente.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  int get unlockedLevel => _prefs.getInt('unlockedLevel') ?? 1;

  Future<void> unlockLevel(int level) async {
    if (level > unlockedLevel) await _prefs.setInt('unlockedLevel', level);
  }

  int starsFor(int level) => _prefs.getInt('stars_$level') ?? 0;
  int bestMoneyFor(int level) => _prefs.getInt('money_$level') ?? 0;

  /// Salva o resultado e retorna `true` se for um novo recorde de dinheiro.
  Future<bool> saveResult(int level, int stars, int money) async {
    if (stars > starsFor(level)) await _prefs.setInt('stars_$level', stars);
    final isRecord = money > bestMoneyFor(level);
    if (isRecord) await _prefs.setInt('money_$level', money);
    return isRecord;
  }

  int get totalStars {
    var total = 0;
    for (var i = 1; i <= 4; i++) {
      total += starsFor(i);
    }
    return total;
  }

  int get totalBestMoney {
    var total = 0;
    for (var i = 1; i <= 4; i++) {
      total += bestMoneyFor(i);
    }
    return total;
  }

  int get reelections => _prefs.getInt('reelections') ?? 0;
  Future<void> addReelection() => _prefs.setInt('reelections', reelections + 1);

  bool get sfxOn => _prefs.getBool('sfx') ?? true;
  set sfxOn(bool v) => _prefs.setBool('sfx', v);

  bool get musicOn => _prefs.getBool('music') ?? true;
  set musicOn(bool v) => _prefs.setBool('music', v);

  bool get vibrationOn => _prefs.getBool('vibration') ?? true;
  set vibrationOn(bool v) => _prefs.setBool('vibration', v);

  bool get tutorialSeen => _prefs.getBool('tutorialSeen') ?? false;
  set tutorialSeen(bool v) => _prefs.setBool('tutorialSeen', v);

  Future<void> resetProgress() async {
    for (final key in _prefs.getKeys().toList()) {
      if (key.startsWith('stars_') ||
          key.startsWith('money_') ||
          key == 'unlockedLevel' ||
          key == 'reelections' ||
          key == 'tutorialSeen') {
        await _prefs.remove(key);
      }
    }
  }
}
