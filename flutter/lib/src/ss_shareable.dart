import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Liga um [SsShareable] a quem tira a foto dele.
class SsShareController {
  final _key = GlobalKey();

  /// PNG do [SsShareable] como está na tela (padrão 3× a densidade lógica).
  /// O app manda os bytes para o share_plus. Chame depois de ele aparecer.
  Future<Uint8List> capture({double pixelRatio = 3}) async {
    final b = _key.currentContext?.findRenderObject();
    if (b is! RenderRepaintBoundary) throw StateError('SsShareable não está na tela');
    final img = await b.toImage(pixelRatio: pixelRatio);
    try {
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    } finally {
      img.dispose();
    }
  }
}

/// Área que vira imagem para compartilhar (resumo do mês, card de conquista).
/// Pinta o fundo da página por trás do [child], para o PNG não sair
/// transparente (fica preto em vários apps de mensagem).
class SsShareable extends StatelessWidget {
  const SsShareable({super.key, required this.child, required this.controller, this.background});

  final Widget child;
  final SsShareController controller;

  /// Fundo da imagem; sem ele, o da tela. `Colors.transparent` para cartão
  /// de cantos arredondados (o PNG sai com os cantos vazios).
  final Color? background;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    key: controller._key,
    child: ColoredBox(color: background ?? Theme.of(context).scaffoldBackgroundColor, child: child),
  );
}
