// v1.13.0 "confiança na IA e suíte": os apps da suíte que a conta usa e os que ela ainda não conhece (par do
// Ss::SuiteSwitcherComponent). O pacote não sabe quais produtos existem: a lista vem do app (da API de licenças).
// No app, abre do menu lateral ([SsSuiteSwitcher.section]) ou numa folha ([showSsSuiteSwitcher]).
import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';
import '../density.dart';
import '../format.dart';
import '../ss_badge.dart';
import '../ss_button.dart';
import '../ss_list.dart';
import '../ss_sheet.dart';
import '../ss_strings.dart';
import '../v27/side_menu.dart';
import 'strings.dart';

/// Um produto da suíte. [color] é dado (a marca do produto, vinda da API: `ssColorFromHex`), nunca estilo do app.
class SsSuiteProduct {
  const SsSuiteProduct({
    required this.id,
    required this.name,
    required this.icon,
    this.color,
    this.lastUsedAt,
    this.badge = 0,
    this.active = true,
    this.current = false,
    this.description,
    this.onOpen,
    this.onDiscover,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color? color;
  final DateTime? lastUsedAt;

  /// Avisos não lidos lá.
  final int badge;

  /// A conta usa (falso: vai para "Conheça também").
  final bool active;

  /// É este app ("Você está aqui").
  final bool current;

  /// Uma linha do que o produto faz (para os que a conta não usa).
  final String? description;
  final VoidCallback? onOpen;
  final VoidCallback? onDiscover;
}

/// A lista dos apps da suíte: "Seus apps" (ícone na cor do produto, nome, último acesso, selo de avisos; o atual
/// marcado) e "Conheça também" com "Conhecer".
///
/// `SsSuiteSwitcher(products: [SsSuiteProduct(id: 'vendas', name: 'Minhas Vendas', icon: Icons.storefront, color: ssColorFromHex(p.cor), lastUsedAt: p.usadoEm, badge: p.avisos, onOpen: () => abrir(p))])`
class SsSuiteSwitcher extends StatelessWidget {
  const SsSuiteSwitcher({super.key, required this.products, this.now});

  final List<SsSuiteProduct> products;

  /// O "agora" do último acesso (teste e catálogo).
  final DateTime? now;

  /// A seção "Apps da suíte" do [SsSideMenu]: os que a conta usa (menos o atual), com o último acesso e o selo, e
  /// "Conhecer" com a contagem dos outros (abre o [onDiscover], que costuma ser o [showSsSuiteSwitcher]).
  static SsSideMenuSection section(
    BuildContext context, {
    required List<SsSuiteProduct> products,
    VoidCallback? onDiscover,
    DateTime? now,
  }) {
    final t = SsTrustStrings.of(context);
    final s = SsStrings.of(context);
    final others = products.where((p) => !p.active).length;
    return SsSideMenuSection([
      for (final p in products)
        if (p.active && !p.current)
          SsSideMenuItem(
            p.icon,
            p.name,
            subtitle: _used(p, t, s, now),
            onTap: p.onOpen,
            badge: p.badge > 0 ? p.badge : null,
            external: true,
          ),
      if (others > 0 && onDiscover != null)
        SsSideMenuItem(Icons.apps_rounded, t.suiteDiscover, onTap: onDiscover, badgeLabel: '$others'),
    ], title: t.suiteTitle);
  }

  static String _used(SsSuiteProduct p, SsTrustStrings t, SsStrings s, DateTime? now) {
    if (p.current) return t.suiteCurrent;
    if (p.lastUsedAt == null) return t.suiteNever;
    return SsTrustStrings.fill(t.suiteUsed, {'ago': timeAgo(p.lastUsedAt, now: now, strings: s)});
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final t = SsTrustStrings.of(context);
    final s = SsStrings.of(context);
    final mine = [
      for (final p in products)
        if (p.active) p,
    ];
    final others = [
      for (final p in products)
        if (!p.active) p,
    ];
    Widget heading(String text) => Padding(
      padding: EdgeInsets.only(top: d.space(12), bottom: d.space(4)),
      child: Semantics(
        header: true,
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: AppType.label,
            fontWeight: FontWeight.w800,
            letterSpacing: AppType.trackingCaps,
            color: c.muted,
          ),
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (mine.isNotEmpty) ...[
          heading(t.suiteYours),
          for (final p in mine)
            SsListItem(
              leading: SsIconTile(p.icon, tone: p.color ?? c.accent, filled: p.current),
              title: p.name,
              subtitle: _used(p, t, s, now),
              trailing: p.badge > 0
                  ? Semantics(
                      label: p.badge == 1 ? t.suiteBadgeOne : SsTrustStrings.fill(t.suiteBadge, {'count': p.badge}),
                      excludeSemantics: true,
                      child: SsBadge(p.badge > 99 ? '99+' : '${p.badge}', variant: SsBadgeVariant.danger, solid: true),
                    )
                  : null,
              onTap: p.current ? null : p.onOpen,
            ),
        ],
        if (others.isNotEmpty) ...[
          heading(t.suiteDiscover),
          for (final p in others)
            SsListItem(
              leading: SsIconTile(p.icon, tone: p.color ?? c.muted),
              title: p.name,
              subtitle: p.description,
              trailing: p.onDiscover == null
                  ? null
                  : SsButton.text(label: t.suiteDiscoverAction, onPressed: p.onDiscover),
            ),
        ],
      ],
    );
  }
}

/// Abre os apps da suíte numa folha.
Future<void> showSsSuiteSwitcher(BuildContext context, {required List<SsSuiteProduct> products, DateTime? now}) =>
    showSsSheet<void>(
      context,
      title: SsTrustStrings.of(context).suiteTitle,
      icon: Icons.apps_rounded,
      child: SsSuiteSwitcher(products: products, now: now),
    );
