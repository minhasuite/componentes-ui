import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'motion.dart';
import 'ss_context_menu.dart';
import 'ss_odometer.dart';
import 'ss_strings.dart';

/// Barra de seleção múltipla: sobe de baixo com mola ([SsMotion.bounce])
/// quando [count] > 0 ("3 selecionados", com o número rolando), as [actions]
/// em ícones e o X
/// ([onClear]). Ponha num `Stack` alinhado embaixo ou no `bottomNavigationBar`.
class SsSelectionBar extends StatefulWidget {
  const SsSelectionBar({super.key, required this.count, required this.actions, required this.onClear});

  final int count;
  final List<SsContextAction> actions;
  final VoidCallback onClear;

  @override
  State<SsSelectionBar> createState() => _SsSelectionBarState();
}

class _SsSelectionBarState extends State<SsSelectionBar> {
  // Saindo, a barra mostra o último número (e não "0 selecionados").
  late int _ultimo = widget.count;

  @override
  Widget build(BuildContext context) {
    if (widget.count > 0) _ultimo = widget.count;
    final c = SsColors.of(context);
    final on = widget.count > 0;
    final d = reduceMotion(context) ? Duration.zero : (on ? SsMotion.indicator : SsMotion.base);
    return IgnorePointer(
      ignoring: !on,
      // Sobe com a mola de verdade (passa um pouco e assenta); desce reto.
      child: AnimatedSlide(
        offset: on ? Offset.zero : const Offset(0, 1.5),
        duration: d,
        curve: on ? SsMotion.bounce : Curves.easeIn,
        child: AnimatedOpacity(
          opacity: on ? 1 : 0,
          duration: d,
          child: SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: c.headerBg,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: c.isDark ? Border.all(color: c.headerLine) : null,
                boxShadow: AppShadows.sheet,
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: SsStrings.of(context).clearSelection,
                    onPressed: widget.onClear,
                    icon: const Icon(Icons.close_rounded, color: AppColors.onDarkIcon),
                  ),
                  SsOdometer('$_ultimo', size: AppType.md, weight: FontWeight.w700, color: AppColors.onDark),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      SsStrings.of(context).selectedCount(_ultimo),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.onDark,
                        fontSize: AppType.body,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  for (final a in widget.actions)
                    IconButton(
                      tooltip: a.label,
                      onPressed: a.onTap,
                      icon: Icon(a.icon, color: a.destructive ? const Color(0xFFF2899A) : AppColors.onDark),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Item selecionável de lista: toque longo entra na seleção ([onToggle]);
/// com [selecting], o toque marca/desmarca, aparece o círculo de ✓ à
/// esquerda (entra com mola) e o selecionado ganha fundo tonal. O círculo é
/// um [SsCheckBox] redondo: ao marcar, pula, a cor inunda do centro, o ✓ se
/// desenha e sai um estouro; ao desmarcar, desfaz e balança.
class SsSelectable extends StatelessWidget {
  const SsSelectable({
    super.key,
    required this.selected,
    required this.selecting,
    required this.onToggle,
    required this.child,
  });

  final bool selected;
  final bool selecting;
  final VoidCallback onToggle;
  final Widget child;

  void _toggle() {
    HapticFeedback.selectionClick();
    onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 300);
    return Semantics(
      selected: selecting ? selected : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: selecting ? null : _toggle,
        onTap: selecting ? _toggle : null,
        child: AnimatedContainer(
          duration: d,
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected ? c.accentSoft : c.accentSoft.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
          child: Row(
            children: [
              // Aberto, não recorta (o estouro do círculo sai para fora); a
              // bolinha entra encolhida, então nada vaza enquanto a vaga abre.
              ClipRect(
                clipBehavior: selecting ? Clip.none : Clip.hardEdge,
                child: AnimatedAlign(
                  duration: d,
                  curve: Curves.easeOut,
                  alignment: Alignment.centerRight,
                  widthFactor: selecting ? 1 : 0,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6, right: 10),
                    child: AnimatedScale(
                      scale: selecting ? 1 : 0,
                      duration: d,
                      curve: SsMotion.bounce,
                      // Marcou: o círculo encolhe, pula, a cor inunda do centro, o ✓
                      // se desenha e sai um estouro; desmarcou: desfaz e balança.
                      child: SsCheckBox(
                        value: selected,
                        circle: true,
                        borderWidth: 2,
                        emptyColor: c.accent.withValues(alpha: 0),
                      ),
                    ),
                  ),
                ),
              ),
              // Selecionando, o toque é da seleção e não do item.
              Expanded(
                child: IgnorePointer(
                  ignoring: selecting,
                  // Material próprio: o splash do InkWell/ListTile do item pinta acima do fundo tonal.
                  child: Material(type: MaterialType.transparency, child: child),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
