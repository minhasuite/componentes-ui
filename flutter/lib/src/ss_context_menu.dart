import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'density.dart';
import 'motion.dart';
import 'motion_view.dart';

/// Ação do [SsContextMenu] (e da `SsSelectionBar`). [destructive] pinta de vermelho.
class SsContextAction {
  const SsContextAction(this.icon, this.label, this.onTap, {this.destructive = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
}

/// Menu de contexto no toque longo: o item levanta (escala 1,03 + sombra),
/// o fundo escurece e a lista de [actions] aparece ancorada abaixo (ou acima,
/// se não couber). [preview] troca o item levantado por uma prévia compacta.
/// No leitor de tela, as ações viram ações personalizadas do item.
class SsContextMenu extends StatefulWidget {
  const SsContextMenu({super.key, required this.child, required this.actions, this.preview});

  final Widget child;
  final List<SsContextAction> actions;
  final Widget? preview;

  @override
  State<SsContextMenu> createState() => SsContextMenuState();
}

/// Estado público para abrir o menu por código (ex.: um botão ⋮ no item):
/// `GlobalKey<SsContextMenuState>()` e `key.currentState!.open()`.
class SsContextMenuState extends State<SsContextMenu> {
  void open() {
    final nav = Navigator.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final navBox = nav.context.findRenderObject() as RenderBox?;
    if (box == null || navBox == null) return;
    HapticFeedback.mediumImpact();
    final rect = box.localToGlobal(Offset.zero, ancestor: navBox) & box.size;
    final rapido = reduceMotion(context);
    nav.push(
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: rapido ? Duration.zero : SsMotion.indicator,
        reverseTransitionDuration: rapido ? Duration.zero : const Duration(milliseconds: 180),
        pageBuilder: (context, a, _) => _Menu(
          rect: rect,
          tela: navBox.size,
          item: widget.preview ?? widget.child,
          actions: widget.actions,
          animation: a,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Semantics(
    customSemanticsActions: {for (final a in widget.actions) CustomSemanticsAction(label: a.label): a.onTap},
    child: GestureDetector(onLongPress: open, child: widget.child),
  );
}

class _Menu extends StatelessWidget {
  const _Menu({
    required this.rect,
    required this.tela,
    required this.item,
    required this.actions,
    required this.animation,
  });

  final Rect rect;
  final Size tela;
  final Widget item;
  final List<SsContextAction> actions;
  final Animation<double> animation;

  static const _largura = 250.0;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final alturaMenu = actions.length * 48.0 + 12;
    final abaixo = tela.height - rect.bottom >= alturaMenu + 24 || tela.height - rect.bottom > rect.top;
    final esquerda = rect.left.clamp(12.0, (tela.width - _largura - 12).clamp(12.0, double.infinity));
    // Mola da suíte: o item levanta e o menu brota da âncora passando um pouco do tamanho.
    final curva = CurvedAnimation(parent: animation, curve: SsMotion.bounce, reverseCurve: Curves.easeIn);

    final levantado = AnimatedBuilder(
      animation: curva,
      builder: (_, child) => Transform.scale(
        scale: 1 + .03 * curva.value,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .28 * animation.value),
                blurRadius: 28,
                offset: const Offset(0, 14),
                spreadRadius: -8,
              ),
            ],
          ),
          child: child,
        ),
      ),
      child: IgnorePointer(child: item),
    );

    final menu = ScaleTransition(
      scale: Tween(begin: .8, end: 1.0).animate(curva),
      alignment: abaixo ? Alignment.topLeft : Alignment.bottomLeft,
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: const Interval(0, .4)),
        child: Container(
          width: _largura,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: c.isDark ? Border.all(color: c.line) : null,
            boxShadow: AppShadows.sheet,
          ),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, a) in actions.indexed)
                SsRouteStagger(
                  index: i,
                  offset: abaixo ? -6 : 6,
                  child: Semantics(
                    button: true,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                        a.onTap();
                      },
                      child: SizedBox(
                        height: SsDensity.of(context).target(SsDensity.of(context).controlHeight),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: SsDensity.of(context).padX),
                          child: Row(
                            children: [
                              Icon(
                                a.icon,
                                size: SsDensity.of(context).iconSize,
                                color: a.destructive ? c.danger : c.ink2,
                              ),
                              SizedBox(width: SsDensity.of(context).gap),
                              Expanded(
                                child: Text(
                                  a.label,
                                  style: TextStyle(
                                    color: a.destructive ? c.dangerText : c.ink,
                                    fontSize: SsDensity.of(context).font(AppType.body),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    final coluna = [
      Padding(
        padding: EdgeInsets.only(left: rect.left),
        child: SizedBox(width: rect.width, child: levantado),
      ),
      const SizedBox(height: 10),
      Padding(
        padding: EdgeInsets.only(left: esquerda),
        child: menu,
      ),
    ];

    // ponytail: prévia alta abaixo do item pode empurrar o menu para fora da tela; use prévia compacta.
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: FadeTransition(
                opacity: animation,
                child: ColoredBox(color: Colors.black.withValues(alpha: c.isDark ? .6 : .42)),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: abaixo ? rect.top : null,
            bottom: abaixo ? null : tela.height - rect.bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: abaixo ? coluna : coluna.reversed.toList(),
            ),
          ),
        ],
      ),
    );
  }
}
