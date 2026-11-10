// v0.18: botão flutuante com várias ações (par do Ss::SpeedDialComponent).
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../ss_strings.dart';
import '../v10/tela_barra.dart';

/// Uma ação do [SsSpeedDial]: rótulo na pílula, ícone no mini botão.
/// [tooltip] é o nome lido pelo leitor de tela (padrão: o [label]) e a dica
/// do toque longo, quando o rótulo visível é curto ("IA" → "Registrar compra com IA").
class SsSpeedDialAction {
  const SsSpeedDialAction(this.label, this.icon, this.onPressed, {this.tooltip});

  final String label;
  final IconData icon;

  /// Sem ele, a ação aparece apagada e não responde.
  final VoidCallback? onPressed;
  final String? tooltip;
}

/// Botão flutuante com várias ações ("Lançamento", "Registrar com IA"): o
/// toque abre a lista acima do botão (rótulo em pílula + mini botão, a
/// primeira ação mais perto do botão), o [icon] gira até virar o [openIcon]
/// ("+" → "×"), as ações sobem com a mola ([SsMotion.bounce]) e um véu cobre a
/// tela. Fecha no ×, ao tocar no véu, no voltar do sistema (a lista é uma rota
/// por cima de tudo) e ao escolher uma ação (que roda depois de fechar).
///
/// O botão é um [SsFab] ([label], [extended] e [extendedFrom] iguais aos
/// dele); sem [label], é o círculo e [tooltip] (padrão "Ações rápidas") vira a
/// dica e o nome lido, com o estado aberto/fechado. Com **uma** ação só, vira
/// um [SsFab] direto com o ícone e o rótulo dela (sem lista); sem ações, nada.
/// Alvo de toque de 48 em tudo; "reduzir movimento" abre e fecha sem animação.
///
/// ```dart
/// floatingActionButton: SsSpeedDial(actions: [
///   SsSpeedDialAction('Lançamento', Icons.add_rounded, () => openForm(context)),
///   if (aiReady) SsSpeedDialAction('Registrar com IA', Icons.auto_awesome, () => context.push('/ai')),
/// ])
/// ```
class SsSpeedDial extends StatefulWidget {
  const SsSpeedDial({
    super.key,
    required this.actions,
    this.icon = Icons.add_rounded,
    this.openIcon = Icons.close_rounded,
    this.label,
    this.tooltip,
    this.extended = true,
    this.extendedFrom,
    this.onOpenChanged,
    this.useRootNavigator = true,
  });

  final List<SsSpeedDialAction> actions;
  final IconData icon;

  /// Ícone com a lista aberta (o toque fecha).
  final IconData openIcon;

  /// Texto do botão fechado (pílula, como no [SsFab]).
  final String? label;

  /// Nome lido e dica do círculo (padrão: `SsStrings.quickActions`).
  final String? tooltip;
  final bool extended;
  final double? extendedFrom;

  /// Avisa quando abre (true) e fecha (false).
  final ValueChanged<bool>? onOpenChanged;

  /// A lista abre no navegador de cima (o véu cobre a barra de abas). Falso:
  /// no navegador mais perto (como no `showDialog`).
  final bool useRootNavigator;

  @override
  State<SsSpeedDial> createState() => _SsSpeedDialState();
}

class _SsSpeedDialState extends State<SsSpeedDial> {
  final _link = LayerLink();
  _DialRoute? _route;
  bool _open = false;

  Future<void> _abrir() async {
    if (_route != null) return;
    final nav = Navigator.of(context, rootNavigator: widget.useRootNavigator);
    final s = SsStrings.of(context);
    final route = _DialRoute(
      link: _link,
      actions: widget.actions,
      icon: widget.icon,
      openIcon: widget.openIcon,
      closeLabel: s.close,
      menuLabel: widget.tooltip ?? s.quickActions,
      reduce: reduceMotion(context),
      themes: InheritedTheme.capture(from: context, to: nav.context),
    );
    _route = route;
    setState(() => _open = true);
    widget.onOpenChanged?.call(true);
    final chosen = await nav.push<SsSpeedDialAction>(route);
    // O botão da página volta só depois que a lista some (senão aparecem os dois).
    void voltou() {
      if (mounted) setState(() => _open = false);
    }

    final a = route.animation;
    if (a == null || a.isDismissed) {
      voltou();
    } else {
      void ouvir(AnimationStatus st) {
        if (st != AnimationStatus.dismissed) return;
        a.removeStatusListener(ouvir);
        voltou();
      }

      a.addStatusListener(ouvir);
    }
    _route = null;
    if (mounted) widget.onOpenChanged?.call(false);
    chosen?.onPressed?.call();
  }

  @override
  void dispose() {
    final r = _route;
    if (r != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (r.isActive) r.navigator?.removeRoute(r);
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final acoes = widget.actions;
    if (acoes.isEmpty) return const SizedBox.shrink();
    if (acoes.length == 1) {
      final a = acoes.single;
      return SsFab(
        icon: a.icon,
        label: a.label,
        tooltip: a.tooltip,
        extended: widget.extended,
        extendedFrom: widget.extendedFrom,
        onPressed: a.onPressed,
      );
    }
    final s = SsStrings.of(context);
    return CompositedTransformTarget(
      link: _link,
      child: Opacity(
        opacity: _open ? 0 : 1,
        child: MergeSemantics(
          child: Semantics(
            expanded: _open,
            child: SsFab(
              icon: widget.icon,
              label: widget.label,
              tooltip: widget.tooltip ?? s.quickActions,
              extended: widget.extended,
              extendedFrom: widget.extendedFrom,
              onPressed: _abrir,
            ),
          ),
        ),
      ),
    );
  }
}

class _DialRoute extends PopupRoute<SsSpeedDialAction> {
  _DialRoute({
    required this.link,
    required this.actions,
    required this.icon,
    required this.openIcon,
    required this.closeLabel,
    required this.menuLabel,
    required this.reduce,
    required this.themes,
  });

  final LayerLink link;
  final List<SsSpeedDialAction> actions;
  final IconData icon, openIcon;
  final String closeLabel, menuLabel;
  final bool reduce;
  final CapturedThemes themes;

  @override
  Color? get barrierColor => AppColors.scrim.withValues(alpha: .42);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => closeLabel;

  @override
  Duration get transitionDuration => reduce ? Duration.zero : SsMotion.base;

  @override
  Duration get reverseTransitionDuration => reduce ? Duration.zero : SsMotion.fast;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) =>
      themes.wrap(_DialMenu(route: this, animation: animation));

  // As ações animam sozinhas; o véu (barreira) já entra com o fade da rota.
  @override
  Widget buildTransitions(BuildContext context, Animation<double> a, Animation<double> b, Widget child) => child;
}

class _DialMenu extends StatelessWidget {
  const _DialMenu({required this.route, required this.animation});

  final _DialRoute route;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final d = SsDensity.of(context);
    // O mesmo diâmetro do SsFab (48 / 56 / 60): o mini botão centra nele.
    final fab = d.controlHeight + 8;
    final mini = math.min(d.iconButton, fab);
    final n = route.actions.length;
    final girando = CurvedAnimation(parent: animation, curve: Curves.easeOut, reverseCurve: Curves.easeIn);
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: route.menuLabel,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: CompositedTransformFollower(
              link: route.link,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.bottomRight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // De cima para baixo: a última ação no topo, a primeira junto do botão.
                  for (var i = n - 1; i >= 0; i--)
                    _Entra(
                      animation: animation,
                      index: i,
                      count: n,
                      child: Padding(
                        padding: EdgeInsets.only(right: (fab - mini) / 2),
                        child: _AcaoLinha(
                          action: route.actions[i],
                          mini: mini,
                          onTap: () => Navigator.of(context).pop(route.actions[i]),
                        ),
                      ),
                    ),
                  SizedBox(height: d.space(4)),
                  AnimatedBuilder(
                    animation: girando,
                    builder: (context, _) {
                      final t = girando.value;
                      // "+" girado 22,5° = "×" a −22,5°: a troca no meio não pula.
                      return MergeSemantics(
                        child: Semantics(
                          expanded: true,
                          child: SsFab(
                            key: const ValueKey('ss-speed-dial-close'),
                            icon: t < .5 ? route.icon : route.openIcon,
                            iconTurns: t < .5 ? t / 8 : (t - 1) / 8,
                            tooltip: route.closeLabel,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sobe e aparece com a mola, em escada a partir do botão.
class _Entra extends StatelessWidget {
  const _Entra({required this.animation, required this.index, required this.count, required this.child});

  final Animation<double> animation;
  final int index, count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ini = math.min(index * .12, .4);
    final fim = math.min(ini + .6, 1.0);
    final mola = CurvedAnimation(
      parent: animation,
      curve: Interval(ini, fim, curve: SsMotion.bounce),
      reverseCurve: Curves.easeIn,
    );
    final fade = CurvedAnimation(
      parent: animation,
      curve: Interval(ini, math.min(ini + .3, 1.0), curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, .6), end: Offset.zero).animate(mola),
        child: child,
      ),
    );
  }
}

class _AcaoLinha extends StatelessWidget {
  const _AcaoLinha({required this.action, required this.mini, required this.onTap});

  final SsSpeedDialAction action;
  final double mini;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final on = action.onPressed != null;
    final sombra = [
      BoxShadow(color: AppColors.scrim.withValues(alpha: .18), offset: const Offset(0, 4), blurRadius: 12),
    ];
    // A linha mede 48 de verdade (alvo de toque); o desenho tem 40 e o resto é o respiro entre elas.
    Widget linha = ConstrainedBox(
      constraints: BoxConstraints(minHeight: math.max(d.minTarget, mini + 8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: d.padX, vertical: d.space(7)),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: sombra,
            ),
            child: Text(
              action.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.ink, fontSize: d.font(AppType.set), fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(width: d.gap),
          Container(
            width: mini,
            height: mini,
            decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle, boxShadow: sombra),
            child: Icon(action.icon, size: d.iconSize, color: c.accentText),
          ),
        ],
      ),
    );
    linha = Semantics(
      button: true,
      enabled: on,
      label: action.tooltip ?? action.label,
      excludeSemantics: true,
      child: SsPressable(
        onTap: on ? onTap : null,
        enabled: on,
        scale: .95,
        child: Opacity(opacity: on ? 1 : .5, child: linha),
      ),
    );
    if (action.tooltip != null && action.tooltip != action.label) {
      linha = Tooltip(message: action.tooltip!, excludeFromSemantics: true, child: linha);
    }
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: math.max(160, MediaQuery.sizeOf(context).width - 32)),
      child: linha,
    );
  }
}
