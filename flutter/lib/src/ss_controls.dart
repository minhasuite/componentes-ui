import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'motion.dart';

/// Seletor de 2 a 4 opções (período, abas de uma tela): trilha afundada e uma
/// pílula que desliza com mola até a opção escolhida. [icons] (um por opção,
/// `null` sem ícone) vai antes do texto; opção em [disabled] fica apagada.
class SsSegmented<T> extends StatelessWidget {
  const SsSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.icons,
    this.disabled = const {},
  }) : assert(segments.length >= 2),
       assert(icons == null || icons.length == segments.length);

  final List<(T, String)> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final List<IconData?>? icons;
  final Set<T> disabled;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final n = segments.length;
    final i = segments.indexWhere((s) => s.$1 == value).clamp(0, n - 1);
    final move = reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 340);
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: Alignment(n == 1 ? 0 : -1 + 2 * i / (n - 1), 0),
            duration: move,
            curve: Curves.easeOutBack,
            child: FractionallySizedBox(
              widthFactor: 1 / n,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  // No escuro a pílula precisa ser mais clara que a trilha.
                  color: c.isDark ? Color.lerp(c.field, Colors.white, .1) : c.surface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: const [BoxShadow(color: Color(0x1F141628), offset: Offset(0, 1), blurRadius: 3)],
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
                                ? c.accentText
                                : c.muted.withValues(alpha: disabled.contains(segments[k].$1) ? .45 : 1),
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

/// Filtro em pílula: marcado fica na cor da marca a 12% com um ✓ que entra
/// crescendo; [count] aparece em DM Mono.
class SsFilterChip extends StatelessWidget {
  const SsFilterChip(this.label, {super.key, required this.selected, required this.onTap, this.count, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  /// Ícone antes do texto; marcado, dá lugar ao ✓.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final fg = selected ? c.accentText : c.ink2;
    final dur = reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 220);
    return Semantics(
      button: true,
      selected: selected,
      child: SsPressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: dur,
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? c.accent.withValues(alpha: c.isDark ? .2 : .12) : c.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: selected ? c.accent.withValues(alpha: .35) : c.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: dur,
                curve: Curves.easeOutBack,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: Icon(Icons.check_rounded, size: 16, color: fg),
                      )
                    : icon == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: Icon(icon, size: 16, color: fg),
                      ),
              ),
              Text(
                label,
                style: TextStyle(color: fg, fontSize: AppType.sub, fontWeight: FontWeight.w700),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: AppTheme.number(context, size: AppType.meta, color: selected ? fg : c.muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Faixa de filtros numa linha só, que rola na horizontal (sem quebrar).
class SsChipBar extends StatelessWidget {
  const SsChipBar({super.key, required this.children, this.padding = const EdgeInsets.symmetric(horizontal: 16)});

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: padding,
    child: Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(width: 8), children[i]],
      ],
    ),
  );
}

/// Busca "afundada": sem borda, fundo de campo; no foco ganha anel e halo na
/// cor da marca. Botão de limpar quando há texto. Com [debounce], o
/// [onChanged] só dispara depois que a pessoa para de digitar (busca no
/// servidor); limpar dispara na hora. [suffix] fica no fim (filtro, leitor de código).
class SsSearchField extends StatefulWidget {
  const SsSearchField({
    super.key,
    this.controller,
    this.hint = 'Buscar',
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.debounce,
    this.suffix,
  });

  final Duration? debounce;
  final Widget? suffix;

  final TextEditingController? controller;
  final String hint;
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
                hintText: widget.hint,
                hintStyle: TextStyle(color: c.muted, fontSize: AppType.body, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          if (_ctrl.text.isNotEmpty)
            IconButton(
              tooltip: 'Limpar',
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
