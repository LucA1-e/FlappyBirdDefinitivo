import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game_config.dart';

/// Céu do jogo.
///
/// O `background.jpg` original é 608x457 (paisagem). A versão anterior
/// esticava essa imagem inteira para 360x640, o que deformava os prédios e o
/// chão. Aqui o céu vira um degradê sólido e apenas as faixas úteis da
/// imagem são recortadas e repetidas na proporção correta.
class SkyLayer extends PositionComponent {
  SkyLayer()
      : super(
          position: Vector2.zero(),
          size: Vector2(GameConfig.worldWidth, GameConfig.worldHeight),
          priority: -100,
        );

  final Paint _paint = Paint();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _paint.shader = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(0, GameConfig.groundTop),
      const <Color>[GameConfig.skyTopColor, GameConfig.skyColor],
    );
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _paint);
  }
}

/// Faixa horizontal recortada de `background.jpg` e repetida sem deformar.
///
/// Usada tanto para a silhueta da cidade quanto para o chão.
class ScrollingStrip extends PositionComponent {
  ScrollingStrip({
    required this.srcPosition,
    required this.srcSize,
    required double tileWidth,
    required double tileHeight,
    required double top,
    required this.speedFactor,
    required int priority,
  })  : _tileWidth = tileWidth,
        super(
          position: Vector2(0, top),
          size: Vector2(GameConfig.worldWidth, tileHeight),
          priority: priority,
        );

  final Vector2 srcPosition;
  final Vector2 srcSize;
  final double speedFactor;
  final double _tileWidth;

  /// Deslocamento acumulado, sempre em `[0, tileWidth)`.
  double scroll = 0;

  Sprite? _sprite;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final flameGame = findGame();
    if (flameGame == null) {
      throw StateError('ScrollingStrip precisa estar dentro de um FlameGame.');
    }
    final ui.Image image = await flameGame.images.load('background.jpg');
    _sprite = Sprite(image, srcPosition: srcPosition, srcSize: srcSize);
  }

  void advance(double dx) {
    scroll = (scroll + dx) % _tileWidth;
    if (scroll < 0) scroll += _tileWidth;
  }

  void resetScroll() => scroll = 0;

  @override
  void render(Canvas canvas) {
    final sprite = _sprite;
    if (sprite == null) return;

    // Uma cópia a mais garante cobertura total mesmo em telas largas.
    final tiles = (GameConfig.worldWidth / _tileWidth).ceil() + 1;
    for (var i = 0; i < tiles; i++) {
      sprite.render(
        canvas,
        position: Vector2(i * _tileWidth - scroll, 0),
        size: Vector2(_tileWidth, size.y),
      );
    }
  }
}

/// Cidade + arbustos, logo acima do chão. Anda mais devagar (parallax).
class SkylineLayer extends ScrollingStrip {
  SkylineLayer()
      : super(
          srcPosition: Vector2(0, GameConfig.skylineSrcTop),
          srcSize: Vector2(
            GameConfig.bgImageWidth,
            GameConfig.skylineSrcHeight,
          ),
          tileWidth: _tileW,
          tileHeight: _tileH,
          top: GameConfig.groundTop - _tileH,
          speedFactor: GameConfig.skylineSpeedFactor,
          priority: -90,
        );

  static const double _tileW = GameConfig.worldWidth;
  static const double _tileH = GameConfig.skylineSrcHeight *
      _tileW /
      GameConfig.bgImageWidth;
}

/// Chão: a faixa texturizada no topo e cor sólida abaixo dela.
class GroundLayer extends PositionComponent {
  GroundLayer()
      : super(
          position: Vector2(0, GameConfig.groundTop),
          size: Vector2(GameConfig.worldWidth, GameConfig.groundHeight),
          priority: -80,
        );

  static const double _scale =
      GameConfig.worldWidth / GameConfig.bgImageWidth;
  static const double _tileW = GameConfig.groundSrcWidth * _scale;
  static const double _tileH = GameConfig.groundSrcHeight * _scale;

  ScrollingStrip? _strip;

  final Paint _fillPaint = Paint()..color = GameConfig.groundColor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final strip = ScrollingStrip(
      srcPosition: Vector2(0, GameConfig.groundSrcTop),
      srcSize: Vector2(
        GameConfig.groundSrcWidth,
        GameConfig.groundSrcHeight,
      ),
      tileWidth: _tileW,
      tileHeight: _tileH,
      top: 0,
      speedFactor: GameConfig.groundSpeedFactor,
      priority: 1,
    );
    await add(strip);
    _strip = strip;
  }

  void advance(double dx) => _strip?.advance(dx);

  void resetScroll() => _strip?.resetScroll();

  @override
  void render(Canvas canvas) {
    // Preenche tudo abaixo da faixa texturizada com a cor sólida do arquivo.
    canvas.drawRect(
      Rect.fromLTWH(0, _tileH - 1, size.x, size.y - _tileH + 1),
      _fillPaint,
    );
  }
}
