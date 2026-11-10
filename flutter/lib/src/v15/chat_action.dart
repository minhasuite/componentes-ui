// v0.15: cartão de ação a confirmar no chat (par do Ss::ChatActionComponent da gem).
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../motion_view.dart';
import '../ss_button.dart';
import '../ss_strings.dart';

/// Situação do [SsChatActionCard].
enum SsChatActionState { pending, confirmed, cancelled, failed }

/// O que o assistente propõe fazer ("Lançar despesa de R$ 45 no Nubank"), com
/// os dados em linhas e Confirmar/Cancelar. Vai dentro de um [SsChatBubble]
/// (`child:`) ou sozinho na lista. Pendente, mostra os botões; [busy] trava os
/// dois e põe o carregando no Confirmar (não confirma duas vezes). Resolvido,
/// os botões dão lugar à frase do resultado ([result], ou "Feito", "Cancelado",
/// "Não deu certo"). [danger] pinta o Confirmar de vermelho (excluir). Entra
/// com a mola. O web é o `Ss::ChatActionComponent`.
///
/// `SsChatActionCard(title: 'Lançar despesa', icon: Icons.credit_card, rows: [('Valor', 'R$ 45,00'), ('Cartão', 'Nubank')], onConfirm: confirmar, onCancel: cancelar)`
class SsChatActionCard extends StatelessWidget {
  const SsChatActionCard({
    super.key,
    required this.title,
    this.rows = const [],
    this.description,
    this.icon,
    this.state = SsChatActionState.pending,
    this.result,
    this.onConfirm,
    this.onCancel,
    this.confirmLabel,
    this.cancelLabel,
    this.busy = false,
    this.danger = false,
  });

  final String title;
  final List<(String, String)> rows;
  final String? description;
  final IconData? icon;
  final SsChatActionState state;
  final String? result;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final String? confirmLabel;
  final String? cancelLabel;
  final bool busy;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    final pendente = state == SsChatActionState.pending;
    final (frase, corFrase) = switch (state) {
      SsChatActionState.confirmed => (result ?? s.chatConfirmed, c.successText),
      SsChatActionState.cancelled => (result ?? s.chatCancelled, c.muted),
      SsChatActionState.failed => (result ?? s.chatFailed, c.dangerText),
      SsChatActionState.pending => ('', c.muted),
    };
    final card = Container(
      padding: EdgeInsets.all(d.space(14)),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.field + 4),
        border: Border.all(color: pendente ? Color.alphaBlend(c.accent.withValues(alpha: .4), c.line) : c.line),
        boxShadow: pendente ? AppShadows.card : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(AppRadius.thumb)),
                  child: Icon(icon, size: 18, color: c.accentText),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.chatAction.toUpperCase(),
                      style: TextStyle(
                        fontSize: AppType.micro,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .8,
                        color: c.accentText,
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(fontSize: d.font(AppType.body), fontWeight: FontWeight.w800, color: c.ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 6),
            Text(
              description!,
              style: TextStyle(fontSize: AppType.sub, color: c.ink2),
            ),
          ],
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(AppRadius.thumb)),
              child: Column(
                children: [
                  for (final (k, v) in rows)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            k,
                            style: TextStyle(fontSize: AppType.sub, color: c.muted),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              v,
                              textAlign: TextAlign.right,
                              style: TextStyle(fontSize: AppType.sub, fontWeight: FontWeight.w700, color: c.ink),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (pendente)
            Row(
              children: [
                if (onCancel != null)
                  Expanded(
                    child: SsButton(
                      label: cancelLabel ?? s.cancel,
                      variant: SsButtonVariant.ghost,
                      small: true,
                      onPressed: busy ? null : onCancel,
                    ),
                  ),
                if (onCancel != null && onConfirm != null) const SizedBox(width: 8),
                if (onConfirm != null)
                  Expanded(
                    child: SsButton(
                      label: confirmLabel ?? s.confirm,
                      variant: danger ? SsButtonVariant.danger : SsButtonVariant.primary,
                      small: true,
                      loading: busy,
                      onPressed: busy ? null : onConfirm,
                    ),
                  ),
              ],
            )
          else
            Semantics(
              liveRegion: true,
              child: Text(
                frase,
                style: TextStyle(fontSize: AppType.sub, fontWeight: FontWeight.w700, color: corFrase),
              ),
            ),
        ],
      ),
    );
    return Semantics(
      container: true,
      label: title,
      child: SsTweenInView(
        end: 1,
        duration: const Duration(milliseconds: 350),
        curve: SsMotion.bounce,
        builder: (_, t, child) => Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, 8 * (1 - t)), child: child),
        ),
        child: card,
      ),
    );
  }
}
