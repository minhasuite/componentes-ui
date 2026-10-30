import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Barra de progresso do design system: 100% é sucesso (verde).
class SsProgress extends StatelessWidget {
  const SsProgress(this.value, {super.key, this.height = 8, this.color});

  /// 0 a 1.
  final double value;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final v = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: LinearProgressIndicator(
        value: v,
        minHeight: height,
        backgroundColor: c.field,
        color: color ?? (v >= 1 ? AppColors.success : c.accent),
      ),
    );
  }
}
