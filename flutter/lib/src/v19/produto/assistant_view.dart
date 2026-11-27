// v1.9 · produto: assistente com IA (par do Ss::AssistantComponent do web). Generaliza o que o meu-personal-app
// (Assistente), o meu-financeiro-app (chat /ai/chat) e o meu-gestor-app (Pergunte à IA) montaram à mão: conversas,
// histórico, atalhos, cartão de ação sugerida, "respondendo", resposta por polling (o app faz; aqui só o estado),
// plano sem direito e cota.
import 'package:material_ui/material_ui.dart';

import '../../app_theme.dart';
import '../../density.dart';
import '../../format.dart';
import '../../ss_badge.dart';
import '../../ss_chat.dart';
import '../../ss_controls.dart' show SsFilterChip;
import '../../ss_dialogs.dart';
import '../../ss_empty_state.dart';
import '../../ss_list.dart';
import '../../ss_plan.dart';
import '../../ss_sheet.dart';
import '../../ss_strings.dart';
import '../../v10/tela_barra.dart' show SsIconButton, SsIconButtonVariant, SsSpinner;
import '../../v15/chat_action.dart';

/// Situação de uma mensagem do [SsAssistantView]. [pending]: a resposta ainda não chegou (o app pergunta ao
/// servidor de tempos em tempos e troca a mensagem por `ready`/`failed`); aparece o [SsThinking].
enum SsAssistantStatus { ready, pending, failed }

/// Ação sugerida pela resposta ("Montar treino", "Lançar despesa"): vira um [SsChatActionCard] logo abaixo da
/// bolha. Sem [onCancel], só o botão de confirmar.
@immutable
class SsAssistantAction {
  const SsAssistantAction({
    required this.title,
    this.description,
    this.icon = Icons.auto_awesome_outlined,
    this.rows = const [],
    this.confirmLabel,
    this.cancelLabel,
    this.onConfirm,
    this.onCancel,
    this.state = SsChatActionState.pending,
    this.result,
    this.busy = false,
    this.danger = false,
  });

  final String title;
  final String? description;
  final IconData? icon;
  final List<(String, String)> rows;
  final String? confirmLabel;
  final String? cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final SsChatActionState state;
  final String? result;
  final bool busy;
  final bool danger;
}

/// Uma mensagem da conversa. [child] troca o texto da bolha por conteúdo livre (lista, foto, cartão).
@immutable
class SsAssistantMessage {
  const SsAssistantMessage({
    required this.id,
    this.text,
    this.child,
    this.fromMe = false,
    this.status = SsAssistantStatus.ready,
    this.time,
    this.error,
    this.action,
  });

  final String id;
  final String? text;
  final Widget? child;
  final bool fromMe;
  final SsAssistantStatus status;

  /// Já formatada ("14:32").
  final String? time;

  /// Texto do erro quando [status] é `failed` (padrão: [SsStrings.assistantFailed]).
  final String? error;
  final SsAssistantAction? action;

  bool get isPending => status == SsAssistantStatus.pending;
  bool get isFailed => status == SsAssistantStatus.failed;
}

/// Atalho (chip) da conversa: "Como foi a minha semana?". [value] é do app (tipo de análise, prompt).
@immutable
class SsAssistantShortcut {
  const SsAssistantShortcut(this.label, {this.icon, this.value});
  final String label;
  final IconData? icon;
  final Object? value;
}

/// Uma conversa da lista. [subtitle] padrão: "há 2 h" de [updatedAt].
@immutable
class SsAssistantConversation {
  const SsAssistantConversation({required this.id, this.title, this.subtitle, this.updatedAt});
  final String id;
  final String? title;
  final String? subtitle;
  final DateTime? updatedAt;
}

/// O assistente fora do plano: no lugar da conversa vai o [SsPlanLocked] (e o campo some).
@immutable
class SsAssistantLock {
  const SsAssistantLock({required this.feature, required this.text, required this.onUpgrade, this.upgradeLabel});
  final String feature;
  final String text;
  final VoidCallback onUpgrade;
  final String? upgradeLabel;
}

/// Tela do assistente com IA, sem estado de servidor: o app passa as [messages] e reage aos callbacks.
///
/// - **Conversa**: as bolhas ([SsChatBubble]) de baixo para cima (a última sempre à vista, sem rolar à mão);
///   mensagem `pending` vira [SsThinking]; `failed` mostra o erro com "Tentar de novo" ([onRetryMessage]);
///   [thinking] põe o "respondendo" no fim enquanto o envio não voltou (o [thinkingText] troca o texto).
/// - **Ação sugerida**: [SsAssistantMessage.action] monta o [SsChatActionCard] abaixo da bolha.
/// - **Atalhos**: [shortcuts] aparecem em chips no vazio (centrados) e, com a conversa aberta, numa faixa
///   rolável acima do campo ([shortcutsInChat]); tocar chama [onShortcut].
/// - **Plano e cota**: [locked] troca tudo pelo [SsPlanLocked]; [quotaUsed]/[quotaLimit] mostram o
///   [SsQuota] acima do campo; [inputEnabled] falso trava o campo com [disabledHint] (padrão "Mensagens do
///   mês esgotadas").
/// - **Conversas**: com [conversations] e largura de [sideBreakpoint] para cima, a lista
///   ([SsAssistantConversations]) fica ao lado. No celular, abra pela barra de cima com
///   [showSsAssistantConversations].
/// - **Campo**: [onSend] recebe o texto; sem [controller], o campo limpa sozinho ao enviar (com o do app,
///   limpar é do app, para devolver o texto se falhar). Enviar trava enquanto [thinking] ou há `pending`.
///
/// `SsAssistantView(messages: msgs, onSend: enviar, thinking: enviando, shortcuts: atalhos, onShortcut: usar, quotaUsed: 3, quotaLimit: 10)`
class SsAssistantView extends StatefulWidget {
  const SsAssistantView({
    super.key,
    required this.messages,
    required this.onSend,
    this.controller,
    this.thinking = false,
    this.thinkingText,
    this.shortcuts = const [],
    this.onShortcut,
    this.shortcutsInChat = true,
    this.emptyTitle,
    this.emptyText,
    this.loading = false,
    this.error,
    this.onRetry,
    this.onRetryMessage,
    this.locked,
    this.quotaUsed,
    this.quotaLimit,
    this.quotaLabel,
    this.inputEnabled = true,
    this.hint,
    this.disabledHint,
    this.maxLength = 2000,
    this.inputLeading,
    this.conversations,
    this.currentConversationId,
    this.onOpenConversation,
    this.onNewConversation,
    this.onDeleteConversation,
    this.sideBreakpoint = 840,
  });

  final List<SsAssistantMessage> messages;
  final ValueChanged<String> onSend;
  final TextEditingController? controller;
  final bool thinking;
  final String? thinkingText;
  final List<SsAssistantShortcut> shortcuts;
  final ValueChanged<SsAssistantShortcut>? onShortcut;
  final bool shortcutsInChat;

  /// Vazio: padrão [SsStrings.assistantEmptyTitle].
  final String? emptyTitle;
  final String? emptyText;

  /// Abrindo a conversa (spinner no lugar).
  final bool loading;

  /// Erro ao abrir a conversa (sem mensagens): estado de erro com [onRetry].
  final String? error;
  final VoidCallback? onRetry;
  final ValueChanged<SsAssistantMessage>? onRetryMessage;
  final SsAssistantLock? locked;
  final int? quotaUsed;
  final int? quotaLimit;

  /// Período da cota (padrão: "este mês").
  final String? quotaLabel;
  final bool inputEnabled;
  final String? hint;
  final String? disabledHint;
  final int? maxLength;
  final Widget? inputLeading;
  final List<SsAssistantConversation>? conversations;
  final String? currentConversationId;
  final ValueChanged<SsAssistantConversation>? onOpenConversation;
  final VoidCallback? onNewConversation;
  final ValueChanged<SsAssistantConversation>? onDeleteConversation;
  final double sideBreakpoint;

  @override
  State<SsAssistantView> createState() => _SsAssistantViewState();
}

class _SsAssistantViewState extends State<SsAssistantView> {
  TextEditingController? _own;
  TextEditingController get _input => widget.controller ?? (_own ??= TextEditingController());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  bool get _waiting => widget.thinking || widget.messages.any((m) => m.isPending);

  void _send(String t) {
    widget.onSend(t);
    if (widget.controller == null) _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final chat = _chat(context);
    final convs = widget.conversations;
    if (convs == null) return chat;
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth < widget.sideBreakpoint) return chat;
        final c = SsColors.of(context);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 300,
              child: SsAssistantConversations(
                conversations: convs,
                currentId: widget.currentConversationId,
                onOpen: widget.onOpenConversation,
                onNew: widget.onNewConversation,
                onDelete: widget.onDeleteConversation,
              ),
            ),
            VerticalDivider(width: 1, thickness: 1, color: c.line),
            Expanded(child: chat),
          ],
        );
      },
    );
  }

  Widget _chat(BuildContext context) {
    final s = SsStrings.of(context);
    final lock = widget.locked;
    if (lock != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SsPlanLocked(
            feature: lock.feature,
            text: lock.text,
            upgradeLabel: lock.upgradeLabel,
            onUpgrade: lock.onUpgrade,
          ),
        ],
      );
    }
    final temConversa = widget.messages.isNotEmpty || widget.thinking;
    final cota = widget.quotaLimit != null && widget.quotaUsed != null;
    return Column(
      children: [
        Expanded(child: _corpo(context)),
        if (temConversa && widget.shortcutsInChat && widget.shortcuts.isNotEmpty && !widget.loading)
          _FaixaAtalhos(shortcuts: widget.shortcuts, onTap: _waiting ? null : widget.onShortcut),
        if (cota)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SsQuota(used: widget.quotaUsed!, limit: widget.quotaLimit!, label: widget.quotaLabel),
            ),
          ),
        SsChatInput(
          controller: _input,
          onSend: _send,
          hint: widget.inputEnabled ? widget.hint : (widget.disabledHint ?? s.assistantExhausted),
          sending: _waiting,
          enabled: widget.inputEnabled && !widget.loading,
          maxLength: widget.maxLength,
          leading: widget.inputLeading,
        ),
      ],
    );
  }

  Widget _corpo(BuildContext context) {
    final s = SsStrings.of(context);
    if (widget.loading) return const Center(child: SsSpinner());
    if (widget.error != null && widget.messages.isEmpty) {
      return SsEmptyState(
        icon: Icons.cloud_off_outlined,
        title: s.loadFailed,
        subtitle: widget.error,
        actionLabel: widget.onRetry == null ? null : s.retry,
        onAction: widget.onRetry,
      );
    }
    if (widget.messages.isEmpty && !widget.thinking) {
      return _Vazio(
        title: widget.emptyTitle ?? s.assistantEmptyTitle,
        text: widget.emptyText,
        shortcuts: widget.shortcuts,
        onTap: widget.inputEnabled ? widget.onShortcut : null,
      );
    }
    // De baixo para cima: a última mensagem fica à vista sem controlar a rolagem.
    final linhas = <Widget>[
      if (widget.thinking && !widget.messages.any((m) => m.isPending)) SsThinking(text: widget.thinkingText),
      for (final m in widget.messages.reversed) _mensagem(context, m),
    ];
    final d = SsDensity.of(context);
    return ListView.builder(
      reverse: true,
      padding: EdgeInsets.fromLTRB(16, d.space(12), 16, d.space(12)),
      itemCount: linhas.length,
      itemBuilder: (_, i) => Padding(padding: const EdgeInsets.only(top: 6), child: linhas[i]),
    );
  }

  Widget _mensagem(BuildContext context, SsAssistantMessage m) {
    final c = SsColors.of(context);
    final s = SsStrings.of(context);
    if (m.fromMe) return SsChatBubble(text: m.text, fromMe: true, time: m.time, child: m.child);
    if (m.isPending) return SsThinking(key: ValueKey('ss-asst-${m.id}'), text: widget.thinkingText);
    if (m.isFailed) {
      return SsChatBubble(
        fromMe: false,
        time: m.time,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              m.error ?? s.assistantFailed,
              style: TextStyle(color: c.dangerText, fontSize: AppType.body, height: 1.4),
            ),
            if (widget.onRetryMessage != null)
              TextButton.icon(
                onPressed: () => widget.onRetryMessage!(m),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(s.retry),
              ),
          ],
        ),
      );
    }
    final a = m.action;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (m.text != null || m.child != null) SsChatBubble(text: m.text, fromMe: false, time: m.time, child: m.child),
        if (a != null)
          Padding(
            // Alinha com a bolha (o ✦ tem 28 + 8).
            padding: const EdgeInsets.only(left: 36, top: 6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SsChatActionCard(
                title: a.title,
                description: a.description,
                icon: a.icon,
                rows: a.rows,
                confirmLabel: a.confirmLabel,
                cancelLabel: a.cancelLabel,
                onConfirm: a.onConfirm,
                onCancel: a.onCancel,
                state: a.state,
                result: a.result,
                busy: a.busy,
                danger: a.danger,
              ),
            ),
          ),
      ],
    );
  }
}

class _Vazio extends StatelessWidget {
  const _Vazio({required this.title, this.text, required this.shortcuts, this.onTap});
  final String title;
  final String? text;
  final List<SsAssistantShortcut> shortcuts;
  final ValueChanged<SsAssistantShortcut>? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = SsStrings.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      children: [
        const Center(child: SsAiMark()),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: AppType.lg, fontWeight: FontWeight.w800, color: c.ink),
          ),
        ),
        if (text != null) ...[
          const SizedBox(height: 4),
          Text(
            text!,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.muted, height: 1.4),
          ),
        ],
        if (shortcuts.isNotEmpty) ...[
          const SizedBox(height: 20),
          Semantics(
            label: s.assistantShortcuts,
            container: true,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final a in shortcuts)
                  SsFilterChip(a.label, icon: a.icon, selected: false, onTap: onTap == null ? null : () => onTap!(a)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _FaixaAtalhos extends StatelessWidget {
  const _FaixaAtalhos({required this.shortcuts, this.onTap});
  final List<SsAssistantShortcut> shortcuts;
  final ValueChanged<SsAssistantShortcut>? onTap;

  @override
  Widget build(BuildContext context) {
    // v1.9.1: a faixa tem a altura do alvo (48) com o chip no meio: a rolagem corta o que passa dela.
    final d = SsDensity.of(context);
    return Semantics(
      label: SsStrings.of(context).assistantShortcuts,
      container: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: d.minTarget),
          child: Row(
            children: [
              for (final a in shortcuts)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SsFilterChip(
                    a.label,
                    icon: a.icon,
                    selected: false,
                    onTap: onTap == null ? null : () => onTap!(a),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lista das conversas do assistente: "Conversas" com o + (nova), cada uma com título, "há 2 h", o selo
/// "Aberta" na atual e a lixeira (pede confirmação antes de [onDelete]). Vai ao lado do [SsAssistantView]
/// na tela larga ou na folha de [showSsAssistantConversations]. [inSheet] tira o cabeçalho próprio.
class SsAssistantConversations extends StatelessWidget {
  const SsAssistantConversations({
    super.key,
    required this.conversations,
    this.currentId,
    this.onOpen,
    this.onNew,
    this.onDelete,
    this.inSheet = false,
  });

  final List<SsAssistantConversation> conversations;
  final String? currentId;
  final ValueChanged<SsAssistantConversation>? onOpen;
  final VoidCallback? onNew;
  final ValueChanged<SsAssistantConversation>? onDelete;
  final bool inSheet;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = SsStrings.of(context);
    final itens = [
      for (final v in conversations)
        SsListItem(
          key: ValueKey('ss-conv-${v.id}'),
          icon: Icons.chat_bubble_outline_rounded,
          title: v.title ?? s.assistantUntitled,
          maxLines: 2,
          subtitle: v.subtitle ?? (v.updatedAt == null ? null : timeAgo(v.updatedAt, strings: s)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (v.id == currentId) SsBadge(s.assistantCurrent, micro: true),
              if (onDelete != null)
                SsIconButton(
                  icon: Icons.delete_outline_rounded,
                  tooltip: s.assistantDelete,
                  variant: SsIconButtonVariant.danger,
                  onPressed: () async {
                    final ok = await showSsConfirm(
                      context,
                      title: s.assistantDeleteConfirm,
                      message: s.assistantDeleteText,
                      confirmLabel: s.assistantDelete,
                      danger: true,
                      icon: Icons.delete_outline_rounded,
                    );
                    if (ok) onDelete!(v);
                  },
                ),
            ],
          ),
          onTap: onOpen == null ? null : () => onOpen!(v),
        ),
    ];
    final lista = conversations.isEmpty
        ? SsEmptyState(compact: true, icon: Icons.forum_outlined, title: s.assistantNoConversations)
        : Column(mainAxisSize: MainAxisSize.min, children: itens);
    if (inSheet) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onNew != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton.icon(
                onPressed: onNew,
                icon: const Icon(Icons.add_comment_outlined),
                label: Text(s.assistantNew),
              ),
            ),
          lista,
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Semantics(
                  header: true,
                  child: Text(
                    s.assistantConversations,
                    style: TextStyle(color: c.ink, fontSize: AppType.md, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
            if (onNew != null)
              SsIconButton(icon: Icons.add_comment_outlined, tooltip: s.assistantNew, onPressed: onNew),
          ],
        ),
        const SizedBox(height: 8),
        lista,
      ],
    );
  }
}

/// Abre as conversas numa folha (celular). Tocar numa conversa ou em "Nova conversa" fecha a folha e chama
/// o callback; apagar também fecha (depois da confirmação), para a lista voltar atualizada.
Future<void> showSsAssistantConversations(
  BuildContext context, {
  required List<SsAssistantConversation> conversations,
  String? currentId,
  ValueChanged<SsAssistantConversation>? onOpen,
  VoidCallback? onNew,
  ValueChanged<SsAssistantConversation>? onDelete,
}) {
  final s = SsStrings.of(context);
  return showSsSheet<void>(
    context,
    title: s.assistantConversations,
    icon: Icons.forum_outlined,
    child: Builder(
      builder: (sheet) => SsAssistantConversations(
        inSheet: true,
        conversations: conversations,
        currentId: currentId,
        onOpen: onOpen == null
            ? null
            : (v) {
                Navigator.of(sheet).pop();
                onOpen(v);
              },
        onNew: onNew == null
            ? null
            : () {
                Navigator.of(sheet).pop();
                onNew();
              },
        onDelete: onDelete == null
            ? null
            : (v) {
                Navigator.of(sheet).pop();
                onDelete(v);
              },
      ),
    ),
  );
}
