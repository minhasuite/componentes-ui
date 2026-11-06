import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';

/// Intensidade do [SsGlass].
enum SsGlassLevel { leve, medio, forte }

/// Superfície de vidro: desfoca o que está atrás, véu claro translúcido e um
/// filete de luz na borda de cima. **Só em sobreposição ou herói** (sobre foto,
/// aurora, gradiente): nunca em card de lista ou dado denso, que continuam em
/// superfície calma (a direção visual proíbe vidro em card/lista).
class SsGlass extends StatelessWidget {
  const SsGlass({
    super.key,
    required this.child,
    this.level = SsGlassLevel.medio,
    this.radius = AppRadius.cardActive,
    this.padding,
  });

  final Widget child;
  final SsGlassLevel level;
  final double radius;

  /// Respiro (padrão: o do card da [SsDensity], 16 no padrão).
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final (sigma, veil, rim) = switch (level) {
      SsGlassLevel.leve => (8.0, .08, .18),
      SsGlassLevel.medio => (16.0, .14, .28),
      SsGlassLevel.forte => (26.0, .22, .4),
    };
    final br = BorderRadius.circular(radius);
    final tintBase = c.isDark ? c.surface : AppColors.onDark;
    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: br,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                tintBase.withValues(alpha: veil + .06),
                tintBase.withValues(alpha: veil),
              ],
            ),
            border: Border.all(color: AppColors.onDark.withValues(alpha: rim * .45)),
          ),
          child: CustomPaint(
            foregroundPainter: _RimPainter(radius: radius, alpha: rim),
            child: Padding(padding: padding ?? EdgeInsets.all(SsDensity.of(context).cardPad), child: child),
          ),
        ),
      ),
    );
  }
}

/// O filete de luz: uma linha clara na borda de cima que some nas pontas.
class _RimPainter extends CustomPainter {
  _RimPainter({required this.radius, required this.alpha});
  final double radius;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(radius * .6, .5, size.width - radius * 1.2, 1.2);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            AppColors.onDark.withValues(alpha: 0),
            AppColors.onDark.withValues(alpha: alpha * 2),
            AppColors.onDark.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RimPainter old) => old.alpha != alpha || old.radius != radius;
}

/// Brilho radial ambiente atrás do filho (botão de ação do herói, ícone de
/// conquista). Sem cor, usa a da marca. Não ocupa espaço: o brilho vaza
/// [spread] px para fora do filho e não recebe toque.
class SsGlow extends StatelessWidget {
  const SsGlow({super.key, required this.child, this.color, this.spread = 28, this.intensity = .45});

  final Widget child;
  final Color? color;
  final double spread;

  /// Opacidade no centro do brilho (0–1).
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final k = color ?? c.accent;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned(
          left: -spread,
          right: -spread,
          top: -spread,
          bottom: -spread,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    k.withValues(alpha: intensity * (c.isDark ? 1.2 : 1)),
                    k.withValues(alpha: 0),
                  ],
                  stops: const [.2, 1],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Padrão do [SsTexture].
enum SsTextureKind { topografia, ruido }

/// Textura sutil pintada (curvas de nível de mapa ou ruído fino), opcional
/// atrás de herói ou mosaico. Semente fixa: igual a cada pintura. Sem [color],
/// usa a tinta do tema a 7%; sobre fundo escuro passe uma cor clara.
class SsTexture extends StatelessWidget {
  const SsTexture({super.key, this.kind = SsTextureKind.topografia, this.color, this.seed = 3, this.child});

  final SsTextureKind kind;
  final Color? color;
  final int seed;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final k = color ?? c.ink.withValues(alpha: .07);
    return CustomPaint(
      painter: kind == SsTextureKind.topografia ? _TopoPainter(k, seed) : _NoisePainter(k, seed),
      child: child ?? const SizedBox.expand(),
    );
  }
}

class _TopoPainter extends CustomPainter {
  _TopoPainter(this.color, this.seed);
  final Color color;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final m = math.max(size.width, size.height);
    // Dois "morros": anéis ondulados concêntricos que crescem para fora.
    for (var h = 0; h < 2; h++) {
      final center = Offset(size.width * (.2 + .6 * rnd.nextDouble()), size.height * (.2 + .6 * rnd.nextDouble()));
      final phase = rnd.nextDouble() * math.pi * 2;
      for (var ring = 1; ring <= 9; ring++) {
        final base = m * .07 * ring;
        final path = Path();
        for (var a = 0; a <= 72; a++) {
          final t = a / 72 * math.pi * 2;
          final wobble = 1 + .12 * math.sin(3 * t + phase + ring * .3) + .06 * math.sin(5 * t - phase);
          final p = center + Offset(math.cos(t), math.sin(t) * .8) * base * wobble;
          a == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path..close(), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_TopoPainter old) => old.color != color || old.seed != seed;
}

class _NoisePainter extends CustomPainter {
  _NoisePainter(this.color, this.seed);
  final Color color;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final n = (size.width * size.height / 22).round();
    final pts = [for (var i = 0; i < n; i++) Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height)];
    canvas.drawPoints(
      ui.PointMode.points,
      pts,
      Paint()
        ..color = color
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(_NoisePainter old) => old.color != color || old.seed != seed;
}

/// Superfície em squircle (canto contínuo): card de ícone, botão quadrado,
/// miniatura. Usa [AppRadius.squircle]; sem [color], a superfície do tema.
class SsSquircle extends StatelessWidget {
  const SsSquircle({
    super.key,
    required this.child,
    this.radius = AppRadius.card,
    this.color,
    this.padding = EdgeInsets.zero,
    this.shadows,
    this.width,
    this.height,
  });

  final Widget child;
  final double radius;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final List<BoxShadow>? shadows;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final shape = AppRadius.squircle(radius);
    return Container(
      width: width,
      height: height,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(color: color ?? c.surface, shape: shape, shadows: shadows ?? AppShadows.card),
      child: child,
    );
  }
}

/// Reflexo diagonal que passa **uma vez** sobre o filho ao aparecer (cartão
/// novo, prêmio, saldo carregado). Mude [trigger] para tocar de novo. Com
/// menos movimento, não passa.
class SsShimmerGlass extends StatefulWidget {
  const SsShimmerGlass({
    super.key,
    required this.child,
    this.radius = AppRadius.cardActive,
    this.duration = const Duration(milliseconds: 1100),
    this.delay = const Duration(milliseconds: 150),
    this.trigger,
  });

  final Widget child;
  final double radius;
  final Duration duration;
  final Duration delay;

  /// Valor que, ao mudar, faz o reflexo passar de novo.
  final Object? trigger;

  @override
  State<SsShimmerGlass> createState() => _SsShimmerGlassState();
}

class _SsShimmerGlassState extends State<SsShimmerGlass> with SingleTickerProviderStateMixin {
  // O atraso entra na própria animação (Interval): nada de Timer solto.
  late final _c = AnimationController(vsync: this, duration: widget.delay + widget.duration);
  late final _curve = Interval(
    widget.delay.inMilliseconds / (widget.delay + widget.duration).inMilliseconds,
    1,
    curve: Curves.easeInOutCubic,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _play();
    }
  }

  @override
  void didUpdateWidget(SsShimmerGlass old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _play();
  }

  void _play() {
    if (reduceMotion(context)) return;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      widget.child,
      Positioned.fill(
        child: IgnorePointer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.radius),
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, _) {
                final t = _curve.transform(_c.value);
                return t <= 0 || t >= 1 ? const SizedBox.shrink() : CustomPaint(painter: _ShinePainter(t));
              },
            ),
          ),
        ),
      ),
    ],
  );
}

class _ShinePainter extends CustomPainter {
  _ShinePainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width + size.height;
    final x = -size.height + w * t;
    final band = size.shortestSide * .5 + 30;
    final rect = Rect.fromLTWH(x - band, 0, band * 2, size.height);
    final path = Path()
      ..moveTo(x - band * .5, 0)
      ..lineTo(x + band * .5, 0)
      ..lineTo(x + band * .5 - size.height * .5, size.height)
      ..lineTo(x - band * .5 - size.height * .5, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [
            AppColors.onDark.withValues(alpha: 0),
            AppColors.onDark.withValues(alpha: .32),
            AppColors.onDark.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_ShinePainter old) => old.t != t;
}
