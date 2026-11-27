// v1.9 · UX transversal: o cartão da tela de sincronização (o "Mais › Sincronização" do minhas-vendas-app).
import 'package:material_ui/material_ui.dart';

import '../../app_theme.dart';
import '../../density.dart';
import '../../ss_button.dart';
import '../../ss_card.dart';
import '../../ss_strings.dart';
import '../../ss_sync.dart';
import '../../v1130/strings.dart';

/// O cartão do topo da tela da fila de envio: quando foi a última sincronização ("Sincronizado às 14:32",
/// "Nunca sincronizado"), o erro da última tentativa (em vermelho), a pílula [SsSyncStatus] com o que falta
/// enviar, um [details] opcional ("120 clientes · 40 pedidos no aparelho") e o botão "Sincronizar agora"
/// ([onSyncNow]), que fica carregando enquanto [state] é [SsSyncState.sending]. A lista da fila embaixo é do
/// app (cada item com o [SsSyncDot]).
///
/// ```dart
/// SsSyncPanel(
///   state: SsSyncStatus.resolve(syncing: s.syncing, failed: falhas, offline: semRede, pending: fila.length),
///   pendingCount: fila.length, failedCount: falhas, lastSyncedAt: s.syncedAt, error: s.erro,
///   onSyncNow: () => sync.run(force: true),
/// )
/// ```
/// Só app: a fila mora no aparelho; o web salva direto no servidor (o `Ss::SyncStatusComponent` é a pílula).
class SsSyncPanel extends StatelessWidget {
  const SsSyncPanel({
    super.key,
    required this.state,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.lastSyncedAt,
    this.error,
    this.details,
    this.onSyncNow,
    this.now,
    this.conflictCount = 0,
    this.onResolveConflicts,
  });

  /// v1.13.0: registros que mudaram aqui e no servidor; com [onResolveConflicts], a linha "2 registros em conflito ·
  /// Resolver", que abre o [SsConflictResolver] do app.
  final int conflictCount;
  final VoidCallback? onResolveConflicts;

  final SsSyncState state;
  final int pendingCount;
  final int failedCount;
  final DateTime? lastSyncedAt;

  /// Mensagem da última falha (ex. "Sem conexão: usando os dados do aparelho.").
  final String? error;

  /// Linha apagada com o que há no aparelho.
  final String? details;

  /// "Sincronizar agora"; nulo esconde o botão.
  final VoidCallback? onSyncNow;

  /// O "agora" do rótulo (testes e catálogo).
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    final sending = state == SsSyncState.sending;
    final titulo = sending ? s.syncSending : SsSyncStatus.lastSyncedLabel(lastSyncedAt, s, now);
    return SsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(
                    titulo,
                    style: TextStyle(color: c.ink, fontWeight: FontWeight.w800, fontSize: d.font(AppType.md)),
                  ),
                ),
              ),
              SizedBox(width: d.gap),
              SsSyncStatus(state: state, pendingCount: pendingCount, failedCount: failedCount),
            ],
          ),
          if (error != null && error!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              error!,
              style: TextStyle(color: c.dangerText, fontSize: d.font(AppType.sub)),
            ),
          ],
          if (details != null) ...[
            const SizedBox(height: 8),
            Text(
              details!,
              style: TextStyle(color: c.muted, fontSize: d.font(AppType.meta)),
            ),
          ],
          if (conflictCount > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.sync_problem_rounded, size: 18, color: c.aquecText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    conflictCount == 1
                        ? SsTrustStrings.of(context).conflictCountOne
                        : SsTrustStrings.fill(SsTrustStrings.of(context).conflictCount, {'count': conflictCount}),
                    style: TextStyle(color: c.aquecText, fontWeight: FontWeight.w700, fontSize: d.font(AppType.sub)),
                  ),
                ),
                if (onResolveConflicts != null)
                  SsButton.text(label: SsTrustStrings.of(context).conflictResolve, onPressed: onResolveConflicts),
              ],
            ),
          ],
          if (onSyncNow != null) ...[
            SizedBox(height: d.gap),
            SsButton(
              label: s.syncNow,
              icon: Icons.sync_rounded,
              loading: sending,
              onPressed: sending ? null : onSyncNow,
            ),
          ],
        ],
      ),
    );
  }
}
