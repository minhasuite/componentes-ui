import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'motion.dart';

/// Uma ação do [SsOverflowMenu]. [destructive] pinta de vermelho (excluir).
class SsMenuAction {
  const SsMenuAction(this.icon, this.label, this.onTap, {this.destructive = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
}

/// Ações secundárias num ⋮ que abre um menu ancorado embaixo dele (raio,
/// ícone + texto, destrutivo em vermelho). Com uma ação só, vira o ícone
/// dela com tooltip; sem ações, não mostra nada.
class SsOverflowMenu extends StatelessWidget {
  const SsOverflowMenu({super.key, required this.items, this.tooltip = 'Mais opções'});

  final List<SsMenuAction> items;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final c = SsColors.of(context);
    if (items.length == 1) {
      final a = items.single;
      return IconButton(
        tooltip: a.label,
        icon: Icon(a.icon, color: a.destructive ? AppColors.danger : null),
        onPressed: a.onTap,
      );
    }
    return PopupMenuButton<int>(
      tooltip: tooltip,
      icon: const Icon(Icons.more_vert_rounded),
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
      onSelected: (i) => items[i].onTap(),
      itemBuilder: (_) => [
        for (final (i, a) in items.indexed) PopupMenuItem(value: i, height: 48, child: SsMenuActionRow(a)),
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
        Text(
          action.label,
          style: TextStyle(color: cor, fontSize: AppType.set, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
