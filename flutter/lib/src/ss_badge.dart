import 'package:flutter/material.dart';

import 'app_theme.dart';

enum SsBadgeVariant { accent, success, warning, danger, ghost, aquec }

/// Badge pill "soft" do design system: fundo dessaturado + texto na cor. Espelha
/// `.mp-badge` (font 11/700, pill). `micro` = variante compacta (10/700, uppercase).
class SsBadge extends StatelessWidget {
  const SsBadge(this.label, {super.key, this.variant = SsBadgeVariant.accent, this.micro = false});

  final String label;
  final SsBadgeVariant variant;
  final bool micro;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    late final Color fg;
    late final Color bg;
    switch (variant) {
      case SsBadgeVariant.accent:
        fg = c.accentText;
        bg = c.accentSoft;
      case SsBadgeVariant.success:
        fg = c.successText;
        bg = AppColors.successSoft;
      case SsBadgeVariant.warning:
        fg = AppColors.warnFg;
        bg = AppColors.warnBg;
      case SsBadgeVariant.danger:
        fg = c.dangerText;
        bg = AppColors.dangerSoft;
      case SsBadgeVariant.ghost:
        fg = c.muted;
        bg = AppColors.ghostSoft;
      case SsBadgeVariant.aquec:
        fg = c.aquecText;
        bg = c.aquecSoft;
    }
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: micro ? 8 : 12, vertical: micro ? 3 : 5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Text(
          micro ? label.toUpperCase() : label,
          style: TextStyle(
            color: fg,
            fontSize: micro ? AppType.micro : AppType.label,
            fontWeight: FontWeight.w700,
            letterSpacing: micro ? 0.5 : 0,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

/// Selo de destaque pontual ("Novo", "Meta batida"): contorno firme e sombra
/// deslocada sem desfoque. Personalidade em doses: no máximo um por tela.
class SsSeal extends StatelessWidget {
  const SsSeal(this.text, {super.key, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 4, 10, 4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.accentText, width: 1.5),
        boxShadow: [BoxShadow(color: c.accent.withValues(alpha: .35), offset: const Offset(3, 3))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: c.accentText), const SizedBox(width: 4)],
          Text(
            text.toUpperCase(),
            style: TextStyle(
              color: c.accentText,
              fontSize: AppType.label,
              fontWeight: FontWeight.w800,
              letterSpacing: .8,
            ),
          ),
        ],
      ),
    );
  }
}
