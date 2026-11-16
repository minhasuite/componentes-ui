// v0.15: gráfico de barras agrupadas ou empilhadas, com negativos e linha
// combinada (par do Ss::BarChartComponent da gem).
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../app_theme.dart';
import '../format.dart';
import '../motion_view.dart';
import '../ss_line_chart.dart' show SsSeries, SsChartEmpty;
import '../v27/chart_markers.dart';
import '../ss_strings.dart';

/// Barras por rótulo (mês, cartão): uma barra por série lado a lado, ou
/// empilhadas com [stacked] (positivos sobem e negativos descem da linha do
/// zero). [line] desenha uma série como linha com pontos por cima (saldo do
/// mês sobre receitas × despesas). Tocar ou arrastar escolhe o grupo e mostra
/// o balão com o rótulo e cada valor (tique de haptic); soltou, fica marcado
/// até tocar fora. As barras crescem da linha do zero quando entram na tela.
///
/// Cor de cada série: a dela, ou a paleta da suíte começando pela marca.
/// [active] destaca um rótulo (o mês atual).
///
/// v0.20: [projection] é uma segunda linha, **tracejada**, para o que ainda vai
/// acontecer (saldo projetado de hoje ao fim do mês). Começa no índice
/// [projectionFrom] (os valores antes dele são ignorados; a lista pode vir
/// inteira) e entra na legenda (traço tracejado), no balão e no resumo do
/// leitor de tela. Cor: a dela, ou a da [line]. Para a linha real parar onde a
/// projeção começa, passe em [line] só os valores até lá (lista mais curta).
///
/// `SsBarChart(labels: meses, series: [SsSeries(receitas, name: 'Receitas', color: c.success), SsSeries(despesas, name: 'Despesas', color: c.danger)], line: SsSeries(saldo, name: 'Saldo'), stacked: true, format: (v) => money((v * 100).round()))`
///
/// v0.27 (par do `Ss::BarChartComponent`, pedido do meulog): [horizontal] deita
/// as barras (uma linha por rótulo, rótulo à esquerda com reticências: classe
/// de exceção, rota); `SsSeries(colors:)` dá cor por valor (a categoria
/// "Outros" apagada); [markers] desenha marcas verticais (deploy, incidente,
/// nota; não valem no deitado); [empty] mostra o texto quando não há valor.
class SsBarChart extends StatefulWidget {
  const SsBarChart({
    super.key,
    required this.labels,
    required this.series,
    this.line,
    this.stacked = false,
    this.format,
    this.height = 200,
    this.legend = true,
    this.active,
    this.projection,
    this.projectionFrom = 0,
    this.horizontal = false,
    this.markers = const [],
    this.empty,
    this.max,
  });

  /// Topo fixo da escala (v0.28, par do `max:` do Ss::BarChartComponent): o eixo vai de 0 até [max],
  /// para pequenos múltiplos lado a lado na mesma escala. Valor acima alarga a escala.
  final double? max;

  /// Barras deitadas, uma linha por rótulo (v0.27). Ignora [line], [projection] e [markers].
  final bool horizontal;

  /// Marcas verticais por rótulo (v0.27).
  final List<SsChartMarker> markers;

  /// Texto do vazio (v0.27).
  final String? empty;

  final List<String> labels;
  final List<SsSeries> series;
  final SsSeries? line;
  final bool stacked;

  /// Texto de um valor (padrão: [qty]).
  final String Function(double value)? format;
  final double height;

  /// Legenda embaixo (só com mais de uma série ou com [line]).
  final bool legend;
  final int? active;

  /// Linha tracejada da projeção (v0.20), a partir de [projectionFrom].
  final SsSeries? projection;

  /// Índice do primeiro ponto da [projection] (normalmente o de hoje).
  final int projectionFrom;

  @override
  State<SsBarChart> createState() => _SsBarChartState();
}

const _top = 18.0;
const _bottom = 22.0;
const _side = 2.0;

double _v(List<double> vs, int i) => i < vs.length ? vs[i] : 0;

/// Faixa (lo, hi) com o zero sempre dentro; empilhado soma positivos e negativos.
@visibleForTesting
(double, double) ssBarRange(
  List<SsSeries> series,
  int n, {
  SsSeries? line,
  bool stacked = false,
  SsSeries? projection,
  int projectionFrom = 0,
  double? max,
}) {
  var lo = 0.0, hi = 0.0;
  for (var i = 0; i < n; i++) {
    if (stacked) {
      var up = 0.0, down = 0.0;
      for (final s in series) {
        final v = _v(s.values, i);
        v >= 0 ? up += v : down += v;
      }
      hi = math.max(hi, up);
      lo = math.min(lo, down);
    } else {
      for (final s in series) {
        hi = math.max(hi, _v(s.values, i));
        lo = math.min(lo, _v(s.values, i));
      }
    }
    if (line != null && i < line.values.length) {
      hi = math.max(hi, line.values[i]);
      lo = math.min(lo, line.values[i]);
    }
    if (projection != null && i >= projectionFrom && i < projection.values.length) {
      hi = math.max(hi, projection.values[i]);
      lo = math.min(lo, projection.values[i]);
    }
  }
  if (hi == 0 && lo == 0) hi = 1;
  final pad = (hi - lo) * .08;
  final topo = max != null ? math.max(max, hi) : (hi > 0 ? hi + pad : 0.0);
  return (lo < 0 ? lo - pad : 0, topo);
}

class _SsBarChartState extends State<SsBarChart> {
  int? _sel;
  SsFormats _formats = SsFormats.brl;

  int get _n => widget.labels.length;
  String _fmt(double v) => widget.format?.call(v) ?? qty(v, _formats);

  /// Índice com ponto da projeção.
  bool _temProj(int i) {
    final p = widget.projection;
    return p != null && i >= widget.projectionFrom && i < p.values.length;
  }

  void _pick(double dx, double width) {
    if (_n == 0) return;
    final i = ((dx - _side) / ((width - _side * 2) / _n)).floor().clamp(0, _n - 1);
    if (i == _sel) return;
    HapticFeedback.selectionClick();
    setState(() => _sel = i);
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = SsStrings.of(context);
    _formats = SsFormats.of(context);
    final paleta = c.series;
    final cores = [for (var i = 0; i < widget.series.length; i++) widget.series[i].color ?? paleta[i % paleta.length]];
    final vazio = _n == 0 || widget.series.every((x) => x.values.isEmpty);
    if (vazio && widget.empty != null) return SsChartEmpty(widget.empty!, height: widget.height);
    if (widget.horizontal) return _deitado(context, cores);
    final marcas = ssResolveMarkers(widget.markers, widget.labels);
    final topo = ssMarkerRows(marcas) * ssMarkerLine;
    final corLinha = widget.line?.color ?? c.ink;
    final corProj = widget.projection?.color ?? widget.line?.color ?? c.muted;
    final (lo, hi) = ssBarRange(
      widget.series,
      _n,
      line: widget.line,
      stacked: widget.stacked,
      projection: widget.projection,
      projectionFrom: widget.projectionFrom,
      max: widget.max,
    );
    final nome = widget.series.map((x) => x.name).whereType<String>().join(', ');
    final resumo = [
      for (var i = 0; i < _n; i++)
        '${widget.labels[i]}: ${[for (final x in widget.series) _fmt(_v(x.values, i)), if (widget.line != null && i < widget.line!.values.length) _fmt(widget.line!.values[i]), if (_temProj(i)) '${widget.projection!.name ?? ''} ${_fmt(widget.projection!.values[i])}'.trim()].join(' / ')}',
    ].join('; ');
    final temLegenda =
        widget.legend &&
        (widget.series.length + (widget.line == null ? 0 : 1) + (widget.projection == null ? 0 : 1)) > 1;

    final grafico = SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final sel = _sel;
          final slot = (w - _side * 2) / math.max(_n, 1);
          final xSel = sel == null ? 0.0 : _side + slot * (sel + .5);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _pick(d.localPosition.dx, w),
            onHorizontalDragStart: (d) => _pick(d.localPosition.dx, w),
            onHorizontalDragUpdate: (d) => _pick(d.localPosition.dx, w),
            child: TapRegion(
              onTapOutside: (_) => sel == null ? null : setState(() => _sel = null),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: SsTweenInView(
                      end: 1,
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutBack,
                      builder: (_, t, _) => CustomPaint(
                        painter: _BarPainter(
                          series: [for (var i = 0; i < widget.series.length; i++) (widget.series[i].values, cores[i])],
                          valueColors: [for (final x in widget.series) x.colors],
                          markers: marcas,
                          markerTop: topo,
                          markerColors: {for (final k in SsChartMarkerKind.values) k: ssMarkerColor(context, k)},
                          line: widget.line == null ? null : (widget.line!.values, corLinha),
                          projection: widget.projection == null
                              ? null
                              : (widget.projection!.values, corProj, widget.projectionFrom),
                          n: _n,
                          labels: widget.labels,
                          lo: lo,
                          hi: hi,
                          stacked: widget.stacked,
                          t: t,
                          sel: sel,
                          active: widget.active,
                          format: _fmt,
                          guide: c.line,
                          zero: c.ink.withValues(alpha: .3),
                          surface: c.surface,
                          hover: c.accent.withValues(alpha: .08),
                          axis: AppTheme.number(context, size: AppType.micro, color: c.muted),
                          axisStrong: AppTheme.number(
                            context,
                            size: AppType.micro,
                            color: c.ink,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (sel != null)
                    Positioned(
                      top: topo,
                      left: (xSel - 70).clamp(0.0, math.max(0.0, w - 140)),
                      width: 140,
                      child: IgnorePointer(
                        child: _Balao(
                          label: widget.labels[sel],
                          rows: [
                            for (var k = 0; k < widget.series.length; k++)
                              (widget.series[k].name, cores[k], _fmt(_v(widget.series[k].values, sel))),
                            if (widget.line != null && sel < widget.line!.values.length)
                              (widget.line!.name, corLinha, _fmt(widget.line!.values[sel])),
                            if (_temProj(sel)) (widget.projection!.name, corProj, _fmt(widget.projection!.values[sel])),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );

    final notas = [for (final (i, _, m) in marcas) '${widget.labels[i]}: ${m.label}'].join('; ');
    return Semantics(
      label:
          '${s.chartOf(nome.isEmpty ? null : nome)}: ${_n == 0 ? s.noData : resumo}${notas.isEmpty ? '' : '. $notas'}',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          grafico,
          if (temLegenda) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                for (var i = 0; i < widget.series.length; i++)
                  if (widget.series[i].name != null) _Legenda(widget.series[i].name!, cores[i]),
                if (widget.line?.name != null) _Legenda(widget.line!.name!, corLinha, line: true),
                if (widget.projection?.name != null) _Legenda(widget.projection!.name!, corProj, dashed: true),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

extension on _SsBarChartState {
  /// Barras deitadas (v0.27): uma linha por rótulo, rótulo à esquerda (34%),
  /// barra que cresce da esquerda e o valor no fim; o rótulo inteiro na dica.
  Widget _deitado(BuildContext context, List<Color> cores) {
    final c = SsColors.of(context);
    final s = SsStrings.of(context);
    final (lo, hi) = ssBarRange(widget.series, _n, stacked: widget.stacked, max: widget.max);
    final nome = widget.series.map((x) => x.name).whereType<String>().join(', ');
    final resumo = [
      for (var i = 0; i < _n; i++)
        '${widget.labels[i]}: ${[for (final x in widget.series) _fmt(_v(x.values, i))].join(' / ')}',
    ].join('; ');
    final rotulo = TextStyle(fontSize: AppType.meta, fontWeight: FontWeight.w600, color: c.ink2);
    final valor = AppTheme.number(context, size: AppType.micro, color: c.muted);
    final temLegenda = widget.legend && widget.series.length > 1;
    return Semantics(
      label: '${s.chartOf(nome.isEmpty ? null : nome)}: $resumo',
      excludeSemantics: true,
      child: SsTweenInView(
        end: 1,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutBack,
        builder: (_, t, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < _n; i++)
              SizedBox(
                height: 30,
                child: Row(
                  children: [
                    Expanded(
                      flex: 34,
                      child: Tooltip(
                        message: widget.labels[i],
                        child: Text(
                          widget.labels[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: rotulo,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 66,
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final largura = math.max(0.0, box.maxWidth - 48);
                          double px(double v) => largura * (v - lo) / (hi - lo);
                          final x0 = px(0);
                          final barras = <Widget>[];
                          var up = 0.0, down = 0.0, maior = 0.0;
                          final k = widget.series.length;
                          final bh = widget.stacked ? 18.0 : (18.0 - 2 * (k - 1)) / math.max(k, 1);
                          for (var j = 0; j < k; j++) {
                            final x = widget.series[j];
                            final v = _v(x.values, i) * t;
                            if (v == 0) continue;
                            final cor = (x.colors != null && i < x.colors!.length ? x.colors![i] : null) ?? cores[j];
                            final de = widget.stacked ? (v > 0 ? up : down) : 0.0;
                            final ate = de + v;
                            if (widget.stacked) v > 0 ? up = ate : down = ate;
                            final l = math.min(px(de), px(ate));
                            final r = math.max(px(de), px(ate));
                            maior = math.max(maior, r);
                            barras.add(
                              Positioned(
                                left: l,
                                width: math.max(r - l, 1),
                                top: widget.stacked ? 6 : 6 + j * (bh + 2),
                                height: bh,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(4)),
                                ),
                              ),
                            );
                          }
                          final vs = [for (final x in widget.series) _v(x.values, i)];
                          final total = widget.stacked
                              ? vs.fold(0.0, (a, b) => a + b)
                              : vs.reduce((a, b) => a.abs() >= b.abs() ? a : b);
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: x0,
                                top: 2,
                                bottom: 2,
                                width: 1,
                                child: ColoredBox(color: c.ink.withValues(alpha: .3)),
                              ),
                              ...barras,
                              Positioned(
                                left: math.max(maior, x0) + 6,
                                top: 8,
                                child: Text(_fmt(total), style: valor),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            if (temLegenda) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 4,
                children: [
                  for (var j = 0; j < widget.series.length; j++)
                    if (widget.series[j].name != null) _Legenda(widget.series[j].name!, cores[j]),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda(this.text, this.color, {this.line = false, this.dashed = false});

  final String text;
  final Color color;
  final bool line;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dashed)
          SizedBox(
            width: 16,
            height: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var k = 0; k < 3; k++)
                  Container(
                    width: 4,
                    height: 3,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1)),
                  ),
              ],
            ),
          )
        else
          Container(
            width: 10,
            height: line ? 3 : 10,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
          ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(fontSize: AppType.meta, fontWeight: FontWeight.w600, color: c.muted),
        ),
      ],
    );
  }
}

class _Balao extends StatelessWidget {
  const _Balao({required this.label, required this.rows});

  final String label;
  final List<(String?, Color, String)> rows;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.thumb),
        border: Border.all(color: c.line),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: AppType.micro, fontWeight: FontWeight.w700, color: c.muted),
          ),
          for (final (nome, cor, valor) in rows)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  if (nome != null)
                    Flexible(
                      child: Text(
                        nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: AppType.micro, color: c.muted),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    valor,
                    style: AppTheme.number(context, size: AppType.meta, color: c.ink),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.series,
    this.valueColors = const [],
    this.markers = const [],
    this.markerTop = 0,
    this.markerColors = const {},
    required this.line,
    this.projection,
    required this.n,
    required this.labels,
    required this.lo,
    required this.hi,
    required this.stacked,
    required this.t,
    required this.sel,
    required this.active,
    required this.format,
    required this.guide,
    required this.zero,
    required this.surface,
    required this.hover,
    required this.axis,
    required this.axisStrong,
  });

  final List<(List<double>, Color)> series;
  final List<List<Color?>?> valueColors;
  final List<(int, int, SsChartMarker)> markers;
  final double markerTop;
  final Map<SsChartMarkerKind, Color> markerColors;
  final (List<double>, Color)? line;
  final (List<double>, Color, int)? projection;
  final int n;
  final List<String> labels;
  final double lo, hi;
  final bool stacked;
  final double t;
  final int? sel, active;
  final String Function(double) format;
  final Color guide, zero, surface, hover;
  final TextStyle axis, axisStrong;

  void _text(Canvas canvas, String s, Offset at, TextStyle style, {double alignX = 0, double? maxWidth, Color? chip}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth ?? double.infinity);
    final o = at - Offset(tp.width * alignX, 0);
    if (chip != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius((o & tp.size).inflate(3), const Radius.circular(6)),
        Paint()..color = chip.withValues(alpha: .88),
      );
    }
    tp.paint(canvas, o);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (n == 0) return;
    final top = _top + markerTop;
    final h = size.height - top - _bottom;
    double y(double v) => top + h * (hi - v) / (hi - lo);
    Color cor(int j, int i) {
      final vc = j < valueColors.length ? valueColors[j] : null;
      return (vc != null && i < vc.length ? vc[i] : null) ?? series[j].$2;
    }

    final slot = (size.width - _side * 2) / n;
    final y0 = y(0);

    final fina = Paint()
      ..color = guide
      ..strokeWidth = 1;
    // Guias: topo, base e o meio, menos as que caem em cima da linha do zero.
    final marcas = {hi, (hi + lo) / 2, lo}..removeWhere((v) => (v / (hi - lo)).abs() < .12);
    for (final v in marcas) {
      canvas.drawLine(Offset(0, y(v)), Offset(size.width, y(v)), fina);
    }
    canvas.drawLine(
      Offset(0, y0),
      Offset(size.width, y0),
      Paint()
        ..color = zero
        ..strokeWidth = 1.25,
    );

    if (sel != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(_side + slot * sel!, top - 8, slot, h + 8), const Radius.circular(8)),
        Paint()..color = hover,
      );
    }

    final gw = slot * .72;
    final passo = (n / math.max(1, (size.width / 44).floor())).ceil();
    for (var i = 0; i < n; i++) {
      final left = _side + slot * i + (slot - gw) / 2;
      if (stacked) {
        var up = 0.0, down = 0.0;
        for (var j = 0; j < series.length; j++) {
          final v = _v(series[j].$1, i) * t;
          if (v == 0) continue;
          final base = v > 0 ? up : down;
          final topo = base + v;
          v > 0 ? up = topo : down = topo;
          _bar(
            canvas,
            Rect.fromLTRB(left, math.min(y(base), y(topo)), left + gw, math.max(y(base), y(topo))),
            cor(j, i),
            v < 0,
          );
        }
      } else {
        final k = series.length;
        final bw = (gw - 2 * (k - 1)) / math.max(k, 1);
        for (var j = 0; j < k; j++) {
          final v = _v(series[j].$1, i) * t;
          final x = left + j * (bw + 2);
          _bar(canvas, Rect.fromLTRB(x, math.min(y0, y(v)), x + bw, math.max(y0, y(v))), cor(j, i), v < 0);
        }
      }
      if (i % passo == 0 || i == active) {
        _text(
          canvas,
          labels[i],
          Offset(_side + slot * (i + .5), size.height - 14),
          i == active || i == sel ? axisStrong : axis,
          alignX: .5,
          maxWidth: math.max(slot * passo, 24),
        );
      }
    }

    if (markers.isNotEmpty) {
      ssPaintMarkers(
        canvas,
        size,
        markers,
        (i) => _side + slot * (i + .5),
        markerColors,
        top: top - 6,
        bottom: top + h,
        style: axis,
      );
    }

    // Valor das guias por cima das barras, numa pílula da cor da superfície.
    for (final v in marcas) {
      _text(canvas, format(v), Offset(_side, y(v) - 15), axis, chip: surface);
    }

    final l = line;
    if (l != null && l.$1.length > 1) {
      final pts = [
        for (var i = 0; i < math.min(n, l.$1.length); i++) Offset(_side + slot * (i + .5), y0 + (y(l.$1[i]) - y0) * t),
      ];
      final p = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final o in pts.skip(1)) {
        p.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(
        p,
        Paint()
          ..color = l.$2
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.25
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      for (final o in pts) {
        canvas.drawCircle(o, 3.5, Paint()..color = surface);
        canvas.drawCircle(
          o,
          3.5,
          Paint()
            ..color = l.$2
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2,
        );
      }
    }

    final pr = projection;
    if (pr != null) {
      final (vs, cor, from) = pr;
      final pts = [
        for (var i = math.max(0, from); i < math.min(n, vs.length); i++)
          Offset(_side + slot * (i + .5), y0 + (y(vs[i]) - y0) * t),
      ];
      if (pts.length > 1) {
        final p = Path()..moveTo(pts.first.dx, pts.first.dy);
        for (final o in pts.skip(1)) {
          p.lineTo(o.dx, o.dy);
        }
        _dashed(
          canvas,
          p,
          Paint()
            ..color = cor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.25
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(pts.last, 3.5, Paint()..color = surface);
        canvas.drawCircle(
          pts.last,
          3.5,
          Paint()
            ..color = cor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2,
        );
      }
    }
  }

  /// Traço tracejado ao longo do caminho (6 cheio, 5 vazio).
  void _dashed(Canvas canvas, Path p, Paint paint) {
    for (final m in p.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + 6, m.length)), paint);
        d += 11;
      }
    }
  }

  void _bar(Canvas canvas, Rect r, Color cor, bool neg) {
    if (r.height < .5) return;
    final rad = Radius.circular(math.min(4, r.width / 4));
    canvas.drawRRect(
      neg
          ? RRect.fromRectAndCorners(r, bottomLeft: rad, bottomRight: rad)
          : RRect.fromRectAndCorners(r, topLeft: rad, topRight: rad),
      Paint()..color = cor,
    );
  }

  @override
  bool shouldRepaint(_BarPainter o) =>
      o.t != t ||
      o.sel != sel ||
      o.series != series ||
      o.line != line ||
      o.projection != projection ||
      o.markers != markers ||
      o.lo != lo ||
      o.hi != hi ||
      o.guide != guide;
}
