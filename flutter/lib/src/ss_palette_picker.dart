import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'motion.dart';

/// Seletor de paleta: faixa horizontal rolável de fichas redondas com o
/// gradiente de 4 paradas de cada paleta e o nome embaixo (ou só no tooltip).
/// A marcada ganha um anel na cor da marca que **desliza** de uma ficha a outra
/// com a mola da suíte ([SsSlidingIndicator]). É a parte de paleta do
/// `Ss::ThemeSwitcherComponent` do Rails, com as mesmas paletas
/// ([SsPaleta.todas], geradas de `paletas/paletas.json`).
///
/// ```dart
/// SsPalettePicker(value: marca, onChanged: (p) => setState(() => marca = p.brand))
/// ```
///
/// - [value] é a marca atual; se não for uma das [paletas], nenhuma fica marcada.
/// - Abre com a marcada à vista e rola até ela quando muda por fora.
/// - [showNames] false: fichas menores, nome só no tooltip (e no leitor de tela).
class SsPalettePicker extends StatefulWidget {
  const SsPalettePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.paletas = SsPaleta.todas,
    this.showNames = true,
    this.chipSize = 38,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  final SsBrand value;
  final ValueChanged<SsPaleta> onChanged;
  final List<SsPaleta> paletas;
  final bool showNames;
  final double chipSize;
  final EdgeInsets padding;

  @override
  State<SsPalettePicker> createState() => _SsPalettePickerState();
}

class _SsPalettePickerState extends State<SsPalettePicker> {
  final _scroll = ScrollController();

  static const _ringGap = 4.0;

  double get _slot => widget.showNames ? widget.chipSize + 30 : widget.chipSize + 12;
  double get _chipTop => _ringGap + 2;

  int get _index {
    final v = widget.value;
    return widget.paletas.indexWhere((p) => identical(p.brand, v) || p.brand == v);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _mostrar(animate: false));
  }

  @override
  void didUpdateWidget(SsPalettePicker old) {
    super.didUpdateWidget(old);
    if (!identical(old.value, widget.value)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _mostrar(animate: true));
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Traz a marcada para a vista (centralizada se estava fora).
  void _mostrar({required bool animate}) {
    final i = _index;
    if (!mounted || i < 0 || !_scroll.hasClients) return;
    final pos = _scroll.position;
    final ini = widget.padding.left + i * _slot;
    if (ini >= pos.pixels && ini + _slot <= pos.pixels + pos.viewportDimension) return;
    final alvo = (ini - (pos.viewportDimension - _slot) / 2).clamp(0.0, pos.maxScrollExtent);
    if (animate && !reduceMotion(context)) {
      _scroll.animateTo(alvo, duration: SsMotion.base, curve: Curves.easeOutCubic);
    } else {
      _scroll.jumpTo(alvo);
    }
  }

  Rect _anel(int i, Size _) {
    final s = widget.chipSize;
    return Rect.fromLTWH(i * _slot + (_slot - s) / 2, _chipTop, s, s).inflate(_ringGap);
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = widget.chipSize;
    final i = _index;
    final altura = _chipTop + s + _ringGap + 2 + (widget.showNames ? 20 : 0);
    return SizedBox(
      height: altura,
      child: SingleChildScrollView(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: widget.padding,
        child: SizedBox(
          width: widget.paletas.length * _slot,
          height: altura,
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final (k, p) in widget.paletas.indexed) _ficha(context, c, p, k == i)],
              ),
              if (i >= 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: SsSlidingIndicator(
                      index: i,
                      rectOf: _anel,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: c.accent, width: 2),
                          boxShadow: [BoxShadow(color: c.accent.withValues(alpha: .22), spreadRadius: 3)],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ficha(BuildContext context, SsColors c, SsPaleta p, bool marcada) {
    final s = widget.chipSize;
    final ficha = Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: p.brand.gradient,
        border: Border.all(color: c.line),
        boxShadow: [BoxShadow(color: c.ink.withValues(alpha: .18), blurRadius: 6, offset: const Offset(0, 2))],
      ),
    );
    return Semantics(
      button: true,
      selected: marcada,
      label: p.nome,
      excludeSemantics: true,
      child: Tooltip(
        message: p.nome,
        child: SsPressable(
          scale: .9,
          onTap: () {
            if (marcada) return;
            SsHaptics.tick();
            widget.onChanged(p);
          },
          child: SizedBox(
            width: _slot,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: _chipTop),
                ficha,
                if (widget.showNames) ...[
                  const SizedBox(height: _ringGap + 4),
                  Text(
                    p.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppType.label,
                      height: 1.2,
                      fontWeight: marcada ? FontWeight.w800 : FontWeight.w600,
                      color: marcada ? c.accentText : c.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
