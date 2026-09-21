import 'dart:ui' show Color;

/// Todas as constantes do jogo em um único lugar.
///
/// O mundo lógico é fixo em 360x640. A tela física nunca entra nos cálculos
/// de gameplay: a câmera escala esse mundo para o tamanho disponível.
/// Isso garante que a dificuldade seja exatamente a mesma no PC e no celular.
class GameConfig {
  GameConfig._();

  // ---------------------------------------------------------------------
  // Mundo lógico
  // ---------------------------------------------------------------------
  static const double worldWidth = 360;
  static const double worldHeight = 640;
  static const double aspectRatio = worldWidth / worldHeight;

  // ---------------------------------------------------------------------
  // Chão
  // ---------------------------------------------------------------------
  /// Altura em que o pássaro morre ao encostar.
  static const double groundTop = worldHeight * 0.925; // 592
  static const double groundHeight = worldHeight - groundTop; // 48

  /// Velocidade do chão relativa à dos canos (parallax).
  static const double groundSpeedFactor = 1.0;
  static const double skylineSpeedFactor = 0.35;

  // ---------------------------------------------------------------------
  // Canos
  // ---------------------------------------------------------------------
  static const double gapHeight = worldHeight * 0.28;
  static const double pipeMargin = worldHeight * 0.12;
  static const double pipeWidth = worldWidth * 0.18;
  static const double pipeSpacing = worldWidth * 0.60;

  /// Três canos reciclados dão folga suficiente mesmo se a tela ficar larga.
  static const int pipeCount = 3;

  /// O primeiro cano nasce fora da tela, à direita.
  static const double firstPipeX = worldWidth + pipeWidth;

  /// A velocidade antiga era 0.36 em coordenadas normalizadas de tela.
  /// Em 360x640 isso corresponde a 64.8 pixels lógicos/segundo.
  static const double pipeSpeed = 64.8;

  /// Fração vertical do PNG ocupada pela cabeça (boca) do cano.
  /// Medido nos arquivos atuais: a cabeça vai de y=717 a y=961 em 961px.
  static const double pipeCapFraction = 0.254;

  /// Distância vertical mínima entre o centro de dois vãos consecutivos,
  /// para que a sequência não fique impossível.
  static const double maxGapCenterDelta = worldHeight * 0.30;

  // ---------------------------------------------------------------------
  // Pássaro
  // ---------------------------------------------------------------------
  static const double birdWidth = worldWidth * 0.14 * 0.72;
  static const double birdAspectRatio = 348 / 239; // tamanho real do PNG
  static const double birdHeight = birdWidth / birdAspectRatio;

  static const double birdStartY = worldHeight * 0.44;

  /// A física antiga também era normalizada verticalmente.
  static const double gravity = 2.65 * worldHeight / 2;
  static const double flapVelocity = -1.05 * worldHeight / 2;

  /// Impulso dado no instante em que a partida começa.
  static const double birdStartVelocity = flapVelocity;

  /// Se `false`, o pássaro apenas bate no teto em vez de morrer nele
  /// (comportamento do Flappy Bird original).
  static const bool dieOnCeiling = false;

  // ---------------------------------------------------------------------
  // Hitboxes (menores que o desenho para o jogo ficar justo)
  // ---------------------------------------------------------------------
  static const double birdHitboxScale = 0.78;
  static const double pipeHitboxScale = 0.72;

  // ---------------------------------------------------------------------
  // HUD
  // ---------------------------------------------------------------------
  static const double scoreFontSize = 42;
  static const double startMessageFontSize = 20;
  static const double panelFontSize = 15;

  /// Tempo mínimo na tela de "fim de jogo" antes de aceitar um novo toque.
  /// Evita reiniciar sem querer por causa do toque que causou a morte.
  static const double gameOverInputDelay = 0.65;

  // ---------------------------------------------------------------------
  // Cores retiradas do próprio background.jpg
  // ---------------------------------------------------------------------
  static const Color skyColor = Color(0xFF71C5CF);
  static const Color skyTopColor = Color(0xFF9EDCE4);
  static const Color groundColor = Color(0xFFE1D694);
  static const Color grassColor = Color(0xFF79B833);

  // ---------------------------------------------------------------------
  // Recortes dentro de background.jpg (608 x 457)
  // ---------------------------------------------------------------------
  static const double bgImageWidth = 608;

  /// Faixa com nuvens, prédios e arbustos.
  static const double skylineSrcTop = 344;
  static const double skylineSrcHeight = 81;

  /// Faixa do chão. Cortamos em x=500 para remover a marca d'água do arquivo.
  static const double groundSrcTop = 425;
  static const double groundSrcHeight = 32;
  static const double groundSrcWidth = 500;
}
