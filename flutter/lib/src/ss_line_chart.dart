import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'format.dart';
import 'motion.dart';

/// Uma série do [SsLineChart]: os valores (um por rótulo), o nome que vai no
/// balão e a cor (sem cor: a paleta da suíte, começando na marca).
class SsSeries {
  const SsSeries(this.values, {this.name, this.color});

  final List<double> values;
  final String? name;
  final Color? color;
}

/// Gráfico de linhas (até 3 séries) com eixo discreto: 3 linhas guia com o
/// valor em DM Mono e poucos rótulos embaixo. Arrastar o dedo mostra a linha
/// vertical, os pontos e um balão com o rótulo e os valores (tique de haptic a
/// cada ponto); soltou, some. [target] desenha uma linha tracejada de alvo
/// com [targetLabel]. Desenha-se da esquerda para a direita ao aparecer.
///
/// `SsLineChart(series: [SsSeries(precos, name: 'Preço')], labels: datas, format: (v) => money(v.round()))`
class SsLineChart extends StatefulWidget {
  const SsLineChart({
    super.key,
    required this.series,
    required this.labels,
    this.target,
    this.targetLabel = 'meta',
    this.format,
    this.height = 180,
  });

  final List<SsSeries> series;

  /// Um por ponto (datas: "01/10"). Só alguns aparecem no eixo; todos no balão.
  final List<String> labels;
  final double? target;
  final String targetLabel;

  /// Texto de um valor (padrão: [qty]).
  final String Function(double value)? format;
  final double height;

  @override
  State<SsLineChart> createState() => _SsLineChartState();
}

// Respiros do desenho (o balão usa a mesma conta do pintor).
const _side = 4.0;
const _top = 16.0;
const _bottom = 22.0;

class _SsLineChartState extends State<SsLineChart> {
  int? _sel;

  int get _n => widget.labels.length;

  String _fmt(double v) => widget.format?.call(v) ?? qty(v);

  void _scrub(double dx, double width) {
    if (_n < 2) return;
    final i = ((dx - _side) / (width - _side * 2) * (_n - 1)).round().clamp(0, _n - 1);
    if (i == _sel) return;
    HapticFeedback.selectionClick();
    setState(() => _sel = i);
  }

  void _solta([_]) => setState(() => _sel = null);

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final paleta = [c.accent, ...AppColors.series.skip(1)];
    final series = [
      for (var i = 0; i < widget.series.length; i++) (widget.series[i].values, widget.series[i].color ?? paleta[i]),
    ];
    final todos = [for (final s in widget.series) ...s.values, ?widget.target];
    var lo = todos.isEmpty ? 0.0 : todos.reduce(math.min);
    var hi = todos.isEmpty ? 1.0 : todos.reduce(math.max);
    if (hi == lo) {
      hi += 1;
      lo -= 1;
    }
    final primeira = widget.series.first.values;
    final resumo = primeira.isEmpty
        ? 'sem dados'
        : 'mínimo ${_fmt(primeira.reduce(math.min))}, máximo ${_fmt(primeira.reduce(math.max))}, '
              'último ${_fmt(primeira.last)}';

    return Semantics(
      label: 'Gráfico${widget.series.first.name == null ? '' : ' de ${widget.series.first.name}'}: $resumo',
      excludeSemantics: true,
      child: SizedBox(
        height: widget.height,
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            final sel = _sel;
            final xSel = sel == null ? 0.0 : _side + (w - _side * 2) * sel / math.max(_n - 1, 1);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (d) => _scrub(d.localPosition.dx, w),
              onHorizontalDragUpdate: (d) => _scrub(d.localPosition.dx, w),
              onHorizontalDragEnd: _solta,
              onHorizontalDragCancel: _solta,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (_, t, _) => CustomPaint(
                        painter: _LinePainter(
                          series: series,
                          labels: widget.labels,
                          lo: lo,
                          hi: hi,
                          target: widget.target,
                          targetLabel: widget.targetLabel,
                          t: t,
                          sel: sel,
                          format: _fmt,
                          guide: c.line,
                          ink: c.ink,
                          surface: c.surface,
                          axis: AppTheme.number(context, size: AppType.micro, color: c.muted),
                        ),
                      ),
                    ),
                  ),
                  if (sel != null)
                    Positioned(
                      top: 0,
                      left: (xSel - 64).clamp(0.0, math.max(0.0, w - 128)),
                      width: 128,
                      child: IgnorePointer(child: _Balao(widget.labels[sel], widget.series, series, sel, _fmt)),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Balao extends StatelessWidget {
  const _Balao(this.label, this.series, this.cores, this.i, this.fmt);

  final String label;
  final List<SsSeries> series;
  final List<(List<double>, Color)> cores;
  final int i;
  final String Function(double) fmt;

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
          for (var s = 0; s < series.length; s++)
            if (i < series[s].values.length)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(color: cores[s].$2, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    if (series[s].name != null)
                      Flexible(
                        child: Text(
                          series[s].name!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: AppType.micro, color: c.muted),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      fmt(series[s].values[i]),
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

/// Curva suave por Catmull-Rom em cúbicas (a mesma do SsSparkline).
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

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.series,
    required this.labels,
    required this.lo,
    required this.hi,
    required this.target,
    required this.targetLabel,
    required this.t,
    required this.sel,
    required this.format,
    required this.guide,
    required this.ink,
    required this.surface,
    required this.axis,
  });

  final List<(List<double>, Color)> series;
  final List<String> labels;
  final double lo, hi;
  final double? target;
  final String targetLabel;
  final double t;
  final int? sel;
  final String Function(double) format;
  final Color guide, ink, surface;
  final TextStyle axis;

  void _text(Canvas canvas, String s, Offset at, {TextStyle? style, double alignX = 0}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: style ?? axis),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width * alignX, 0));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = labels.length;
    final w = size.width - _side * 2;
    final h = size.height - _top - _bottom;
    double y(double v) => _top + h * (1 - (v - lo) / (hi - lo));
    double x(int i) => _side + w * i / math.max(n - 1, 1);

    // Eixo Y discreto: 3 linhas guia finas, valor em cima de cada uma.
    final fina = Paint()
      ..color = guide
      ..strokeWidth = 1;
    for (final v in [lo, (lo + hi) / 2, hi]) {
      canvas.drawLine(Offset(0, y(v)), Offset(size.width, y(v)), fina);
      _text(canvas, format(v), Offset(_side, y(v) - 13));
    }
    // Eixo X: até 4 rótulos espaçados (primeiro e último sempre).
    if (n > 0) {
      final passos = math.min(3, n - 1);
      for (var k = 0; k <= passos; k++) {
        final i = passos == 0 ? 0 : (k * (n - 1) / passos).round();
        _text(canvas, labels[i], Offset(x(i), size.height - 13), alignX: k == 0 ? 0 : (k == passos ? 1 : .5));
      }
    }
    // Alvo: tracejado com rótulo à direita.
    if (target != null) {
      final ty = y(target!);
      final tr = Paint()
        ..color = ink.withValues(alpha: .45)
        ..strokeWidth = 1.2;
      for (var dx = 0.0; dx < size.width; dx += 8) {
        canvas.drawLine(Offset(dx, ty), Offset(math.min(dx + 4, size.width), ty), tr);
      }
      _text(
        canvas,
        '$targetLabel ${format(target!)}',
        Offset(size.width - _side, ty - 13),
        style: axis.copyWith(color: ink),
        alignX: 1,
      );
    }
    // Linhas, reveladas da esquerda para a direita.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * t, size.height));
    for (final (values, color) in series) {
      if (values.length < 2) continue;
      final pts = [for (var i = 0; i < values.length; i++) Offset(x(i), y(values[i]))];
      final line = _curva(pts);
      if (series.length == 1) {
        final area = Path.from(line)
          ..lineTo(pts.last.dx, _top + h)
          ..lineTo(pts.first.dx, _top + h)
          ..close();
        canvas.drawPath(
          area,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withValues(alpha: .2), color.withValues(alpha: 0)],
            ).createShader(Rect.fromLTWH(0, _top, size.width, h)),
        );
      }
      canvas.drawPath(
        line,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    canvas.restore();
    // Scrub: linha vertical e um ponto em cada série.
    final s = sel;
    if (s != null) {
      canvas.drawLine(
        Offset(x(s), _top - 4),
        Offset(x(s), _top + h),
        Paint()
          ..color = ink.withValues(alpha: .35)
          ..strokeWidth = 1,
      );
      for (final (values, color) in series) {
        if (s >= values.length) continue;
        final p = Offset(x(s), y(values[s]));
        canvas.drawCircle(p, 5.5, Paint()..color = surface);
        canvas.drawCircle(p, 4, Paint()..color = color);
      }
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.t != t || old.sel != sel || old.series != series || old.target != target || old.guide != guide;
}
