import 'ss_strings.dart';

/// Formatação sem depender do `intl`: dinheiro em centavos (padrão da API:
/// `*_cents` inteiros), quantidades e datas. Sem [SsFormats]/[SsStrings], sai
/// em pt-BR com real; nos widgets, passe `SsFormats.of(context)` e
/// `SsStrings.of(context)`.
String money(int? cents, [SsFormats? formats]) => (formats ?? SsFormats.brl).money(cents);

/// "12,50" → 1250. Aceita "R$ 1.234,56", "12.5", "12". Nulo se não der.
int? parseMoney(String text, [SsFormats? formats]) => (formats ?? SsFormats.brl).parseMoney(text);

/// Centavos → texto para o campo de edição ("12,50").
String moneyField(int? cents, [SsFormats? formats]) {
  if (cents == null) return '';
  return (cents / 100).toStringAsFixed(2).replaceAll('.', (formats ?? SsFormats.brl).decimalSeparator);
}

/// Quantidade sem zeros inúteis: 2.0 → "2", 1.5 → "1,5", 0.25 → "0,25".
String qty(num? q, [SsFormats? formats]) {
  if (q == null) return '—';
  if (q == q.roundToDouble()) return q.toInt().toString();
  return q
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceAll('.', (formats ?? SsFormats.brl).decimalSeparator);
}

double? parseQty(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

String qtyUnit(num? q, String? unit, [SsFormats? formats]) =>
    unit == null || unit.isEmpty ? qty(q, formats) : '${qty(q, formats)} $unit';

String two(int n) => n.toString().padLeft(2, '0');

/// 06/10/2026 (com [strings], no formato do idioma: en 10/06/2026).
String date(DateTime? d, [SsStrings? strings]) => d == null ? '—' : (strings ?? SsStrings.pt).formatDate(d);

/// 06/10/2026 14:05
String dateTime(DateTime? d, [SsStrings? strings]) =>
    d == null ? '—' : '${date(d, strings)} ${two(d.hour)}:${two(d.minute)}';

/// "há 5 min", "há 2 h", "ontem", "06/10". Com [strings], no idioma dele
/// (`timeAgo(d, strings: SsStrings.of(context))`).
String timeAgo(DateTime? d, {DateTime? now, SsStrings? strings}) {
  if (d == null) return '';
  final s = strings ?? SsStrings.pt;
  final diff = (now ?? DateTime.now()).difference(d.toLocal());
  if (diff.inMinutes < 1) return s.agoNow;
  if (diff.inMinutes < 60) return s.agoMinutes(diff.inMinutes);
  if (diff.inHours < 24) return s.agoHours(diff.inHours);
  if (diff.inDays == 1) return s.agoYesterday;
  if (diff.inDays < 7) return s.agoDays(diff.inDays);
  return s.formatDayMonth(d.toLocal());
}
