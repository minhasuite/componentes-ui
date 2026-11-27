// v0.27: menu lateral que abre arrastando da borda esquerda, com a dica que
// "espia" ao abrir o app, e a casca única das abas ([SsNavScaffold]).
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../app_theme.dart';
import '../motion.dart';
import '../ss_badge.dart';
import '../ss_nav_bar.dart';
import '../ss_strings.dart';
import '../version.dart';
import '../v1110/platform.dart';
import '../v19/paridade_web/hide_on_scroll.dart';
import '../v19/paridade_web/side_search.dart';

/// Uma linha do [SsSideMenu].
class SsSideMenuItem {
  const SsSideMenuItem(
    this.icon,
    this.label, {
    this.activeIcon,
    this.subtitle,
    this.onTap,
    this.selected = false,
    this.badge,
    this.danger = false,
    this.external = false,
    this.badgeLabel,
  });

  /// Contornado; [activeIcon] (cheio) entra quando [selected].
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final String? subtitle;

  /// O menu fecha sozinho depois do toque.
  final VoidCallback? onTap;

  /// Onde a pessoa está (fundo na marca suave, ícone cheio, negrito).
  final bool selected;

  /// Contagem à direita (0 ou nulo some; acima de 99 vira "99+").
  final int? badge;

  /// Vermelho: só para o que apaga ou sai.
  final bool danger;

  /// v1.6: abre fora do app (navegador ou aba personalizada): ícone de saída à
  /// direita e "abre no navegador" para o leitor de tela. O par do item
  /// `external: true` do menu do web.
  final bool external;

  /// v1.6: selo em texto na cor da marca (ex. "2 novas"); ganha do [badge] e
  /// do ícone de saída. Novidade, não alerta: por isso não é o vermelho.
  final String? badgeLabel;
}

/// Grupo de linhas do [SsSideMenu], com título pequeno opcional.
class SsSideMenuSection {
  const SsSideMenuSection(this.items, {this.title});

  final String? title;
  final List<SsSideMenuItem> items;
}

/// Conteúdo do menu lateral: cabeçalho (cartão na cor da marca com o [icon]
/// ou o [leading], o [title] na fonte de exibição e o [subtitle]), as seções,
/// o [footer] e, no pé, a versão do app ([version]) e a do componentes_ui num
/// tom apagado. Vai no [SsSideMenuHost.menu] (ou no `sideMenu:` do
/// [SsNavScaffold]). Dentro do host, as linhas entram em cascata conforme o
/// painel abre (as de baixo chegam por último).
class SsSideMenu extends StatelessWidget {
  const SsSideMenu({
    super.key,
    this.sections = const [],
    this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.footer,
    this.version,
    this.search,
  });

  /// v1.9: a linha "Buscar" no topo do menu, que abre o [showSsCommandPalette] com as telas, as ações e os
  /// registros do app ([SsSideMenuSearch.records]); no [SsSideMenuHost] (e no [SsNavScaffold]) o Ctrl+K
  /// abre a mesma busca. Par do Ctrl+K do `Ss::AppShellComponent`.
  final SsSideMenuSearch? search;

  /// Nome do app (fonte de exibição, no cartão da marca).
  final String? title;

  /// Linha de baixo do cartão (a conta: nome ou e-mail).
  final String? subtitle;

  /// v1.1: ícone do app num quadrado translúcido no cartão (ignorado com [leading]).
  final IconData? icon;

  /// Marca do app ou avatar no lugar do [icon].
  final Widget? leading;
  final List<SsSideMenuSection> sections;

  /// Fica no pé do painel, acima das versões (ex.: Sair).
  final Widget? footer;

  /// v1.1: versão do app (ex. `1.4.0 (123)`), no pé ao lado da do componentes_ui.
  final String? version;

  /// Uma cópia com [sections] na frente das seções atuais.
  SsSideMenu _withLeading(List<SsSideMenuSection> first) => SsSideMenu(
    key: key,
    title: title,
    subtitle: subtitle,
    icon: icon,
    leading: leading,
    footer: footer,
    version: version,
    search: search,
    sections: [...first, ...sections],
  );

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final scope = _SsSideMenuScope.maybeOf(context);
    final progress = scope?.progress ?? kAlwaysCompleteAnimation;
    final pad = MediaQuery.paddingOf(context);
    var row = 0;
    final children = <Widget>[];
    final busca = search;
    if (busca != null) {
      children.add(
        _Cascade(
          progress: progress,
          index: row++,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
            child: Builder(
              builder: (context) => SsSideSearchRow(
                search: busca,
                onOpen: () {
                  final host = SsSideMenuHost.maybeOf(context);
                  host != null ? host.openSearch() : busca.open(context);
                },
              ),
            ),
          ),
        ),
      );
    }
    for (final s in sections) {
      if (s.title != null) {
        children.add(
          _Cascade(
            progress: progress,
            index: row++,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
              child: Text(
                s.title!.toUpperCase(),
                style: TextStyle(
                  color: c.muted,
                  fontSize: AppType.label,
                  fontWeight: FontWeight.w800,
                  letterSpacing: AppType.trackingCaps,
                ),
              ),
            ),
          ),
        );
      } else if (children.isNotEmpty) {
        children.add(const SizedBox(height: 12));
      }
      for (final item in s.items) {
        children.add(
          _Cascade(
            progress: progress,
            index: row++,
            child: _SideRow(item: item, onDone: scope?.close),
          ),
        );
      }
    }
    final versoes = [
      if (version != null && version!.isNotEmpty) '${title ?? ''} $version'.trim(),
      'componentes_ui $ssComponentesUiVersion',
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null || leading != null || icon != null)
          _Cascade(
            progress: progress,
            index: 0,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, pad.top + 12, 12, 6),
              child: _Cabecalho(title: title, subtitle: subtitle, icon: icon, leading: leading),
            ),
          )
        else
          SizedBox(height: pad.top + 12),
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(10, 4, 10, 8), children: children),
        ),
        if (footer != null) Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 0), child: footer),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, pad.bottom + 14),
          child: Text(
            versoes,
            maxLines: 2,
            style: TextStyle(color: c.muted2, fontSize: AppType.label, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// O cartão do topo do menu: gradiente da marca, o ícone do app num quadrado
/// translúcido, o nome na fonte de exibição e a conta embaixo. Um círculo
/// claro no canto dá o acabamento (decoração, fora do leitor de tela).
class _Cabecalho extends StatelessWidget {
  const _Cabecalho({this.title, this.subtitle, this.icon, this.leading});

  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final marca =
        leading ??
        (icon == null
            ? null
            : Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.onDark.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.onDark.withValues(alpha: .28)),
                ),
                child: Icon(icon, color: AppColors.onDark, size: 26),
              ));
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: c.gradient4,
        // Sem sombra: a sombra tingida formava uma faixa escura embaixo do cartão.
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -38,
            top: -46,
            child: ExcludeSemantics(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.onDark.withValues(alpha: .10)),
              ),
            ),
          ),
          Positioned(
            right: 34,
            bottom: -30,
            child: ExcludeSemantics(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.onDark.withValues(alpha: .07)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (marca != null) ...[marca, const SizedBox(height: 14)],
                if (title != null)
                  Text(
                    title!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.display(context, size: 30, color: AppColors.onDark),
                  ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.onDark.withValues(alpha: .86),
                      fontSize: AppType.sub,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Linha que entra em cascata: com o painel abrindo, as de baixo ficam um
/// pouco para trás e mais apagadas, e alcançam as de cima no fim.
class _Cascade extends StatelessWidget {
  const _Cascade({required this.progress, required this.index, required this.child});

  final Animation<double> progress;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: progress,
    child: child,
    builder: (context, child) {
      final t = progress.value.clamp(0.0, 1.0);
      final i = math.min(index, 8);
      // Atraso pequeno (no máximo uns 12 px na fresta da dica): os ícones
      // continuam à vista e só as linhas de baixo chegam por último.
      final lag = (1 - t) * (1 - t) * (3 + 3 * i);
      final opacity = ((t - .02 * i) / .2).clamp(.35, 1.0);
      return Opacity(
        opacity: opacity,
        child: Transform.translate(offset: Offset(-lag, 0), child: child),
      );
    },
  );
}

class _SideRow extends StatelessWidget {
  const _SideRow({required this.item, this.onDone});

  final SsSideMenuItem item;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final sel = item.selected;
    final fg = item.danger ? c.dangerText : (sel ? c.accentText : c.ink);
    final n = item.badge ?? 0;
    final tag = item.badgeLabel;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Semantics(
        button: true,
        selected: sel,
        hint: item.external ? SsStrings.of(context).opensOutside : null,
        child: Material(
          color: sel ? c.accentSoft : AppColors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.field),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.field),
            onTap: item.onTap == null
                ? null
                : () {
                    onDone?.call();
                    item.onTap!();
                  },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      sel ? (item.activeIcon ?? item.icon) : item.icon,
                      size: 22,
                      color: item.danger ? c.dangerText : (sel ? c.accentText : c.ink2),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: fg,
                              fontSize: AppType.body,
                              fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                          if (item.subtitle != null)
                            Text(
                              item.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: c.muted, fontSize: AppType.meta),
                            ),
                        ],
                      ),
                    ),
                    if (tag != null) ...[
                      const SizedBox(width: 8),
                      SsBadge(tag),
                    ] else if (n > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(99)),
                        child: Text(
                          n > 99 ? '99+' : '$n',
                          style: AppTheme.number(context)
                              .copyWith(color: AppColors.onDark, fontSize: AppType.label, fontWeight: FontWeight.w800),
                        ),
                      ),
                    if (item.external && tag == null && n == 0) ...[
                      const SizedBox(width: 8),
                      ExcludeSemantics(child: Icon(Icons.open_in_new_rounded, size: 18, color: c.muted)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SsSideMenuScope extends InheritedWidget {
  const _SsSideMenuScope({required this.progress, required this.close, required super.child});

  final Animation<double> progress;
  final VoidCallback close;

  static _SsSideMenuScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SsSideMenuScope>();

  @override
  bool updateShouldNotify(_SsSideMenuScope old) => old.progress != progress;
}

/// Menu lateral por cima de [child]: abre arrastando da borda esquerda (ou
/// por [SsSideMenuHostState.open], ex. um botão de menu), fecha arrastando de
/// volta, tocando fora, pelo voltar do sistema ou ao tocar numa linha.
///
/// **Dica ao abrir o app** ([peek]): na primeira vez que o host aparece em
/// cada abertura do app, o painel espia (abre uma fresta com mola mostrando a
/// coluna de ícones), volta, e a borda pisca duas vezes na cor da marca (v1.1:
/// sem a pílula "Arraste para abrir o menu", rápida demais para ler). Não segura o
/// toque: a tela segue usável durante a dica; tocar na fresta abre o menu.
/// Com "reduzir movimento" a dica não roda.
///
/// v1.9.3: **a alça e a faixa de arrastar ficam fora da faixa de gesto do sistema**
/// (`MediaQuery.systemGestureInsets.left`, mais o `padding.left`). No Android com navegação por gestos,
/// o arraste que começa nessa faixa é o "voltar" do sistema e nunca chega ao app: arrastar a alça colada na
/// borda fechava o app na 1ª aba. O Flutter 3.50 não tem como pedir a exclusão do gesto
/// (`View.setSystemGestureExclusionRects` não está no canal da plataforma), então a alça fica logo depois
/// da faixa (a pílula ganha as duas pontas arredondadas) e a faixa de arrastar começa ali. Tocar na alça
/// abre o menu. Sem gesto do sistema (navegação por botões, iOS, testes) tudo fica colado na borda, como antes.
///
/// v1.11.0 · **iOS**: lá, voltar é arrastar da borda esquerda (o `CupertinoPageTransitionsBuilder` que o
/// [AppTheme.build] liga no iOS), justo onde ficam a alça e a faixa. Então, com [adaptive] e no iOS:
/// - **rota empilhada** (a tela do host foi empilhada por cima de outra, ou um `Navigator` de dentro do
///   [child] pode voltar, ex. o `ShellRoute` do go_router com uma tela aberta): a alça e a faixa somem, e o
///   arrastar da borda é o voltar do sistema. A dica ao abrir não roda. O menu ainda abre por
///   [SsSideMenuHostState.open];
/// - **telas principais** (a raiz, nada para voltar): a alça e a faixa ficam, como no Android.
/// O "pode voltar de dentro" vem da `NavigationNotification` que todo `Navigator` manda ao mudar a pilha
/// (vale o `Navigator` mais recente que avisou). `adaptive: false` (ou o [SsPlatformScope]) deixa a alça
/// sempre, como no Android.
class SsSideMenuHost extends StatefulWidget {
  const SsSideMenuHost({
    super.key,
    required this.menu,
    required this.child,
    this.peek = true,
    this.handleBack = true,
    this.onOpenChanged,
    this.width,
    this.debugHintAt,
    this.handleKey,
    this.adaptive = true,
  });

  /// v1.11.0: no iOS, a alça e a faixa somem em rota empilhada (ver acima). Falso: ficam sempre.
  final bool adaptive;

  /// v1.9.1: chave posta na alça (a pílula da borda e o respiro de toque dela): o alvo de um passo do
  /// [SsTour] que mostra onde abre o menu. Nulo: sem chave.
  final GlobalKey? handleKey;

  /// Nos testes e no catálogo: a dica parada neste instante (0..1 da linha do tempo).
  @visibleForTesting
  final double? debugHintAt;

  /// O painel (quase sempre um [SsSideMenu]).
  final Widget menu;
  final Widget child;

  /// Espia uma vez por abertura do app.
  final bool peek;

  /// Fecha no voltar do sistema (com o menu fechado, o voltar segue normal).
  /// O [SsNavScaffold] desliga e cuida do voltar ele mesmo.
  final bool handleBack;
  final ValueChanged<bool>? onOpenChanged;

  /// Largura do painel (padrão: 84% da tela, até 320).
  final double? width;

  /// Quanto o painel mostra ao espiar (a coluna de ícones).
  static const peekWidth = 76.0;

  /// Largura da faixa da borda que pega o arraste, além do gesto do sistema.
  static const edgeWidth = 20.0;

  static bool _peeked = false;

  /// v1.9.3: x a partir do qual o toque e o arraste chegam ao app na borda esquerda: a faixa de gesto do
  /// sistema (`systemGestureInsets.left`, o "voltar" do Android) mais o recorte da tela (`padding.left`).
  /// A alça e a faixa de arrastar começam aqui.
  static double gestureFreeLeft(MediaQueryData mq) => mq.systemGestureInsets.left + mq.padding.left;

  /// Nos testes: deixa a dica rodar de novo.
  @visibleForTesting
  static void debugResetPeek() => _peeked = false;

  static SsSideMenuHostState? maybeOf(BuildContext context) => context.findAncestorStateOfType<SsSideMenuHostState>();

  @override
  State<SsSideMenuHost> createState() => SsSideMenuHostState();
}

class SsSideMenuHostState extends State<SsSideMenuHost> with TickerProviderStateMixin {
  // Abertura do painel: 0 fechado, 1 aberto. Sem limites: a mola passa um
  // pouco de 1 ao abrir e assenta.
  late final _c = AnimationController.unbounded(vsync: this);

  // Linha do tempo da dica (painel que espia e a borda que pisca).
  late final _hint = AnimationController(vsync: this, duration: _hintTotal);
  static const _hintTotal = Duration(milliseconds: 3600);

  // Fases da dica, em fração de [_hintTotal].
  static const _out = .17; // espia (mola)
  static const _back = .45; // começa a voltar
  static const _closed = .56; // fechou; a borda pisca até o fim

  bool _open = false;
  bool _peeking = false;
  double _w = 300;

  // v1.11.0: um Navigator de dentro do child pode voltar (NavigationNotification) e, no iOS, a alça cede.
  bool _innerCanPop = false;
  bool _yields = false;

  bool get isOpen => _open;

  /// v1.11.0: a alça e a faixa estão fora porque, no iOS, o arrastar da borda é o voltar do sistema.
  bool get yieldsToBack => _yields;

  bool _onNavigation(NavigationNotification n) {
    if (n.canHandlePop != _innerCanPop && mounted) setState(() => _innerCanPop = n.canHandlePop);
    return false;
  }

  double _widthFor(MediaQueryData mq) => widget.width ?? math.min(mq.size.width * .84, 320.0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final at = widget.debugHintAt;
    if (at != null) {
      _w = _widthFor(MediaQuery.of(context));
      _peeking = true;
      _hint.value = at;
      _c.value = _peekPos(at);
    }
  }

  @override
  void initState() {
    super.initState();
    _hint.addListener(_onHint);
    if (widget.peek && widget.debugHintAt == null && !SsSideMenuHost._peeked) {
      SsSideMenuHost._peeked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(const Duration(milliseconds: 900), () {
          if (!mounted || _open || _yields || _c.value != 0 || reduceMotion(context)) return;
          setState(() => _peeking = true);
          _hint.forward(from: 0).whenCompleteOrCancel(() {
            if (mounted && _peeking) setState(() => _peeking = false);
          });
        });
      });
    }
  }

  @override
  void dispose() {
    _hint.dispose();
    _c.dispose();
    super.dispose();
  }

  double get _peekFrac => SsSideMenuHost.peekWidth / _w;

  /// Abertura do painel num instante da dica.
  double _peekPos(double t) {
    final p = _peekFrac;
    if (t <= _out) return p * SsMotion.bounce.transform(t / _out);
    if (t <= _back) {
      // Parado, com duas cutucadas para fora ("pode puxar").
      final f = (t - _out) / (_back - _out);
      return p + 10 / _w * math.pow(math.sin(2 * math.pi * f), 2) * (1 - f);
    }
    if (t <= _closed) return p * (1 - Curves.easeInCubic.transform((t - _back) / (_closed - _back)));
    return 0;
  }

  void _onHint() {
    if (_peeking) _c.value = _peekPos(_hint.value);
  }

  void _stopPeek() {
    if (!_peeking) return;
    _peeking = false;
    _hint.stop();
    _hint.value = 1;
  }

  void _setOpen(bool v) {
    if (_open == v) return;
    setState(() => _open = v);
    widget.onOpenChanged?.call(v);
  }

  void open() {
    _stopPeek();
    _setOpen(true);
    if (reduceMotion(context)) {
      _c.value = 1;
    } else {
      _c.animateTo(1, duration: const Duration(milliseconds: 520), curve: SsMotion.bounce);
    }
  }

  void close() {
    _stopPeek();
    _setOpen(false);
    if (reduceMotion(context)) {
      _c.value = 0;
    } else {
      _c.animateTo(0, duration: SsMotion.medium, curve: Curves.easeOutCubic);
    }
  }

  void toggle() => _open ? close() : open();

  void _dragStart(DragStartDetails _) {
    _stopPeek();
    _c.stop();
    setState(() {});
  }

  void _dragUpdate(DragUpdateDetails d) {
    final was = _c.value;
    _c.value = (_c.value + d.primaryDelta! / _w).clamp(0.0, 1.0);
    if ((was < .5) != (_c.value < .5)) HapticFeedback.selectionClick();
  }

  void _dragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    final abre = v.abs() > 365 ? v > 0 : _c.value > .5;
    if (abre) {
      _open = false; // força o aviso
      open();
    } else {
      _open = true;
      close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = SsStrings.of(context);
    final mq = MediaQuery.of(context);
    _w = _widthFor(mq);
    // v1.9.3: onde começa a área que é do app (depois do gesto de voltar do sistema).
    final inicio = SsSideMenuHost.gestureFreeLeft(mq);
    // v1.11.0: no iOS, em rota empilhada, a borda esquerda é do voltar do sistema.
    final yields =
        SsPlatform.cupertino(context, adaptive: widget.adaptive) &&
        (_innerCanPop || !(ModalRoute.of(context)?.isFirst ?? true));
    _yields = yields;

    Widget host = Stack(
      children: [
        NotificationListener<NavigationNotification>(onNotification: _onNavigation, child: widget.child),
        // Faixa da borda: pega o arraste com o menu fechado. Translúcida: o
        // toque passa para a tela de baixo.
        if (!_open && !yields)
          Positioned(
            left: inicio,
            top: 0,
            bottom: 0,
            width: SsSideMenuHost.edgeWidth,
            child: Semantics(
              button: true,
              label: s.sideMenuOpen,
              onTap: open,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragStart: _dragStart,
                onHorizontalDragUpdate: _dragUpdate,
                onHorizontalDragEnd: _dragEnd,
              ),
            ),
          ),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: Listenable.merge([_c, _hint]),
            builder: (context, _) {
              final t = _c.value;
              // A alça fica sempre na árvore (só some da vista com o painel aberto): o arraste que
              // começa nela continua com o mesmo dono enquanto o painel abre.
              final alca = _EdgeGlow(
                t: _hint.value,
                color: c.accent,
                visible: t <= 0,
                active: _peeking && (_hint.isAnimating || widget.debugHintAt != null),
                onTap: open,
                onDragStart: _dragStart,
                onDragUpdate: _dragUpdate,
                onDragEnd: _dragEnd,
                targetKey: widget.handleKey,
                inset: inicio,
              );
              if (t <= 0) return yields ? const SizedBox.shrink() : Stack(children: [Positioned.fill(child: alca)]);
              final shown = t.clamp(0.0, 1.0);
              final width = _w * math.max(t, 0);
              return Stack(
                children: [
                  if (!yields) Positioned.fill(child: alca),
                  // Fundo que escurece. Na dica ele só tinge, sem segurar o toque.
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: _peeking,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: close,
                        onHorizontalDragStart: _dragStart,
                        onHorizontalDragUpdate: _dragUpdate,
                        onHorizontalDragEnd: _dragEnd,
                        child: Semantics(
                          label: s.close,
                          button: true,
                          onTap: close,
                          child: ColoredBox(color: AppColors.scrim.withValues(alpha: (c.isDark ? .55 : .42) * shown)),
                        ),
                      ),
                    ),
                  ),
                  // O painel se revela da esquerda (o conteúdo fica ancorado: na
                  // fresta aparecem os ícones), com a borda da direita arredondada.
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: width,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _peeking ? open : null,
                      onHorizontalDragStart: _dragStart,
                      onHorizontalDragUpdate: _dragUpdate,
                      onHorizontalDragEnd: _dragEnd,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(28)),
                          border: c.isDark ? Border(right: BorderSide(color: c.line)) : null,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.scrim.withValues(alpha: (c.isDark ? .5 : .2) * math.min(1, shown * 3)),
                              blurRadius: 32,
                              offset: const Offset(6, 0),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(28)),
                          child: OverflowBox(
                            alignment: Alignment.centerLeft,
                            minWidth: _w,
                            maxWidth: _w,
                            child: Semantics(
                              scopesRoute: _open,
                              namesRoute: _open,
                              explicitChildNodes: true,
                              label: s.sideMenu,
                              child: ExcludeSemantics(
                                excluding: !_open,
                                // Sem um Material acima, o Text do cabeçalho ganhava o sublinhado
                                // amarelo duplo de depuração (o host fica por cima do Scaffold).
                                child: Material(
                                  type: MaterialType.transparency,
                                  child: _SsSideMenuScope(progress: _c, close: close, child: widget.menu),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
    if (widget.handleBack) {
      host = PopScope(
        canPop: !_open,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _open) close();
        },
        child: host,
      );
    }
    // v1.9: Ctrl+K (⌘K) abre a busca do menu, com ele aberto ou fechado.
    final search = widget.menu is SsSideMenu ? (widget.menu as SsSideMenu).search : null;
    if (search != null && search.shortcut) {
      host = SsSearchShortcut(enabled: true, onShortcut: () => openSearch(), child: host);
    }
    return host;
  }

  /// v1.9: fecha o menu e abre a paleta da busca do [SsSideMenu] (`search:`), se houver.
  Future<void> openSearch() async {
    final search = widget.menu is SsSideMenu ? (widget.menu as SsSideMenu).search : null;
    if (search == null) return;
    if (_open) close();
    await search.open(context);
  }
}

/// A alça do menu na borda esquerda: uma pílula pequena na cor da marca, sempre à vista com o
/// menu fechado (v1.3), que diz "tem menu aqui" sem ocupar a tela. No fim da dica ao abrir o app
/// ela pulsa duas vezes e assenta no tom suave. Tocar abre o menu (só a área da alça: o resto da
/// borda segue com o toque da tela; o arraste continua na faixa da borda).
class _EdgeGlow extends StatelessWidget {
  const _EdgeGlow({
    required this.t,
    required this.color,
    required this.visible,
    required this.active,
    required this.onTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    this.targetKey,
    this.inset = 0,
  });

  final GlobalKey? targetKey;

  /// v1.9.3: distância da borda (a faixa de gesto do sistema); acima de 0 a pílula solta da borda e
  /// arredonda as duas pontas.
  final double inset;
  final double t;
  final Color color;

  /// Com o painel aberto (ou espiando) a alça fica invisível, mas segue na árvore.
  final bool visible;
  final bool active;
  final VoidCallback onTap;

  // A alça fica por cima da faixa da borda: o arraste que começa nela também abre o menu.
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;

  /// Opacidade em repouso.
  static const _repouso = .38;

  @override
  Widget build(BuildContext context) {
    var a = _repouso;
    if (!visible || (active && t < SsSideMenuHostState._closed)) {
      a = 0; // painel aberto, ou espiando na dica
    } else if (active) {
      final f = (t - SsSideMenuHostState._closed) / (1 - SsSideMenuHostState._closed);
      a = _repouso + (1 - _repouso) * math.pow(math.sin(2 * math.pi * f), 2).toDouble() * (1 - f * .4);
    }
    final solta = inset > 0;
    return Padding(
      padding: EdgeInsets.only(left: inset),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ExcludeSemantics(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            onHorizontalDragStart: onDragStart,
            onHorizontalDragUpdate: onDragUpdate,
            onHorizontalDragEnd: onDragEnd,
            child: Padding(
              key: targetKey,
              padding: const EdgeInsets.fromLTRB(0, 18, 16, 18),
              child: Container(
                width: 5,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: a),
                  borderRadius: solta
                      ? BorderRadius.circular(99)
                      : const BorderRadius.horizontal(right: Radius.circular(99)),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: a * .5), blurRadius: 12, spreadRadius: 1)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Casca única das abas da suíte: `Scaffold` com a [SsNavBar] embaixo, o
/// menu lateral opcional e o voltar do sistema que leva à 1ª aba.
///
/// **A faixa acima da barra é transparente** (v0.27): o círculo da aba atual
/// sobe [SsNavBar.rise] acima da barra, e no `bottomNavigationBar` comum essa
/// faixa era uma tira do fundo da tela cortando o conteúdo (com a sombra da
/// barra mudando dentro dela a cada troca de aba). Aqui o corpo vai até a
/// borda da barra e passa por trás da faixa; o corpo recebe
/// `MediaQuery.padding.bottom = SsNavBar.rise`, então lista com padding
/// padrão e `SafeArea` não ficam embaixo do círculo.
///
/// Com [sideMenu], as abas entram como 1ª seção do menu ([tabsInMenu]) e a
/// aba atual fica marcada nele.
class SsNavScaffold extends StatefulWidget {
  const SsNavScaffold({
    super.key,
    required this.body,
    required this.navBar,
    this.sideMenu,
    this.tabsInMenu = true,
    this.backToFirstTab = true,
    this.peek = true,
    this.floatingActionButton,
    this.debugHintAt,
    this.hideNavOnScroll = false,
    this.handleKey,
    this.adaptive = true,
  });

  /// v1.11.0: ver [SsSideMenuHost.adaptive].
  final bool adaptive;

  /// v1.9.1: chave da alça do menu (ver [SsSideMenuHost.handleKey]), para o [SsTour] apontar para ela.
  /// As abas usam o `itemKeys:` da [navBar].
  final GlobalKey? handleKey;

  /// v1.9: a barra de abas some ao rolar o corpo para baixo e volta ao rolar para cima (ou no topo, ou ao
  /// trocar de aba); enquanto ela está escondida o corpo ganha a altura dela. `navBar.hideOnScroll: true`
  /// vale o mesmo. Com leitor de tela ligado não some; com "reduzir movimento" some sem animar.
  final bool hideNavOnScroll;

  /// Botão flutuante de todas as abas (fica acima da barra).
  final Widget? floatingActionButton;

  /// Ver [SsSideMenuHost.debugHintAt].
  @visibleForTesting
  final double? debugHintAt;

  final Widget body;
  final SsNavBar navBar;
  final SsSideMenu? sideMenu;

  /// As abas da [navBar] na frente das seções do [sideMenu].
  final bool tabsInMenu;

  /// Voltar do sistema fora da 1ª aba vai para ela (sai do app só nela).
  final bool backToFirstTab;

  /// Ver [SsSideMenuHost.peek].
  final bool peek;

  @override
  State<SsNavScaffold> createState() => _SsNavScaffoldState();
}

class _SsNavScaffoldState extends State<SsNavScaffold> with SingleTickerProviderStateMixin {
  final _menu = GlobalKey<SsSideMenuHostState>();
  bool _menuOpen = false;
  late final _hide = SsScrollHide(this);

  bool get _hides => widget.hideNavOnScroll || widget.navBar.hideOnScroll;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _hide.configure(context);
  }

  @override
  void didUpdateWidget(SsNavScaffold old) {
    super.didUpdateWidget(old);
    if (old.navBar.currentIndex != widget.navBar.currentIndex || !_hides) _hide.show();
  }

  @override
  void dispose() {
    _hide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = widget.navBar;
    final hides = _hides;
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    // Teclado aberto: o Scaffold já encolhe o corpo até o teclado e a barra
    // fica atrás dele. Reservar a faixa da barra deixava um vão vazio entre o
    // campo e o teclado (o chat do assistente no Minhas Viagens).
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    Widget shell = Scaffold(
      extendBody: true,
      body: Builder(
        builder: (context) {
          // A MediaQuery que o Scaffold dá ao corpo (sem teclado), com o rodapé
          // trocado pela faixa do círculo.
          final mq = MediaQuery.of(context);
          Widget corpo(double v) => Padding(
            padding: EdgeInsets.only(bottom: keyboard ? 0 : (SsNavBar.barHeight + safeBottom) * v),
            child: MediaQuery(
              data: mq.copyWith(
                // v1.9: com a barra escondida, o rodapé volta a ser o do sistema.
                padding: mq.padding.copyWith(bottom: keyboard ? 0 : SsNavBar.rise * v + safeBottom * (1 - v)),
                viewPadding: mq.viewPadding.copyWith(bottom: keyboard ? 0 : SsNavBar.rise * v + safeBottom * (1 - v)),
              ),
              child: widget.body,
            ),
          );
          if (!hides) return corpo(1);
          return NotificationListener<ScrollNotification>(
            onNotification: _hide.handle,
            child: AnimatedBuilder(
              animation: _hide.visibility,
              builder: (_, _) => corpo(Curves.easeOut.transform(_hide.visibility.value.clamp(0.0, 1.0))),
            ),
          );
        },
      ),
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: hides
          ? SsNavHideScope(
              child: SsHideOnScrollBox(visibility: _hide.visibility, child: nav),
            )
          : nav,
    );
    final menu = widget.sideMenu;
    if (menu != null) {
      shell = SsSideMenuHost(
        key: _menu,
        peek: widget.peek,
        debugHintAt: widget.debugHintAt,
        handleKey: widget.handleKey,
        adaptive: widget.adaptive,
        handleBack: false,
        onOpenChanged: (v) => setState(() => _menuOpen = v),
        menu: widget.tabsInMenu
            ? menu._withLeading([
                SsSideMenuSection([
                  for (var i = 0; i < nav.items.length; i++)
                    SsSideMenuItem(
                      nav.items[i].icon,
                      nav.items[i].label,
                      activeIcon: nav.items[i].activeIcon,
                      badge: nav.items[i].badge,
                      selected: i == nav.currentIndex,
                      onTap: () => nav.onTap(i),
                    ),
                ]),
              ])
            : menu,
        child: shell,
      );
    }
    final first = !widget.backToFirstTab || nav.currentIndex == 0;
    return PopScope(
      canPop: !_menuOpen && first,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_menuOpen) {
          _menu.currentState?.close();
        } else if (!first) {
          nav.onTap(0);
        }
      },
      child: shell,
    );
  }
}
