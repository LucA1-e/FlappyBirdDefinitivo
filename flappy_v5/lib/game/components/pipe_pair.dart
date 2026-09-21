import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../flappy_game.dart';
import '../game_config.dart';
import '../game_state.dart';
import 'stretchable_pipe.dart';

/// Um par de canos que se move como uma única entidade.
///
/// O par nunca é destruído: quando sai pela esquerda ele é reposicionado com
/// um novo vão através de [recycleTo]. Assim não há alocação nem remoção de
/// componentes durante a partida.
class PipePair extends PositionComponent with HasGameReference<FlappyGame> {
  PipePair({required double gapCenterY})
      : _gapCenterY = gapCenterY,
        super(
          size: Vector2(GameConfig.pipeWidth, GameConfig.groundTop),
          anchor: Anchor.topCenter,
        );

  double _gapCenterY;
  double get gapCenterY => _gapCenterY;

  bool scored = false;

  late final StretchablePipe _top;
  late final StretchablePipe _bottom;
  late final RectangleHitbox _topHitbox;
  late final RectangleHitbox _bottomHitbox;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // O sistema de coordenadas local de um componente começa no seu canto
    // superior esquerdo, independentemente do `anchor`. Por isso os filhos
    // ficam em x = 0 e não em -pipeWidth/2 (esse deslocamento era o que
    // desalinhava o desenho em relação à hitbox).
    _top = StretchablePipe(
      imagePath: 'Cano_Cima.png',
      width: GameConfig.pipeWidth,
      capAtEnd: true,
      position: Vector2.zero(),
    );
    _bottom = StretchablePipe(
      imagePath: 'Cano_Baixo.png',
      width: GameConfig.pipeWidth,
      capAtEnd: false,
      position: Vector2.zero(),
    );

    // As hitboxes são mais estreitas que o desenho para não contar pixels
    // transparentes da borda como colisão. Elas têm altura fixa e só são
    // deslocadas: redimensionar hitbox em tempo de execução é mais frágil.
    final hitboxWidth = GameConfig.pipeWidth * GameConfig.pipeHitboxScale;
    final hitboxX = (GameConfig.pipeWidth - hitboxWidth) / 2;
    final hitboxHeight = GameConfig.worldHeight;

    _topHitbox = RectangleHitbox(
      position: Vector2(hitboxX, 0),
      size: Vector2(hitboxWidth, hitboxHeight),
      collisionType: CollisionType.passive,
    );
    _bottomHitbox = RectangleHitbox(
      position: Vector2(hitboxX, 0),
      size: Vector2(hitboxWidth, hitboxHeight),
      collisionType: CollisionType.passive,
    );

    await addAll(<Component>[_top, _bottom, _topHitbox, _bottomHitbox]);
    _applyGap();
  }

  /// Reposiciona o par com um novo vão, reaproveitando os mesmos componentes.
  void recycleTo({required double x, required double gapCenterY}) {
    this.x = x;
    _gapCenterY = gapCenterY;
    scored = false;
    if (isLoaded) _applyGap();
  }

  void _applyGap() {
    final gapTop = _gapCenterY - GameConfig.gapHeight / 2;
    final gapBottom = _gapCenterY + GameConfig.gapHeight / 2;

    final double topHeight =
        gapTop.clamp(0.0, GameConfig.groundTop).toDouble();
    final double bottomHeight = (GameConfig.groundTop - gapBottom)
        .clamp(0.0, GameConfig.groundTop)
        .toDouble();

    _top
      ..position.setValues(0, 0)
      ..setHeight(topHeight);

    _bottom
      ..position.setValues(0, gapBottom)
      ..setHeight(bottomHeight);

    // As hitboxes têm altura fixa e "vazam" para fora da tela; essas áreas
    // nunca são alcançáveis pelo pássaro (ele é travado no teto e morre no
    // chão), então isso é seguro e evita redimensionar formas em runtime.
    _topHitbox.position.setValues(
      _topHitbox.position.x,
      topHeight - GameConfig.worldHeight,
    );
    _bottomHitbox.position.setValues(
      _bottomHitbox.position.x,
      gapBottom,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (game.state != GameState.playing) return;

    x -= GameConfig.pipeSpeed * dt;

    // O par usa Anchor.topCenter, então `x` é o centro horizontal.
    final halfWidth = width / 2;

    if (!scored && x + halfWidth < game.bird.x) {
      scored = true;
      game.addPoint();
    }

    if (x + halfWidth < 0) {
      game.recyclePipe(this);
    }
  }
}
