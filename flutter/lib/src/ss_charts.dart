import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'motion.dart';
import 'motion_view.dart';
import 'ss_aurora.dart';

/// Linha sem eixo com preenchimento que some para baixo e um ponto no último
/// valor. Desenha-se da esquerda para a direita quando entra na tela (700 ms).
///
/// v0.16: [target] desenha a linha tracejada do alvo (preço desejado, meta),
/// que entra na escala; [markMin] marca o menor valor com um ponto verde.
class SsSparkline extends StatelessWidget {
  const SsSparkline(
    this.values, {
    super.key,
    this.color,
    this.height = 40,
    this.edgeToEdge = false,
    this.target,
    this.markMin = false,
  });

  final List<double> values;
  final Color? color;
  final double height;

  /// Encostada nas bordas (base de card): sem respiro nas laterais.
  final bool edgeToEdge;

  /// Alvo (mesma unidade de [values]): linha tracejada apagada.
  final double? target;

  /// Ponto verde no menor valor (o mais barato do histórico).
  final bool markMin;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final cor = color ?? c.accent;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: SsTweenInView(
        end: 1,
        duration: const Duration(milliseconds: 700),
        builder: (_, t, _) => CustomPaint(
          painter: _SparkPainter(
            values,
            cor,
            t,
            inset: edgeToEdge ? 0 : 4,
            target: target,
            targetColor: c.muted,
            minColor: markMin ? AppColors.success : null,
          ),
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color, this.t, {required this.inset, this.target, this.targetColor, this.minColor});

  final List<double> values;
  final Color color;
  final double t;
  final double inset;
  final double? target;
  final Color? targetColor;
  final Color? minColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final todos = [...values, ?target];
    final lo = todos.reduce(math.min);
    final hi = todos.reduce(math.max);
    final span = hi - lo == 0 ? 1 : hi - lo;
    final w = size.width - inset * 2;
    // Respiro em cima para o ponto e embaixo para o preenchimento não colar.
    final top = 6.0;
    final h = size.height - top - 2;
    final pts = [
      for (var i = 0; i < values.length; i++)
        Offset(inset + w * i / (values.length - 1), top + h * (1 - (values[i] - lo) / span)),
    ];
    if (target != null) {
      // Alvo: tracejado de 3 px a cada 6 px, atrás da linha.
      final y = top + h * (1 - (target! - lo) / span);
      final p = Paint()
        ..color = (targetColor ?? color).withValues(alpha: .7)
        ..strokeWidth = 1;
      for (var x = 0.0; x < size.width; x += 6) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 3, size.width), y), p);
      }
    }
    // Curva suave (Catmull-Rom em cúbicas), sem passar do mínimo/máximo demais.
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = pts[math.max(i - 1, 0)];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = pts[math.min(i + 2, pts.length - 1)];
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      line.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * t, size.height));
    final area = Path.from(line)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: .24), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
    if (t >= .98 && minColor != null) {
      final i = values.indexOf(values.reduce(math.min));
      if (i != values.length - 1) {
        canvas.drawCircle(pts[i], 5, Paint()..color = minColor!.withValues(alpha: .22));
        canvas.drawCircle(pts[i], 3, Paint()..color = minColor!);
      }
    }
    if (t >= .98) {
      final last = pts.last.translate(inset == 0 ? -4 : 0, 0);
      canvas.drawCircle(last, 5, Paint()..color = color.withValues(alpha: .22));
      canvas.drawCircle(last, 2.6, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.t != t || old.values != values || old.color != color || old.target != target || old.minColor != minColor;
}

/// Um anel do [SsRings].
class SsRing {
  const SsRing(this.value, {this.color});

  /// 0 a 1 (passa de 1 = anel cheio).
  final double value;
  final Color? color;
}

/// Anéis concêntricos com ponta arredondada sobre a trilha da mesma cor a 12%.
/// Preenchem em cascata quando entram na tela (80 ms entre eles). Até 3 anéis; sem cor,
/// usam as cores da aurora da marca. [center] vai no meio (o número).
class SsRings extends StatelessWidget {
  const SsRings(this.rings, {super.key, this.size = 128, this.stroke = 11, this.center});

  final List<SsRing> rings;
  final double size;
  final double stroke;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final cores = auroraColors(SsColors.of(context));
    final padrao = [cores[1], cores[2], cores[0]];
    final n = rings.length;
    final total = 700 + 80 * (n - 1);
    return SizedBox.square(
      dimension: size,
      child: SsTweenInView(
        end: 1,
        duration: Duration(milliseconds: total),
        curve: Curves.linear,
        builder: (_, t, child) => CustomPaint(
          painter: _RingsPainter([
            for (var i = 0; i < n; i++)
              (
                // Cada anel anda 700 ms, começando 80 ms depois do anterior.
                rings[i].value.clamp(0.0, 1.0) *
                    Curves.easeOutCubic.transform(((t * total - 80 * i) / 700).clamp(0.0, 1.0)),
                rings[i].color ?? padrao[i % 3],
              ),
          ], stroke),
          child: child,
        ),
        child: center == null ? null : Center(child: center),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.rings, this.stroke);

  final List<(double, Color)> rings;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (var i = 0; i < rings.length; i++) {
      final (v, color) = rings[i];
      final r = size.shortestSide / 2 - stroke / 2 - i * (stroke + 4);
      if (r <= 0) break;
      final rect = Rect.fromCircle(center: c, radius: r);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(c, r, paint..color = color.withValues(alpha: .14));
      if (v > 0) canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * v, false, paint..color = color);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => true;
}

/// Barras em pílula (7 a 12 colunas). A coluna [highlight] (padrão: a última,
/// "hoje") fica na cor da marca e as outras a 22%. Tocar numa barra mostra o
/// valor em cima dela ([format]). Crescem de baixo com mola, em cascata,
/// quando entram na tela.
class SsPillBars extends StatefulWidget {
  const SsPillBars({
    super.key,
    required this.values,
    required this.labels,
    this.highlight,
    this.format,
    this.height = 132,
  }) : assert(values.length == labels.length);

  final List<double> values;
  final List<String> labels;
  final int? highlight;
  final String Function(double value)? format;
  final double height;

  @override
  State<SsPillBars> createState() => _SsPillBarsState();
}

class _SsPillBarsState extends State<SsPillBars> {
  int? _sel;

  /// Altura (0 a ~1,12) da barra [i] no instante [t] da cascata.
  double _sobe(double t, int i) {
    final total = 520 + 40 * (widget.values.length - 1);
    return SsMotion.bounce.transform(((t * total - 40 * i) / 520).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final hi = widget.values.fold<double>(0, math.max);
    final destaque = widget.highlight ?? widget.values.length - 1;
    final mostrar = _sel ?? (widget.format != null ? destaque : null);
    return SizedBox(
      height: widget.height,
      // Cada barra sobe com mola, 40 ms depois da anterior, quando entra na tela.
      child: SsInView(
        duration: Duration(milliseconds: 520 + 40 * (widget.values.length - 1)),
        curve: Curves.linear,
        builder: (context, anim, _) => Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < widget.values.length; i++)
              Expanded(
                child: Semantics(
                  label: '${widget.labels[i]}: ${widget.format?.call(widget.values[i]) ?? widget.values[i]}',
                  button: widget.format != null,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.format == null ? null : () => setState(() => _sel = i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedOpacity(
                          opacity: mostrar == i ? 1 : 0,
                          duration: const Duration(milliseconds: 150),
                          child: Text(
                            widget.format?.call(widget.values[i]) ?? '',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            style: AppTheme.number(context, size: AppType.micro, color: c.ink),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: hi == 0
                                ? .04
                                : math.max(.04, widget.values[i] / hi * _sobe(anim.value, i).clamp(0.0, 1.05)),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 14,
                              decoration: BoxDecoration(
                                color: i == destaque || i == _sel ? c.accent : c.accent.withValues(alpha: .22),
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.labels[i],
                          style: TextStyle(
                            color: i == destaque ? c.ink : c.muted,
                            fontSize: AppType.micro,
                            fontWeight: i == destaque ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
