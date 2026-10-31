import 'dart:math' as math;

import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'motion.dart';

/// As três cores da aurora a partir da marca: a clara, a principal e uma
/// vizinha fria (matiz −32°, o azul do gradiente violeta; no verde, um
/// verde-amarelado). Assim cada produto ganha a sua aurora sem cor fixa.
List<Color> auroraColors(SsColors c) {
  final hsl = HSLColor.fromColor(c.brandTo);
  return [c.brandFrom, c.brandTo, hsl.withHue((hsl.hue - 32) % 360).withLightness(.6).toColor()];
}

/// O "momento de luz" da tela: base escura, manchas de aurora num canto e grão
/// por cima. Texto sempre claro (a base é escura nos dois temas). Use **um por
/// tela**, para o número que importa (saldo, vendido no mês).
///
/// As manchas derivam devagar (14 s, ida e volta); param com menos movimento.
class SsAuroraCard extends StatefulWidget {
  const SsAuroraCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.animate = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Falso para capturas e listas longas (a deriva é a única animação contínua).
  final bool animate;

  @override
  State<SsAuroraCard> createState() => _SsAuroraCardState();
}

class _SsAuroraCardState extends State<SsAuroraCard> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 14));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final move = widget.animate && !reduceMotion(context);
    if (move && !_c.isAnimating) _c.repeat(reverse: true);
    if (!move) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final radius = BorderRadius.circular(AppRadius.cardActive);
    final card = Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: c.brandDeep.withValues(alpha: c.isDark ? .5 : .35),
            offset: const Offset(0, 18),
            blurRadius: 36,
            spreadRadius: -18,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: CustomPaint(
          painter: _AuroraPainter(t: _c, colors: auroraColors(c), base: _base(c)),
          // Camada própria: a deriva repinta a aurora, não o grão nem o texto.
          child: RepaintBoundary(
            child: CustomPaint(
              painter: const _GrainPainter(opacity: .07),
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: AppColors.onDark),
                child: IconTheme.merge(
                  data: const IconThemeData(color: AppColors.onDark),
                  child: Padding(padding: widget.padding, child: widget.child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return SsPressable(onTap: widget.onTap, child: card);
  }

  /// Base: a cor funda da marca, ainda mais escura (contraste AA do texto).
  static Color _base(SsColors c) => Color.lerp(c.brandDeep, const Color(0xFF0B0A14), .55)!;
}

/// Fundo de tela com a aurora fraca (10% no claro, 16% no escuro) só no topo.
/// Vai atrás do conteúdo, num Stack do tamanho da tela:
/// `Stack(fit: StackFit.expand, children: [const SsAuroraBackground(), conteudo])`.
class SsAuroraBackground extends StatelessWidget {
  const SsAuroraBackground({super.key, this.height = 360});

  final double height;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final cores = auroraColors(c).map((k) => k.withValues(alpha: c.isDark ? .16 : .10)).toList();
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: height,
      child: IgnorePointer(
        child: CustomPaint(
          painter: _AuroraPainter(
            t: const AlwaysStoppedAnimation(.3),
            colors: cores,
            base: Colors.transparent,
            fade: true,
          ),
        ),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({required this.t, required this.colors, required this.base, this.fade = false}) : super(repaint: t);

  final Animation<double> t;
  final List<Color> colors;
  final Color base;

  /// Some em direção à base (fundo de tela).
  final bool fade;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Camada própria: o esmaecer (dstIn) só pode apagar a aurora, não a tela.
    if (fade) canvas.saveLayer(rect, Paint());
    if (base.a > 0) canvas.drawRect(rect, Paint()..color = base);
    final v = Curves.easeInOutSine.transform(t.value);
    final w = size.width;
    final h = size.height;
    final m = math.max(w, h);
    // Três manchas: canto de cima à direita, a fria embaixo à direita, uma
    // pequena à esquerda. A deriva é de poucos % (calma, não lava-lâmpada).
    final blobs = [
      (Offset(w * (.86 - .06 * v), h * (.05 + .1 * v)), m * .62, colors[1]),
      (Offset(w * (1.02 - .04 * v), h * (.95 - .12 * v)), m * .5, colors[2]),
      (Offset(w * (.55 + .08 * v), h * (-.15 + .08 * v)), m * .38, colors[0]),
    ];
    for (final (center, r, color) in blobs) {
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: color.a * .85),
              color.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }
    if (fade) {
      canvas.drawRect(
        rect,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.transparent],
          ).createShader(rect),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.colors != colors || old.base != base;
}

/// Grão fino (pontos claros e escuros, semente fixa): tira o "digital" do gradiente.
class _GrainPainter extends CustomPainter {
  const _GrainPainter({required this.opacity});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final n = (size.width * size.height / 28).round();
    final claros = <Offset>[];
    final escuros = <Offset>[];
    for (var i = 0; i < n; i++) {
      final p = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      (i.isEven ? claros : escuros).add(p);
    }
    final paint = Paint()..strokeWidth = 1;
    canvas.drawPoints(PointMode.points, claros, paint..color = Colors.white.withValues(alpha: opacity));
    canvas.drawPoints(PointMode.points, escuros, paint..color = Colors.black.withValues(alpha: opacity));
  }

  @override
  bool shouldRepaint(_GrainPainter old) => old.opacity != opacity;
}
