import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'motion.dart';

enum SsButtonVariant { primary, ghost, success, danger }

/// Botão do design system. `primary` tem o **glow roxo** direcional que o
/// `elevation` do Material não reproduz. Altura 50, raio 14 (11 quando `small`).
/// No toque afunda rápido e, ao soltar, volta com mola ([SsPressable]); o
/// carregando e o conteúdo trocam com um cruzamento curto.
class SsButton extends StatelessWidget {
  const SsButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = SsButtonVariant.primary,
    this.icon,
    this.small = false,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final SsButtonVariant variant;
  final IconData? icon;
  final bool small;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final enabled = onPressed != null && !loading;

    late final Color bg;
    late final Color fg;
    List<BoxShadow>? shadow;
    switch (variant) {
      case SsButtonVariant.primary:
        bg = c.accent;
        fg = AppColors.onDark;
        shadow = enabled ? c.primaryShadow : null;
      case SsButtonVariant.ghost:
        bg = c.field;
        fg = c.ink2;
      case SsButtonVariant.success:
        bg = AppColors.success;
        fg = AppColors.onDark;
      case SsButtonVariant.danger:
        bg = AppColors.danger;
        fg = AppColors.onDark;
    }

    final height = small ? 36.0 : 50.0;
    final radius = BorderRadius.circular(small ? AppRadius.stepperBtn : AppRadius.field);
    final fontSize = small ? AppType.meta : AppType.body;

    Widget content;
    if (loading) {
      content = SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: fg));
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: small ? 16 : 20, color: fg), const SizedBox(width: 8)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: fg, fontSize: fontSize, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      );
    }

    // Conteúdo ↔ carregando: cruza com um pulinho (mola), sem pular o tamanho.
    content = AnimatedSwitcher(
      duration: reduceMotion(context) ? Duration.zero : SsMotion.base,
      switchInCurve: SsMotion.bounce,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: a.drive(Tween(begin: .7, end: 1.0)), child: child),
      ),
      child: KeyedSubtree(key: ValueKey(loading), child: content),
    );

    return SsPressable(
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          height: height,
          width: expand ? double.infinity : null,
          decoration: BoxDecoration(borderRadius: radius, boxShadow: shadow),
          // Brilho de 1 px no topo dos botões sólidos (volume sem gradiente).
          foregroundDecoration: variant == SsButtonVariant.ghost
              ? null
              : BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withValues(alpha: .22), Colors.white.withValues(alpha: 0)],
                    stops: const [0, .08],
                  ),
                ),
          child: Material(
            color: bg,
            borderRadius: radius,
            child: InkWell(
              onTap: enabled ? onPressed : null,
              borderRadius: radius,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: small ? 12 : 18),
                child: Center(child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
