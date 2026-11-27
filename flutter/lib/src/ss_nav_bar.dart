import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'motion.dart';
import 'ss_strings.dart';
import 'v19/paridade_web/hide_on_scroll.dart';

/// Uma aba da [SsNavBar].
class SsNavItem {
  const SsNavItem(this.icon, this.label, {this.activeIcon, this.badge});

  /// v0.20: contagem no ícone (pedidos novos, cards atrasados); 0 ou nulo
  /// some, acima de 99 vira "99+". O leitor de tela ouve "Pedidos: 3 novas".
  /// Par do `badge:` do item do `Ss::AppShellComponent`.
  final int? badge;

  /// O ícone com a contagem por cima (quando há).
  static Widget withBadge(Widget icon, int? n) {
    if (n == null || n <= 0) return icon;
    return Badge(
      label: Text(n > 99 ? '99+' : '$n'),
      backgroundColor: AppColors.danger,
      textColor: AppColors.onDark,
      child: icon,
    );
  }

  /// Contornado (inativo).
  final IconData icon;

  /// Cheio, dentro do círculo. Sem ele, usa [icon].
  final IconData? activeIcon;
  final String label;
}

/// Ação central elevada da [SsNavBar] (ex.: "Novo lançamento"): botão
/// redondo na cor da marca, com sombra na própria cor, encaixado num recorte
/// fixo no meio da barra. Não é uma aba: só chama [onTap].
class SsNavCenter {
  const SsNavCenter(this.icon, {required this.onTap, required this.label, this.key});

  final IconData icon;
  final VoidCallback onTap;

  /// v1.9.2: chave posta no botão (o alvo de um passo do [SsTour] ou de um teste). O mesmo que
  /// `SsNavBar(centerKey:)`, que ganha se vier também.
  final GlobalKey? key;

  /// Para o leitor de tela e a dica (o botão não mostra texto).
  final String label;
}

/// Barra de abas com o item atual num círculo encaixado num recorte da barra.
/// Todas as abas mostram o rótulo: o da aba atual fica no lugar dela, embaixo
/// do círculo, na tinta da marca (v0.25; antes a aba atual era só o ícone).
/// O círculo tem um anel de [ringWidth] na [ringColor] (3:1 em todo tema).
/// Ao trocar de aba, o círculo pula em arco até o item novo: achata antes de
/// sair, estica no ar e achata de novo ao pousar; o recorte fica raso enquanto
/// ele está no ar e afunda quando ele pousa.
///
/// Use no `bottomNavigationBar`. Sem `extendBody` o recorte mostra o fundo da
/// tela (o comum); com `Scaffold(extendBody: true)` o conteúdo passa por trás,
/// mas as listas das abas precisam reservar a altura da barra.
///
/// Com [center], um botão de ação fica no meio (entre as abas da metade
/// esquerda e as da direita), num recorte fixo; o círculo da aba atual passa
/// por cima dele ao pular de um lado para o outro. Use com 2 ou 4 abas.
class SsNavBar extends StatefulWidget {
  const SsNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.center,
    this.hideOnScroll = false,
    this.itemKeys,
    this.centerKey,
  }) : assert(items.length >= 2),
       assert(itemKeys == null || itemKeys.length == items.length);

  /// v1.9.1: uma chave por aba (na ordem de [items]), posta na aba inteira: o alvo de um passo do
  /// [SsTour] (`SsTourStep(target: abas[1], …)`) ou de um teste. Nulo: sem chave.
  final List<GlobalKey>? itemKeys;

  /// v1.9.2: chave no botão central ([center]), para o [SsTour] apontar para ele
  /// (`SsTourStep(target: centro, …)`). Sem [center], não tem efeito.
  final GlobalKey? centerKey;

  /// v1.9: some ao rolar a lista da tela para baixo e volta ao rolar para cima (ou ao chegar no topo, ou ao
  /// trocar de aba). Escuta o `ScrollNotificationObserver` do `Scaffold` (o mesmo do `AppBar`), então serve
  /// no `bottomNavigationBar` de qualquer `Scaffold`; dentro do [SsNavScaffold] quem cuida é ele
  /// (`hideNavOnScroll:`, que também devolve ao corpo a altura da barra). Com leitor de tela ligado não some;
  /// com "reduzir movimento" some sem animar.
  final bool hideOnScroll;

  final List<SsNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Ação central elevada (opcional).
  final SsNavCenter? center;

  /// Altura da barra (sem o círculo que sobe e sem a área segura).
  static const barHeight = 64.0;

  /// v1.9.3: menor tamanho do rótulo da aba quando ele encolhe para caber (texto grande, rótulo longo,
  /// 5 abas em 360): 10, um ponto abaixo do [AppType.label]. Abaixo disso termina em "…".
  static const minLabelSize = 10.0;

  /// Quanto o círculo passa da borda de cima da barra.
  static const rise = 22.0;

  /// v0.25: cor do anel do círculo da aba atual: a marca na variante de tinta
  /// ([SsColors.inkFor]: 4,5:1 sobre surface, página e field; 7:1 no alto
  /// contraste), então passa os 3:1 de borda (WCAG 1.4.11) em claro, escuro e OLED.
  static Color ringColor(SsColors c) => c.inkFor(c.accent);

  /// Espessura do anel do círculo da aba atual.
  static const ringWidth = 2.0;

  static const _circle = 52.0;
  static const _gap = 6.0;
  static const _centerSize = 56.0;

  @override
  State<SsNavBar> createState() => _SsNavBarState();
}

/// Onde o círculo está num instante do pulo.
typedef _Pose = ({double x, double lift, double squash, double notch});

class _SsNavBarState extends State<SsNavBar> with TickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 640), value: 1);
  late final _hide = SsScrollHide(this);
  ScrollNotificationObserverState? _observer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _hide.configure(context);
    _listen();
  }

  void _listen() {
    final want = widget.hideOnScroll && !SsNavHideScope.of(context);
    final o = want ? ScrollNotificationObserver.maybeOf(context) : null;
    if (o == _observer) return;
    _observer?.removeListener(_onScroll);
    _observer = o?..addListener(_onScroll);
    if (o == null) _hide.show();
  }

  void _onScroll(ScrollNotification n) => _hide.handle(n);
  late double _from = widget.currentIndex.toDouble();
  double _fromLift = 0;

  // Fases do pulo, em fração da duração.
  static const _takeoff = .16; // fim da preparação (achatar)
  static const _land = .74; // pouso

  @override
  void didUpdateWidget(SsNavBar old) {
    super.didUpdateWidget(old);
    if (old.hideOnScroll != widget.hideOnScroll) _listen();
    if (old.currentIndex == widget.currentIndex) return;
    _hide.show();
    // Começa de onde o círculo está (troca no meio do pulo não teleporta).
    final p = _pose(old.currentIndex);
    _from = p.x;
    _fromLift = p.lift;
    if (reduceMotion(context)) {
      _c.value = 1;
    } else {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _observer?.removeListener(_onScroll);
    _hide.dispose();
    _c.dispose();
    super.dispose();
  }

  _Pose _pose(int target) {
    final t = _c.value;
    final dist = (target - _from).abs();
    if (dist == 0 && _fromLift == 0) return (x: _from, lift: 0, squash: 0, notch: 1);
    // Mais longe, pulo mais alto (até 40 px).
    final height = math.min(20 + 7 * dist, 40.0);
    final f = ((t - _takeoff) / (_land - _takeoff)).clamp(0.0, 1.0);
    final l = ((t - _land) / (1 - _land)).clamp(0.0, 1.0);
    final x = lerpDouble(_from, target.toDouble(), Curves.easeInOutSine.transform(f))!;
    final arc = math.sin(math.pi * f);
    final lift = height * arc + _fromLift * (1 - Curves.easeOut.transform(f)) - 3 * math.sin(math.pi * l);
    // squash < 0 achata, > 0 estica. Preparação, estica na subida/descida, pouso.
    final prep = t < _takeoff ? -.14 * math.sin(math.pi * t / _takeoff) : 0.0;
    final air = .16 * arc * math.cos(math.pi * f).abs();
    final landing = -.16 * math.sin(math.pi * l) * (1 - .5 * l);
    // O recorte fecha até 60% com o círculo no ar e afunda um pouco no pouso.
    final notch = 1 - .6 * arc + .08 * math.sin(math.pi * l);
    return (x: x, lift: lift, squash: prep + air + landing, notch: notch);
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    final n = widget.items.length;
    final center = widget.center;
    // Com a ação central, há uma vaga a mais no meio: a aba i vai para a vaga
    // _slotOf(i) (contínuo, para o círculo atravessar o meio no pulo).
    final half = n ~/ 2;
    double slotOf(double x) => center == null ? x : x + (x - (half - 1)).clamp(0.0, 1.0);
    final slots = center == null ? n : n + 1;
    final bar = SizedBox(
      height: SsNavBar.rise + SsNavBar.barHeight + bottom,
      child: LayoutBuilder(
        builder: (context, box) {
          final slot = box.maxWidth / slots;
          final ccx = slot * (half + .5);
          return AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final p = _pose(widget.currentIndex);
              final cx = slot * (slotOf(p.x) + .5);
              // O recorte que anda some perto do recorte fixo do meio (não se cruzam).
              const r = SsNavBar._circle / 2 + SsNavBar._gap;
              final depth = center == null ? p.notch : math.min(p.notch, (((cx - ccx).abs() - r) / r).clamp(0.0, 1.0));
              // O ícone novo aparece crescendo a partir do meio do voo.
              final iconIn = Curves.easeOutBack.transform(((_c.value - .4) / .45).clamp(0.0, 1.0));
              final current = widget.items[widget.currentIndex];
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BarPainter(
                        color: c.surface,
                        line: c.line,
                        cx: cx,
                        dark: c.isDark,
                        depth: depth,
                        centerX: center == null ? null : ccx,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: SsNavBar.rise,
                    height: SsNavBar.barHeight,
                    child: Row(
                      children: [
                        for (var i = 0; i < n; i++) ...[
                          if (center != null && i == half) const Spacer(),
                          Expanded(
                            child: _Tab(
                              key: widget.itemKeys?[i],
                              item: widget.items[i],
                              selected: i == widget.currentIndex,
                              index: i,
                              count: n,
                              onTap: () {
                                if (i != widget.currentIndex) HapticFeedback.selectionClick();
                                widget.onTap(i);
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (center != null)
                    Positioned(
                      left: ccx - SsNavBar._centerSize / 2,
                      top: SsNavBar.rise + _BarPainter.dip - SsNavBar._centerSize / 2 - 4,
                      child: KeyedSubtree(key: widget.centerKey ?? center.key, child: _CenterButton(center)),
                    ),
                  Positioned(
                    left: cx - SsNavBar._circle / 2,
                    top: SsNavBar.rise + _BarPainter.dip - SsNavBar._circle / 2 - p.lift,
                    child: IgnorePointer(
                      child: Transform(
                        alignment: Alignment.bottomCenter,
                        transform: Matrix4.diagonal3Values(1 - p.squash * .8, 1 + p.squash, 1),
                        child: Container(
                          width: SsNavBar._circle,
                          height: SsNavBar._circle,
                          // v0.25: anel na tinta da marca (3:1 sobre a barra e a página em
                          // todo tema e paleta) e, no escuro, o miolo um degrau acima (field):
                          // surface sobre surface sumia no escuro e no OLED.
                          decoration: BoxDecoration(
                            color: c.isDark ? c.field : c.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: SsNavBar.ringColor(c), width: SsNavBar.ringWidth),
                            boxShadow: c.primaryShadow,
                          ),
                          child: Opacity(
                            opacity: iconIn.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: .5 + .5 * iconIn,
                              // v0.25: Center (com contagem, o Badge ia para o canto de cima).
                              child: Center(
                                child: SsNavItem.withBadge(
                                  Icon(current.activeIcon ?? current.icon, color: c.accent, size: 26),
                                  current.badge,
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
          );
        },
      ),
    );
    if (!widget.hideOnScroll || SsNavHideScope.of(context)) return bar;
    return SsHideOnScrollBox(visibility: _hide.visibility, child: bar);
  }
}

class _CenterButton extends StatelessWidget {
  const _CenterButton(this.center);
  final SsNavCenter center;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Semantics(
      button: true,
      label: center.label,
      excludeSemantics: true,
      child: Tooltip(
        message: center.label,
        child: SsPressable(
          onTap: center.onTap,
          scale: .92,
          child: Container(
            key: const ValueKey('ss-nav-center'),
            width: SsNavBar._centerSize,
            height: SsNavBar._centerSize,
            decoration: BoxDecoration(
              color: c.accent,
              borderRadius: BorderRadius.circular(SsNavBar._centerSize / 2),
              boxShadow: c.tintedShadow(c.accent),
            ),
            child: Icon(center.icon, color: AppColors.onDark, size: 28),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    super.key,
    required this.item,
    required this.selected,
    required this.index,
    required this.count,
    required this.onTap,
  });

  final SsNavItem item;
  final bool selected;
  final int index;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: SsStrings.of(context).tabOf(
        (item.badge ?? 0) > 0 ? SsStrings.of(context).newCount(item.label, item.badge!) : item.label,
        index + 1,
        count,
      ),
      // v0.25: o toque vai no nó da aba (o excludeSemantics tirava o do InkResponse).
      onTap: onTap,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // O ícone do item atual está no círculo: o lugar dele na barra fica vazio.
            AnimatedOpacity(
              opacity: selected ? 0 : 1,
              duration: SsMotion.short,
              child: SsNavItem.withBadge(Icon(item.icon, color: c.muted, size: 24), item.badge),
            ),
            const SizedBox(height: 3),
            // v0.25: o rótulo fica sempre, e o da aba atual na tinta da marca, embaixo do círculo.
            // v0.25.1: o AnimatedDefaultTextStyle troca o estilo herdado inteiro; sem a família do
            // tema o rótulo caía na fonte do sistema (e em caixinhas nas capturas de teste).
            AnimatedDefaultTextStyle(
              duration: SsMotion.short,
              style: TextStyle(
                fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                fontFamilyFallback: Theme.of(context).textTheme.bodyMedium?.fontFamilyFallback,
                color: selected ? c.accentText : c.muted,
                fontSize: AppType.label,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
              // v1.9.3: com texto grande o rótulo encolhe até caber (sem "Lançam…"), não abaixo de
              // [SsNavBar.minLabelSize]; só então termina em "…".
              child: _TabLabel(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rótulo da aba: a escala de texto do sistema vale até caber na largura da aba; passou, encolhe só
/// este texto (o alvo de toque e o ícone não mudam), com piso em [SsNavBar.minLabelSize].
class _TabLabel extends StatelessWidget {
  const _TabLabel(this.label);
  final String label;

  static const _respiro = 2.0;

  @override
  Widget build(BuildContext context) {
    final estilo = DefaultTextStyle.of(context).style;
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final base = estilo.fontSize ?? AppType.label;
        final cheio = scaler.scale(base);
        var tamanho = cheio;
        // Respiro de 2 de cada lado: rótulos vizinhos não encostam ("LançamentosAssistente").
        final cabe = box.maxWidth - 2 * _respiro;
        if (box.maxWidth.isFinite) {
          final piso = math.min(SsNavBar.minLabelSize, cheio);
          double largura(double t) {
            final tp = TextPainter(
              text: TextSpan(
                text: label,
                style: estilo.copyWith(fontSize: t),
              ),
              textDirection: Directionality.of(context),
              maxLines: 1,
              textScaler: TextScaler.noScaling,
            )..layout();
            final w = tp.width;
            tp.dispose();
            return w;
          }

          final w = largura(cheio);
          if (w > cabe) {
            // A largura não é bem proporcional ao tamanho (arredondamento dos glifos): confere e desce de 0,25.
            tamanho = math.max(piso, cheio * cabe / w);
            while (tamanho > piso && largura(tamanho) > cabe) {
              tamanho = math.max(piso, tamanho - .25);
            }
          }
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: _respiro),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            textScaler: TextScaler.linear(tamanho / base),
          ),
        );
      },
    );
  }
}

/// A barra com o recorte em U centrado em [cx].
class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.color,
    required this.line,
    required this.cx,
    required this.dark,
    this.depth = 1,
    this.centerX,
  });

  /// Centro do recorte fixo da ação central (nulo: sem ação central).
  final double? centerX;

  final Color color;
  final Color line;
  final double cx;
  final bool dark;

  /// 1 = recorte inteiro; menor = mais raso (círculo no ar).
  final double depth;

  /// O centro do círculo fica esta distância abaixo da borda da barra.
  static const dip = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    const top = SsNavBar.rise;
    const cy = top + dip;
    const r = SsNavBar._circle / 2 + SsNavBar._gap;
    const s = 14.0; // largura do ombro que suaviza a entrada do recorte
    // Recortes da esquerda para a direita: o que anda e, se houver, o fixo do meio.
    final notches = <(double, double, double)>[
      if (depth > .01) (cx, r, depth),
      if (centerX != null) (centerX!, SsNavBar._centerSize / 2 + SsNavBar._gap, 1.0),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    final edge = Path()..moveTo(0, top);
    for (final (x, rr, d) in notches) {
      edge
        ..lineTo(x - rr - s, top)
        ..cubicTo(x - rr - s * .25, top, x - rr, top + dip * .2, x - rr, cy)
        ..arcToPoint(Offset(x + rr, cy), radius: Radius.elliptical(rr, rr * d), clockwise: false)
        ..cubicTo(x + rr, top + dip * .2, x + rr + s * .25, top, x + rr + s, top);
    }
    edge.lineTo(size.width, top);
    final bar = Path.from(edge)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawShadow(bar, Colors.black, dark ? 2 : 6, false);
    canvas.drawPath(bar, Paint()..color = color);
    if (dark) {
      // No escuro a sombra some: a borda de 1 px separa a barra da tela.
      canvas.drawPath(
        edge,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.cx != cx || old.depth != depth || old.color != color || old.dark != dark || old.centerX != centerX;
}
