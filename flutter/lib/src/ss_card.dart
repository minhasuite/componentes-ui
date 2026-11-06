import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'density.dart';
import 'motion.dart';

/// Card do design system: superfície, raio 18 (22 quando ativo; os dois da
/// [SsDensity]), respiro 16 (o `cardPad`), sombra suave
/// (glow roxo quando ativo) e borda accent no estado ativo. Espelha `.ss-card`.
/// Com [onTap], afunda de leve no toque e volta com mola ([SsPressable]).
class SsCard extends StatelessWidget {
  const SsCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.active = false,
    this.done = false,
    this.tint,
  });

  final Widget child;

  /// Respiro interno. Nulo: `cardPad` da [SsDensity] (16 no padrão).
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool active;
  final bool done;

  /// Cor de um tom ([SsTone], categoria): fundo a 8% sobre a superfície.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final radius = BorderRadius.circular(active ? d.radiusCard + 4 : d.radiusCard);
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: padding ?? EdgeInsets.all(d.cardPad),
      decoration: BoxDecoration(
        color: tint == null ? c.surface : Color.alphaBlend(tint!.withValues(alpha: .08), c.surface),
        borderRadius: radius,
        border: active ? Border.all(color: c.accentBright, width: 2) : null,
        boxShadow: active ? c.activeShadow : AppShadows.card,
      ),
      // Material transparente: ListTile/InkWell dentro do card pintam aqui,
      // e não por baixo da decoração (o que esconderia o splash).
      child: Material(
        type: MaterialType.transparency,
        child: Opacity(opacity: done ? 0.7 : 1, child: child),
      ),
    );
    if (onTap == null) return content;
    // Tocável: afunda de leve no toque e volta com mola ao soltar.
    return SsPressable(
      scale: .98,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(onTap: onTap, borderRadius: radius, child: content),
      ),
    );
  }
}
