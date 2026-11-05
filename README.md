# componentes-ui

Design system **Lista Clara** da MinhaSuite, num lugar só, para os dois runtimes:

| Pasta | O que é | Quem usa |
|---|---|---|
| `flutter/` | pacote `componentes_ui`: tema (`AppTheme`, `SsColors`, `AppType`, `AppRadius`), `SsBrand` (cor do produto) e os `Ss*` | apps Flutter |
| `rails/` | gem `componentes_ui`: tokens CSS + classes `.ss-*` para Tailwind 4 | webs Rails |

Fica **aqui** só o que é igual em todos os produtos. Componente de um produto só
(`mc_*`, `mv_*`, cartão de crédito, kanban) continua no repo dele.

## Flutter

```yaml
# pubspec.yaml
dependencies:
  componentes_ui:
    git:
      url: https://github.com/minhasuite/componentes-ui.git
      path: flutter
      ref: v0.10.2
```

```dart
import 'package:componentes_ui/componentes_ui.dart';

// Violeta (padrão):
MaterialApp(theme: AppTheme.light, darkTheme: AppTheme.dark);

// Outra cor: guarde num static final (getter recria o tema a cada rebuild).
static final light = AppTheme.build(Brightness.light, brand: minhaMarca);
```

- As fontes (Manrope, DM Mono) vêm **no pacote** (`assets/google_fonts/`); o app só
  liga `GoogleFonts.config.allowRuntimeFetching = false` e pode apagar a cópia dele.
- O pacote depende do `flutter_riverpod` (^2.5.1, o mesmo de todos os apps), por
  causa do `SsAsyncBody`. Plugins (câmera, compartilhar, scanner, cache em disco)
  ficam no app: o componente devolve a escolha ou os bytes (`showSsImageSource`,
  `SsShareController.capture`). Fica no app o que depende da API dele (tradução de
  erro, `CancelToken`), o `share_file` e o `theme_mode_provider`.

## Acesso

Repo **público** desde 04/11/2026 (licença Apache 2.0, arquivo `LICENSE`): os
produtos usam o endereço HTTPS acima sem chave. A deploy key "CI dos produtos"
(`COMPONENTES_UI_DEPLOY_KEY` nos CIs, `--secret componentes_ui` nos
`Dockerfile.prod`) deixou de ser necessária; pode sair de cada produto quando ele
for mexido.

## Rails (Tailwind 4, tailwindcss-rails ≥ 4.2)

```ruby
# Gemfile
gem "componentes_ui", git: "https://github.com/minhasuite/componentes-ui.git", tag: "v0.10.2"
```

```css
/* app/assets/tailwind/application.css */
@import "tailwindcss";
@import "../builds/tailwind/componentes_ui";

/* Outra cor de marca: redefina só as variáveis. */
:root { --accent: #1ba06a; --accent-hover: #138152; --accent-soft: #e3f6ee; }
```

O `tailwindcss:build` gera `app/assets/builds/tailwind/componentes_ui.css` sozinho
(suporte a engines do tailwindcss-rails).

Helpers de view (entram sozinhos em todas as views), com a mesma conta do Flutter:

```erb
<%= ss_amount(money(total)) %>                       <%# R$ 1.234<small>,56</small> %>
<%= ss_sparkline(@vendas_por_dia) %>                  <%# base de um .ss-stat %>
<%= ss_rings([0.72, 0.5], center: "72%") %>
<%= ss_avatar(cliente.nome, status: "ok", brand_hue: 250) %>
<%= ss_odometer(money(total)) %>                      <%# dígitos que rolam quando o valor muda %>
<%= ss_gauge(0.72, label: "da meta") %>               <%# meia-lua com agulha; text: troca o 72% %>
<%= ss_countdown(total: 10, left: 7, label: "dias") %> <%# anel em gomos (até 60) %>
<%= ss_heat(@treinos_por_dia, weeks: 12) %>           <%# { Date => n }, nível 0–4 por quartil %>
<%= ss_status(pedido.status, PEDIDO_STATUS) %>        <%# { "pago" => ["Pago", :success], … } %>
```

O markup de cada classe nova (`.ss-aurora`, `.ss-stat`, `.ss-bars`, `.ss-seg`,
`.ss-fchip`, `.ss-search`, `.ss-item`, `.ss-toast`, `.ss-seal`) está em
`rails/catalogo/index.html`. Na v0.5, HTML nativo primeiro (`<dialog>`, `<details>`,
`role=switch`, `input type=range/date`, `:user-invalid`, `:has()`):

- **Estados:** `.ss-loading-bar`, `.ss-load-more` (`aria-busy`), `.ss-offline`, `.ss-toast-timer` (anel de 5 s no `.ss-toast`, com o botão Desfazer).
- **Diálogos:** `.ss-dialog` + `.ss-dialog-body`/`-icon`/`-actions` (botões empilhados, `.is-danger`), `.ss-sheet` + `.ss-sheet-header` (folha de baixo no celular, central no desktop), `.ss-command` (paleta, `<mark>` no resultado).
- **Formulários:** `.ss-field` (`.ss-field-help`, `.ss-field-error`, `.is-invalid` ou `:user-invalid`), `.ss-money`, `.ss-date-chips`, `.ss-choice`, `.ss-switch-row`, `.ss-stepper`.
- **Dados:** `.ss-timeline` (`.is-done`, `.is-current`), `.ss-gauge`, `.ss-countdown`, `.ss-month` (`.is-today`, `.is-selected`, `.is-out`, marcadores `<i>`), `.ss-heat` (`data-level`), `.ss-progress` com `--marker` e `.is-over`, `.ss-proportion`, `.ss-status` (`data-tone`), `.ss-value-row` (`.is-total`), `.ss-dashed`, `.ss-offer` (`.is-best` + `.ss-offer-tag`), `.ss-deal`, `.ss-source`, `.ss-img`, `.ss-highlight`.
- **Telas:** `.ss-screen-header` (encolhe com `animation-timeline: scroll()`; `.is-compact`), `.ss-onboarding` + `.ss-dots`, `.ss-checklist`, `.ss-tip`, `.ss-plan-locked` + `.ss-plan-locked-cta`, `.ss-quota` (`.is-low`, `.is-out`), `.ss-chat` + `.ss-bubble` (`.is-me`) + `.ss-thinking`, `.ss-sync` (`data-state`), `.ss-menu` (`<details>`).
- **Extras:** `.ss-odometer`, `.ss-selection-bar`, `.ss-compare` (o `oninput` do range põe o `--pos`), arrasto do `.ss-kanban` (`.is-dragging`, `.is-over`, `.ss-drop-slot`), `.ss-action-btn` (`.is-loading`, `.is-done`). Teste dos helpers: `ruby -Ilib test/helpers_test.rb`
(em `rails/`, num container com Rails).

## Direção visual (v0.4)

- **Um momento de luz por tela:** o `SsAuroraCard`/`.ss-aurora` para o número que
  importa; o resto são superfícies calmas.
- **Números são os protagonistas:** DM Mono, centavos menores, variação colorida
  pelo sentido (bom/ruim), não pelo sinal.
- **Movimento curto e de mola** (pílula que desliza, anel que preenche, aviso que
  sobe, bolinha da barra que pula); nada contínuo além da deriva da aurora; tudo
  desliga com menos movimento.
- **Evitar:** vidro (blur) em card e lista, texto ou botão em gradiente, aurora
  atrás de dado denso, mais de um `SsSeal` por tela.

## Peças da v0.5: use no lugar de

Na migração, troque a cópia local (coluna da direita) pela peça do pacote/gem.

| Pacote (Flutter) | Web (gem) | No lugar de |
|---|---|---|
| `SsAsyncBody`, `SsInlineAsync` | `.ss-loading-bar` | `AsyncBody`, `InlineAsync`, `_Empty`/`_Retry` |
| `SsPullToRefresh`, `SsPagedList`, `SsLoadMore` | `.ss-load-more` | `PullToRefresh`, `PagedList`, `LoadMore`, `RefreshIndicator` cru |
| `showSsConfirm`, `showSsConfirmIrreversible`, `showSsPrompt`, `ssRunBlocking` | `.ss-dialog` (`.is-danger`) | `confirmDialog`, `confirmIrreversible`, `promptText`, `runBlocking`, `AlertDialog` à mão |
| `showSsSheet`, `SsSheet`, `SsSheetHeader` | `.ss-sheet`, `.ss-sheet-header` | `showSheet`, `_Folha`, `MvFormHeader`, `showModalBottomSheet` cru |
| `showSsUndo`, `SsToast(countdown:)` | `.ss-toast` + `.ss-toast-timer` | `showSnack`, `showUndoSnack`, `toast` |
| `SsOfflineBanner` | `.ss-offline` | `offlineBuilder` |
| `SsUnsavedGuard` | — | `UnsavedGuard`, `UnsavedChangesGuard` |
| `showSsImageSource` (devolve `SsImageSource`; o app chama o image_picker) | — | `pickImageFromSheet` |
| `SsTextField`, `SsValidators` | `.ss-field` | `AppTextField`, `TextFormField` cru, `moneyValidator`/`intValidator` |
| `SsMoneyField`, `showSsAmountKeypad` | `.ss-money` | `MoneyField`, `BrlInputFormatter`, `showAmountKeypad` |
| `SsDateField`, `SsDateTimeField` | `.ss-date-chips` | `DateField`, `DateTimeField`, `pickDate`, `showDatePicker` cru |
| `SsChoiceField` | `.ss-choice` | `ChoiceField`, `NamedDropdown`, `DropdownButtonFormField` |
| `SsSwitchRow` | `.ss-switch-row` | `SwitchRow` |
| `SsStepper` | `.ss-stepper` | `SsStepper` do personal, `NumberStepper` |
| `showSsPicker`, `foldAccents` | `.ss-command` (busca) | `pickCustomer`, `pickPlace`, `_ProductPicker` |
| `SsSwipeAction` | — (gesto do app) | `Dismissible` |
| `SsLineChart` | `ss_sparkline` | `fl_chart`, `PriceChart`, `MvPriceChart`, `SeriesChart` |
| `SsMonthSwitcher`, `SsMonthGrid` | `.ss-month` | `MonthSwitcher`, calendários à mão |
| `SsHeatCalendar` | `ss_heat` / `.ss-heat` | `MvHeatCalendar` |
| `SsTimeline` | `.ss-timeline` | `MvItinerary*`, `_Marco`, `_Event` |
| `SsGauge`, `SsCountdownRing` | `ss_gauge`, `ss_countdown` | `McPriceMeter`, `MvPriceGauge`, `GaugeArc`, `Mc/MvCountdownRing` |
| `SsProgress(marker:, segments:)`, `SsProportionBar` | `.ss-progress` (`--marker`, `.is-over`), `.ss-proportion` | `McFillMeter`, `McSpectrum`, `GoalTile` |
| `SsStatusBadge`, `SsTone` | `ss_status` / `.ss-status` | `StatusBadge`, `FulfillmentBadge`, `ExpiryBadge` |
| `SsValueRow`, `SsDashedDivider`, `SsHighlight` | `.ss-value-row`, `.ss-dashed`, `.ss-highlight` | `SsValueTile`, `FitValue`, `_Linha`, `McDashedRule` |
| `SsOfferCard`, `SsDealBadge`, `SsSourceChip` | `.ss-offer`, `.ss-deal`, `.ss-source` | `Mc/MvOfferCard`, `DealBadge`, `StoreChip`, `SiteIcon` |
| `SsNetImage` | `.ss-img` | `FotoRede`, `NetImage`, `ProductThumb`, `StripedThumb` |
| `SsScreenHeader`, `SsSliverHeader`, `SsHeaderAction` | `.ss-screen-header` | `ScreenScaffold`, `SsHeader` do personal, `SsTitle` |
| `SsOnboarding`, `SsChecklistCard` | `.ss-onboarding`, `.ss-checklist` | telas de onboarding próprias |
| `SsTip` | `.ss-tip` | `SsTip` do personal |
| `showSsPlanLimit`, `SsPlanLocked`, `SsQuota` | `.ss-plan-locked`, `.ss-quota` | `showPlanLimitSheet`, `PlanLockedCard`, `QuotaHint` |
| `SsChatBubble`, `SsThinking`, `SsChatInput` | `.ss-chat`, `.ss-bubble`, `.ss-thinking` | `_Bubble`, `_Answer`, `_Thinking` |
| `SsShareable` + `SsShareController` (PNG; o app chama o share_plus) | — | `Compartilhavel`, `share_workout_card` |
| `SsSyncStatus`, `SsSyncDot` | `.ss-sync` | `OutboxTile`, `SyncAction` |
| `SsOverflowMenu` | `.ss-menu` | `SsMenu` do gestor, `PopupMenuButton` cru |
| `SsReveal`, `SsDrawIn`, `showSsConfetti`, `SsHaptics`, `SsMotion` | — | `FadeSlideIn`, `MvReveal`, `DrawIn`, `showConfetti`, `ConfettiBurst` |
| `SsIconTile` (v0.6) | `.ss-icon-tile` | `SsIconBadge`, quadrado tonal à mão, `StripedThumb(done:)` |
| `SsTimeField` (v0.6) | `<input type="time" class="ss-input">` | `showTimePicker` cru |
| `SsCheckRow` (v0.6) | `.ss-check` | `Checkbox` + texto à mão |
| `SsStatCard(tone:)` (v0.6) | `.ss-stat` | `SsStatTile` do personal |

Extras (não havia nos apps): `SsOdometer` / `ss_odometer` (só os dígitos que mudam
rolam), `SsActionButton` / `.ss-action-btn` (carregando → ✓), `showSsCommandPalette` /
`.ss-command`, `SsContextMenu` (toque longo), `SsSelectionBar` + `SsSelectable` /
`.ss-selection-bar`, `SsOpenCard` (card que vira tela), `SsCompare` / `.ss-compare`
(antes/depois), `SsKanban` (arrastar entre fases; `.ss-kanban` com `.is-dragging`),
`ssFlyTo` (valor que voa até o total).

## v0.9: paletas, componentes Rails e vitrines

Inspirada nas referências de `D:\Componentes`. Nada quebra da v0.8; a gem passa a
depender do `view_component` (>= 3.9; testado na 3.24 e na 4.22).

**Fundação (os dois lados).** Paletas prontas (28, ver "Paletas" abaixo: `SsBrand.tokyoNight`,
`eucalipto`, `safira`…, mapa `SsBrand.paletas` / `data-palette="tokyo-night|…"`),
gradiente de 4 paradas (`SsColors.gradient4` / `--grad-4`), OLED
(`AppTheme.build(b, oled: true)` / `[data-theme=dark][data-oled]`), sombra na cor do card
(`SsColors.tintedShadow` / `.ss-shadow-tint`), vidro só para sobreposição e herói
(`SsGlass` / `.ss-glass-1..3`), brilho e textura (`SsGlow`, `SsTexture` / `.ss-glow`,
`.ss-texture`), raio contínuo (`AppRadius.squircle` / `.ss-squircle`) e `.ss-swatch`.

**Flutter (novos):** navegação `SsTabsUnderline`, `SsCurvedHeader`, `SsSideRail`,
`SsBellDot`, `SsCountTabs`, `SsStepTopBar`, `SsNavBar(center:)`, `SsSegmented(onDark:)`;
cards `SsMosaicGrid`, `SsTicketCard`, `SsBoardingPass`, `SsWalletCard`, `SsCardStack`,
`SsStatusTabCard`, `SsShapeIcon`, `SsPopOutCard`, `SsDuoStat`, `SsGoalCard`, `SsQrCard`
(recebe o QR pronto), `SsRecurringCard`, `SsFeatureTile`; herói `SsHeroSplash`,
`SsIllustratedSplit`, `SsHeroFlight`, `SsHexButton`, `SsShimmerGlass`; campos
`SsSplitSlider`, `SsVerticalSlider`, `SsDial`, `SsHoldToConfirm`, `SsSwipeToConfirm`,
`SsMorphButton`, `SsPeoplePicker`; agenda `SsDateStrip`, `SsDayAgenda`; mídia
`SsAttachBar`, `SsSnapCarousel`, `SsThumbRail`; dados `SsAreaChart`, `SsExplodedDonut`,
`SsBigRing`, `SsFloatingBars`, `SsLevelCard`, `SsPriceBoard`; social `SsPulseAvatar`,
`SsStoryRing`, `SsProfileHero`, `SsCelebrate`, `SsCallControls`;
`SsAvatar(unread:, ring:)`, `SsAvatarStack(onAdd:)`. Linha de transação rica e
Mês/Semana/Dia não viraram peça: `SsListItem(subtitle:, valueCaption:)` e `SsSegmented`.

**Rails (novos): componentes `Ss::*Component`** (em `app/components/ss`), com
comportamento em controllers Stimulus da gem. O app liga uma vez:

```js
// app/javascript/controllers/index.js
eagerLoadControllersFrom("componentes_ui/controllers", application) // data-controller="ss-*"
```

- Layout: `Page`, `Breadcrumbs`, `AppShell` (menu recolhível, Ctrl+K), `SplitView`,
  `Drawer`, `Tabs` (frame lazy), `StickyActionBar` (form sujo), `SettingsLayout`,
  `BentoGrid`, `HeroSection`, `FeatureStrip`, `PrintLayout` (A4), `ThemeSwitcher`.
- Formulários: `ss_form_with` (`f.ss_text_field :nome, help:, prefix:, suffix:, counter:`,
  obrigatório pelo validator, erro inline do model, `f.ss_submit`), `Combobox`,
  `MoneyInput`, `DateRange`, `SplitAllocator`, `FileDrop` (direct upload), `InlineEdit`,
  `Wizard`, `OtpInput`, `SwatchPicker`, `TagInput`, `OptionCard`, `Range` / `.ss-range`.
- Dados: `DataTable` (ordenação por link com aria-sort, colunas e densidade lembradas,
  linha expansível, seleção em massa, paginação, vira cards no celular), `FilterBar`,
  `KpiStrip`, `AreaChart`, `DonutChart`, `Agenda`, `TimelineHorizontal`, `Gantt`,
  `TreeView`, `AuditTrail`, `PriceBoard`, `CompareTable`.
- Retorno: `Toast` + `ToastStack` (`Ss::ToastStackComponent.append(turbo_stream, ...)`),
  `ConfirmDanger`, `Skeleton` (`frame:` para turbo-frame lazy), `JobProgress`,
  `EmptyState`, `Popover`, `Tooltip`, `Tour`, `WhatsNew`, `Shortcuts` (`?`).
- Cards: `TicketCard`, `BoardingPass`, `ProductCard`, `ReviewCard`, `PricingTable`,
  `StatusTabCard`, `QrCard` (Pix: copiar + validade), `AiInsightCard`, `LevelCard`, `PersonCard`.
- Acabamento: View Transitions do Turbo (`Ss::TransitionComponent`, `.ss-vt-*`) e `CountUp`.

Os helpers da gem (`ss_amount`, `ss_sparkline`…) valem dentro dos componentes
(`Ss::BaseComponent`). Correção: `ss_sparkline` voltou a sair `html_safe`.

### Paletas (fonte única: `paletas/paletas.json`)

As paletas existem **uma vez só**, em `paletas/paletas.json` (slug, nome em pt-BR, `dartName`,
família, as 4 paradas do gradiente da funda à clara, os 5 accents e brandFrom/To/Deep).
`python3 paletas/gerar.py` (no host; não precisa de container) confere o contraste WCAG e
escreve os dois lados de uma vez:

- `flutter/lib/src/paletas.g.dart` (part de `app_theme.dart`) e o trecho
  `// <paletas>` do `SsBrand`: as consts (`SsBrand.safira`…), `SsBrand.paletas`
  (nome → marca) e `SsPaleta.todas` (slug, nome, família, brand) / `SsPaleta.familias`;
- `rails/app/assets/tailwind/componentes_ui/paletas.css` (importado pelo
  `v09_fundacao.css`): `:root[data-palette=…]` claro e escuro e `[data-swatch=…]`;
- `rails/lib/componentes_ui/paletas.rb`: `ComponentesUi::PALETAS` (slug → nome),
  `PALETA_FAMILIA` e `PALETA_FAMILIAS`, de onde sai o `ThemeSwitcherComponent::PALETTES`.

**Para criar ou mudar uma paleta:** edite o JSON, rode `python3 paletas/gerar.py`, depois
`bin/rails tailwindcss:build` na vitrine. Os gerados não se editam à mão;
`python3 paletas/gerar.py --check` falha se estiverem atrasados ou se o contraste quebrar
(accent claro e hover ≥ 4,5:1 sobre o branco e as páginas claras, accent escuro ≥ 4,5:1 sobre
as páginas escuras e o OLED, `--grad` ≥ 4,5:1 com texto branco). Testes de paridade:
`flutter/test/paletas_test.dart` e `rails/sample/test/components/paletas_test.rb`.

Seletor: `Ss::ThemeSwitcherComponent` mostra fichas redondas com o gradiente, agrupadas por
família (mais de 8; `group: false` desliga), o nome da marcada no cabeçalho e o anel que
desliza; `compact: true` vira faixa rolável. No Flutter, `SsPalettePicker(value:, onChanged:)`
é a mesma peça (faixa rolável, anel com `SsSlidingIndicator`). A violeta continua padrão
(`palettes: %w[none …]`; `"violeta"` também vale). Mudança visual: Noite de Tóquio, Marple,
Crepúsculo e Neon pop no Rails passaram a usar os accents do Flutter (antes divergiam), e o
`--grad-4` da violeta no Rails segue o do Flutter (`#3b2bb0 → #8f7dff`).

### Vitrines (todos os componentes ao vivo)

- **Flutter** (`flutter/example`): navegador do catálogo inteiro (os mesmos estados
  do SVG) + telas montadas, claro/escuro/OLED e as paletas.
  `flutter/example/tool/vitrine.sh` compila para web e serve em http://localhost:3910.
  O `example/lib/catalogo` é link para `../../test`.
- **Rails** (`rails/sample`): app Rails 8.1 com a gem por `path:`, uma página por grupo,
  com o código de uso. `rails/sample/bin/vitrine` sobe em http://localhost:3900
  (`PORTA=` muda). O CSS da gem não entra no watch: mudou um `v09_*.css`, rode
  `bin/rails tailwindcss:build`. Testes dos componentes: `bin/rails test` dentro de `sample`.

### Movimento (mola do menu do app em tudo)

Uma mola só nos dois lados: `SsMotion.bounce` (Flutter) e `--ss-bounce` (CSS),
passa ~12% do ponto e assenta. "Reduzir movimento" do sistema desliga tudo.

- **Flutter:** `SsSlidingIndicator` (segmented, chips, abas, trilho, faixa de
  datas), `SsPop`, `SsCheckMark`, `SsSwitch`; `SsPressable` volta com mola.
  Em `motion_view.dart`: `SsInView` (anima quando entra na tela, não ao montar),
  `SsInViewReveal`, `SsTweenInView`, `SsRollSwitcher`/`SsRollingText` (valor que
  rola), `SsOverlayMotion.sheet/dialog` (folha e diálogo com mola);
  `SsAmount(countUp:, roll:)`, `SsOdometer(rollIn:)`. Aviso arrasta para fechar.
- **Rails:** `ss-indicator` (pílula/traço/anel que desliza: abas, segmented,
  filtros, tema, wizard, menu, paginação), `ss-in-view` (entrada ao rolar, com
  cascata; sem JS nada fica escondido), `Ss::CountUpComponent(roll: true)` e
  `ssRoll`, `KpiStripComponent(count:)`; aviso arrastável, gaveta/diálogo/folha
  com entrada e saída. Checkbox e rádio de `.ss-check` passam a ser desenhados
  pelo CSS (para o ✓ se desenhar): o visual muda um pouco.
- Vitrines: seção "Movimento" no Flutter; páginas "Movimento: toque e seleção"
  e "Movimento: entrada, números e camadas" no Rails.

### Idioma (pt/en/es)

Os textos das peças Flutter (botões, dicas, leitor de tela, tempo relativo, meses e
dias da semana) vêm de `SsStrings`, com `SsStrings.pt` (padrão), `.en` e `.es`. O app
multilíngue registra o delegate junto com os do Material:
`localizationsDelegates: [SsStrings.delegate, GlobalMaterialLocalizations.delegate, …]`.
Sem o delegate, vale o idioma do `Localizations` (pt, en ou es); app sem idioma
configurado continua em português. Para trocar textos soltos:
`SsStringsDelegate(apply: (s) => s.copyWith(cancel: 'Dismiss'))` no lugar do delegate,
ou `SsStringsScope.override(apply: …, child: …)` num trecho da árvore. Rótulo passado
ao widget (`confirmLabel:`, `hint:`…) sempre ganha. Funções sem contexto aceitam o
idioma: `timeAgo(d, strings: SsStrings.of(context))`, `ssMonthName(m, s)`,
`SsValidators.required(v, s)`. Moeda e separadores são à parte (`SsFormats`, padrão
real em pt-BR): `SsFormatsScope(formats: SsFormats.usd, child: …)`.

## v0.10: casa e automação, idioma pt/en/es

Peças para migrar o minha-automacao (plano em `../docs/MIGRACAO-minha-automacao.md`),
com o mesmo nome e os mesmos estados nos dois lados. Vitrine Rails: grupo "Casa e
automação"; vitrine Flutter: seção "Casa e automação (v0.10)".

| Peça | Flutter | Rails |
|---|---|---|
| Tile de dispositivo | `SsDeviceTile` | `Ss::DeviceTileComponent` |
| Slider (trilha brilho/kelvin/matiz, variante "fill") | `SsSlider` | `Ss::RangeComponent(track:, submit: :release)` |
| Termostato | `SsThermostat` | `Ss::ThermostatComponent` |
| Switch avulso (checkbox ou `button_to`) | `SsSwitch` | `Ss::SwitchComponent` |
| Teclado de código | `SsCodeKeypad` | `Ss::CodeKeypadComponent` |
| Campo −/+ | `SsStepper` | `Ss::StepperInputComponent` |
| Dias da semana | `SsWeekdayPicker` | `Ss::WeekdayPickerComponent` |
| Gráfico no tempo (cursor, 2 unidades, zoom no web) | `SsTimeChart` | `Ss::TimeSeriesChartComponent` |
| Faixas de estado | `SsStateBands` | `Ss::StateBandsComponent` |
| Logbook por dia | `SsLogbook` | `Ss::LogbookComponent` |
| Tabela de dados | `SsDataTable` | `Ss::DataTableComponent` |
| Câmera, player, aviso com ações, microfone | `SsCameraTile`, `SsMediaPlayer`, `SsNoticeCard`, `SsMicButton` | `Ss::CameraTileComponent`, `MediaPlayerComponent`, `NoticeCardComponent`, `MicButtonComponent` |
| Tela de bloqueio | `SsLockScreen` | — |
| Fluxo de energia, controle remoto, clima, relógio, radar | `SsFlowDiagram`, `SsDPad`, `SsWeatherCard`, `SsClock`, `SsScanRadar` | `Ss::FlowDiagramComponent`, `DPadComponent`, `WeatherCardComponent`, `ClockComponent`, `ScanRadarComponent` |
| Ícone, idioma, blocos, grupo recolhível | `SsIconPicker`, `SsLocalePicker`, `SsBlockList`, `SsCollapsible` | `Ss::IconPickerComponent`, `LocalePickerComponent`, `BlockListComponent`, `CollapsibleComponent` |
| Página com voltar/badge, confirmação global, paginação, paleta Ctrl+K, cor livre | (já havia) | `PageComponent(back:)`, `ConfirmDialogComponent`, `PaginationComponent`, `CommandPaletteComponent`, `SwatchPickerComponent(free:)` |

**Idioma.** Rails: `config/locales/componentes_ui.{pt-BR,en,es}.yml` (o engine
carrega), `ss_t`, `ss_number`, `ss_money`, `ss_date`; JS usa `Intl` com o `lang` da
página (`ss_intl.js`); moeda em `ComponentesUi.config.currency` (padrão BRL).
Flutter: `SsStrings` (veja "Idioma (pt/en/es)" acima) e `SsFormats` para moeda.

**Tokens.** `--accent-solid` / `SsColors.accentSolid` (destaque sólido com 4,5:1 para
texto branco, gerado por paleta); sucesso e perigo do claro mais escuros (AA).

## v0.10.1: o que a migração do minha-automacao pediu

Tudo opcional e aditivo; nada quebra da v0.10.0. Mesmo nome nos dois lados quando a
peça existe nos dois. Os estados novos estão no catálogo (Flutter e `rails/catalogo`)
e nas vitrines.

**Rolagem e listas.** `SsLogbook.sliver(...)` (num `CustomScrollView` / nos `slivers` do
`SsScreenHeader`), `SsLogbook(endAction:, showEnd:)` / `LogbookComponent(end_url:,
end_link_label:, with_end, end_marker: false)`. `SsPullToRefresh(scrollable:)` e a marca
`SsSelfScrolling` (`SsLogbook`, `SsPagedList`, `SsScreenHeader`, `SsMenuView` vão direto,
sem `SingleChildScrollView`). `SsLoadMore(endLabel:)`. `SsTabsUnderline(icons:,
scrollable:)` rola quando não cabe e traz a escolhida para a vista / `TabsComponent`
`icon:` por aba. Novo `SsAgendaList` (`SsAgendaDay`, `SsAgendaItem`, `.sliver`) /
`Ss::AgendaListComponent(days:, week_strip:, selected:, day_url:, empty_label:)`.

**Fuso.** `utcOffset:` em `SsTimeChart`, `SsStateBands`, `SsTimeAxis`, `SsLogbook` e
`SsTimeFormat` (deslocamento fixo: o pacote não tem base de fusos) / `time_zone:` (IANA)
em `TimeSeriesChart`, `StateBands`, `Logbook`. Gráfico: `SsTimeChart(showValues:,
legendAlways:)` / `TimeSeriesChartComponent(show_values:, legend: :always)`.

**Avisos e imagem.** `SsNoticeCard(onTap:, image:, unread:, footer:)` /
`NoticeCardComponent(url:, image_url:, unread:, footer:, with_footer)`.
`SsOfflineBanner(message:, actionLabel:, onAction:)` (no web, `.ss-offline-action`).
`SsNetImage(image:, aspectRatio:)`, `SsNetImage.bytes(load, cacheKey:)` e `SsBytesImage`;
sem altura não estoura (4:3 pela largura). `SsLinearLoader` (o `.ss-loading-bar`).

**Menu, botões, cabeçalho.** `SsMenuView(onDeleteAccount:` opcional`, appearance:,
appearanceOpen:)`, `SsMenuSection(top:)`, `SsMenuCard` público, tema com `SsSegmented`;
`SsMenuSwitch(icon:)`. `SsButton.text(...)` (link). `SsScreenHeader`/`SsSliverHeader
(titleLeading:, titleWidget:)`.

**Campos.** `helperText:` em `SsChoiceField`, `SsDateField`, `SsDateTimeField`,
`SsTimeField`, `SsSlider`; `SsTimeField(validator:)`; `SsFieldLabel`/`SsFieldHelper`
públicos; `SsTextField(autocorrect:, enableSuggestions:)`; `showSsPrompt(autofillHints:,
icon:, textCapitalization:)`; `SsChatInput(maxLength:, sendTooltip:)`;
`SsSlider(decimals:, unit:)` / `RangeComponent` `format:` com a vírgula do idioma.
Novo `SsColorPicker(free:)` + `showSsColorSheet` (o `SwatchPickerComponent(free:)`).
`SsLocalePicker(systemOption:, onSystem:)` / `LocalePickerComponent(system_option:,
form:, button_data:)`. `SsIconPicker(labels:)` / `IconPickerComponent` com rótulo.
`SsBlockList(deleteConfirm:)`, `SsBlock(duplicable:)` / `BlockComponent(html_id:,
move_url:, toggle_method:, toggle_params:, delete_confirm:, duplicable:)`.
`SsStepper` (`onChanged` nulo = apagado, `decreaseLabel`, `increaseLabel`, `debounce`) /
`StepperInputComponent(decrease_label:, increase_label:)`. `SsFilterChip` (`onTap` nulo,
`color:`, `swatch:`).

**Casa.** `SsThermostat(color:, tone:, showModes:, currentText:, currentFormat:,
adjustWhenOff:)` / `ThermostatComponent(color:, tone:, show_modes:, current_label:,
adjust_when_off:)`. `SsCodeKeypad(onChanged:, controller:, actionsNeedCode:)` /
`CodeKeypadComponent(actions_need_code:)` + evento `ss-code-keypad:change`.
`SsDPad(showNavRow:, keys:, extraButtons:, onCommand:)` / `DPadComponent(nav_row:, keys:,
extra_buttons:)`. `SsCallAction(onHoldStart:, onHoldEnd:)`. `SsMediaPlayer(onVolumeEnd:,
onVolumeUp:, onVolumeDown:, muted:, onMute:, power:, onPower:, mediaPicker:)` /
`MediaPlayerComponent(power:, power_url:, volume_param:, volume_up_url:, volume_down_url:,
mute_url:, muted:, with_media_picker)`. `SsWeatherCard(rainChance:, feelsLike:)` /
`WeatherCardComponent(rain_chance:, feels_like:)` (e chuva na previsão diária).
`SsClock(seconds: SsClockSeconds.digits)` e encolhe em caixa estreita /
`ClockComponent(seconds: :digits, fit: true)`. `SsScanRadar(compact:)` /
`ScanRadarComponent(compact:)`. `SsFlowDiagram`/`FlowDiagramComponent` sem sobrepor
rótulos a ~330 px. `SsDeviceTile(onPress:, confirm:, confirmTitle:)` /
`DeviceTileComponent(action_url:, action_params:, confirm_title:, link_data:)`.
`SsCameraTile(status:)` / `CameraTileComponent(status:, with_status)`.

**Só no web.** `AppShellComponent(collapsed:, brand_url:, mobile_brand:, main_class:,
main_max:, with_mark)`, separador e `class:` nos itens, selo 0 some, e o recolhido fica em
`<html data-ss-shell-collapsed>` com o helper `ss_app_shell_head` no `<head>` (sobrevive ao
morph do Turbo, sem piscar). `PageComponent` só com cabeçalho. `CommandPaletteComponent`:
grupos no `src:`, `subtitle:`, `fill:`. `PaginationComponent` com SVG (`prev_icon:`,
`next_icon:`). `EmptyStateComponent(with_art, art: false)`. `WizardComponent(current:,
done:)` com passos por `url:`. `.ss-menu-btn` e `form > button` no `.ss-menu`.
`ToastComponent(role:)` e `position:` por aviso. `SwitchComponent(form_data:,
confirm_title:)`. `OptionCardComponent(url:)`. `JobProgressComponent(stages:, total:)`
(só no web: o Flutter não tem peça de etapas). `AgendaComponent` com `all_day:`.
`Ss::BaseComponent` junta `class:` com `css:` (antes descartava).

## v0.10.2: o minha-automacao 100% na gem e no pacote

Tudo aditivo; nada quebra da v0.10.1. É o que o minha-automacao (web e app) ainda tinha
no produto (`ponte.css`, utilitários soltos nas views, Material cru no app) e que serve a
qualquer produto. Vitrine Rails: grupo "Tela (v0.10.2)"; vitrine Flutter: seção "Novos na
v0.10.2 (tela)"; catálogo nos dois lados.

| Peça | Flutter | Rails / CSS |
|---|---|---|
| Barra de topo compacta (editor, mapa, câmera; `surface`/`dark`/`overlay`) | `SsTopBar(title:, subtitle:, actions:, style:, onBack:, bottom:)` | `Ss::TopBarComponent(title:, subtitle:, back:, variant:, sticky:)` + `with_action` · `.ss-topbar` |
| Botão só de ícone (alvo 48, dica = nome lido) | `SsIconButton(icon:, tooltip:, variant: plain/tonal/outline/danger, badge:, selected:)` | `.ss-icon-btn` (`.is-tonal`, `.is-outline`, `.is-danger`, `.is-sm`, `aria-pressed`) |
| Botão flutuante | `SsFab(icon:, label:, tooltip:)` | `.ss-fab` (`.is-icon`, `.is-static`) |
| Carregando e abertura | `SsSpinner(size:)`, `SsSplash(logo:, title:, message:, delay:)` | `.ss-spinner` (`.is-sm`, `.is-lg`), `Ss::SplashComponent(title:, message:, inline:)` + `with_mark` |
| Linhas num card | `SsRows(children:, indent:, card:)` | `.ss-rows` (`.is-compact`) |
| Arrastar para ordenar | `SsReorderableList(itemCount:, itemBuilder:, onReorder:, spacing:, longPress:)` + `SsDragHandle(index:)` | `Ss::SortableListComponent(url:, param:, name:, label:)` + `with_item(id:, title:)`, `ss-sortable` (ponteiro e ↑/↓) |
| Zona de perigo | `SsDangerZone(title:, message:, child:)` | `.ss-danger-zone` (+ `.ss-danger-zone-title`) |
| Aviso em linha | `SsCallout(tone:, title:, message:, child:, actions:)` | `Ss::CalloutComponent(tone:, title:, icon:)` + `with_action` (bloco com `render(...) { }` ou `do … end`) · `.ss-callout[data-tone]` |
| Código (log, YAML, chave) | `SsCodeBlock(text, terminal:, copy:, maxHeight:, wrap:)` | `Ss::CodeBlockComponent(text:, terminal:, copy:, max_height:, wrap:)` · `.ss-code`, `.ss-code-input`, `.ss-code-inline` |
| Grupo de botões de comando | `SsButtonGroup(buttons: [SsGroupButton(icon:, tooltip:, onPressed:)], label:)` | `.ss-btn-group` (`form > button` também) |
| Passo numerado | `SsStepHeading(n, title, subtitle:, trailing:, done:)` | `.ss-steps` + `.ss-steps-head` (`.is-done`) |
| Divisor com texto | `SsDivider(label:)` | `hr.ss-divider`, `div.ss-divider` |
| Pergunta de um campo | `showSsPrompt` (já havia) | `Ss::PromptDialogComponent(id:, title:, label:, url:, method:, name:, value:)` + `[data-ss-prompt-open]` / `el.ssPrompt()` |
| Atalhos de seção (atual preenchida; menu no celular) | — (no app é o `SsMenuView`) | `Ss::SubnavComponent(items:, label:, menu:)` · `.ss-subnav a[aria-current=page]`, `.ss-subnav-menu` |
| Chips | `SsFilterChip(solid:)`, `SsChipBar(fade:, wrapAbove:)` | `.ss-chip.is-solid` / `.ss-chips.is-solid`, `.ss-chip-count`, `.ss-chips` (`.is-scroll`) |
| Selos e ícone tonal | `SsBadge(dot:)`, `SsBadgeVariant.muted`, `SsIconTile(gradient:)` | `.ss-badge-dot`, `.ss-badge-muted`, `.ss-icon-tile.is-accent/.is-grad/.is-muted/.is-success/.is-warn/.is-danger/.is-sm/.is-lg/.is-circle` |
| Agenda em lista | `SsAgendaItem(end:, allDay:)`, `SsAgendaList(timeWidth:)` (coluna mede o texto; a hora nunca quebra) | `events: [{ end:, all_day: }]`, coluna pelo maior horário (todas alinhadas) |
| Só no web | — | `.ss-inputs` (caixas e rádios soltos desenhados), `.ss-summary`, `.ss-go`, `ss_skip_link` / `.ss-skip`, `turbo-frame.ss-live[busy]` |

**Stimulus novos (web):** `ss-filter` (busca na própria lista, sem acento; `item`, `empty`,
`group`, `count`), `ss-poll` (JSON `{url}`/`{error}`/`{status}`), `ss-reload` (frame ou
página a cada N ms, pausa com a aba escondida), `ss-autosubmit` (`#queue` com atraso,
`#now`), `ss-privacy` (`[data-privacy]` + tecla P), `ss-check-all` (coluna com meio
marcado), `ss-sortable`, `ss-prompt-dialog`; `ss-copy` ganhou o target `source` (copia o
`value` de um input) e `ss-theme#toggle` (claro ↔ escuro).

**Textos novos:** Flutter `SsStrings.allDay`, `copy`, `copied`, `dangerZone`; Rails
`agenda_list.all_day`, `check_all`, `code_block`, `danger_zone`, `prompt_dialog`,
`skip_link`, `sortable`, `spinner`, `subnav`, `top_bar` (pt-BR, en, es).

## Verificar

```bash
podman run --rm -v "$PWD/flutter":/app -v flutter_pub:/root/.pub-cache -w /app \
  ghcr.io/cirruslabs/flutter:stable bash -lc 'flutter pub get && dart format lib test && flutter analyze && flutter test'
```

## Catálogo e SVG

`flutter/test/catalogo.dart` e `rails/catalogo/index.html` descrevem cada
componente (estados e comportamentos). A skill `componentes` exporta tudo em SVG
(`/componentes --export`). Componente novo = entrada no catálogo na mesma mudança.

## Versões

Tag `vX.Y.Z` a cada mudança, e os produtos apontam para a tag. Mudança que
quebra (renomear componente, tirar token) sobe o X, e o produto atualiza quando quiser.

- `v0.1.0` (30/10/2026): primeira versão (base: minhas-vendas e meu-gestor).
- `v0.2.0` (30/10/2026): `SsNavBar`, a barra de abas com o item atual num círculo encaixado num recorte que desliza.
- `v0.3.0` (30/10/2026): `.ss-kanban` na gem (vinha do minhas-vendas e do meu-gestor); `SsNavBar` sem exigir `extendBody`.
- `v0.4.0` (31/10/2026): componentes "únicos" nos dois lados — aurora (`SsAuroraCard`, `SsAuroraBackground`, `.ss-aurora`), indicador (`SsStatCard`, `SsAmount`, `SsDelta`), gráficos (`SsSparkline`, `SsRings`, `SsPillBars`), `SsSegmented`, `SsFilterChip`/`SsChipBar`, `SsSearchField`, `SsListItem`/`SsGroupHeader`, `SsAvatar`/`SsAvatarStack`, `showSsToast`, `SsSeal`, `SsPressable`, `SsCountUp`; helpers Rails (`ss_amount`, `ss_sparkline`, `ss_rings`, `ss_avatar`). `SsNavBar`: a bolinha **pula** em arco (achata, estica, pousa). `SsButton` encolhe ao toque e tem brilho no topo. Botões do menu e dos planos voltam a usar a Manrope.
- `v0.10.2` (05/11/2026): o que faltava para o minha-automacao ficar 100% no pacote e na gem (seção "v0.10.2"): barra de topo, botão de ícone, botão flutuante, carregando/abertura, linhas em card, arrastar para ordenar, zona de perigo, aviso em linha, bloco de código, grupo de comandos, passo numerado, divisor, pergunta de um campo no web, atalhos de seção com menu, chips sólidos e faixa que esmaece, coluna da hora da agenda que cresce, controllers genéricos. Nada quebra; no web o `.ss-subnav` passa a marcar a seção atual (`aria-current=page`) e a esmaecer a borda no celular.
- `v0.10.1` (04/11/2026): o que a migração do minha-automacao pediu (seção "v0.10.1"). Nada quebra; no web, a marca passa a aparecer na barra do celular do `AppShell` (`mobile_brand: false` desliga) e as regras de `.ss-shell[data-collapsed]` ganharam o seletor do `<html>`.
- `v0.10.0` (04/11/2026): peças de casa e automação (tabela da seção "v0.10"), idioma pt/en/es nos dois lados, `--accent-solid`, sucesso/perigo AA. Nada quebra: parâmetros de texto que tinham padrão em português ficaram opcionais (passar String continua valendo); no web, o checkbox e o switch ligado usam `--accent-solid`.
- `v0.9.0` (04/11/2026): paletas, OLED, 58 peças Flutter e 60 componentes Rails (`Ss::*Component` + Stimulus + `ss_form_with`), vitrines Flutter e Rails (seção "v0.9"), movimento com a mola do menu do app em tudo e 28 paletas geradas de `paletas/paletas.json` para os dois lados. A gem passa a depender do `view_component`. Nada quebra da v0.8; no web o `.ss-check` passa a ser desenhado pelo CSS e quatro paletas antigas mudam um pouco de cor (alinhadas ao Flutter).
- `v0.8.0` (02/11/2026): parâmetros que as migrações pediram. `SsListItem(trailing:, dimmed:, onLongPress:, maxLines:)`, `SsTextField(helperText:, minLines:)`, `showSsPrompt(allowEmpty:, maxLines:, maxLength:, message:)`, `SsSearchField(debounce:, suffix:)`, `SsDateField(initialDate:, validator:, showShortcuts:)`, `ssRunBlocking(onCancel:)`, `SsUnsavedGuard(isDirty:)`, `SsSegmented(icons:, disabled:)`, `SsFilterChip(icon:)`, `SsSwitchRow(icon:)`, `SsBadge(icon:)`, `SsCard(tint:)`, `SsMenuAction(checked:, subtitle:)`, `SsOverflowMenu(icon:)`, `SsEmptyState(art:)`, `SsProgress(null)` (indeterminado), `SsChatInput(enabled:, leading:)`, `SsOnboardingPage(action:)`, `showSsPlanLimit(secondaryLabel:, onSecondary:)`, `showSsPicker(initialQuery:)`, `SsCountdownRing(format:, onDark:)` e `SsCountdownRing.mmss`, `SsColors.series` (a 1ª cor é a marca do produto; `AppColors.series[0]` segue violeta). Só Flutter. Nada quebra da v0.7.
- `v0.7.0` (02/11/2026): o que a migração de gestor, compras, viagens, cultivo e financeiro pediu. Novos `SsAsyncSliver` (o `SsAsyncBody` como sliver, para o `SsScreenHeader`), `SsFit`/`SsFitTitle`/`SsButtonPair` (valor e título que encolhem; dois botões que empilham com fonte grande), `SsSectionHeader` (título de bloco com explicação e ação) e `SsValueTile` (linha com nome em 2 linhas e valor que encolhe ou desce). `SsNetImage(provider:)` aceita o provider do app (cache em disco). Correções: o título grande do `SsScreenHeader` cresce com a fonte (estourava em 1,6×) e `SkeletonList`/`SkeletonBox` param com "reduzir movimento". Só Flutter. Nada quebra da v0.6.
- `v0.6.0` (01/11/2026): o que a migração do meu-personal pediu. Novos `SsIconTile` (ícone tonal, `filled`/`circle`), `SsTimeField` e `SsCheckRow`; parâmetros novos, todos opcionais: `SsStepper(label:)`, `SsStatCard(tone:)` (e o número encolhe em vez de estourar a coluna), `SsTextField(suffixText:, textCapitalization:, maxLength:, autofillHints:, focusNode:)`, `SsSearchField(onSubmitted:)`, `SsScreenHeader`/`SsSliverHeader(leading:)` com voltar automático quando a tela pode voltar, `SsScreenHeader(onRefresh:)`, `SsAsyncBody(showRefreshing:)`, `SsEmptyState(compact:)`, `SsShareable(background:)`. Só Flutter (a web já tinha os equivalentes). Nada quebra da v0.5.
- `v0.5.0` (31/10/2026): o que os apps tinham repetido vira pacote (tabela "Peças da v0.5": estados assíncronos, diálogos, folha, desfazer com contagem, faixa offline, campos com validação na hora, dinheiro com teclado próprio, data com atalhos, escolha e busca em folha, contador, deslizar com ação, gráfico de linha com dedo que corre, calendários, linha do tempo, medidor, anel de prazo, progresso com marcador, proporção, status, oferta, imagem de rede, cabeçalho que encolhe, apresentação, primeiros passos, dica, limite de plano, chat com IA, compartilhar como imagem, sincronização, menu ⋮, movimento e vibração por contexto) e extras (odômetro, botão com estados, paleta de comandos, menu de toque longo, seleção múltipla, card que vira tela, antes/depois, kanban com arrasto, valor que voa). O pacote passa a depender de `flutter_riverpod`. Web: classes e helpers equivalentes (`ss_odometer`, `ss_gauge`, `ss_countdown`, `ss_heat`, `ss_status`). Nada quebra da v0.4.
