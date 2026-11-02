import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'motion.dart';

/// Barra de progresso do design system: 100% é sucesso (verde). Cresce de 0
/// ao aparecer.
///
/// - [marker] (0 a 1): tracinho de "onde devia estar hoje", com [markerLabel].
/// - [value] acima de 1 é estouro: a barra passa a valer [value] e o excesso
///   aparece listrado em vermelho.
/// - [segments]: divide a barra em N gomos (passos, parcelas).
class SsProgress extends StatelessWidget {
  const SsProgress(this.value, {super.key, this.height = 8, this.color, this.marker, this.markerLabel, this.segments});

  /// 0 a 1 (mais que 1 = estourou). `null` = indeterminado (enviando, sem
  /// saber quanto falta): faixa que corre na cor da marca.
  final double? value;
  final double height;
  final Color? color;
  final double? marker;
  final String? markerLabel;
  final int? segments;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    if (value == null) {
      return Semantics(
        label: 'Carregando',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            minHeight: height,
            color: color ?? c.accent,
            backgroundColor: c.field,
            // Sem movimento: a faixa fica parada em 1/3.
            value: reduceMotion(context) ? .33 : null,
          ),
        ),
      );
    }
    final v = math.max(0.0, value!);
    final cor = color ?? (v >= 1 && v <= 1.0001 ? AppColors.success : c.accent);
    final escala = math.max(1.0, v); // largura total = max(1, valor)
    final temMarca = marker != null;
    final bar = SizedBox(
      height: height + (temMarca ? 8 : 0),
      width: double.infinity,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: v),
        duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (_, t, _) => CustomPaint(
          painter: _BarPainter(
            t: t / escala,
            cheio: 1 / escala,
            marker: marker == null ? null : marker!.clamp(0.0, 1.0) / escala,
            segments: segments,
            height: height,
            track: c.field,
            color: cor,
            ink: c.ink,
          ),
        ),
      ),
    );
    final pct = '${(v * 100).round()}%';
    return Semantics(
      value: v > 1 ? '$pct, estourou' : pct,
      child: markerLabel == null || marker == null
          ? bar
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment(marker!.clamp(0.0, 1.0) / escala * 2 - 1, 0),
                  child: Text(
                    markerLabel!,
                    style: TextStyle(fontSize: AppType.micro, fontWeight: FontWeight.w700, color: c.muted),
                  ),
                ),
                const SizedBox(height: 2),
                bar,
              ],
            ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.t,
    required this.cheio,
    required this.marker,
    required this.segments,
    required this.height,
    required this.track,
    required this.color,
    required this.ink,
  });

  /// Fração da largura preenchida agora (animação) e onde fica o 100%.
  final double t, cheio;
  final double? marker;
  final int? segments;
  final double height;
  final Color track, color, ink;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final top = (size.height - height) / 2;
    final r = Radius.circular(height / 2);
    // Forma da barra: uma pílula ou N gomos com 3 px de folga.
    final forma = Path();
    final n = segments ?? 1;
    const folga = 3.0;
    final gomo = (w - folga * (n - 1)) / n;
    for (var i = 0; i < n; i++) {
      forma.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(i * (gomo + folga), top, gomo, height), r));
    }
    canvas.save();
    canvas.clipPath(forma);
    canvas.drawRect(Rect.fromLTWH(0, top, w, height), Paint()..color = track);
    final ate = math.min(t, cheio) * w;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, top, ate, height), r), Paint()..color = color);
    if (t > cheio) {
      // Estouro: vermelho com listras diagonais claras.
      final ex = Rect.fromLTRB(cheio * w, top, t * w, top + height);
      canvas.drawRect(ex, Paint()..color = AppColors.danger);
      canvas.save();
      canvas.clipRect(ex);
      final listra = Paint()
        ..color = Colors.white.withValues(alpha: .35)
        ..strokeWidth = 2.5;
      for (var x = ex.left - height; x < ex.right + height; x += 7) {
        canvas.drawLine(Offset(x, top + height), Offset(x + height, top), listra);
      }
      canvas.restore();
    }
    canvas.restore();
    if (marker != null) {
      final x = marker! * w;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = ink
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.t != t || old.cheio != cheio || old.marker != marker || old.color != color || old.track != track;
}

/// Categorias numa barra só ([parts]: `(valor, rótulo, cor?)`), com legenda
/// e % em DM Mono. Tocar numa parte (na barra ou na legenda) destaca ela e
/// apaga as outras; tocar de novo desfaz. Sem cor: a paleta da suíte.
class SsProportionBar extends StatefulWidget {
  const SsProportionBar({super.key, required this.parts, this.legend = true, this.height = 14});

  final List<(double, String, Color?)> parts;
  final bool legend;
  final double height;

  @override
  State<SsProportionBar> createState() => _SsProportionBarState();
}

class _SsProportionBarState extends State<SsProportionBar> {
  int? _sel;

  void _toca(int i) {
    HapticFeedback.selectionClick();
    setState(() => _sel = _sel == i ? null : i);
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final paleta = c.series;
    final total = widget.parts.fold<double>(0, (s, p) => s + math.max(0, p.$1));
    final partes = [
      for (var i = 0; i < widget.parts.length; i++)
        (
          math.max(0.0, widget.parts[i].$1),
          widget.parts[i].$2,
          widget.parts[i].$3 ?? paleta[i % paleta.length],
          total == 0 ? 0 : (math.max(0.0, widget.parts[i].$1) / total * 100).round(),
        ),
    ];
    Color tom(int i) => _sel == null || _sel == i ? partes[i].$3 : partes[i].$3.withValues(alpha: .3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            height: widget.height,
            color: c.field,
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, t, child) => FractionallySizedBox(widthFactor: t, child: child),
              child: Row(
                children: [
                  for (var i = 0; i < partes.length; i++)
                    if (partes[i].$1 > 0)
                      Expanded(
                        flex: math.max(1, (partes[i].$1 / total * 1000).round()),
                        child: Semantics(
                          button: true,
                          selected: _sel == i,
                          label: '${partes[i].$2}: ${partes[i].$4}%',
                          excludeSemantics: true,
                          child: GestureDetector(
                            onTap: () => _toca(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: EdgeInsets.only(right: i == partes.length - 1 ? 0 : 2),
                              color: tom(i),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
        if (widget.legend) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              for (var i = 0; i < partes.length; i++)
                Semantics(
                  button: true,
                  selected: _sel == i,
                  label: '${partes[i].$2}: ${partes[i].$4}%',
                  excludeSemantics: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _toca(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: tom(i), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            partes[i].$2,
                            style: TextStyle(
                              fontSize: AppType.meta,
                              fontWeight: _sel == i ? FontWeight.w800 : FontWeight.w600,
                              color: _sel == null || _sel == i ? c.ink2 : c.muted,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${partes[i].$4}%',
                            style: AppTheme.number(context, size: AppType.meta, color: c.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
