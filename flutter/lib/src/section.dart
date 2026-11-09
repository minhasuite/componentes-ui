import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'density.dart';

/// Título de seção ("VENCE LOGO") com ação opcional à direita e, desde a
/// v0.13, um [icon] antes do texto (o `Ss::SectionComponent` do Rails).
class SsSection extends StatelessWidget {
  const SsSection(this.title, {super.key, this.action, this.onAction, this.icon});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  /// Ícone pequeno antes do título, na cor apagada do texto (v0.13).
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(4, d.space(20), 4, d.space(8)),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: c.muted), const SizedBox(width: 6)],
          Expanded(
            child: Text(
              title.toUpperCase(),
              semanticsLabel: title,
              style: TextStyle(
                color: c.muted,
                fontSize: AppType.label,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(action!, style: TextStyle(fontSize: d.font(AppType.sub))),
            ),
        ],
      ),
    );
  }
}

/// Ícone redondo suave (lista, cards).
class SsIconBubble extends StatelessWidget {
  const SsIconBubble(this.icon, {super.key, this.color, this.size = 40});

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final fg = color ?? c.accent;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: fg.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(size / 3)),
      child: Icon(icon, color: fg, size: size * 0.5),
    );
  }
}
