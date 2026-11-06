// v0.10 (dados): gráfico de séries no tempo (histórico de sensores): várias
// séries com instantes reais e desiguais, eixo do tempo inteligente, um eixo Y
// por unidade (até duas), linha/área/degrau, legenda que liga e desliga,
// cursor com balão e faixas de estado alinhadas embaixo.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../motion_view.dart';
import '../skeleton.dart';
import '../ss_badge.dart';
import '../ss_strings.dart';
import 'dados_formato.dart';
import 'dados_state_bands.dart';

/// Como uma série se desenha: [line] (linha reta entre leituras), [area]
/// (linha com área em degradê) ou [step] (degrau: o valor vale até a próxima
/// leitura; para valores discretos, como nível ou modo).
enum SsTimeChartMode { line, area, step }

/// Uma leitura: instante, valor ([v] nulo = buraco, a linha quebra) e, se a
/// série for agregada (média por hora), o [min] e o [max] do período, que
/// viram uma faixa clara atrás da linha.
class SsTimePoint {
  const SsTimePoint(this.t, this.v, {this.min, this.max});

  final DateTime t;
  final double? v;
  final double? min;
  final double? max;
}

/// Uma série do [SsTimeChart]. [unit] agrupa os eixos (duas unidades = um
/// eixo de cada lado); [mode] troca o modo do gráfico só nesta série; sem
/// [color], a paleta da suíte (começando na marca).
class SsTimeSeries {
  const SsTimeSeries({required this.name, required this.points, this.unit, this.color, this.mode, this.decimals});

  final String name;

  /// Em ordem de tempo.
  final List<SsTimePoint> points;
  final String? unit;
  final Color? color;
  final SsTimeChartMode? mode;

  /// Casas decimais do valor (padrão: automáticas pelo tamanho).
  final int? decimals;

  /// Valor no instante [t]: no degrau, a última leitura até [t]; na linha, a
  /// reta entre as leituras vizinhas (buraco = nulo). Depois da última
  /// leitura vale a última; antes da primeira, nulo. O Rails faz igual.
  double? valueAt(DateTime t, SsTimeChartMode mode) {
    final p = points;
    if (p.isEmpty || t.isBefore(p.first.t)) return null;
    var lo = 0, hi = p.length - 1, i = 0;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (!p[mid].t.isAfter(t)) {
        i = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    final a = p[i];
    if (mode == SsTimeChartMode.step || i == p.length - 1 || a.v == null) return a.v;
    final b = p[i + 1];
    if (b.v == null) return a.v;
    final span = b.t.difference(a.t).inMilliseconds;
    if (span <= 0) return b.v;
    final f = t.difference(a.t).inMilliseconds / span;
    return a.v! + (b.v! - a.v!) * f;
  }
}

/// Gráfico de séries no tempo. Os instantes são reais (leituras desiguais
/// ficam onde aconteceram) e o eixo X escolhe as marcas pelo intervalo:
/// horas num dia, dias numa semana, meses num ano. Duas unidades (°C e %)
/// ganham um eixo de cada lado; mais que isso dividem um só.
///
/// - Arrastar (ou tocar) mostra o cursor com o horário e o valor de cada
///   série (e o estado de cada faixa de [bands]); soltou, some.
/// - Toque duplo aproxima 2× naquele ponto; "Ver tudo" volta. [onZoom] avisa
///   o app (para buscar leituras mais finas da janela).
/// - A legenda liga e desliga cada série (o eixo Y se ajusta).
/// - Desenha-se da esquerda para a direita quando entra na tela.
/// - Número e data no idioma do `Localizations` (ou [locale]).
///
/// `SsTimeChart(series: [SsTimeSeries(name: 'Sala', unit: '°C', points: leituras)], from: ontem, to: agora)`
class SsTimeChart extends StatefulWidget {
  const SsTimeChart({
    super.key,
    required this.series,
    this.from,
    this.to,
    this.mode = SsTimeChartMode.line,
    this.bands = const [],
    this.bandTones = const {},
    this.loading = false,
    this.height = 200,
    this.legend = true,
    this.dualAxis = true,
    this.locale,
    this.title,
    this.onScrub,
    this.onZoom,
    this.initialCursor,
    this.initialZoom,
    this.emptyText,
    this.resetZoomLabel,
    this.loadingLabel,
    this.minLabel,
    this.maxLabel,
    this.lastLabel,
    this.untilText,
    this.utcOffset,
    this.showValues = false,
    this.legendAlways = false,
  });

  final List<SsTimeSeries> series;

  /// Janela do eixo (padrão: da 1ª à última leitura).
  final DateTime? from;
  final DateTime? to;
  final SsTimeChartMode mode;

  /// Faixas de estado embaixo do gráfico, no mesmo eixo e sob o mesmo cursor.
  final List<SsStateRow> bands;
  final Map<String, SsTone> bandTones;

  /// Esqueleto na altura final (os dados ainda não chegaram).
  final bool loading;

  /// Altura da área do gráfico (sem faixas, eixo e legenda).
  final double height;
  final bool legend;

  /// Duas unidades → um eixo de cada lado. Falso: um eixo só, dividido.
  final bool dualAxis;

  /// Idioma dos números e das datas (padrão: o do `Localizations`).
  final Locale? locale;

  /// Nome do gráfico para o leitor de tela ("Clima da sala").
  final String? title;

  /// Instante do cursor (nulo quando some): para sincronizar outra peça.
  final ValueChanged<DateTime?>? onScrub;

  /// Janela nova depois do toque duplo ou do "Ver tudo".
  final void Function(DateTime from, DateTime to)? onZoom;

  /// Começa com o cursor neste instante (estado de catálogo, deep link).
  final DateTime? initialCursor;

  /// Começa aproximado nesta janela (com o "Ver tudo").
  final (DateTime, DateTime)? initialZoom;

  final String? emptyText;
  final String? resetZoomLabel;
  final String? loadingLabel;
  final String? minLabel;
  final String? maxLabel;
  final String? lastLabel;

  /// Entre as datas do resumo: "04/11 10:00 a 05/11 10:00".
  final String? untilText;

  /// Fuso fixo das horas e datas (ex.: `Duration(hours: -3)`, o do site);
  /// nulo = o do aparelho. Ver [SsTimeFormat.utcOffset].
  final Duration? utcOffset;

  /// A legenda mostra o valor de cada série: o do cursor enquanto arrasta,
  /// senão a última leitura ("Sala 23,4 °C").
  final bool showValues;

  /// Legenda mesmo com uma série só (com [showValues], vira o "valor
  /// atual" do gráfico). Sem efeito com [legend] falso.
  final bool legendAlways;

  @override
  State<SsTimeChart> createState() => _SsTimeChartState();
}

// Respiro de cima (rótulo da guia mais alta) e de baixo da área do gráfico.
const _top = 14.0;
const _bottom = 4.0;

class _Eixo {
  _Eixo(this.unit, this.lo, this.hi, this.step);
  final String? unit;
  final double lo, hi, step;
}

class _SsTimeChartState extends State<SsTimeChart> {
  SsStrings get _s => SsStrings.of(context);
  final _ocultas = <int>{};
  late DateTime? _cursor = widget.initialCursor;
  late (DateTime, DateTime)? _zoom = widget.initialZoom;

  (DateTime, DateTime)? get _cheio {
    DateTime? a = widget.from, b = widget.to;
    for (final s in widget.series) {
      if (s.points.isEmpty) continue;
      if (widget.from == null && (a == null || s.points.first.t.isBefore(a))) a = s.points.first.t;
      if (widget.to == null && (b == null || s.points.last.t.isAfter(b))) b = s.points.last.t;
    }
    final faixa = SsStateBands.rangeOf(widget.bands, widget.from, widget.to);
    if (faixa != null) {
      if (widget.from == null && (a == null || faixa.$1.isBefore(a))) a = faixa.$1;
      if (widget.to == null && (b == null || faixa.$2.isAfter(b))) b = faixa.$2;
    }
    if (a == null || b == null || !b.isAfter(a)) return null;
    return (a, b);
  }

  SsTimeChartMode _modo(SsTimeSeries s) => s.mode ?? widget.mode;

  @override
  void didUpdateWidget(SsTimeChart old) {
    super.didUpdateWidget(old);
    // Janela nova vinda do app (buscou leituras finas): ela manda.
    if (old.from != widget.from || old.to != widget.to) _zoom = null;
    _ocultas.removeWhere((i) => i >= widget.series.length);
  }

  void _scrub(double dx, double w, (DateTime, DateTime) janela) {
    final span = janela.$2.difference(janela.$1).inMilliseconds;
    final t = janela.$1.add(Duration(milliseconds: (dx.clamp(0.0, w) / w * span).round()));
    if (_cursor == null) SsHaptics.tick();
    setState(() => _cursor = t);
    widget.onScrub?.call(t);
  }

  void _solta([_]) {
    if (_cursor == null) return;
    setState(() => _cursor = null);
    widget.onScrub?.call(null);
  }

  void _aproxima(double dx, double w, (DateTime, DateTime) janela, (DateTime, DateTime) cheio) {
    final span = janela.$2.difference(janela.$1).inMilliseconds;
    final novo = span ~/ 2;
    if (novo < const Duration(minutes: 5).inMilliseconds) return;
    final centro = janela.$1.add(Duration(milliseconds: (dx / w * span).round()));
    var a = centro.subtract(Duration(milliseconds: novo ~/ 2));
    var b = a.add(Duration(milliseconds: novo));
    if (a.isBefore(cheio.$1)) {
      a = cheio.$1;
      b = a.add(Duration(milliseconds: novo));
    }
    if (b.isAfter(cheio.$2)) {
      b = cheio.$2;
      a = b.subtract(Duration(milliseconds: novo));
    }
    SsHaptics.tick();
    setState(() {
      _zoom = (a, b);
      _cursor = null;
    });
    widget.onZoom?.call(a, b);
  }

  void _verTudo((DateTime, DateTime) cheio) {
    setState(() => _zoom = null);
    widget.onZoom?.call(cheio.$1, cheio.$2);
  }

  /// Eixos Y das séries visíveis: por unidade (até 2 com [dualAxis]) ou um só.
  List<(_Eixo, List<int>)> _eixos((DateTime, DateTime) janela) {
    final vis = [
      for (var i = 0; i < widget.series.length; i++)
        if (!_ocultas.contains(i)) i,
    ];
    final unidades = <String?>[];
    for (final i in vis) {
      if (!unidades.contains(widget.series[i].unit)) unidades.add(widget.series[i].unit);
    }
    final grupos = widget.dualAxis && unidades.length == 2
        ? [
            for (final u in unidades)
              [
                for (final i in vis)
                  if (widget.series[i].unit == u) i,
              ],
          ]
        : [vis];
    return [
      for (final g in grupos)
        if (g.isNotEmpty)
          (_eixo(g, janela, unidades.length == 1 || grupos.length == 2 ? widget.series[g.first].unit : null), g),
    ];
  }

  _Eixo _eixo(List<int> idx, (DateTime, DateTime) janela, String? unit) {
    var lo = double.infinity, hi = -double.infinity;
    for (final i in idx) {
      final pts = widget.series[i].points;
      for (var k = 0; k < pts.length; k++) {
        final p = pts[k];
        // Conta também a leitura logo antes e logo depois da janela (a linha passa por elas).
        final dentro = !p.t.isBefore(janela.$1) && !p.t.isAfter(janela.$2);
        final vizinha =
            (k + 1 < pts.length && p.t.isBefore(janela.$1) && !pts[k + 1].t.isBefore(janela.$1)) ||
            (k > 0 && p.t.isAfter(janela.$2) && !pts[k - 1].t.isAfter(janela.$2));
        if (!dentro && !vizinha) continue;
        for (final v in [p.v, p.min, p.max]) {
          if (v == null) continue;
          lo = math.min(lo, v);
          hi = math.max(hi, v);
        }
      }
    }
    if (lo == double.infinity) {
      lo = 0;
      hi = 1;
    }
    final n = ssNiceRange(lo, hi, count: 3);
    return _Eixo(unit, n.lo, n.hi, n.step);
  }

  String _resumo(SsTimeFormat fmt, (DateTime, DateTime) janela) {
    final partes = <String>[];
    for (final s in widget.series) {
      final vs = [
        for (final p in s.points)
          if (p.v != null && !p.t.isBefore(janela.$1) && !p.t.isAfter(janela.$2)) p.v!,
      ];
      if (vs.isEmpty) continue;
      String v(double x) => fmt.value(x, unit: s.unit, decimals: s.decimals);
      partes.add(
        '${s.name}: ${widget.minLabel ?? _s.chartMin} ${v(vs.reduce(math.min))}, ${widget.maxLabel ?? _s.chartMax} ${v(vs.reduce(math.max))}, '
        '${widget.lastLabel ?? _s.chartLast} ${v(vs.last)}',
      );
    }
    final periodo = '${fmt.when(janela.$1)} ${widget.untilText ?? _s.chartUntil} ${fmt.when(janela.$2)}';
    return '${widget.title ?? ''}${widget.title == null ? '' : ', '}$periodo. ${partes.join('. ')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final fmt = SsTimeFormat.of(context, widget.locale, widget.utcOffset);
    if (widget.loading) {
      return Semantics(
        label: widget.loadingLabel ?? _s.chartLoading,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SkeletonBox(height: widget.height, radius: AppRadius.thumb),
            if (widget.legend) ...[
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(width: 160, child: SkeletonBox(height: 14)),
              ),
            ],
          ],
        ),
      );
    }
    final cheio = _cheio;
    final semDados = cheio == null || widget.series.every((s) => s.points.every((p) => p.v == null));
    if (cheio == null || (semDados && widget.bands.isEmpty)) {
      return Semantics(
        label: '${widget.title == null ? '' : '${widget.title}: '}${widget.emptyText ?? _s.chartNoReadings}',
        excludeSemantics: true,
        child: Container(
          height: widget.height,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(AppRadius.thumb)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.show_chart_rounded, color: c.muted2, size: 32),
              const SizedBox(height: 6),
              Text(
                widget.emptyText ?? _s.chartNoReadings,
                style: TextStyle(color: c.muted, fontSize: SsDensity.of(context).font(AppType.sub)),
              ),
            ],
          ),
        ),
      );
    }
    final janela = _zoom ?? cheio;
    final cores = [
      for (var i = 0; i < widget.series.length; i++) widget.series[i].color ?? c.series[i % c.series.length],
    ];
    final eixos = _eixos(janela);
    final bandCores = ssStateColors(context, widget.bands, widget.bandTones);

    return Semantics(
      container: true,
      label: _resumo(fmt, janela),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth;
              final span = janela.$2.difference(janela.$1).inMilliseconds;
              final cur = _cursor;
              final xCur = cur == null ? 0.0 : w * cur.difference(janela.$1).inMilliseconds / span;
              return Stack(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: (d) => _scrub(d.localPosition.dx, w, janela),
                    onHorizontalDragUpdate: (d) => _scrub(d.localPosition.dx, w, janela),
                    onHorizontalDragEnd: _solta,
                    onHorizontalDragCancel: _solta,
                    // Toque mostra o balão; outro toque esconde.
                    onTapDown: (d) => _cursor == null ? _scrub(d.localPosition.dx, w, janela) : _solta(),
                    onDoubleTapDown: (d) => _aproxima(d.localPosition.dx, w, janela, cheio),
                    onDoubleTap: () {},
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ExcludeSemantics(
                              child: SizedBox(
                                height: widget.height,
                                child: SsTweenInView(
                                  end: 1,
                                  duration: const Duration(milliseconds: 900),
                                  builder: (_, t, _) => CustomPaint(
                                    size: Size(w, widget.height),
                                    painter: _TimePainter(
                                      series: widget.series,
                                      cores: cores,
                                      ocultas: _ocultas,
                                      modo: _modo,
                                      eixos: eixos,
                                      from: janela.$1,
                                      to: janela.$2,
                                      ticks: fmt.ticks(janela.$1, janela.$2, maxTicks: math.max(2, (w / 72).floor())),
                                      t: t,
                                      cursor: cur,
                                      fmt: fmt,
                                      guide: c.line,
                                      plot: c.field,
                                      surface: c.surface,
                                      axis: AppTheme.number(
                                        context,
                                        size: SsDensity.of(context).font(AppType.micro),
                                        color: c.muted,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            for (var i = 0; i < widget.bands.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: SsStateBandRow(
                                  row: widget.bands[i],
                                  from: janela.$1,
                                  to: janela.$2,
                                  colors: bandCores,
                                  fmt: fmt,
                                  labelOnTop: true,
                                  barHeight: 16,
                                  index: i,
                                ),
                              ),
                            const SizedBox(height: 6),
                            SsTimeAxis(
                              from: janela.$1,
                              to: janela.$2,
                              locale: widget.locale,
                              utcOffset: widget.utcOffset,
                            ),
                          ],
                        ),
                        if (cur != null)
                          Positioned(
                            left: xCur - .5,
                            top: _top - 6,
                            bottom: 24,
                            width: 1,
                            child: IgnorePointer(child: ColoredBox(color: c.ink.withValues(alpha: .4))),
                          ),
                        if (cur != null)
                          Positioned(
                            top: 0,
                            left: xCur > w * .55 ? null : xCur + 12,
                            right: xCur > w * .55 ? w - xCur + 12 : null,
                            width: 190,
                            child: IgnorePointer(child: _balao(context, fmt, cur, cores, bandCores)),
                          ),
                      ],
                    ),
                  ),
                  // Fora do GestureDetector: o toque no botão não espera o toque duplo.
                  if (_zoom != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: _BotaoVerTudo(label: widget.resetZoomLabel ?? _s.showAll, onTap: () => _verTudo(cheio)),
                    ),
                ],
              );
            },
          ),
          if (widget.legend && (widget.series.length > 1 || widget.legendAlways)) ...[
            const SizedBox(height: 10),
            _legenda(context, cores, fmt),
          ],
        ],
      ),
    );
  }

  /// Valor da série na legenda: no cursor, se houver; senão, a última leitura.
  double? _valorLegenda(SsTimeSeries s) {
    final cur = _cursor;
    if (cur != null) return s.valueAt(cur, _modo(s));
    for (var k = s.points.length - 1; k >= 0; k--) {
      if (s.points[k].v != null) return s.points[k].v;
    }
    return null;
  }

  Widget _legenda(BuildContext context, List<Color> cores, SsTimeFormat fmt) {
    final c = SsColors.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < widget.series.length; i++)
          Builder(
            builder: (context) {
              final s = widget.series[i];
              final on = !_ocultas.contains(i);
              return Semantics(
                button: true,
                toggled: on,
                label: widget.showValues
                    ? '${s.name}, ${fmt.value(_valorLegenda(s), unit: s.unit, decimals: s.decimals)}'
                    : (s.unit == null ? s.name : '${s.name}, ${s.unit}'),
                excludeSemantics: true,
                child: SsPressable(
                  onTap: () => setState(() => on ? _ocultas.add(i) : _ocultas.remove(i)),
                  child: AnimatedContainer(
                    duration: reduceMotion(context) ? Duration.zero : SsMotion.fast,
                    padding: _respiro(context, 8, 5, 10, 5),
                    decoration: BoxDecoration(
                      color: on ? c.field : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: on ? Colors.transparent : c.line),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: reduceMotion(context) ? Duration.zero : SsMotion.fast,
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: on ? cores[i] : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(color: cores[i], width: 1.5),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          s.name,
                          style: TextStyle(
                            fontSize: SsDensity.of(context).font(AppType.meta),
                            fontWeight: FontWeight.w600,
                            color: on ? c.ink : c.muted,
                            decoration: on ? null : TextDecoration.lineThrough,
                          ),
                        ),
                        if (widget.showValues) ...[
                          const SizedBox(width: 6),
                          Text(
                            fmt.value(_valorLegenda(s), unit: s.unit, decimals: s.decimals),
                            style: AppTheme.number(
                              context,
                              size: SsDensity.of(context).font(AppType.meta),
                              color: on ? c.ink : c.muted,
                            ),
                          ),
                        ] else if (s.unit != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            s.unit!,
                            style: TextStyle(fontSize: SsDensity.of(context).font(AppType.label), color: c.muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _balao(BuildContext context, SsTimeFormat fmt, DateTime t, List<Color> cores, Map<String, Color> bandCores) {
    final c = SsColors.of(context);
    Widget linha(Widget marca, String nome, String valor) => Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          marca,
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: SsDensity.of(context).font(AppType.label), color: c.ink2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            valor,
            style: AppTheme.number(context, size: SsDensity.of(context).font(AppType.meta), color: c.ink),
          ),
        ],
      ),
    );
    return Container(
      padding: _respiro(context, 10, 7, 10, 8),
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
            fmt.when(t),
            style: AppTheme.number(
              context,
              size: SsDensity.of(context).font(AppType.label),
              weight: FontWeight.w700,
              color: c.ink,
            ),
          ),
          for (var i = 0; i < widget.series.length; i++)
            if (!_ocultas.contains(i))
              linha(
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: cores[i], shape: BoxShape.circle),
                ),
                widget.series[i].name,
                fmt.value(
                  widget.series[i].valueAt(t, _modo(widget.series[i])),
                  unit: widget.series[i].unit,
                  decimals: widget.series[i].decimals,
                ),
              ),
          for (final r in widget.bands)
            Builder(
              builder: (context) {
                SsStateSegment? s;
                for (final x in r.segments) {
                  if (!t.isBefore(x.from) && t.isBefore(x.to)) s = x;
                }
                return linha(
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: s == null ? c.line : bandCores[s.state],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  r.label,
                  s?.text ?? '—',
                );
              },
            ),
        ],
      ),
    );
  }
}

class _BotaoVerTudo extends StatelessWidget {
  const _BotaoVerTudo({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Semantics(
      button: true,
      child: SsPop(
        active: true,
        child: SsPressable(
          onTap: onTap,
          child: Container(
            padding: _respiro(context, 8, 5, 10, 5),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: c.line),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.zoom_out_map_rounded, size: 14, color: c.accentText),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: SsDensity.of(context).font(AppType.label),
                    fontWeight: FontWeight.w700,
                    color: c.accentText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimePainter extends CustomPainter {
  _TimePainter({
    required this.series,
    required this.cores,
    required this.ocultas,
    required this.modo,
    required this.eixos,
    required this.from,
    required this.to,
    required this.ticks,
    required this.t,
    required this.cursor,
    required this.fmt,
    required this.guide,
    required this.plot,
    required this.surface,
    required this.axis,
  });

  final List<SsTimeSeries> series;
  final List<Color> cores;
  final Set<int> ocultas;
  final SsTimeChartMode Function(SsTimeSeries) modo;
  final List<(_Eixo, List<int>)> eixos;
  final DateTime from, to;
  final List<SsTimeTick> ticks;
  final double t;
  final DateTime? cursor;
  final SsTimeFormat fmt;
  final Color guide, plot, surface;
  final TextStyle axis;

  void _texto(Canvas canvas, String s, Offset at, {bool direita = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: axis),
      textDirection: TextDirection.ltr,
    )..layout();
    final o = at - Offset(direita ? tp.width : 0, 0);
    // Pílula da cor do fundo: o rótulo não se mistura com as linhas.
    canvas.drawRRect(
      RRect.fromRectAndRadius((o & tp.size).inflate(2.5), const Radius.circular(5)),
      Paint()..color = plot.withValues(alpha: .85),
    );
    tp.paint(canvas, o);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final span = to.difference(from).inMilliseconds.toDouble();
    final h = size.height - _top - _bottom;
    double x(DateTime d) => size.width * d.difference(from).inMilliseconds / span;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(AppRadius.thumb)),
      Paint()..color = plot,
    );
    final fina = Paint()
      ..color = guide
      ..strokeWidth = 1;
    // Guias verticais nas marcas do tempo (tracejadas).
    for (final k in ticks) {
      final gx = x(k.at);
      for (var y = 0.0; y < size.height; y += 7) {
        canvas.drawLine(Offset(gx, y), Offset(gx, math.min(y + 3, size.height)), fina);
      }
    }
    // Guias horizontais do 1º eixo.
    if (eixos.isEmpty) return;
    final e0 = eixos.first.$1;
    double yDe(_Eixo e, double v) => _top + h * (1 - (v - e.lo) / (e.hi - e.lo));
    for (var v = e0.lo; v <= e0.hi + e0.step / 2; v += e0.step) {
      canvas.drawLine(Offset(0, yDe(e0, v)), Offset(size.width, yDe(e0, v)), fina);
    }

    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width * t, size.height), const Radius.circular(AppRadius.thumb)),
    );
    for (final (e, idx) in eixos) {
      for (final i in idx) {
        final s = series[i];
        final m = modo(s);
        final cor = cores[i];
        // Trechos sem buraco; inclui a leitura antes e a depois da janela.
        final trechos = <List<Offset>>[];
        final faixa = <(double, double, double)>[]; // x, yMin, yMax
        var atual = <Offset>[];
        for (var k = 0; k < s.points.length; k++) {
          final p = s.points[k];
          if (p.t.isBefore(from) && k + 1 < s.points.length && s.points[k + 1].t.isBefore(from)) continue;
          if (p.t.isAfter(to) && k > 0 && s.points[k - 1].t.isAfter(to)) break;
          if (p.v == null) {
            if (atual.isNotEmpty) trechos.add(atual);
            atual = <Offset>[];
            continue;
          }
          final o = Offset(x(p.t), yDe(e, p.v!));
          if (m == SsTimeChartMode.step && atual.isNotEmpty) atual.add(Offset(o.dx, atual.last.dy));
          atual.add(o);
          if (p.min != null && p.max != null) faixa.add((o.dx, yDe(e, p.min!), yDe(e, p.max!)));
        }
        if (atual.isNotEmpty) trechos.add(atual);
        // Degrau: a última leitura vale até o fim da janela (ou até agora).
        if (m == SsTimeChartMode.step && trechos.isNotEmpty && s.points.last.v != null) {
          final ult = trechos.last.last;
          final fim = math.min(size.width, x(DateTime.now()));
          if (fim > ult.dx) trechos.last.add(Offset(fim, ult.dy));
        }
        if (faixa.length > 1) {
          final p = Path()..moveTo(faixa.first.$1, faixa.first.$3);
          for (final f in faixa.skip(1)) {
            p.lineTo(f.$1, f.$3);
          }
          for (final f in faixa.reversed) {
            p.lineTo(f.$1, f.$2);
          }
          canvas.drawPath(p..close(), Paint()..color = cor.withValues(alpha: .12));
        }
        for (final pts in trechos) {
          if (pts.length == 1) {
            canvas.drawCircle(pts.first, 2.5, Paint()..color = cor);
            continue;
          }
          final linha = Path()..moveTo(pts.first.dx, pts.first.dy);
          for (final o in pts.skip(1)) {
            linha.lineTo(o.dx, o.dy);
          }
          if (m == SsTimeChartMode.area) {
            final area = Path.from(linha)
              ..lineTo(pts.last.dx, _top + h)
              ..lineTo(pts.first.dx, _top + h)
              ..close();
            canvas.drawPath(
              area,
              Paint()
                ..shader = LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [cor.withValues(alpha: .26), cor.withValues(alpha: 0)],
                ).createShader(Rect.fromLTWH(0, _top, size.width, h)),
            );
          }
          canvas.drawPath(
            linha,
            Paint()
              ..color = cor
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round,
          );
        }
      }
    }
    canvas.restore();

    // Rótulos dos eixos Y por cima: 1º à esquerda, 2º à direita.
    for (var a = 0; a < eixos.length; a++) {
      final e = eixos[a].$1;
      final direita = a == 1;
      for (var v = e.lo; v <= e.hi + e.step / 2; v += e.step) {
        final y = yDe(e, v);
        if (y < _top - 1 || y > _top + h + 1) continue;
        final txt = fmt.value(v, unit: e.unit, decimals: e.step < 1 ? (e.step < .1 ? 2 : 1) : 0);
        _texto(canvas, txt, Offset(direita ? size.width - 5 : 5, math.max(2, y - 13)), direita: direita);
      }
    }

    // Cursor: um ponto em cada série visível.
    final cur = cursor;
    if (cur != null) {
      for (final (e, idx) in eixos) {
        for (final i in idx) {
          final v = series[i].valueAt(cur, modo(series[i]));
          if (v == null) continue;
          final p = Offset(x(cur), yDe(e, v));
          canvas.drawCircle(p, 5.5, Paint()..color = surface);
          canvas.drawCircle(p, 4, Paint()..color = cores[i]);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_TimePainter old) => true;
}

/// Respiro na escala da densidade (0,75 / 1 / 1,2).
EdgeInsets _respiro(BuildContext context, double l, double t, double r, double b) {
  final d = SsDensity.of(context);
  return EdgeInsets.fromLTRB(d.space(l), d.space(t), d.space(r), d.space(b));
}
