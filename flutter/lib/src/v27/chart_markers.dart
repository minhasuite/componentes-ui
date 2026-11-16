// v0.27 (meulog): marcas verticais nos gráficos por categoria ([SsBarChart] e
// [SsLineChart]), par do `markers:` do Ss::BarChartComponent/LineChartComponent.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';
import '../ss_badge.dart' show SsTone;

/// O tipo da marca: deploy (o que mudou), incidente (o que caiu) ou nota.
enum SsChartMarkerKind { deploy, incident, note }

/// Uma marca vertical num rótulo do eixo X: traço tracejado de cima a baixo e o
/// [label] no alto. Deploy na cor de informação, incidente na de perigo, nota na
/// apagada. Duas marcas no mesmo rótulo empilham o texto. Marca com [at] que não
/// está nos rótulos não aparece.
///
/// `SsLineChart(..., markers: [SsChartMarker(at: '12/11', label: 'v2.3.1')])`
@immutable
class SsChartMarker {
  const SsChartMarker({required this.at, required this.label, this.kind = SsChartMarkerKind.deploy});

  final String at;
  final String label;
  final SsChartMarkerKind kind;
}

/// Altura de uma linha de rótulo de marca.
const ssMarkerLine = 13.0;

/// As marcas que caem nos rótulos: (índice, linha empilhada 1.., marca).
List<(int, int, SsChartMarker)> ssResolveMarkers(List<SsChartMarker> markers, List<String> labels) {
  final per = <int, int>{};
  return [
    for (final m in markers)
      if (labels.indexOf(m.at) case final i when i >= 0) (i, per[i] = (per[i] ?? 0) + 1, m),
  ];
}

/// Quantas linhas de rótulo empilhadas no rótulo mais cheio.
int ssMarkerRows(List<(int, int, SsChartMarker)> resolved) => resolved.fold(0, (a, r) => math.max(a, r.$2));

/// Cor (AA) de cada tipo no tema atual.
Color ssMarkerColor(BuildContext context, SsChartMarkerKind kind) {
  final c = SsColors.of(context);
  return switch (kind) {
    SsChartMarkerKind.deploy => SsTone.info.colors(context).text,
    SsChartMarkerKind.incident => c.dangerText,
    SsChartMarkerKind.note => c.muted,
  };
}

/// Pinta as marcas: traço de [top] a [bottom] em x(índice) e o rótulo no alto
/// (perto da borda direita, alinhado pelo fim).
void ssPaintMarkers(
  Canvas canvas,
  Size size,
  List<(int, int, SsChartMarker)> resolved,
  double Function(int i) x,
  Map<SsChartMarkerKind, Color> colors, {
  required double top,
  required double bottom,
  required TextStyle style,
}) {
  for (final (i, row, m) in resolved) {
    final cor = colors[m.kind]!;
    final px = x(i);
    if (row == 1) {
      final paint = Paint()
        ..color = cor
        ..strokeWidth = 1.25;
      for (var y = top; y < bottom; y += 7) {
        canvas.drawLine(Offset(px, y), Offset(px, math.min(y + 4, bottom)), paint);
      }
    }
    final tp = TextPainter(
      text: TextSpan(
        text: m.label,
        style: style.copyWith(color: cor),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: math.max(40, size.width / 3));
    final fim = px > size.width - 90;
    tp.paint(canvas, Offset(fim ? px - 4 - tp.width : px + 4, ssMarkerLine * (row - 1)));
  }
}

/// O texto das marcas de um rótulo, para o leitor de tela e o balão.
String ssMarkersAt(List<(int, int, SsChartMarker)> resolved, int i) => [
  for (final (k, _, m) in resolved)
    if (k == i) m.label,
].join(', ');
