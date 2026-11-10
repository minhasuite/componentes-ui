// v0.14: nota e tarefa com comando (pares do Ss::NoteComponent/.ss-note e do
// .ss-checklist com [role=checkbox] + .ss-checklist-x).
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../density.dart';
import '../ss_badge.dart' show SsTone;
import '../ss_fields.dart' show SsCheckRow;
import '../ss_strings.dart';
import '../v10/tela_barra.dart' show SsIconButton;

/// Nota: a frase curta e apagada no lugar do conteúdo de um card ou de uma
/// seção ("Nenhum alerta aberto", "Escolha o medidor", "Sem leituras"), com
/// [icon] opcional antes. Não é o estado vazio ilustrado ([SsEmptyState]): é
/// uma linha. O [tone] pinta o ícone; `warning` e `danger` pintam a frase
/// também (é aviso) e viram região viva para o leitor de tela. O web é o
/// `Ss::NoteComponent` (`.ss-note`).
class SsNote extends StatelessWidget {
  const SsNote(this.text, {super.key, this.icon, this.tone = SsTone.neutral});

  final String text;
  final IconData? icon;
  final SsTone tone;

  bool get _alert => tone == SsTone.warning || tone == SsTone.danger;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final cores = tone.colors(context);
    final textColor = _alert ? cores.text : c.muted;
    final iconColor = switch (tone) {
      SsTone.neutral => c.muted,
      SsTone.warning || SsTone.danger => cores.text,
      _ => cores.solid,
    };
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: d.font(18), color: iconColor),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: d.font(AppType.body),
              fontWeight: _alert ? FontWeight.w600 : FontWeight.w400,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
    return _alert ? Semantics(liveRegion: true, child: row) : row;
  }
}

/// Tarefa com comando: a linha inteira marca/desmarca ([onChanged]; nulo =
/// só leitura), marcada fica riscada e apagada, e o × no fim remove
/// ([onDelete], dica [deleteTooltip], padrão "Excluir"). Monta o [SsCheckRow]
/// com o [SsIconButton] do pacote. O web é a `.ss-checklist` com
/// `button[role=checkbox]` e o `.ss-checklist-x`.
class SsTaskItem extends StatelessWidget {
  const SsTaskItem(this.label, {super.key, this.done = false, this.onChanged, this.onDelete, this.deleteTooltip});

  final String label;
  final bool done;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onDelete;
  final String? deleteTooltip;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    return Row(
      children: [
        Expanded(
          child: SsCheckRow(
            value: done,
            onChanged: onChanged,
            child: Text(
              label,
              style: TextStyle(
                fontSize: d.font(AppType.body),
                fontWeight: FontWeight.w600,
                decoration: done ? TextDecoration.lineThrough : null,
                decorationColor: c.muted,
                color: done ? c.muted : c.ink,
              ),
            ),
          ),
        ),
        if (onDelete != null)
          SsIconButton(
            tooltip: deleteTooltip ?? '${SsStrings.of(context).delete}: $label',
            onPressed: onDelete,
            icon: Icons.close_rounded,
            size: d.controlHeightSmall,
            color: c.muted,
          ),
      ],
    );
  }
}
