import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/flappy_game.dart';
import '../game/game_config.dart';

/// Casca responsiva em volta do jogo.
///
/// O mundo do jogo é sempre 360x640, então o que muda entre celular e PC é
/// apenas o tamanho do retângulo em que ele é desenhado e o acabamento em
/// volta dele.
///
/// Importante: a instância de [FlappyGame] vive no `State`. Na versão
/// anterior ela era criada dentro de `build()`, o que fazia o jogo reiniciar
/// do zero a cada rebuild (girar a tela, redimensionar a janela, abrir o
/// teclado, mudar o tema...).
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final FlappyGame _game = FlappyGame();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              GameConfig.skyTopColor,
              GameConfig.skyColor,
              Color(0xFF4E9CA6),
            ],
            stops: <double>[0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Em telas largas (PC/tablet) reservamos uma margem e damos
              // uma moldura ao jogo. Em celular ele encosta nas bordas.
              final hasSideRoom = constraints.maxWidth -
                      constraints.maxHeight * GameConfig.aspectRatio >
                  40;
              final margin = hasSideRoom ? 16.0 : 0.0;
              final radius = hasSideRoom ? 20.0 : 0.0;

              final double maxW =
                  math.max(1.0, constraints.maxWidth - margin * 2);
              final double maxH =
                  math.max(1.0, constraints.maxHeight - margin * 2);

              // Maior retângulo 360x640 que cabe no espaço disponível.
              double boardWidth = maxW;
              double boardHeight = boardWidth / GameConfig.aspectRatio;
              if (boardHeight > maxH) {
                boardHeight = maxH;
                boardWidth = boardHeight * GameConfig.aspectRatio;
              }

              return Center(
                child: Padding(
                  padding: EdgeInsets.all(margin),
                  child: SizedBox(
                    width: boardWidth,
                    height: boardHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius),
                        boxShadow: hasSideRoom
                            ? const <BoxShadow>[
                                BoxShadow(
                                  color: Color(0x40000000),
                                  blurRadius: 28,
                                  offset: Offset(0, 12),
                                ),
                              ]
                            : const <BoxShadow>[],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(radius),
                        child: GameWidget<FlappyGame>(
                          game: _game,
                          // Sem isso o teclado só funciona depois de clicar.
                          autofocus: true,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
