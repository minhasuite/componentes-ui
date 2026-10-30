/// Formatação pt-BR sem depender do `intl`: dinheiro em centavos (padrão da
/// API: `*_cents` inteiros), quantidades e datas.
String money(int? cents) {
  if (cents == null) return '—';
  final neg = cents < 0;
  final abs = cents.abs();
  final reais = (abs ~/ 100).toString();
  final buf = StringBuffer();
  for (var i = 0; i < reais.length; i++) {
    if (i > 0 && (reais.length - i) % 3 == 0) buf.write('.');
    buf.write(reais[i]);
  }
  final centavos = (abs % 100).toString().padLeft(2, '0');
  return '${neg ? '-' : ''}R\$ $buf,$centavos';
}

/// "12,50" → 1250. Aceita "R$ 1.234,56", "12.5", "12". Nulo se não der.
int? parseMoney(String text) {
  var t = text.replaceAll(RegExp(r'[^0-9,.]'), '');
  if (t.isEmpty) return null;
  if (t.contains(',')) {
    t = t.replaceAll('.', '').replaceAll(',', '.');
  }
  final v = double.tryParse(t);
  return v == null ? null : (v * 100).round();
}

/// Centavos → texto para o campo de edição ("12,50").
String moneyField(int? cents) {
  if (cents == null) return '';
  return (cents / 100).toStringAsFixed(2).replaceAll('.', ',');
}

/// Quantidade sem zeros inúteis: 2.0 → "2", 1.5 → "1,5", 0.25 → "0,25".
String qty(num? q) {
  if (q == null) return '—';
  if (q == q.roundToDouble()) return q.toInt().toString();
  return q.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '').replaceAll('.', ',');
}

double? parseQty(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

String qtyUnit(num? q, String? unit) => unit == null || unit.isEmpty ? qty(q) : '${qty(q)} $unit';

String two(int n) => n.toString().padLeft(2, '0');

/// 06/10/2026
String date(DateTime? d) => d == null ? '—' : '${two(d.day)}/${two(d.month)}/${d.year}';

/// 06/10/2026 14:05
String dateTime(DateTime? d) => d == null ? '—' : '${date(d)} ${two(d.hour)}:${two(d.minute)}';

/// "há 5 min", "há 2 h", "ontem", "06/10".
String timeAgo(DateTime? d, {DateTime? now}) {
  if (d == null) return '';
  final diff = (now ?? DateTime.now()).difference(d.toLocal());
  if (diff.inMinutes < 1) return 'agora';
  if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'há ${diff.inHours} h';
  if (diff.inDays == 1) return 'ontem';
  if (diff.inDays < 7) return 'há ${diff.inDays} dias';
  final l = d.toLocal();
  return '${two(l.day)}/${two(l.month)}';
}
