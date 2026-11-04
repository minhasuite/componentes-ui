// v0.9 (lote b): dados — área, rosca, anel grande e barras num card.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../format.dart';
import '../motion.dart';
import '../motion_view.dart';
import '../ss_strings.dart';

/// Curva suave por Catmull-Rom em cúbicas (a mesma do SsLineChart).
Path _curva(List<Offset> pts) {
  final p = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (var i = 0; i < pts.length - 1; i++) {
    final p0 = pts[math.max(i - 1, 0)];
    final p1 = pts[i];
    final p2 = pts[i + 1];
    final p3 = pts[math.min(i + 2, pts.length - 1)];
    final c1 = p1 + (p2 - p0) / 6;
    final c2 = p2 - (p3 - p1) / 6;
    p.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }
  return p;
}

// ---------------------------------------------------------------------------
// SsAreaChart
// ---------------------------------------------------------------------------

/// Gráfico de área suave (histórico do mês a mês) com gradiente vertical da
/// marca. Um ponto fica ativo ([active], padrão o último): linha tracejada
/// até o eixo, marcador e o valor numa pílula; o rótulo dele no eixo X fica
/// destacado. Arrastar ou tocar troca o ativo (tique por ponto) e chama
/// [onSelect]. Cresce de baixo e se desenha quando entra na tela. Para várias séries
/// ou linha de meta, use o `SsLineChart`.
class SsAreaChart extends StatefulWidget {
  const SsAreaChart({
    super.key,
    required this.values,
    required this.labels,
    this.active,
    this.onSelect,
    this.format,
    this.height = 220,
    this.label,
  }) : assert(values.length == labels.length);

  final List<double> values;
  final List<String> labels;
  final int? active;
  final ValueChanged<int>? onSelect;

  /// Texto do valor (padrão: [qty]).
  final String Function(double value)? format;
  final double height;

  /// Nome do gráfico para o leitor de tela ("Despesas").
  final String? label;

  @override
  State<SsAreaChart> createState() => _SsAreaChartState();
}

const _aTop = 40.0;
const _aBottom = 30.0;
const _aSide = 12.0;

class _SsAreaChartState extends State<SsAreaChart> {
  late int _sel = widget.active ?? widget.values.length - 1;

  @override
  void didUpdateWidget(SsAreaChart old) {
    super.didUpdateWidget(old);
    if (widget.active != null && widget.active != old.active) _sel = widget.active!;
    if (_sel >= widget.values.length) _sel = widget.values.length - 1;
  }

  SsFormats _formats = SsFormats.brl;

  String _fmt(double v) => widget.format?.call(v) ?? qty(v, _formats);

  void _go(int i) {
    final n = widget.values.length;
    if (n == 0) return;
    final k = i.clamp(0, n - 1);
    if (k == _sel) return;
    SsHaptics.tick();
    setState(() => _sel = k);
    widget.onSelect?.call(k);
  }

  void _scrub(double dx, double w) {
    final n = widget.values.length;
    if (n < 2) return;
    _go(((dx - _aSide) / (w - _aSide * 2) * (n - 1)).round());
  }

  @override
  Widget build(BuildContext context) {
    _formats = SsFormats.of(context);
    final c = SsColors.of(context);
    final n = widget.values.length;
    final temSel = n > 0 && _sel >= 0;
    final s = SsStrings.of(context);
    return Semantics(
      label: widget.label == null ? s.areaChart : s.chartOfLabel(widget.label!),
      value: temSel ? '${widget.labels[_sel]}: ${_fmt(widget.values[_sel])}' : s.noData,
      increasedValue: temSel && _sel < n - 1 ? '${widget.labels[_sel + 1]}: ${_fmt(widget.values[_sel + 1])}' : null,
      decreasedValue: temSel && _sel > 0 ? '${widget.labels[_sel - 1]}: ${_fmt(widget.values[_sel - 1])}' : null,
      onIncrease: temSel && _sel < n - 1 ? () => _go(_sel + 1) : null,
      onDecrease: temSel && _sel > 0 ? () => _go(_sel - 1) : null,
      excludeSemantics: true,
      child: SizedBox(
        height: widget.height,
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (d) => _scrub(d.localPosition.dx, w),
              onHorizontalDragUpdate: (d) => _scrub(d.localPosition.dx, w),
              onTapUp: (d) => _scrub(d.localPosition.dx, w),
              // Desenha-se quando entra na tela.
              child: SsTweenInView(
                end: 1,
                duration: const Duration(milliseconds: 900),
                builder: (context, t, _) => CustomPaint(
                  size: Size(w, widget.height),
                  painter: _AreaPainter(
                    values: widget.values,
                    labels: widget.labels,
                    sel: temSel ? _sel : null,
                    t: t,
                    accent: c.accent,
                    accentText: c.accentText,
                    muted: c.muted,
                    surface: c.surface,
                    guide: c.line,
                    valor: temSel ? _fmt(widget.values[_sel]) : '',
                    axis: TextStyle(
                      fontFamily: Theme.of(context).textTheme.bodySmall?.fontFamily,
                      fontSize: AppType.label,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .5,
                      color: c.muted,
                    ),
                    pill: AppTheme.number(
                      context,
                      size: AppType.meta,
                      weight: FontWeight.w500,
                      color: AppColors.onDark,
                    ),
                    scaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AreaPainter extends CustomPainter {
  _AreaPainter({
    required this.values,
    required this.labels,
    required this.sel,
    required this.t,
    required this.accent,
    required this.accentText,
    required this.muted,
    required this.surface,
    required this.guide,
    required this.valor,
    required this.axis,
    required this.pill,
    required this.scaler,
  });

  final List<double> values;
  final List<String> labels;
  final int? sel;
  final double t;
  final Color accent, accentText, muted, surface, guide;
  final String valor;
  final TextStyle axis, pill;
  final TextScaler scaler;

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    if (n == 0) return;
    final lo0 = values.reduce(math.min);
    final hi0 = values.reduce(math.max);
    final span = hi0 - lo0 == 0 ? 1.0 : hi0 - lo0;
    final lo = lo0 - span * .45;
    final hi = hi0 + span * .05;
    final w = size.width - _aSide * 2;
    final base = size.height - _aBottom;
    final h = base - _aTop;
    double x(int i) => _aSide + w * i / math.max(n - 1, 1);
    // Cresce da base: altura multiplicada pelo progresso da entrada.
    double y(double v) => base - h * (v - lo) / (hi - lo) * t;

    // Eixo X: todos os rótulos se couberem, senão um a cada k; o ativo sempre.
    final passo = math.max(1, (n * 34 / math.max(w, 1)).ceil());
    for (var i = 0; i < n; i++) {
      final ativo = i == sel;
      if (!ativo && i % passo != 0) continue;
      if (!ativo && sel != null && (i - sel!).abs() < passo && passo > 1) continue;
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i].toUpperCase(),
          style: ativo ? axis.copyWith(color: accentText, fontWeight: FontWeight.w800) : axis,
        ),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      final dx = (x(i) - tp.width / 2).clamp(0.0, size.width - tp.width);
      tp.paint(canvas, Offset(dx, size.height - tp.height - 4));
    }
    if (n < 2) return;
    final pts = [for (var i = 0; i < n; i++) Offset(x(i), y(values[i]))];
    final linha = _curva(pts);
    final area = Path.from(linha)
      ..lineTo(pts.last.dx, base)
      ..lineTo(pts.first.dx, base)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent.withValues(alpha: .38), accent.withValues(alpha: .02)],
        ).createShader(Rect.fromLTWH(0, _aTop, size.width, h)),
    );
    canvas.drawPath(
      linha,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawLine(Offset(0, base), Offset(size.width, base), Paint()..color = guide);

    final s = sel;
    if (s == null || t < .6) return;
    final p = pts[s];
    // Tracejado do ponto até a base.
    final tr = Paint()
      ..color = accent.withValues(alpha: .6)
      ..strokeWidth = 1.4;
    for (var yy = p.dy + 8; yy < base; yy += 6) {
      canvas.drawLine(Offset(p.dx, yy), Offset(p.dx, math.min(yy + 3, base)), tr);
    }
    canvas.drawCircle(p, 9, Paint()..color = accent.withValues(alpha: .22));
    canvas.drawCircle(p, 6, Paint()..color = surface);
    canvas.drawCircle(p, 4, Paint()..color = accent);
    // Pílula com o valor em cima do ponto.
    final tp = TextPainter(
      text: TextSpan(text: valor, style: pill),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final pw = tp.width + 18;
    final ph = tp.height + 10;
    final left = (p.dx - pw / 2).clamp(0.0, size.width - pw);
    final top = math.max(0.0, p.dy - ph - 14);
    final r = RRect.fromLTRBR(left, top, left + pw, top + ph, Radius.circular(ph / 2));
    canvas.drawRRect(r, Paint()..color = accent);
    // Biquinho apontando para o ponto.
    final bx = p.dx.clamp(left + 10, left + pw - 10);
    canvas.drawPath(
      Path()
        ..moveTo(bx - 5, top + ph - 1)
        ..lineTo(bx + 5, top + ph - 1)
        ..lineTo(bx, top + ph + 5)
        ..close(),
      Paint()..color = accent,
    );
    tp.paint(canvas, Offset(left + 9, top + 5));
  }

  @override
  bool shouldRepaint(_AreaPainter old) =>
      old.t != t || old.sel != sel || old.values != values || old.accent != accent || old.surface != surface;
}

// ---------------------------------------------------------------------------
// SsExplodedDonut
// ---------------------------------------------------------------------------

/// Uma fatia do [SsExplodedDonut].
class SsDonutSlice {
  const SsDonutSlice(this.label, this.value, {this.color});
  final String label;
  final double value;
  final Color? color;
}

/// Rosca com fatias de espessuras diferentes (a maior é a mais grossa): a
/// selecionada sai um pouco para fora e o centro mostra o valor dela (sem
/// seleção, o total). Legenda com bolinhas embaixo; tocar na fatia ou na
/// legenda seleciona, tocar de novo volta ao total.
class SsExplodedDonut extends StatefulWidget {
  const SsExplodedDonut({
    super.key,
    required this.slices,
    this.selected,
    this.onSelect,
    this.format,
    this.totalLabel,
    this.size = 200,
    this.legend = true,
  });

  final List<SsDonutSlice> slices;
  final int? selected;
  final ValueChanged<int?>? onSelect;
  final String Function(double value)? format;

  /// Padrão: [SsStrings.total].
  final String? totalLabel;
  final double size;
  final bool legend;

  @override
  State<SsExplodedDonut> createState() => _SsExplodedDonutState();
}

class _SsExplodedDonutState extends State<SsExplodedDonut> {
  late int? _sel = widget.selected;
  int? _prev;

  SsFormats _formats = SsFormats.brl;

  String _fmt(double v) => widget.format?.call(v) ?? qty(v, _formats);
  double get _total => widget.slices.fold(0.0, (s, e) => s + math.max(0, e.value));

  void _pick(int? i) {
    final novo = i == _sel ? null : i;
    SsHaptics.tick();
    setState(() {
      _prev = _sel;
      _sel = novo;
    });
    widget.onSelect?.call(novo);
  }

  void _tap(Offset p) {
    final c = Offset(widget.size / 2, widget.size / 2);
    final d = p - c;
    if (d.distance < widget.size * .25 || _total == 0) return;
    var a = math.atan2(d.dy, d.dx) + math.pi / 2;
    if (a < 0) a += 2 * math.pi;
    var acc = 0.0;
    for (var i = 0; i < widget.slices.length; i++) {
      acc += math.max(0, widget.slices[i].value) / _total * 2 * math.pi;
      if (a <= acc) return _pick(i);
    }
  }

  @override
  Widget build(BuildContext context) {
    _formats = SsFormats.of(context);
    final c = SsColors.of(context);
    final cores = [
      for (var i = 0; i < widget.slices.length; i++) widget.slices[i].color ?? c.series[i % c.series.length],
    ];
    final total = _total;
    final sel = _sel;
    final dur = reduceMotion(context) ? Duration.zero : SsMotion.base;
    final str = SsStrings.of(context);
    final totalLabel = widget.totalLabel ?? str.total;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: str.donutSummary(
            '$totalLabel ${_fmt(total)}',
            [for (final s in widget.slices) '${s.label} ${_fmt(s.value)}'].join(', '),
          ),
          excludeSemantics: true,
          child: GestureDetector(
            onTapUp: (d) => _tap(d.localPosition),
            child: SizedBox.square(
              dimension: widget.size,
              child: SsTweenInView(
                end: 1,
                duration: const Duration(milliseconds: 800),
                builder: (context, entra, _) => TweenAnimationBuilder<double>(
                  key: ValueKey(sel),
                  tween: Tween(begin: 0, end: 1),
                  duration: dur,
                  curve: SsMotion.spring,
                  builder: (context, k, _) => CustomPaint(
                    painter: _DonutPainter(
                      values: [for (final s in widget.slices) math.max(0, s.value).toDouble()],
                      colors: cores,
                      sel: sel,
                      prev: _prev,
                      k: k,
                      t: entra,
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: dur,
                        child: Column(
                          key: ValueKey(sel),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              sel == null ? totalLabel : widget.slices[sel].label,
                              style: TextStyle(color: c.muted, fontSize: AppType.meta, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: widget.size * .5),
                              child: FittedBox(
                                child: Text(
                                  _fmt(sel == null ? total : widget.slices[sel].value),
                                  style: AppTheme.number(context, size: widget.size * .11, color: c.ink),
                                ),
                              ),
                            ),
                            if (sel != null && total > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${(widget.slices[sel].value / total * 100).round()}%',
                                style: AppTheme.number(context, size: AppType.meta, color: c.muted),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.legend) ...[
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 2,
            children: [
              for (var i = 0; i < widget.slices.length; i++)
                Semantics(
                  button: true,
                  selected: i == sel,
                  label:
                      '${widget.slices[i].label}: ${_fmt(widget.slices[i].value)}'
                      '${total > 0 ? ', ${(widget.slices[i].value / total * 100).round()}%' : ''}',
                  excludeSemantics: true,
                  child: SsPressable(
                    onTap: () => _pick(i),
                    child: AnimatedContainer(
                      duration: SsMotion.fast,
                      constraints: const BoxConstraints(minHeight: 40),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: i == sel ? cores[i].withValues(alpha: c.isDark ? .22 : .14) : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(color: cores[i], shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.slices[i].label,
                            style: TextStyle(
                              color: i == sel ? c.ink : c.ink2,
                              fontSize: AppType.sub,
                              fontWeight: i == sel ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.values,
    required this.colors,
    required this.sel,
    required this.prev,
    required this.k,
    required this.t,
  });

  final List<double> values;
  final List<Color> colors;
  final int? sel, prev;
  final double k, t;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold(0.0, (s, v) => s + v);
    if (total == 0) return;
    final maior = values.reduce(math.max);
    final c = size.center(Offset.zero);
    final rOut = size.shortestSide / 2 - 10;
    const minT = 12.0;
    final maxT = size.shortestSide * .16;
    final gap = values.where((v) => v > 0).length > 1 ? .035 : 0.0;
    var a = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * 2 * math.pi * t;
      if (sweep <= 0) continue;
      final esp = minT + (maxT - minT) * (values[i] / maior);
      // Selecionada: sai para fora e engrossa; a anterior volta.
      final ex = i == sel ? k : (i == prev ? 1 - k : 0.0);
      final mid = a + sweep / 2;
      final off = Offset(math.cos(mid), math.sin(mid)) * 7 * ex;
      final w = esp + 4 * ex;
      // Borda de dentro comum a todas; a espessura cresce para fora.
      final rIn = rOut - maxT - 4;
      final rect = Rect.fromCircle(center: c + off, radius: rIn + w / 2);
      canvas.drawArc(
        rect,
        a + gap / 2,
        math.max(0.001, sweep - gap),
        false,
        Paint()
          ..color = sel == null || i == sel ? colors[i] : colors[i].withValues(alpha: .55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w,
      );
      a += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => true;
}

// ---------------------------------------------------------------------------
// SsBigRing
// ---------------------------------------------------------------------------

/// Percentual grande num anel fino com marcações em volta (estilo
/// termostato): as marcações até o valor acendem na cor da marca. Enche e
/// conta quando entra na tela.
class SsBigRing extends StatelessWidget {
  const SsBigRing(this.value, {super.key, this.caption, this.size = 200, this.color, this.ticks = 60});

  /// 0 a 1.
  final double value;

  /// Texto embaixo do número ("da meta", "umidade").
  final String? caption;
  final double size;
  final Color? color;
  final int ticks;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final cor = color ?? c.accent;
    final v = value.clamp(0.0, 1.0);
    final pct = (v * 100).round();
    return Semantics(
      label: '$pct%${caption == null ? '' : ' $caption'}',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: SsTweenInView(
          end: v,
          duration: const Duration(milliseconds: 900),
          builder: (context, t, _) => CustomPaint(
            painter: _BigRingPainter(t: t, color: cor, track: c.field, tick: c.muted2, ticks: ticks),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      text: '${(t * 100).round()}',
                      children: [
                        TextSpan(
                          text: '%',
                          style: AppTheme.number(context, size: size * .11, color: c.muted),
                        ),
                      ],
                    ),
                    style: AppTheme.number(context, size: size * .24, weight: FontWeight.w400, color: c.ink),
                  ),
                  if (caption != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      caption!,
                      style: TextStyle(color: c.muted, fontSize: AppType.sub, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BigRingPainter extends CustomPainter {
  _BigRingPainter({required this.t, required this.color, required this.track, required this.tick, required this.ticks});

  final double t;
  final Color color, track, tick;
  final int ticks;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    for (var k = 0; k < ticks; k++) {
      final a = -math.pi / 2 + 2 * math.pi * k / ticks;
      final on = k / ticks < t;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        c + dir * (r - 2),
        c + dir * (r - (k % 5 == 0 ? 11 : 7)),
        Paint()
          ..color = on ? color : tick
          ..strokeWidth = k % 5 == 0 ? 2 : 1.3
          ..strokeCap = StrokeCap.round,
      );
    }
    final ar = r - 22;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, ar, p..color = track);
    if (t > 0) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: ar), -math.pi / 2, 2 * math.pi * t, false, p..color = color);
      final a = -math.pi / 2 + 2 * math.pi * t;
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * ar, 6, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_BigRingPainter old) => old.t != t || old.color != color || old.track != track;
}

// ---------------------------------------------------------------------------
// SsFloatingBars
// ---------------------------------------------------------------------------

/// Barras verticais grandes dentro de um card na cor da marca: as outras
/// translúcidas, a selecionada branca com o "detalhe" (valor numa etiqueta em
/// cima). Tocar escolhe. [title] e [value] vão no topo do card.
class SsFloatingBars extends StatefulWidget {
  const SsFloatingBars({
    super.key,
    required this.values,
    required this.labels,
    this.selected,
    this.onSelect,
    this.format,
    this.title,
    this.value,
    this.height = 260,
  }) : assert(values.length == labels.length);

  final List<double> values;
  final List<String> labels;
  final int? selected;
  final ValueChanged<int>? onSelect;
  final String Function(double value)? format;
  final String? title;

  /// Texto pronto (`money(...)`) ao lado do título.
  final String? value;
  final double height;

  @override
  State<SsFloatingBars> createState() => _SsFloatingBarsState();
}

class _SsFloatingBarsState extends State<SsFloatingBars> {
  late int _sel = widget.selected ?? widget.values.length - 1;

  SsFormats _formats = SsFormats.brl;

  String _fmt(double v) => widget.format?.call(v) ?? qty(v, _formats);

  /// Altura (0 a ~1,12) da barra [i] no instante [t] da cascata.
  double _sobe(double t, int i) {
    final total = 520 + 40 * (widget.values.length - 1);
    return SsMotion.bounce.transform(((t * total - 40 * i) / 520).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    _formats = SsFormats.of(context);
    final c = SsColors.of(context);
    // Fundo cheio na cor da marca (versão do claro, que passa AA com branco).
    final fundo = c.brand.accentLight;
    final hi = widget.values.fold<double>(0, math.max);
    return Container(
      height: widget.height,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(AppRadius.cardActive),
        boxShadow: c.primaryShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null || widget.value != null)
            Row(
              children: [
                if (widget.title != null)
                  Expanded(
                    child: Text(
                      widget.title!,
                      style: TextStyle(
                        color: AppColors.onDark.withValues(alpha: .85),
                        fontSize: AppType.set,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (widget.value != null)
                  Text(
                    widget.value!,
                    style: AppTheme.number(context, size: AppType.lg, color: AppColors.onDark),
                  ),
              ],
            ),
          const SizedBox(height: 10),
          Expanded(
            // Cada barra sobe com mola, 40 ms depois da anterior, quando entra na tela.
            child: SsInView(
              duration: Duration(milliseconds: 520 + 40 * (widget.values.length - 1)),
              curve: Curves.linear,
              builder: (context, anim, _) => Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < widget.values.length; i++)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: i == _sel,
                        label: '${widget.labels[i]}: ${_fmt(widget.values[i])}',
                        excludeSemantics: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (i == _sel) return;
                            SsHaptics.tick();
                            setState(() => _sel = i);
                            widget.onSelect?.call(i);
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Etiqueta do detalhe: pode passar da largura da coluna.
                              SizedBox(
                                height: 22,
                                child: OverflowBox(
                                  maxWidth: 200,
                                  child: AnimatedOpacity(
                                    opacity: i == _sel ? 1 : 0,
                                    duration: SsMotion.fast,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.onDark,
                                        borderRadius: BorderRadius.circular(AppRadius.pill),
                                      ),
                                      child: Text(
                                        _fmt(widget.values[i]),
                                        maxLines: 1,
                                        softWrap: false,
                                        overflow: TextOverflow.visible,
                                        textScaler: TextScaler.noScaling,
                                        style: AppTheme.number(context, size: AppType.micro, color: AppColors.inkLight),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Flexible(
                                child: FractionallySizedBox(
                                  heightFactor: hi == 0
                                      ? .05
                                      : math.max(.05, widget.values[i] / hi * _sobe(anim.value, i).clamp(0.0, 1.05)),
                                  child: AnimatedContainer(
                                    duration: SsMotion.fast,
                                    width: 22,
                                    decoration: BoxDecoration(
                                      color: i == _sel ? AppColors.onDark : AppColors.onDark.withValues(alpha: .26),
                                      borderRadius: BorderRadius.circular(AppRadius.pill),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.labels[i],
                                maxLines: 1,
                                style: TextStyle(
                                  color: AppColors.onDark.withValues(alpha: i == _sel ? 1 : .8),
                                  fontSize: AppType.label,
                                  fontWeight: i == _sel ? FontWeight.w800 : FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
