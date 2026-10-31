import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
