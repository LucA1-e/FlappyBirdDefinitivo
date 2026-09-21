/// Estados possíveis de uma partida.
enum GameState {
  /// Tela inicial: o pássaro flutua e nada se move.
  ready,

  /// Partida em andamento.
  playing,

  /// O pássaro morreu; o cenário está congelado.
  gameOver,
}
