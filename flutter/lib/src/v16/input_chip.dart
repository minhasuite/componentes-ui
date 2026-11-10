// v0.16: chip removível (par do .ss-tag da gem: etiqueta com ✕).
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../ss_strings.dart';

/// Chip de um valor escolhido que se tira com o ✕ (destino, etiqueta,
/// validade): fundo suave da marca, [icon] opcional antes, rótulo que termina
/// em "…" e o ✕ com alvo de 48. [onPressed] (tocar no chip: editar, trocar a
/// data) e [onDeleted] (o ✕; nulo, o ✕ some) são independentes. O web é o
/// `.ss-tag` (`<span class="ss-tag"><span>Lisboa</span><button>×</button></span>`).
///
/// `SsInputChip('Lisboa', icon: Icons.place_outlined, onDeleted: () => remover(d))`
class SsInputChip extends StatelessWidget {
  const SsInputChip(
    this.label, {
    super.key,
    this.icon,
    this.onPressed,
    this.onDeleted,
    this.deleteTooltip,
    this.tooltip,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final VoidCallback? onDeleted;

  /// Dica e rótulo do ✕ para o leitor de tela. Padrão: [SsStrings.removeItem].
  final String? deleteTooltip;

  /// Dica do chip (com [onPressed]).
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    final fg = c.accentText;
    final h = d.chipHeight - 2;
    Widget corpo = Padding(
      padding: EdgeInsets.only(left: d.padX - 6, right: onDeleted == null ? d.padX - 6 : 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: fg), SizedBox(width: d.space(5))],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(color: fg, fontSize: d.font(AppType.sub), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (onPressed != null) {
      corpo = Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: SsPressable(onTap: onPressed, child: corpo),
      );
      if (tooltip != null) corpo = Tooltip(message: tooltip!, child: corpo);
    } else {
      corpo = Semantics(label: label, excludeSemantics: true, child: corpo);
    }
    final rotuloX = deleteTooltip ?? s.removeItem(label);
    return SsTapTarget(
      minSize: Size(0, d.minTarget),
      child: Container(
        height: h,
        decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: corpo),
            if (onDeleted != null)
              Tooltip(
                message: rotuloX,
                child: Semantics(
                  button: true,
                  label: rotuloX,
                  excludeSemantics: true,
                  child: SsTapTarget(
                    minSize: Size(d.minTarget, d.minTarget),
                    child: SsPressable(
                      onTap: onDeleted,
                      child: SizedBox(
                        width: h,
                        height: h,
                        child: Icon(Icons.close_rounded, size: 16, color: fg),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
