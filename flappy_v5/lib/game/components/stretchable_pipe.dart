import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../game_config.dart';

/// Renderiza um cano preservando a proporção da cabeça (boca).
///
/// A imagem é dividida em duas regiões:
/// - corpo: cresce verticalmente;
/// - cabeça: mantém sempre a mesma altura visual.
///
/// Isso evita esticar a imagem inteira, que era a causa da deformação quando
/// o cano precisava ficar muito alto.
///
/// A altura pode ser alterada a qualquer momento com [setHeight], sem
/// recriar componentes. Isso permite reciclar os canos em vez de destruí-los
/// e construí-los de novo a cada volta.
class StretchablePipe extends PositionComponent {
  StretchablePipe({
    required this.imagePath,
    required double width,
    required this.capAtEnd,
    Vector2? position,
  }) : super(
          position: position,
          size: Vector2(width, 0),
          anchor: Anchor.topLeft,
        );

  final String imagePath;

  /// `true` para o cano de cima (cabeça na ponta de baixo).
  final bool capAtEnd;

  SpriteComponent? _body;
  SpriteComponent? _cap;

  double _capSourceHeight = 0;
  double _bodySourceHeight = 0;
  double _imageWidth = 1;
  double _pendingHeight = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final game = findGame();
    if (game == null) {
      throw StateError('StretchablePipe precisa estar dentro de um FlameGame.');
    }

    final ui.Image image = await game.images.load(imagePath);

    _imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();

    _capSourceHeight = (imageHeight * GameConfig.pipeCapFraction)
        .clamp(1.0, imageHeight)
        .toDouble();
    _bodySourceHeight = math.max(1.0, imageHeight - _capSourceHeight);

    final bodySrcTop = capAtEnd ? 0.0 : _capSourceHeight;
    final capSrcTop = capAtEnd ? _bodySourceHeight : 0.0;

    _body = SpriteComponent.fromImage(
      image,
      srcPosition: Vector2(0, bodySrcTop),
      srcSize: Vector2(_imageWidth, _bodySourceHeight),
      size: Vector2(width, 0),
    );
    _cap = SpriteComponent.fromImage(
      image,
      srcPosition: Vector2(0, capSrcTop),
      srcSize: Vector2(_imageWidth, _capSourceHeight),
      size: Vector2(width, 0),
    );

    await addAll(<Component>[_body!, _cap!]);
    _layout(_pendingHeight);
  }

  /// Define a altura total do cano.
  void setHeight(double value) {
    _pendingHeight = math.max(0, value);
    if (_body != null && _cap != null) {
      _layout(_pendingHeight);
    }
  }

  void _layout(double totalHeight) {
    final body = _body;
    final cap = _cap;
    if (body == null || cap == null) return;

    size.y = totalHeight;

    // A cabeça é dimensionada pela largura original do sprite, portanto sua
    // altura visual não muda quando o corpo fica mais comprido.
    final capHeight = math.min(
      totalHeight,
      width * _capSourceHeight / _imageWidth,
    );
    final bodyHeight = math.max(0.0, totalHeight - capHeight);

    if (capAtEnd) {
      // Cano superior: corpo em cima, cabeça embaixo.
      body.position.setValues(0, 0);
      cap.position.setValues(0, bodyHeight);
    } else {
      // Cano inferior: cabeça em cima, corpo embaixo.
      cap.position.setValues(0, 0);
      body.position.setValues(0, capHeight);
    }

    body.size.setValues(width, bodyHeight);
    cap.size.setValues(width, capHeight);
  }
}
