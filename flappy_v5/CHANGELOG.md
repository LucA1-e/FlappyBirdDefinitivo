# Correções aplicadas nesta revisão

## Bugs que afetavam o jogo

1. **Desenho do cano deslocado meio cano em relação à hitbox.**
   Em `pipe_pair.dart` os sprites eram posicionados em `x = -pipeWidth/2`.
   O sistema de coordenadas local de um componente do Flame começa no canto
   superior esquerdo, **independentemente do `anchor`**, então o desenho
   ficava 32 px lógicos à esquerda da área de colisão: dava para morrer no
   ar e atravessar o cano visível. Agora os filhos ficam em `x = 0`.

2. **Cabeça do cano deformada.** `pipeCapFraction` era `0.18`, mas nos PNGs
   atuais a cabeça começa em y=717 de 961 → `0.254`. Com 0.18 parte da
   cabeça entrava na região "corpo" e era esticada.

3. **"TOQUE PARA JOGAR" nunca sumia.** O texto era adicionado à viewport e
   nada o removia; ficava por cima durante a partida inteira.

4. **Precisava de dois toques para reiniciar.** `restartGame()` colocava o
   jogo em "parado" e só o toque seguinte começava a partida.

5. **`recyclePipe()` quebrava com mais de dois canos** — usava
   `firstWhere((c) => c != pipe)`, que pega um cano qualquer, não o último.
   Além disso destruía e recriava o `PipePair` inteiro a cada volta.
   Agora o par é reposicionado (`recycleTo`) sem alocar nada.

6. **`bird.reset()` ignorava `GameConfig.birdStartVelocity`** — a constante
   existia e nunca era usada; a partida começava com o pássaro despencando.

7. **Fundo esticado.** `background.jpg` é 608×457 (paisagem) e era esticado
   para 360×640, achatando prédios e chão. Agora: céu em degradê + faixa da
   cidade + faixa do chão, cada uma na proporção correta e repetidas
   horizontalmente. A marca d'água do arquivo original é cortada.

8. **Não existia chão visível.** O pássaro morria numa linha invisível em
   92,5% da altura. Agora há chão desenhado, com rolagem.

9. **`_syncHud()` dependia de `isLoaded`**, que é `false` durante `onLoad`;
   a sincronização inicial do HUD nunca acontecia de fato.

10. **Teto matava o jogador.** Diferente do Flappy Bird original. Agora o
    pássaro bate no teto e para de subir (`GameConfig.dieOnCeiling`).

11. **Vãos consecutivos podiam ser impossíveis** — o sorteio era totalmente
    aleatório. Agora há um limite de variação entre canos vizinhos
    (`maxGapCenterDelta`).

12. **Ponto marcado cedo demais** — usava o centro do cano; agora usa a
    borda direita.

## Responsividade

13. **O jogo reiniciava sozinho.** `GameWidget(game: FlappyGame())` estava
    dentro de `build()` de um `StatelessWidget`: cada rebuild (girar a tela,
    redimensionar a janela) criava um jogo novo. A instância agora vive no
    `State`.

14. **`web/index.html` sem `<meta name="viewport">`** — no celular o
    navegador renderizava a página com 980 px de largura e o jogo aparecia
    minúsculo. Também foram adicionados `touch-action`, `overscroll-behavior`
    (evita "puxar para atualizar" no meio da partida) e `theme-color`.

15. **Fundo preto em volta do jogo no PC.** Agora há um degradê de céu,
    margem, cantos arredondados e sombra em telas largas; no celular o jogo
    encosta nas bordas.

16. `SafeArea` + orientação travada em retrato no celular + `edgeToEdge`.

17. **Sem teclado no PC.** Adicionado `KeyboardEvents`: `Espaço`, `↑`, `W`,
    `Enter` para voar e `R` para voltar à tela inicial.

## Organização

18. `pubspec.yaml` declarava só 4 imagens; `pipe_top.png`, `pipe_bottom.png`
    e `Designer.png` ficavam de fora do bundle. Agora a pasta inteira é
    declarada.

19. `.dart_tool/chrome-device/` (perfil do Chrome, ~50 MB) e `build/`
    (incluindo um `.dill` de 47 MB) vieram dentro do .rar. Já estão no
    `.gitignore` — não precisam ser versionados nem compartilhados.

20. Estado do jogo virou um `enum` (`GameState`) em vez de dois `bool`
    (`isPlaying` / `isGameOver`), que permitiam combinações inválidas.

## Melhorias pequenas de acabamento

- Pássaro flutua na tela inicial e cai até o chão ao morrer.
- Painel de fim de jogo com escurecimento, pontuação e recorde da sessão.
- Parallax: cidade anda a 35% da velocidade do chão.
- Pequeno atraso (0,65 s) antes de aceitar toque na tela de fim de jogo,
  para não reiniciar sem querer.

---

# Revisão 2

21. **Erro de compilação em `flappy_game.dart`:** `TargetPlatform` era usado
    em `_hasKeyboard` mas o import de `foundation.dart` tinha um `show` que
    só liberava `defaultTargetPlatform` e `kIsWeb`. Resultado:
    `Undefined name 'TargetPlatform'`. Corrigido nos dois arquivos que usam
    o símbolo (`flappy_game.dart` e `main.dart`).

22. `Vector2.toRect()` em `background.dart` vem de `package:flame/extensions.dart`,
    que não era importado. Trocado por `Rect.fromLTWH(0, 0, size.x, size.y)`,
    que não depende de extensão nenhuma.

23. `KeyboardEvents` e `TapCallbacks` podem vir de `flame/input.dart` ou de
    `flame/events.dart` dependendo da versão. Os dois imports foram mantidos
    para não depender de qual reexporta qual.
