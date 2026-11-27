// v1.9 · paridade_app: lista + detalhe (par do Ss::SplitViewComponent) e a casca
// que troca a barra de baixo pelo trilho lateral em tela larga.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../app_theme.dart';
import '../../density.dart';
import '../../motion.dart';
import '../../ss_nav_bar.dart';
import '../../ss_strings.dart';
import '../../v09/a_nav.dart' show SsSideRail;
import '../../v27/side_menu.dart' show SsNavScaffold, SsSideMenu;

/// Largura a partir da qual a tela é "larga" (o `expanded` do Material).
const ssWideBreakpoint = 840.0;

/// Lista e detalhe: em tela larga (≥ [breakpoint]) lado a lado, a lista num
/// cartão de [listWidth] e o detalhe ao lado (ou o [empty], "Escolha um item
/// da lista."); no celular empilha: sem [detail] mostra a lista, com
/// [detail] o detalhe vira a tela, com "Voltar" no topo e o voltar do sistema
/// chamando [onBack]. Quem escolhe o item é o app (guarda o selecionado e
/// monta o [detail]; nulo = nada escolhido). A troca do detalhe sobe suave.
/// Par do `Ss::SplitViewComponent` (lá o detalhe é um turbo-frame e a
/// quebra é 1024).
///
/// ```dart
/// SsSplitView(
///   list: ListView(children: [for (final p in pedidos) SsListRow(…, selected: p == atual, onTap: () => setState(() => atual = p))]),
///   detail: atual == null ? null : PedidoDetalhe(atual!),
///   onBack: () => setState(() => atual = null),
/// )
/// ```
class SsSplitView extends StatelessWidget {
  const SsSplitView({
    super.key,
    required this.list,
    required this.onBack,
    this.detail,
    this.empty,
    this.breakpoint = ssWideBreakpoint,
    this.listWidth = 352,
    this.backLabel,
    this.listLabel,
  });

  final Widget list;
  final Widget? detail;

  /// Sem item escolhido, em tela larga. Padrão: [SsStrings.splitEmpty].
  final Widget? empty;

  /// Voltar do detalhe para a lista no celular (limpe o selecionado).
  final VoidCallback onBack;
  final double breakpoint;
  final double listWidth;

  /// Padrão: [SsStrings.back].
  final String? backLabel;

  /// Nome da lista para o leitor de tela. Padrão: [SsStrings.splitList].
  final String? listLabel;

  /// Lado a lado nesta largura?
  static bool isWide(double width, [double breakpoint = ssWideBreakpoint]) => width >= breakpoint;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    final dur = reduceMotion(context) ? Duration.zero : SsMotion.base;

    Widget cartao(Widget child) => Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(d.radiusCard),
        border: Border.all(color: c.line),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );

    Widget sobe(Widget child, Animation<double> a) => FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, .03), end: Offset.zero).animate(a),
        child: child,
      ),
    );

    final lista = Semantics(container: true, label: listLabel ?? s.splitList, child: list);

    return LayoutBuilder(
      builder: (context, k) {
        if (isWide(k.maxWidth, breakpoint)) {
          final vazio =
              empty ??
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    s.splitEmpty,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: AppType.set, color: c.muted),
                  ),
                ),
              );
          return Padding(
            padding: EdgeInsets.all(d.gap),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: math.min(listWidth, k.maxWidth * .4), child: cartao(lista)),
                SizedBox(width: d.gap * 1.33),
                Expanded(
                  child: cartao(
                    Semantics(
                      liveRegion: true,
                      child: AnimatedSwitcher(
                        duration: dur,
                        transitionBuilder: sobe,
                        child: KeyedSubtree(key: ValueKey(detail?.key ?? detail.runtimeType), child: detail ?? vazio),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        final det = detail;
        return PopScope(
          canPop: det == null,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && det != null) onBack();
          },
          child: AnimatedSwitcher(
            duration: dur,
            transitionBuilder: sobe,
            child: det == null
                ? KeyedSubtree(key: const ValueKey('lista'), child: lista)
                : Column(
                    key: const ValueKey('detalhe'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(d.padX - 12, 4, 0, 0),
                          child: TextButton.icon(
                            onPressed: onBack,
                            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                            icon: Icon(Icons.chevron_left_rounded, color: c.accentText),
                            label: Text(
                              backLabel ?? s.back,
                              style: TextStyle(color: c.accentText, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                      Expanded(child: Semantics(liveRegion: true, child: det)),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

/// Casca adaptável das abas: no celular é o [SsNavScaffold] com a
/// [SsNavBar] embaixo (e o menu lateral, se houver); a partir de
/// [breakpoint] (840) a barra de baixo vira o [SsSideRail] à esquerda, com
/// as mesmas abas, o mesmo [currentIndex] e o voltar do sistema levando à 1ª
/// aba. Use com [SsSplitView] no corpo para lista + detalhe no tablet.
///
/// `SsAdaptiveScaffold(items: abas, currentIndex: i, onTap: (v) => setState(() => i = v), body: telas[i])`
class SsAdaptiveScaffold extends StatelessWidget {
  const SsAdaptiveScaffold({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.body,
    this.sideMenu,
    this.floatingActionButton,
    this.railHeader,
    this.railFooter,
    this.breakpoint = ssWideBreakpoint,
    this.backToFirstTab = true,
  });

  final List<SsNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Widget body;

  /// Só no celular (no trilho, use [railHeader] para o botão do menu).
  final SsSideMenu? sideMenu;
  final Widget? floatingActionButton;

  /// Topo e rodapé do trilho (logo, menu, conta).
  final Widget? railHeader;
  final Widget? railFooter;
  final double breakpoint;
  final bool backToFirstTab;

  @override
  Widget build(BuildContext context) {
    final largo = MediaQuery.sizeOf(context).width >= breakpoint;
    if (!largo) {
      return SsNavScaffold(
        body: body,
        navBar: SsNavBar(items: items, currentIndex: currentIndex, onTap: onTap),
        sideMenu: sideMenu,
        backToFirstTab: backToFirstTab,
        floatingActionButton: floatingActionButton,
      );
    }
    final primeira = !backToFirstTab || currentIndex == 0;
    return PopScope(
      canPop: primeira,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !primeira) onTap(0);
      },
      child: Scaffold(
        floatingActionButton: floatingActionButton,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // v1.9.3: o trilho pinta até o topo (sem a faixa clara do SafeArea sob a barra de status).
            SsSideRail(
              items: items,
              currentIndex: currentIndex,
              onTap: onTap,
              header: railHeader,
              footer: railFooter,
              edgeToEdge: true,
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
