import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'motion.dart';
import 'ss_button.dart';

/// [SsButton] que roda uma ação assíncrona: carregando → ✓ [doneLabel] em
/// verde (volta ao normal após 1,4 s). Se [onPressed] lançar erro, o botão
/// sacode e volta: mostre o aviso dentro dele e relance.
/// `SsActionButton(label: 'Salvar', onPressed: () => api.salvar())`.
class SsActionButton extends StatefulWidget {
  const SsActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = SsButtonVariant.primary,
    this.doneLabel = 'Pronto',
    this.small = false,
    this.expand = true,
  });

  final String label;
  final Future<void> Function()? onPressed;
  final IconData? icon;
  final SsButtonVariant variant;
  final String doneLabel;
  final bool small;
  final bool expand;

  @override
  State<SsActionButton> createState() => _SsActionButtonState();
}

enum _Fase { normal, carregando, pronto }

class _SsActionButtonState extends State<SsActionButton> with SingleTickerProviderStateMixin {
  var _fase = _Fase.normal;
  late final _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  Timer? _volta;

  Future<void> _run() async {
    setState(() => _fase = _Fase.carregando);
    try {
      await widget.onPressed!();
    } catch (_) {
      // O erro é de quem chamou (que já avisou e relançou); aqui só sacode.
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() => _fase = _Fase.normal);
      if (!reduceMotion(context)) _shake.forward(from: 0);
      return;
    }
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() => _fase = _Fase.pronto);
    _volta = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _fase = _Fase.normal);
    });
  }

  @override
  void dispose() {
    _volta?.cancel();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pronto = _fase == _Fase.pronto;
    final button = SsButton(
      key: ValueKey(pronto),
      label: pronto ? widget.doneLabel : widget.label,
      icon: pronto ? Icons.check_rounded : widget.icon,
      variant: pronto ? SsButtonVariant.success : widget.variant,
      loading: _fase == _Fase.carregando,
      small: widget.small,
      expand: widget.expand,
      onPressed: widget.onPressed == null ? null : (_fase == _Fase.normal ? _run : () {}),
    );
    return Semantics(
      liveRegion: true,
      child: AnimatedBuilder(
        animation: _shake,
        builder: (_, child) {
          final v = _shake.value;
          return Transform.translate(offset: Offset(math.sin(v * math.pi * 6) * 8 * (1 - v), 0), child: child);
        },
        child: AnimatedSwitcher(
          duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 320),
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: ScaleTransition(
              scale: Tween(begin: .9, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)),
              child: child,
            ),
          ),
          child: button,
        ),
      ),
    );
  }
}
