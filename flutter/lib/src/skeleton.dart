import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'motion.dart';

/// Skeleton loader reutilizável: uma lista de "cartões-fantasma" que pulsam
/// suavemente enquanto os dados carregam. Substitui os spinners nas listas,
/// dando sensação de que a tela já está montando (mais rápido de percepção).
class SkeletonList extends StatefulWidget {
  const SkeletonList({super.key, this.count = 5, this.padding});
  final int count;
  final EdgeInsets? padding;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);

  // Com "reduzir movimento" fica parado no meio da pulsação.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.stop();
      _c.value = .5;
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
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = 0.45 + _c.value * 0.4; // opacidade pulsando 0.45–0.85
        return ListView(
          padding: widget.padding ?? const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            for (var i = 0; i < widget.count; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CardSkeleton(pulse: t),
              ),
          ],
        );
      },
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton({required this.pulse});
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = cs.surfaceContainerHighest.withValues(alpha: .5);
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: .08 * pulse * 2),
        borderRadius: BorderRadius.circular(6),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [bar(180, 15), const SizedBox(height: 12), bar(120, 12)],
            ),
          ),
          const SizedBox(width: 16),
          bar(64, 26),
        ],
      ),
    );
  }
}

/// Bloco-fantasma de altura fixa, para o lugar de um gráfico ou imagem.
///
/// A lista tem `SkeletonList`; o gráfico não tinha nada e caía num spinner
/// dentro do card — a moldura ficava, o conteúdo sumia e a altura pulava
/// quando os dados chegavam. Este segura a altura final desde o começo.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({super.key, required this.height, this.radius});
  final double height;
  final double? radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);

  // Com "reduzir movimento" fica parado no meio da pulsação.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.stop();
      _c.value = .5;
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
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Opacity(
        opacity: 0.45 + _c.value * 0.4,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: c.field,
            borderRadius: BorderRadius.circular(widget.radius ?? AppRadius.card),
          ),
        ),
      ),
    );
  }
}
