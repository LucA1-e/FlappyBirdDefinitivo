import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game_config.dart';
import '../game_state.dart';

/// HUD do jogo, montado na viewport da câmera.
///
/// Nada aqui é adicionado ou removido durante a partida: a visibilidade é
/// controlada por texto vazio e por alfa do painel. Isso evita corridas com
/// a fila de componentes do Flame.
class GameHud extends PositionComponent {
  GameHud()
      : super(
          position: Vector2.zero(),
          size: Vector2(GameConfig.worldWidth, GameConfig.worldHeight),
          priority: 100,
        );

  static const Color _shadow = Color(0x66000000);

  late final TextComponent _score;
  late final TextComponent _title;
  late final TextComponent _hint;
  late final TextComponent _best;
  late final RectangleComponent _dim;

  static TextPaint _paint(double size, {FontWeight weight = FontWeight.bold}) {
    return TextPaint(
      style: TextStyle(
        color: Colors.white,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: 1.1,
        shadows: const <Shadow>[
          Shadow(blurRadius: 4, offset: Offset(2, 2), color: _shadow),
        ],
      ),
    );
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _dim = RectangleComponent(
      position: Vector2.zero(),
      size: size.clone(),
      paint: Paint()..color = const Color(0x00000000),
      priority: 0,
    );

    _score = TextComponent(
      text: '0',
      anchor: Anchor.topCenter,
      position: Vector2(GameConfig.worldWidth / 2, 28),
      textRenderer: _paint(GameConfig.scoreFontSize),
      priority: 1,
    );

    _title = TextComponent(
      text: '',
      anchor: Anchor.center,
      position: Vector2(
        GameConfig.worldWidth / 2,
        GameConfig.worldHeight * 0.60,
      ),
      textRenderer: _paint(GameConfig.startMessageFontSize),
      priority: 1,
    );

    _best = TextComponent(
      text: '',
      anchor: Anchor.center,
      position: Vector2(
        GameConfig.worldWidth / 2,
        GameConfig.worldHeight * 0.60 + 26,
      ),
      textRenderer: _paint(GameConfig.panelFontSize, weight: FontWeight.w600),
      priority: 1,
    );

    _hint = TextComponent(
      text: '',
      anchor: Anchor.center,
      position: Vector2(
        GameConfig.worldWidth / 2,
        GameConfig.worldHeight * 0.60 + 56,
      ),
      textRenderer: _paint(GameConfig.panelFontSize, weight: FontWeight.w600),
      priority: 1,
    );

    await addAll(<Component>[_dim, _score, _title, _best, _hint]);
  }

  /// Atualiza tudo de uma vez a partir do estado do jogo.
  void sync({
    required GameState state,
    required int score,
    required int best,
    required bool showKeyboardHint,
  }) {
    if (!isLoaded) return;

    _score.text = state == GameState.ready ? '' : '$score';

    switch (state) {
      case GameState.ready:
        _dim.paint.color = const Color(0x00000000);
        _title.text = 'Toque para começar';
        _best.text = best > 0 ? 'Recorde: $best' : '';
        _hint.text = showKeyboardHint ? 'Espaço ou clique para voar' : '';
      case GameState.playing:
        _dim.paint.color = const Color(0x00000000);
        _title.text = '';
        _best.text = '';
        _hint.text = '';
      case GameState.gameOver:
        _dim.paint.color = const Color(0x59000000);
        _title.text = 'Fim de jogo';
        _best.text = 'Pontos: $score   Recorde: $best';
        _hint.text = showKeyboardHint
            ? 'Toque, clique ou espaço para jogar de novo'
            : 'Toque para jogar de novo';
    }
  }
}
