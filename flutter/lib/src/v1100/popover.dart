// v1.10.0: o par Flutter do Ss::PopoverComponent (balão ancorado com seta).
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../ss_button.dart';
import '../ss_strings.dart';
import '../v10/tela_barra.dart';

/// Onde o balão abre em relação ao alvo (o `placement:` do web).
enum SsPopoverPlacement { bottomStart, bottomEnd, topStart }

/// Abre o balão ancorado no widget de [anchor] (o contexto do botão). Fecha ao tocar fora, no voltar do
/// Android e no Esc; devolve o que o conteúdo passar ao [Navigator.pop] (ou [SsPopover.close]).
///
/// v1.14.3: abre pelo `Navigator` raiz ([useRootNavigator], padrão `true`), por cima da barra de abas do
/// `SsNavScaffold` (ver `showSsSheet`).
Future<T?> showSsPopover<T>(
  BuildContext anchor, {
  required Widget child,
  String? title,
  String? label,
  SsPopoverPlacement placement = SsPopoverPlacement.bottomStart,
  double maxWidth = 352,
  bool useRootNavigator = true,
}) {
  final box = anchor.findRenderObject()! as RenderBox;
  final nav = Navigator.of(anchor, rootNavigator: useRootNavigator);
  final overlay = nav.overlay!.context.findRenderObject()! as RenderBox;
  final alvo = MatrixUtils.transformRect(box.getTransformTo(overlay), Offset.zero & box.size);
  final reduz = reduceMotion(anchor);
  return nav.push(
    _PopoverRoute<T>(
      anchor: alvo,
      placement: placement,
      maxWidth: maxWidth,
      reduce: reduz,
      barrierLabel: SsStrings.of(anchor).close,
      label: title ?? label,
      title: title,
      child: child,
    ),
  );
}

/// Balão ancorado (v1.10, par do `Ss::PopoverComponent`): o botão abre um cartão pequeno com seta que
/// aponta para ele, abaixo e alinhado pelo começo ([placement]); sem espaço embaixo, vira para cima.
/// Fecha ao tocar fora, no voltar e no Esc. Entra crescendo do lado da seta com a mola (reduzir
/// movimento: aparece direto). O leitor de tela entra no balão como uma rota com o nome do [title].
///
/// ```dart
/// SsPopover(label: 'Detalhes', title: 'Como calculamos', child: Text('Média dos últimos 3 meses.'))
/// SsPopover(label: 'Mais ações', icon: Icons.more_vert, placement: SsPopoverPlacement.bottomEnd, child: menu)
/// ```
/// Gatilho: o botão discreto com o [label] (padrão), um [icon] (o [label] vira a dica e o nome no leitor
/// de tela) ou o [triggerBuilder] (recebe a função que abre).
class SsPopover extends StatelessWidget {
  const SsPopover({
    super.key,
    required this.label,
    required this.child,
    this.title,
    this.icon,
    this.triggerBuilder,
    this.placement = SsPopoverPlacement.bottomStart,
    this.maxWidth = 352,
  });

  final String label;
  final Widget child;
  final String? title;
  final IconData? icon;
  final Widget Function(BuildContext context, VoidCallback open)? triggerBuilder;
  final SsPopoverPlacement placement;
  final double maxWidth;

  /// Fecha o balão de dentro do conteúdo.
  static void close<T>(BuildContext context, [T? result]) => Navigator.of(context).pop<T>(result);

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) {
        void abrir() => showSsPopover<void>(
          ctx,
          child: child,
          title: title,
          label: label,
          placement: placement,
          maxWidth: maxWidth,
        );
        if (triggerBuilder != null) return triggerBuilder!(ctx, abrir);
        if (icon != null) return SsIconButton(icon: icon!, tooltip: label, onPressed: abrir);
        return SsButton.ghost(label: label, small: true, expand: false, onPressed: abrir);
      },
    );
  }
}

class _PopoverRoute<T> extends PopupRoute<T> {
  _PopoverRoute({
    required this.anchor,
    required this.placement,
    required this.maxWidth,
    required this.reduce,
    required this.barrierLabel,
    required this.label,
    required this.title,
    required this.child,
  });

  final Rect anchor;
  final SsPopoverPlacement placement;
  final double maxWidth;
  final bool reduce;
  final String? label;
  final String? title;
  final Widget child;

  @override
  final String barrierLabel;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => reduce ? Duration.zero : SsMotion.medium;

  @override
  Duration get reverseTransitionDuration => reduce ? Duration.zero : SsMotion.short;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final mq = MediaQuery.of(context);
    return CustomSingleChildLayout(
      delegate: _Posicao(anchor: anchor, placement: placement, padding: mq.padding, onPlace: _lugar),
      child: ValueListenableBuilder<_Lugar>(
        valueListenable: _lugar,
        builder: (context, l, _) => _Balao(
          lugar: l,
          animation: animation,
          maxWidth: math.min(maxWidth, mq.size.width - 24),
          label: label,
          title: title,
          child: child,
        ),
      ),
    );
  }

  final _lugar = ValueNotifier(const _Lugar(up: false, arrowX: 24, end: false));

  @override
  void dispose() {
    _lugar.dispose();
    super.dispose();
  }
}

/// Para onde a seta aponta (x dentro do balão) e se o balão abriu para cima.
@immutable
class _Lugar {
  const _Lugar({required this.up, required this.arrowX, required this.end});
  final bool up;
  final double arrowX;
  final bool end;

  @override
  bool operator ==(Object other) => other is _Lugar && other.up == up && other.arrowX == arrowX && other.end == end;

  @override
  int get hashCode => Object.hash(up, arrowX, end);
}

const _gap = 10.0;
const _seta = 8.0;
const _margem = 12.0;

class _Posicao extends SingleChildLayoutDelegate {
  _Posicao({required this.anchor, required this.placement, required this.padding, required this.onPlace});
  final Rect anchor;
  final SsPopoverPlacement placement;
  final EdgeInsets padding;
  final ValueNotifier<_Lugar> onPlace;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => BoxConstraints.loose(
    Size(constraints.maxWidth - 2 * _margem, constraints.maxHeight - padding.vertical - 2 * _margem),
  );

  @override
  Offset getPositionForChild(Size size, Size child) {
    final end = placement == SsPopoverPlacement.bottomEnd;
    var x = end ? anchor.right - child.width : anchor.left;
    x = x.clamp(_margem, math.max(_margem, size.width - child.width - _margem));
    final cabeEmbaixo = anchor.bottom + _gap + child.height <= size.height - padding.bottom - _margem;
    final cabeEmCima = anchor.top - _gap - child.height >= padding.top + _margem;
    final up = placement == SsPopoverPlacement.topStart ? (cabeEmCima || !cabeEmbaixo) : (!cabeEmbaixo && cabeEmCima);
    final y = up ? anchor.top - _gap - child.height : anchor.bottom + _gap;
    final seta = (anchor.center.dx - x).clamp(18.0, math.max(18.0, child.width - 18)).toDouble();
    final l = _Lugar(up: up, arrowX: seta, end: end);
    if (onPlace.value != l) WidgetsBinding.instance.addPostFrameCallback((_) => onPlace.value = l);
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_Posicao old) => old.anchor != anchor || old.placement != placement || old.padding != padding;
}

class _Balao extends StatelessWidget {
  const _Balao({
    required this.lugar,
    required this.animation,
    required this.maxWidth,
    required this.label,
    required this.title,
    required this.child,
  });
  final _Lugar lugar;
  final Animation<double> animation;
  final double maxWidth;
  final String? label;
  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final raio = d.radiusField + 4;
    final corpo = CustomPaint(
      painter: _Moldura(
        fill: c.surface,
        line: c.line,
        radius: raio,
        arrowX: lugar.arrowX,
        up: lugar.up,
        shadow: c.isDark ? Colors.black.withValues(alpha: .5) : c.ink.withValues(alpha: .16),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(d.cardPad * .8, d.cardPad * .72, d.cardPad * .8, d.cardPad * .72),
        child: Material(
          type: MaterialType.transparency,
          child: DefaultTextStyle.merge(
            style: TextStyle(color: c.ink2, fontSize: d.font(AppType.sub), height: 1.4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Semantics(
                    header: true,
                    child: Text(
                      title!,
                      style: TextStyle(color: c.ink, fontSize: d.font(AppType.set), fontWeight: FontWeight.w800),
                    ),
                  ),
                  SizedBox(height: d.space(6)),
                ],
                Flexible(child: SingleChildScrollView(child: child)),
              ],
            ),
          ),
        ),
      ),
    );
    final anim = CurvedAnimation(parent: animation, curve: SsMotion.spring, reverseCurve: SsMotion.exit);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: label,
        child: FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: SsMotion.enter),
          child: ScaleTransition(
            scale: Tween(begin: .9, end: 1.0).animate(anim),
            alignment: Alignment(lugar.end ? 1 : -1, lugar.up ? 1 : -1),
            child: corpo,
          ),
        ),
      ),
    );
  }
}

/// O cartão com a seta (preenchido, com a linha fina e a sombra), num caminho só.
class _Moldura extends CustomPainter {
  _Moldura({
    required this.fill,
    required this.line,
    required this.radius,
    required this.arrowX,
    required this.up,
    required this.shadow,
  });
  final Color fill;
  final Color line;
  final double radius;
  final double arrowX;
  final bool up;
  final Color shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final ponta = up
        ? (Path()
            ..moveTo(arrowX - _seta, size.height - 1)
            ..lineTo(arrowX, size.height + _seta)
            ..lineTo(arrowX + _seta, size.height - 1)
            ..close())
        : (Path()
            ..moveTo(arrowX - _seta, 1)
            ..lineTo(arrowX, -_seta)
            ..lineTo(arrowX + _seta, 1)
            ..close());
    final p = Path.combine(PathOperation.union, Path()..addRRect(r), ponta);
    canvas.drawShadow(p, shadow, 10, false);
    canvas.drawPath(p, Paint()..color = fill);
    canvas.drawPath(
      p,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_Moldura old) =>
      old.fill != fill || old.line != line || old.arrowX != arrowX || old.up != up || old.radius != radius;
}
