import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';

/// Movimento do design system: tudo aqui some quando o sistema pede menos
/// animação (Acessibilidade → remover animações).
bool reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Encolhe para 0,97 enquanto o dedo está em cima. Com [onTap], também trata
/// o toque (com haptic leve); sem ele, só dá o efeito a um filho que já é
/// tocável (InkWell, botão). [enabled] falso desliga o efeito.
class SsPressable extends StatefulWidget {
  const SsPressable({super.key, required this.child, this.onTap, this.enabled = true, this.scale = .97});

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final double scale;

  @override
  State<SsPressable> createState() => _SsPressableState();
}

class _SsPressableState extends State<SsPressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    Widget child = AnimatedScale(
      scale: _down && !reduceMotion(context) ? widget.scale : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: widget.child,
    );
    if (widget.onTap != null) {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap!();
        },
        child: child,
      );
    }
    // Listener (ponteiro cru): não disputa o toque com o InkWell do filho.
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: child,
    );
  }
}

/// Número que conta de onde estava até [value] (600 ms) e é desenhado por
/// [builder]: `SsCountUp(1234.5, builder: (v) => Text(money(v)))`.
class SsCountUp extends StatelessWidget {
  const SsCountUp(this.value, {super.key, required this.builder, this.duration = const Duration(milliseconds: 600)});

  final double value;
  final Widget Function(double value) builder;
  final Duration duration;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value),
    duration: reduceMotion(context) ? Duration.zero : duration,
    curve: Curves.easeOutCubic,
    builder: (_, v, _) => builder(v),
  );
}

/// A "mesma mola em todo lugar": curva e tempos do movimento da suíte.
/// `AnimatedFoo(duration: SsMotion.base, curve: SsMotion.spring)`.
class SsMotion {
  const SsMotion._();
  static const Curve spring = Curves.easeOutBack;
  static const fast = Duration(milliseconds: 180);
  static const base = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 400);

  /// Atraso entre itens de uma lista que entra em cascata.
  static const stagger = Duration(milliseconds: 40);
}

/// Entrada do filho, uma vez: aparece e sobe 12 px, com atraso de
/// `index * SsMotion.stagger` (só os 8 primeiros esperam: lista longa não
/// fica "chegando" para sempre). Com menos movimento, aparece direto.
class SsReveal extends StatelessWidget {
  const SsReveal({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return child;
    final delay = math.min(index, 8) * SsMotion.stagger.inMilliseconds;
    final total = SsMotion.slow.inMilliseconds + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 12), child: child),
      ),
      child: child,
    );
  }
}

/// Revela o filho da esquerda para a direita (gráfico "se desenhando"), uma vez.
class SsDrawIn extends StatelessWidget {
  const SsDrawIn({super.key, required this.child, this.duration = const Duration(milliseconds: 900)});

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeInOutCubic,
      builder: (_, t, child) => ClipRect(clipper: _WidthClipper(t), child: child),
      child: child,
    );
  }
}

class _WidthClipper extends CustomClipper<Rect> {
  _WidthClipper(this.t);
  final double t;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * t, size.height);

  @override
  bool shouldReclip(_WidthClipper old) => old.t != t;
}

/// Confete por cima de tudo (~1,2 s) nas cores da marca e do sucesso, e some
/// sozinho. Para conquista de verdade (meta batida, primeiros passos feitos).
/// Com menos movimento não faz nada: a mensagem já comemora.
void showSsConfetti(BuildContext context) {
  if (reduceMotion(context)) return;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  final c = SsColors.of(context);
  final cores = [c.brandFrom, c.brandTo, c.accentBright, c.brandDeep, AppColors.success];
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Confetti(cores: cores, onDone: () => entry.remove()),
  );
  overlay.insert(entry);
}

class _Confetti extends StatefulWidget {
  const _Confetti({required this.cores, required this.onDone});
  final List<Color> cores;
  final VoidCallback onDone;

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
    ..forward().whenComplete(widget.onDone);
  final _rnd = math.Random();
  late final _pieces = List.generate(
    70,
    (i) => _Piece(
      x: .5 + (_rnd.nextDouble() - .5) * .3,
      vx: (_rnd.nextDouble() - .5) * 1.1,
      vy: -(.35 + _rnd.nextDouble() * .45),
      spin: (_rnd.nextDouble() - .5) * 12,
      size: 6 + _rnd.nextDouble() * 5,
      color: widget.cores[i % widget.cores.length],
    ),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, _) => CustomPaint(size: Size.infinite, painter: _ConfettiPainter(_pieces, _c.value)),
    ),
  );
}

class _Piece {
  const _Piece({
    required this.x,
    required this.vx,
    required this.vy,
    required this.spin,
    required this.size,
    required this.color,
  });
  final double x, vx, vy, spin, size;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);
  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in pieces) {
      // Estoura do meio para cima e cai com gravidade; some no último quarto.
      final y = .45 + p.vy * t + 1.1 * t * t;
      final x = p.x + p.vx * t * .5;
      paint.color = p.color.withValues(alpha: (1 - math.max(0.0, t - .75) * 4).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(p.spin * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * .55),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/// Vibração por contexto, para todo app usar a mesma: [tick] ao escolher,
/// [threshold] ao cruzar um limite (deslize), [success] ao concluir,
/// [error] ao falhar.
class SsHaptics {
  const SsHaptics._();
  static Future<void> tick() => HapticFeedback.selectionClick();
  static Future<void> threshold() => HapticFeedback.mediumImpact();

  /// Dois toques leves (o "deu certo").
  static Future<void> success() async {
    await HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    await HapticFeedback.lightImpact();
  }

  static Future<void> error() => HapticFeedback.heavyImpact();
}
