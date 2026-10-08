import 'dart:ui';

import 'package:flame/components.dart';

import '../mamata_game.dart';

/// Base de tudo que rola pela tela em direção ao jogador.
abstract class Entity extends PositionComponent with HasGameReference<MamataGame> {
  Entity({super.position, super.size, super.priority});

  /// Velocidade própria extra em direção ao jogador (px/s).
  double extraSpeed = 0;

  /// Se ainda pode interagir com o jogador.
  bool active = true;

  double age = 0;

  Rect get hitbox => toRect().deflate(6);

  /// Chamado pelo jogo quando a hitbox encosta na do jogador.
  void onPlayerContact();

  @override
  void onMount() {
    super.onMount();
    game.entities.add(this);
  }

  @override
  void onRemove() {
    game.entities.remove(this);
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    age += dt;
    x -= (game.worldSpeed + (game.isRunning ? extraSpeed : 0)) * dt;
    if (x + width < -400) removeFromParent();
  }
}
