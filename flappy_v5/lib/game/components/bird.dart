import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../flappy_game.dart';
import '../game_config.dart';
import '../game_state.dart';

class Bird extends SpriteComponent
    with CollisionCallbacks, HasGameReference<FlappyGame> {
  Bird()
      : super(
          size: Vector2(GameConfig.birdWidth, GameConfig.birdHeight),
          anchor: Anchor.center,
          priority: 10,
        );

  double velocity = 0;
  double _idleTime = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    sprite = await Sprite.load('flappy_bird_transparente.png');

    add(
      RectangleHitbox(
        size: Vector2(
          width * GameConfig.birdHitboxScale,
          height * GameConfig.birdHitboxScale,
        ),
        anchor: Anchor.center,
        position: size / 2,
        collisionType: CollisionType.active,
      ),
    );

    reset();
  }

  /// Volta para a posição inicial, parado, sem velocidade.
  void reset() {
    position.setValues(GameConfig.worldWidth / 2, GameConfig.birdStartY);
    velocity = 0;
    angle = -0.08;
    _idleTime = 0;
  }

  /// Chamado no primeiro toque da partida: dá o impulso inicial.
  void launch() {
    reset();
    velocity = GameConfig.birdStartVelocity;
  }

  void flap() {
    velocity = GameConfig.flapVelocity;
  }

  @override
  void update(double dt) {
    super.update(dt);

    switch (game.state) {
      case GameState.ready:
        _idleTime += dt;
        position.y =
            GameConfig.birdStartY + math.sin(_idleTime * 3.2) * 5.0;
        angle = math.sin(_idleTime * 3.2) * 0.06;
      case GameState.playing:
        _applyPhysics(dt);
        _checkBounds();
      case GameState.gameOver:
        // Continua caindo até bater no chão, como no jogo original.
        final floor = GameConfig.groundTop - height / 2;
        if (position.y < floor) {
          _applyPhysics(dt);
          if (position.y > floor) position.y = floor;
        } else {
          position.y = floor;
          velocity = 0;
          angle = 1.3;
        }
    }
  }

  void _applyPhysics(double dt) {
    velocity += GameConfig.gravity * dt;
    position.y += velocity * dt;
    angle = (velocity / 560).clamp(-0.45, 0.65).toDouble();
  }

  void _checkBounds() {
    final halfHeight = height / 2;

    if (position.y - halfHeight <= 0) {
      if (GameConfig.dieOnCeiling) {
        game.endGame();
        return;
      }
      // Bate no teto: para de subir mas não morre.
      position.y = halfHeight;
      if (velocity < 0) velocity = 0;
    }

    if (position.y + halfHeight >= GameConfig.groundTop) {
      position.y = GameConfig.groundTop - halfHeight;
      game.endGame();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (game.state == GameState.playing) {
      game.endGame();
    }
  }
}
