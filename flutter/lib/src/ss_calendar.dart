import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'format.dart';
import 'motion.dart';

const _meses = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

/// "Outubro 2026".
String ssMonthName(DateTime m) => '${_meses[m.month - 1]} ${m.year}';

DateTime _mes(DateTime d) => DateTime(d.year, d.month);
DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);

/// ‹ Outubro 2026 ›: troca de mês. O título desliza na direção da troca;
/// tocar nele volta ao mês atual. [min]/[max] travam as setas.
class SsMonthSwitcher extends StatefulWidget {
  const SsMonthSwitcher({super.key, required this.month, required this.onChanged, this.min, this.max});

  final DateTime month;
  final ValueChanged<DateTime> onChanged;
  final DateTime? min;
  final DateTime? max;

  @override
  State<SsMonthSwitcher> createState() => _SsMonthSwitcherState();
}

class _SsMonthSwitcherState extends State<SsMonthSwitcher> {
  // 1 = foi para a frente (o novo entra pela direita).
  int _dir = 1;

  @override
  void didUpdateWidget(SsMonthSwitcher old) {
    super.didUpdateWidget(old);
    final a = _mes(old.month), b = _mes(widget.month);
    if (a != b) _dir = b.isAfter(a) ? 1 : -1;
  }

  bool _pode(DateTime m) =>
      (widget.min == null || !m.isBefore(_mes(widget.min!))) && (widget.max == null || !m.isAfter(_mes(widget.max!)));

  void _ir(DateTime m) {
    HapticFeedback.selectionClick();
    widget.onChanged(m);
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final m = _mes(widget.month);
    final antes = DateTime(m.year, m.month - 1);
    final depois = DateTime(m.year, m.month + 1);
    final hoje = _mes(DateTime.now());
    final atual = ValueKey(m);
    return Row(
      children: [
        IconButton(
          tooltip: 'Mês anterior',
          onPressed: _pode(antes) ? () => _ir(antes) : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Semantics(
            button: m != hoje,
            liveRegion: true,
            hint: m != hoje ? 'Voltar ao mês atual' : null,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: m != hoje && _pode(hoje) ? () => _ir(hoje) : null,
              child: SizedBox(
                height: 48,
                child: ClipRect(
                  child: AnimatedSwitcher(
                    duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) {
                      // O que entra vem do lado da troca; o que sai vai para o outro.
                      final entra = child.key == atual;
                      final de = Offset((entra ? .5 : -.5) * _dir, 0);
                      return FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween(begin: de, end: Offset.zero).animate(anim),
                          child: child,
                        ),
                      );
                    },
                    child: Center(
                      key: atual,
                      child: Text(
                        ssMonthName(m),
                        style: TextStyle(fontSize: AppType.md, fontWeight: FontWeight.w800, color: c.ink),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Próximo mês',
          onPressed: _pode(depois) ? () => _ir(depois) : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

/// Dias que a grade de [month] mostra: do domingo antes do dia 1 ao sábado
/// depois do último (5 ou 6 semanas).
List<DateTime> ssMonthDays(DateTime month) {
  final first = DateTime(month.year, month.month);
  final ultimo = DateTime(month.year, month.month + 1, 0).day;
  final antes = first.weekday % 7; // domingo = 0
  final total = ((antes + ultimo) / 7).ceil() * 7;
  return [for (var i = 0; i < total; i++) DateTime(month.year, month.month, 1 - antes + i)];
}

/// Grade do mês (7 colunas, semana começa no domingo). Hoje tem anel, o
/// selecionado tem o fundo da marca, [markers] viram pontinhos embaixo do dia
/// (até 3) e os dias de fora do mês ficam apagados. Arrastar para o lado
/// chama [onMonthChanged] com o mês vizinho.
class SsMonthGrid extends StatelessWidget {
  const SsMonthGrid({
    super.key,
    required this.month,
    required this.onSelect,
    this.selected,
    this.markers = const {},
    this.today,
    this.onMonthChanged,
  });

  final DateTime month;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelect;

  /// Dia → cores dos pontinhos (uma por tipo de evento).
  final Map<DateTime, List<Color>> markers;

  /// Padrão: hoje do relógio.
  final DateTime? today;
  final ValueChanged<DateTime>? onMonthChanged;

  static const _semana = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final m = _mes(month);
    final hoje = _dia(today ?? DateTime.now());
    final sel = selected == null ? null : _dia(selected!);
    final marcas = {for (final e in markers.entries) _dia(e.key): e.value};
    final dias = ssMonthDays(m);

    Widget dia(DateTime d) {
      final fora = d.month != m.month;
      final eSel = d == sel;
      final eHoje = d == hoje;
      final pontos = marcas[d] ?? const <Color>[];
      final cor = fora
          ? c.muted2
          : eSel
          ? Colors.white
          : c.ink;
      final cell = SizedBox(
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 180),
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: eSel ? c.accent : Colors.transparent,
                border: eHoje && !eSel ? Border.all(color: c.accent, width: 1.6) : null,
              ),
              child: Text(
                '${d.day}',
                style: AppTheme.number(
                  context,
                  size: AppType.set,
                  weight: eSel || eHoje ? FontWeight.w700 : FontWeight.w500,
                  color: cor,
                ),
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final p in pontos.take(3))
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(color: fora ? p.withValues(alpha: .4) : p, shape: BoxShape.circle),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
      if (fora) return ExcludeSemantics(child: cell);
      return Semantics(
        button: true,
        selected: eSel,
        label: '${date(d)}${eHoje ? ', hoje' : ''}${pontos.isEmpty ? '' : ', ${pontos.length} marcador(es)'}',
        excludeSemantics: true,
        child: InkResponse(
          radius: 22,
          onTap: () {
            HapticFeedback.selectionClick();
            onSelect(d);
          },
          child: cell,
        ),
      );
    }

    return GestureDetector(
      onHorizontalDragEnd: onMonthChanged == null
          ? null
          : (d) {
              final v = d.primaryVelocity ?? 0;
              if (v.abs() < 200) return;
              HapticFeedback.selectionClick();
              onMonthChanged!(DateTime(m.year, m.month + (v < 0 ? 1 : -1)));
            },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              for (final s in _semana)
                Expanded(
                  child: ExcludeSemantics(
                    child: Text(
                      s,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: AppType.micro, fontWeight: FontWeight.w700, color: c.muted),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (var s = 0; s < dias.length; s += 7)
            Row(children: [for (final d in dias.sublist(s, s + 7)) Expanded(child: dia(d))]),
        ],
      ),
    );
  }
}

/// Nível 0 a 4 de [v] num calendário de calor cujo maior valor é [max].
int ssHeatLevel(double? v, double max) {
  if (v == null || v <= 0 || max <= 0) return 0;
  return (v / max * 4).ceil().clamp(1, 4);
}

Color _nivel(SsColors c, int n) => n == 0 ? c.field : c.accent.withValues(alpha: const <double>[0, .28, .5, .74, 1][n]);

/// Constância (estilo contribuições do GitHub): uma coluna por semana, de
/// domingo a sábado, em 5 níveis da cor da marca. As últimas [weeks] semanas
/// até [end] (hoje), ou só o mês [month] se for dado. Tocar num dia mostra o
/// valor dele embaixo ([format]). [legend] põe a [SsHeatLegend].
class SsHeatCalendar extends StatefulWidget {
  const SsHeatCalendar({
    super.key,
    required this.values,
    this.weeks = 18,
    this.month,
    this.end,
    this.format,
    this.legend = true,
  });

  final Map<DateTime, double> values;
  final int weeks;
  final DateTime? month;
  final DateTime? end;

  /// Texto do valor do dia tocado (padrão: [qty]).
  final String Function(double value)? format;
  final bool legend;

  @override
  State<SsHeatCalendar> createState() => _SsHeatCalendarState();
}

class _SsHeatCalendarState extends State<SsHeatCalendar> {
  DateTime? _sel;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final vals = {for (final e in widget.values.entries) _dia(e.key): e.value};
    final max = vals.values.fold<double>(0, math.max);
    final m = widget.month;
    final fim = m != null ? DateTime(m.year, m.month + 1, 0) : _dia(widget.end ?? DateTime.now());
    final ini = m != null ? DateTime(m.year, m.month) : DateTime(fim.year, fim.month, fim.day - widget.weeks * 7 + 1);
    // Colunas do domingo da semana de [ini] ao sábado da semana de [fim].
    final dom = DateTime(ini.year, ini.month, ini.day - ini.weekday % 7);
    final cols = ((DateTime(fim.year, fim.month, fim.day).difference(dom).inHours / 24).round() ~/ 7) + 1;
    final fmt = widget.format ?? (double v) => qty(v);
    const gap = 3.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final lado = math.min(m != null ? 32.0 : 18.0, (box.maxWidth - gap * (cols - 1)) / cols);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var k = 0; k < cols; k++)
                  Padding(
                    padding: EdgeInsets.only(right: k == cols - 1 ? 0 : gap),
                    child: Column(
                      children: [
                        for (var r = 0; r < 7; r++)
                          Padding(
                            padding: EdgeInsets.only(bottom: r == 6 ? 0 : gap),
                            child: _celula(
                              c,
                              DateTime(dom.year, dom.month, dom.day + k * 7 + r),
                              ini,
                              fim,
                              vals,
                              max,
                              lado,
                              fmt,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  _sel == null ? '' : '${date(_sel)}: ${vals[_sel] == null ? 'nada' : fmt(vals[_sel]!)}',
                  style: AppTheme.number(context, size: AppType.meta, color: c.ink2),
                ),
              ),
            ),
            if (widget.legend) const SsHeatLegend(),
          ],
        ),
      ],
    );
  }

  Widget _celula(
    SsColors c,
    DateTime d,
    DateTime ini,
    DateTime fim,
    Map<DateTime, double> vals,
    double max,
    double lado,
    String Function(double) fmt,
  ) {
    if (d.isBefore(ini) || d.isAfter(fim)) return SizedBox.square(dimension: lado);
    final v = vals[d];
    final eSel = d == _sel;
    return Semantics(
      button: true,
      selected: eSel,
      label: '${date(d)}: ${v == null ? 'nada' : fmt(v)}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _sel = eSel ? null : d);
        },
        child: Container(
          width: lado,
          height: lado,
          decoration: BoxDecoration(
            color: _nivel(c, ssHeatLevel(v, max)),
            borderRadius: BorderRadius.circular(lado / 4),
            border: eSel ? Border.all(color: c.ink, width: 1.5) : null,
          ),
        ),
      ),
    );
  }
}

/// Legenda do [SsHeatCalendar]: "menos ▢▢▢▢▢ mais".
class SsHeatLegend extends StatelessWidget {
  const SsHeatLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = TextStyle(fontSize: AppType.micro, color: c.muted, fontWeight: FontWeight.w600);
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('menos', style: s),
          for (var n = 0; n < 5; n++)
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(left: 3),
              decoration: BoxDecoration(color: _nivel(c, n), borderRadius: BorderRadius.circular(2.5)),
            ),
          const SizedBox(width: 4),
          Text('mais', style: s),
        ],
      ),
    );
  }
}
