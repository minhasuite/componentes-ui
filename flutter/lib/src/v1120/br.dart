// v1.12.0 "Kit Brasil": as contas brasileiras, puras e sem rede (par do ComponentesUi::Br do Ruby e do ss_br.js
// do Stimulus; a mesma conta nos três, conferida pelos exemplos de docs/v1120/exemplos.json).
//
// Nada aqui chama serviço externo: buscar CEP ou CNPJ é do app (callback `onLookup`).

/// Tipo da chave Pix.
enum SsPixKeyType {
  cpf,
  cnpj,
  phone,
  email,

  /// Chave aleatória (EVP, um UUID).
  random;

  /// O nome nos três lados ("cpf", "random"...).
  String get key => name;
}

/// Tipo do boleto: bancário (47 dígitos) ou de arrecadação (48: concessionária, tributo, carnê).
enum SsBoletoKind {
  bank,
  collection;

  String get key => this == bank ? 'bank' : 'collection';
}

/// As contas: CPF, CNPJ (o alfanumérico de 2026 também), CEP, telefone, e-mail, chave Pix e os módulos 10 e 11.
abstract final class SsBr {
  /// DDDs em uso (Anatel).
  static const ddds = {
    '11', '12', '13', '14', '15', '16', '17', '18', '19', '21', '22', '24', '27', '28', '31', '32', '33', '34', //
    '35', '37', '38', '41', '42', '43', '44', '45', '46', '47', '48', '49', '51', '53', '54', '55', '61', '62',
    '63', '64', '65', '66', '67', '68', '69', '71', '73', '74', '75', '77', '79', '81', '82', '83', '84', '85',
    '86', '87', '88', '89', '91', '92', '93', '94', '95', '96', '97', '98', '99',
  };

  /// Código IBGE da UF → sigla (os 2 primeiros dígitos da chave da NF-e).
  static const ufs = {
    '11': 'RO', '12': 'AC', '13': 'AM', '14': 'RR', '15': 'PA', '16': 'AP', '17': 'TO', '21': 'MA', '22': 'PI', //
    '23': 'CE', '24': 'RN', '25': 'PB', '26': 'PE', '27': 'AL', '28': 'SE', '29': 'BA', '31': 'MG', '32': 'ES',
    '33': 'RJ', '35': 'SP', '41': 'PR', '42': 'SC', '43': 'RS', '50': 'MS', '51': 'MT', '52': 'GO', '53': 'DF',
  };

  /// Modelo do documento na chave de acesso.
  static const models = {'55': 'NF-e', '65': 'NFC-e', '57': 'CT-e', '58': 'MDF-e', '59': 'CF-e SAT', '67': 'CT-e OS'};

  /// Segmento do boleto de arrecadação (2º dígito).
  static const segments = {
    '1': 'prefeitura',
    '2': 'saneamento',
    '3': 'energia',
    '4': 'telecom',
    '5': 'governo',
    '6': 'carne',
    '7': 'transito',
    '9': 'banco',
  };

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s.]{2,}$');
  static final _evp = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

  /// Só os dígitos.
  static String digits(String? text) => (text ?? '').replaceAll(RegExp(r'\D'), '');

  /// Só letras e dígitos, em maiúscula (o CNPJ alfanumérico).
  static String alnum(String? text) => (text ?? '').toUpperCase().replaceAll(RegExp('[^0-9A-Z]'), '');

  // ── CPF e CNPJ ─────────────────────────────────────────────────────

  static bool cpfValid(String? text) {
    final d = digits(text);
    if (d.length != 11 || RegExp(r'^(\d)\1{10}$').hasMatch(d)) return false;
    int dv(int n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        s += int.parse(d[i]) * (n + 1 - i);
      }
      final r = s % 11;
      return r < 2 ? 0 : 11 - r;
    }

    return dv(9) == int.parse(d[9]) && dv(10) == int.parse(d[10]);
  }

  /// Os 2 dígitos do CNPJ para as 12 primeiras posições (números ou letras; valor = código ASCII − 48).
  static String cnpjDv(String base12) {
    int calc(List<int> v) {
      var s = 0;
      for (var i = 0; i < v.length; i++) {
        s += v[v.length - 1 - i] * (2 + i % 8);
      }
      final r = s % 11;
      return r < 2 ? 0 : 11 - r;
    }

    final v = [for (final c in base12.codeUnits) c - 48];
    final d1 = calc(v);
    return '$d1${calc([...v, d1])}';
  }

  static bool cnpjValid(String? text) {
    final s = alnum(text);
    if (!RegExp(r'^[0-9A-Z]{12}\d{2}$').hasMatch(s) || RegExp(r'^(.)\1{13}$').hasMatch(s)) return false;
    return cnpjDv(s.substring(0, 12)) == s.substring(12);
  }

  /// "cpf" (até 11), "cnpj" (12 ou mais, ou com letra) ou nulo (vazio).
  static String? documentKind(String? text) {
    final s = alnum(text);
    if (s.isEmpty) return null;
    return s.length > 11 || RegExp('[A-Z]').hasMatch(s) ? 'cnpj' : 'cpf';
  }

  static bool documentValid(String? text) => documentKind(text) == 'cnpj' ? cnpjValid(text) : cpfValid(text);

  // ── Formatadores ───────────────────────────────────────────────────

  static String _join(String raw, List<int> cuts, List<String> seps) {
    final b = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final k = cuts.indexOf(i);
      if (k >= 0) b.write(seps[k]);
      b.write(raw[i]);
    }
    return b.toString();
  }

  static String _cap(String s, int n) => s.length > n ? s.substring(0, n) : s;

  /// 000.000.000-00 (parcial quando incompleto).
  static String formatCpf(String? text) => _join(_cap(digits(text), 11), const [3, 6, 9], const ['.', '.', '-']);

  /// 00.000.000/0000-00 (o alfanumérico com as letras em maiúscula).
  static String formatCnpj(String? text) {
    var s = _cap(alnum(text), 14);
    if (s.length > 12) s = s.substring(0, 12) + s.substring(12).replaceAll(RegExp(r'\D'), '');
    return _join(s, const [2, 5, 8, 12], const ['.', '.', '/', '-']);
  }

  static String formatDocument(String? text) => documentKind(text) == 'cnpj' ? formatCnpj(text) : formatCpf(text);

  /// 00000-000.
  static String formatCep(String? text) => _join(_cap(digits(text), 8), const [5], const ['-']);

  /// (11) 98765-4321 ou (11) 3456-7890; com o 55 na frente, +55 (11) 98765-4321.
  static String formatPhone(String? text) {
    var raw = digits(text);
    final ddi = raw.length > 11 && raw.startsWith('55');
    if (ddi) raw = raw.substring(2);
    raw = _cap(raw, 11);
    if (raw.isEmpty) return '';
    final out = raw.length <= 2
        ? '($raw'
        : '(${raw.substring(0, 2)}) ${_join(raw.substring(2), [raw.length <= 10 ? 4 : 5], const ['-'])}';
    return ddi ? '+55 $out' : out;
  }

  /// Linha digitável: 00000.00000 00000.000000 00000.000000 0 00000000000000 (47) ou
  /// 00000000000-0 00000000000-0 00000000000-0 00000000000-0 (48). 44 dígitos (código de barras) viram a linha.
  static String formatBoleto(String? text) {
    var d = digits(text);
    if (d.length == 44) d = boletoLineFromBarcode(d) ?? d;
    if (d.startsWith('8')) {
      d = _cap(d, 48);
      return [
        for (var i = 0; i < d.length; i += 12)
          i + 12 <= d.length ? '${d.substring(i, i + 11)}-${d[i + 11]}' : d.substring(i),
      ].join(' ');
    }
    return _join(_cap(d, 47), const [5, 10, 15, 21, 26, 32, 33], const ['.', ' ', '.', ' ', '.', ' ', ' ']);
  }

  /// Chave de acesso em 11 blocos de 4.
  static String formatNfeKey(String? text) {
    final d = _cap(digits(text), 44);
    return [for (var i = 0; i < d.length; i += 4) d.substring(i, i + 4 > d.length ? d.length : i + 4)].join(' ');
  }

  // ── CEP, telefone, e-mail e chave Pix ──────────────────────────────

  static bool cepValid(String? text) {
    final d = digits(text);
    return d.length == 8 && d != '00000000';
  }

  /// Os 10 ou 11 dígitos nacionais (sem o 55), ou nulo se não for telefone brasileiro.
  static String? phoneNational(String? text) {
    final raw = (text ?? '').trim();
    var d = digits(raw);
    if ((raw.startsWith('+55') || raw.startsWith('55')) && d.length > 11) d = d.substring(2);
    if (d.length == 12 && d.startsWith('0')) d = d.substring(1);
    if ((d.length != 10 && d.length != 11) || !ddds.contains(d.substring(0, 2))) return null;
    if (d.length == 11 && d[2] != '9') return null;
    if (d.length == 10 && !RegExp('[2-5]').hasMatch(d[2])) return null;
    return d;
  }

  static bool phoneValid(String? text) => phoneNational(text) != null;

  /// +5511987654321 (o formato da chave Pix de telefone).
  static String? phoneE164(String? text) {
    final n = phoneNational(text);
    return n == null ? null : '+55$n';
  }

  static bool emailValid(String? text) => _email.hasMatch((text ?? '').trim());

  static bool evpValid(String? text) => _evp.hasMatch((text ?? '').trim());

  /// O tipo da chave Pix, ou nulo. 11 dígitos com CPF válido é CPF; senão, celular com DDD é telefone. "+55…" é
  /// sempre telefone.
  static SsPixKeyType? pixKeyType(String? text) {
    final t = (text ?? '').trim();
    if (t.isEmpty) return null;
    if (t.contains('@')) return SsPixKeyType.email;
    if (_evp.hasMatch(t)) return SsPixKeyType.random;
    if (t.startsWith('+')) return phoneValid(t) ? SsPixKeyType.phone : null;
    if (RegExp(r'[^\d.\-/\s()A-Za-z]').hasMatch(t)) return null;
    final a = alnum(t), d = digits(t);
    if (RegExp('[A-Za-z]').hasMatch(t)) return cnpjValid(t) ? SsPixKeyType.cnpj : null;
    if (d.length == 11 && cpfValid(d)) return SsPixKeyType.cpf;
    if (d.length == 14 && cnpjValid(d)) return SsPixKeyType.cnpj;
    if (phoneValid(t) && a == d) return SsPixKeyType.phone;
    return null;
  }

  /// A chave como vai no Pix: CPF/CNPJ só dígitos (letras em maiúscula), +55… no telefone, e-mail e aleatória
  /// em minúscula.
  static String? pixKeyNormalize(String? text, [SsPixKeyType? type]) => switch (type ?? pixKeyType(text)) {
    SsPixKeyType.cpf => digits(text),
    SsPixKeyType.cnpj => alnum(text),
    SsPixKeyType.phone => phoneE164(text),
    SsPixKeyType.email || SsPixKeyType.random => (text ?? '').trim().toLowerCase(),
    null => null,
  };

  /// A chave para mostrar (CPF e CNPJ com pontuação, telefone com DDD).
  static String pixKeyDisplay(String? text, [SsPixKeyType? type]) => switch (type ?? pixKeyType(text)) {
    SsPixKeyType.cpf => formatCpf(text),
    SsPixKeyType.cnpj => formatCnpj(text),
    SsPixKeyType.phone => formatPhone(phoneE164(text)),
    _ => (text ?? '').trim(),
  };

  // ── Módulos 10 e 11 ────────────────────────────────────────────────

  static int mod10(String num) {
    var s = 0;
    for (var i = 0; i < num.length; i++) {
      var p = int.parse(num[num.length - 1 - i]) * (i.isEven ? 2 : 1);
      if (p > 9) p -= 9;
      s += p;
    }
    return (10 - s % 10) % 10;
  }

  static int _mod11Sum(String num) {
    var s = 0;
    for (var i = 0; i < num.length; i++) {
      s += int.parse(num[num.length - 1 - i]) * (2 + i % 8);
    }
    return s;
  }

  /// DV geral do boleto bancário: 0, 10 e 11 viram 1.
  static int mod11Bank(String num) {
    final dv = 11 - _mod11Sum(num) % 11;
    return dv == 0 || dv == 10 || dv == 11 ? 1 : dv;
  }

  /// DV do boleto de arrecadação e da chave de acesso: resto 0 ou 1 vira 0.
  static int mod11Dv(String num) {
    final r = _mod11Sum(num) % 11;
    return r < 2 ? 0 : 11 - r;
  }

  // ── Boleto (o código de barras) ────────────────────────────────────

  /// Código de barras (44) → linha digitável (47 ou 48); nulo se não tiver 44 dígitos.
  static String? boletoLineFromBarcode(String? code) {
    final c = digits(code);
    if (c.length != 44) return null;
    if (c.startsWith('8')) {
      final m = c[2] == '6' || c[2] == '7' ? mod10 : mod11Dv;
      return [for (var i = 0; i < 44; i += 11) '${c.substring(i, i + 11)}${m(c.substring(i, i + 11))}'].join();
    }
    final f1 = c.substring(0, 4) + c.substring(19, 24);
    final f2 = c.substring(24, 34);
    final f3 = c.substring(34, 44);
    return '$f1${mod10(f1)}$f2${mod10(f2)}$f3${mod10(f3)}${c[4]}${c.substring(5, 19)}';
  }

  /// "123.45" (o campo 54 do BR Code) → 12345; nulo se fora do formato.
  static int? amountCents(String? text) {
    final m = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch((text ?? '').trim());
    if (m == null) return null;
    return int.parse(m.group(1)!) * 100 + int.parse((m.group(2) ?? '').padRight(2, '0'));
  }

  static const _accents = {'ÁÀÂÃÄ': 'A', 'ÉÈÊË': 'E', 'ÍÌÎÏ': 'I', 'ÓÒÔÕÖ': 'O', 'ÚÙÛÜ': 'U', 'Ç': 'C', 'Ñ': 'N'};

  /// Sem acento ("São Paulo" → "Sao Paulo").
  static String ascii(String text) {
    final b = StringBuffer();
    for (final ch in text.split('')) {
      var out = ch;
      for (final e in _accents.entries) {
        if (e.key.contains(ch)) out = e.value;
        if (e.key.toLowerCase().contains(ch)) out = e.value.toLowerCase();
      }
      b.write(out);
    }
    return b.toString();
  }
}

/// Um boleto lido da linha digitável (47 ou 48 dígitos) ou do código de barras (44).
class SsBoleto {
  const SsBoleto({
    required this.kind,
    required this.line,
    required this.barcode,
    required this.valid,
    this.amountCents,
    this.dueDate,
    this.bank,
    this.segment,
    this.errors = const [],
  });

  final SsBoletoKind kind;

  /// A linha digitável, só os dígitos.
  final String line;

  /// O código de barras (44 dígitos).
  final String barcode;

  /// Os dígitos verificadores conferem.
  final bool valid;

  /// Nulo quando o boleto não traz valor (zero).
  final int? amountCents;

  /// Vencimento pelo fator (só no bancário; nulo com fator 0000).
  final DateTime? dueDate;

  /// Código do banco (bancário: "341").
  final String? bank;

  /// Segmento da arrecadação ("energia", "governo"...).
  final String? segment;

  /// "field_dv", "general_dv", "value_id".
  final List<String> errors;

  /// A linha formatada.
  String get display => SsBr.formatBoleto(line);

  static final _baseOld = DateTime.utc(1997, 10, 7);

  /// Fator 1000 de novo em 22/02/2025 (Febraban, depois do 9999 de 21/02/2025).
  static final _baseNew = DateTime.utc(2025, 2, 22);

  /// Data do fator de vencimento, no ciclo mais perto de [today]; 0 = sem vencimento.
  static DateTime? due(String fator, {DateTime? today}) {
    final f = int.tryParse(fator) ?? 0;
    if (f == 0) return null;
    final old = _baseOld.add(Duration(days: f));
    if (f < 1000) return old;
    final t = today ?? DateTime.now();
    final ref = DateTime.utc(t.year, t.month, t.day);
    final novo = _baseNew.add(Duration(days: f - 1000));
    return novo.difference(ref).inDays.abs() < old.difference(ref).inDays.abs() ? novo : old;
  }

  /// O fator de vencimento de uma data (o inverso de [due]).
  static int factor(DateTime date) {
    final d = DateTime.utc(date.year, date.month, date.day);
    final f = d.difference(_baseOld).inDays;
    return f > 9999 ? d.difference(_baseNew).inDays + 1000 : f;
  }

  /// Linha digitável (com ou sem pontuação) ou código de barras → boleto; nulo se o tamanho não é de boleto.
  static SsBoleto? parse(String? text, {DateTime? today}) {
    String? d = SsBr.digits(text);
    if (d.length == 44) d = SsBr.boletoLineFromBarcode(d);
    if (d == null) return null;
    if (d.length == 48 && d.startsWith('8')) return _collection(d);
    if (d.length == 47) return _bank(d, today);
    return null;
  }

  static SsBoleto _bank(String d, DateTime? today) {
    final errors = <String>[];
    final fields = [(d.substring(0, 9), d[9]), (d.substring(10, 20), d[20]), (d.substring(21, 31), d[31])];
    if (!fields.every((f) => '${SsBr.mod10(f.$1)}' == f.$2)) errors.add('field_dv');
    final barcode =
        d.substring(0, 4) + d[32] + d.substring(33, 47) + d.substring(4, 9) + d.substring(10, 20) + d.substring(21, 31);
    if ('${SsBr.mod11Bank(barcode.substring(0, 4) + barcode.substring(5))}' != barcode[4]) errors.add('general_dv');
    final valor = int.parse(d.substring(37, 47));
    return SsBoleto(
      kind: SsBoletoKind.bank,
      line: d,
      barcode: barcode,
      valid: errors.isEmpty,
      amountCents: valor == 0 ? null : valor,
      dueDate: due(d.substring(33, 37), today: today),
      bank: d.substring(0, 3),
      errors: errors,
    );
  }

  static SsBoleto _collection(String d) {
    final errors = <String>[];
    final blocks = [for (var i = 0; i < 48; i += 12) d.substring(i, i + 12)];
    final barcode = blocks.map((b) => b.substring(0, 11)).join();
    final id = barcode[2];
    final m = id == '6' || id == '7' ? SsBr.mod10 : SsBr.mod11Dv;
    if (!'6789'.contains(id)) errors.add('value_id');
    if (!blocks.every((b) => '${m(b.substring(0, 11))}' == b[11])) errors.add('field_dv');
    if ('${m(barcode.substring(0, 3) + barcode.substring(4))}' != barcode[3]) errors.add('general_dv');
    final valor = id == '6' || id == '8' ? int.parse(barcode.substring(4, 15)) : 0;
    return SsBoleto(
      kind: SsBoletoKind.collection,
      line: d,
      barcode: barcode,
      valid: errors.isEmpty,
      amountCents: valor == 0 ? null : valor,
      segment: SsBr.segments[barcode[1]],
      errors: errors,
    );
  }
}

/// A chave de acesso da NF-e, NFC-e ou CT-e (44 dígitos).
class SsNfeKey {
  const SsNfeKey({
    required this.key,
    required this.valid,
    required this.ufCode,
    required this.year,
    required this.month,
    required this.cnpj,
    required this.model,
    required this.series,
    required this.number,
    required this.emission,
    required this.code,
    required this.dv,
    this.uf,
    this.modelName,
  });

  /// Os 44 dígitos.
  final String key;

  /// DV, UF, mês e modelo conferem.
  final bool valid;
  final String? uf;
  final String ufCode;
  final int year;
  final int month;

  /// CNPJ do emitente (14).
  final String cnpj;

  /// "55" (NF-e), "65" (NFC-e)...
  final String model;
  final String? modelName;
  final int series;
  final int number;
  final String emission;
  final String code;
  final String dv;

  /// Em 11 blocos de 4.
  String get display => SsBr.formatNfeKey(key);

  /// 44 dígitos (com ou sem espaço) → a chave; nulo se não tiver 44 dígitos.
  static SsNfeKey? parse(String? text) {
    final k = SsBr.digits(text);
    if (k.length != 44) return null;
    final uf = SsBr.ufs[k.substring(0, 2)];
    final mes = int.parse(k.substring(4, 6));
    final model = k.substring(20, 22);
    final ok =
        uf != null &&
        mes >= 1 &&
        mes <= 12 &&
        '${SsBr.mod11Dv(k.substring(0, 43))}' == k[43] &&
        SsBr.models.containsKey(model);
    return SsNfeKey(
      key: k,
      valid: ok,
      uf: uf,
      ufCode: k.substring(0, 2),
      year: 2000 + int.parse(k.substring(2, 4)),
      month: mes,
      cnpj: k.substring(6, 20),
      model: model,
      modelName: SsBr.models[model],
      series: int.parse(k.substring(22, 25)),
      number: int.parse(k.substring(25, 34)),
      emission: k[34],
      code: k.substring(35, 43),
      dv: k[43],
    );
  }

  /// O DV (44º dígito) para 43 dígitos.
  static int dvFor(String key43) => SsBr.mod11Dv(SsBr.digits(key43).substring(0, 43));
}

/// Um Pix copia e cola (BR Code EMV) lido.
class SsPixCode {
  const SsPixCode({
    required this.payload,
    required this.valid,
    this.key,
    this.keyType,
    this.name,
    this.city,
    this.amountCents,
    this.txid,
    this.description,
    this.url,
    this.dynamic = false,
    this.errors = const [],
  });

  final String payload;

  /// CRC confere e tem a chave (ou a URL do QR dinâmico).
  final bool valid;
  final String? key;
  final SsPixKeyType? keyType;

  /// Nome do recebedor (campo 59).
  final String? name;
  final String? city;

  /// Nulo: quem paga digita o valor.
  final int? amountCents;
  final String? txid;
  final String? description;
  final String? url;

  /// QR dinâmico (01 = 12 ou URL no 26.25).
  final bool dynamic;

  /// "crc", "key", "format".
  final List<String> errors;

  /// CRC16-CCITT (0x1021, início 0xFFFF), 4 dígitos hexadecimais em maiúscula.
  static String crc16(String text) {
    var crc = 0xFFFF;
    for (final b in _utf8(text)) {
      crc ^= b << 8;
      for (var i = 0; i < 8; i++) {
        crc = ((crc & 0x8000) != 0 ? (crc << 1) ^ 0x1021 : crc << 1) & 0xFFFF;
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  static List<int> _utf8(String s) {
    final out = <int>[];
    for (final r in s.runes) {
      if (r < 0x80) {
        out.add(r);
      } else if (r < 0x800) {
        out.addAll([0xC0 | (r >> 6), 0x80 | (r & 0x3F)]);
      } else if (r < 0x10000) {
        out.addAll([0xE0 | (r >> 12), 0x80 | ((r >> 6) & 0x3F), 0x80 | (r & 0x3F)]);
      } else {
        out.addAll([0xF0 | (r >> 18), 0x80 | ((r >> 12) & 0x3F), 0x80 | ((r >> 6) & 0x3F), 0x80 | (r & 0x3F)]);
      }
    }
    return out;
  }

  static Map<String, String>? _fields(String text) {
    final out = <String, String>{};
    var i = 0;
    while (i < text.length) {
      if (i + 4 > text.length) return null;
      final id = text.substring(i, i + 2), len = text.substring(i + 2, i + 4);
      if (!RegExp(r'^\d\d$').hasMatch(id) || !RegExp(r'^\d\d$').hasMatch(len)) return null;
      final n = int.parse(len);
      if (i + 4 + n > text.length) return null;
      out[id] = text.substring(i + 4, i + 4 + n);
      i += 4 + n;
    }
    return out;
  }

  /// "000201…6304ABCD" → o Pix; nulo se não for BR Code do Pix.
  static SsPixCode? parse(String? text) {
    final t = (text ?? '').trim().replaceAll(RegExp(r'[\r\n]'), '');
    if (!t.startsWith('000201') || !t.toLowerCase().contains('br.gov.bcb.pix')) return null;
    final f = _fields(t);
    if (f == null) return SsPixCode(payload: t, valid: false, errors: const ['format']);
    final mai = _fields(f['26'] ?? '') ?? const {};
    final extra = _fields(f['62'] ?? '') ?? const {};
    final errors = <String>[];
    if ((f['63'] ?? '').toUpperCase() != crc16(t.substring(0, t.length - 4))) errors.add('crc');
    final key = mai['01'];
    if (key == null && mai['25'] == null) errors.add('key');
    return SsPixCode(
      payload: t,
      valid: errors.isEmpty,
      key: key,
      keyType: key == null ? null : SsBr.pixKeyType(key),
      name: f['59'],
      city: f['60'],
      amountCents: f['54'] == null ? null : SsBr.amountCents(f['54']),
      txid: extra['05'],
      description: mai['02'],
      url: mai['25'],
      dynamic: f['01'] == '12' || mai['25'] != null,
      errors: errors,
    );
  }

  /// Monta o copia e cola estático (exemplo, teste e o Pix de balcão sem PSP): chave, nome (até 25), cidade (até
  /// 15), valor em centavos (nulo = livre) e o txid ("***" = sem). O mesmo `Br.pix_build` do Ruby.
  static String build({
    required String key,
    required String name,
    required String city,
    int? amountCents,
    String txid = '***',
    String? description,
  }) {
    String tlv(String id, String v) => '$id${v.length.toString().padLeft(2, '0')}$v';
    String plain(String s, int n) {
      final p = SsBr.ascii(s).toUpperCase().replaceAll(RegExp('[^A-Z0-9 ]'), '');
      return p.length > n ? p.substring(0, n) : p;
    }

    String cut(String s, int n) => s.length > n ? s.substring(0, n) : s;
    final mai =
        tlv('00', 'br.gov.bcb.pix') + tlv('01', key) + (description == null ? '' : tlv('02', cut(description, 40)));
    final valor = amountCents == null
        ? ''
        : tlv('54', '${amountCents ~/ 100}.${(amountCents % 100).toString().padLeft(2, '0')}');
    final body =
        '${tlv('00', '01')}${tlv('26', mai)}${tlv('52', '0000')}${tlv('53', '986')}$valor${tlv('58', 'BR')}'
        '${tlv('59', plain(name, 25))}${tlv('60', plain(city, 15))}${tlv('62', tlv('05', cut(txid, 25)))}6304';
    return body + crc16(body);
  }
}
