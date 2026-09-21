# Flappy Bird — v5 / Flutter + Flame

Mundo lógico fixo de **360 × 640**. A tela física nunca entra nos cálculos de
gameplay: a câmera (`CameraComponent.withFixedResolution`) escala esse mundo
para o espaço disponível, então a dificuldade é idêntica no PC e no celular.

## Estrutura

```
lib/
  main.dart                     inicialização e orientação
  ui/game_screen.dart           casca responsiva (PC / celular / web)
  game/
    flappy_game.dart            loop, estados, entrada, reciclagem de canos
    game_config.dart            TODAS as constantes
    game_state.dart             ready / playing / gameOver
    hud/game_hud.dart           placar, tela inicial, fim de jogo
    components/
      background.dart           céu, silhueta da cidade e chão (parallax)
      bird.dart                 física e colisão do pássaro
      pipe_pair.dart            par de canos reciclável
      stretchable_pipe.dart     cano com cabeça não deformada
```

## Controles

| Ação | Celular | PC / Web |
|---|---|---|
| Voar / começar / reiniciar | toque | clique, `Espaço`, `↑`, `W`, `Enter` |
| Voltar à tela inicial | — | `R` |

## Ajustes rápidos

Tudo fica em `lib/game/game_config.dart`:

- `gapHeight` — tamanho do vão (maior = mais fácil).
- `pipeSpeed` — velocidade do cenário.
- `gravity` / `flapVelocity` — peso e força do pulo.
- `pipeCapFraction` — fração vertical do PNG ocupada pela cabeça do cano.
  Os arquivos atuais (`Cano_Cima.png` / `Cano_Baixo.png`, 588×961) têm a
  cabeça entre y=717 e y=961, ou seja **0.254**. Se trocar as imagens,
  meça de novo e altere só esse valor.
- `dieOnCeiling` — `false` (padrão) faz o pássaro bater no teto sem morrer.
- `maxGapCenterDelta` — quanto um vão pode variar em relação ao anterior.
- `skylineSrcTop` / `groundSrcTop` / ... — recortes usados dentro de
  `background.jpg` (608×457). `groundSrcWidth = 500` existe para cortar a
  marca d'água que vem no canto inferior direito do arquivo original.

## Assets

Todos os arquivos em `assets/images/` são incluídos automaticamente
(`pubspec.yaml` declara a pasta, não arquivo por arquivo).

Em uso: `background.jpg`, `flappy_bird_transparente.png`, `Cano_Cima.png`,
`Cano_Baixo.png`. Não usados hoje, mas mantidos: `Designer.png`,
`pipe_top.png`, `pipe_bottom.png`.

## Rodar

```bash
flutter pub get
flutter run -d chrome     # web
flutter run               # celular / desktop
```

## Recorde

O recorde é guardado só em memória e zera ao fechar o app. Para persistir,
adicione `shared_preferences` e grave `bestScore` em `FlappyGame.endGame()`.

## Gerar o APK sem instalar nada (GitHub Actions)

Este repositório tem `.github/workflows/build-apk.yml`. Ele compila o APK
num runner do GitHub, que já vem com Flutter, Java e Android SDK prontos.

1. Suba esta pasta para um repositório no GitHub (pode ser privado).
2. Vá em **Actions** → escolha **Build APK** → **Run workflow** (ou apenas
   dê `git push` na branch `main`, que ele já dispara sozinho).
3. Espere a execução terminar (uns 5–8 minutos na primeira vez).
4. Abra essa execução e desça até **Artifacts** → baixe `flappy-bird-apk`.
   Dentro tem o `app-release.apk`.

O workflow gera a pasta `android/` sozinho no início (`flutter create
--platforms=android .`), já que o projeto veio só com `web/`. Isso significa
que o `applicationId` fica como `com.example.flappy_bird_v5` e o nome do
app no launcher fica `flappy_bird_v5` — para trocar isso antes de distribuir
o APK, veja a seção abaixo.

### Personalizar nome e identificador do app

Depois que a pasta `android/` existir no seu repositório (rode o workflow
uma vez, depois baixe o repo ou rode o `flutter create` localmente e faça
commit da pasta `android/`), edite:

- `android/app/build.gradle.kts` → troque `applicationId = "com.example.flappy_bird_v5"`.
- `android/app/src/main/AndroidManifest.xml` → troque `android:label="flappy_bird_v5"`.

Se preferir, me peça e eu escrevo os dois arquivos já com os valores que
você quiser, prontos para colar por cima.

### Assinatura do APK

Sem configurar assinatura própria, o APK sai assinado com a chave de debug
do Flutter — funciona perfeitamente para instalar e testar no celular, mas
não é aceito pela Play Store. Se a ideia for publicar na Play Store, é
preciso gerar um keystore e apontar para ele em `android/app/build.gradle.kts`;
posso te guiar nisso quando chegar a hora.
