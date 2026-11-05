import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'motion.dart';
import 'ss_strings.dart';

/// Seletor de 2 a 4 opções (período, abas de uma tela): trilha afundada e uma
/// pílula que desliza com mola até a opção escolhida, esticando no caminho
/// ([SsSlidingIndicator]). [icons] (um por opção,
/// `null` sem ícone) vai antes do texto; opção em [disabled] fica apagada.
/// [onDark]: variante "embutida" para dentro de cabeçalho escuro
/// (`SsCurvedHeader`): trilha clara translúcida e texto claro.
class SsSegmented<T> extends StatelessWidget {
  const SsSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.icons,
    this.disabled = const {},
    this.onDark = false,
  }) : assert(segments.length >= 2),
       assert(icons == null || icons.length == segments.length);

  final List<(T, String)> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final List<IconData?>? icons;
  final Set<T> disabled;

  /// Sobre fundo escuro (cabeçalho em `brandDeep`/`headerBg`).
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final n = segments.length;
    final i = segments.indexWhere((s) => s.$1 == value).clamp(0, n - 1);
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: onDark ? AppColors.onDark.withValues(alpha: .1) : c.field,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: onDark ? Border.all(color: AppColors.onDark.withValues(alpha: .08)) : null,
      ),
      child: Stack(
        children: [
          // A pílula desliza com mola até a opção nova, esticando no caminho.
          Positioned.fill(
            child: SsSlidingIndicator(
              index: i,
              count: n,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  // No escuro a pílula precisa ser mais clara que a trilha.
                  color: onDark
                      ? AppColors.onDark
                      : c.isDark
                      ? Color.lerp(c.field, Colors.white, .1)
                      : c.surface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: onDark
                      ? const []
                      : const [BoxShadow(color: Color(0x1F141628), offset: Offset(0, 1), blurRadius: 3)],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var k = 0; k < n; k++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: k == i,
                    enabled: !disabled.contains(segments[k].$1),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (k == i || disabled.contains(segments[k].$1)) return;
                        HapticFeedback.selectionClick();
                        onChanged(segments[k].$1);
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                            color: k == i
                                ? (onDark ? c.brand.accentHoverLight : c.accentText)
                                : (onDark ? AppColors.onDarkSoft : c.muted).withValues(
                                    alpha: disabled.contains(segments[k].$1) ? .45 : 1,
                                  ),
                            fontSize: AppType.sub,
                            fontWeight: k == i ? FontWeight.w800 : FontWeight.w600,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (icons?[k] case final ic?) ...[
                                Builder(
                                  builder: (ctx) => Icon(ic, size: 16, color: DefaultTextStyle.of(ctx).style.color),
                                ),
                                const SizedBox(width: 5),
                              ],
                              Flexible(child: Text(segments[k].$2, maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Filtro em pílula: marcado fica na cor da marca a 12%, dá um pulinho com
/// mola e o ✓ se desenha no lugar do ícone; [count] aparece em DM Mono.
class SsFilterChip extends StatelessWidget {
  const SsFilterChip(
    this.label, {
    super.key,
    required this.selected,
    required this.onTap,
    this.count,
    this.icon,
    this.color,
    this.swatch = false,
    this.solid = false,
  });

  final String label;
  final bool selected;

  /// Marcado em cor sólida da marca com texto branco (em vez da marca a 12%):
  /// o filtro "atual" das abas de categoria. O `.ss-chip.is-solid` do web.
  final bool solid;

  /// Nulo desabilita: o chip apaga e não responde ao toque.
  final VoidCallback? onTap;
  final int? count;

  /// Ícone antes do texto; marcado, dá lugar ao ✓.
  final IconData? icon;

  /// Amostra de cor (escolher cor de luz, etiqueta): uma bolinha antes do
  /// texto, com borda para a cor clara não sumir no fundo. Marcado, o ✓
  /// aparece dentro da bolinha.
  final Color? color;

  /// Com [color], pinta o chip inteiro com a cor (texto claro ou escuro
  /// conforme a cor) em vez da bolinha; marcado ganha o anel da marca.
  final bool swatch;

  bool get _enabled => onTap != null;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final dur = reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 220);
    final cor = color;
    final cheio = swatch && cor != null;
    // Texto sobre a cor cheia: escuro em cor clara, branco em cor escura.
    final sobreCor = cor == null
        ? null
        : (ThemeData.estimateBrightnessForColor(cor) == Brightness.light ? const Color(0xFF1A1A2E) : Colors.white);
    final macico = solid && selected && !cheio && cor == null;
    final fg = cheio ? sobreCor! : (macico ? AppColors.onDark : (selected ? c.accentText : c.ink2));
    final temIcone = cor == null && (selected || icon != null);
    // Borda que separa a cor do fundo (cor clara no claro, escura no escuro).
    final bordaCor = c.isDark ? Colors.white.withValues(alpha: .28) : Colors.black.withValues(alpha: .22);

    Widget marca;
    if (cor != null && !cheio) {
      // Bolinha da cor, com o ✓ dentro quando marcada.
      marca = Padding(
        padding: const EdgeInsets.only(right: 7),
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: cor,
            shape: BoxShape.circle,
            border: Border.all(color: bordaCor),
          ),
          alignment: Alignment.center,
          child: SsCheckMark(value: selected, size: 12, color: sobreCor!, strokeWidth: 2.2),
        ),
      );
    } else if (cheio) {
      marca = ClipRect(
        child: AnimatedContainer(
          duration: dur,
          curve: Curves.easeOutCubic,
          width: selected ? 21 : 0,
          child: OverflowBox(
            minWidth: 21,
            maxWidth: 21,
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(right: 5),
              child: SsCheckMark(value: selected, size: 16, color: fg, strokeWidth: 2.2),
            ),
          ),
        ),
      );
    } else {
      // A vaga do ícone abre (sem ícone) e o ✓ toma o lugar dele.
      marca = ClipRect(
        child: AnimatedContainer(
          duration: dur,
          curve: Curves.easeOutCubic,
          width: temIcone ? 21 : 0,
          child: OverflowBox(
            minWidth: 21,
            maxWidth: 21,
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(right: 5),
              child: SizedBox.square(
                dimension: 16,
                child: Stack(
                  children: [
                    if (icon != null)
                      AnimatedScale(
                        duration: dur,
                        scale: selected ? 0 : 1,
                        child: Icon(icon, size: 16, color: fg),
                      ),
                    SsCheckMark(value: selected, size: 16, color: fg, strokeWidth: 2.2),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final Color fundo;
    final Border borda;
    if (cheio) {
      fundo = cor;
      // Marcado: anel da marca por fora; senão, a borda que separa a cor clara.
      borda = selected ? Border.all(color: c.accent, width: 2) : Border.all(color: bordaCor);
    } else {
      fundo = macico ? c.accentSolid : (selected ? c.accent.withValues(alpha: c.isDark ? .2 : .12) : c.surface);
      borda = Border.all(color: macico ? c.accentSolid : (selected ? c.accent.withValues(alpha: .35) : c.line));
    }

    return Semantics(
      button: true,
      selected: selected,
      enabled: _enabled,
      child: SsPressable(
        onTap: onTap,
        enabled: _enabled,
        // Marcou: o chip dá um pulinho com mola e o ✓ se desenha.
        child: AnimatedOpacity(
          duration: dur,
          opacity: _enabled ? 1 : .45,
          child: SsPop(
            active: selected,
            from: .9,
            child: AnimatedContainer(
              duration: dur,
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: fundo,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: borda,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  marca,
                  Text(
                    label,
                    style: TextStyle(color: fg, fontSize: AppType.sub, fontWeight: FontWeight.w700),
                  ),
                  if (count != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      '$count',
                      style: AppTheme.number(
                        context,
                        size: AppType.meta,
                        color: cheio || macico ? fg.withValues(alpha: .8) : (selected ? fg : c.muted),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Faixa de filtros numa linha só, que rola na horizontal (sem quebrar).
///
/// v0.10.2: [fade] apaga a borda direita enquanto há mais chips para rolar
/// (mostra que tem mais; o `.ss-chips` do web no celular). [wrapAbove] quebra
/// em várias linhas, sem rolar, quando a largura passa disso (tablet).
class SsChipBar extends StatelessWidget {
  const SsChipBar({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.fade = false,
    this.wrapAbove,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final bool fade;
  final double? wrapAbove;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      if (wrapAbove != null && box.maxWidth >= wrapAbove!) {
        return Padding(
          padding: padding,
          child: Wrap(spacing: 8, runSpacing: 8, children: children),
        );
      }
      final faixa = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: fade ? padding.add(const EdgeInsetsDirectional.only(end: 32)) : padding,
        child: Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(width: 8), children[i]],
          ],
        ),
      );
      if (!fade) return faixa;
      return _FaixaEsmaecida(child: faixa);
    },
  );
}

/// Some a borda do fim enquanto ainda dá para rolar.
class _FaixaEsmaecida extends StatefulWidget {
  const _FaixaEsmaecida({required this.child});
  final SingleChildScrollView child;

  @override
  State<_FaixaEsmaecida> createState() => _FaixaEsmaecidaState();
}

class _FaixaEsmaecidaState extends State<_FaixaEsmaecida> {
  bool _temMais = true;

  bool _ouvir(ScrollMetrics m) {
    final mais = m.extentAfter > 1;
    if (mais != _temMais) setState(() => _temMais = mais);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => _ouvir(n.metrics),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => _ouvir(n.metrics),
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (r) => LinearGradient(
            begin: rtl ? Alignment.centerRight : Alignment.centerLeft,
            end: rtl ? Alignment.centerLeft : Alignment.centerRight,
            colors: [
              const Color(0xFF000000),
              const Color(0xFF000000),
              _temMais ? const Color(0x00000000) : const Color(0xFF000000),
            ],
            stops: [0, r.width <= 40 ? 0 : (r.width - 40) / r.width, 1],
          ).createShader(r),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Busca "afundada": sem borda, fundo de campo; no foco ganha anel e halo na
/// cor da marca. Botão de limpar quando há texto. Com [debounce], o
/// [onChanged] só dispara depois que a pessoa para de digitar (busca no
/// servidor); limpar dispara na hora. [suffix] fica no fim (filtro, leitor de código).
class SsSearchField extends StatefulWidget {
  const SsSearchField({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.debounce,
    this.suffix,
  });

  final Duration? debounce;
  final Widget? suffix;

  final TextEditingController? controller;

  /// Padrão: [SsStrings.search].
  final String? hint;
  final ValueChanged<String>? onChanged;

  /// Enter do teclado (busca que vai ao servidor só ao confirmar).
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  State<SsSearchField> createState() => _SsSearchFieldState();
}

class _SsSearchFieldState extends State<SsSearchField> {
  final _focus = FocusNode();
  late final _ctrl = widget.controller ?? TextEditingController();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    _ctrl.addListener(() => setState(() {}));
  }

  Timer? _timer;

  void _changed(String v) {
    _timer?.cancel();
    final d = widget.debounce;
    if (d == null || v.isEmpty) return widget.onChanged?.call(v);
    _timer = Timer(d, () => widget.onChanged?.call(v));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focus.dispose();
    if (widget.controller == null) _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final on = _focus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 48,
      decoration: BoxDecoration(
        color: on ? c.surface : c.field,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: on ? c.accent.withValues(alpha: .45) : Colors.transparent, width: 2),
        boxShadow: on ? [BoxShadow(color: c.accent.withValues(alpha: .12), spreadRadius: 4)] : const [],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search_rounded, size: 22, color: on ? c.accent : c.muted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              autofocus: widget.autofocus,
              onChanged: _changed,
              onSubmitted: (v) {
                _timer?.cancel();
                widget.onSubmitted?.call(v);
              },
              textInputAction: TextInputAction.search,
              style: TextStyle(color: c.ink, fontSize: AppType.body, fontWeight: FontWeight.w600),
              decoration: InputDecoration.collapsed(
                hintText: widget.hint ?? SsStrings.of(context).search,
                hintStyle: TextStyle(color: c.muted, fontSize: AppType.body, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          if (_ctrl.text.isNotEmpty)
            IconButton(
              tooltip: SsStrings.of(context).clear,
              icon: Icon(Icons.close_rounded, size: 20, color: c.muted),
              onPressed: () {
                _ctrl.clear();
                _changed('');
              },
            )
          else if (widget.suffix == null)
            const SizedBox(width: 12),
          ?widget.suffix,
        ],
      ),
    );
  }
}
