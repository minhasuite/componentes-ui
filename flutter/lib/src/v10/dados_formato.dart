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
///
/// Fuso: sem [utcOffset], hora e data saem no fuso do aparelho
/// (`toLocal`). Com ele (ex.: `Duration(hours: -3)`, o fuso do site da casa
/// que o servidor informa), saem na hora daquele lugar, seja qual for o fuso
/// do aparelho. É um deslocamento fixo: o pacote não tem a base de fusos,
/// então horário de verão é o app que resolve (mandando o deslocamento da
/// janela que mostra).
class SsTimeFormat {
  SsTimeFormat(Locale? locale, {this.utcOffset}) : lang = _lang(locale);

  /// Idioma do contexto (o `Localizations` do app); [override] ganha.
  factory SsTimeFormat.of(BuildContext context, [Locale? override, Duration? utcOffset]) =>
      SsTimeFormat(override ?? Localizations.maybeLocaleOf(context), utcOffset: utcOffset);

  /// 'pt', 'en' ou 'es'.
  final String lang;

  /// Fuso fixo das horas e datas (nulo = o do aparelho).
  final Duration? utcOffset;

  /// Hora de parede de [t] (o que o relógio do lugar mostra): no fuso do
  /// aparelho ou em [utcOffset]. Os campos (`hour`, `day`…) são os do lugar.
  DateTime wall(DateTime t) {
    final o = utcOffset;
    if (o == null) return t.toLocal();
    final u = t.toUtc().add(o);
    return DateTime.utc(u.year, u.month, u.day, u.hour, u.minute, u.second, u.millisecond);
  }

  /// Instante de uma hora de parede (o inverso de [wall]): campos no lugar
  /// → o momento real.
  DateTime instant(int year, [int month = 1, int day = 1, int hour = 0, int minute = 0]) {
    final o = utcOffset;
    if (o == null) return DateTime(year, month, day, hour, minute);
    return DateTime.utc(year, month, day, hour, minute).subtract(o);
  }

  /// Dia de parede de [t] (meia-noite, sem hora), para agrupar por dia.
  DateTime dateOf(DateTime t) {
    final w = wall(t);
    return DateTime(w.year, w.month, w.day);
  }

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

  /// Hora: `15:00` ou `3:00 PM` (no fuso: ver [wall]).
  String hm(DateTime t) => _hm(wall(t));

  String _hm(DateTime t) {
    if (lang != 'en') return '${_two(t.hour)}:${_two(t.minute)}';
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h:${_two(t.minute)} ${t.hour < 12 ? 'AM' : 'PM'}';
  }

  /// Dia e mês: `04/11` ou `11/04`.
  String dm(DateTime t) => _dm(wall(t));

  String _dm(DateTime t) => lang == 'en' ? '${_two(t.month)}/${_two(t.day)}' : '${_two(t.day)}/${_two(t.month)}';

  /// Data completa curta: `04/11/2026` ou `11/04/2026`.
  String dmy(DateTime t) => _dmy(wall(t));

  String _dmy(DateTime t) => '${_dm(t)}/${t.year}';

  /// Mês abreviado: `nov.`, `Nov`, `nov`.
  String month(DateTime t) => _month(wall(t));

  String _month(DateTime t) => _meses[lang]![t.month - 1];

  /// Dia da semana abreviado: `qua.`, `Wed`, `mié`.
  String weekday(DateTime t) => _weekday(wall(t));

  String _weekday(DateTime t) => _semana[lang]![t.weekday - 1];

  /// Instante do balão do cursor: `04/11 15:00`.
  String when(DateTime t) {
    final w = wall(t);
    return '${_dm(w)} ${_hm(w)}';
  }

  /// Cabeçalho de dia do logbook fora de hoje/ontem: `qua, 04/11` (sem o
  /// ponto da abreviação, como o Rails; com o ano quando não é o de [now]).
  /// [t] é a data do calendário (de [dateOf]), sem conversão de fuso.
  String day(DateTime t, {DateTime? now}) {
    final ano = now != null && now.year != t.year;
    return '${_weekday(t).replaceAll('.', '')}, ${ano ? _dmy(t) : _dm(t)}';
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
    // As contas são na hora de parede ([wall]); cada marca volta a instante.
    final f = wall(from);
    final fim = wall(to);
    DateTime w(int y, [int m = 1, int d = 1, int h = 0, int min = 0]) =>
        utcOffset == null ? DateTime(y, m, d, h, min) : DateTime.utc(y, m, d, h, min);
    SsTimeTick tick(DateTime t, String label, {bool major = false}) =>
        SsTimeTick(instant(t.year, t.month, t.day, t.hour, t.minute), label, major: major);
    if (p < _dia) {
      final minutos = p ~/ _min;
      final base = w(f.year, f.month, f.day);
      var k = ((f.hour * 60 + f.minute) / minutos).ceil() * minutos;
      var t = w(base.year, base.month, base.day, 0, k);
      if (t.isBefore(f)) t = w(base.year, base.month, base.day, 0, k += minutos);
      while (!t.isAfter(fim)) {
        final meiaNoite = t.hour == 0 && t.minute == 0;
        out.add(tick(t, meiaNoite ? _dm(t) : _hm(t), major: meiaNoite));
        k += minutos;
        t = w(base.year, base.month, base.day, 0, k);
      }
    } else if (p < 30 * _dia) {
      final dias = p ~/ _dia;
      var t = w(f.year, f.month, f.day);
      if (t.isBefore(f)) t = w(f.year, f.month, f.day + 1);
      final ini = t;
      var i = 0;
      while (!t.isAfter(fim)) {
        // Até ~8 dias: dia da semana + dia; mais: dia/mês.
        final curto = to.difference(from).inDays <= 8;
        out.add(tick(t, curto ? '${_weekday(t)} ${t.day}' : _dm(t), major: t.day == 1));
        i += dias;
        t = w(ini.year, ini.month, ini.day + i);
      }
    } else if (p < 365 * _dia) {
      final meses = (p / (30.44 * _dia)).round();
      var t = w(f.year, f.month);
      if (t.isBefore(f)) t = w(f.year, f.month + 1);
      // Alinha ao múltiplo do passo (trimestre, semestre).
      while ((t.month - 1) % meses != 0) {
        t = w(t.year, t.month + 1);
      }
      while (!t.isAfter(fim)) {
        out.add(tick(t, t.month == 1 ? '${t.year}' : _month(t), major: t.month == 1));
        t = w(t.year, t.month + meses);
      }
    } else {
      var t = w(f.year);
      if (t.isBefore(f)) t = w(f.year + 1);
      while (!t.isAfter(fim)) {
        out.add(tick(t, '${t.year}', major: true));
        t = w(t.year + 1);
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
