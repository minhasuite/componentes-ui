// v0.27: menu lateral que abre arrastando da borda esquerda, com a dica que
// "espia" ao abrir o app, e a casca única das abas ([SsNavScaffold]).
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../app_theme.dart';
import '../motion.dart';
import '../ss_nav_bar.dart';
import '../ss_strings.dart';

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
}

/// Grupo de linhas do [SsSideMenu], com título pequeno opcional.
class SsSideMenuSection {
  const SsSideMenuSection(this.items, {this.title});

  final String? title;
  final List<SsSideMenuItem> items;
}

/// Conteúdo do menu lateral: cabeçalho (o [leading], o [title] e o
/// [subtitle]), as seções e o [footer]. Vai no [SsSideMenuHost.menu] (ou no
/// `sideMenu:` do [SsNavScaffold]). Dentro do host, as linhas entram em
/// cascata conforme o painel abre (as de baixo chegam por último).
class SsSideMenu extends StatelessWidget {
  const SsSideMenu({super.key, this.sections = const [], this.title, this.subtitle, this.leading, this.footer});

  final String? title;
  final String? subtitle;

  /// Marca do app ou avatar, à esquerda do título.
  final Widget? leading;
  final List<SsSideMenuSection> sections;

  /// Fica no pé do painel (versão, sair).
  final Widget? footer;

  /// Uma cópia com [sections] na frente das seções atuais.
  SsSideMenu _withLeading(List<SsSideMenuSection> first) => SsSideMenu(
    key: key,
    title: title,
    subtitle: subtitle,
    leading: leading,
    footer: footer,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null || leading != null)
          _Cascade(
            progress: progress,
            index: 0,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, pad.top + 20, 20, 12),
              child: Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 12)],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: c.ink, fontSize: AppType.lg, fontWeight: FontWeight.w800),
                          ),
                        if (subtitle != null && subtitle!.isNotEmpty)
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: c.muted, fontSize: AppType.sub),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(height: pad.top + 12),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(10, 4, 10, footer == null ? pad.bottom + 16 : 8),
            children: children,
          ),
        ),
        if (footer != null) Padding(padding: EdgeInsets.fromLTRB(20, 8, 20, pad.bottom + 16), child: footer),
      ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Semantics(
        button: true,
        selected: sel,
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
                    if (n > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(99)),
                        child: Text(
                          n > 99 ? '99+' : '$n',
                          style: AppTheme.number(context)
                              .copyWith(color: AppColors.onDark, fontSize: AppType.label, fontWeight: FontWeight.w800),
                        ),
                      ),
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
/// coluna de ícones, com a pílula "Arraste para abrir o menu" e a seta que
/// cutuca), volta, e a borda pisca duas vezes na cor da marca. Não segura o
/// toque: a tela segue usável durante a dica; tocar na fresta abre o menu.
/// Com "reduzir movimento" a dica não roda.
///
/// A faixa da borda fica depois dos gestos do sistema
/// (`MediaQuery.systemGestureInsets`), para não brigar com o voltar do Android.
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
  });

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

  // Linha do tempo da dica (painel que espia, pílula, seta, borda que pisca).
  late final _hint = AnimationController(vsync: this, duration: _hintTotal);
  static const _hintTotal = Duration(milliseconds: 3600);

  // Fases da dica, em fração de [_hintTotal].
  static const _out = .17; // espia (mola)
  static const _back = .45; // começa a voltar
  static const _closed = .56; // fechou; a borda pisca até o fim

  bool _open = false;
  bool _peeking = false;
  double _w = 300;

  bool get isOpen => _open;

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
          if (!mounted || _open || _c.value != 0 || reduceMotion(context)) return;
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
      _c.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
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
    final edge = mq.systemGestureInsets.left + mq.padding.left + SsSideMenuHost.edgeWidth;

    Widget host = Stack(
      children: [
        widget.child,
        // Faixa da borda: pega o arraste com o menu fechado. Translúcida: o
        // toque passa para a tela de baixo.
        if (!_open)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: edge,
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
              if (t <= 0) {
                return _EdgeGlow(
                  t: _hint.value,
                  color: c.accent,
                  active: _peeking && (_hint.isAnimating || widget.debugHintAt != null),
                );
              }
              final shown = t.clamp(0.0, 1.0);
              final width = _w * math.max(t, 0);
              return Stack(
                children: [
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
                                child: _SsSideMenuScope(progress: _c, close: close, child: widget.menu),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_peeking) _HintPill(t: _hint.value, left: width + 12, text: s.sideMenuHint),
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
    return host;
  }
}

/// A pílula "Arraste para abrir o menu" ao lado da fresta, com a seta que
/// cutuca para a direita. Entra com mola, sai antes do painel voltar.
class _HintPill extends StatelessWidget {
  const _HintPill({required this.t, required this.left, required this.text});

  final double t;
  final double left;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    double seg(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);
    final enter = SsMotion.pop.transform(seg(.08, .22));
    final exit = Curves.easeIn.transform(seg(.40, .47));
    final opacity = (seg(.08, .14) * (1 - exit)).clamp(0.0, 1.0);
    // Duas cutucadas da seta enquanto o painel está parado.
    final nudge = 6 * math.pow(math.sin(2 * math.pi * seg(.2, .44)), 2).toDouble();
    return Positioned(
      left: left,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Center(
          child: Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(-14 * (1 - enter) - 8 * exit, 0),
              child: Transform.scale(
                scale: .85 + .15 * enter,
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
                  decoration: BoxDecoration(
                    color: c.ink,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: c.tintedShadow(c.accent, strength: .6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: Offset(nudge, 0),
                        child: Icon(Icons.keyboard_double_arrow_right_rounded, size: 18, color: c.surface),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        text,
                        style: TextStyle(color: c.surface, fontSize: AppType.sub, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Depois que o painel volta, a borda esquerda pisca duas vezes na cor da
/// marca: "o menu mora aqui".
class _EdgeGlow extends StatelessWidget {
  const _EdgeGlow({required this.t, required this.color, required this.active});

  final double t;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    if (!active || t < SsSideMenuHostState._closed) return const SizedBox.shrink();
    final f = (t - SsSideMenuHostState._closed) / (1 - SsSideMenuHostState._closed);
    final a = math.pow(math.sin(2 * math.pi * f), 2).toDouble() * (1 - f * .4);
    return IgnorePointer(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 5,
          height: 72,
          decoration: BoxDecoration(
            color: color.withValues(alpha: a),
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(99)),
            boxShadow: [BoxShadow(color: color.withValues(alpha: a * .6), blurRadius: 16, spreadRadius: 2)],
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
  });

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

class _SsNavScaffoldState extends State<SsNavScaffold> {
  final _menu = GlobalKey<SsSideMenuHostState>();
  bool _menuOpen = false;

  @override
  Widget build(BuildContext context) {
    final nav = widget.navBar;
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    Widget shell = Scaffold(
      extendBody: true,
      body: Builder(
        builder: (context) {
          // A MediaQuery que o Scaffold dá ao corpo (sem teclado), com o rodapé
          // trocado pela faixa do círculo.
          final mq = MediaQuery.of(context);
          return Padding(
            padding: EdgeInsets.only(bottom: SsNavBar.barHeight + safeBottom),
            child: MediaQuery(
              data: mq.copyWith(
                padding: mq.padding.copyWith(bottom: SsNavBar.rise),
                viewPadding: mq.viewPadding.copyWith(bottom: SsNavBar.rise),
              ),
              child: widget.body,
            ),
          );
        },
      ),
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: nav,
    );
    final menu = widget.sideMenu;
    if (menu != null) {
      shell = SsSideMenuHost(
        key: _menu,
        peek: widget.peek,
        debugHintAt: widget.debugHintAt,
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
