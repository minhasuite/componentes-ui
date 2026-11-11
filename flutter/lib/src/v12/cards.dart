// v0.12: cabeçalho de card, card de indicador e lista ranqueada (pares do
// Ss::CardHeaderComponent, Ss::KpiCardComponent e Ss::RankListComponent).
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../ss_badge.dart' show SsTone;
import '../ss_card.dart';
import '../ss_charts.dart';
import '../ss_list.dart' show SsIconTile;
import '../ss_stat.dart';
import '../ss_strings.dart';

/// Cabeçalho de card: o título na tipografia padrão de card (14, 800), uma
/// linha menor embaixo ([subtitle]: período, total) e, à direita, o ícone
/// tonal pequeno ([icon] na cor [tone], padrão a marca) ou o [trailing]
/// (botão, menu), que ganha do ícone. Mesma cara em todos os cards (web:
/// `Ss::CardHeaderComponent`, `.ss-card-title`/`.ss-card-sub`).
class SsCardHeader extends StatelessWidget {
  const SsCardHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.tone,
    this.trailing,
    this.titleMaxLines = 1,
    this.eyebrow,
    this.eyebrowTone,
  });

  /// v0.20: sobrelinha em versalete em cima do título ("ESTOQUE · URGENTE");
  /// par do `CardHeaderComponent(eyebrow:)`. [eyebrowTone] a pinta no tom.
  final String? eyebrow;
  final SsTone? eyebrowTone;

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? tone;
  final Widget? trailing;

  /// Linhas do título (1: reticências; o [SsKpiCard] usa 2).
  final int titleMaxLines;

  /// Estilo do título de card (para quem monta um cabeçalho próprio).
  static TextStyle titleStyle(BuildContext context) => TextStyle(
    color: SsColors.of(context).ink,
    fontSize: SsDensity.of(context).font(AppType.set),
    fontWeight: FontWeight.w800,
    height: 1.3,
  );

  /// Estilo da linha menor do cabeçalho.
  static TextStyle subtitleStyle(BuildContext context) => TextStyle(
    color: SsColors.of(context).muted,
    fontSize: SsDensity.of(context).font(AppType.meta),
    fontWeight: FontWeight.w500,
    height: 1.35,
  );

  @override
  Widget build(BuildContext context) {
    final d = SsDensity.of(context);
    final fim =
        trailing ??
        (icon == null
            ? null
            : ExcludeSemantics(
                child: SsIconTile(icon!, size: d.iconTile * .8, tone: tone),
              ));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (eyebrow != null && eyebrow!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    eyebrow!.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: eyebrowTone?.colors(context).text ?? SsColors.of(context).muted,
                      fontSize: d.font(AppType.label),
                      fontWeight: FontWeight.w800,
                      letterSpacing: AppType.trackingTight,
                    ),
                  ),
                ),
              Semantics(
                header: true,
                child: Text(
                  title,
                  maxLines: titleMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle(context),
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: subtitleStyle(context)),
                ),
            ],
          ),
        ),
        if (fim != null) ...[SizedBox(width: d.gap), fim],
      ],
    );
  }
}

/// Card de indicador: um número só num card, com o [SsCardHeader] (o
/// [label] como título, [caption] embaixo, [icon] tonal à direita), o valor em
/// DM Mono no tamanho de card ([valueSize], 24; os centavos menores pelo
/// [SsAmount]), a variação ([delta], colorida pelo sentido) com [hint] e o
/// minigráfico opcional ([spark]) na base. [onTap] faz o card todo tocável.
/// Para o número de herói use o [SsStatCard]/[SsAuroraCard]; vários lado a
/// lado numa faixa, o KpiStrip do web. Web: `Ss::KpiCardComponent`.
class SsKpiCard extends StatelessWidget {
  const SsKpiCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.tone,
    this.caption,
    this.delta,
    this.hint,
    this.spark,
    this.onTap,
    this.valueSize = 24,
    this.valueTone,
  });

  /// v0.20: o valor no tom (saldo negativo em [SsTone.danger], meta batida em
  /// [SsTone.success]); par do `Ss::KpiCardComponent(value_tone:)`.
  final SsTone? valueTone;

  final String label;
  final String value;
  final IconData? icon;
  final Color? tone;
  final String? caption;
  final SsDelta? delta;
  final String? hint;
  final List<double>? spark;
  final VoidCallback? onTap;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final temSpark = spark != null && spark!.length > 1;
    return Semantics(
      container: true,
      label: [label, value, ?caption].join(', '),
      button: onTap != null,
      child: SsCard(
        onTap: onTap,
        padding: EdgeInsets.fromLTRB(d.cardPad, d.cardPad, d.cardPad, temSpark ? 0 : d.cardPad * .9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: SsCardHeader(title: label, subtitle: caption, icon: icon, tone: tone, titleMaxLines: 2),
            ),
            SizedBox(height: d.gap * .7),
            ExcludeSemantics(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: SsAmount(
                  value,
                  size: d.font(valueSize),
                  countUp: true,
                  roll: true,
                  color: valueTone?.colors(context).text,
                ),
              ),
            ),
            if (delta != null || hint != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  ?delta,
                  if (delta != null && hint != null) const SizedBox(width: 6),
                  if (hint != null)
                    Flexible(
                      child: Text(
                        hint!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.muted, fontSize: AppType.meta),
                      ),
                    ),
                ],
              ),
            ],
            if (temSpark) ...[const SizedBox(height: 8), SsSparkline(spark!, height: 36, color: tone)],
          ],
        ),
      ),
    );
  }
}

/// Um item da [SsRankList].
@immutable
class SsRankItem {
  const SsRankItem({required this.label, required this.value, this.amount, this.share, this.caption, this.onTap});

  final String label;

  /// Valor pronto ("163,6 kWh").
  final String value;

  /// Número da barra (proporcional ao maior da lista). Nulo: sem barra.
  final double? amount;

  /// Fatia ao lado do valor ("41%").
  final String? share;

  /// Linha menor embaixo da barra (custo, detalhe).
  final String? caption;
  final VoidCallback? onTap;
}

/// Lista ranqueada com barra: posição, nome, valor · fatia, a barra
/// proporcional ao maior (o 1º cheio) e uma linha menor opcional. O 1º lugar
/// ganha a posição na cor ([tone], padrão a marca). Vai dentro de um card,
/// com o [SsCardHeader] em cima ("Consumo por aparelho", "Mais vendidos").
/// [numbered] tira a posição. Web: `Ss::RankListComponent` (`.ss-rank`).
class SsRankList extends StatelessWidget {
  const SsRankList({super.key, required this.items, this.tone, this.numbered = true, this.semanticLabel});

  final List<SsRankItem> items;
  final Color? tone;
  final bool numbered;

  /// Nome da lista no leitor de tela (padrão: [SsStrings.ranking]).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final cor = tone ?? c.accent;
    var topo = 0.0;
    for (final i in items) {
      if ((i.amount ?? 0) > topo) topo = i.amount!;
    }
    return Semantics(
      container: true,
      label: semanticLabel ?? SsStrings.of(context).ranking,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (n, it) in items.indexed)
            Padding(
              padding: EdgeInsets.only(top: n == 0 ? 0 : d.gap * .8),
              child: SsReveal(
                index: n,
                child: _LinhaRank(
                  item: it,
                  posicao: numbered ? n + 1 : null,
                  fracao: it.amount == null || topo <= 0 ? null : (it.amount! / topo).clamp(.02, 1.0),
                  cor: cor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LinhaRank extends StatelessWidget {
  const _LinhaRank({required this.item, required this.posicao, required this.fracao, required this.cor});

  final SsRankItem item;
  final int? posicao;
  final double? fracao;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final primeiro = posicao == 1;
    final reduce = reduceMotion(context);
    final linha = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (posicao != null) ...[
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primeiro ? Color.alphaBlend(cor.withValues(alpha: c.isDark ? .26 : .18), c.surface) : c.field,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$posicao',
              style: AppTheme.number(
                context,
                size: AppType.label,
                weight: primeiro ? FontWeight.w800 : FontWeight.w600,
                color: primeiro ? Color.lerp(cor, c.ink, .2) : c.ink2,
              ),
            ),
          ),
          SizedBox(width: d.gap * .8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.ink, fontSize: d.font(AppType.sub), fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text.rich(
                    TextSpan(
                      text: item.value,
                      style: AppTheme.number(context, size: AppType.meta, weight: FontWeight.w500, color: c.ink),
                      children: [
                        if (item.share != null)
                          TextSpan(
                            text: ' · ${item.share}',
                            style: AppTheme.number(context, size: AppType.meta, color: c.muted),
                          ),
                      ],
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
              if (fracao != null) ...[
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Container(
                    height: 6,
                    color: c.field,
                    alignment: AlignmentDirectional.centerStart,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: reduce ? fracao! : 0, end: fracao!),
                      duration: reduce ? Duration.zero : const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => FractionallySizedBox(
                        widthFactor: v,
                        heightFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(AppRadius.pill)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (item.caption != null)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    item.caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.number(context, size: AppType.label, color: c.muted),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    final rotulo = [if (posicao != null) '$posicao.', item.label, item.value, ?item.share, ?item.caption].join(' ');
    return Semantics(
      label: rotulo,
      button: item.onTap != null,
      excludeSemantics: true,
      child: item.onTap == null ? linha : SsPressable(onTap: item.onTap, child: linha),
    );
  }
}
