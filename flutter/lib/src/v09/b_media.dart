// v0.9 (lote b): mídia — anexos, carrossel e trilho de miniaturas.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../ss_strings.dart';

/// Um botão do [SsAttachBar].
class SsAttachItem {
  const SsAttachItem(this.icon, this.label, {this.onTap, this.color});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// Padrão: a paleta da suíte, na ordem.
  final Color? color;
}

/// Fileira de botões quadrados coloridos com ícone para anexar (foto,
/// documento, contato, local). Entram em cascata, crescendo com mola. O
/// ícone fica escuro quando a cor de fundo é clara (amarelo), para contrastar.
class SsAttachBar extends StatelessWidget {
  const SsAttachBar({super.key, required this.items, this.size});

  final List<SsAttachItem> items;

  /// Lado do quadrado (padrão: o botão da [SsDensity] + 8, 56 no padrão).
  final double? size;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final reduzir = reduceMotion(context);
    final size = this.size ?? SsDensity.of(context).controlHeight + 8;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          Flexible(
            child: _Entra(
              index: i,
              off: reduzir,
              child: Semantics(
                button: true,
                label: items[i].label,
                excludeSemantics: true,
                child: SsPressable(
                  onTap: items[i].onTap,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Builder(
                        builder: (context) {
                          final cor = items[i].color ?? c.series[i % c.series.length];
                          final claro = ThemeData.estimateBrightnessForColor(cor) == Brightness.light;
                          return Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              color: cor,
                              borderRadius: BorderRadius.circular(size * .32),
                              boxShadow: [
                                BoxShadow(
                                  color: cor.withValues(alpha: .35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                  spreadRadius: -6,
                                ),
                              ],
                            ),
                            child: Icon(
                              items[i].icon,
                              color: claro ? AppColors.inkLight : AppColors.onDark,
                              size: size * .44,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        items[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.ink2, fontSize: AppType.meta, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Entra extends StatelessWidget {
  const _Entra({required this.index, required this.off, required this.child});
  final int index;
  final bool off;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (off) return child;
    final delay = math.min(index, 8) * 50;
    final total = SsMotion.slow.inMilliseconds + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      builder: (_, t, child) {
        final k = ((t * total - delay) / SsMotion.slow.inMilliseconds).clamp(0.0, 1.0);
        return Opacity(
          opacity: Curves.easeOut.transform(k),
          child: Transform.scale(scale: .6 + .4 * SsMotion.spring.transform(k), child: child),
        );
      },
      child: child,
    );
  }
}

/// Indicador do [SsSnapCarousel].
enum SsCarouselIndicator { dots, counter, none }

/// Carrossel que para em cada item: o do meio maior, os vizinhos cortados nas
/// bordas e encolhidos. Ao soltar, assenta no item com mola (passa um pouco e
/// volta). Indicador de bolinhas (a ativa vira pílula com mola) ou "2/5".
class SsSnapCarousel extends StatefulWidget {
  const SsSnapCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.height = 220,
    this.viewportFraction = .78,
    this.indicator = SsCarouselIndicator.dots,
    this.initialPage = 0,
    this.onPageChanged,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double height;
  final double viewportFraction;
  final SsCarouselIndicator indicator;
  final int initialPage;
  final ValueChanged<int>? onPageChanged;

  @override
  State<SsSnapCarousel> createState() => _SsSnapCarouselState();
}

class _SsSnapCarouselState extends State<SsSnapCarousel> {
  late final _pc = PageController(viewportFraction: widget.viewportFraction, initialPage: widget.initialPage);
  late int _atual = widget.initialPage;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  double get _page =>
      _pc.hasClients && _pc.position.haveDimensions ? (_pc.page ?? _atual.toDouble()) : _atual.toDouble();

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pc,
            // Assenta na página com mola (passa um tiquinho e volta).
            physics: reduceMotion(context)
                ? null
                : _MolaPagina(parent: ScrollConfiguration.of(context).getScrollPhysics(context)),
            itemCount: widget.itemCount,
            onPageChanged: (i) {
              SsHaptics.tick();
              setState(() => _atual = i);
              widget.onPageChanged?.call(i);
            },
            itemBuilder: (context, i) => AnimatedBuilder(
              animation: _pc,
              builder: (context, child) {
                final d = (_page - i).abs().clamp(0.0, 1.0);
                return Transform.scale(
                  scale: 1 - .1 * d,
                  child: Opacity(opacity: 1 - .35 * d, child: child),
                );
              },
              child: Semantics(
                label: SsStrings.of(context).itemOf(i + 1, widget.itemCount),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: widget.itemBuilder(context, i),
                ),
              ),
            ),
          ),
        ),
        if (widget.indicator != SsCarouselIndicator.none) const SizedBox(height: 12),
        switch (widget.indicator) {
          SsCarouselIndicator.none => const SizedBox.shrink(),
          SsCarouselIndicator.counter => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(AppRadius.pill)),
            child: Text(
              '${_atual + 1}/${widget.itemCount}',
              semanticsLabel: SsStrings.of(context).nOfTotal(_atual + 1, widget.itemCount),
              style: AppTheme.number(context, size: AppType.meta, color: c.ink2),
            ),
          ),
          SsCarouselIndicator.dots => ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                for (var i = 0; i < widget.itemCount; i++)
                  AnimatedContainer(
                    duration: reduceMotion(context) ? Duration.zero : SsMotion.indicator,
                    curve: SsMotion.bounce,
                    width: i == _atual ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _atual ? c.accent : c.muted2,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
              ],
            ),
          ),
        },
      ],
    );
  }
}

/// Física de página com mola subamortecida: o snap passa ~4% e assenta.
class _MolaPagina extends ScrollPhysics {
  const _MolaPagina({super.parent});

  @override
  _MolaPagina applyTo(ScrollPhysics? ancestor) => _MolaPagina(parent: buildParent(ancestor));

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(mass: .5, stiffness: 140, ratio: .7);
}

/// Miniaturas em coluna (ao lado da foto grande do produto, da planta): a
/// ativa ganha borda na cor da marca e as outras ficam apagadas. Setas em
/// cima e embaixo rolam uma miniatura; somem nas pontas.
class SsThumbRail extends StatefulWidget {
  const SsThumbRail({
    super.key,
    required this.count,
    required this.thumbBuilder,
    required this.selected,
    required this.onSelect,
    this.thumbSize = 64,
  });

  final int count;
  final IndexedWidgetBuilder thumbBuilder;
  final int selected;
  final ValueChanged<int> onSelect;
  final double thumbSize;

  @override
  State<SsThumbRail> createState() => _SsThumbRailState();
}

class _SsThumbRailState extends State<SsThumbRail> {
  final _s = ScrollController();
  bool _podeSubir = false;
  bool _podeDescer = false;

  double get _passo => widget.thumbSize + 10;

  @override
  void initState() {
    super.initState();
    _s.addListener(_atualiza);
    WidgetsBinding.instance.addPostFrameCallback((_) => _atualiza());
  }

  void _atualiza() {
    if (!mounted || !_s.hasClients) return;
    final p = _s.position;
    final sobe = p.pixels > 1;
    final desce = p.pixels < p.maxScrollExtent - 1;
    if (sobe != _podeSubir || desce != _podeDescer) {
      setState(() {
        _podeSubir = sobe;
        _podeDescer = desce;
      });
    }
  }

  void _rola(int dir) {
    final alvo = (_s.offset + dir * _passo).clamp(0.0, _s.position.maxScrollExtent);
    _s.animateTo(alvo, duration: reduceMotion(context) ? Duration.zero : SsMotion.base, curve: Curves.easeOutCubic);
  }

  @override
  void didUpdateWidget(SsThumbRail old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected && _s.hasClients) {
      final vp = _s.position.viewportDimension;
      final top = widget.selected * _passo;
      if (top < _s.offset || top + _passo > _s.offset + vp) {
        final alvo = (top - (vp - _passo) / 2).clamp(0.0, _s.position.maxScrollExtent);
        _s.animateTo(alvo, duration: SsMotion.base, curve: Curves.easeOutCubic);
      }
    }
  }

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  Widget _seta(IconData icon, bool on, int dir, String label) {
    final c = SsColors.of(context);
    return AnimatedOpacity(
      opacity: on ? 1 : 0,
      duration: SsMotion.fast,
      child: IgnorePointer(
        ignoring: !on,
        child: Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: SsPressable(
            onTap: () => _rola(dir),
            child: SizedBox(
              width: math.max(48, widget.thumbSize),
              height: 36,
              child: Icon(icon, color: c.ink2),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return SizedBox(
      width: math.max(48, widget.thumbSize + 8),
      child: Column(
        children: [
          _seta(Icons.keyboard_arrow_up_rounded, _podeSubir, -1, SsStrings.of(context).previousThumbs),
          Expanded(
            child: ListView.separated(
              controller: _s,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: widget.count,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final on = i == widget.selected;
                return Center(
                  child: Semantics(
                    button: true,
                    selected: on,
                    label: SsStrings.of(context).imageOf(i + 1, widget.count),
                    child: SsPressable(
                      onTap: () {
                        if (!on) widget.onSelect(i);
                      },
                      child: AnimatedOpacity(
                        opacity: on ? 1 : .55,
                        duration: SsMotion.fast,
                        child: AnimatedContainer(
                          duration: reduceMotion(context) ? Duration.zero : SsMotion.base,
                          curve: SsMotion.spring,
                          width: widget.thumbSize,
                          height: widget.thumbSize,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.field + 3),
                            border: Border.all(color: on ? c.accent : Colors.transparent, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.field - 2),
                            child: widget.thumbBuilder(context, i),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _seta(Icons.keyboard_arrow_down_rounded, _podeDescer, 1, SsStrings.of(context).nextThumbs),
        ],
      ),
    );
  }
}
