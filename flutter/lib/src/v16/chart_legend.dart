// v0.16: legenda de gráfico (par do Ss::ChartLegendComponent / .ss-legend da gem).
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../density.dart';

/// Um item do [SsChartLegend]: a cor da série, o rótulo e, opcional, o valor
/// em DM Mono ("menor R$ 2.148"). [line] troca a bolinha por um traço
/// (série de linha); com [dashed], tracejado (alvo, média, previsão).
@immutable
class SsLegendItem {
  const SsLegendItem(this.label, this.color, {this.value, this.line = false, this.dashed = false});

  final String label;
  final Color color;
  final String? value;
  final bool line;
  final bool dashed;

  @override
  bool operator ==(Object other) =>
      other is SsLegendItem &&
      other.label == label &&
      other.color == color &&
      other.value == value &&
      other.line == line &&
      other.dashed == dashed;

  @override
  int get hashCode => Object.hash(label, color, value, line, dashed);
}

/// Legenda de gráfico: cor da série + rótulo (+ valor), em linhas que quebram.
/// Rótulo longo termina em "…" na largura do contêiner; o leitor de tela lê
/// "rótulo: valor". Itens repetidos aparecem uma vez. Vai embaixo de
/// [SsLineChart], [SsSparkline], [SsBarChart] e de gráfico próprio do produto.
///
/// ```dart
/// SsChartLegend(items: [
///   SsLegendItem('Atacadão', c.series[0]),
///   SsLegendItem('menor', AppColors.success, value: money(214800)),
///   SsLegendItem('alvo', c.muted, value: money(199000), line: true, dashed: true),
/// ])
/// ```
class SsChartLegend extends StatelessWidget {
  const SsChartLegend({super.key, required this.items, this.alignment = WrapAlignment.start});

  final List<SsLegendItem> items;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    return Wrap(
      alignment: alignment,
      spacing: d.space(14),
      runSpacing: d.space(6),
      children: [
        for (final it in {...items})
          Semantics(
            label: it.value == null ? it.label : '${it.label}: ${it.value}',
            excludeSemantics: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Marca(it),
                SizedBox(width: d.space(6)),
                Flexible(
                  child: Text(
                    it.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: TextStyle(color: c.ink2, fontSize: d.font(AppType.meta), fontWeight: FontWeight.w600),
                  ),
                ),
                if (it.value != null) ...[
                  SizedBox(width: d.space(5)),
                  Text(
                    it.value!,
                    maxLines: 1,
                    style: AppTheme.number(context, size: d.font(AppType.meta), color: c.muted),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Marca extends StatelessWidget {
  const _Marca(this.it);
  final SsLegendItem it;

  @override
  Widget build(BuildContext context) {
    if (!it.line) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: it.color, shape: BoxShape.circle),
      );
    }
    return CustomPaint(size: const Size(14, 3), painter: _Traco(it.color, it.dashed));
  }
}

class _Traco extends CustomPainter {
  _Traco(this.color, this.dashed);
  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = size.height
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    if (!dashed) {
      canvas.drawLine(Offset(1, y), Offset(size.width - 1, y), p);
      return;
    }
    canvas.drawLine(Offset(1, y), Offset(4, y), p);
    canvas.drawLine(Offset(size.width - 4, y), Offset(size.width - 1, y), p);
  }

  @override
  bool shouldRepaint(_Traco old) => old.color != color || old.dashed != dashed;
}
