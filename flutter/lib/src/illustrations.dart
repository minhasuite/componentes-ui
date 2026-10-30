import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'motion.dart';

/// Ilustração dos estados vazios: bolha com o gradiente da marca, dois
/// "cartões" flutuando, moedas e o ícone do contexto por cima. Desenhada em
/// código (sem asset de terceiros) e na paleta do tema. Flutua devagar.
class EmptyIllustration extends StatefulWidget {
  const EmptyIllustration({super.key, required this.icon, this.size = 132});

  final IconData icon;
  final double size;

  @override
  State<EmptyIllustration> createState() => _EmptyIllustrationState();
}

class _EmptyIllustrationState extends State<EmptyIllustration> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 4));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = widget.size;
    return SizedBox(
      width: s,
      height: s,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final t = Curves.easeInOut.transform(_c.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(s),
                painter: _BlobPainter(cores: c, t: t),
              ),
              Transform.translate(
                offset: Offset(0, -4 + t * 6),
                child: Container(
                  width: s * .42,
                  height: s * .42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [c.brandFrom, c.brandDeep],
                    ),
                    borderRadius: BorderRadius.circular(s * .14),
                    boxShadow: c.primaryShadow,
                  ),
                  child: Icon(widget.icon, color: AppColors.onDark, size: s * .2),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter({required this.cores, required this.t});

  final SsColors cores;
  final double t;

  bool get dark => cores.isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final c = Offset(w / 2, w / 2);
    // Halo
    canvas.drawCircle(
      c,
      w * .48,
      Paint()
        ..shader = RadialGradient(
          colors: [
            cores.brandFrom.withValues(alpha: dark ? .28 : .18),
            cores.brandTo.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: w * .48)),
    );
    // Cartões flutuando atrás do ícone
    void card(double dx, double dy, double angle, Color color) {
      canvas.save();
      canvas.translate(c.dx + dx * w, c.dy + dy * w);
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w * .5, height: w * .3),
          Radius.circular(w * .05),
        ),
        Paint()..color = color,
      );
      canvas.restore();
    }

    final surface = dark ? AppColors.surfaceDark : AppColors.surfaceLight;
    card(-.12, .08 - t * .02, -.28, cores.brandTo.withValues(alpha: dark ? .35 : .22));
    card(.13, .1 + t * .02, .22, surface.withValues(alpha: dark ? .9 : 1));
    // Moedas
    final coin = Paint()..color = const Color(0xFFF4B740);
    final rim = Paint()
      ..color = const Color(0xFFE09B1B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .012;
    for (final (dx, dy, r) in [(.34, -.28, .055), (-.36, -.22, .04), (.3, .32, .035)]) {
      final o = Offset(c.dx + dx * w, c.dy + dy * w + math.sin(t * math.pi + dx * 9) * w * .015);
      canvas.drawCircle(o, r * w, coin);
      canvas.drawCircle(o, r * w * .72, rim);
    }
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t || old.dark != dark || old.cores.brand != cores.brand;
}
