# v1.9 · Paridade web

Três entregas: os pares Rails das peças que só existiam no Flutter, o `paridade.yml` (com um teste em cada
lado que falha quando alguém cria peça num lado só) e a UX transversal do app (componentes que os apps
adotam depois).

## 1. Pares web (Rails: componente + Stimulus + CSS)

CSS em `rails/app/assets/tailwind/componentes_ui/v19_paridade_web.css` (importado no `engine.css`), só
tokens; `prefers-reduced-motion` desliga as animações. Textos em `componentes_ui.<componente>` (pt/en/es).
Vitrine: `rails/sample/app/views/vitrine/pecas_v190_paridade.html.erb`. Catálogo:
`rails/catalogo/index.html` (gerado por `rails/sample/script/catalogo_v19_paridade_web.rb`).

| Flutter | Rails | Controller |
|---|---|---|
| `SsSwipeToConfirm` | `Ss::SwipeToConfirmComponent(label:, url:, method:, params:, done_label:, icon:, done:, disabled:)` | `ss-swipe-confirm` |
| `SsHoldToConfirm` | `Ss::HoldToConfirmComponent(label:, url:, method:, params:, done_label:, icon:, duration:, danger:, disabled:)` | `ss-hold-confirm` |
| `SsSnapCarousel` | `Ss::SnapCarouselComponent(label:, height:, peek:, indicator: :dots\|:counter\|:none, initial:)` + `with_slide` | `ss-carousel` |
| `SsStoryRing` | `Ss::StoryRingComponent(name:, segments:, seen:, size:, caption:, href:, add_href:)` | `ss-in-view` |
| `SsOdometer` | `Ss::OdometerComponent(text:, size:, roll_in:, cents:)` (o `CountUpComponent` continua) | `ss-odometer` |
| `SsMorphButton` | `Ss::MorphButtonComponent(label:, icon:, type:, name:, value:, form:, block:)` | `ss-morph` |
| `SsBurst` | `Ss::BurstComponent(on: :click\|:change\|:connect\|:manual, count:, distance:, radius:, tone:)` | `ss-burst` |
| `SsHeatCalendar` / `SsHeatLegend` | `Ss::HeatCalendarComponent(values:, weeks:, month:, end_date:, format:, legend:)` | `ss-heat-calendar` |
| `SsBigRing` | `Ss::BigRingComponent(value:, caption:, size:, ticks:, tone:)` | `ss-in-view` + `ss-count-up` |
| `SsRings` | `Ss::RingsComponent(rings: [{ value:, label:, tone: }], center:, size:, stroke:, label:)` | `ss-in-view` |
| `SsDateStrip` | `Ss::DateStripComponent(selected:, url: "…%{date}", markers:, today:, show_header:, turbo_frame:)` | `ss-date-strip` |
| `SsSplitSlider` | `Ss::SplitSliderComponent(name:, total:, entries: [{ key:, name:, cents: }], locked:, step:, marks:)` | `ss-split-slider` |
| `SsSyncStatus` | `Ss::SyncStatusComponent(state:, pending_count:, failed_count:, last_synced_at:, href:)` | — |

O `SsCelebrate` ↔ `Ss::CelebrateComponent` é do agente de transições (registrado como pendente); daqui saiu
só o `Burst`.

Exemplos:

```erb
<%= render Ss::SwipeToConfirmComponent.new(label: "Deslize para pagar R$ 120,00", url: pagamento_path(p)) %>
<%= render Ss::HoldToConfirmComponent.new(label: "Segure para excluir", url: cliente_path(c), method: :delete, danger: true) %>
<%= form_with model: @nota do |f| %> … <%= render Ss::MorphButtonComponent.new(label: "Salvar", icon: "check") %> <% end %>
<%= render Ss::OdometerComponent.new(text: ss_money(@total)) %>
<%= render Ss::DateStripComponent.new(selected: @dia, url: "/agenda?dia=%{date}", markers: { Date.current => [:accent] }) %>
<%= render Ss::SplitSliderComponent.new(name: "divisao", total: 75_086, entries: [{ key: "eu", name: "Eu", cents: 25_000 }, …]) %>
<%= render Ss::SyncStatusComponent.new(**Ss::SyncStatusComponent.resolve(syncing: false, failed: 1, pending: 3)) %>
```

Notas de comportamento:

- **Confirmar (deslizar/segurar):** com `url:` é um formulário de verdade (`requestSubmit`); o
  `turbo:submit-end` decide ✓ ou volta. Sem `url:`, eventos `ss-swipe-confirm:confirm`
  (`detail.done()/fail()`, depois de `preventDefault`) e `ss-hold-confirm:confirm`. O clique de teclado ou
  do leitor de tela (`event.detail === 0`) confirma direto, como o toque do leitor no Flutter.
- **MorphButton:** no formulário segue o Turbo; `type: :button` dispara `ss-morph:run` com
  `detail.waitUntil(promise)`. Progresso real pelo `direct-upload:progress` ou `ss-morph:progress { value }`.
  Por JS: `el.ssMorph.start() / succeed() / fail() / progress(v)`.
- **Odômetro:** cada dígito é um rolo 0–9 repetido três vezes; subir anda para a frente e descer para trás
  (dá a volta certa no 9→0), em cascata da direita (35 ms) e com a mola `--ss-bounce`.
- **SplitSlider:** a mesma `redistribute` em Ruby (`Ss::SplitSliderComponent.redistribute`), JS (`export
  function redistribute`) e Dart (`SsSplitSlider.redistribute`): a soma fecha o total ao centavo. O
  `Ss::SplitAllocatorComponent` (porcentagem) continua.
- **HeatCalendar:** o nível é o do `ssHeatLevel`; um ponto de tab só (↑ ↓ dia, ← → semana). O `ss_heat`
  (helper) continua.
- **DateStrip:** a pílula anda por transição de `left` com `--i`, então o morph do Turbo também desliza.
  O mês abre o calendário nativo (`input type=date` + `showPicker()`) e vai para a `url:` do dia.

## 2. `paridade.yml` e os dois testes

Na raiz do repo. Seções:

- `pares:` `SsX: "alvo"` ou `["alvo", …]`. Alvo: `Ss::XComponent`, `helper:ss_x`, `form:ss_x`
  (FormBuilder), `css:.ss-x` ou `js:ss-x` (controller). `{ rails: "…", pendente_v19: true }` = peça que
  outro agente desta onda está criando (o teste não cobra a existência; **tirar a marca no merge**).
- `apis:` funções e classes que não são widget (`showSsSheet`, `SsIcons`, `SsHelpMenu`) com o par web.
- `so_app:` / `so_web:` exceção com motivo (gesto, câmera, infra do Flutter / tela grande, landing, impressão).
- `divida:` peça do Flutter sem par web que deveria ter (não é exceção); `divida_app:` o contrário.

Testes:

- `flutter/test/v19_paridade_web_test.dart`: segue os `export` de `lib/componentes_ui.dart` (com
  `show`/`hide`) e confere que **todo widget `Ss*` exportado** está no yml e que **todo `SsX` do yml é
  exportado** (pendentes à parte); os alvos estão no formato certo.
- `rails/sample/test/components/v19_paridade_web_web_test.rb`: **todo `Ss::*Component`** da gem está no
  yml (par, `so_web` ou `divida_app`) e **todo alvo existe** (constante, helper, método do FormBuilder,
  classe no CSS, arquivo do controller).

Estado atual: 269 pares, 10 apis, 33 só app, 14 só web, 21 dívidas web (`divida:`, 1 pendente) e 1 dívida app (`ProductCard`); 29 entradas pendentes. Pendentes
da v1.9 (marcar como feitas no merge): `SsNotificationCenter` (↔ `NotificationList` e o
`NotificationCenterComponent` que o agente de produto criou), `SsAssistantView`, `SsAssistantConversations`,
`SsCaptureHub`, `SsNotificationTile`, `SsGantt`, `SsTour`, `SsWizard`, `SsDateRangeField`, `SsOtpField`,
`SsTagField`, `SsAuditTrail`, `SsReviewCard`, `SsPersonCard`, `SsBentoGrid`, `SsWhatsNew`, `SsWhatsNewList`,
`SsSkeleton`, `SsSkeletonSwitch`, `SsSplitView`, `SsAdaptiveScaffold`, `SsOpenContainer` (↔
`TransitionComponent`, confirmar), `SsUndoableRemoval` (↔ `UndoableRemovalComponent`), `SsCelebrate`;
só app pendentes: `SsBackGestureListener`, `SsBackShrink`, `SsPredictiveBackScope`, `SsSliverEntrance`;
dívida pendente: `SsIllustrationArt`. Os nomes vieram dos worktrees dos outros agentes em 24/11; confira no
merge.

## 3. UX transversal (Flutter; os apps adotam depois)

### a) Barra que some ao rolar

```dart
Scaffold(body: lista, bottomNavigationBar: SsNavBar(items: abas, currentIndex: i, onTap: ir, hideOnScroll: true))
SsNavScaffold(hideNavOnScroll: true, navBar: SsNavBar(...), body: ...)
```

24 px para baixo esconde, 24 px para cima (ou o topo, ou trocar de aba) mostra. O `SsNavBar` solto escuta o
`ScrollNotificationObserver` do `Scaffold`; no `SsNavScaffold` quem cuida é a casca, que também devolve ao
corpo a altura da barra (e o rodapé do sistema no `MediaQuery.padding`). Leitor de tela ligado: não some.
Reduzir movimento: some sem animar. Escondida, sai do foco do teclado. No web não há barra de baixo para
esconder (o `AppShellComponent` tem o menu do topo).

### b) Busca no menu lateral + Ctrl+K

```dart
SsSideMenu(
  search: SsSideMenuSearch(commands: telasEAcoes, recent: recentes, records: (q) => api.buscar(q)),
  sections: [...],
)
```

A linha "Buscar" no topo do menu fecha o menu e abre o `showSsCommandPalette`. `records:` é chamado 250 ms
depois da última tecla; os registros entram depois das telas e ações, com o `group` que o app der (erro =
nada achado). O `SsCommandPalette`/`showSsCommandPalette` ganharam `search:` (o mesmo callback, para quem
usa a paleta solta). No `SsSideMenuHost`/`SsNavScaffold`, **Ctrl+K** (⌘K) abre a mesma busca com o menu
aberto ou fechado (só se a rota está no topo: com a paleta aberta não abre outra); `SsSideMenuHostState.openSearch()`
abre por código. O atalho aparece na linha só no computador (`SsSideMenuSearch.shortcutLabel`).
Web: o `Ss::AppShellComponent` já tinha o Ctrl/⌘+K (`keydown.ctrl+k@window->ss-shell#search`) abrindo o
`Ss::CommandPaletteComponent` (`search_action:`), com registros pelo `src:`; nada a mudar.

### c) Sincronização completa (como no minhas-vendas-app)

- `SsSyncStatus.resolve(syncing:, failed:, offline:, pending:)` (a regra do `SyncAction` do minhas-vendas-app;
  par: `Ss::SyncStatusComponent.resolve`).
- `SsSyncStatus(failedCount:, lastSyncedAt:)`: "2 com erro"; "Sincronizado às 14:32"/"em 12/11" na dica e no
  leitor de tela. `SsSyncStatus.lastSyncedLabel(at)`.
- `SsSyncPanel(state:, pendingCount:, failedCount:, lastSyncedAt:, error:, details:, onSyncNow:)`: o cartão
  do topo da tela da fila (o "Mais › Sincronização"). Só app (`so_app`): a fila mora no aparelho.
- Textos novos no `SsStrings` (com padrão): `syncFailedCount`, `syncedAt`, `syncedOn`, `syncNever`, `syncNow`.
  (Não entraram no `copyWith`.)

### d) Toque longo e deslizar no item

```dart
SsListItem(
  title: 'Pedido 12', onTap: abrir,
  contextActions: [SsContextAction(Icons.edit_outlined, 'Editar', editar)],
  swipeEnd: SsSwipeSide(icon: Icons.archive_outlined, label: 'Arquivar', color: AppColors.danger, onTrigger: arquivar),
)
```

`contextActions` embrulha no `SsContextMenu` (ganha do `onLongPress`); `swipeStart`/`swipeEnd` no
`SsSwipeAction`. No leitor de tela viram ações personalizadas. Web: as mesmas ações no menu ⋮
(`Ss::RowActionsComponent`); deslizar é só do app.

### e) `ssA11yAudit(tester)`

```dart
import 'package:componentes_ui/testing.dart';

await tester.pumpWidget(app(const PedidosScreen()));
await tester.pumpAndSettle();
await ssA11yAudit(tester); // tapTargets:, labels:, textScale: (1.6; null desliga), settle:
```

Confere alvo de toque ≥ 48 (`androidTapTargetGuideline`; o Flutter pula o que encosta na borda da tela),
rótulo de leitor de tela em todo tocável (`labeledTapTargetGuideline`) e, com o texto em 1,6×
(`platformDispatcher.textScaleFactorTestValue`, que o `MaterialApp` lê), nenhum erro de layout. Falha com a
lista de tudo que achou e devolve o texto ao normal.

## O que ficou de fora

- As 20 `divida:` do yml (fora a pendente) (peças do Flutter sem par web: `SsDial`, `SsThumbRail`, `SsVerticalSlider`,
  `SsMonthGrid`, `SsImageViewer`…) e o `SsProductCard` (`divida_app`).
- Deslizar o item e o voltar preditivo são gesto do app; no web as ações vão no menu ⋮.
- A mola do carrossel ao assentar: o web usa o scroll-snap do navegador (sem passar e voltar).
- `copyWith` do `SsStrings` sem os 5 textos novos.
