// v1.9 · paridade_app: esqueleto por forma (par do Ss::SkeletonComponent).
import 'package:material_ui/material_ui.dart';

import '../../app_theme.dart';
import '../../density.dart';
import '../../motion.dart';
import '../../ss_strings.dart';

/// Forma do [SsSkeleton] (os `shape:` do web).
enum SsSkeletonShape { line, table, card, list }

/// Esqueleto de carregamento por forma, que pulsa enquanto espera: linhas de
/// texto ([lines]), tabela ([rows] × [cols] com cabeçalho), cartão (mídia,
/// título e linhas) ou lista (ícone, duas linhas e o valor). As larguras
/// variam como no web. Com "reduzir movimento" fica parado. O leitor de tela
/// ouve só "Carregando…".
///
/// O [SkeletonList] (lista de cartões) e o [SkeletonBox] (bloco de altura
/// fixa) continuam; este cobre as formas do web. Serve de `loading:` do
/// [SsAsyncBody]: `SsAsyncBody(value: v, loading: const SsSkeleton(shape: SsSkeletonShape.list), …)`.
class SsSkeleton extends StatefulWidget {
  const SsSkeleton({
    super.key,
    this.shape = SsSkeletonShape.line,
    this.lines = 3,
    this.rows = 4,
    this.cols = 4,
    this.label,
  });

  final SsSkeletonShape shape;
  final int lines;
  final int rows;
  final int cols;

  /// Padrão: [SsStrings.loadingEllipsis].
  final String? label;

  /// As larguras das barras (fração), na ordem do web.
  static const widths = [.92, .78, .64, .85, .56, .70];

  @override
  State<SsSkeleton> createState() => _SsSkeletonState();
}

class _SsSkeletonState extends State<SsSkeleton> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.stop();
      _c.value = .5;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    // A cor do `--sk` do web: o fio misturado ao fundo de campo.
    final barCor = Color.alphaBlend(c.line, Color.alphaBlend(c.line, c.field));
    const w = SsSkeleton.widths;

    Widget bar(double frac, {double h = 12, double? width, double radius = 99}) => FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: width == null ? frac : null,
      child: Container(
        width: width,
        height: h,
        decoration: BoxDecoration(color: barCor, borderRadius: BorderRadius.circular(radius)),
      ),
    );

    Widget caixa(Widget child, {EdgeInsets? pad}) => Container(
      padding: pad,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(d.radiusCard),
        border: Border.all(color: c.line),
      ),
      child: child,
    );

    final corpo = switch (widget.shape) {
      SsSkeletonShape.line => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [for (var i = 0; i < widget.lines; i++) bar(i == widget.lines - 1 ? .55 : w[i % 6])],
      ),
      SsSkeletonShape.card => caixa(
        pad: EdgeInsets.all(d.cardPad),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            bar(1, h: 136, radius: 14),
            const SizedBox(height: 2),
            bar(.6, h: 17),
            for (var i = 0; i < widget.lines; i++) bar(w[i % 6]),
          ],
        ),
      ),
      SsSkeletonShape.table => caixa(
        Column(
          children: [
            for (var r = -1; r < widget.rows; r++)
              Container(
                padding: EdgeInsets.symmetric(horizontal: d.padX * .8, vertical: r < 0 ? 13 : 15),
                decoration: BoxDecoration(
                  color: r < 0 ? c.field : null,
                  border: r < 0 ? null : Border(top: BorderSide(color: c.line)),
                ),
                child: Row(
                  spacing: 16,
                  children: [
                    for (var k = 0; k < widget.cols; k++)
                      Expanded(flex: k == 0 ? 2 : 1, child: r < 0 ? bar(.45, h: 9) : bar(w[(r + k) % 6])),
                  ],
                ),
              ),
          ],
        ),
      ),
      SsSkeletonShape.list => Column(
        spacing: 4,
        children: [
          for (var i = 0; i < widget.rows; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
              child: Row(
                spacing: 12,
                children: [
                  Container(
                    width: d.iconTile,
                    height: d.iconTile,
                    decoration: BoxDecoration(color: barCor, borderRadius: BorderRadius.circular(13)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 7,
                      children: [bar(w[i % 6]), bar(.4, h: 9)],
                    ),
                  ),
                  bar(0, width: 72),
                ],
              ),
            ),
        ],
      ),
    };

    return Semantics(
      label: widget.label ?? s.loadingEllipsis,
      liveRegion: true,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Opacity(opacity: .45 + _c.value * .4, child: child),
        child: corpo,
      ),
    );
  }
}
