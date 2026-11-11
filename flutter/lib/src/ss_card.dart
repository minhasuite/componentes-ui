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
    this.soft = false,
    this.stripe,
    this.outline,
  });

  final Widget child;

  /// Respiro interno. Nulo: `cardPad` da [SsDensity] (16 no padrão).
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool active;
  final bool done;

  /// Cor de um tom ([SsTone], categoria): fundo a 8% sobre a superfície.
  final Color? tint;

  /// v0.14.1: painel rebaixado (fundo do campo, sem sombra), para um bloco
  /// dentro de outro card ou de um passo. O web é o `.ss-card.is-soft`.
  final bool soft;

  /// v0.19.2: faixa de cor na borda esquerda, por dentro do raio (5 px):
  /// o tipo ou a urgência do card (aviso, recall, conselho). O [padding]
  /// continua valendo a partir da faixa. O web é o `.ss-card.has-stripe`
  /// com `--ss-card-stripe`. Ex.: `SsCard(stripe: SsTone.danger.colors(context).solid)`.
  final Color? stripe;

  /// v0.19.2: contorno de 2 px na cor (sem trocar o fundo nem a sombra):
  /// "no alvo" em verde, conflito em vermelho. O [active] (contorno da marca
  /// com brilho) ganha dele. O web é o `.ss-card.has-outline` com
  /// `--ss-card-outline`.
  final Color? outline;

  /// Largura da faixa do [stripe].
  static const stripeWidth = 5.0;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final radius = BorderRadius.circular(active ? d.radiusCard + 4 : d.radiusCard);
    final pad = padding ?? EdgeInsets.all(d.cardPad);
    // Material transparente: ListTile/InkWell dentro do card pintam aqui,
    // e não por baixo da decoração (o que esconderia o splash).
    Widget inner = Material(
      type: MaterialType.transparency,
      child: Opacity(opacity: done ? 0.7 : 1, child: child),
    );
    if (stripe != null) {
      inner = Stack(
        children: [
          Padding(
            padding: pad.add(const EdgeInsets.only(left: stripeWidth)),
            child: inner,
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: stripeWidth,
            child: ColoredBox(color: stripe!),
          ),
        ],
      );
    }
    final border = active
        ? Border.all(color: c.accentBright, width: 2)
        : (outline != null ? Border.all(color: outline!, width: 2) : null);
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: stripe != null ? EdgeInsets.zero : pad,
      // A faixa fica por dentro do raio: recorta o conteúdo (a sombra fica de fora).
      clipBehavior: stripe != null ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: soft ? c.field : (tint == null ? c.surface : Color.alphaBlend(tint!.withValues(alpha: .08), c.surface)),
        borderRadius: radius,
        border: border,
        boxShadow: active ? c.activeShadow : (soft ? null : AppShadows.card),
      ),
      child: inner,
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
