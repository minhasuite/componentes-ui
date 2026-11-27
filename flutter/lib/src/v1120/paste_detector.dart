// v1.12.0: o que foi colado é o quê? Puro e testável (par do ComponentesUi::PasteDetector do Ruby e do ssDetect do
// ss_br.js). Os três seguem a mesma ordem e devolvem as mesmas chaves em [SsPasteMatch.fields]; os exemplos de
// docs/v1120/exemplos.json passam nos três.
import '../ss_strings.dart';
import 'br.dart';
import 'strings.dart';

/// O tipo do que foi colado.
enum SsPasteType {
  /// Pix copia e cola (BR Code EMV).
  pix('pix'),

  /// Chave Pix aleatória (EVP). CPF, CNPJ, telefone e e-mail válidos também são chave: ver [SsPasteMatch.also].
  pixKey('pix_key'),
  boleto('boleto'),

  /// Chave de acesso da NF-e/NFC-e (44 dígitos, solta ou dentro da URL do QR da NFC-e).
  nfe('nfe'),
  cpf('cpf'),
  cnpj('cnpj'),
  cep('cep'),
  phone('phone'),
  email('email'),
  url('url'),
  money('money'),
  date('date'),
  text('text');

  const SsPasteType(this.key);

  /// O nome nos três lados ("pix_key", "boleto"...).
  final String key;

  static SsPasteType? byKey(String key) => [
    for (final t in values)
      if (t.key == key) t,
  ].firstOrNull;
}

/// O resultado do [SsPasteDetector.detect].
class SsPasteMatch {
  const SsPasteMatch({
    required this.type,
    required this.text,
    required this.value,
    required this.valid,
    this.fields = const {},
    this.also = const [],
  });

  final SsPasteType type;

  /// O que foi colado (sem os espaços das pontas).
  final String text;

  /// O valor normalizado: os dígitos (boleto, chave, CPF, CNPJ, CEP), o payload do Pix, o telefone em +55…, o
  /// e-mail em minúscula, a URL com https://, os centavos ("12345") ou a data ISO ("2026-12-10").
  final String value;

  /// O dígito verificador (ou o CRC do Pix, ou a data) confere.
  final bool valid;

  /// Os detalhes, com as mesmas chaves do Ruby e do JS: amount_cents, due_date, name, city, key, key_type,
  /// txid, dynamic, kind, bank, segment, barcode, display, uf, model, model_name, cnpj, series, number, year,
  /// month, url, domain, date, length, lines. Nulos ficam de fora.
  final Map<String, Object> fields;

  /// Outros tipos que o mesmo valor também é (CPF, CNPJ, telefone e e-mail válidos: [SsPasteType.pixKey]).
  final List<SsPasteType> also;

  /// O principal e os do [also] (para procurar as ações do produto).
  List<SsPasteType> get types => [type, ...also];

  int? get amountCents => fields['amount_cents'] as int?;

  /// O vencimento do boleto ou a data colada.
  DateTime? get date {
    final s = (fields['due_date'] ?? fields['date']) as String?;
    return s == null ? null : DateTime.parse(s);
  }

  /// O texto formatado para mostrar (CPF com pontos, linha do boleto em blocos), ou o [value].
  String get display => (fields['display'] as String?) ?? value;

  @override
  String toString() => 'SsPasteMatch(${type.key}, $value, valid: $valid, $fields, also: $also)';
}

/// O detector: `SsPasteDetector.detect('23793.38128 …')` → [SsPasteMatch] (nulo para texto vazio).
abstract final class SsPasteDetector {
  static final _url = RegExp(r'^https?://[^\s/$.?#][^\s]*$', caseSensitive: false);
  static final _domain = RegExp(
    r'^(?:www\.)?[a-z0-9](?:[a-z0-9-]*[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]*[a-z0-9])?)*\.[a-z]{2,}(?:/\S*)?$',
    caseSensitive: false,
  );
  static final _dateBr = RegExp(r'^(\d{1,2})/(\d{1,2})(?:/(\d{2}|\d{4}))?$');
  static final _dateIso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
  static final _numeric = RegExp(r'^[\d\s.\-/()]+$');
  static final _money = RegExp(r'^(-)?\s*(R\$\s*)?(-)?(\d{1,3}(?:\.\d{3})+|\d+)(?:,(\d{1,2}))?$', caseSensitive: false);
  static final _cep = RegExp(r'^\d{2}\.?\d{3}-?\d{3}$');
  static final _cnpjAlnum = RegExp(
    r'^[0-9A-Z]{2}\.?[0-9A-Z]{3}\.?[0-9A-Z]{3}/?[0-9A-Z]{4}-?\d{2}$',
    caseSensitive: false,
  );

  /// O que [text] é. [today] decide o ciclo do fator de vencimento do boleto e o ano da data sem ano.
  static SsPasteMatch? detect(String? text, {DateTime? today}) {
    final t = (text ?? '').replaceAll(RegExp(r'\r\n?'), '\n').trim();
    if (t.isEmpty) return null;
    final hoje = today ?? DateTime.now();
    final s = t.replaceAll(RegExp(r'\s+'), ' ');
    return _pix(t) ??
        _urlMatch(s) ??
        _dateMatch(s, hoje) ??
        _numericMatch(s, hoje) ??
        _plus(s) ??
        _emailMatch(s) ??
        (SsBr.evpValid(s) ? _m(SsPasteType.pixKey, s, s.toLowerCase(), true, {'key_type': 'random'}) : null) ??
        (_cnpjAlnum.hasMatch(s) && RegExp('[A-Za-z]').hasMatch(s) ? _doc(SsPasteType.cnpj, s, SsBr.alnum(s)) : null) ??
        _moneyMatch(s) ??
        _domainMatch(s) ??
        _m(SsPasteType.text, t, t, true, {'length': t.runes.length, 'lines': '\n'.allMatches(t).length + 1});
  }

  static SsPasteMatch _m(
    SsPasteType type,
    String text,
    String value,
    bool valid, [
    Map<String, Object?> fields = const {},
    List<SsPasteType> also = const [],
  ]) => SsPasteMatch(
    type: type,
    text: text,
    value: value,
    valid: valid,
    fields: {
      for (final e in fields.entries)
        if (e.value != null) e.key: e.value!,
    },
    also: also,
  );

  static SsPasteMatch? _pix(String t) {
    final p = SsPixCode.parse(t.replaceAll('\n', ''));
    if (p == null) return null;
    return _m(SsPasteType.pix, t, p.payload, p.valid, {
      'amount_cents': p.amountCents,
      'name': p.name,
      'city': p.city,
      'key': p.key,
      'key_type': p.keyType?.key,
      'txid': p.txid,
      'dynamic': p.dynamic,
    });
  }

  static SsPasteMatch? _urlMatch(String t) {
    if (!_url.hasMatch(t)) return null;
    for (final k in RegExp(r'\d{44}').allMatches(t)) {
      final key = SsNfeKey.parse(k.group(0));
      if (key != null && key.valid) return _nfe(t, key, url: t);
    }
    final host = t
        .replaceFirst(RegExp('^https?://', caseSensitive: false), '')
        .split(RegExp('[/?#:]'))
        .first
        .toLowerCase()
        .replaceFirst(RegExp(r'^www\.'), '');
    return _m(SsPasteType.url, t, t, true, {'domain': host});
  }

  static SsPasteMatch _nfe(String t, SsNfeKey k, {String? url}) => _m(SsPasteType.nfe, t, k.key, k.valid, {
    'uf': k.uf,
    'model': k.model,
    'model_name': k.modelName,
    'cnpj': k.cnpj,
    'series': k.series,
    'number': k.number,
    'year': k.year,
    'month': k.month,
    'url': url,
  });

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static SsPasteMatch? _dateMatch(String t, DateTime today) {
    int y, mo, d;
    final br = _dateBr.firstMatch(t);
    final iso = _dateIso.firstMatch(t);
    if (br != null) {
      d = int.parse(br.group(1)!);
      mo = int.parse(br.group(2)!);
      final ano = br.group(3);
      y = ano == null ? today.year : int.parse(ano) + (ano.length == 2 ? 2000 : 0);
    } else if (iso != null) {
      y = int.parse(iso.group(1)!);
      mo = int.parse(iso.group(2)!);
      d = int.parse(iso.group(3)!);
    } else {
      return null;
    }
    final dt = DateTime.utc(y, mo, d);
    if (dt.year != y || dt.month != mo || dt.day != d) return null;
    final v = _iso(dt);
    return _m(SsPasteType.date, t, v, true, {'date': v});
  }

  static SsPasteMatch? _boleto(String t, SsBoleto? b) {
    if (b == null) return null;
    return _m(SsPasteType.boleto, t, b.line, b.valid, {
      'kind': b.kind.key,
      'amount_cents': b.amountCents,
      'due_date': b.dueDate == null ? null : _iso(b.dueDate!),
      'bank': b.bank,
      'segment': b.segment,
      'barcode': b.barcode,
      'display': SsBr.formatBoleto(b.line),
    });
  }

  static SsPasteMatch? _numericMatch(String t, DateTime today) {
    if (!_numeric.hasMatch(t)) return null;
    final d = SsBr.digits(t);
    switch (d.length) {
      case 47:
      case 48:
        return d.length == 47 || d.startsWith('8') ? _boleto(t, SsBoleto.parse(d, today: today)) : null;
      case 44:
        final k = SsNfeKey.parse(d)!;
        final b = SsBoleto.parse(d, today: today);
        if (k.valid) return _nfe(t, k);
        if (b != null && b.valid) return _boleto(t, b);
        if (d.startsWith('8') && b != null) return _boleto(t, b);
        return _nfe(t, k);
      case 14:
        return _doc(SsPasteType.cnpj, t, d);
      case 11:
        if (SsBr.cpfValid(d)) return _doc(SsPasteType.cpf, t, d);
        if (SsBr.phoneValid(d)) return _phone(t);
        if (t.contains('(')) return _phone(t, valid: false);
        return _doc(SsPasteType.cpf, t, d);
      case 10:
      case 12:
      case 13:
        return SsBr.phoneValid(t) || t.contains('(') ? _phone(t, valid: SsBr.phoneValid(t)) : null;
      case 8:
        return _cep.hasMatch(t) ? _m(SsPasteType.cep, t, d, SsBr.cepValid(d), {'display': SsBr.formatCep(d)}) : null;
    }
    return null;
  }

  static SsPasteMatch _doc(SsPasteType type, String t, String raw) {
    final cpf = type == SsPasteType.cpf;
    final ok = cpf ? SsBr.cpfValid(raw) : SsBr.cnpjValid(raw);
    return _m(type, t, raw, ok, {
      'display': cpf ? SsBr.formatCpf(raw) : SsBr.formatCnpj(raw),
    }, ok ? const [SsPasteType.pixKey] : const []);
  }

  static SsPasteMatch _phone(String t, {bool valid = true}) {
    final e = SsBr.phoneE164(t);
    if (e == null || !valid) return _m(SsPasteType.phone, t, SsBr.digits(t), false, {'display': t});
    return _m(SsPasteType.phone, t, e, true, {'display': SsBr.formatPhone(e)}, const [SsPasteType.pixKey]);
  }

  static SsPasteMatch? _plus(String t) {
    if (!t.startsWith('+') || !RegExp(r'^[\d\s\-()]+$').hasMatch(t.substring(1))) return null;
    return SsBr.phoneValid(t) ? _phone(t) : _m(SsPasteType.phone, t, SsBr.digits(t), false, {'display': t});
  }

  static SsPasteMatch? _emailMatch(String t) {
    if (!RegExp(r'^[^@\s]+@[^@\s]+$').hasMatch(t)) return null;
    final ok = SsBr.emailValid(t);
    return _m(SsPasteType.email, t, t.toLowerCase(), ok, const {}, ok ? const [SsPasteType.pixKey] : const []);
  }

  static SsPasteMatch? _moneyMatch(String t) {
    final x = _money.firstMatch(t);
    if (x == null || (x.group(2) == null && x.group(5) == null)) return null;
    var cents = int.parse(SsBr.digits(x.group(4))) * 100 + int.parse((x.group(5) ?? '').padRight(2, '0'));
    if (x.group(1) != null || x.group(3) != null) cents = -cents;
    return _m(SsPasteType.money, t, '$cents', true, {'amount_cents': cents});
  }

  static SsPasteMatch? _domainMatch(String t) {
    if (!_domain.hasMatch(t) || RegExp(r'^[\d.]+$').hasMatch(t)) return null;
    final host = t.split('/').first.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    return _m(SsPasteType.url, t, 'https://$t', true, {'domain': host});
  }

  /// A frase do cartão ("Isso parece um boleto de R$ 123,45 com vencimento em 10/12/2026"), no idioma de
  /// [strings]/[br] e com o dinheiro do [formats]. Inválido: "Parece um boleto, mas os números não conferem."
  static String summary(SsPasteMatch m, {SsBrStrings? br, SsStrings? strings, SsFormats? formats}) {
    final b = br ?? SsBrStrings.pt;
    final s = strings ?? SsStrings.pt;
    final f = formats ?? SsFormats.brl;
    final what = b.pasteWhat[m.type.key];
    if (!m.valid && what != null) return SsBrStrings.fill(b.pasteInvalid, {'what': what});
    final amount = m.amountCents == null ? null : f.money(m.amountCents);
    final date = m.date == null ? null : s.formatDate(m.date!);
    final key = switch (m.type) {
      SsPasteType.pix => amount == null ? 'pix_free' : 'pix',
      SsPasteType.boleto =>
        amount != null && date != null
            ? 'boleto'
            : amount != null
            ? 'boleto_amount'
            : date != null
            ? 'boleto_due'
            : 'boleto_plain',
      _ => m.type.key,
    };
    final number = m.fields['number'];
    return SsBrStrings.fill(b.pasteSummary[key] ?? m.type.key, {
      'amount': ?amount,
      'date': ?date,
      'name': (m.fields['name'] as String?) ?? '',
      'value': m.display,
      'model': (m.fields['model_name'] as String?) ?? 'NF-e',
      'uf': (m.fields['uf'] as String?) ?? '',
      'number': number is int ? f.integer(number) : '',
      'domain': (m.fields['domain'] as String?) ?? '',
      'count': '${m.fields['length'] ?? m.text.length}',
    });
  }
}
