import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'density.dart';
import 'motion.dart';
import 'ss_badge.dart';
import 'ss_list.dart';
import 'ss_strings.dart';

/// Oferta de uma loja/site para comparar preço: fonte (chip), título, preço
/// pronto em DM Mono, preço antigo riscado e uma nota ("à vista", "10x sem
/// juros"). [best] põe a fita "Mais barata", borda e preço em verde.
///
/// v0.16 (o `McOfferCard` do compras e o `MvOfferCard` do viagens), tudo
/// opcional: [badges] (selos embaixo), [meta] (linha pequena: "verificado
/// 12/10 14:00"), [actions] (botões no rodapé, à direita), [menu] (⋮ no canto),
/// [hit] (preço no alvo: valor em verde, sem a fita), [kind]/[kindIcon] (tipo
/// em caixa alta: "PACOTE", "VOO"), [unit] ("R$ 3.904 por pessoa", embaixo do
/// preço), [estimate] (montado por conta: borda tracejada, fundo de campo,
/// "≈" antes do preço e "ESTIMATIVA" no tipo), [savings] + [savingsGood]
/// ("R$ 112 abaixo do alvo", em verde ou apagado) e [stacked]/[fill] (preço
/// embaixo do texto, para cartão estreito numa fileira; com [fill], o preço
/// desce até a base do cartão de altura fixa).
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
    this.badges = const [],
    this.meta,
    this.actions = const [],
    this.menu,
    this.hit = false,
    this.kind,
    this.kindIcon,
    this.unit,
    this.estimate = false,
    this.savings,
    this.savingsGood = true,
    this.stacked = false,
    this.fill = false,
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

  /// Selos ([SsBadge], [SsDealBadge], [SsDelta]) num `Wrap` embaixo do texto.
  final List<Widget> badges;

  /// Linha pequena e apagada no fim ("verificado 12/10 14:00", "há 2 dias").
  final String? meta;

  /// Botões de texto no rodapé, alinhados à direita ("Ver oferta").
  final List<Widget> actions;

  /// No canto superior direito, depois do preço ([SsOverflowMenu]).
  final Widget? menu;

  /// Preço no alvo (ou abaixo): valor em verde, sem a fita do [best].
  final bool hit;

  /// Tipo da oferta em caixa alta, acima do título ("Pacote", "Voo").
  final String? kind;
  final IconData? kindIcon;

  /// Embaixo do preço ("R$ 640 por noite", "por pessoa").
  final String? unit;

  /// Estimativa montada por conta (não é oferta de verdade): borda tracejada.
  final bool estimate;

  /// Economia ou diferença embaixo do preço; verde com [savingsGood].
  final String? savings;
  final bool savingsGood;

  /// Preço embaixo do texto (alinhado à esquerda) em vez de à direita.
  final bool stacked;

  /// Com altura fixa (fileira): o preço desce para a base. Liga o [stacked].
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = SsStrings.of(context);
    final radius = BorderRadius.circular(AppRadius.card);
    final d = SsDensity.of(context);
    final empilhado = stacked || fill;
    final verde = best || hit;
    final precoTexto = estimate ? '≈ $price' : price;
    final priceBox = Column(
      crossAxisAlignment: empilhado ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: empilhado ? Alignment.centerLeft : Alignment.centerRight,
          child: Text(
            precoTexto,
            maxLines: 1,
            style: AppTheme.number(
              context,
              size: AppType.lg,
              weight: FontWeight.w700,
              color: verde ? c.successText : c.ink,
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
        if ((unit ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              unit!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: empilhado ? TextAlign.start : TextAlign.end,
              style: TextStyle(color: c.muted, fontSize: AppType.label, fontWeight: FontWeight.w600),
            ),
          ),
        if ((savings ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              savings!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: empilhado ? TextAlign.start : TextAlign.end,
              style: TextStyle(
                color: savingsGood ? c.successText : c.muted,
                fontSize: AppType.meta,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
    final tipo = [if (estimate) s.estimateLabel, ?kind].join(' · ');
    final texto = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SsSourceChip(source, favicon: sourceIcon),
        if (tipo.isNotEmpty) ...[
          SizedBox(height: d.space(8)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(estimate ? Icons.build_outlined : (kindIcon ?? Icons.sell_outlined), size: 13, color: c.muted),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  tipo.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.muted,
                    fontSize: AppType.micro,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .6,
                  ),
                ),
              ),
            ],
          ),
        ],
        SizedBox(height: d.space(tipo.isNotEmpty ? 4 : 8)),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: c.ink, fontSize: d.font(AppType.body), fontWeight: FontWeight.w700),
        ),
        if ((note ?? '').isNotEmpty)
          Text(
            note!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: c.muted, fontSize: AppType.meta),
          ),
      ],
    );
    final topo = LayoutBuilder(
      builder: (context, box) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: texto),
          if (!empilhado) ...[
            SizedBox(width: d.gap),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: box.maxWidth * .4),
              child: priceBox,
            ),
          ],
          if (menu != null) Padding(padding: const EdgeInsets.only(left: 2), child: menu),
        ],
      ),
    );
    final body = Padding(
      padding: EdgeInsets.fromLTRB(
        d.cardPad - 2,
        best ? 26 : d.cardPad - 4,
        menu == null ? d.cardPad - 2 : 4,
        actions.isEmpty ? d.cardPad - 4 : 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
        children: [
          ExcludeSemantics(child: topo),
          if (empilhado) ...[
            if (fill) const Spacer() else SizedBox(height: d.space(10)),
            ExcludeSemantics(child: priceBox),
          ],
          if (badges.isNotEmpty) ...[
            SizedBox(height: d.space(8)),
            Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: badges),
          ],
          if ((meta ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            ExcludeSemantics(
              child: Text(
                meta!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: c.muted, fontSize: AppType.label),
              ),
            ),
          ],
          if (actions.isNotEmpty) Wrap(alignment: WrapAlignment.end, children: actions),
        ],
      ),
    );
    final card = CustomPaint(
      foregroundPainter: estimate ? _Tracejado(color: c.muted, radius: AppRadius.card) : null,
      child: Container(
        decoration: BoxDecoration(
          color: estimate ? c.field : c.surface,
          borderRadius: radius,
          border: best
              ? Border.all(color: AppColors.success, width: 1.5)
              : (c.isDark && !estimate ? Border.all(color: c.line) : null),
          boxShadow: c.isDark || estimate ? null : AppShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            body,
            if (best)
              Positioned(
                top: 0,
                right: menu == null ? 16 : 52,
                child: ExcludeSemantics(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 3, 10, 4),
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_rounded, size: 13, color: AppColors.inkLight),
                        const SizedBox(width: 3),
                        Text(
                          s.cheapestBadge,
                          style: const TextStyle(
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
              ),
          ],
        ),
      ),
    );
    final label = [
      source,
      if (tipo.isNotEmpty) tipo,
      title,
      precoTexto,
      if ((oldPrice ?? '').isNotEmpty) s.wasPrice(oldPrice!),
      if ((unit ?? '').isNotEmpty) unit!,
      if ((note ?? '').isNotEmpty) note!,
      if ((savings ?? '').isNotEmpty) savings!,
      if (best) s.cheapest,
      if ((meta ?? '').isNotEmpty) meta!,
    ].join(', ');
    return Semantics(
      container: true,
      button: onTap != null,
      label: label,
      child: SsPressable(onTap: onTap, enabled: onTap != null, child: card),
    );
  }
}

/// Borda tracejada da oferta estimada (5 px de traço, 4 de vão).
class _Tracejado extends CustomPainter {
  _Tracejado({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRRect(RRect.fromRectAndRadius((Offset.zero & size).deflate(.75), Radius.circular(radius)));
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 9) {
        canvas.drawPath(m.extractPath(d, d + 5), p);
      }
    }
  }

  @override
  bool shouldRepaint(_Tracejado old) => old.color != color || old.radius != radius;
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
///
/// v0.19.2: [trailing] vai depois do nome (ícone do estado da busca na
/// loja, contagem) e [semanticLabel] troca o que o leitor de tela lê (o
/// nome com o estado: "Shopee: 3 ofertas").
class SsSourceChip extends StatelessWidget {
  const SsSourceChip(this.name, {super.key, this.icon, this.favicon, this.trailing, this.semanticLabel});

  final String name;
  final IconData? icon;
  final Widget? favicon;
  final Widget? trailing;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final lead =
        favicon ??
        (icon != null ? Icon(icon, size: 15, color: c.accentText) : ExcludeSemantics(child: SsAvatar(name, size: 22)));
    return Semantics(
      label: semanticLabel ?? name,
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.fromLTRB(3, 3, trailing == null ? 10 : 6, 3),
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
            if (trailing != null) ...[
              const SizedBox(width: 4),
              IconTheme.merge(
                data: IconThemeData(size: 14, color: c.muted),
                child: trailing!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
