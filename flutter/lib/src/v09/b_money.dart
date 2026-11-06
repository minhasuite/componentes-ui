// v0.9 (lote b): dinheiro — pontos e nível, quadro de cotações.
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../density.dart';
import '../format.dart';
import '../motion.dart';
import '../motion_view.dart';
import '../ss_badge.dart';
import '../ss_list.dart';
import '../ss_progress.dart';
import '../ss_stat.dart';
import '../ss_strings.dart';

/// Uma linha do [SsLevelCard]: onde gastou, quanto e quantos pontos ganhou.
class SsLevelEntry {
  const SsLevelEntry(this.title, this.cents, this.points, {this.icon = Icons.receipt_long_outlined});
  final String title;
  final int cents;
  final int points;
  final IconData icon;
}

/// Programa de pontos: o saldo em número grande (conta quando entra na tela),
/// o nível num selo, a barra até o próximo nível (enche quando aparece) e a
/// lista "gastou → ganhou +n" (em cascata, com mola).
class SsLevelCard extends StatelessWidget {
  const SsLevelCard({
    super.key,
    required this.points,
    required this.level,
    this.nextLevel,
    this.progress = 0,
    this.pointsToNext,
    this.entries = const [],
    this.title,
  });

  final int points;
  final String level;
  final String? nextLevel;

  /// 0 a 1 até o próximo nível.
  final double progress;
  final int? pointsToNext;
  final List<SsLevelEntry> entries;

  /// Padrão: [SsStrings.yourPoints].
  final String? title;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = SsStrings.of(context);
    final f = SsFormats.of(context);
    String mil(int n) => f.integer(n);
    final d = SsDensity.of(context);
    return Container(
      padding: EdgeInsets.all(d.cardPad + 2),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
        border: c.isDark ? Border.all(color: c.line) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title ?? s.yourPoints,
                  style: TextStyle(color: c.muted, fontSize: AppType.sub, fontWeight: FontWeight.w700),
                ),
              ),
              SsBadge(level, icon: Icons.workspace_premium_rounded),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            label: s.pointsCount(mil(points)),
            excludeSemantics: true,
            // Conta quando o card entra na tela (não ao montar, fora dela).
            child: SsTweenInView(
              end: points.toDouble(),
              builder: (context, v, _) => Text.rich(
                TextSpan(
                  text: mil(v.round()),
                  children: [
                    TextSpan(
                      text: s.pointsShort,
                      style: AppTheme.number(context, size: AppType.md, color: c.muted),
                    ),
                  ],
                ),
                style: AppTheme.number(context, size: 40, weight: FontWeight.w500, color: c.ink),
              ),
            ),
          ),
          if (nextLevel != null) ...[
            const SizedBox(height: 16),
            SsProgress(progress.clamp(0.0, 1.0)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    pointsToNext == null ? s.towardsLevel(nextLevel!) : s.pointsToLevel(mil(pointsToNext!), nextLevel!),
                    style: TextStyle(color: c.ink2, fontSize: AppType.meta, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${(progress.clamp(0.0, 1.0) * 100).round()}%',
                  style: AppTheme.number(context, size: AppType.meta, color: c.muted),
                ),
              ],
            ),
          ],
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(color: c.line, height: 1),
            const SizedBox(height: 4),
            for (var i = 0; i < entries.length; i++)
              SsInViewReveal(
                index: i,
                child: Semantics(
                  label: s.spentEarned(entries[i].title, money(entries[i].cents, f), entries[i].points),
                  excludeSemantics: true,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: d.rowPadV - 2),
                    child: Row(
                      children: [
                        SsIconTile(entries[i].icon, size: d.iconTile - 6),
                        SizedBox(width: d.gap),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entries[i].title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: c.ink, fontSize: AppType.set, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                money(entries[i].cents, f),
                                style: AppTheme.number(context, size: AppType.meta, color: c.muted),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_rounded, size: 16, color: c.muted2),
                        const SizedBox(width: 8),
                        Text(
                          '+${mil(entries[i].points)}',
                          style: AppTheme.number(context, size: AppType.body, color: c.successText),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Uma linha do [SsPriceBoard]. Preços vêm prontos (moeda, cripto, grão).
class SsPriceRow {
  const SsPriceRow({
    required this.name,
    required this.buy,
    required this.sell,
    this.code,
    this.icon,
    this.leading,
    this.change,
    this.goodWhenUp = true,
  });

  final String name;
  final String buy;
  final String sell;

  /// Sigla embaixo do nome ("USD").
  final String? code;
  final IconData? icon;
  final Widget? leading;

  /// Variação em % (positiva sobe).
  final double? change;

  /// Para quem compra, subir é ruim: falso pinta a alta de vermelho.
  final bool goodWhenUp;
}

/// Quadro de cotações compra/venda: ícone, nome e duas colunas em DM Mono,
/// a variação colorida pelo sentido (bom ou ruim, não pelo sinal) e uma linha
/// destacada ([highlighted]). Tocar numa linha chama [onTap]. Preço e
/// variação que mudam rolam na vertical (para cima quando subiram).
class SsPriceBoard extends StatelessWidget {
  const SsPriceBoard({super.key, required this.rows, this.highlighted, this.onTap, this.buyLabel, this.sellLabel});

  final List<SsPriceRow> rows;
  final int? highlighted;
  final ValueChanged<int>? onTap;

  /// Padrões: [SsStrings.buy] e [SsStrings.sell].
  final String? buyLabel, sellLabel;

  /// Sem [formats], com vírgula decimal.
  static String pct(double v, [SsFormats? formats]) {
    final s = v.abs().toStringAsFixed(2).replaceAll('.', (formats ?? SsFormats.brl).decimalSeparator);
    return '${v > 0 ? '+' : (v < 0 ? '-' : '')}$s%';
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final cab = TextStyle(color: c.muted, fontSize: AppType.label, fontWeight: FontWeight.w800, letterSpacing: .8);
    final s = SsStrings.of(context);
    final d = SsDensity.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(d.padX - 4, 0, d.padX - 4, 6),
          child: Row(
            children: [
              Expanded(child: Text(s.asset, style: cab)),
              SizedBox(
                width: 80,
                child: Text((buyLabel ?? s.buy).toUpperCase(), textAlign: TextAlign.right, style: cab),
              ),
              SizedBox(
                width: 80,
                child: Text((sellLabel ?? s.sell).toUpperCase(), textAlign: TextAlign.right, style: cab),
              ),
            ],
          ),
        ),
        for (var i = 0; i < rows.length; i++) _linha(context, c, i),
      ],
    );
  }

  Widget _linha(BuildContext context, SsColors c, int i) {
    final r = rows[i];
    final on = i == highlighted;
    final ch = r.change;
    final bom = ch == null || ch == 0 ? null : (ch > 0) == r.goodWhenUp;
    final corCh = bom == null ? c.muted : (bom ? c.successText : c.dangerText);
    final s = SsStrings.of(context);
    final f = SsFormats.of(context);
    return Semantics(
      button: onTap != null,
      selected: on,
      label:
          '${r.name}: ${buyLabel ?? s.buy} ${r.buy}, ${sellLabel ?? s.sell} ${r.sell}'
          '${ch == null ? '' : s.changeOf(pct(ch, f))}',
      excludeSemantics: true,
      child: SsPressable(
        onTap: onTap == null ? null : () => onTap!(i),
        child: AnimatedContainer(
          duration: SsMotion.fast,
          padding: EdgeInsets.symmetric(
            horizontal: SsDensity.of(context).padX - 6,
            vertical: SsDensity.of(context).rowPadV,
          ),
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: on ? c.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
          child: Row(
            children: [
              r.leading ?? SsIconTile(r.icon ?? Icons.currency_exchange_rounded, size: 38, circle: true),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.ink, fontSize: AppType.set, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (r.code != null)
                          Flexible(
                            child: Text(
                              r.code!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: c.muted, fontSize: AppType.meta, fontWeight: FontWeight.w600),
                            ),
                          ),
                        if (r.code != null && ch != null) const SizedBox(width: 6),
                        if (ch != null) ...[
                          Icon(
                            ch > 0
                                ? Icons.arrow_drop_up_rounded
                                : (ch < 0 ? Icons.arrow_drop_down_rounded : Icons.remove_rounded),
                            size: 16,
                            color: corCh,
                          ),
                          Flexible(
                            child: SsRollSwitcher(
                              value: ch,
                              child: Text(
                                pct(ch, f),
                                maxLines: 1,
                                style: AppTheme.number(context, size: AppType.meta, color: corCh),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 80,
                child: SsRollSwitcher(
                  value: SsAmount.parse(r.buy) ?? r.buy,
                  alignment: Alignment.centerRight,
                  child: Text(
                    r.buy,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    style: AppTheme.number(context, size: AppType.set, color: c.ink),
                  ),
                ),
              ),
              SizedBox(
                width: 80,
                child: SsRollSwitcher(
                  value: SsAmount.parse(r.sell) ?? r.sell,
                  alignment: Alignment.centerRight,
                  child: Text(
                    r.sell,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    style: AppTheme.number(context, size: AppType.set, color: on ? c.accentText : c.ink),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
