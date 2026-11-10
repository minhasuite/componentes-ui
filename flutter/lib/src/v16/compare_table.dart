// v0.16: tabela de comparação (par do Ss::CompareTableComponent da gem).
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../density.dart';
import '../ss_strings.dart';

/// Uma coluna do [SsCompareTable] (plano, fornecedor, destino): nome, preço
/// opcional embaixo e [recommended] (fita "Recomendado", fundo e topo na marca).
@immutable
class SsComparePlan {
  const SsComparePlan(this.name, {this.price, this.recommended = false});

  final String name;
  final String? price;
  final bool recommended;
}

/// Uma linha do [SsCompareTable]: rótulo e um valor por coluna. `true` vira
/// ✓ (incluído), `false`/`null` vira — (não incluído), o resto é texto (em DM
/// Mono com [mono]). [best] destaca em verde a célula dessa coluna (o menor
/// total, o mais rápido).
@immutable
class SsCompareFeature {
  const SsCompareFeature(this.label, this.values, {this.best, this.mono = true});

  final String label;
  final List<Object?> values;
  final int? best;
  final bool mono;
}

/// Comparação lado a lado (planos, fornecedores, destinos) com a mesma API e
/// o mesmo desenho do `Ss::CompareTableComponent` da gem: coluna
/// recomendada destacada, ✓/— por linha (ou o texto do valor), cabeçalho
/// acima das linhas e rolagem de lado quando não cabe ([columnWidth] por
/// coluna). [caption] é o título para o leitor de tela.
///
/// ```dart
/// SsCompareTable(caption: 'Planos',
///   plans: [SsComparePlan('Grátis', price: r'R$ 0'), SsComparePlan('Pro', price: r'R$ 19,90/mês', recommended: true)],
///   features: [SsCompareFeature('Lançamentos', ['50/mês', 'Ilimitado']), SsCompareFeature('IA', [false, true])])
/// ```
class SsCompareTable extends StatelessWidget {
  const SsCompareTable({
    super.key,
    required this.plans,
    required this.features,
    required this.caption,
    this.columnWidth = 132,
    this.labelWidth = 132,
  });

  final List<SsComparePlan> plans;
  final List<SsCompareFeature> features;
  final String caption;
  final double columnWidth;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    final rec = c.accent.withValues(alpha: c.isDark ? .12 : .07);
    final pad = EdgeInsets.symmetric(horizontal: d.space(10), vertical: d.space(10));

    Widget celula({required Widget child, double? width, bool destaque = false, Alignment align = Alignment.center}) =>
        Container(
          width: width ?? columnWidth,
          padding: pad,
          alignment: align,
          color: destaque ? rec : null,
          child: child,
        );

    Widget valor(SsCompareFeature f, int i) {
      final v = i < f.values.length ? f.values[i] : null;
      if (v == true) {
        return Semantics(
          label: s.included,
          excludeSemantics: true,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: AppColors.successSoft, shape: BoxShape.circle),
            child: Icon(Icons.check_rounded, size: 16, color: c.successText),
          ),
        );
      }
      if (v == false || v == null) {
        return Semantics(
          label: s.notIncluded,
          excludeSemantics: true,
          child: Text(
            '—',
            style: TextStyle(color: c.muted, fontSize: d.font(AppType.sub)),
          ),
        );
      }
      final best = f.best == i;
      final estilo = f.mono
          ? AppTheme.number(
              context,
              size: d.font(AppType.sub),
              weight: best ? FontWeight.w700 : FontWeight.w500,
              color: best ? c.successText : c.ink,
            )
          : TextStyle(
              color: best ? c.successText : c.ink2,
              fontSize: d.font(AppType.sub),
              fontWeight: best ? FontWeight.w800 : FontWeight.w500,
            );
      return Text('$v', maxLines: 3, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: estilo);
    }

    final cabeca = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(width: labelWidth),
        for (final p in plans)
          Container(
            width: columnWidth,
            padding: pad,
            decoration: BoxDecoration(
              color: p.recommended ? rec : null,
              border: p.recommended ? Border(top: BorderSide(color: c.accent, width: 3)) : null,
            ),
            child: Semantics(
              header: true,
              child: Column(
                children: [
                  if (p.recommended)
                    Container(
                      margin: EdgeInsets.only(bottom: d.space(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: c.accentSolid,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        s.recommended,
                        style: const TextStyle(
                          color: AppColors.onDark,
                          fontSize: AppType.micro,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: p.recommended ? c.accentText : c.ink,
                      fontSize: d.font(AppType.set),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (p.price != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        p.price!,
                        textAlign: TextAlign.center,
                        style: AppTheme.number(context, size: d.font(AppType.meta), color: c.muted),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );

    final linhas = [
      for (final (k, f) in features.indexed)
        DecoratedBox(
          decoration: BoxDecoration(
            border: k == features.length - 1 ? null : Border(bottom: BorderSide(color: c.line)),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                celula(
                  width: labelWidth,
                  align: Alignment.centerLeft,
                  child: Text(
                    f.label,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.ink2, fontSize: d.font(AppType.sub), fontWeight: FontWeight.w600),
                  ),
                ),
                for (var i = 0; i < plans.length; i++) celula(destaque: plans[i].recommended, child: valor(f, i)),
              ],
            ),
          ),
        ),
    ];

    return Semantics(
      label: caption,
      container: true,
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(d.radiusCard),
          border: c.isDark ? Border.all(color: c.line) : null,
          boxShadow: c.isDark ? null : AppShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [cabeca, ...linhas],
          ),
        ),
      ),
    );
  }
}
