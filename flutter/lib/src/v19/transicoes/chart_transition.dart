import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

import '../../motion.dart';

/// Troca de dados animada nos gráficos da suíte (v1.9): quando os valores
/// mudam (outro mês, outro filtro), cada ponto vai do valor anterior ao novo
/// em vez de pular. Série com outro número de pontos troca direto. Com
/// "reduzir movimento", troca direto.
///
/// No State do gráfico (com um `TickerProvider`):
/// ```dart
/// class _S extends State<MeuGrafico> with SingleTickerProviderStateMixin, SsChartTransition<MeuGrafico> {
///   @override
///   List<List<double>> chartValues(MeuGrafico w) => [w.valores];
///   // no build: chartShown[0] no lugar de widget.valores
/// }
/// ```
/// `NaN` é "sem valor" (buraco) e não interpola.
mixin SsChartTransition<T extends StatefulWidget> on State<T>, TickerProvider {
  /// Os valores do gráfico, por série.
  List<List<double>> chartValues(T widget);

  /// Duração da troca.
  Duration get chartTransitionDuration => const Duration(milliseconds: 520); // v1.9 tokens

  late final AnimationController _troca = AnimationController(vsync: this, duration: chartTransitionDuration, value: 1)
    ..addListener(_aoTrocar);
  late List<List<double>> _de;
  late List<List<double>> _para;

  @override
  void initState() {
    super.initState();
    _de = _para = chartValues(widget);
  }

  void _aoTrocar() {
    if (mounted) setState(() {});
  }

  /// Os valores a desenhar agora (o meio do caminho durante a troca).
  List<List<double>> get chartShown {
    final v = _troca.value;
    if (v >= 1) return _para;
    final t = Curves.easeInOutCubic.transform(v);
    return [
      for (var i = 0; i < _para.length; i++)
        if (i < _de.length && _de[i].length == _para[i].length)
          [
            for (var k = 0; k < _para[i].length; k++)
              _de[i][k].isNaN || _para[i][k].isNaN ? _para[i][k] : lerpDouble(_de[i][k], _para[i][k], t)!,
          ]
        else
          _para[i],
    ];
  }

  /// Se está trocando de dados agora.
  bool get chartTransitioning => _troca.isAnimating;

  static bool _iguais(List<List<double>> a, List<List<double>> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i], y = b[i];
      if (x.length != y.length) return false;
      for (var k = 0; k < x.length; k++) {
        if (x[k] != y[k] && !(x[k].isNaN && y[k].isNaN)) return false;
      }
    }
    return true;
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    final novo = chartValues(widget);
    if (_iguais(novo, _para)) return;
    final atual = chartShown;
    _para = novo;
    if (reduceMotion(context)) {
      _de = novo;
      _troca.value = 1;
      return;
    }
    _de = atual;
    _troca.forward(from: 0);
  }

  @override
  void dispose() {
    _troca.dispose();
    super.dispose();
  }
}
