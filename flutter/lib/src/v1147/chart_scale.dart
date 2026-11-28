// v1.14.7: a escala dos gráficos, uma conta só para todas as peças (par do ComponentesUi::ChartScale do Rails,
// com os mesmos casos de teste nos dois lados).
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Escala do eixo Y de um gráfico: de [lo] a [hi] em passos "redondos" ([step] = 1, 2, 2,5 ou 5 × 10ⁿ), com as
/// guias em [ticks] (de [lo] a [hi], inclusive).
///
/// - [SsChartScale.of] parte do menor e do maior valor. Com `zero: true` (barras) o zero fica sempre dentro;
///   com `max:` o topo vai pelo menos até lá (pequenos múltiplos na mesma escala).
/// - Valores iguais (todos 3) ou minúsculos (0,001) também saem com passo redondo, nunca com a escala colada.
/// - Com `format:` (o texto do app, que pode arredondar: "1 min"), o passo cresce até nenhum rótulo se repetir:
///   menos guias, nunca "1 min, 1 min".
///
/// `SsChartScale.of(0, 5.4)` → 0, 2, 4, 6. `SsChartScale.allZero([0, 0, null])` → verdadeiro (o gráfico vazio).
@immutable
class SsChartScale {
  const SsChartScale._(this.lo, this.hi, this.step, this.ticks);

  final double lo, hi, step;
  final List<double> ticks;

  static const _mantissas = [1.0, 2.0, 2.5, 5.0, 10.0];

  /// Arredonda o ruído do ponto flutuante (0,30000000000000004 → 0,3).
  static double clean(double v) {
    if (v == 0 || !v.isFinite) return v == 0 ? 0 : v;
    return double.parse(v.toStringAsPrecision(12));
  }

  /// O menor passo redondo (1, 2, 2,5, 5 × 10ⁿ) maior ou igual a [raw].
  static double niceStep(double raw) {
    if (!raw.isFinite || raw <= 0) return 1;
    final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    for (final m in _mantissas) {
      final s = clean(m * mag);
      if (s >= raw * (1 - 1e-9)) return s;
    }
    return clean(10 * mag);
  }

  /// O passo redondo logo acima de [step] (1 → 2 → 2,5 → 5 → 10).
  static double nextStep(double step) => niceStep(step * (1 + 1e-6));

  /// Casas decimais para escrever as guias de passo [step] sem repetir (2,5 → 1; 0,25 → 2; 0,001 → 3; 50 → 0).
  static int decimals(double step) {
    if (!step.isFinite || step <= 0) return 0;
    for (var d = 0; d < 12; d++) {
      final m = step * math.pow(10, d);
      if ((m - m.roundToDouble()).abs() < 1e-6 * math.max(1, m.abs())) return d;
    }
    return 12;
  }

  /// Tudo zero ou nulo (ou nada): o gráfico mostra o vazio.
  static bool allZero(Iterable<double?> values) => values.every((v) => v == null || v == 0);

  /// Escala para os valores entre [min] e [max].
  ///
  /// [intervals]: o máximo de faixas entre as guias (padrão 3, ou seja até 4 guias). [zero]: põe o zero dentro.
  /// [top]: o topo mínimo (o `max:` das peças). [format]: o texto de cada guia; com ele, rótulo repetido faz o
  /// passo crescer.
  factory SsChartScale.of(
    double min,
    double max, {
    int intervals = 3,
    bool zero = true,
    double? top,
    String Function(double value)? format,
  }) {
    var lo = min.isFinite ? min : 0.0;
    var hi = max.isFinite ? max : 0.0;
    if (lo > hi) (lo, hi) = (hi, lo);
    if (zero) {
      lo = math.min(lo, 0);
      hi = math.max(hi, 0);
    }
    if (top != null && top.isFinite) hi = math.max(hi, top);
    if (hi == lo) {
      if (hi == 0) {
        hi = 1;
      } else {
        final d = hi.abs() * .1;
        lo -= d;
        hi += d;
      }
    }
    final n = math.max(1, intervals);
    var step = niceStep((hi - lo) / n);
    var ultima = const SsChartScale._(0, 1, 1, [0, 1]);
    for (var k = 0; k < 40; k++) {
      final a = clean(((lo / step) + 1e-9).floor() * step);
      final b = clean(((hi / step) - 1e-9).ceil() * step);
      final faixas = math.max(1, ((b - a) / step).round());
      final ticks = [for (var i = 0; i <= faixas; i++) clean(a + step * i)];
      ultima = SsChartScale._(a, b == a ? a + step : b, step, ticks);
      if (faixas > n) {
        step = nextStep(step);
        continue;
      }
      if (format != null) {
        final textos = ticks.map(format).toList();
        if (textos.toSet().length < textos.length) {
          step = nextStep(step);
          continue;
        }
      }
      return ultima;
    }
    return ultima;
  }

  /// As guias menos o zero (que tem a linha própria nas barras).
  List<double> get guides => [
    for (final v in ticks)
      if (v != 0) v,
  ];

  @override
  String toString() => 'SsChartScale($lo..$hi, passo $step: $ticks)';
}
