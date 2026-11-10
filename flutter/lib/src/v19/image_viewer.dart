// v0.19: imagem em tela cheia com zoom (comprovante, foto do cupom, anexo).
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../motion.dart';
import '../ss_strings.dart';
import '../v10/tela_barra.dart';

/// Abre [image] em tela cheia sobre fundo escuro ([SsImageViewer]): pinça e
/// toque duplo ampliam, arrastar move a imagem ampliada, o × e o voltar do
/// sistema fecham. [title] vai na barra de cima (nome do arquivo); [actions]
/// ficam à direita dela (compartilhar, baixar). No lugar do
/// `showDialog(builder: (_) => Dialog(child: InteractiveViewer(...)))`.
///
/// ```dart
/// showSsImageViewer(context, image: MemoryImage(bytes), title: 'cupom.jpg');
/// ```
Future<void> showSsImageViewer(
  BuildContext context, {
  required ImageProvider image,
  String? title,
  String? semanticLabel,
  List<Widget> actions = const [],
  double maxScale = 4,
  bool useRootNavigator = true,
}) => Navigator.of(context, rootNavigator: useRootNavigator).push<void>(
  PageRouteBuilder<void>(
    opaque: false,
    barrierColor: AppColors.headerDarkBg,
    transitionDuration: reduceMotion(context) ? Duration.zero : SsMotion.base,
    reverseTransitionDuration: reduceMotion(context) ? Duration.zero : SsMotion.fast,
    pageBuilder: (_, _, _) =>
        SsImageViewer(image: image, title: title, semanticLabel: semanticLabel, actions: actions, maxScale: maxScale),
    transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
  ),
);

/// A tela do [showSsImageViewer] (pública para quem monta a rota sozinho):
/// barra escura ([SsTopBarStyle.dark]) com × e [title], a imagem inteira no
/// meio ([BoxFit.contain]) num [InteractiveViewer] de 1× até [maxScale].
/// Toque duplo amplia 2,5× no ponto tocado e volta a 1×; "reduzir movimento"
/// troca sem animar. Imagem que não carrega vira o ícone de imagem quebrada.
class SsImageViewer extends StatefulWidget {
  const SsImageViewer({
    super.key,
    required this.image,
    this.title,
    this.semanticLabel,
    this.actions = const [],
    this.maxScale = 4,
  });

  final ImageProvider image;
  final String? title;

  /// Nome lido da imagem (padrão: `SsStrings.image`, ou o [title]).
  final String? semanticLabel;
  final List<Widget> actions;
  final double maxScale;

  @override
  State<SsImageViewer> createState() => _SsImageViewerState();
}

class _SsImageViewerState extends State<SsImageViewer> with SingleTickerProviderStateMixin {
  final _t = TransformationController();
  late final _anim = AnimationController(vsync: this, duration: SsMotion.base);
  Animation<Matrix4>? _para;
  Offset _toque = Offset.zero;

  @override
  void initState() {
    super.initState();
    _anim.addListener(() {
      if (_para != null) _t.value = _para!.value;
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    _t.dispose();
    super.dispose();
  }

  /// Escala atual (1 = imagem inteira).
  double get _escala => _t.value.getMaxScaleOnAxis();

  void _toqueDuplo() {
    final alvo = _escala > 1.01
        ? Matrix4.identity()
        // 2,5× com o ponto tocado parado: desloca −p × (2,5 − 1).
        : (Matrix4.diagonal3Values(2.5, 2.5, 1)..setTranslationRaw(-_toque.dx * 1.5, -_toque.dy * 1.5, 0));
    if (reduceMotion(context)) {
      _t.value = alvo;
      return;
    }
    _para = Matrix4Tween(
      begin: _t.value,
      end: alvo,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final s = SsStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.headerDarkBg,
      appBar: SsTopBar(
        title: widget.title,
        style: SsTopBarStyle.dark,
        leading: SsIconButton(
          icon: Icons.close_rounded,
          tooltip: s.close,
          color: AppColors.onDark,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: widget.actions,
      ),
      body: GestureDetector(
        onDoubleTapDown: (d) => _toque = d.localPosition,
        onDoubleTap: _toqueDuplo,
        child: InteractiveViewer(
          transformationController: _t,
          maxScale: widget.maxScale,
          child: SizedBox.expand(
            child: Semantics(
              image: true,
              label: widget.semanticLabel ?? widget.title ?? s.image,
              hint: s.zoomHint,
              child: Image(
                image: widget.image,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Center(child: Icon(Icons.broken_image_outlined, size: 48, color: AppColors.onDarkSoft)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
