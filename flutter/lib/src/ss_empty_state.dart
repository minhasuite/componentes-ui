import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'illustrations.dart';
import 'ss_button.dart';
import 'ss_card.dart';

/// Estado vazio padronizado (ilustração animada + título + subtítulo + ação
/// opcional), dentro de um SsCard. Substitui as ~4 variantes espalhadas.
class SsEmptyState extends StatelessWidget {
  const SsEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    this.art,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  /// Dentro de folha ou seção que já rola: sem card, sem rolagem própria e
  /// com a ilustração menor.
  final bool compact;

  final IconData icon;

  /// Arte própria do produto no lugar da ilustração com [icon].
  final Widget? art;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final corpo = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        art ?? EmptyIllustration(icon: icon, size: compact ? 72 : 112),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: AppType.lg, color: c.ink),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.muted, height: 1.35),
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 16),
          SsButton(label: actionLabel!, expand: false, onPressed: onAction),
        ],
      ],
    );
    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(child: corpo),
      );
    }
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: SsCard(child: corpo),
      ),
    );
  }
}
