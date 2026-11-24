# v1.9 · Transições

Seis peças de movimento, com o mesmo nome dos dois lados quando existem nos dois. Todas desligam com
"reduzir movimento" (`MediaQuery.disableAnimations` / `prefers-reduced-motion`). As durações estão
marcadas com `// v1.9 tokens` (Dart) e `/* v1.9 tokens */` (CSS) para virar `SsMotion.*` / `--ss-dur-*`.

Nada quebra na API: `SsOpenCard`, `SsCelebrate`, `SsEmptyState`, `Ss::EmptyStateComponent`,
`Ss::ConfettiComponent` e `Ss::PageComponent` ganharam parâmetros opcionais.

## 1. Lista → detalhe (container transform)

### Flutter: `SsOpenContainer`, `SsOpenRoute`, `SsOpenPage`

O cartão cresce até virar a tela (raio 18 → 0, fundo escurece, crossfade do conteúdo; ida 460 ms,
volta 380 ms) e encolhe de volta ao fechar. Enquanto a tela está aberta, o cartão fica invisível no
lugar (a lista não pula). Com "reduzir movimento", a tela só aparece (200 ms).

```dart
SsOpenContainer<String>(
  closedBuilder: (context, open) => SsListItem(title: 'Pedido 1042', onTap: open),
  openBuilder: (context) => PedidoPage(id: 1042),
  onClosed: (resultado) {},
)
```

Com **go_router**: o cartão guarda de onde sai (`tag`) e abre pela rota; a rota usa `SsOpenPage` com o
mesmo `tag`. Sem cartão na tela (link direto, notificação), a tela sobe e aparece.

```dart
SsOpenCard(
  tag: 'pedido-${p.id}',
  onOpen: () => context.push('/pedidos/${p.id}'),
  closed: PedidoResumo(p),
)

GoRoute(
  path: '/pedidos/:id',
  pageBuilder: (context, state) => SsOpenPage(
    key: state.pageKey,
    tag: 'pedido-${state.pathParameters['id']}',
    child: PedidoPage(id: state.pathParameters['id']!),
  ),
)
```

`SsOpenCard(closed:, open:)` continua igual: agora é o `SsOpenContainer` com a casca de card
(sombra no claro, borda no escuro), mais `tag:`/`onOpen:` para o go_router.
`SsOpenRoute(builder:, tag:)` é a rota (para quem empurra direto pelo `Navigator`).

### Web: View Transitions com Turbo

O card da lista e o cabeçalho do detalhe levam o mesmo `view-transition-name`; o Turbo 8 faz a
transição entre as páginas quando o `<head>` tem o `<meta name="view-transition" content="same-origin">`.
Sem suporte do navegador (ou com `prefers-reduced-motion`): corte normal.

```erb
<%# layout %>
<head> … <%= ss_view_transitions_head %> … </head>

<%# lista %>
<%= link_to pedido_path(p), class: "ss-card ss-card-pad", **ss_view_transition_attrs(p) do %> … <% end %>

<%# detalhe %>
<%= render Ss::PageComponent.new(title: "Pedido #{p.numero}", back: pedidos_path, view_transition: p) %>
```

- `ss_view_transition_name(registro, part = :card)` → `"ss-pedido-12-card"` (ActiveRecord, objeto com
  `to_param` ou texto).
- `ss_view_transition_attrs(registro, part = :card)` → `{ style: "view-transition-name: …", data: { ss_vt: "card" } }`
  (`:title` e `:image` usam as curvas `.ss-vt-title`/`.ss-vt-img` da v0.9).
- `Ss::PageComponent(view_transition: registro)` põe os atributos no `<header class="ss-page-head">`.
- O mesmo nome não pode aparecer duas vezes na mesma tela (o navegador cancela a transição).

## 2. Voltar preditivo (Android 14+, só app)

O `AppTheme.build` liga no Android o `SsPredictiveBackPageTransitionsBuilder` no `pageTransitionsTheme`:
a ida e a volta pelo botão continuam a transição de sempre (subir e aparecer), e **durante o gesto de
voltar** a página encolhe até 90%, arredonda os cantos e dá um passo para o lado do gesto, mostrando a
anterior por trás; soltou, fecha; desistiu, volta. O iOS segue igual. Os apps ganham só subindo a tag.

O material_ui 1.11 tem o `PredictiveBackPageTransitionsBuilder`, mas fora do gesto ele usa o
`FadeForwards` (Android 16), que mudaria a transição de todos os apps; o builder da suíte usa o gesto
e mantém a nossa transição (`fallback:` troca).

Também reagem ao gesto:

- `SsOpenRoute`: a tela volta para o cartão junto com o dedo;
- folhas (`SsSheet`/`showSsSheet`): descem 48 px e encolhem por baixo;
- diálogos do pacote (`SsRouteScale`: `showSsConfirm`, `showSsPrompt`…): encolhem no centro.

Folha e diálogo fecham com `maybePop` (respeitam o `PopScope`). Rota que não pode sair
(`PopScope(canPop: false)`, a primeira) não mostra prévia. Com "reduzir movimento", o gesto fica com o
sistema (volta normal, sem prévia).

Peças para quem monta rota própria: `SsBackGestureListener(route:, builder:, drivesRoute:)`,
`SsBackShrink(animation:, edge:)` e `SsPredictiveBackScope(style: sheet|dialog, child:)`.

**O app precisa ligar no manifesto** (`android/app/src/main/AndroidManifest.xml`), senão o Android
não manda o gesto e a volta é a antiga:

```xml
<application
    android:enableOnBackInvokedCallback="true"
    ...>
```

## 3. Gráficos animados

### Flutter

A entrada já existia (linha e área se desenham, barras crescem do eixo, rosca varre). Novo:

- **troca de dados**: `SsLineChart`, `SsAreaChart`, `SsBarChart` (e a linha dele), `SsExplodedDonut` e
  `SsTimeChart` interpolam do valor anterior ao novo (520 ms) quando os dados mudam; o eixo acompanha.
  Série com outro número de pontos troca direto; buraco (`null` no tempo) não interpola.
- **rosca gira** um quarto de volta enquanto varre ao entrar.
- Para um gráfico do produto: o mixin `SsChartTransition` (`chartValues(widget)` → `chartShown`).

### Web

- `Ss::LineChartComponent`: a linha (e a área empilhada) **se desenha** da esquerda para a direita (antes
  só aparecia).
- `Ss::DonutChartComponent`: a rosca **gira** ao entrar.
- **Troca de dados no lugar** (Turbo morph, `turbo_stream` com `method: :morph`, JS que muda o atributo):
  `transition` em `d` (linhas e áreas), `y`/`height`/`x`/`width` (barras), `cx`/`cy` (pontos) e
  `stroke-dasharray`/`stroke-dashoffset` (fatias). Navegador que não anima atributo de SVG troca direto.
  Sem JS novo.

## 4. Rolagem no web (só CSS)

- `Ss::PageComponent(shrink: true)`: o cabeçalho gruda no alto e encolhe ao rolar
  (`animation-timeline: scroll()`, 0 a 96 px).
- `.ss-scroll-reveal` (um elemento) e `.ss-scroll-stagger > *` (filhos em cascata): aparecem e sobem ao
  entrar na tela (`animation-timeline: view()`).
- Tudo dentro de `@supports (animation-timeline: …)` e `prefers-reduced-motion: no-preference`: sem
  suporte, nada muda.

## 5. Estados vazios ilustrados

| Flutter | Web | Caso |
|---|---|---|
| `SsIllustration.empty` | `:empty` | nada ainda |
| `SsIllustration.offline` | `:offline` | sem conexão |
| `SsIllustration.noResults` | `:no_results` | busca/filtro sem resultado |
| `SsIllustration.allDone` | `:all_done` | tudo feito |
| `SsIllustration.error` | `:error` | erro ao carregar (cor de perigo; web com `role=alert`) |

```dart
SsEmptyState(illustration: SsIllustration.allDone, title: 'Tudo em dia', subtitle: 'Nenhuma tarefa para hoje.')
SsIllustrationArt(SsIllustration.offline, size: 120) // só a arte
```

```erb
<%= render Ss::EmptyStateComponent.new(illustration: :all_done, title: "Tudo em dia", text: "Nenhuma tarefa para hoje.") %>
```

Desenhadas em código (CustomPaint + ícone / SVG inline) na cor da marca. Entram crescendo com mola e,
paradas, flutuam devagar com os brilhos piscando; decorativas (o leitor de tela lê o título). O
`variant:` antigo do web segue igual.

## 6. Regra de comemoração

Só conquista de verdade, e **no máximo uma por sessão por tipo**: `goal` (meta batida), `streak`
(sequência mantida), `firstUse`/`first_use` (primeiro uso). Meta e primeiro uso soltam o confete;
sequência dá o pulo e o estouro em volta do número, sem confete. O leitor de tela ouve
"Meta batida!" / "Sequência mantida!" / "Primeiro passo dado!" (pt/en/es).

### Flutter

```dart
SsCelebrate(achieved: meta.batida, kind: SsCelebrationKind.goal, child: SsKpiCard(...))

// Porta da regra (armazenamento injetado; o padrão é a memória = o app aberto):
SsCelebrationGate.instance = SsCelebrationGate(store: MinhaStore(prefs), scope: usuario.id);
if (SsCelebrationGate.instance.claim(SsCelebrationKind.streak)) { /* SsBurst próprio */ }
```

`SsCelebrationStore` é a interface (`contains`, `add`, `remove`); `SsMemoryCelebrationStore` o padrão.
A chave é `ss-celebrate:[scope:]<tipo>` (`first_use` com sublinhado, igual ao web). Sem `kind:`, o
`SsCelebrate` comemora toda vez, como antes. Textos: `SsStrings.celebrateGoal/Streak/FirstUse`.

### Web

```erb
<%= render Ss::CelebrateComponent.new(kind: :goal, achieved: meta.batida?) do %> … <% end %>
<%= render(Ss::CelebrateComponent.new(kind: :first_use, on: :click)) do %>
  <button data-action="ss-celebrate#celebrate">Salvar</button>
<% end %>
<%= render Ss::ConfettiComponent.new(kind: :goal) %>   <%# o confete antigo, agora com a regra %>
```

`kind:` aceita `:goal`, `:streak`, `:first_use` (e `:firstUse`); outro dá `ArgumentError`. `achieved:`
falso não comemora; `on: :connect` (padrão) ou `:click`; por JS, o evento `ss:celebrate` no elemento.
A regra fica no `sessionStorage` (`ss-celebrate:<tipo>`), pela função `ssCelebrationClaim(kind)` do
`ss_confetti_controller`. Textos em `componentes_ui.celebrate.{goal,streak,first_use}`.

## Arquivos

- Flutter: `flutter/lib/src/v19/transicoes/` (`open_container`, `predictive_back`, `chart_transition`,
  `illustrations`, `celebration`); mudados: `ss_open_card`, `app_theme` (pageTransitionsTheme),
  `ss_sheet`, `motion_view` (`SsRouteScale`), `ss_empty_state`, `ss_line_chart`, `v09/b_charts`,
  `v15/bar_chart`, `v10/dados_time_chart`, `v09/b_social` (`SsCelebrate`), `ss_strings`.
  Catálogo `test/catalogo_v19_transicoes.dart` (`comV19Transicoes`), testes `test/v19_transicoes_test.dart`.
- Rails: `lib/componentes_ui/transition_helpers.rb`, `Ss::CelebrateComponent`, `ss_celebrate_controller.js`,
  CSS `v19_transicoes.css`; mudados: `PageComponent`, `EmptyStateComponent`, `ConfettiComponent`,
  `ss_confetti_controller.js`, locales. Vitrine `pecas_v19_transicoes`, catálogo
  (`sample/script/catalogo_v19_transicoes.rb`), testes `v19_transicoes_web_test.rb`.

## O que ficou de fora

- Voltar preditivo é só do app (o web usa o voltar do navegador).
- Troca de dados no web depende de o gráfico ser atualizado no lugar (morph/JS); numa visita normal do
  Turbo o gráfico é novo e só toca a entrada. O `TimeSeriesChartComponent` (desenhado no JS) segue como
  estava.
- `SsTimeChart`: na troca, a faixa min/max e os eixos vão direto para o novo (só as linhas deslizam).
- Barras deitadas (`horizontal`) no Flutter: só a entrada, sem troca animada.
