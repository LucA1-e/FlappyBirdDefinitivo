import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
// `events.dart` traz TapCallbacks/TapDownEvent (clique do mouse e toque);
// `input.dart` traz KeyboardEvents. Dependendo da versão do Flame um deles
// reexporta o outro, então manter os dois é inofensivo e evita surpresa.
import 'package:flame/events.dart';
import 'package:flame/input.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import 'components/background.dart';
import 'components/bird.dart';
import 'components/pipe_pair.dart';
import 'game_config.dart';
import 'game_state.dart';
import 'hud/game_hud.dart';

/// Loop principal, máquina de estados e entrada.
///
/// `TapCallbacks` cobre toque na tela **e clique do mouse** no desktop/web:
/// o Flutter entrega o clique do botão esquerdo como um evento de toque, e
/// `onTapDown` dispara já no momento em que o botão desce (sem esperar o
/// botão subir), que é o que dá a sensação de resposta imediata no pulo.
class FlappyGame extends FlameGame
    with HasCollisionDetection, TapCallbacks, KeyboardEvents {
  FlappyGame()
      : super(
          world: World(),
          camera: CameraComponent.withFixedResolution(
            width: GameConfig.worldWidth,
            height: GameConfig.worldHeight,
          ),
        );

  // `final`, não `const`: LogicalKeyboardKey não tem igualdade primitiva,
  // então o compilador rejeita um Set const dessas chaves (erro visto no
  // build: "Constant evaluation error... does not have a primitive
  // equality"). `final` calcula o mesmo Set uma única vez, em runtime.
  static final Set<LogicalKeyboardKey> _flapKeys = <LogicalKeyboardKey>{
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.keyW,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
  };

  final Random _random = Random();
  final List<PipePair> _pipes = <PipePair>[];

  late final Bird bird;
  late final GameHud hud;
  late final SkylineLayer _skyline;
  late final GroundLayer _ground;

  GameState state = GameState.ready;
  int score = 0;
  int bestScore = 0;

  double _gameOverTimer = 0;
  bool _hudReady = false;

  /// No desktop e na web mostramos a dica de teclado.
  bool get _hasKeyboard =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Faz a câmera enxergar o mundo a partir do canto superior esquerdo,
    // que é a origem usada por todos os componentes.
    camera.viewfinder.anchor = Anchor.topLeft;

    _skyline = SkylineLayer();
    _ground = GroundLayer();
    bird = Bird();

    await world.addAll(<Component>[SkyLayer(), _skyline, _ground, bird]);

    hud = GameHud();
    await camera.viewport.add(hud);
    _hudReady = true;

    _createPipes();
    _syncHud();
  }

  // ---------------------------------------------------------------------
  // Entrada
  // ---------------------------------------------------------------------

  @override
  void onTapDown(TapDownEvent event) {
    event.handled = true;
    handleInput();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (_flapKeys.contains(event.logicalKey)) {
      handleInput();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyR) {
      goToReady();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Ponto único de entrada: toque, clique ou tecla.
  void handleInput() {
    switch (state) {
      case GameState.ready:
        startGame();
      case GameState.playing:
        bird.flap();
      case GameState.gameOver:
        // Ignora o toque logo após a morte para não reiniciar sem querer.
        if (_gameOverTimer >= GameConfig.gameOverInputDelay) {
          startGame();
        }
    }
  }

  // ---------------------------------------------------------------------
  // Ciclo de vida da partida
  // ---------------------------------------------------------------------

  void startGame() {
    score = 0;
    _gameOverTimer = 0;
    state = GameState.playing;

    bird.launch();
    _resetPipes();
    _skyline.resetScroll();
    _ground.resetScroll();
    _syncHud();
  }

  /// Volta para a tela inicial sem começar a jogar.
  void goToReady() {
    score = 0;
    _gameOverTimer = 0;
    state = GameState.ready;

    bird.reset();
    _resetPipes();
    _syncHud();
  }

  void endGame() {
    if (state != GameState.playing) return;

    state = GameState.gameOver;
    _gameOverTimer = 0;
    if (score > bestScore) bestScore = score;
    _syncHud();
  }

  void addPoint() {
    if (state != GameState.playing) return;
    score++;
    _syncHud();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (state == GameState.playing) {
      final dx = GameConfig.pipeSpeed * dt;
      _ground.advance(dx * GameConfig.groundSpeedFactor);
      _skyline.advance(dx * GameConfig.skylineSpeedFactor);
    } else if (state == GameState.gameOver) {
      _gameOverTimer += dt;
    }
  }

  // ---------------------------------------------------------------------
  // Canos
  // ---------------------------------------------------------------------

  void _createPipes() {
    for (var i = 0; i < GameConfig.pipeCount; i++) {
      final pipe = PipePair(gapCenterY: _randomGapCenter())
        ..position = Vector2(
          GameConfig.firstPipeX + i * GameConfig.pipeSpacing,
          0,
        );
      _pipes.add(pipe);
    }
    world.addAll(_pipes);
  }

  void _resetPipes() {
    var previous = GameConfig.worldHeight / 2;
    for (var i = 0; i < _pipes.length; i++) {
      final gap = _randomGapCenter(previous: previous);
      previous = gap;
      _pipes[i].recycleTo(
        x: GameConfig.firstPipeX + i * GameConfig.pipeSpacing,
        gapCenterY: gap,
      );
    }
  }

  /// Move o cano que saiu da tela para o fim da fila.
  void recyclePipe(PipePair pipe) {
    if (_pipes.isEmpty) return;

    var maxX = double.negativeInfinity;
    var reference = pipe.gapCenterY;
    for (final candidate in _pipes) {
      if (candidate.x > maxX) {
        maxX = candidate.x;
        reference = candidate.gapCenterY;
      }
    }

    pipe.recycleTo(
      x: maxX + GameConfig.pipeSpacing,
      gapCenterY: _randomGapCenter(previous: reference),
    );
  }

  double _randomGapCenter({double? previous}) {
    final minCenter = GameConfig.pipeMargin + GameConfig.gapHeight / 2;
    final maxCenter =
        GameConfig.groundTop - GameConfig.pipeMargin - GameConfig.gapHeight / 2;

    var low = minCenter;
    var high = maxCenter;

    // Limita o salto vertical entre vãos consecutivos para a sequência não
    // ficar impossível de passar.
    if (previous != null) {
      low = max(low, previous - GameConfig.maxGapCenterDelta);
      high = min(high, previous + GameConfig.maxGapCenterDelta);
      if (low > high) {
        low = minCenter;
        high = maxCenter;
      }
    }

    return low + _random.nextDouble() * (high - low);
  }

  // ---------------------------------------------------------------------
  // HUD
  // ---------------------------------------------------------------------

  void _syncHud() {
    if (!_hudReady) return;
    hud.sync(
      state: state,
      score: score,
      best: bestScore,
      showKeyboardHint: _hasKeyboard,
    );
  }
}
