import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'density.dart';
import 'motion.dart';

/// Herói com o gradiente da marca: rótulo, o número grande (DM Mono), uma
/// legenda e selos. Texto sempre `onDark` (o gradiente é escuro nos dois temas).
///
/// v0.19.2: [SsHeroCard.custom] é o mesmo gradiente com conteúdo livre
/// (chamada principal "Para onde vamos?", abertura do login, faixa da rota,
/// o bloco "Foto do cupom"): texto e ícones já saem claros, [background]
/// fica atrás do conteúdo (desenho decorativo com `Positioned`) e [onTap]
/// o deixa tocável. No web é o `.ss-hero` com qualquer conteúdo dentro.
class SsHeroCard extends StatelessWidget {
  const SsHeroCard({super.key, required this.label, required this.value, this.caption, this.chips = const []})
    : child = null,
      background = null,
      padding = null,
      radius = null,
      shadow = false,
      onTap = null,
      semanticLabel = null;

  /// Conteúdo livre no gradiente da marca (diagonal, da cor clara à funda).
  /// [radius] padrão `AppRadius.card` (o login usa `AppRadius.sheet`);
  /// [padding] padrão o do card da densidade + 2; [shadow] é a sombra da
  /// marca (`primaryShadow`); [semanticLabel] troca o que o leitor de tela lê
  /// (útil quando o card inteiro é um botão).
  const SsHeroCard.custom({
    super.key,
    required Widget this.child,
    this.background,
    this.padding,
    this.radius,
    this.shadow = true,
    this.onTap,
    this.semanticLabel,
  }) : label = '',
       value = '',
       caption = null,
       chips = const [];

  final String label;
  final String value;
  final String? caption;
  final List<Widget> chips;

  /// v0.19.2: conteúdo do [SsHeroCard.custom].
  final Widget? child;

  /// v0.19.2: camada atrás do [child], no tamanho do card e recortada pelo
  /// raio (ex.: `Positioned(right: -10, top: 8, child: arco)`).
  final Widget? background;
  final EdgeInsetsGeometry? padding;
  final double? radius;
  final bool shadow;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => child == null ? _numero(context) : _custom(context);

  Widget _custom(BuildContext context) {
    final c = SsColors.of(context);
    final r = BorderRadius.circular(radius ?? AppRadius.card);
    Widget body = Padding(padding: padding ?? EdgeInsets.all(SsDensity.of(context).cardPad + 2), child: child);
    body = DefaultTextStyle.merge(
      style: const TextStyle(color: AppColors.onDark),
      child: IconTheme.merge(
        data: const IconThemeData(color: AppColors.onDark),
        child: body,
      ),
    );
    Widget card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.brandFrom, c.brandTo, c.brandDeep],
        ),
        boxShadow: shadow ? c.primaryShadow : null,
      ),
      child: background == null ? body : Stack(children: [background!, body]),
    );
    if (onTap != null) card = SsPressable(onTap: onTap, child: card);
    if (semanticLabel != null || onTap != null) {
      card = Semantics(
        button: onTap != null,
        label: semanticLabel,
        excludeSemantics: semanticLabel != null,
        child: card,
      );
    }
    return card;
  }

  Widget _numero(BuildContext context) => Container(
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
