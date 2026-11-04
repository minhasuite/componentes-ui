// v0.10 (dados): formato de número e data pelo idioma e as marcas do eixo do
// tempo. A mesma conta do Rails (ss_time_axis.js, que usa o Intl do
// navegador): o pacote não depende do `intl`, então pt, en e es estão aqui.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Uma marca do eixo do tempo: o instante, o texto e se é "virada" (meia-noite
/// num eixo de horas, janeiro num eixo de meses), que sai em negrito.
class SsTimeTick {
  const SsTimeTick(this.at, this.label, {this.major = false});

  final DateTime at;
  final String label;
  final bool major;

  @override
  String toString() => 'SsTimeTick($at, $label${major ? ', major' : ''})';
}

/// Número e data no idioma do [locale] (pt, en ou es; outro cai no en), com
/// as mesmas saídas do `Intl` do navegador que o Rails usa:
///
/// - [number]: `1.234,5` (pt), `1,234.5` (en), `1234,5` / `12.345,6` (es).
/// - [hm]: `15:00` (pt, es), `3:00 PM` (en).
/// - [dm]: `04/11` (pt, es), `11/04` (en).
/// - [when] (balão do cursor): `04/11 15:00`.
class SsTimeFormat {
  SsTimeFormat(Locale? locale) : lang = _lang(locale);

  /// Idioma do contexto (o `Localizations` do app); [override] ganha.
  factory SsTimeFormat.of(BuildContext context, [Locale? override]) =>
      SsTimeFormat(override ?? Localizations.maybeLocaleOf(context));

  /// 'pt', 'en' ou 'es'.
  final String lang;

  static String _lang(Locale? l) {
    final c = l?.languageCode.toLowerCase() ?? 'pt';
    return const {'pt', 'en', 'es'}.contains(c) ? c : 'en';
  }

  static const _meses = {
    'pt': ['jan.', 'fev.', 'mar.', 'abr.', 'mai.', 'jun.', 'jul.', 'ago.', 'set.', 'out.', 'nov.', 'dez.'],
    'en': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
    'es': ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sept', 'oct', 'nov', 'dic'],
  };

  static const _semana = {
    'pt': ['seg.', 'ter.', 'qua.', 'qui.', 'sex.', 'sáb.', 'dom.'],
    'en': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    'es': ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'],
  };

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// Casas decimais automáticas pelo tamanho (o mesmo do Rails): ≥ 100 → 0,
  /// ≥ 10 → 1, abaixo → 2 (zeros do fim somem).
  static int autoDecimals(double v) {
    final a = v.abs();
    if (a >= 100) return 0;
    if (a >= 10) return 1;
    return 2;
  }

  /// Número com separadores do idioma. [decimals] fixa o máximo de casas
  /// (padrão: [autoDecimals]); zeros do fim somem, como no `Intl`.
  String number(double v, {int? decimals}) {
    final d = decimals ?? autoDecimals(v);
    var s = v.abs().toStringAsFixed(d);
    if (s.contains('.')) s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    final partes = s.split('.');
    final inteiro = partes[0];
    final grupo = lang == 'en' ? ',' : '.';
    final decimal = lang == 'en' ? '.' : ',';
    // O es-ES só agrupa a partir de 5 dígitos (minimumGroupingDigits 2).
    final agrupa = lang == 'es' ? inteiro.length >= 5 : inteiro.length >= 4;
    final buf = StringBuffer();
    for (var i = 0; i < inteiro.length; i++) {
      if (agrupa && i > 0 && (inteiro.length - i) % 3 == 0) buf.write(grupo);
      buf.write(inteiro[i]);
    }
    final neg = v < 0 && (double.tryParse(s) ?? 0) != 0;
    return '${neg ? '-' : ''}$buf${partes.length > 1 ? '$decimal${partes[1]}' : ''}';
  }

  /// Valor com unidade: `21,5 °C`, `48%` (o % vai colado).
  String value(double? v, {String? unit, int? decimals, String empty = '—'}) {
    if (v == null) return empty;
    final n = number(v, decimals: decimals);
    if (unit == null || unit.isEmpty) return n;
    return unit == '%' ? '$n%' : '$n $unit';
  }

  /// Hora: `15:00` ou `3:00 PM`.
  String hm(DateTime t) {
    if (lang != 'en') return '${_two(t.hour)}:${_two(t.minute)}';
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h:${_two(t.minute)} ${t.hour < 12 ? 'AM' : 'PM'}';
  }

  /// Dia e mês: `04/11` ou `11/04`.
  String dm(DateTime t) => lang == 'en' ? '${_two(t.month)}/${_two(t.day)}' : '${_two(t.day)}/${_two(t.month)}';

  /// Data completa curta: `04/11/2026` ou `11/04/2026`.
  String dmy(DateTime t) => '${dm(t)}/${t.year}';

  /// Mês abreviado: `nov.`, `Nov`, `nov`.
  String month(DateTime t) => _meses[lang]![t.month - 1];

  /// Dia da semana abreviado: `qua.`, `Wed`, `mié`.
  String weekday(DateTime t) => _semana[lang]![t.weekday - 1];

  /// Instante do balão do cursor: `04/11 15:00`.
  String when(DateTime t) => '${dm(t)} ${hm(t)}';

  /// Cabeçalho de dia do logbook fora de hoje/ontem: `qua, 04/11` (sem o
  /// ponto da abreviação, como o Rails; com o ano quando não é o de [now]).
  String day(DateTime t, {DateTime? now}) {
    final ano = now != null && now.year != t.year;
    return '${weekday(t).replaceAll('.', '')}, ${ano ? dmy(t) : dm(t)}';
  }

  /// Duração curta: `2 h 30 min`, `3 d 4 h`, `45 min` (en: `2h 30m`).
  String duration(Duration d) {
    final en = lang == 'en';
    String u(int n, String pt, String e) => en ? '$n$e' : '$n $pt';
    final min = d.inMinutes;
    if (min < 1) return u(d.inSeconds, 's', 's');
    if (min < 60) return u(min, 'min', 'm');
    final h = d.inHours;
    if (h < 24) return min % 60 == 0 ? u(h, 'h', 'h') : '${u(h, 'h', 'h')} ${u(min % 60, 'min', 'm')}';
    final dias = d.inDays;
    return h % 24 == 0 ? u(dias, 'd', 'd') : '${u(dias, 'd', 'd')} ${u(h % 24, 'h', 'h')}';
  }

  // ---------------------------------------------------------------- marcas

  static const _min = 60 * 1000;
  static const _hora = 60 * _min;
  static const _dia = 24 * _hora;

  /// Passos possíveis do eixo, em ms (mês e ano aproximados só para escolher).
  static const passos = <int>[
    _min,
    2 * _min,
    5 * _min,
    10 * _min,
    15 * _min,
    30 * _min,
    _hora,
    2 * _hora,
    3 * _hora,
    6 * _hora,
    12 * _hora,
    _dia,
    2 * _dia,
    7 * _dia,
    14 * _dia,
    30 * _dia,
    91 * _dia,
    182 * _dia,
    365 * _dia,
  ];

  /// Escolhe o menor passo que cabe em [maxTicks] marcas.
  static int passo(Duration span, int maxTicks) {
    final ms = span.inMilliseconds;
    for (final p in passos) {
      if (ms / p <= maxTicks) return p;
    }
    return passos.last;
  }

  /// Marcas "inteligentes" do eixo do tempo entre [from] e [to] com no máximo
  /// [maxTicks]: horas dentro de um dia (a meia-noite vira a data, em negrito),
  /// dias numa semana, meses num ano. Alinhadas à hora local.
  List<SsTimeTick> ticks(DateTime from, DateTime to, {int maxTicks = 6}) {
    if (!to.isAfter(from)) return const [];
    final p = passo(to.difference(from), math.max(2, maxTicks));
    final out = <SsTimeTick>[];
    final f = from.toLocal();
    if (p < _dia) {
      final minutos = p ~/ _min;
      final base = DateTime(f.year, f.month, f.day);
      var k = ((f.hour * 60 + f.minute) / minutos).ceil() * minutos;
      var t = DateTime(base.year, base.month, base.day, 0, k);
      if (t.isBefore(f)) t = DateTime(base.year, base.month, base.day, 0, k += minutos);
      while (!t.isAfter(to)) {
        final meiaNoite = t.hour == 0 && t.minute == 0;
        out.add(SsTimeTick(t, meiaNoite ? dm(t) : hm(t), major: meiaNoite));
        k += minutos;
        t = DateTime(base.year, base.month, base.day, 0, k);
      }
    } else if (p < 30 * _dia) {
      final dias = p ~/ _dia;
      var t = DateTime(f.year, f.month, f.day);
      if (t.isBefore(f)) t = DateTime(f.year, f.month, f.day + 1);
      final ini = t;
      var i = 0;
      while (!t.isAfter(to)) {
        // Até ~8 dias: dia da semana + dia; mais: dia/mês.
        final curto = to.difference(from).inDays <= 8;
        out.add(SsTimeTick(t, curto ? '${weekday(t)} ${t.day}' : dm(t), major: t.day == 1));
        i += dias;
        t = DateTime(ini.year, ini.month, ini.day + i);
      }
    } else if (p < 365 * _dia) {
      final meses = (p / (30.44 * _dia)).round();
      var t = DateTime(f.year, f.month);
      if (t.isBefore(f)) t = DateTime(f.year, f.month + 1);
      // Alinha ao múltiplo do passo (trimestre, semestre).
      while ((t.month - 1) % meses != 0) {
        t = DateTime(t.year, t.month + 1);
      }
      while (!t.isAfter(to)) {
        out.add(SsTimeTick(t, t.month == 1 ? '${t.year}' : month(t), major: t.month == 1));
        t = DateTime(t.year, t.month + meses);
      }
    } else {
      var t = DateTime(f.year);
      if (t.isBefore(f)) t = DateTime(f.year + 1);
      while (!t.isAfter(to)) {
        out.add(SsTimeTick(t, '${t.year}', major: true));
        t = DateTime(t.year + 1);
      }
    }
    return out;
  }
}

/// Marcas "redondas" do eixo Y (1, 2, 2,5 ou 5 × 10ⁿ) cobrindo [lo]..[hi],
/// cerca de [count]. A mesma conta do Rails.
({double lo, double hi, double step}) ssNiceRange(double lo, double hi, {int count = 4}) {
  if (lo == hi) {
    final d = lo == 0 ? 1.0 : lo.abs() * .1;
    lo -= d;
    hi += d;
  }
  final cru = (hi - lo) / math.max(1, count);
  final mag = math.pow(10, (math.log(cru) / math.ln10).floor()).toDouble();
  final norm = cru / mag;
  final passo =
      (norm <= 1
          ? 1
          : norm <= 2
          ? 2
          : norm <= 2.5
          ? 2.5
          : norm <= 5
          ? 5
          : 10) *
      mag;
  return (lo: (lo / passo).floor() * passo, hi: (hi / passo).ceil() * passo, step: passo);
}
