// v1.13.0 "confiança na IA e suíte": o valor falado em centavos (par do ComponentesUi::Speech.parse_amount da gem e
// do ssParseAmount do ss_speech.js). O reconhecimento de voz é do app (o plugin dele); o pacote só converte o texto
// que o reconhecedor devolveu. Os mesmos casos (docs/v1130/fala.json) passam nos três lados.

/// O texto falado → centavos.
///
/// ```dart
/// SsSpeech.parseAmountPtBr('cento e vinte e três e cinquenta'); // 12350
/// SsSpeech.parseAmountPtBr('mil e duzentos reais');             // 120000
/// SsSpeech.parseAmountPtBr('doze e meio');                      // 1250
/// SsSpeech.parseAmountPtBr('R\$ 12,50');                         // 1250
/// ```
///
/// As regras, na ordem em que a pessoa fala:
/// - os números por extenso montam os reais em grupos de até 999 ("cento e vinte e três"), com "mil", "milhão" e
///   "bilhão" multiplicando o grupo de antes (sempre em ordem decrescente; "mil mil" não vale);
/// - a palavra que não cabe mais no grupo (uma dezena depois de "três", "cinquenta" depois de "doze" ou de "cem")
///   começa os centavos: "doze e cinquenta" é 12,50 e "cem e cinquenta" é 100,50;
/// - "real"/"reais" (e "conto"/"contos") fecham os reais: o que vem depois são centavos ("doze reais e cinco" é
///   12,05);
/// - "centavo"/"centavos" no fim de um número de mil ou mais separa a dezena final como centavos ("dois mil e
///   quinhentos e noventa centavos" é 2.500,90); abaixo de mil, conta os centavos ao pé da letra ("noventa e nove
///   centavos" é 0,99; "cento e vinte e três centavos" é 1,23);
/// - "e meio" é 50 centavos ("doze e meio" é 12,50), menos depois de "mil"/"milhão", onde é metade dele ("um milhão
///   e meio" é 1.500.000,00);
/// - "vírgula" separa os centavos como na escrita ("doze vírgula cinco" é 12,50; "vírgula zero cinco" é 0,05);
/// - números escritos com algarismos também valem, soltos ou misturados ("R\$ 1.234,56", "12,5", "2 mil e 500",
///   "1,5 mil", "12 reais e 50 centavos"); vírgula decimal, ponto de milhar (e "12.50", com 2 casas, é decimal);
/// - "menos" no começo deixa negativo; acentos, maiúsculas, "R\$", "de" e palavras que não são número não contam.
///
/// Devolve `null` quando não há número ou a frase não fecha ("mil mil", centavos acima de 99, "1,234").
abstract final class SsSpeech {
  /// O texto falado em português (do Brasil ou de Portugal) → centavos, ou `null`.
  static int? parseAmountPtBr(String? text) => _Parser(text ?? '').run();

  /// As palavras de número que o parser entende (para quem monta a gramática do reconhecedor).
  static final Set<String> words = {
    ..._units.keys,
    ..._teens.keys,
    ..._tens.keys,
    ..._hundreds.keys,
    'cem',
    ..._scales.keys,
  };
}

const _units = {
  'zero': 0, 'um': 1, 'uma': 1, 'dois': 2, 'duas': 2, 'tres': 3, 'quatro': 4, 'cinco': 5, 'seis': 6, 'sete': 7, //
  'oito': 8, 'nove': 9,
};
const _teens = {
  'dez': 10, 'onze': 11, 'doze': 12, 'treze': 13, 'catorze': 14, 'quatorze': 14, 'quinze': 15, 'dezesseis': 16, //
  'dezasseis': 16, 'dezessete': 17, 'dezassete': 17, 'dezoito': 18, 'dezenove': 19, 'dezanove': 19,
};
const _tens = {
  'vinte': 20, 'trinta': 30, 'quarenta': 40, 'cinquenta': 50, 'cincoenta': 50, 'sessenta': 60, 'setenta': 70, //
  'oitenta': 80, 'noventa': 90,
};
const _hundreds = {
  'cento': 100, 'duzentos': 200, 'duzentas': 200, 'trezentos': 300, 'trezentas': 300, 'quatrocentos': 400, //
  'quatrocentas': 400, 'quinhentos': 500, 'quinhentas': 500, 'seiscentos': 600, 'seiscentas': 600, //
  'setecentos': 700, 'setecentas': 700, 'oitocentos': 800, 'oitocentas': 800, 'novecentos': 900, 'novecentas': 900,
};
const _scales = {'mil': 1000, 'milhao': 1000000, 'milhoes': 1000000, 'bilhao': 1000000000, 'bilhoes': 1000000000};
const _reais = {'real', 'reais', 'conto', 'contos'};
const _centavos = {'centavo', 'centavos'};

/// Um grupo de até 999: [value] e o nível mais baixo já preenchido (3 = centena, 2 = dezena, 1 = unidade; 4 = vazio,
/// 0 = fechado por um número com algarismos).
class _Group {
  int value = 0;
  int minLevel = 4;
  bool get empty => minLevel == 4;

  /// Soma a palavra se ela cabe (nível abaixo do último); [closes] fecha até a unidade (dez a dezenove, "cem").
  bool add(int v, int level, {bool closes = false}) {
    if (level >= minLevel) return false;
    value += v;
    minLevel = closes ? 1 : level;
    return true;
  }

  void set(int v) {
    value = v;
    minLevel = 0;
  }

  void reset() {
    value = 0;
    minLevel = 4;
  }
}

enum _Mode { reais, cents, decimal, end }

class _Parser {
  _Parser(this.text);
  final String text;

  var _mode = _Mode.reais;
  var _total = 0; // reais das escalas já fechadas
  final _group = _Group(); // o grupo de reais em montagem
  final _cents = _Group();
  int? _lastScale;
  var _lastWasScale = false;
  var _seen = false; // algum número
  var _neg = false;
  int? _rawCents; // centavos contados ao pé da letra ("noventa centavos", "meio real")
  int? _numericFrac; // a fração de um "1,5" que uma escala depois multiplica
  final _decimal = <(int, int)>[]; // depois de "vírgula": (valor, nível)
  var _decimalDigits = '';
  var _decimalOnlyDigits = true;

  static String _fold(String s) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const to = 'aaaaaeeeeiiiiooooouuuuc';
    final b = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      final i = from.indexOf(ch);
      b.write(i < 0 ? ch : to[i]);
    }
    return b.toString();
  }

  /// "1.234,56" → (1234, 56); "12,5" → (12, 50); "1.500" → (1500, null); "12.50" → (12, 50); inválido → null.
  static (int, int?)? _numeric(String t) {
    int? frac(String f) => f.isEmpty || f.length > 2 ? null : int.parse(f.padRight(2, '0'));
    if (t.contains(',')) {
      final i = t.lastIndexOf(',');
      final whole = t.substring(0, i), f = t.substring(i + 1);
      if (whole.contains(',')) return null;
      final w = _thousands(whole.isEmpty ? '0' : whole);
      final c = frac(f);
      return w == null || c == null ? null : (w, c);
    }
    if (t.contains('.')) {
      final parts = t.split('.');
      if (parts.length == 2 && parts[1].length <= 2) {
        final c = frac(parts[1]);
        return c == null ? null : (int.parse(parts[0]), c);
      }
      final w = _thousands(t);
      return w == null ? null : (w, null);
    }
    return (int.parse(t), null);
  }

  static int? _thousands(String t) {
    final parts = t.split('.');
    if (parts.skip(1).any((p) => p.length != 3)) return null;
    return int.tryParse(parts.join());
  }

  int? run() {
    final folded = _fold(text).replaceAll(r'r$', ' ').replaceAll('−', '-');
    final tokens = [for (final m in RegExp(r'\d+(?:[.,]\d+)*|[a-z]+|-').allMatches(folded)) m.group(0)!];
    for (final t in tokens) {
      if (!_step(t)) return null;
    }
    return _finish();
  }

  /// `false` = a frase não fecha.
  bool _step(String t) {
    if (t == 'menos' || t == '-') {
      if (!_seen) _neg = true;
      return true;
    }
    if (RegExp(r'^\d').hasMatch(t)) return _number(t);
    if (_units.containsKey(t)) return _word(_units[t]!, 1);
    if (_teens.containsKey(t)) return _word(_teens[t]!, 2, closes: true);
    if (_tens.containsKey(t)) return _word(_tens[t]!, 2);
    if (_hundreds.containsKey(t)) return _word(_hundreds[t]!, 3);
    if (t == 'cem') return _word(100, 3, closes: true);
    if (_scales.containsKey(t)) return _scale(_scales[t]!);
    if (_reais.contains(t)) return _markReais();
    if (_centavos.contains(t)) return _markCentavos();
    if (t == 'meio' || t == 'meia') return _meio();
    if (t == 'virgula') {
      if (_mode != _Mode.reais || !_seen) return false;
      _mode = _Mode.decimal;
      return true;
    }
    return true; // "e", "de", "rs" e o que não é número
  }

  bool _word(int v, int level, {bool closes = false}) {
    switch (_mode) {
      case _Mode.reais:
        _seen = true;
        if (_group.add(v, level, closes: closes)) {
          _lastWasScale = false;
          return true;
        }
        if (_group.empty) return false;
        _mode = _Mode.cents;
        return _cents.add(v, level, closes: closes);
      case _Mode.cents:
        return _cents.add(v, level, closes: closes);
      case _Mode.decimal:
        if (level != 1) _decimalOnlyDigits = false;
        _decimal.add((v, closes ? 2 : level));
        _decimalDigits += '$v';
        return true;
      case _Mode.end:
        return false;
    }
  }

  bool _number(String t) {
    final n = _numeric(t);
    if (n == null) return false;
    final (whole, frac) = n;
    switch (_mode) {
      case _Mode.reais:
        _seen = true;
        if (_group.empty) {
          _group.set(whole);
          _lastWasScale = false;
          if (frac != null) {
            _cents.set(frac);
            _numericFrac = frac;
          }
          return true;
        }
        if (frac != null || whole > 99 || !_cents.empty) return false;
        _mode = _Mode.cents;
        _cents.set(whole);
        return true;
      case _Mode.cents:
        if (frac != null || whole > 99 || !_cents.empty) return false;
        _cents.set(whole);
        return true;
      case _Mode.decimal:
        if (frac != null) return false;
        _decimalDigits += t;
        _decimal.add((whole, whole < 10 ? 1 : 2));
        return true;
      case _Mode.end:
        return false;
    }
  }

  bool _scale(int scale) {
    if (_mode != _Mode.reais) return false;
    if (_lastScale != null && scale >= _lastScale!) return false;
    final mult = _group.empty ? 1 : _group.value;
    _total += mult * scale;
    if (_numericFrac != null) {
      _total += _numericFrac! * scale ~/ 100;
      _numericFrac = null;
      _cents.reset();
    }
    _group.reset();
    _lastScale = scale;
    _lastWasScale = true;
    _seen = true;
    return true;
  }

  bool _markReais() {
    if (!_seen) return true;
    switch (_mode) {
      case _Mode.reais:
        _mode = _Mode.cents;
        _numericFrac = null;
        return true;
      case _Mode.decimal:
        _closeDecimal();
        _mode = _Mode.end;
        return true;
      case _Mode.cents:
        // "R$ 12,50 reais": a fração do número já fechou os centavos.
        return _numericFrac != null || _cents.empty;
      case _Mode.end:
        return true;
    }
  }

  bool _markCentavos() {
    if (!_seen) return true;
    switch (_mode) {
      case _Mode.cents:
        _mode = _Mode.end;
        return true;
      case _Mode.reais:
        if (_numericFrac != null) return false;
        if (_total > 0) {
          // "dois mil e quinhentos e noventa centavos": a dezena final são os centavos.
          final c = _group.value % 100;
          _group.value -= c;
          _cents.set(c);
        } else {
          _rawCents = _group.value;
          _group.reset();
        }
        _mode = _Mode.end;
        return true;
      case _Mode.decimal:
      case _Mode.end:
        return false;
    }
  }

  bool _meio() {
    switch (_mode) {
      case _Mode.reais:
        if (!_seen) {
          _rawCents = 50;
          _seen = true;
        } else if (_lastWasScale && _group.empty) {
          _total += _lastScale! ~/ 2;
        } else {
          if (!_cents.empty) return false;
          _cents.set(50);
        }
        _mode = _Mode.end;
        return true;
      case _Mode.cents:
        if (!_cents.empty) return false;
        _cents.set(50);
        _mode = _Mode.end;
        return true;
      case _Mode.decimal:
      case _Mode.end:
        return false;
    }
  }

  bool _closeDecimal() {
    if (_decimal.isEmpty) return true;
    if (_decimalOnlyDigits) {
      final d = '${_decimalDigits}00'.substring(0, 2);
      _cents.set(int.parse(d));
    } else {
      final g = _Group();
      for (final (v, level) in _decimal) {
        if (!g.add(v, level, closes: level == 2 && v < 20 && v >= 10)) return false;
      }
      if (g.value > 99) return false;
      _cents.set(g.value);
    }
    _decimal.clear();
    return true;
  }

  int? _finish() {
    if (!_seen) return null;
    if (_mode == _Mode.decimal && !_closeDecimal()) return null;
    if (_cents.value > 99) return null;
    final reais = _total + _group.value;
    final cents = reais * 100 + _cents.value + (_rawCents ?? 0);
    return _neg ? -cents : cents;
  }
}
