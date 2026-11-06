import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'density.dart';

/// Herói com o gradiente da marca: rótulo, o número grande (DM Mono), uma
/// legenda e selos. Texto sempre `onDark` (o gradiente é escuro nos dois temas).
class SsHeroCard extends StatelessWidget {
  const SsHeroCard({super.key, required this.label, required this.value, this.caption, this.chips = const []});

  final String label;
  final String value;
  final String? caption;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(SsDensity.of(context).cardPad + 2),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [SsColors.of(context).brandFrom, SsColors.of(context).brandTo]),
      borderRadius: BorderRadius.circular(AppRadius.card),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.onDark, fontSize: AppType.sub, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.number(context, size: AppType.statNum, color: AppColors.onDark),
        ),
        if (caption != null)
          Text(
            caption!,
            style: TextStyle(color: AppColors.onDark.withValues(alpha: 0.8), fontSize: AppType.sub),
          ),
        if (chips.isNotEmpty) ...[const SizedBox(height: 10), Wrap(spacing: 6, runSpacing: 6, children: chips)],
      ],
    ),
  );
}

/// Selo translúcido dentro do [SsHeroCard].
class SsHeroChip extends StatelessWidget {
  const SsHeroChip(this.icon, this.text, {super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.onDark.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.onDark),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.onDark, fontSize: AppType.meta, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
