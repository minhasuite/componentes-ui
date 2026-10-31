import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'motion.dart';
import 'ss_badge.dart';
import 'ss_list.dart';

/// Oferta de uma loja/site para comparar preço: fonte (chip), título, preço
/// pronto em DM Mono, preço antigo riscado e uma nota ("à vista", "10x sem
/// juros"). [best] põe a fita "Mais barata", borda e preço em verde.
///
/// `SsOfferCard(source: 'Amazon', title: 'Air Fryer 4 L', price: r'R$ 329,90', oldPrice: r'R$ 399,00', best: true)`
class SsOfferCard extends StatelessWidget {
  const SsOfferCard({
    super.key,
    required this.source,
    this.sourceIcon,
    required this.title,
    required this.price,
    this.oldPrice,
    this.note,
    this.best = false,
    this.onTap,
  });

  final String source;

  /// Ícone/favicon da fonte; sem ele, as iniciais coloridas pelo nome.
  final Widget? sourceIcon;
  final String title;
  final String price;
  final String? oldPrice;
  final String? note;
  final bool best;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final radius = BorderRadius.circular(AppRadius.card);
    final priceBox = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            price,
            maxLines: 1,
            style: AppTheme.number(
              context,
              size: AppType.lg,
              weight: FontWeight.w700,
              color: best ? c.successText : c.ink,
            ),
          ),
        ),
        if ((oldPrice ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              oldPrice!,
              maxLines: 1,
              style: AppTheme.number(
                context,
                size: AppType.meta,
                color: c.muted,
              ).copyWith(decoration: TextDecoration.lineThrough, decorationColor: c.muted),
            ),
          ),
      ],
    );
    final body = Padding(
      padding: EdgeInsets.fromLTRB(14, best ? 26 : 12, 14, 12),
      child: LayoutBuilder(
        builder: (context, box) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SsSourceChip(source, favicon: sourceIcon),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.ink, fontSize: AppType.body, fontWeight: FontWeight.w700),
                  ),
                  if ((note ?? '').isNotEmpty)
                    Text(
                      note!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.muted, fontSize: AppType.meta),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: box.maxWidth * .4),
              child: priceBox,
            ),
          ],
        ),
      ),
    );
    final card = Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: radius,
        border: best ? Border.all(color: AppColors.success, width: 1.5) : (c.isDark ? Border.all(color: c.line) : null),
        boxShadow: c.isDark ? null : AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          body,
          if (best)
            Positioned(
              top: 0,
              right: 16,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 3, 10, 4),
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, size: 13, color: AppColors.inkLight),
                    SizedBox(width: 3),
                    Text(
                      'MAIS BARATA',
                      style: TextStyle(
                        color: AppColors.inkLight,
                        fontSize: AppType.micro,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
    final label = [
      source,
      title,
      price,
      if ((oldPrice ?? '').isNotEmpty) 'antes $oldPrice',
      if ((note ?? '').isNotEmpty) note!,
      if (best) 'mais barata',
    ].join(', ');
    return Semantics(
      button: onTap != null,
      label: label,
      excludeSemantics: true,
      child: SsPressable(onTap: onTap, enabled: onTap != null, child: card),
    );
  }
}

/// Selo de promoção ("−18%", "Baixou", "Frete grátis"): pílula do [tone]
/// em DM Mono. Verde por padrão (preço caiu).
///
/// `SsDealBadge('−18%')` · `SsDealBadge('Subiu 6%', tone: SsTone.danger)`
class SsDealBadge extends StatelessWidget {
  const SsDealBadge(this.text, {super.key, this.tone = SsTone.success});

  final String text;
  final SsTone tone;

  @override
  Widget build(BuildContext context) {
    final t = tone.colors(context);
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: t.soft,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: t.solid.withValues(alpha: .5)),
        ),
        child: Text(
          text,
          style: AppTheme.number(context, size: AppType.meta, weight: FontWeight.w700, color: t.text),
        ),
      ),
    );
  }
}

/// Chip de loja/site: [favicon] (widget, ex. `SsNetImage`), [icon] ou as
/// iniciais coloridas pelo nome (mesma cor sempre, como o [SsAvatar]) + nome.
///
/// `SsSourceChip('Mercado Livre')` · `SsSourceChip('Booking', icon: Icons.hotel_outlined)`
class SsSourceChip extends StatelessWidget {
  const SsSourceChip(this.name, {super.key, this.icon, this.favicon});

  final String name;
  final IconData? icon;
  final Widget? favicon;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final lead =
        favicon ??
        (icon != null ? Icon(icon, size: 15, color: c.accentText) : ExcludeSemantics(child: SsAvatar(name, size: 22)));
    return Semantics(
      label: name,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(3, 3, 10, 3),
        decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(dimension: 22, child: Center(child: lead)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: c.ink2, fontSize: AppType.meta, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
