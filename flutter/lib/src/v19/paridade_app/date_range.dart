// v1.9 · paridade_app: período com atalhos (par do Ss::DateRangeComponent).
import 'package:material_ui/material_ui.dart';

import '../../app_theme.dart';
import '../../density.dart';
import '../../motion.dart';
import '../../ss_controls.dart' show SsFilterChip;
import '../../ss_fields.dart' show SsFieldLabel;
import '../../ss_strings.dart';

/// Os atalhos do [SsDateRangeField] (as chaves do web: `today`, `7d`, `month`,
/// `last_month`).
enum SsDateRangeShortcut {
  today,
  last7Days,
  thisMonth,
  lastMonth;

  /// O período do atalho a partir de [today] (só o dia conta). "Este mês" é o
  /// mês inteiro, do dia 1 ao último, como no web.
  DateTimeRange rangeFrom(DateTime today) {
    final t = DateUtils.dateOnly(today);
    return switch (this) {
      SsDateRangeShortcut.today => DateTimeRange(start: t, end: t),
      SsDateRangeShortcut.last7Days => DateTimeRange(start: DateTime(t.year, t.month, t.day - 6), end: t),
      SsDateRangeShortcut.thisMonth => DateTimeRange(
        start: DateTime(t.year, t.month),
        end: DateTime(t.year, t.month + 1, 0),
      ),
      SsDateRangeShortcut.lastMonth => DateTimeRange(
        start: DateTime(t.year, t.month - 1),
        end: DateTime(t.year, t.month, 0),
      ),
    };
  }

  String label(SsStrings s) => switch (this) {
    SsDateRangeShortcut.today => s.today,
    SsDateRangeShortcut.last7Days => s.dateRange7d,
    SsDateRangeShortcut.thisMonth => s.dateRangeMonth,
    SsDateRangeShortcut.lastMonth => s.dateRangeLastMonth,
  };
}

/// O calendário de período do pacote: textos do [SsStrings], período inicial
/// preso entre [firstDate] e [lastDate] (padrão 2000–2100) e o tema do app.
/// Devolve o período (só dias) ou nulo se cancelar. Par do
/// [showSsDatePicker] para dois dias.
Future<DateTimeRange?> showSsDateRangePicker(
  BuildContext context, {
  DateTimeRange? initialRange,
  DateTime? firstDate,
  DateTime? lastDate,
  String? helpText,
}) {
  final s = SsStrings.of(context);
  final first = DateUtils.dateOnly(firstDate ?? DateTime(2000));
  final last = DateUtils.dateOnly(lastDate ?? DateTime(2100));
  DateTimeRange? inicial;
  if (initialRange != null) {
    DateTime prende(DateTime d) {
      final x = DateUtils.dateOnly(d);
      return x.isBefore(first) ? first : (x.isAfter(last) ? last : x);
    }

    inicial = DateTimeRange(start: prende(initialRange.start), end: prende(initialRange.end));
  }
  return showDateRangePicker(
    context: context,
    initialDateRange: inicial,
    firstDate: first,
    lastDate: last,
    locale: s.locale,
    helpText: helpText ?? s.dateRangeLabel,
    confirmText: s.confirm,
    cancelText: s.cancel,
    saveText: s.confirm,
  );
}

/// Período: atalhos em chips (Hoje, 7 dias, Este mês, Mês passado; o que bate
/// com o período atual fica marcado) e a faixa "De → Até" que abre o
/// calendário de período ([showSsDateRangePicker]). Par do
/// `Ss::DateRangeComponent` (o web usa dois `input type=date`).
///
/// `SsDateRangeField(value: periodo, onChanged: (p) => setState(() => periodo = p))`
class SsDateRangeField extends StatelessWidget {
  const SsDateRangeField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.shortcuts = SsDateRangeShortcut.values,
    this.firstDate,
    this.lastDate,
    this.today,
  });

  final DateTimeRange? value;
  final ValueChanged<DateTimeRange?> onChanged;

  /// Padrão: [SsStrings.dateRangeLabel] ("Período").
  final String? label;
  final List<SsDateRangeShortcut> shortcuts;
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// "Hoje" dos atalhos (teste e captura). Padrão: agora.
  final DateTime? today;

  static bool _igual(DateTimeRange? a, DateTimeRange b) =>
      a != null && DateUtils.isSameDay(a.start, b.start) && DateUtils.isSameDay(a.end, b.end);

  Future<void> _abrir(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final r = await showSsDateRangePicker(context, initialRange: value, firstDate: firstDate, lastDate: lastDate);
    if (r != null) onChanged(DateTimeRange(start: DateUtils.dateOnly(r.start), end: DateUtils.dateOnly(r.end)));
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    final hoje = today ?? DateTime.now();
    final v = value;

    Widget caixa(String rotulo, DateTime? dia) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rotulo,
            style: TextStyle(fontSize: AppType.label, fontWeight: FontWeight.w700, color: c.muted),
          ),
          const SizedBox(height: 2),
          Text(
            dia == null ? '—' : MaterialLocalizations.of(context).formatCompactDate(dia),
            style: AppTheme.number(context, size: AppType.body, color: dia == null ? c.muted : c.ink),
          ),
        ],
      ),
    );

    final faixa = Semantics(
      button: true,
      label:
          '${label ?? s.dateRangeLabel}: ${s.dateRangeFrom} ${v == null ? '—' : s.longDate(v.start)}, '
          '${s.dateRangeTo} ${v == null ? '—' : s.longDate(v.end)}',
      excludeSemantics: true,
      child: SsPressable(
        onTap: () => _abrir(context),
        child: Container(
          constraints: BoxConstraints(minHeight: d.fieldHeight + 8),
          padding: EdgeInsets.symmetric(horizontal: d.padX * .8, vertical: 8),
          decoration: BoxDecoration(
            color: c.field,
            borderRadius: BorderRadius.circular(d.radiusField),
            border: Border.all(color: c.line),
          ),
          child: Row(
            children: [
              caixa(s.dateRangeFrom, v?.start),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward_rounded, size: 18, color: c.muted),
              ),
              caixa(s.dateRangeTo, v?.end),
              Icon(Icons.calendar_month_outlined, size: d.iconSize, color: c.accentText),
            ],
          ),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SsFieldLabel(label ?? s.dateRangeLabel),
        Semantics(
          container: true,
          label: s.dateRangeShortcuts,
          child: Wrap(
            spacing: d.gap - 4,
            runSpacing: d.gap - 4,
            children: [
              for (final a in shortcuts)
                Builder(
                  builder: (context) {
                    final r = a.rangeFrom(hoje);
                    return SsFilterChip(a.label(s), selected: _igual(v, r), onTap: () => onChanged(r));
                  },
                ),
            ],
          ),
        ),
        SizedBox(height: d.gap),
        faixa,
      ],
    );
  }
}
