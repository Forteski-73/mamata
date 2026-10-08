import 'dart:ui';

/// Tipos de obstáculo ("escândalos") que podem aparecer no caminho.
enum ObstacleType {
  cpi,
  jornalista,
  drone,
  tcu,
  cpmi,
  pf,
  delacao,
  mandado,

  /// Arremessado por cidadãos revoltados (não aparece sozinho nas fases).
  tomate,
}

/// Paleta de céu/ambiente de cada fase.
class SkyTheme {
  const SkyTheme({
    required this.top,
    required this.bottom,
    required this.skyline,
    required this.mid,
    required this.ground,
    this.night = false,
    this.sunColor = const Color(0xFFFFF3B0),
    this.sunY = 0.22,
  });

  final Color top;
  final Color bottom;
  final Color skyline;
  final Color mid;
  final Color ground;
  final bool night;
  final Color sunColor;
  final double sunY;
}

class LevelConfig {
  const LevelConfig({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.length,
    required this.baseSpeed,
    required this.maxSpeed,
    required this.truthRecovery,
    required this.hitPenalty,
    required this.obstacles,
    required this.obstacleChance,
    required this.minGap,
    required this.maxGap,
    required this.finishLabel,
    required this.sky,
    required this.taxValue,
  });

  final int number;
  final String title;
  final String subtitle;
  final String description;

  /// Comprimento da fase em unidades virtuais (40 unidades = 1 metro).
  final double length;
  final double baseSpeed;
  final double maxSpeed;

  /// Quanto a distância para a Verdade se recupera por segundo.
  final double truthRecovery;

  /// Quanto a Verdade se aproxima a cada escândalo sofrido.
  final double hitPenalty;
  final List<ObstacleType> obstacles;
  final double obstacleChance;
  final double minGap;
  final double maxGap;
  final String finishLabel;
  final SkyTheme sky;

  /// Valor (em mil reais) arrecadado por imposto cobrado.
  final int taxValue;

  /// Chance de um cidadão taxado à distância revidar com um tomate.
  double get revoltChance => 0.3 + (number - 1) * 0.08;

  bool get isFinal => number == levels.length;
}

const double kMetersFactor = 40;

const List<LevelConfig> levels = [
  LevelConfig(
    number: 1,
    title: 'Ano 1',
    subtitle: 'A Posse',
    description:
        'Recém-empossado, o gabinete já tem cofre novo. Encha os bolsos, '
        'cobre uns impostos e não deixe a CPI te alcançar.',
    length: 22000,
    baseSpeed: 420,
    maxSpeed: 480,
    truthRecovery: 26,
    hitPenalty: 140,
    obstacles: [ObstacleType.cpi, ObstacleType.jornalista],
    obstacleChance: 0.55,
    minGap: 560,
    maxGap: 860,
    finishLabel: 'FIM DO 1º ANO',
    taxValue: 20,
    sky: SkyTheme(
      top: Color(0xFF4FA3F7),
      bottom: Color(0xFFBFE3FF),
      skyline: Color(0xFF7FA6C9),
      mid: Color(0xFF3E8E4E),
      ground: Color(0xFF6BBF59),
      sunY: 0.18,
    ),
  ),
  LevelConfig(
    number: 2,
    title: 'Ano 2',
    subtitle: 'Primeiro Escândalo',
    description:
        'A imprensa começou a desconfiar. Drones e auditorias do TCU '
        'estão por toda parte. Abaixe-se e pule alto!',
    length: 27000,
    baseSpeed: 470,
    maxSpeed: 540,
    truthRecovery: 23,
    hitPenalty: 150,
    obstacles: [
      ObstacleType.cpi,
      ObstacleType.jornalista,
      ObstacleType.drone,
      ObstacleType.tcu,
    ],
    obstacleChance: 0.62,
    minGap: 520,
    maxGap: 800,
    finishLabel: 'FIM DO 2º ANO',
    taxValue: 25,
    sky: SkyTheme(
      top: Color(0xFF3B8FE0),
      bottom: Color(0xFFFFE6A8),
      skyline: Color(0xFF8A9BB5),
      mid: Color(0xFF4C7F3A),
      ground: Color(0xFF7CB342),
      sunColor: Color(0xFFFFE082),
      sunY: 0.30,
    ),
  ),
  LevelConfig(
    number: 3,
    title: 'Ano 3',
    subtitle: 'A CPMI',
    description:
        'Instalaram a CPMI e a Polícia Federal está na rua. Guarde laranjas: '
        'elas assumem a culpa por você.',
    length: 32000,
    baseSpeed: 520,
    maxSpeed: 600,
    truthRecovery: 20,
    hitPenalty: 160,
    obstacles: [
      ObstacleType.cpi,
      ObstacleType.jornalista,
      ObstacleType.drone,
      ObstacleType.tcu,
      ObstacleType.cpmi,
      ObstacleType.pf,
    ],
    obstacleChance: 0.68,
    minGap: 490,
    maxGap: 760,
    finishLabel: 'FIM DO 3º ANO',
    taxValue: 30,
    sky: SkyTheme(
      top: Color(0xFF5B3B8C),
      bottom: Color(0xFFFF9E5E),
      skyline: Color(0xFF6B4A6E),
      mid: Color(0xFF3D5A2E),
      ground: Color(0xFF6E8F3A),
      sunColor: Color(0xFFFF7043),
      sunY: 0.55,
    ),
  ),
  LevelConfig(
    number: 4,
    title: 'Ano 4',
    subtitle: 'Rumo à Reeleição',
    description:
        'Ano eleitoral! Delações voando, mandados de busca e a Verdade '
        'mais perto do que nunca. Chegue à urna e garanta mais 4 anos.',
    length: 38000,
    baseSpeed: 570,
    maxSpeed: 660,
    truthRecovery: 17,
    hitPenalty: 170,
    obstacles: [
      ObstacleType.cpi,
      ObstacleType.jornalista,
      ObstacleType.drone,
      ObstacleType.tcu,
      ObstacleType.cpmi,
      ObstacleType.pf,
      ObstacleType.delacao,
      ObstacleType.mandado,
    ],
    obstacleChance: 0.74,
    minGap: 470,
    maxGap: 720,
    finishLabel: 'REELEIÇÃO',
    taxValue: 40,
    sky: SkyTheme(
      top: Color(0xFF0B1033),
      bottom: Color(0xFF2B3A78),
      skyline: Color(0xFF1E2756),
      mid: Color(0xFF1B3324),
      ground: Color(0xFF2F4A2A),
      night: true,
      sunColor: Color(0xFFF5F3CE),
      sunY: 0.16,
    ),
  ),
];
