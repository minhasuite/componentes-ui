# v1.9 · produto: central de notificações, assistente com IA e formas de capturar

Peças que os apps da suíte repetiram à mão na última rodada, agora no componentes-ui, nos dois lados e com o mesmo nome.
Tudo aditivo, sem quebrar nada.

- Flutter: `flutter/lib/src/v19/produto/` (`notification_center.dart`, `assistant_view.dart`, `capture_hub.dart`).
- Rails: `rails/app/components/ss/{notification_center,assistant,capture_hub}_component.rb`, Stimulus `ss_assistant_controller.js` e
  `ss_capture_hub_controller.js`, CSS `v19_produto.css`.
- Testes: `flutter/test/v19_produto_test.dart` e `rails/sample/test/components/v19_produto_web_test.rb`.
- Catálogo: `flutter/test/catalogo_v19_produto.dart` (`comV19Produto`) e `rails/catalogo/index.html` (gerado por
  `rails/sample/script/catalogo_v19_produto.rb`), com `ss-notification-center`, `ss-assistant` e `ss-capture-hub`.
- Vitrine Rails: página "Central, assistente e captura (v1.9)" (`pecas_v19_produto`, grupo Retorno).

De onde veio cada uma:

| Peça | Generaliza |
|---|---|
| Central de notificações | `minhas-vendas-app/.../notifications_screen.dart`, `meu-cultivo-app/.../notifications/`, `meu-personal-app/.../notifications/` |
| Assistente | `meu-personal-app/.../assistant/`, o chat `/ai/chat` do `meu-financeiro-app`, `meu-gestor-app/.../ask/` |
| Formas de capturar | `minhas-compras-app/.../scan/scan_sheet.dart` |

## Central de notificações

| | Web | Flutter |
|---|---|---|
| Peça | `Ss::NotificationCenterComponent(items:, id: "ss-ncenter", unread_count: nil, read_all_href: nil, read_all_method: :patch, next_href: nil, fragment: false, page: 1, after: nil, now: nil, empty: nil, empty_text: nil)` | `SsNotificationCenter(load:, markRead:, markAllRead:, archive:, onOpen:, onUnreadChanged:, controller:, showHeader: true, groupByDay: true, emptyTitle:, emptyText:, emptyIcon:, errorText:, padding:, now:)` |
| Item | `{ id:, title:, text:, at:, unread:, icon:, tone:, href:, method:, read_href:, archive_href: }` | `SsNotificationItem(id:, title:, body:, createdAt:, read:, icon:, tone: SsTone, data:)` |
| Página | `next_href:` → `<turbo-frame id="<id>-p2" loading=lazy>`; a resposta é o componente com `fragment: true, page: 2, after:` | `load(page)` devolve `SsNotificationPage(items, hasMore:, unreadCount:)` |
| Linha | `.ss-ncenter-item` (`.is-unread`) | `SsNotificationTile(item:, onTap:, time:)` (também serve na folha do sino) |
| Sino | `Ss::NotificationBellComponent` (já existia) | `SsNotificationBell` / `SsBellDot` com `SsNotificationCenterController.unreadCount` |
| Textos | `componentes_ui.notification_center.*` | `SsStrings.notif*` (`notifMarkAllRead`, `notifUnreadCount(n)`, …) |

Comportamento (igual nos dois lados):

- Agrupa por dia: "Hoje", "Ontem", o dia por extenso no ano ("segunda, 5 de outubro"; no web, "segunda-feira, …") e a data
  inteira em outro ano. A hora (`HH:mm`) vai na linha, em DM Mono.
- Não lida: título em negrito e na cor do texto, contorno na cor da marca e o ponto (o leitor de tela ouve "não lida").
- Tocar/abrir: marca como lida e leva ao destino. No Flutter é otimista (`markRead` falhar não impede o `onOpen`); no
  web, `href:` com `method: :patch` vira `button_to` (o servidor marca e redireciona).
- "Marcar todas como lidas" na faixa de cima, com a contagem ("3 não lidas"). Flutter: otimista, volta e avisa se falhar;
  `showHeader: false` quando o app põe o botão na barra (chame `controller.markAllRead()`).
- Ler e arquivar um aviso: no app, deslizar (direita lê, esquerda arquiva; também nas ações do leitor de tela); no web,
  botões de ícone de 44px que aparecem ao passar o mouse ou com o foco (sempre à vista no toque).
- Paginação: Flutter pede `load(n+1)` perto do fim e não repete id; web pagina com turbo-frame lazy e `after:` evita
  repetir o título do dia na emenda.
- Puxar para atualizar (app), também no vazio e no erro. Vazio: "Nenhuma notificação"; erro da 1ª página: o motivo
  (`errorText`) e "Tentar de novo".
- A contagem: `unreadCount` do servidor ganha da contagem dos itens carregados (Flutter `SsNotificationPage.unreadCount`,
  web `unread_count:`).

```dart
final central = SsNotificationCenterController();
Scaffold(
  appBar: SsTopBar(title: 'Notificações'),
  body: SsNotificationCenter(
    controller: central,
    load: (p) async {
      final r = await api.get('/notifications', query: {'page': p});
      return SsNotificationPage([for (final j in r.data) aviso(j)], hasMore: r.meta['next'] != null, unreadCount: r.meta['unread_count']);
    },
    markRead: (id) => api.patch('/notifications/$id/read'),
    markAllRead: () => api.patch('/notifications/read'),
    archive: (id) => api.patch('/notifications/$id/archive'),
    onOpen: (n) => n.data is String ? context.push(n.data as String) : null,
    onUnreadChanged: (_) => ref.invalidate(unreadProvider),
  ),
);
```

```erb
<%= render Ss::NotificationCenterComponent.new(id: "avisos", unread_count: @nao_lidas, read_all_href: avisos_lidos_path,
      next_href: (avisos_path(page: @page + 1) if @mais), fragment: params[:page].present?, page: @page, after: @anterior&.created_at,
      items: @avisos.map { |a| { id: a.id, title: a.title, text: a.body, at: a.created_at, unread: a.read_at.nil?, icon: a.icone,
        href: abrir_aviso_path(a), method: :patch, read_href: aviso_lido_path(a), archive_href: arquivar_aviso_path(a) } }) %>
```

## Assistente com IA

| | Web | Flutter |
|---|---|---|
| Peça | `Ss::AssistantComponent(id:, url:, messages:, shortcuts:, conversations: nil, current_conversation_id:, new_conversation_href:, delete_method: :delete, quota:, locked:, disabled:, thinking:, empty_title:, empty_text:, placeholder:, every: 2000, max_polls: 90)` + bloco (vai no log) | `SsAssistantView(messages:, onSend:, controller:, thinking:, thinkingText:, shortcuts:, onShortcut:, shortcutsInChat: true, emptyTitle:, emptyText:, loading:, error:, onRetry:, onRetryMessage:, locked:, quotaUsed:, quotaLimit:, quotaLabel:, inputEnabled: true, hint:, disabledHint:, maxLength: 2000, inputLeading:, conversations:, currentConversationId:, onOpenConversation:, onNewConversation:, onDeleteConversation:, sideBreakpoint: 840)` |
| Mensagem | `{ from: :me/:ai, text:, time:, status: :pending/:failed, poll_url:, error:, retry_href:, action: {…ChatActionComponent} }` | `SsAssistantMessage(id:, text:, child:, fromMe:, status: SsAssistantStatus, time:, error:, action: SsAssistantAction)` |
| Atalho | `{ label:, prompt:, icon:, href: }` | `SsAssistantShortcut(label, icon:, value:)` |
| Conversa | `{ id:, title:, subtitle:, href:, delete_href: }` | `SsAssistantConversation(id:, title:, subtitle:, updatedAt:)`; lista `SsAssistantConversations`; folha `showSsAssistantConversations` |
| Plano | `locked: { feature:, text:, href:, label: }` | `SsAssistantLock(feature:, text:, onUpgrade:, upgradeLabel:)` (o `SsPlanLocked`) |
| Cota | `quota: { used:, limit:, label: }` (`.ss-quota`) | `quotaUsed:`/`quotaLimit:` (o `SsQuota`) |
| Textos | `componentes_ui.assistant.*` | `SsStrings.assistant*` |

- Conversa em bolhas (`SsChatBubble` / `Ss::ChatComponent::Message`); a última sempre à vista (Flutter: lista invertida;
  web: o `ss-chat` rola).
- Ação sugerida: `action` vira o `SsChatActionCard` / `Ss::ChatActionComponent` abaixo da bolha ("Montar treino").
- **Resposta por polling**: o pacote só expõe o estado. No Flutter, a mensagem `pending` vira o `SsThinking`; o app
  pergunta ao servidor e troca a mensagem por `ready`/`failed`. No web, a bolha pendente leva `data-url=poll_url` e o
  `ss-assistant` pergunta a cada `every:` ms com `Accept: text/html` (pausa com a aba escondida): 204 ou corpo vazio =
  ainda pensando; HTML = troca a bolha (outra pendente continua); depois de `max_polls:`, vira o erro. A resposta do
  envio (turbo_stream append em `<id>-messages`) pode trazer uma pendente, que começa a perguntar sozinha.
- `failed`: o erro em vermelho e "Tentar de novo" (`onRetryMessage` / `retry_href:` com POST).
- Atalhos: chips no vazio (centrados) e, com a conversa aberta, uma faixa (app: acima do campo; web: no topo). No web,
  tocar escreve o `prompt` no campo e envia; com `href:`, é link (análise pronta).
- Cota: barra com "3 de 10"; acabada, o campo trava com "Mensagens do mês esgotadas" (web: `disabled` automático;
  app: `inputEnabled: false`). `locked` troca a conversa pelo cartão do plano, sem campo.
- Conversas: ao lado a partir de 840 de largura (abrir, + nova, lixeira com confirmação de perigo). No celular, a barra
  de cima do app abre `showSsAssistantConversations` (folha).
- Enviar trava enquanto responde (`thinking` ou há pendente). Sem `controller`, o campo do app limpa ao enviar.

```dart
SsAssistantView(
  messages: [for (final m in conversa) SsAssistantMessage(id: m.id, text: m.content, fromMe: m.fromMe,
      status: m.isPending ? SsAssistantStatus.pending : (m.isFailed ? SsAssistantStatus.failed : SsAssistantStatus.ready),
      action: m.action?.isBuildWorkout == true ? SsAssistantAction(title: 'Montar este treino', confirmLabel: 'Montar treino', onConfirm: () => montar(m)) : null)],
  onSend: enviar,               // o app posta e faz o polling até ready/failed
  thinking: enviando,
  shortcuts: const [SsAssistantShortcut('Resumo da semana', value: 'weekly_summary')],
  onShortcut: (a) => analisar(a.value as String),
  quotaUsed: cota.used, quotaLimit: cota.limit, inputEnabled: !cota.exhausted,
  locked: cota.available ? null : SsAssistantLock(feature: 'Assistente com IA', text: '…', onUpgrade: () => context.push('/pro')),
)
```

```erb
<%= render Ss::AssistantComponent.new(id: "assistente", url: assistente_mensagens_path,
      messages: @mensagens.map { |m| { from: m.role == "user" ? :me : :ai, text: m.content, time: l(m.created_at, format: "%H:%M"),
                                       status: (m.status unless m.status == "ready"), poll_url: assistente_mensagem_path(m) } },
      shortcuts: [{ label: "Resumo da semana" }], conversations: @conversas.map { |c| { id: c.id, title: c.title, href: conversa_path(c), delete_href: conversa_path(c) } },
      current_conversation_id: @conversa&.id, new_conversation_href: new_conversa_path, quota: { used: @usadas, limit: @limite }) %>
```

O `poll_url` responde 204 enquanto pensa e, pronta, o HTML da resposta (`render Ss::ChatComponent::Message.new(from: :ai, text: …)`,
com o `Ss::ChatActionComponent` se houver ação).

## Formas de capturar

| | Web | Flutter |
|---|---|---|
| Peça | `Ss::CaptureHubComponent(options:, upload: nil, paste: nil, id:, label:)` | `SsCaptureHub(options:, columns:)`; folha `showSsCaptureHub(context, options:, title:, subtitle:, icon:)` |
| Opção | `{ kind:, title:, description:, icon:, href:, method:, highlighted:, disabled_reason:, disabled_href:, group:, data: }` | `SsCaptureOption(kind: SsCaptureKind, onTap:, icon:, title:, description:, highlighted:, disabledReason:, onDisabledTap:, group:)` |
| Tipos | `:camera`, `:gallery`, `:paste`, `:barcode`, `:file`, `:custom` | `SsCaptureKind.camera` … `.custom` |
| Envio | `upload: { url:, name:, accept:, multiple:, label:, hint: }` (o `Ss::FileDropComponent`: arrastar, escolher, colar) e `paste: { url:, name:, label:, placeholder: }` | o app abre câmera/galeria/arquivo no `onTap` |
| Textos | `componentes_ui.capture_hub.*` | `SsStrings.capture*` |

- O `kind` dá ícone, título e descrição padrão (pt/en/es): Tirar foto, Da galeria, Colar texto, Código de barras, Enviar
  arquivo.
- `highlighted`: bloco largo no gradiente da marca, no alto, com "Recomendado" (o "Foto do cupom" do Minhas Compras).
- Indisponível (`disabledReason` / `disabled_reason:`): apagada, com cadeado e o motivo no lugar da descrição; com
  `onDisabledTap` / `disabled_href:` continua tocável (abrir os planos). O leitor de tela ouve "… Indisponível".
- `group`: título de seção para opções seguidas do mesmo grupo ("Compra", "Produto").
- Grade: Flutter 2 colunas (1 com texto 1,15× ou largura abaixo de 300); web auto-fit com mínimo de 13rem (as opções ocupam a largura).
- Web: sem `href:`, câmera/galeria/arquivo abrem o seletor do `upload:` (câmera com `capture="environment"`, só imagem)
  e enviam ao escolher; "Colar texto" abre o campo; Ctrl+V em qualquer ponto da peça manda o print para o envio e o
  texto para o campo. Flutter: `showSsCaptureHub` fecha a folha antes de chamar o `onTap` (o fluxo abre sobre quem chamou).

```dart
showSsCaptureHub(context, title: 'O que você quer registrar?', options: [
  SsCaptureOption(kind: SsCaptureKind.camera, title: 'Foto do cupom', description: 'Comprido? Tire em partes.', highlighted: true, onTap: () => fotoCupom(context)),
  SsCaptureOption(kind: SsCaptureKind.paste, group: 'Compra', onTap: () => colar(context)),
  SsCaptureOption(kind: SsCaptureKind.barcode, group: 'Produto', onTap: () => ler(context)),
  SsCaptureOption(kind: SsCaptureKind.gallery, group: 'Produto', disabledReason: 'No plano Pro ou Max', onDisabledTap: () => planos(context)),
]);
```

```erb
<%= render Ss::CaptureHubComponent.new(upload: { url: leituras_path, name: "leitura[arquivos][]", accept: "image/*,.pdf,.xml" },
      paste: { url: leituras_texto_path, name: "leitura[texto]" },
      options: [{ kind: :camera, title: "Foto do cupom", highlighted: true }, { kind: :paste, group: "Compra" },
                { kind: :barcode, group: "Produto", href: leitor_path },
                { kind: :gallery, group: "Produto", disabled_reason: "No plano Pro ou Max", disabled_href: planos_path }]) %>
```

## SsStrings (Flutter)

Campos novos, todos com valor padrão (pt) no construtor, num bloco `// v1.9 · produto` em cada idioma, no
`debugSamples` e no `copyWith`: `notifMarkAllRead`, `notifMarkRead`, `notifArchive`, `notifArchived`, `notifEmptyTitle`,
`notifEmptyText`, `notifUnread`, `notifEnd`, `notifUnreadCount(n)`, `assistantConversations`, `assistantNew`,
`assistantDelete`, `assistantDeleteConfirm`, `assistantDeleteText`, `assistantNoConversations`, `assistantUntitled`,
`assistantCurrent`, `assistantEmptyTitle`, `assistantFailed`, `assistantShortcuts`, `assistantExhausted`,
`assistantRemaining(n)`, `captureCamera(Hint)`, `captureGallery(Hint)`, `capturePaste(Hint)`, `captureBarcode(Hint)`,
`captureFile(Hint)`, `captureRecommended`, `captureUnavailable`.

## Ficou de fora

- Web sem "deslizar" (é gesto do app); o resultado chega igual pelos botões de ler/arquivar.
- Web sem "puxar para atualizar" (o navegador recarrega); a central pagina sozinha.
- `assistantRemaining(n)` está nos textos, mas o `SsAssistantView` não o usa sozinho (a cota é o `SsQuota`); o app pode pôr no `hint`.
- A leitura de código de barras e a câmera de verdade continuam no app (plugin); o hub só oferece as opções.
