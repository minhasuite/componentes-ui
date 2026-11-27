// v1.14.0 "interface e animação": este período × o anterior no mesmo gráfico. Par do Ss::PeriodCompareComponent.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';
import '../density.dart';
import '../format.dart';
import '../ss_card.dart';
import '../ss_controls.dart';
import '../ss_line_chart.dart';
import '../ss_odometer.dart';
import '../ss_stat.dart';
import '../ss_strings.dart';
import '../v12/cards.dart';
import '../v16/chart_legend.dart';
import 'strings.dart';

/// Este período × o anterior: o total deste período (o número rola ao trocar, [SsOdometer]), a diferença em
/// destaque ([SsDelta], verde quando o sentido é bom: [higherIsBetter]), e as duas séries no mesmo
/// [SsLineChart]: a deste período cheia na cor da marca e a do anterior como linha fantasma (tracejada, apagada).
///
/// Com [periods] (até 4: "Semana", "Mês", "Ano"), um [SsSegmented] em cima troca o período ([onPeriodChanged]);
/// os dados novos deslizam do valor antigo ao novo (a troca animada do gráfico, v1.9) e o total rola.
/// Arrastando o dedo no gráfico, o número de cima passa a ser o do ponto (e a diferença, a daquele ponto contra o
/// mesmo ponto do anterior); [onScrub] avisa o índice para o resto da tela acompanhar.
///
/// `SsPeriodCompare(title: 'Gastos', labels: dias, current: novembro, previous: outubro, format: (v) => money(...))`
class SsPeriodCompare extends StatefulWidget {
  const SsPeriodCompare({
    super.key,
    required this.labels,
    required this.current,
    required this.previous,
    this.title,
    this.currentLabel,
    this.previousLabel,
    this.format,
    this.higherIsBetter = true,
    this.currentTotal,
    this.previousTotal,
    this.periods = const [],
    this.period = 0,
    this.onPeriodChanged,
    this.onScrub,
    this.height = 160,
    this.card = true,
  }) : assert(periods.length == 0 || periods.length >= 2);

  /// Um por ponto ("01/11"); o anterior usa o mesmo eixo (dia 1 com dia 1).
  final List<String> labels;
  final List<double> current;
  final List<double> previous;
  final String? title;

  /// Padrão: [SsInterfaceStrings.periodCurrent] e [SsInterfaceStrings.periodPrevious].
  final String? currentLabel;
  final String? previousLabel;

  /// Texto de um valor (padrão: [qty]).
  final String Function(double value)? format;

  /// Subir é bom (receita, vendas); falso para despesa, atraso.
  final bool higherIsBetter;

  /// Totais prontos (média, último valor); padrão: a soma de cada série.
  final double? currentTotal;
  final double? previousTotal;

  /// Nomes dos períodos para o seletor (vazio: sem seletor).
  final List<String> periods;
  final int period;
  final ValueChanged<int>? onPeriodChanged;
  final ValueChanged<int?>? onScrub;
  final double height;

  /// Dentro de um [SsCard] (padrão); falso para pôr no card do app.
  final bool card;

  /// A diferença em porcentagem de [previous] para [current] (nula sem base).
  static double? change(double current, double previous) =>
      previous == 0 ? null : (current - previous) / previous.abs() * 100;

  @override
  State<SsPeriodCompare> createState() => _SsPeriodCompareState();
}

class _SsPeriodCompareState extends State<SsPeriodCompare> {
  int? _sel;

  double _soma(List<double> v) => v.fold(0.0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final t = SsInterfaceStrings.of(context);
    final formats = SsFormats.of(context);
    String fmt(double v) => widget.format?.call(v) ?? qty(v, formats);
    final sel = _sel;
    final agora = sel != null && sel < widget.current.length
        ? widget.current[sel]
        : widget.currentTotal ?? _soma(widget.current);
    final antes = sel != null
        ? (sel < widget.previous.length ? widget.previous[sel] : 0.0)
        : widget.previousTotal ?? _soma(widget.previous);
    final pct = SsPeriodCompare.change(agora, antes);
    final nomeAgora = widget.currentLabel ?? t.periodCurrent;
    final nomeAntes = widget.previousLabel ?? t.periodPrevious;
    final pctTexto = pct == null ? null : '${pct.abs().toStringAsFixed(pct.abs() < 10 ? 1 : 0).replaceAll('.', ',')}%';
    final delta = pct == null || pctTexto == null
        ? null
        : (pct.abs() < .05
              ? SsDelta.neutral(pctTexto)
              : SsDelta(pctTexto, up: pct > 0, good: (pct > 0) == widget.higherIsBetter));
    final resumo = SsInterfaceStrings.fill(t.periodSummary, {'current': fmt(agora), 'previous': fmt(antes)});

    final corpo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title != null || widget.periods.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                if (widget.title != null) SsCardHeader(title: widget.title!),
                if (widget.periods.isNotEmpty)
                  Semantics(
                    label: t.periodChoose,
                    child: SsSegmented<int>(
                      segments: [for (var i = 0; i < widget.periods.length; i++) (i, widget.periods[i])],
                      value: widget.period,
                      onChanged: (i) {
                        setState(() => _sel = null);
                        widget.onPeriodChanged?.call(i);
                      },
                    ),
                  ),
              ],
            ),
          ),
        // O número e a diferença, lidos juntos ("R$ 4.210 neste período, R$ 3.880 no anterior, 8,5% a mais").
        MergeSemantics(
          child: Semantics(
            liveRegion: sel != null,
            label: resumo,
            child: ExcludeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: SsOdometer(fmt(agora), size: AppType.statNum),
                    ),
                  ),
                  if (delta != null) ...[
                    const SizedBox(width: 8),
                    Padding(padding: const EdgeInsets.only(bottom: 4), child: delta),
                  ],
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 12),
          child: Text(
            sel != null && sel < widget.labels.length
                ? '${widget.labels[sel]} · ${t.periodVs}'
                : '${fmt(antes)} · ${nomeAntes.toLowerCase()}',
            maxLines: 2,
            style: TextStyle(fontSize: AppType.meta, color: c.muted),
          ),
        ),
        SsLineChart(
          labels: widget.labels,
          height: widget.height,
          format: fmt,
          series: [
            SsSeries(widget.current, name: nomeAgora, color: c.accent),
            // A linha fantasma: o anterior, tracejado e apagado, por baixo da leitura.
            SsSeries(widget.previous, name: nomeAntes, color: c.muted, dashed: true),
          ],
          onScrub: (i) {
            setState(() => _sel = i);
            widget.onScrub?.call(i);
          },
        ),
        const SizedBox(height: 8),
        SsChartLegend(
          items: [
            SsLegendItem(nomeAgora, c.accent, line: true),
            SsLegendItem(nomeAntes, c.muted, line: true, dashed: true),
          ],
        ),
      ],
    );
    if (!widget.card) return corpo;
    return SsCard(padding: EdgeInsets.all(math.max(d.cardPad, 12)), child: corpo);
  }
}
