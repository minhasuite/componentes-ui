import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'motion.dart';

/// Uma aba da [SsNavBar].
class SsNavItem {
  const SsNavItem(this.icon, this.label, {this.activeIcon});

  /// Contornado (inativo).
  final IconData icon;

  /// Cheio, dentro do círculo. Sem ele, usa [icon].
  final IconData? activeIcon;
  final String label;
}

/// Barra de abas com o item atual num círculo encaixado num recorte da barra.
/// Ao trocar de aba, o recorte e o círculo deslizam até o item novo.
///
/// Use no `bottomNavigationBar`. Sem `extendBody` o recorte mostra o fundo da
/// tela (o comum); com `Scaffold(extendBody: true)` o conteúdo passa por trás,
/// mas as listas das abas precisam reservar a altura da barra.
class SsNavBar extends StatefulWidget {
  const SsNavBar({super.key, required this.items, required this.currentIndex, required this.onTap})
    : assert(items.length >= 2);

  final List<SsNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Altura da barra (sem o círculo que sobe e sem a área segura).
  static const barHeight = 64.0;

  /// Quanto o círculo passa da borda de cima da barra.
  static const rise = 22.0;

  static const _circle = 52.0;
  static const _gap = 6.0;

  @override
  State<SsNavBar> createState() => _SsNavBarState();
}

class _SsNavBarState extends State<SsNavBar> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420), value: 1);
  late double _from = widget.currentIndex.toDouble();

  @override
  void didUpdateWidget(SsNavBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex == widget.currentIndex) return;
    // Começa de onde o círculo está agora (troca no meio da animação não pula).
    _from = _pos(old.currentIndex);
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

  double _pos(int target) => lerpDouble(_from, target.toDouble(), Curves.easeInOutCubic.transform(_c.value))!;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    final n = widget.items.length;
    return SizedBox(
      height: SsNavBar.rise + SsNavBar.barHeight + bottom,
      child: LayoutBuilder(
        builder: (context, box) {
          final slot = box.maxWidth / n;
          return AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final cx = slot * (_pos(widget.currentIndex) + .5);
              // O ícone novo aparece na segunda metade do deslize.
              final iconIn = Curves.easeOut.transform(((_c.value - .4) / .6).clamp(0.0, 1.0));
              final current = widget.items[widget.currentIndex];
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BarPainter(color: c.surface, line: c.line, cx: cx, dark: c.isDark),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: SsNavBar.rise,
                    height: SsNavBar.barHeight,
                    child: Row(
                      children: [
                        for (var i = 0; i < n; i++)
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
                    ),
                  ),
                  Positioned(
                    left: cx - SsNavBar._circle / 2,
                    top: SsNavBar.rise + _BarPainter.dip - SsNavBar._circle / 2,
                    child: IgnorePointer(
                      child: Container(
                        width: SsNavBar._circle,
                        height: SsNavBar._circle,
                        decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle, boxShadow: c.primaryShadow),
                        child: Opacity(
                          opacity: iconIn,
                          child: Transform.scale(
                            scale: .6 + .4 * iconIn,
                            child: Icon(current.activeIcon ?? current.icon, color: c.accent, size: 26),
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
      label: '${item.label}, aba ${index + 1} de $count',
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
              Icon(item.icon, color: c.muted, size: 24),
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
  _BarPainter({required this.color, required this.line, required this.cx, required this.dark});

  final Color color;
  final Color line;
  final double cx;
  final bool dark;

  /// O centro do círculo fica esta distância abaixo da borda da barra.
  static const dip = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    const top = SsNavBar.rise;
    const cy = top + dip;
    const r = SsNavBar._circle / 2 + SsNavBar._gap;
    const s = 14.0; // largura do ombro que suaviza a entrada do recorte
    final edge = Path()
      ..moveTo(0, top)
      ..lineTo(cx - r - s, top)
      ..cubicTo(cx - r - s * .25, top, cx - r, top + dip * .2, cx - r, cy)
      ..arcToPoint(Offset(cx + r, cy), radius: const Radius.circular(r), clockwise: false)
      ..cubicTo(cx + r, top + dip * .2, cx + r + s * .25, top, cx + r + s, top)
      ..lineTo(size.width, top);
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
  bool shouldRepaint(_BarPainter old) => old.cx != cx || old.color != color || old.dark != dark;
}
