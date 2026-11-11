import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'density.dart';
import 'v192/pecas.dart' show SsDot;

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
///
/// v0.19.2: [badge] põe um [SsDot] dessa cor no canto de baixo à direita,
/// com anel na cor da superfície (estado da conexão: ligado, erro);
/// [badgeLabel] é o que o leitor de tela lê.
class SsIconBubble extends StatelessWidget {
  const SsIconBubble(this.icon, {super.key, this.color, this.size = 40, this.badge, this.badgeLabel});

  final IconData icon;
  final Color? color;
  final double size;
  final Color? badge;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final fg = color ?? c.accent;
    final bubble = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: fg.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(size / 3)),
      child: Icon(icon, color: fg, size: size * 0.5),
    );
    if (badge == null) return bubble;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        bubble,
        Positioned(
          right: -2,
          bottom: -2,
          child: SsDot(color: badge, size: (size * .23).clamp(8.0, 14.0), ring: c.surface, semanticLabel: badgeLabel),
        ),
      ],
    );
  }
}
