// Ajudantes internos dos controles da casa (v0.10). Não é exportado pelo
// barril: só os arquivos ctl_*.dart usam.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Tons semânticos dos controles da casa (os mesmos do CSS da gem):
/// aquecimento é o âmbar da suíte ([AppColors.aquecFg]); frio é o azul de
/// informação da suíte (`--ss-info` no CSS). Não são cores da marca.
const ctlHeat = AppColors.aquecFg;
const ctlCool = Color(0xFF3B82F6);

/// Borda tracejada de um retângulo arredondado (tile indisponível).
class CtlDashedBorder extends CustomPainter {
  CtlDashedBorder({required this.color, required this.radius, this.width = 1.4, this.dash = 6, this.gap = 4});

  final Color color;
  final double radius, width, dash, gap;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(width / 2),
      Radius.circular(math.max(0, radius - width / 2)),
    );
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    for (final m in (Path()..addRRect(r)).computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + dash, m.length)), p);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(CtlDashedBorder old) => old.color != color || old.radius != radius || old.width != width;
}

/// Prende [v] entre [min] e [max] e arredonda no [step] (a partir de [min]).
double ctlSnap(double v, double min, double max, double step) {
  final c = v.clamp(min, max).toDouble();
  if (step <= 0) return c;
  final s = min + ((c - min) / step).round() * step;
  // Corta o lixo de ponto flutuante (0.1 + 0.2).
  return double.parse(s.clamp(min, max).toStringAsFixed(6));
}
