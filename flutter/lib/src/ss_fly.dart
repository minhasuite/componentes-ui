import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'motion.dart';

/// "Valor que voa até o total": um clone de [child] sai de [from] e voa num
/// arco até [to], encolhendo (~550 ms), com haptic leve ao chegar. Atualize o
/// total (o `SsOdometer` rola) depois do `await`. Com menos movimento, ou se
/// alguma chave não estiver na tela, volta na hora.
Future<void> ssFlyTo(BuildContext context, {required GlobalKey from, required GlobalKey to, required Widget child}) {
  final overlay = Overlay.of(context);
  final ob = overlay.context.findRenderObject() as RenderBox?;
  final fb = from.currentContext?.findRenderObject() as RenderBox?;
  final tb = to.currentContext?.findRenderObject() as RenderBox?;
  if (ob == null || fb == null || tb == null || reduceMotion(context)) return Future.value();
  final a = fb.localToGlobal(Offset.zero, ancestor: ob) & fb.size;
  final b = tb.localToGlobal(Offset.zero, ancestor: ob) & tb.size;
  final done = Completer<void>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Voo(
      a: a,
      b: b,
      onDone: () {
        entry.remove();
        HapticFeedback.lightImpact();
        done.complete();
      },
      child: child,
    ),
  );
  overlay.insert(entry);
  return done.future;
}

class _Voo extends StatefulWidget {
  const _Voo({required this.a, required this.b, required this.onDone, required this.child});
  final Rect a;
  final Rect b;
  final VoidCallback onDone;
  final Widget child;

  @override
  State<_Voo> createState() => _VooState();
}

class _VooState extends State<_Voo> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.a;
    final p0 = a.center, p2 = widget.b.center;
    // Controle acima dos dois pontos: o clone sobe e cai no total.
    final p1 = Offset((p0.dx + p2.dx) / 2, (p0.dy < p2.dy ? p0.dy : p2.dy) - 90);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final v = _c.value;
        final t = Curves.easeInOutCubic.transform(v);
        final u = 1 - t;
        final p = p0 * (u * u) + p1 * (2 * u * t) + p2 * (t * t);
        return Positioned(
          left: p.dx - a.width / 2,
          top: p.dy - a.height / 2,
          width: a.width,
          height: a.height,
          child: Opacity(
            opacity: v < .8 ? 1 : (1 - v) / .2,
            child: Transform.scale(scale: 1 - .65 * t, child: child),
          ),
        );
      },
      child: IgnorePointer(
        child: Material(type: MaterialType.transparency, child: widget.child),
      ),
    );
  }
}
