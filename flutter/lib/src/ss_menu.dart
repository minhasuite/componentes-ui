import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'motion.dart';
import 'motion_view.dart';

/// Uma ação do [SsOverflowMenu]. [destructive] pinta de vermelho (excluir);
/// [checked] põe um ✓ no fim (ordem, filtro ativo); [subtitle] é uma linha menor.
class SsMenuAction {
  const SsMenuAction(
    this.icon,
    this.label,
    this.onTap, {
    this.destructive = false,
    this.checked = false,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  final bool checked;
  final String? subtitle;
}

/// Ações secundárias num ⋮ que abre um menu ancorado embaixo dele (raio,
/// ícone + texto, destrutivo em vermelho). Com uma ação só, vira o ícone
/// dela com tooltip; sem ações, não mostra nada. O menu abre da âncora e as
/// linhas descem em cascata com mola.
class SsOverflowMenu extends StatelessWidget {
  const SsOverflowMenu({
    super.key,
    required this.items,
    this.tooltip = 'Mais opções',
    this.icon = Icons.more_vert_rounded,
  });

  final List<SsMenuAction> items;
  final String tooltip;

  /// Ícone do botão (ex.: `Icons.sort_rounded` num menu de ordem).
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final c = SsColors.of(context);
    if (items.length == 1 && !items.single.checked) {
      final a = items.single;
      return IconButton(
        tooltip: a.label,
        icon: Icon(a.icon, color: a.destructive ? AppColors.danger : null),
        onPressed: a.onTap,
      );
    }
    return PopupMenuButton<int>(
      tooltip: tooltip,
      icon: Icon(icon),
      position: PopupMenuPosition.under,
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: c.isDark ? 0 : 8,
      shadowColor: const Color(0x66141628),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        side: c.isDark ? BorderSide(color: c.line) : BorderSide.none,
      ),
      onOpened: SsHaptics.tick,
      // Abre rápido; as linhas descem em cascata com mola (SsRouteStagger).
      popUpAnimationStyle: reduceMotion(context)
          ? AnimationStyle.noAnimation
          : AnimationStyle(curve: Curves.easeOutCubic, duration: const Duration(milliseconds: 300)),
      onSelected: (i) => items[i].onTap(),
      itemBuilder: (_) => [
        for (final (i, a) in items.indexed)
          PopupMenuItem(
            value: i,
            height: 48,
            child: SsRouteStagger(index: i, child: SsMenuActionRow(a)),
          ),
      ],
    );
  }
}

/// A linha de uma ação (ícone + texto) como aparece no [SsOverflowMenu];
/// pública para montar o mesmo visual em outro menu.
class SsMenuActionRow extends StatelessWidget {
  const SsMenuActionRow(this.action, {super.key});

  final SsMenuAction action;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final cor = action.destructive ? c.dangerText : c.ink;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(action.icon, size: 20, color: action.destructive ? AppColors.danger : c.ink2),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                action.label,
                style: TextStyle(color: cor, fontSize: AppType.set, fontWeight: FontWeight.w600),
              ),
              if (action.subtitle != null)
                Text(
                  action.subtitle!,
                  style: TextStyle(color: c.muted, fontSize: AppType.meta),
                ),
            ],
          ),
        ),
        if (action.checked) ...[
          const SizedBox(width: 12),
          Icon(Icons.check_rounded, size: 20, color: c.accentText, semanticLabel: 'marcado'),
        ],
      ],
    );
  }
}
