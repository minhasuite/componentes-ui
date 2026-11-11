import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'motion.dart';
import 'ss_strings.dart';

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
  const SsNavCenter(this.icon, {required this.onTap, required this.label});

  final IconData icon;
  final VoidCallback onTap;

  /// Para o leitor de tela e a dica (o botão não mostra texto).
  final String label;
}

/// Barra de abas com o item atual num círculo encaixado num recorte da barra.
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
  const SsNavBar({super.key, required this.items, required this.currentIndex, required this.onTap, this.center})
    : assert(items.length >= 2);

  final List<SsNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Ação central elevada (opcional).
  final SsNavCenter? center;

  /// Altura da barra (sem o círculo que sobe e sem a área segura).
  static const barHeight = 64.0;

  /// Quanto o círculo passa da borda de cima da barra.
  static const rise = 22.0;

  static const _circle = 52.0;
  static const _gap = 6.0;
  static const _centerSize = 56.0;

  @override
  State<SsNavBar> createState() => _SsNavBarState();
}

/// Onde o círculo está num instante do pulo.
typedef _Pose = ({double x, double lift, double squash, double notch});

class _SsNavBarState extends State<SsNavBar> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 640), value: 1);
  late double _from = widget.currentIndex.toDouble();
  double _fromLift = 0;

  // Fases do pulo, em fração da duração.
  static const _takeoff = .16; // fim da preparação (achatar)
  static const _land = .74; // pouso

  @override
  void didUpdateWidget(SsNavBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex == widget.currentIndex) return;
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
    return SizedBox(
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
                      child: _CenterButton(center),
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
                          decoration: BoxDecoration(
                            color: c.surface,
                            shape: BoxShape.circle,
                            boxShadow: c.primaryShadow,
                          ),
                          child: Opacity(
                            opacity: iconIn.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: .5 + .5 * iconIn,
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
                ],
              );
            },
          );
        },
      ),
    );
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
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: AnimatedOpacity(
          // O item atual está no círculo: o lugar dele na barra fica vazio.
          opacity: selected ? 0 : 1,
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SsNavItem.withBadge(Icon(item.icon, color: c.muted, size: 24), item.badge),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: c.muted, fontSize: AppType.label, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
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
