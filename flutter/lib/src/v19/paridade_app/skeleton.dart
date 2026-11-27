// v1.9 · paridade_app: esqueleto por forma (par do Ss::SkeletonComponent).
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
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
///
/// v1.14.0: [SsSkeleton.of] gera o esqueleto **no formato real** a partir da própria árvore de widgets: monta e
/// mede o [child] (a linha da lista, o card do painel, com dados de exemplo), não pinta nada dele e desenha um
/// bloco onde há texto (um por linha, na largura do texto), um bloco onde há imagem ou foto (e um círculo no
/// avatar redondo) e o contorno dos cards, com o mesmo pulso ([SsMotion.pulse]). Nada de manter um esqueleto à
/// mão que deixa de bater com a tela. O [child] fica fora do toque e do leitor de tela (que ouve "Carregando…").
/// Par do `ss_skeleton_for(partial)` do web.
///
/// `SsAsyncBody(value: v, loading: SsSkeleton.of(PedidoTile(Pedido.exemplo)), …)`.
class SsSkeleton extends StatefulWidget {
  const SsSkeleton({
    super.key,
    this.shape = SsSkeletonShape.line,
    this.lines = 3,
    this.rows = 4,
    this.cols = 4,
    this.label,
  }) : child = null;

  /// v1.14.0: o esqueleto no formato do [child] (ver a classe).
  const SsSkeleton.of(Widget this.child, {super.key, this.label})
    : shape = SsSkeletonShape.line,
      lines = 3,
      rows = 4,
      cols = 4;

  /// v1.14.0: a árvore de onde sai o esqueleto ([SsSkeleton.of]).
  final Widget? child;

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
  late final _c = AnimationController(vsync: this, duration: SsMotion.pulse);

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

    final arvore = widget.child;
    if (arvore != null) {
      return Semantics(
        label: widget.label ?? s.loadingEllipsis,
        liveRegion: true,
        excludeSemantics: true,
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, child) => _SkeletonOf(
              block: barCor.withValues(alpha: barCor.a * (.45 + _c.value * .4)),
              outline: c.line,
              surface: c.surface,
              child: child!,
            ),
            child: arvore,
          ),
        ),
      );
    }

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

/// O pintor do [SsSkeleton.of]: mede o filho e desenha os blocos no lugar dele.
class _SkeletonOf extends SingleChildRenderObjectWidget {
  const _SkeletonOf({required this.block, required this.outline, required this.surface, required super.child});

  final Color block, outline, surface;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSkeletonOf(block, outline, surface);

  @override
  void updateRenderObject(BuildContext context, _RenderSkeletonOf r) {
    r
      ..block = block
      ..outline = outline
      ..surface = surface;
  }
}

class _RenderSkeletonOf extends RenderProxyBox {
  _RenderSkeletonOf(this._block, this._outline, this._surface);

  Color _block, _outline, _surface;
  set block(Color v) {
    if (v == _block) return;
    _block = v;
    markNeedsPaint();
  }

  set outline(Color v) {
    if (v == _outline) return;
    _outline = v;
    markNeedsPaint();
  }

  set surface(Color v) {
    if (v == _surface) return;
    _surface = v;
    markNeedsPaint();
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) => false;

  /// Os blocos do esqueleto: (retângulo, raio, é contorno de card).
  @visibleForTesting
  List<(Rect, double, bool)> blocks() {
    final out = <(Rect, double, bool)>[];
    void visit(RenderObject o) {
      if (o is RenderBox && !o.hasSize) return;
      Rect? local(Rect r) {
        final m = o.getTransformTo(this);
        return MatrixUtils.transformRect(m, r);
      }

      if (o is RenderParagraph) {
        final n = o.text.toPlainText().length;
        if (n == 0) return;
        final linhas = <double, Rect>{};
        for (final b in o.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: n))) {
          final r = b.toRect();
          final k = r.top.roundToDouble();
          linhas[k] = linhas[k]?.expandToInclude(r) ?? r;
        }
        for (final r in linhas.values) {
          // O bloco tem ~70% da altura da linha, centrado (como a barra do esqueleto por forma).
          final h = math.max(4.0, r.height * .7);
          final rr = local(Rect.fromLTWH(r.left, r.center.dy - h / 2, r.width, h));
          if (rr != null && !rr.isEmpty) out.add((rr, h / 2, false));
        }
        return;
      }
      if (o is RenderImage) {
        final rr = local(Offset.zero & o.size);
        if (rr != null && !rr.isEmpty) out.add((rr, 8, false));
        return;
      }
      if (o is RenderDecoratedBox && o.decoration is BoxDecoration) {
        final d = o.decoration as BoxDecoration;
        final rr = local(Offset.zero & o.size);
        if (rr != null && !rr.isEmpty) {
          if (d.image != null || d.shape == BoxShape.circle) {
            // Foto de fundo ou avatar redondo: um bloco só, no formato dele.
            out.add((rr, d.shape == BoxShape.circle ? rr.shortestSide / 2 : 8, false));
            return;
          }
          final raio = d.borderRadius?.resolve(TextDirection.ltr).topLeft.x ?? 0;
          // Quadradinho tonal (ícone num fundo, selo pequeno): um bloco só, no formato dele.
          if (d.color != null && rr.width >= 16 && rr.height >= 16 && rr.width <= 64 && rr.height <= 64) {
            out.add((rr, raio, false));
            return;
          }
          if ((d.color != null || d.border != null) && raio >= 8 && rr.width > 64 && rr.height > 40) {
            out.add((rr, raio, true));
          }
        }
      }
      o.visitChildren(visit);
    }

    final c = child;
    if (c != null) visit(c);
    return out;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final bloco = Paint()..color = _block;
    final borda = Paint()
      ..color = _outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final fundo = Paint()..color = _surface;
    final bs = blocks();
    // Os cards primeiro (por baixo), depois os blocos de texto e imagem.
    for (final (r, raio, card) in bs) {
      if (!card) continue;
      final rr = RRect.fromRectAndRadius(r.shift(offset), Radius.circular(raio));
      canvas.drawRRect(rr, fundo);
      canvas.drawRRect(rr.deflate(.5), borda);
    }
    for (final (r, raio, card) in bs) {
      if (card) continue;
      canvas.drawRRect(RRect.fromRectAndRadius(r.shift(offset), Radius.circular(raio)), bloco);
    }
  }
}
