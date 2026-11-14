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
      ref: v0.22.1
```

```dart
import 'package:componentes_ui/componentes_ui.dart';

// Violeta (padrão):
MaterialApp(theme: AppTheme.light, darkTheme: AppTheme.dark);

// Outra cor: guarde num static final (getter recria o tema a cada rebuild).
static final light = AppTheme.build(Brightness.light, brand: minhaMarca);

// v0.11: densidade (compacta, padrão, confortável). Ver "v0.11" abaixo.
static final denso = AppTheme.build(Brightness.light, density: SsDensity.compact);
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
gem "componentes_ui", git: "https://github.com/minhasuite/componentes-ui.git", tag: "v0.22.1"
```

```css
/* app/assets/tailwind/application.css */
@import "tailwindcss";
@import "../builds/tailwind/componentes_ui";

/* Outra cor de marca: redefina só as variáveis. */
:root { --accent: #1ba06a; --accent-hover: #138152; --accent-soft: #e3f6ee; }
```

```erb
<%# layouts/application: densidade do produto (v0.11) e a escolhida pela pessoa, antes da 1ª pintura %>
<html lang="pt-BR" <%= tag.attributes(ss_density_attrs) %>>
  <head> … <%= ss_density_head %> … </head>
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

**Fundação (os dois lados).** Paletas prontas (30, ver "Paletas" abaixo: `SsBrand.tokyoNight`,
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

## v0.10.3: o que a migração do minha-automacao para a v0.10.2 achou

Tudo aditivo; nada quebra da v0.10.2. Correções e lacunas que o minha-automacao (app e web)
achou ao subir para a v0.10.2. Vitrine Rails: grupo "Tela (v0.10.3)"; catálogo nos dois lados
(estados "v0.10.3" nas entradas de cada peça).

**Correções**

- `SsTopBar`: título e subtítulo agora saem do `textTheme` do tema (Manrope; antes caíam na
  fonte do sistema e viravam quadradinhos nos goldens). No `overlay`, o véu escuro embrulha a
  barra inteira (antes, no `flexibleSpace`, tinha altura zero e o texto branco ficava direto no mapa).
- Web: `turbo-frame.ss-live` não força mais `display: block` (a regra foi para a camada; `.contents`
  do app vence); com `display: contents` (`.contents`, `.is-contents` ou `style`), os filhos pulsam
  enquanto recarrega no lugar da faixa.
- Web: `Ss::FilterBarComponent` lê e escreve arrays (`tipo[]`), leva os filtros ativos (arrays e
  hashes) nos campos escondidos da busca e mantém a query do `url:` (`/pontos?site_id=3`) em todo
  link, na busca e no "Limpar filtros".

**Peças e parâmetros novos**

| Peça | Flutter | Rails / CSS | Produto |
|---|---|---|---|
| Toque longo / duplo no tile de aparelho | `SsDeviceTile(onLongPress:, longPressLabel:, onDoubleTap:)` (vibração média, ação "Mais opções" no leitor de tela; vale até indisponível) | `Ss::DeviceTileComponent(more_url:, more_label:, more_data:)`: botão ⋯ e menu de contexto (clique direito / toque longo) que segue o ⋯; no modo aperto, `url:` vira o ⋯. O toque duplo é só do app | app: menu do aparelho; web: o mesmo menu |
| Segurar para falar | `SsMicButton(holdToTalk:, onHoldStart:, onHoldEnd:, onHoldCancel:, cancelDistance:, compact:)` | `Ss::MicButtonComponent(hold:, compact:)` · eventos `ss-mic:hold-start/-end/-cancel` (ponteiro, Espaço/Enter, clique do leitor de tela alterna) | assistente por voz |
| Microfone no campo de mensagem | `SsChatInput(onMicHoldStart:, onMicHoldEnd:, onMicHoldCancel:, micState:, micLevel:)`: campo vazio mostra o microfone compacto no lugar do enviar | o `MicButtonComponent(hold: true, compact: true, size: 44)` ao lado do campo (o web não tem `SsChatInput`) | chat da casa |
| Vibração leve | `SsHaptics.light()` | `navigator.vibrate` nos controllers | — |
| Ícone tonal sobre o gradiente | `SsIconTile(onGradient: true)` | `.ss-icon-tile.is-on-grad` | herói do painel |
| Faixa de chips rola até o atual | `SsChipBar(currentIndex:)` (só a faixa rola) | `ss-scroll-current` (Stimulus; já no `SubnavComponent` e nas visões do `FilterBarComponent`) | filtros por cômodo |
| Card de opção | — (o app usa `SsCheckRow`/`SsChoiceField`) | `Ss::OptionCardComponent(id:, input: {}, dense:, vertical:)` · `.ss-option-card.is-dense`, `.is-vertical`, `.ss-option-grid.is-tiles` | escolher integração e cômodo |
| Chip de caixa de marcar | `SsFilterChip` (já cobre) | `label.ss-chip > input[type=checkbox\|radio]` (marcado = atual, `:has(:checked)`) · `.ss-chip[aria-current=page]` igual a `true` | filtros em form |
| Checklist de linha inteira | `SsChecklistItem(onTap:)` (já cobre) | `.ss-checklist li > label > input[type=checkbox]` (a linha marca; marcado riscado) | primeiros passos |
| Etiqueta com × em link | — | `.ss-tag > a` | tags de automação |
| Atalhos de seção em abas | — (no app é o `SsMenuView`) | `Ss::SubnavComponent(layout: :tabs)`: abas numa linha no desktop, menu no celular | configurações |
| Base opcional | — (o Flutter já lê `MediaQuery.disableAnimations`) | `.ss-base` (no `<html>`/`<body>`): tira o marcador de todo `<summary>` e corta animação/transição com "reduzir movimento"; `.ss-reduce-motion` no `<html>` corta sempre (preferência do app) | layout do produto |

O marcador do `<summary>` não sai globalmente de propósito: a gem é usada por vários produtos
e um `<details>` cru perderia o único sinal de que abre. Quem quer, põe `.ss-base`.

**Textos novos:** Flutter `SsStrings.micHold`, `micRelease`; Rails `mic_button.hold`,
`mic_button.release`, `device_tile.more` (pt-BR, en, es).

## v0.11: densidade

Resposta a "alguns componentes achei grande" (vitrines e minha-automacao). Três densidades,
iguais nos dois lados: **compacta** (mais coisa por tela: tabela, painel, desktop), **padrão** e
**confortável** (alvos e respiros maiores: quiosque, toque, pouca visão). Os componentes leem
altura, respiro, espaço, linha, card, raio, ícone e um leve ajuste de fonte de tokens, nunca de
número solto. Claro/escuro e movimento não mudam; o alvo de toque nunca cai (48 no app; 40 px no
web com ponteiro grosso).

| Token | Compacta | Padrão | Confortável | Flutter (`SsDensity`) | CSS |
|---|---|---|---|---|---|
| Botão / controle | 40 · 34 px | 48 · 40 px | 52 · 46 px | `controlHeight` | `--ss-control-h` |
| Botão pequeno | 32 · 28 | 36 · 32 | 40 · 36 | `controlHeightSmall` | `--ss-control-h-sm` |
| Campo | 44 · 34 | 52 · 40 | 56 · 46 | `fieldHeight` | `--ss-field-h` |
| Chip | 30 · 28 | 34 · 32 | 38 · 36 | `chipHeight` | `--ss-chip-h` |
| Respiro lateral | 12 · 12 | 16 · 16 | 20 · 20 | `padX` | `--ss-pad-x` |
| Espaço entre itens | 8 · 8 | 12 · 12 | 14 · 16 | `gap` | `--ss-gap` |
| Linha (respiro vertical) | 6 · 7 | 10 · 12 | 14 · 16 | `rowPadV` | `--ss-row-py`, `--ss-row-h` |
| Card | 12 · 14 | 16 · 20 | 20 · 24 | `cardPad` | `--ss-card-pad` |
| Raio campo / card | 12/16 · 10/16 | 14/18 · 12/20 | 16/20 · 14/22 | `radiusField`, `radiusCard` | `--ss-radius`, `--ss-radius-card` (= `--r-field`, `--r-card`) |
| Ícone / quadrado tonal | 18/36 · 15/32 | 20/42 · 17/40 | 22/46 · 19/44 | `iconSize`, `iconTile` | `--ss-icon`, `--ss-icon-tile` |
| Fonte dos controles | ×0,94 | ×1 | ×1,05–1,06 | `font(x)` | `--ss-font-scale` |

(Flutter em dp · web em px.)

**Flutter.** `AppTheme.build(b, density: SsDensity.compact)` põe a `SsDensity` no `extensions` e
alinha o `visualDensity` e os botões/campos Material que sobram. `SsDensityScope(density:, child:)`
troca num trecho (uma tabela compacta numa tela padrão). Os `Ss*` leem `SsDensity.of(context)`
(`d.font(AppType.body)`, `d.space(10)` para respiros sem token). `SsTapTarget` aumenta a área de
toque até 48 sem mudar o layout (o compacto desenha 40 e toca 48). `SsDensityPicker(value:,
onChanged:)` é o seletor (textos `SsStrings.densityLabel/Compact/Standard/Comfortable`); guardar a
escolha e reconstruir o tema é do app. `SsDensity.byName('compact')` lê a preferência salva.

**Rails.** Tokens em `v11_densidade.css` (`--ss-control-h`, `--ss-pad-x`, `--ss-gap`, `--ss-row-h`,
`--ss-row-py`, `--ss-card-pad`, `--ss-radius`, `--ss-font-scale`, `--ss-icon`…), trocados por
`data-ss-density="compact|comfortable"` no `<html>` ou em **qualquer contêiner** (vale para o que
está dentro). `ComponentesUi.configure { |c| c.density = "compact" }` é o padrão do produto;
`ss_density_attrs` (atributo para o `<html>` ou um contêiner), `ss_density_head` (aplica a
escolha guardada antes da 1ª pintura e sobrevive ao morph), `Ss::DensityPickerComponent(target:,
persist:, value:)` + controller `ss-density` (guarda em `localStorage["ss-density"]`, evento
`ss-density:change`). O produto decide se mostra o seletor.

**Vitrines:** seletor de densidade na barra de cima do Rails (e a página "Densidade (v0.11)",
as três lado a lado e o escopo numa tabela) e no `AparenciaBar` do Flutter (seção "Densidade
(v0.11)"; o ícone de densidade na tela de cada componente alterna). Catálogo: `ss-density` e
`ss-density-picker` nos dois lados; `flutter/test/densidade_test.dart` captura as peças
representativas nas três densidades, claro e escuro (`DENSIDADE_SAIDA=<pasta>`).

**Padrões que mudaram (densidade padrão)** — o resto da padrão ficou igual ao da v0.10.3:

| Peça | Flutter (antes → depois) | Web (antes → depois) |
|---|---|---|
| Botão | `SsButton` 50 → **48** (e os botões do fim do `SsMenuView`) | `.ss-btn` 40 (igual) |
| Campo | `SsTextField`/escolha/hora 52 (igual) | `.ss-input`, `.ss-affix`, `.ss-tags-box` 41,6 → **40** |
| Busca | `SsSearchField` 48 (igual) | `.ss-search` 48 → **44** |
| Chip | `SsFilterChip` 34 (igual) | `.ss-chip` ~34 → **32** |
| Linha com chave | `SsSwitchRow` (igual) | `.ss-switch-row` 52 → **48**; `.ss-dashed` 52 → **48** |
| Tabela | `SsDataTable` (igual) | `.ss-table` td 12,8 → **12**, th 12 → **11,4** de respiro |
| Diálogo | — | botões do `.ss-dialog-actions` 44 → **40** |
| Termostato | `SsThermostat` anel 240 → **220**, − e + 52 → **48** (ícone 26 → 24), modos 48 → **40** de desenho (toque 48) | anel 15rem → **13,75rem**, número 2,9rem → **2,6rem**, − e + 52 → **48** (vão 4,5 → 4rem), modos 44 → **40** |
| Teclado de código | `SsCodeKeypad` tecla 64 → **56** | `.ss-keypad` tecla 64 → **56**, largura 20 → **18rem**, ações 48 → **44** |
| Slider "fill" | `SsSlider(fill)` 56 → **48** | `.ss-range.is-fill` 56 → **48** |
| Dias da semana | atalhos do `SsWeekdayPicker` 48 → **34** de desenho (toque 48) | — |
| Confirmar | `SsHoldToConfirm` 56 → **48**, `SsMorphButton` 52 → **48**, `SsSwipeToConfirm` 60/52 → **56/48** | — |
| Tile de aparelho | `SsDeviceTile` (igual; numa grade de altura fixa o vão do meio cede em vez de estourar) | `.ss-device` respiro 14,4 → **14** |

Toque: no app nada fica abaixo de 48 (o `SsTapTarget` cobre o que encolheu no desenho); no web,
o compacto com ponteiro grosso volta a 40 px. Contraste não muda (só tamanho).

**Migrar um produto:** roteiro em [`docs/MIGRACAO.md`](docs/MIGRACAO.md) (levantar, lacunas na
gem com tag, web e app, o que fica no domínio, armadilhas, conferência e como medir o %).

## v0.12: tile com o ícone como chave, agenda dentro do card, indicador e ranking

Pedido do minha-automacao (painéis "Casa" e "Energia"). Vitrine Rails: grupo "Cards e casa (v0.12)";
vitrine Flutter: seção "Cards e casa (v0.12)"; catálogo nos dois lados.

| Peça | Flutter | Rails / CSS | O que mudou |
|---|---|---|---|
| Tile de aparelho | `SsDeviceTile` (mesma API) | `Ss::DeviceTileComponent` (mesma API) | **Uma linha:** o ícone é a chave (`onToggle`/`toggle_url:`), nome e estado ficam onde era a chave. Web: `button role="switch"` com `aria-checked`, rótulo = nome, `title` Ligar/Desligar, Enter/Espaço, dentro de um `form[data-controller=ss-switch]` (pendente/erro/volta como antes). Flutter: `Semantics(toggled:)`, foco + Enter/Espaço (`InkWell`), alvo de 48 (`SsTapTarget`). Desligado com chave: quadrado claro com contorno na cor; ligado: cheio na cor. Sem permissão: o ícone não é chave e o cadeado (menor, não tocável) vai no fim. `wide:` continua aceito (o tile já é deitado) |
| Agenda, dia inteiro | `SsDayAgenda(allDay: [SsAgendaItem])` (novo: a faixa de cima que só o web tinha) | `Ss::AgendaComponent` (correção) | O compromisso de dia inteiro fica **dentro do card** em qualquer largura: uma linha com reticências e o título inteiro no `title=` (web; todo evento ganhou) / `Tooltip` e leitor de tela (Flutter). Web: colunas `minmax(0, 1fr)` |
| Cabeçalho de card | `SsCardHeader(title:, subtitle:, icon:, tone:, trailing:, titleMaxLines: 1)` · `SsCardHeader.titleStyle/subtitleStyle` | `Ss::CardHeaderComponent(title:, subtitle:, icon:, tone:, heading:)` + slot `action` · `.ss-card-head`, `.ss-card-title`, `.ss-card-sub` | A tipografia padrão de título de card (14 / 800) e da linha menor (12, apagada), com o ícone tonal pequeno à direita |
| Card de indicador | `SsKpiCard(label:, value:, icon:, tone:, caption:, delta:, hint:, spark:, onTap:, valueSize: 24)` | `Ss::KpiCardComponent(label:, value:, money:, icon:, tone:, caption:, delta:, good:, trend:, hint:, spark:, url:)` · `.ss-kpi-card` | Um número num card com o cabeçalho padrão e o valor no tamanho de card (o `SsStatCard`/`.ss-kpi` continuam para herói e faixa) |
| Lista ranqueada | `SsRankList(items: [SsRankItem(label:, value:, amount:, share:, caption:, onTap:)], tone:, numbered:)` | `Ss::RankListComponent(items: [{ label:, value:, amount:, share:, caption:, url: }], tone:, numbered:, label:)` · `.ss-rank` | Posição, nome, valor · fatia, barra proporcional ao maior e linha menor; 1º lugar na cor |

**Tom âmbar de energia/luz:** web `tone: :heat` (`#e0952a`, nos três componentes e no tile) ↔ Flutter
`tone: AppColors.aquecFg`.

**Textos novos:** Flutter `SsStrings.ranking`; Rails `rank_list.label` (pt-BR, en, es).
**Controller:** `ss-switch` usa `aria-checked` quando o botão é `role="switch"` (o resto igual).

**Padrões que mudaram:** o `SsDeviceTile`/`.ss-device` deixou de ter a chave à direita (o `Ss::SwitchComponent`
saiu de dentro do tile; quem procurava `.ss-device .ss-switch` no JS do app deve olhar o
`form[data-controller~="ss-switch"]` ou o `.ss-device-toggle`). Respiro do tile 14 → **12** px; nome 0,9 → **0,88rem**.

## v0.13: seções, mosaico em colunas, coluna lateral, área, foto, marca de duas cores, textos e formulário

Pedido do minha-automacao (painéis e formulários 100% na gem). Tudo aditivo; nada quebra da v0.12. Vitrine Rails:
grupo "Painéis (v0.13)"; vitrine Flutter: seção "Painéis (v0.13)"; catálogo nos dois lados.

| Peça | Flutter | Rails / CSS |
|---|---|---|
| Título de seção com ícone e ação | `SsSection(title, icon:, action:, onAction:)` (`icon:` novo) | `Ss::SectionComponent(title:, icon:, heading: :h2)` + slot `action` · `.ss-section-row` (o `.ss-section` com ícone) |
| Cabeçalho de bloco (1,15rem / 800) | `SsSectionHeader(title, subtitle:, icon:, action:)` (`icon:` novo) | `Ss::SectionHeaderComponent(title:, subtitle:, icon:, heading:)` + slot `action` · `.ss-section-head` |
| Mosaico em colunas (1/2/3/4 por 640/1024/1440) | `SsMasonry(children:, maxColumns:, spacing:)`, `SsMasonry.columnsFor(width)` | `Ss::MasonryComponent(max:)` · `.ss-masonry` (`.is-max-N`; filho `display: contents` vale pelo de dentro; `.ss-section-row` gruda no card seguinte) |
| Conteúdo + coluna lateral | `SsAsideLayout(main:, aside:, breakpoint: 1024, spacing:, asideLabel:)` | `Ss::AsideLayoutComponent(label:)` + slots `main`/`aside` · `.ss-aside-layout` (a coluna gruda no topo no computador) |
| Bloco do mosaico com pílulas | `SsMosaicTile(facts: [SsMosaicFact(label, icon:, tone:, onTap:, semanticLabel:)])` (novo; uma linha que rola de lado; desde a v0.20.3 `tone:` é um `SsTone` e a pílula com `onTap:` é um botão à parte, que ganha do `onTap` do bloco) | `Ss::MosaicTileComponent(title:, caption:, icon:, image_url:, variant: 0..4, facts: [{ label:, icon:, num:, tone:, title:, url:, link_data: }], url:, link_data:)` · `.ss-mosaic` (matiz da marca deslocado como o `colorsFor`, ou foto com véu). Desde a v0.20.3: `tone:` `ok`/`warn`/`danger`/`info` (`.ss-mosaic-fact.is-warn`…); pílula com `url:` é `a.ss-mosaic-fact` e, com `url:` no bloco, ele vira `div.ss-mosaic.is-linked` com o link esticado `a.ss-mosaic-link` (link dentro de link não vale) |
| Card de foto | `SsPhotoCard(image:, title:, badge:, aspectRatio:, dimmed:, onTap:)` | `Ss::PhotoCardComponent(src:, title:, badge:, ratio: "16 / 9", dimmed:, alt:, url:)` · `.ss-photo` (`.is-dimmed`) |
| Chip que alterna, só ícone/cor, travado | `SsFilterChip` (já cobre) | `.ss-chip[aria-pressed=true]` (igual ao atual), `.ss-chip.is-icon`, `.ss-chip-swatch` (`--c`), `.ss-chip[aria-disabled=true]` |
| Avatar com anel e ponto apagado | `SsAvatar(ring:, status:)` (já havia) | `ss_avatar(name, ring: true, status: "muted")` (`ring:` e `"muted"` novos) |
| Marca a partir de uma ou duas cores | `SsBrand.fromColors(accent, [accent2])`, `ssMix(a, b, t)` (color-mix em sRGB) | `ComponentesUi.brand_css(accent, accent2)` / `ss_brand_style(...)`: `--accent`, `--accent-hover`, `--accent-soft`, `--accent-solid`, `--grad`, `--glow`, `--ring` |
| Texto longo (termos, privacidade, ajuda) | `SsProse(children:, maxWidth:)`, `SsProse.paragraphs(texto)`, `SsProseList`, `SsProse.heading(context)` | `Ss::ProseComponent(tag: :article)` · `.ss-prose` (parágrafos, títulos, listas, links, citação) |
| Parágrafo de abertura de aba/seção | `SsIntro(texto)` | `Ss::IntroComponent(text:)` (ou bloco) · `.ss-intro` |
| Grupo de campos com ajuda do grupo | `SsFieldGroup(label:, helperText:, children:, spacing:)` | `f.ss_fieldset(legend:, help:, class:, wrapper_class:) { … }` / `ss_fieldset(...)` fora do form · `.ss-field-group` |
| Formulário | — | `wrapper_class:` em todo `f.ss_*` (vai no `.ss-field`/fieldset: coluna de grade sem `<div>` a mais); `f.ss_select(..., selected:)` e `ss_collection_select(selected:)` sem model; `f.ss_submit(variant: :primary/:outline/:ghost/:danger, small:)` |
| Árvore com rótulo longo | — (o app não tem árvore) | `Ss::TreeViewComponent(wrap: true)` · `.ss-tree.is-wrap` (quebra em vez de reticências) |

`SsBrand.fromColors` deriva os tons com o preto (`AppColors.scrim`) e o branco (`AppColors.surfaceLight`) da
suíte: hover 14% mais escuro, suave 12% sobre o branco (22% sobre a superfície no escuro), accent do escuro
28% mais claro, fundo do gradiente 35% mais escuro. Use no tema do usuário em vez de `Colors.black/white`.

**Textos novos:** Rails `aside_layout.label` (pt-BR, en, es).

## v0.20.4: linhas repetíveis com cabeçalho único e colunas próprias, tabela que não vira cartão e o número grande separado do card

O que o pedido do minhas-vendas (web) achou no `Ss::RepeaterComponent` da v0.20.0: cada linha repetia os rótulos, o ×
tinha `margin-top` fixo e as colunas só saíam com uma `<div>` de grade do Tailwind dentro da linha. Tudo aditivo (sem os
parâmetros novos, igual à v0.20.0). Catálogo: estado `cabecalho` no `ss-repeater` (`flutter/test/catalogo_v20.dart`) e a
seção `ss-repeater-header` em `rails/catalogo/index.html` (`rails/sample/script/catalogo_v020.rb`); testes em
`flutter/test/v20_test.dart` e `rails/sample/test/components/v20_web_test.rb`. CSS em `v20_web.css`.

| Peça | Flutter | Rails / CSS | No lugar de |
|---|---|---|---|
| Cabeçalho único | `SsRepeater(header: ['Produto', 'Qtd', 'Total'], flex: [4, 1, 2])`: o cabeçalho uma vez em cima (versalete, fio embaixo, a coluna do × reservada) e o × no meio da linha; os campos usam `SsTextField(label:, hideLabel: true)` | `Ss::RepeaterComponent(header: ["Produto", "Qtd", { label: "Total", align: :end }])` → `.ss-repeater.has-header` + `.ss-repeater-head` (só a partir de 48rem; `aria-hidden`, os campos continuam com rótulo) | o rótulo repetido em cada linha |
| Rótulos só para o leitor de tela | (`hideLabel:` em cada campo) | `hide_labels:` (padrão `true` com `header:`): `.ss-field > label`, `legend` e `.ss-label` da linha ficam visíveis só abaixo de 48rem; o × vai ao meio da linha (`.is-labels-hidden`) | `margin-top` fixo do × |
| Colunas da linha | `SsRepeater.cells([...], flex: [4, 1, 2])` (a linha com os mesmos flex do cabeçalho) | `columns: [4, 1, "7rem"]` (número = `minmax(0, Nfr)`) ou texto de `grid-template-columns`, no componente (cabeçalho e linhas) ou por linha em `r.row(columns:)`; vale a partir de 48rem, abaixo a grade automática | `<div class="grid grid-cols-2 md:grid-cols-12 …">` dentro da linha |
| Atributos da linha | — | `r.row(data: {…}, class: "…", id: "…", **attrs)` no `.ss-repeater-row` (`data:` soma ao alvo do `ss-repeater`, `class:` soma) | `data-row` numa `<div>` interna |
| Tabela que continua tabela no celular | `SsDataTable(stack: false)`: nunca vira cartões; quando as colunas não cabem, rola de lado (com `stickyFirstColumn`, a 1ª fica parada; cada coluna sem `width` tem no mínimo `minColumnWidth`) | `Ss::DataTableComponent(stack: false)` → `.ss-dt.is-scroll` (abaixo de 640px segue tabela, rolando de lado; `t.column(sticky: true)` funciona) | escala de 14 dias virando 14 linhas de cartão |
| Número grande | `AppType.statNum` (já existia) | `.ss-figure` (novo nome) = o `.ss-stat` solto da v0.5 | `.ss-stat` dentro do herói saindo branco sobre card branco |

Uso no pedido: `render(Ss::RepeaterComponent.new(add_label: "Adicionar item", header: ["Produto", "Descrição", "Qtd", "Unitário", "Desc.", { label: "Total", align: :end }], columns: [4, 2, 1, 2, 1, 2]))`
e, em cada linha, `r.row(data: { auto_price: 1, promo_discount: 0 }) { campos direto, um por coluna }`.

Catálogo também: estado `sem-cartoes` no `ss-data-table` (Flutter) e as seções `ss-data-table-scroll` e `ss-figure` (web).

**Padrões que mudaram.**

- **`.ss-stat` tinha dois desenhos** no `engine.css`: o número grande da v0.5 (`.ss-hero .ss-stat`, `.ss-card .ss-stat`) e,
  mais abaixo, o card de indicador (`.ss-stat` com `.ss-stat-body`/`.ss-stat-label`/`.ss-stat-foot` e `.ss-spark`), que dava
  fundo de superfície a **todo** `.ss-stat`: no herói o número saía branco sobre card branco. Agora o card só vale com
  `.ss-stat.is-card` ou com o markup dele (`.ss-stat:has(> .ss-stat-body)`, o que mantém o markup antigo); `.ss-stat` solto
  é só o número, e `.ss-figure` é o mesmo número com nome próprio (prefira em código novo). Conferido em 10/11 nos webs
  (`*-workspace/*/app/views`): meu-gestor e minhas-vendas usam `.ss-stat` só como número (`<p class="ss-stat">`, mais de
  60 lugares, que deixam de ganhar o card); ninguém usava o card fora da vitrine/catálogo da gem (que ganharam `.is-card`).
- Sem `header:`/`columns:`/`hide_labels:` o repetidor é o da v0.20.0; sem `stack: false` a tabela vira cartão no celular
  como antes (as regras do celular passaram a `.ss-dt:where(:not(.is-scroll))`, sem mudar a especificidade).
## (próxima) área segura do celular (`viewport-fit=cover`)

Com `<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">` (PWA instalada no
iPhone/Android, tela cheia), a página vai até as bordas e o `env(safe-area-inset-*)` passa a valer. A moldura
(`.ss-shell-top`, `.ss-shell-content`, a gaveta `.ss-shell-side`), os toasts, a barra de seleção, a barra fixa e as
gavetas (`.ss-drawer`, `dialog.ss-drawer-panel`) agora respeitam o entalhe, a ilha e a barra de gestos
(`safe_area_web.css`). Sem `viewport-fit=cover` ou fora do celular o `env()` é 0 e nada muda. O `.ss-fab`,
o `.ss-speed-dial` e a `.ss-sheet` já respeitavam. No Flutter é o `SafeArea` de sempre (nada novo).

## v0.23.4: campos que aparecem conforme a escolha (`ss-reveal`)

Achado na migração do minha-automacao web (formulário do card do painel: os campos de cada tipo e de cada ação de
gesto apareciam por um `<style>` gerado na view). Teste em `rails/sample/test/components/v23_4_web_test.rb`.

- **Stimulus `ss-reveal`**: `data-controller="ss-reveal"` no contêiner, o `<select>` com `data-ss-reveal-target="source"` e
  `data-action="change->ss-reveal#update"`, e cada item com `data-ss-reveal-for="tipo1 tipo2"`: aparece quando o valor
  escolhido está na lista, some (`hidden`, mesmo com `display` próprio) nos outros. Um `ss-reveal` dentro de outro não se
  mistura (cada um cuida só dos seus itens). No Flutter isso é estado do widget (um `if` no `build`).

**Padrões que mudaram.** Nenhum.

## v0.23.3: abas no seletor segmentado e o botão sem desenho que não atropela

Achado na migração do minha-automacao web. Testes em `rails/sample/test/components/v23_3_web_test.rb`.

- **`Ss::SegmentedComponent(role:)`** troca o `role="group"` (ex. `"tablist"`) e o `role:` do item vai nele (`"tab"`, com
  `aria: { selected: }`): abas leves com a semântica certa (andares de uma planta).
- **`.ss-btn-bare`** passa a valer só por `:where(...)` (especificidade zero): quando o botão também tem outra classe
  (`.ss-checklist-x`, uma classe do produto), ela vence. Antes o bare passava por cima (largura toda, `display: block`).

**Padrões que mudaram.** Botão `variant: :bare` com outra classe agora fica com o desenho dessa classe.

## v0.23.2: o verificador do Flutter pega chamada com tipo record
- `conferirConformidade` passa a reprovar `showDialog<({String kind, String body})>(` e `showModalBottomSheet<(int, String)?>(`
  (o tipo record escapava da regra da v0.19.1). App que tinha esse caso escondido passa a acusar. Nada mais muda.
## v0.23.1: amostra de tema no formulário, opção de rádio desligada e o `form=` do botão

Achado na migração do minha-automacao web. Nada quebra. Catálogo: `ss-swatch-radio` (de `rails/sample/script/catalogo_v0231.rb`);
testes em `rails/sample/test/components/v23_1_web_test.rb`.

- **`f.ss_swatch_radio(method, value, label:, style:, size: :lg, block:, dots: 4, bar: true, checked:)`**: o `.ss-swatch` (galeria de
  temas da v0.14) com o rádio montado pela gem; com bloco, o conteúdo entra no lugar das bolinhas (a opção "Herdar").
- **`f.ss_radio_buttons`**: um 3º item na opção vai no input dela (`["Bluetooth", "ble", { disabled: true }]`).
- **`Ss::ButtonComponent(form: "id")`** num `<button>` sem `href` vira o atributo `form=` (antes sumia); o `form: {}` (hash)
  segue indo no `<form>` do `button_to`.

**Padrões que mudaram.** Nenhum.

## v0.23.0: relógio do pacote, seletor segmentado, chips de marcar, botão sem desenho, movimento, grade por tela e papel de parede

O que o minha-automacao (web e app) pedia para ficar 100% na gem, sem CSS próprio e sem `<button>`/`<input>` à mão.
Tudo aditivo; nada quebra. Catálogo: `flutter/test/catalogo_v23.dart` (`ss-time-picker`) e `rails/catalogo/index.html`
(`ss-segmented`, `ss-btn-bare`, `ss-chip-check`, `ss-anim`, `ss-span-grid`, `ss-wall`, de `rails/sample/script/catalogo_v023.rb`);
vitrine Rails "Painel e ilustração (v0.23)"; testes em `flutter/test/v23_test.dart` e `rails/sample/test/components/v23_web_test.rb`.
CSS em `v23_web.css`.

- **Flutter:** `showSsTimePicker(context, initialTime:, helpText:, confirmText:, cancelText:, initialEntryMode:, use24h: true)`,
  par do `showSsDatePicker` e no lugar do `showTimePicker` cru (o verificador já o reprovava). Texto novo `SsStrings.pickTime`
  ("Escolher hora" / "Pick a time" / "Elegir hora"). O `SsTimeField` e o chip de hora do `SsDateTimeField` passam a usá-lo.
- **`Ss::SegmentedComponent(items:, label:, scroll:)`** ↔ `SsSegmented`: o `.ss-seg` montado pela gem. Item com `href:` vira `<a>`
  (`aria-current`), sem ele `<button>` (`aria-pressed`; `type: :submit` com `name:`/`value:`). `aria-selected` também marca.
  `scroll: true` (`.ss-seg.is-scroll`): itens do tamanho do texto numa faixa que rola, o escolhido em `--surface` (abas leves).
- **`Ss::ButtonComponent(variant: :bare)`** ↔ `SsPressable`: `.ss-btn-bare`, botão sem desenho para conteúdo livre (card, amostra).
- **`f.ss_chip_check_box` / `f.ss_chip_radio_buttons`** ↔ `SsFilterChip`: o `.ss-chip` com o input dentro (desenho da v0.10.3).
- **Movimento (só web):** `.ss-anim-spin|breathe|float|twinkle|blink|dash|draw|ping|shimmer|from|to|shuttle|path|tick|blip`, reguladas
  por `--ss-anim-dur/-delay/-ease/-iter/-dir/-fill` e pelas próprias (`--ss-anim-float`, `-dash`, `-ping`, `-from`, `-to`); paradas
  com "menos movimento". Para ilustração e arte viva do produto sem `@keyframes` próprio.
- **Grade por tela (só web):** `.ss-span-grid` + `.ss-span` (`--ss-span-m/-t/-d`, celular/tablet/computador), `data-ss-screen` num
  ancestral força a tela, `.is-full`, `.ss-hide-mobile|tablet|desktop`, `data-tone` e `.ss-span-flags`.
- **Papel de parede (só web):** `.ss-wall` no `<body>` (`--ss-wall-img`, `--ss-wall`, `--ss-wall-blur`, `.is-dim` + `--ss-wall-dim`) e
  `.ss-wall-glass` (cards de vidro pelos tokens `--ss-card-*`).

**Padrões que mudaram.** O relógio do `SsTimeField`/`SsDateTimeField` ganha os textos do `SsStrings` e fica sempre em 24 h.

## v0.22.1: a barra fixa com `always: true` não some mais

Correção achada no meu-gestor web (Revisão de preços, "Enviar os marcados"): com `Ss::StickyActionBarComponent(always: true)`,
mudar um campo e voltar ao valor original escondia a barra, e não havia como enviar sem recarregar. A causa era o
Stimulus `ss-dirty`: o setter do "sujo" fazia `toggleAttribute("data-visible", on)` sem saber do `always`, então
qualquer volta ao estado inicial (e também Cancelar e o `submit`) tirava o `data-visible` que o `always` tinha posto.
Agora o componente passa `data-ss-dirty-always-value="true"` e o controller mostra a barra com `sujo || always`; o
"sujo" (`form[data-dirty]`) continua cuidando só do aviso ao sair. Sem `always`, nada muda: a barra aparece enquanto o
form difere do inicial (o form inteiro é comparado, então voltar um campo com outro ainda alterado mantém a barra) e
some quando volta tudo. Teste em `rails/sample/test/components/v22_1_web_test.rb`; catálogo: comportamento do
`ss-sticky-bar-v20`.

Flutter: nada a corrigir. O `SsStickyActionBar(visible:)` não guarda estado; quem decide é o app (padrão `true`).

**Padrões que mudaram.** `StickyActionBarComponent(always: true)` passa a ficar visível também depois de voltar ao
original, de Cancelar e de enviar (antes sumia). Quem contornou isso no produto (re-pondo `data-visible` por JS) pode tirar.

## v0.22.0: tela de entrada "Folhinha" e a fonte de exibição

A identidade nova das telas de entrada da suíte (proposta "Folhinha", aprovada em 13/11/2026): a folhinha de parede do
comércio com a data de hoje, o formulário do produto no bloco e a faixa do patrocinador na cor do produto. Tudo aditivo;
nada quebra. Catálogo: `flutter/test/catalogo_v22.dart` (`ss-auth-folhinha`) e `rails/catalogo/index.html` (seção
`ss-auth`, de `rails/sample/script/catalogo_v022.rb`); vitrine Rails "Entrada (v0.22)"; testes em `flutter/test/v22_test.dart`
e `rails/sample/test/components/v22_web_test.rb`. CSS em `v22_web.css`.

| Peça | Flutter | Rails / CSS | No lugar de |
|---|---|---|---|
| Tela de entrada | `SsAuthLayout.folhinha(product:, title:, subtitle:, tagline:, variant: SsAuthVariant.sheet \| wall \| pad, date:, note:, brand:, footer:, children:)` | `Ss::AuthLayoutComponent(product:, title:, subtitle:, tagline:, variant: :sheet \| :wall \| :pad, date:, note:, brand:, brand_href:, links:)` + bloco | layout de login próprio do produto (card centralizado, halos) |
| Fonte de exibição | `AppTheme.display(context, size:, weight: w800 \| w900, color:)` (Big Shoulders Display empacotada, OFL) | `--ss-font-display` + `ss_display_font_tag(preconnect:)` no `<head>` | `fontFamily:`/`font-family` solto no produto |
| "Parte da MinhaSuite" | `SsStrings.authPartOf(brand)` | `componentes_ui.auth.part_of` (+ `months`, `days`, `links_label`) | texto fixo |

- **As três variações:** `sheet` é a folha pendurada (data no alto, o bloco e a faixa do produto embaixo); `wall` é a
  parede (folhinha grande à esquerda e o formulário numa coluna à direita; abaixo de 840 px, empilha); `pad` é o bloco
  de destacar (faixa colada em cima, folha picotada e a de amanhã aparecendo por baixo).
- **O bloco é do produto,** montado com as peças de sempre: `ss_form_with` / `SsTextField`, `Ss::GoogleButtonComponent` /
  `SsGoogleButton`, `Ss::CalloutComponent` / `SsCallout` (senha errada, link enviado), `Ss::TextLinkComponent` /
  `SsLinkText`, `Ss::ButtonComponent` / `SsButton`. A tela serve para entrar, criar conta, esqueci a senha e "link enviado".
- **Só tokens:** folha = `--surface`/`c.surface`, parede = `--page`/`c.page`, faixa = `--accent-solid`/`c.accentSolid`,
  domingo = `--danger`/`c.danger`. A cor do produto entra pelo `--accent`/`SsBrand` como sempre.
- **Fonte:** o web carrega a Big Shoulders Display com `ss_display_font_tag` (sem ela, cai para a fonte do texto); o
  Flutter já traz os pesos 800 e 900 em `assets/google_fonts` (com `OFL-BigShouldersDisplay.txt`). Só para título curto e
  número grande; texto corrido continua na Manrope.
- **Acessibilidade:** na `wall`, a folhinha grande fica fora do leitor de tela (`aria-hidden` / `ExcludeSemantics`); o
  título do bloco é o `h1` / cabeçalho.
- **O construtor padrão do `SsAuthLayout` (halos e ícone) não muda:** o app só troca quando escolher a folhinha.

**Padrões que mudaram.** Nenhum.

## v0.21.0: acenos de estado da casa e brilho real da lâmpada

Pedido do minha-automacao ("beleza" dos painéis: ideias 16 e 18). Tudo aditivo; nada quebra. Catálogo:
`flutter/test/catalogo_v21.dart` (`ss-cue` novo; estado `brilho` no `ss-device-tile`) e `rails/catalogo/index.html`
(seções de `rails/sample/script/catalogo_v021.rb`: `ss-device-level-v21`, `ss-cue`); vitrine Rails "Casa (v0.21)";
testes em `flutter/test/v21_test.dart` e `rails/sample/test/components/v21_web_test.rb`. CSS em `v21_web.css`;
Stimulus novo `ss-cue`.

| Peça | Flutter | Rails / CSS | No lugar de |
|---|---|---|---|
| Aceno de mudança de estado | `SsCue(kind: SsCueKind.on \| open \| arrive, active:, color:, radius:, child:)` | `.ss-cue` + `data: ss_cue_data(kind: :on \| :open \| :arrive, active:, key:)` (Stimulus `ss-cue`) | animação de "ligou/abriu/chegou" no CSS ou no widget do produto |
| Brilho real no tile | `SsDeviceTile(level: 0..1)` (`intensity` = .35 a 1) | `Ss::DeviceTileComponent(level: 0..1)` → `.ss-device.has-level` + `--ss-level` | opacidade/filtro do produto em cima do `.ss-device` |

- **Regra dos acenos:** tocam **uma vez** (620 ms) quando o estado vira ativo; nunca na primeira pintura (abrir a tela
  não acena tudo) nem ao desligar. `on`: pulo .94 → 1 pela mola (`--ss-bounce`/`SsMotion.bounce`) e halo na cor
  (`--tone`/`color:`, a cor real da lâmpada); `open`: gira ~28° pela borda esquerda (porta) e volta; `arrive`: sobe
  8 px e assenta. No web, `key:` guarda o estado entre trocas do HTML (Turbo Frame/Stream refaz o elemento); sem
  `key`, só a troca do atributo no mesmo elemento acena. "Menos movimento" (`prefers-reduced-motion` /
  `MediaQuery.disableAnimations`) desliga. Não mexe no layout.
- **Brilho:** ligado, a tinta do fundo, a borda, o degradê e o halo do ícone vão de 35% (`level` 0) a 100% (`level` 1);
  sem `level`, igual a antes.

**Padrões que mudaram.** Nenhum.

## v0.20.2: projeção tracejada no gráfico de barras

O que o fluxo do mês do meu-financeiro perdeu ao sair do Chart.js: a linha **tracejada** do saldo projetado, de hoje
até o fim do mês, por cima das barras e da linha do saldo acumulado. Tudo aditivo (sem `projection:` nada muda).
Catálogo: estado `projecao` do `ss-bar-chart` (`flutter/test/catalogo_v15.dart`) e `ss-barc-proj` em
`rails/catalogo/index.html` (seção de `rails/sample/script/catalogo_v020_projecao.rb`); testes em
`flutter/test/v15_test.dart` e `rails/sample/test/components/projecao_web_test.rb`.

| Peça | Flutter | Rails / CSS | No lugar de |
|---|---|---|---|
| Linha projetada | `SsBarChart(projection: SsSeries(...), projectionFrom: hoje)` | `Ss::BarChartComponent(projection: { name:, values:, tone:/color: }, projection_from: hoje)` · `.ss-barc-proj`, `.ss-barc-dot.is-proj`, `.ss-barc-legend li.is-dashed` | segunda linha de Chart.js/`fl_chart`, ou a projeção desenhada como série comum |

- **Desenho:** traço 6/6 (Rails) ou 6/5 (Flutter), largura igual à da linha, sem pontos, com um ponto só no fim. Cor: a
  da projeção ou, sem ela, a da `line` (o traço é o que diferencia). Aparece com um esmaecer depois das barras (nada com
  "reduzir movimento").
- **Onde começa:** `projection_from:`/`projectionFrom:` ignora os valores antes do índice (a lista pode vir inteira).
  No Rails, `nil` num valor também é "sem ponto". Para a linha real **parar** onde a projeção começa, passe `nil` depois
  de hoje (Rails) ou só os valores até hoje (Flutter: a lista da `line` mais curta).
- **Legenda, dica e leitor de tela:** entra na legenda com um traço tracejado; na dica do grupo (`<title>`) e no balão
  do Flutter quando o grupo tem ponto; na tabela para leitor de tela (coluna própria, "—" onde não há ponto) e no
  resumo do `Semantics` do Flutter ("Projeção R$ …"). A faixa do eixo inclui a projeção.

```ruby
render Ss::BarChartComponent.new(title: "Fluxo do mês", labels: dias, series: [...],
  line: { name: "Saldo acumulado", values: real_ate_hoje_e_nil_depois, tone: :accent },
  projection: { name: "Projeção", values: projetado }, projection_from: Date.current.day - 1)
```
```dart
SsBarChart(labels: dias, series: [...], line: SsSeries(realAteHoje, name: 'Saldo'),
    projection: SsSeries(projetado, name: 'Projeção'), projectionFrom: hoje)
```

**Padrões que mudaram.** Nenhum.

## v0.20.1: botão sem `expand` do tamanho do texto

Correção do Flutter achada pelo meu-gestor-app: `SsButton(expand: false)` (e os construtores que já nascem sem `expand`)
dentro de `Wrap`, `Align` ou `Row` sem limite esticava até a largura toda, porque o `Center` interno não tinha
`widthFactor`. Agora fica do tamanho do conteúdo. Quem envolveu o botão em `IntrinsicWidth` para contornar pode tirar.

**Padrões que mudaram.** Botão sem `expand` num pai sem limite de largura deixa de ocupar a linha inteira. Nada no Rails.

## v0.20.0: tabela com coluna parada, linha-link e total, máscara, rádio, rótulo escondido, barra com resumo, linhas repetíveis, ação ao lado da busca, palco de nós, termos e o que mais o minhas-vendas e o meu-gestor pediram

O que o minhas-vendas (web e app) e o meu-gestor (web e app) acharam ao migrar para 100% de componentização. Tudo
aditivo (parâmetro novo opcional; a API não quebra). Catálogo: `flutter/test/catalogo_v20.dart` (`ss-radio-group`,
`ss-sticky-action-bar`, `ss-repeater`, `ss-link-text`, `ss-terms-notice`, `ss-editable-value` novos; estados `mascara`
no `ss-text-field`, `ghost-perigo` no `ss-button`, `tons` no `ss-list-item`, `tom` no `ss-kpi-card`, `total` e
`coluna-parada` no `ss-data-table`, `acao` no `ss-picker`, `contagem` no `ss-nav-bar`) e `rails/catalogo/index.html`
(seções de `rails/sample/script/catalogo_v020.rb`: `ss-data-table-v20`, `ss-form-v20`, `ss-button-v20`, `ss-list-item`,
`ss-kpi-tone-v20`, `ss-sticky-bar-v20`, `ss-repeater`, `ss-search-action-v20`, `ss-link-v20`, `ss-editable-value`,
`ss-node-canvas`); vitrine Rails "Vendas e gestor (v0.20)" (grupo Tela); testes em `flutter/test/v20_test.dart` e
`rails/sample/test/components/v20_web_test.rb`. CSS em `v20_web.css`; Stimulus novos `ss-mask` e `ss-repeater`.

| Peça | Flutter | Rails / CSS | No lugar de |
|---|---|---|---|
| Rótulo só para o leitor de tela | `SsTextField(hideLabel: true)`, `SsRadioGroup(hideLabel:)` | `hide_label: true` em todo `f.ss_*` (texto, select, rádio, caixa) → `.ss-sr` | rótulo apagado com CSS do produto, `<label class="sr-only">` à mão |
| Máscara brasileira | `SsTextField(mask: SsMask.document \| SsMask.phone \| SsMask.cep)`; `SsMask` é um `TextInputFormatter` com `format`/`unmask`/`maxLength`/`keyboardType` | `f.ss_text_field(mask: :document \| :phone \| :cep)` (também no `ss_telephone_field`) + Stimulus `ss-mask` (`inputmode`, `autocomplete`, `maxlength`) | máscara JS do produto, `mask_controller.js`, formatador próprio no app |
| Rádio marcado sem model | `SsRadioGroup<T>(label:, value:, options: {valor: texto}, onChanged:, inline: true, validator:, helperText:)` (novo; `Radio` é reprovado no verificador) | `f.ss_radio_buttons(:tipo, opções, checked: "pj")` | `radio_button_tag` à mão, `Radio`/`RadioListTile` |
| Caixa com id próprio | — | `f.ss_check_box(:ativo, id: "ativo-3")`: o `for=` do rótulo agora usa o `id:` (antes ia no `field_id`, **correção**) | rótulo que não marcava a caixa |
| Botão discreto de perigo | `SsButton.ghost(label:, tone: SsTone.danger)` ou `SsButton(variant: SsButtonVariant.ghost, tone:)` | `Ss::ButtonComponent(variant: :ghost, tone: :danger)` (e `:outline`) → `.ss-btn-ghost.is-danger` (o `is-danger` já saía; faltava o CSS) | ghost com cor do produto |
| Lista de arrastar fora do kanban | `SsReorderableList` (já existia, v0.10.2) | `Ss::SortableListComponent` + `ss-sortable` (já existia; `.ss-sortable-item.is-dragging`) | — (já cobre; ver "O que já existia") |
| Linha apagada | `SsListItem(dimmed:)` (já existia) e `SsDataRow(dimmed: true)` (novo) | `.is-dimmed` no `.ss-item`, `tr` da `.ss-table`, `.ss-sortable-item`, `.ss-kanban-card`, `.ss-row`; `Ss::ListItemComponent(dimmed:)`; na tabela, `row_attrs: ->(r) { { class: ("is-dimmed" if r.inativo?) } }` | `opacity-50` do Tailwind solto |
| Item de lista | `SsListItem` (já existia) + `subtitleTone:`, `valueTone:` (`SsTone`) | `Ss::ListItemComponent(title:, subtitle:, subtitle_tone:, value:, value_caption:, value_tone:, icon:, tone:, href:, dimmed:, money:)` (novo; o `.ss-item` como componente) + bloco no fim · `.ss-item-sub[data-tone]`, `.ss-item-value[data-tone]` | `.ss-item` montado à mão, `text-danger` no subtítulo |
| Valor do indicador em tom | `SsKpiCard(valueTone: SsTone.danger)` | `Ss::KpiCardComponent(value_tone: :danger \| :success \| :warning \| :accent)` → `.ss-kpi-card-value[data-tone]` | `valueColor` à mão, classe de cor no valor |
| Sobrelinha no cabeçalho do card | `SsCardHeader(eyebrow:, eyebrowTone:)` | `Ss::CardHeaderComponent(eyebrow:, eyebrow_tone:)` → `.ss-card-eyebrow` | `Text(kind.toUpperCase(), style: ...)` em cima do título |
| Barra fixa com resumo | `SsStickyActionBar(summary: Widget, message:, actions: [...], visible:)` (novo; fio no topo, superfície, área segura, densidade, desce e some com `visible: false`) | `Ss::StickyActionBarComponent` + slot `with_summary { … }` (no lugar da mensagem, região viva) · `.ss-sticky-bar-summary` | barra de baixo montada com `Container`, `.ss-sticky-bar-msg` com HTML |
| Tabela: 1ª coluna parada | `SsDataTable(stickyFirstColumn: true, minColumnWidth: 120)` (rola de lado só quando as colunas não cabem) | `t.column(:cliente, "Cliente", sticky: true)` (só a 1ª coluna de dados) → `th/td.is-sticky` | `position: sticky` no CSS do produto |
| Tabela: cabeçalho com HTML | `SsDataColumn(label, header: Widget)` (o `label` segue no leitor e nos cartões) | `t.column(..., header: "<b>…</b>".html_safe)` (o `label` segue no celular e na escolha de colunas) | `<th>` à mão |
| Tabela: linha clicável | `SsDataRow(cells, onTap:)` (já existia) | `Ss::DataTableComponent(row_href: ->(row) { pedido_path(row) })` → `tr.is-link[data-href][tabindex=0]` + `ss-table#go` (clique fora de `a`, `button`, campo, `summary`, `details`, `label`, `[role=button]`, `[data-ss-table-no-link]` e sem texto selecionado; Enter com o foco na linha; Ctrl/⌘ ou o botão do meio abrem em outra aba; Turbo quando houver) | `onclick` na `<tr>`, controller `row_link` do produto |
| Tabela: total | `SsDataTable(footer: [Text('Total'), Text('R\$ 15,00'), ...])` (uma célula por coluna; no celular, bloco no fim) | `t.total(:valor, ss_amount(...))` ou `t.total(:valor) { \|rows\| ... }` (a 1ª coluna sem total recebe "Total"; `t.total(:cliente, "Geral")` troca) e `t.footer { \|rows\| ... }` (célula única) → `<tfoot>` | `<tfoot>` à mão abaixo da tabela, linha de total como linha de dado |
| Tabela sem card | `SsDataTable(flat: true)` | `Ss::DataTableComponent(flat: true)` → `.ss-dt.is-flat` (sem `.ss-card` no rolo) | card dentro de card |
| Ação ao lado da busca | `showSsPicker(actions: [SsPickerAction(icon:, tooltip:, onPressed: (ctx) => ...)])`: devolve um item para fechar com ele, ou nulo para continuar aberto | `Ss::CommandPaletteComponent` e `Ss::ComboboxComponent` com `with_action { … }` (vários) → `.ss-command-bar`/`.ss-command-actions`, `.ss-combobox-row`/`.ss-combobox-actions`; `data-action="ss-command#close"` fecha a paleta | ícone de leitor posicionado à mão sobre a busca |
| Linhas repetíveis | `SsRepeater(itemCount:, itemBuilder:, onAdd:, onRemove:, minItems:, addLabel:, removeLabel:)` | `Ss::RepeaterComponent(add_label:, remove_label:, min:, placeholder: "NEW_RECORD", label:)` com `r.row { … }` e `r.with_template { … }` + Stimulus `ss-repeater` (clona o `<template>` trocando o marcador; linha salva ganha `_destroy=1` e some; eventos `ss-repeater:add/remove`) | `nested_form_controller.js`, lista + botão montados no app |
| Valor fora do "esconder valores" | `SsPrivacyScope(hidden: false, child: ...)` (já funcionava: o escopo mais perto vale) | `data-ss-privacy="off"` num contêiner: nada lá dentro borra | `filter: none` no CSS do produto |
| Item externo no menu | — | `AppShellComponent` item `{ label:, href:, external: true }` → `target=_blank rel=noopener`, ícone de saída (`.ss-shell-ext`) e "(abre em outra aba)" para o leitor | link externo à mão fora da moldura |
| Contagem na aba de baixo | `SsNavItem(icon, label, badge: 3)` (0 some, > 99 vira "99+"; lido "Cards: 3 novas, aba 2 de 4") | `badge:` do item do `AppShellComponent` (já existia) | `Badge` do Material em volta do ícone |
| Link no meio do texto | `SsLinkText(['Li os ', SsTextLink('termos', onTap: ..., external: true), '.'])` (os reconhecedores são do widget) | `Ss::TextLinkComponent(label:, href:, external:)` → `a.ss-link` | `WidgetSpan` + `SsPressable`, `<a>` com classe de cor |
| Aviso de termos | `SsTermsNotice(termsUrl:, privacyUrl:, onOpen: (url) => ..., text:)` | `Ss::TermsNoticeComponent(terms_url:, privacy_url:, text:, align:)` → `.ss-terms-notice` | a frase "Ao criar a conta você concorda…" montada no login |
| Valor editável ao toque | `SsEditableValue(label:, value:, onEdit:, mono: true, editLabel:, alignment:)` | `Ss::EditableValueComponent(label:, value:, href:, mono:, edit_label:, align:)` (sem `href`, `<button>` com o `data-action` do app) → `.ss-editable-value` | `InkWell` com rótulo/valor/"editar" no app |
| Editor de nós (fluxograma) | — (só web; o app do gestor não edita fluxo) | `Ss::NodeCanvasComponent(label:, height:, grid: true, readonly:, node_delete: true, sketch:)` + bloco por cima · `.ss-node-canvas` (pele do Drawflow: grade, `.drawflow-node`, portas, `.is-branch`/`.is-condition` com saída 1 verde e 2 vermelha, `.connection.is-yes/.is-no`, `.ss-node-label`, `.drawflow-delete`, `.selected`, `.is-changed`, `.is-refused`/`.is-flash`, `.is-sketch`) e `.ss-node` (caixa padrão do bloco) | o CSS do Drawflow no `application.css` do meu-gestor |
| Entrar com o Google (GIS) | `SsGoogleButton` (já cobre) | `Ss::GoogleButtonComponent(mode: :gis, client_id:, login_uri: \| callback:, theme:, text:, width:, locale:, one_tap:, script:)` → `g_id_onload` + `g_id_signin` com os `data-*` do Google, pílula centrada (`.ss-google-gis`) | `<div id="g_id_onload">` à mão |

**Palco de nós no meu-gestor.** O CSS das linhas ~9–34 do `application.css` sai inteiro. No markup:
`render(Ss::NodeCanvasComponent.new(label: "Desenho do fluxo", sketch: true, node_delete: false, data: { canvas_target: "stage" }))`
(o palco já nasce com `parent-drawflow` na frente; o `canvas_controller.js` pode parar de prefixar a classe). Troque
`is-condition` por `is-branch` quando quiser (os dois valem), `[data-node]` não precisa de classe (os estados valem para o
filho do `.drawflow_content_node`), o rótulo da seta vira `<text class="ss-node-label">` no lugar das utilidades
`fill-muted stroke-surface …`, e `mg-glow`/`mg-shake` viram os `ss-node-glow`/`ss-node-shake` da gem (`.is-changed`,
`.is-refused`, `.is-flash` iguais).

**Máscara.** CPF `000.000.000-00` até 11 caracteres; com 12 ou mais, ou com letra, CNPJ `00.000.000/0000-00` (o CNPJ
alfanumérico entra: letras em maiúscula nas 12 primeiras posições, dígitos nas 2 últimas). Telefone `(00) 0000-0000`
e, com 11 dígitos, `(00) 00000-0000`. CEP `00000-000`. O valor vai formatado; tire a pontuação no servidor (ou
`SsMask.document.unmask(texto)` no app). O teclado é numérico; para digitar letra do CNPJ alfanumérico no celular passe
`keyboardType: TextInputType.text` (app) ou `inputmode: "text"` (web).

**O que já existia (use assim).**

- Lista de arrastar fora do kanban: `Ss::SortableListComponent.new(url:, label:) { |l| l.with_item(id:, title:) { … } }`
  com o Stimulus `ss-sortable` (alça, ↑/↓, `.is-dragging`, PATCH `{ ids: [...] }`) ↔ `SsReorderableList` (v0.10.2).
- Linha clicável no app: `SsDataRow(cells, onTap: () => ...)`.
- Linha apagada no app: `SsListItem(dimmed: true)`.
- Privacidade desligada num trecho do app: `SsPrivacyScope(hidden: false, child: ...)` dentro do escopo do app.
- Contagem no menu do web: `badge:` do item do `Ss::AppShellComponent`.
- Login Google no app: `SsGoogleButton`.

**O que ficou de fora.** `SsNodeCanvas` no Flutter: o app do meu-gestor não tem editor de fluxo (só o web desenha);
nasce quando um app precisar. `Ss::NavBarComponent` no web: a navegação de baixo do web é a do `AppShellComponent`
(que já tem `badge:`). Coluna parada além da 1ª (ou com `selectable:`/expansão na frente): a caixa e a seta rolam.

**Textos novos (pt, en, es):** Flutter `SsStrings.addRow`, `removeRow`, `editValue`, `termsNotice`, `termsOfUse`,
`privacyPolicy`, `opensExternal`; Rails `componentes_ui.app_shell.external`, `data_table.total`, `node_canvas.label`,
`repeater.add/remove/added/removed`, `terms_notice.text/terms/privacy`.

**Padrões que mudaram.** Nenhum desenho existente mudou. Correção: `f.ss_check_box(id:)` passa a ligar o rótulo ao
`id:` dado (antes o `for=` apontava para o id padrão e o clique no texto não marcava a caixa). O `ss-command` ganhou a
ação `close`. `Ss::GoogleButtonComponent` aceita `href:` nulo só com `mode: :gis` (sem `href:` no modo padrão, avisa).

## v0.19.2: herói com conteúdo livre, botão sobre o gradiente, faixa e contorno no card, monograma, foto escolhida, selo sólido, passos, ponto, recado, palco e indicador de página

As últimas caixas genéricas que o minhas-compras-app e o minhas-viagens-app ainda desenhavam à mão (o verificador
já dava 0 nos dois; estas eram peça genérica reinventada, a seção (c) das tabelas de classificação dos dois apps). Tudo
aditivo (parâmetro novo opcional; a API não quebra). Catálogo: `flutter/test/catalogo_v192.dart` (`ss-monogram`,
`ss-dot`, `ss-quote`, `ss-illustration-stage`, `ss-page-dots` novos; estados `livre`/`toque` no `ss-hero`,
`sobre-gradiente` no `ss-button`, `faixa`/`contorno` no `ss-card`, `solido` no `ss-badge`, `destino` no
`ss-photo-card`, `passos` no `ss-prose`, `ponto` no `ss-section`, `escuro` no `ss-glass`, `estado` no
`ss-deal-badge`) e `rails/catalogo/index.html` (`ss-card-v192`, `ss-button-v192`, `ss-badge-v192`, `ss-steps-v192`,
`ss-dot-v192`, `ss-quote-v192`, `ss-glass-v192`, `ss-photo-v192`); testes em `flutter/test/v192_test.dart`,
`rails/test/helpers_test.rb` e `rails/sample/test/components/v19_2_web_test.rb`. CSS em `v19_2_web.css`.

| Peça | Flutter | Rails / CSS | No lugar de |
|---|---|---|---|
| Herói com conteúdo livre | `SsHeroCard.custom(child:, background:, padding:, radius:, shadow: true, onTap:, semanticLabel:)`: gradiente da marca na diagonal (`brandFrom → brandTo → brandDeep`), texto e ícone já claros, `background` atrás do conteúdo (desenho com `Positioned`), recortado pelo raio | `.ss-hero` com qualquer conteúdo (já existia) | viagens `today_screen.dart:227` ("Para onde vamos?"), `auth/auth_hero.dart:17` (login, `radius: AppRadius.sheet`), `wishes/wish_detail_screen.dart:455` (faixa da rota, `shadow: false`); compras `scan/scan_sheet.dart:133` ("Foto do cupom", `onTap:`, `radius: AppRadius.cardActive`) |
| Botão sobre o gradiente | `SsButton.onGradient(label:, icon:, onPressed:, solid: false, stacked: false, small:, expand:, loading:)`: translúcido com fio claro ou, com `solid`, branco com o texto em `brandDeep`; `stacked` (também no `SsButton` comum) põe o ícone em cima e o rótulo encolhe numa linha | `ButtonComponent(variant: :on_grad, solid: true, stacked: true)` → `.ss-btn.is-on-grad.is-solid.is-stacked` | viagens `today_screen.dart:284` (os três atalhos brancos Voo/Pacote/Hospedagem: `SsButton.onGradient(label: w.title, icon: w.icon, solid: true, stacked: true, ...)` em `Expanded`) |
| Faixa na borda do card | `SsCard(stripe: Color)`: 5 px (`SsCard.stripeWidth`) por dentro do raio, o `padding` conta a partir dela | `.ss-card.has-stripe` + `--ss-card-stripe` (com `.ss-card-pad`, o respiro conta a partir da faixa) | compras `home/home_screen.dart:458`, `insights/recalls_screen.dart:75`, `wishes/advice_card.dart:58` (`SsCard(padding: zero)` + `ClipRRect` + `Positioned` de 5 px) |
| Contorno no tom | `SsCard(outline: Color)`: 2 px, sem trocar fundo nem sombra (o `active:` ganha dele) | `.ss-card.has-outline` + `--ss-card-outline` | viagens `wishes/wish_widgets.dart:387` (no alvo: `outline: AppColors.success`), `trips/trip_tabs.dart:455` (conflito: `outline: AppColors.dangerBorder`) |
| Monograma | `SsMonogram(text, color:, size: 20, circle: false, semanticLabel:)`: sigla clara que encolhe, raio `size/4` ou círculo; `color` é dado (`ssColorFromHex`), sem ela a marca do produto | `ss_monogram(text, color: "#2D3277", size: 20, circle:, label:)` → `.ss-monogram` (hex validado, inline em `--ss-mono`) | viagens `wishes/wish_widgets.dart:149` (`SiteIcon`, quadrado); compras `wishes/store_widgets.dart:57` (`StoreIcon`, `circle: true`); o mapa de cores continua no app |
| Card de foto escolhido | `SsPhotoCard(subtitle:, credit:, onCredit:, selected:, expand:)`: o título cresce com `subtitle`, crédito no canto (tocável, dica `photoSource`), contorno `accentBright` e ✓, `expand` ocupa a altura recebida (no `PageView`) | `PhotoCardComponent(subtitle:, credit:, credit_url:, selected:)` → `.has-subtitle`, `.ss-photo-credit`, `.is-selected[aria-current=true]` | viagens `wishes/destination_carousel.dart:65–91` (`DestinationCard` + `_Credit`) |
| Selo sólido e em mono | `SsBadge(solid: true, mono: true)`: fundo cheio no tom e texto claro (`accent` → `accentSolid`; success/warning/danger escurecidos até 4,5:1; `muted`/`ghost` invertidos: fundo `ink`, texto `surface`); `mono` em DM Mono | `.ss-badge.is-solid` (com `ss-badge-accent/-success/-danger/-warn`) e `.is-mono` | viagens `core/domain_ui/mv_itinerary.dart:54` ("DIA 3"/"ANTES": `SsBadge(..., variant: today ? accent : muted, solid: true, mono: true)`) |
| Passos numerados | `SsProseList(items, ordered: true, start: 1)`: número em DM Mono num círculo `accentSoft`; o leitor lê "1. texto" | `<ol class="ss-steps">` ou `.ss-prose ol.is-steps` | compras `insights/recipes_screen.dart:232`, `more/background_screen.dart:258`; viagens `more/price_network_screen.dart:271` |
| Ponto | `SsDot(color:, size: 8, ring:, semanticLabel:)` e `SsIconBubble(icon, badge: Color, badgeLabel:)` (ponto no canto com anel na cor da superfície) | `.ss-dot` (`--ss-dot`, `--ss-dot-size`, `.is-ring`; dê `role="img"` + `aria-label`) | compras `more/finance_link_card.dart:90` (`SsIconBubble(..., badge: statusColor, badgeLabel: status)`), `notifications/notifications_screen.dart:131` (`SsDot(size: 10, semanticLabel: 'não lida')`) |
| Recado de outra pessoa | `SsQuote(text, author:, quoted: true)`: balão no fundo do campo, canto de cima à esquerda reto, itálico entre aspas | `<blockquote class="ss-quote"><p>…</p><cite>…</cite></blockquote>` | compras `more/offers_screen.dart:170` (recado da doação/troca) |
| Palco da ilustração | `SsIllustrationStage(child:, height: 112, padding:)`: degradê `accentSoft → page`, raio de folha, a arte encolhe na altura | — (só app) | compras `onboarding/onboarding_screen.dart:111` |
| Indicador de página | `SsPageDots(count:, index:, size: 8, alignment:)` (o do `SsOnboarding`, agora público e usado por ele); lê "Página 2 de 3" | `.ss-dots` com `aria-current` (já existia no `.ss-onboarding`) | compras `onboarding/onboarding_screen.dart:158` (os passos têm formulário e só avançam ao salvar: `SsPageDots(count: 3, index: _page, size: 6, alignment: MainAxisAlignment.start)`) |
| Vidro escuro | `SsGlass(tone: SsGlassTone.dark)`: véu `sheetBg` a 55/63/74% por `level`, texto e ícone claros | `.ss-glass.is-dark` | compras `scan/scanner_screen.dart:115` (dica sobre a câmera) |
| Chip de loja com estado | `SsSourceChip(name, favicon:, trailing: Widget, semanticLabel:)`: `trailing` depois do nome (ícone 14 no `muted` se não tiver cor própria) | — (só app; o `.ss-source` do web é outra peça) | compras `wishes/wish_search.dart:151` (`_StoreStateChip`: `SsSourceChip(s.name, favicon: StoreIcon(...), trailing: Icon(look.icon, color: look.color))` dentro do `SsTooltip`) |

**O que não virou peça.**

- **`SsChatBubble(author:)`**: o recado da oferta (compras `offers_screen.dart:170`) não é conversa. O `SsChatBubble` é a
  conversa com a IA (entra com mola, se alinha pelo remetente, ✦ da IA, largura de 78% da tela) e o assistente do compras
  já o usa (`assistant_screen.dart:294`). O recado parado dentro de um card virou o `SsQuote`.
- **`SsCard(unread:)`**: o ponto solto resolve com o `SsDot`; o card da notificação do compras é uma linha do tempo com
  selo de oferta, que não cabe no `SsNoticeCard` (o viagens já usa o `SsNoticeCard(unread:)`).
- **`SsOnboarding(showNext: false, controller:)`**: o indicador saiu como `SsPageDots` e o palco como `SsIllustrationStage`;
  a tela do onboarding com formulário continua do app, montada com eles.
- **`SsBadge(variant: SsBadgeVariant.solid / inverse)`**: virou `solid: true` sobre a variante (sem valor novo no enum,
  que quebraria um `switch` exaustivo).
- **`SsCard(outline: SsTone)`**: `outline` e `stripe` recebem `Color` (o compras pinta a faixa com cores dele, `freshUrgent`,
  `aquecText`); para um tom, `SsTone.success.colors(context).solid`.

**Textos novos (pt, en, es):** `SsStrings.photoSource` ↔ `componentes_ui.photo_card.source` ("Abrir a página da foto").

**Padrões que mudaram.** Nenhum desenho de peça existente mudou. O `SsOnboarding` passa a desenhar os pontos com o
`SsPageDots` (mesmos tamanhos e cores). O `SsPhotoCard` passa a ser um nó só para o leitor de tela (título, subtítulo e
selo no rótulo; antes o título era lido duas vezes).

## v0.19.1: conteúdo das abas, dica ao segurar, fio em pé, menu com logo, tela cheia, cor de dado e card à mão no verificador

O que o minhas-compras-app e o minhas-viagens-app ainda montavam com peça crua do Material, cor literal ou número solto
no estilo de texto, para os dois passarem no `conferirConformidade` sem exceção. Tudo aditivo (parâmetro novo opcional;
a API não quebra). Catálogo: `flutter/test/catalogo_v191.dart` (`ss-tabs-view`, `ss-tooltip`, `ss-fullscreen` novos;
estados `empilhada` no `ss-tabs-underline`, `vertical` no `ss-divider`, `ancora` no `ss-overflow-menu`) e
`rails/catalogo/index.html` (`ss-divider-vertical`); testes em `flutter/test/v191_test.dart`,
`flutter/test/conformidade_test.dart` e `rails/sample/test/conformidade_test.rb`.

| Peça | Flutter | Rails / CSS | No lugar de |
|---|---|---|---|
| Conteúdo das abas | `SsTabsView(controller:, children:, swipe: true)` (sem `controller`, o `DefaultTabController`) | `Ss::TabsComponent` com painéis (já existia) | `TabBarView` |
| Aba com ícone em cima | `SsTabsUnderline(stacked: true, icons: [...])`: ícone em cima do nome, divide a largura e nunca rola (o nome encolhe; 5 abas cabem em 360 px); altura em `SsTabsUnderline.stackedHeight(context)` (60/66/70) | — (só app) | `TabBar(tabs: [Tab(icon:, child:)])` dentro do `SsSliverHeader(bottom:)` |
| Dica ao segurar / passar o mouse | `SsTooltip(message:, child:, below: false)` | `Ss::TooltipComponent` (já existia; mesmo nome) | `Tooltip` |
| Fio em pé | `SsDivider.vertical(width: 1, indent: 0)` ou `SsDivider(vertical: true, height:)` | `<hr class="ss-divider is-vertical" aria-orientation="vertical">` | `VerticalDivider` |
| Item de menu com logo | `SsMenuAction(icon, label, onTap, leading: Widget)` + `SsOverflowMenu(items:, tooltip:, child: Widget)` (âncora própria) | `PopoverComponent` + `ButtonComponent(variant: :item)` com o bloco (já cobre) | `PopupMenuButton` + `PopupMenuItem(child: Row(logo, texto))` |
| Tela cheia | `showSsFullscreen<T>(context, title:, child:, actions:, dismissOnTap: false, useRootNavigator: true)`; a tela `SsFullscreenPage` é pública | — (só app) | `showDialog(builder: (_) => Dialog.fullscreen(...))` |
| Transparente | `AppColors.transparent` | `transparent` do CSS | `Colors.transparent` |
| Entrelinha e espaço entre letras | `AppType.solid` (1), `AppType.tight` (1,2), `AppType.snug` (1,3), `AppType.trackingTight` (0,5), `AppType.trackingTitle` (−0,3), além dos da v0.19 (`leading` 1,4, `trackingCaps` 0,8, `trackingWide` 1,4) | — (só app) | `height: 1.2`, `letterSpacing: 1` soltos |
| Cor que é dado | `ssColorFromHex('#E43225')` (`#RGB`, `#RRGGBB`, `#RRGGBBAA`; lança `FormatException`), `ssTryColorFromHex(String?)` (nulo se não for cor), `ssColorFromRgb(0x3A6EA5)` | variável inline com o hex validado (como o `WalletCardComponent(colors:)`) | `Color(0xFF000000 \| v)`, `Color(0xFFE43225)` num mapa |
| Glifo de ícone no canvas | `ssIconTextStyle(icon, size:, color:)` e `ssPaintIcon(canvas, icon, center, size:, color:, angle:)` | — (só app) | `TextStyle(fontFamily: icon.fontFamily, package: icon.fontPackage, fontSize: 20)` |

**Cor que é dado.** `ssColorFromHex`/`ssColorFromRgb` são **o** jeito de pintar uma cor que não é estilo, é dado: a que
vem da API (cor média da foto do destino, `color` do JSON) ou a cor de marca de um terceiro guardada no app como dado
(monograma das lojas e dos sites de viagem: o mapa vira `'amazon': ('a', '#232F3E')` e a tela chama
`ssColorFromHex(hex)`; decisão do usuário em 10/11/2026: a cor de marca das lojas fica no app, sem API). O verificador
não reprova essas chamadas. Cor de **estilo** (fundo, texto, borda) continua só por token (`SsColors.of(context)`,
`AppColors`, o `SsBrand`): usar o helper para escrever a cor da tela é burlar a régua.

**SsTabsView.** Mesmo `TabController` do `SsTabsUnderline` (`index: _tabs.index, onChanged: _tabs.animateTo`, com o
`setState`/`ListenableBuilder` no controlador): o toque na aba desliza a página e arrastar troca a aba. `swipe: false`
desliga o arrastar (aba com mapa). Uma `PageStorageKey` por filho guarda a rolagem de cada aba.

**SsTabsUnderline(stacked:).** Para as 5 abas do detalhe da viagem dentro do `SsSliverHeader`:
`bottom: SsTabsUnderline(stacked: true, tabs:, icons:, index:, onChanged:)` e
`bottomHeight: SsTabsUnderline.stackedHeight(context)`. Ícone 20 em cima, nome 12 (800 na escolhida) que encolhe
(sem reticências); o traço que viaja é o mesmo.

**SsTooltip.** Aparece ao segurar (toque) ou com o mouse/foco por 250 ms, em cima do filho (`below: true`, embaixo);
claro: fundo de tinta e texto branco; escuro: o fundo do campo com borda; 12/600, raio 8, sombra do card. O leitor
de tela lê a mensagem junto do filho. Não é o `SsTip` (a dica dispensável com ×). Botão de ícone continua com o
`SsIconButton(tooltip:)`.

**SsMenuAction(leading:) e SsOverflowMenu(child:).** `leading` vai numa caixa do tamanho do ícone da densidade (o
`icon` fica para o atalho de uma ação só). Com `child` (ex. "↗ No app" em texto), o menu abre mesmo com uma ação e
o `tooltip` é o nome da âncora. "Buscar no app da loja":
`SsOverflowMenu(tooltip: 'Buscar no app da loja', child: ..., items: [SsMenuAction(Icons.storefront, 'Buscar no app da Shopee', () => ..., leading: StoreIcon(store: 'shopee', name: 'Shopee', size: 18))])`.

**showSsFullscreen.** Rota por cima de tudo, sobe com fade (sem animação com "reduzir movimento"); barra com × (`SsStrings.close`),
`title` e `actions`; `dismissOnTap: true` fecha com um toque em qualquer lugar e o leitor diz "Toque para fechar".

**Entrelinha e espaço entre letras: o mapa dos valores dos apps** (arredonde para o token mais próximo; a diferença
não aparece no desenho):

| Valor solto | Token |
|---|---|
| `height: 1` | `AppType.solid` |
| `height: 1.1`, `1.2` | `AppType.tight` (1,2) |
| `height: 1.3` | `AppType.snug` (1,3) |
| `height: 1.35`, `1.4` | `AppType.leading` (1,4) |
| `letterSpacing: .3`, `.5`, `.6` | `AppType.trackingTight` (0,5) |
| `letterSpacing: .8`, `1` | `AppType.trackingCaps` (0,8) |
| `letterSpacing: 1.2`, `1.5`, `1.6` | `AppType.trackingWide` (1,4) |
| `letterSpacing: -0.4` (título grande) | `AppType.trackingTitle` (−0,3) |
| `fontSize: 10` / `11` / `14` / `20` / `34` | `AppType.micro` / `label` / `set` / `headerTitle` / `statNum` (já existiam) |

**Verificador: card à mão (regra nova, ligada para todos).** `conferirConformidade` reprova `card-à-mão:SsCard`: um
`BoxDecoration` com a cor `surface` pura (`c.surface`, `SsColors.of(context).surface`) e a sombra de card
(`AppShadows.card`, ou qualquer `boxShadow:` com o raio `AppRadius.card`/`cardActive`), que é o `SsCard` (ou
`SsCard(soft:)`, `SsCard(active:)`, `SsCard(tint:)`). Para não pegar desenho de domínio fica de fora: decoração com
`gradient:`, `image:` ou `shape:`, cor que não é a `surface` pura (papel do cupom, `surface.withValues(...)`,
ternário), `ShapeDecoration` e sombra sem raio de card (barra de baixo). No web, `ComponentesUi::Conformidade` reprova
`card-a-mao:ss-card`: no mesmo `class`, `bg-surface`/`bg-[var(--surface)]` + `shadow*` + `rounded*` (é o `.ss-card`).
Achados ao ligar (10/11/2026): meu-financeiro-app (o `main` 100%) **0**, minhas-compras-app 8, minhas-viagens-app 2,
minha-automacao-app 0, meu-gestor-app 0, meu-personal-app 0, meu-cultivo-app 0, minhas-vendas-app 0; no web, 0
em todos (meu-financeiro 100%, compras, viagens, automação, gestor, personal, vendas). Como ninguém que já estava verde quebra, a regra não tem parâmetro para desligar.

**Verificador: chamada com tipo.** `showDialog<void>(`, `PopupMenuButton<String>(`, `SegmentedButton<int>(` passavam
pelo verificador (o tipo entre o nome e o parêntese); agora reprovam como sem o tipo. No meu-financeiro-app: 0 achados.

**Textos novos (pt, en, es):** `SsStrings.tapToClose` ("Toque para fechar").

**Padrões que mudaram.** Nenhum desenho mudou; o verificador ficou mais rígido (card à mão e chamada com tipo).

## v0.19.0: botão como componente, entrar com o Google, cartão físico, arquivo e cor no formulário (web 100% do meu-financeiro)

O que o Meu Financeiro (web) ainda escrevia à mão (`<button>`, `button_to` com classe, `<input type=file|color>`, o "G" do
Google com hex, o cartão de crédito em CSS próprio) para chegar a 100% no componentes-ui, com um teste de conformidade que
não aceita exceção. Só o lado Rails; tudo aditivo (a API não quebra). Vitrine "Financeiro (v0.19)" (grupo Tela); catálogo
em `rails/catalogo/index.html` (seções de `rails/sample/script/catalogo_v019.rb`); testes `v19_web_test.rb`.

| Peça | Flutter | Rails / CSS | No lugar de |
|---|---|---|---|
| Botão | `SsButton` (já cobre) | `Ss::ButtonComponent(label:, icon:, trailing_icon:, href:, method:, variant: :primary/:outline/:ghost/:danger/:on_grad/:chip/:item, size: :sm, block:, type: :submit, confirm:, confirm_tone:, confirm_button:, params:, form:, submitting:, tone: :danger)` (+ bloco) · `.ss-btn.is-block`, `.ss-item.is-danger` | `<button class="ss-btn">` à mão, `button_to … class: "ss-btn …"`, `button_tag`, `submit_tag`, `<button class="ss-chip">` |
| Entrar com o Google | `SsGoogleButton` (já existia) | `Ss::GoogleButtonComponent(href:, label:, method: :post)` · `.ss-google-btn` | `devise/shared/_google_button` com o SVG de quatro cores no produto |
| Cartão físico | `SsWalletCard` (já existia) | `Ss::WalletCardComponent(amount:, label:, holder:, holder_label:, number:, network:, expiry:, colors:, href:, tilt:)` (bloco = logo da bandeira) · Stimulus `ss-tilt` · `.ss-wallet-card*` | `.mf-cc` + `tilt_controller.js` do produto |
| Arquivo e cor | `SsImageSourcePicker`, `SsColorPicker` | `f.ss_file_field`, `f.ss_color_field` (o campo inteiro, como os outros `f.ss_*`) | `f.file_field`/`f.color_field` com `class: "ss-input"` |
| Seleção da tabela | — | `DataTableComponent(select_name: "pedido_ids[]", bulk_method: :patch)` | caixas `<input type=checkbox>` à mão com o nome do controller do app |
| Rodapé só com a ação | — | `FormActionsComponent(submit: false)` (a ação vem no bloco, ex. um `ButtonComponent(method: :post)`) | `.ss-dialog-panel-foot` à mão |
| Botão de ícone que envia | — | `IconButtonComponent(type: :submit, form:, name:, value:)` | `<button type="submit" class="…">` com ícone |
| Cor da barra do navegador | — | `ss_theme_color_tag(color = nil, dark: false)` | `<meta name="theme-color" content="#5A45E8">` |
| Barras num card largo | `SsBarChart` (já mede a largura) | `BarChartComponent(width: 1100, label_every:)`: largura do desenho (viewBox) e rótulos do eixo X de N em N quando não cabem (automático) | gráfico de 30 dias com texto gigante no computador e rótulos encostados |

**Ss::ButtonComponent.** Um botão só para os três jeitos de agir: `href:` (link), sem `href:` (`<button type="button">` do JS,
ou `type: :submit` com `name:`/`value:`/`form:`/`formaction:`) e `href:` + `method: :post/:patch/:put/:delete` (o `button_to`,
com o `confirm:` no `<form>`, onde o Turbo lê, `params:` como campos escondidos e `form: {}` no form). `variant: :chip` é a
ficha (`.ss-chip`, "Hoje", "+R$ 10"), `:item` a linha de menu (no popover ⋯; `tone: :danger` pinta de perigo), `:on_grad` o
botão sobre o gradiente. O resto dos atributos (`data:`, `aria:`, `title:`, `id:`, `disabled:`) vai no elemento.

**Ss::WalletCardComponent.** `number:` são só os 4 dígitos finais (sai `•••• •••• •••• 4086`); o valor (`amount:`, já
formatado) é borrado no modo privacidade. `colors:` aceita dois `#rrggbb` (a cor do cartão é dado, vai como variável
inline); o que não for hex é ignorado e fica o gradiente da marca. A inclinação (`ss-tilt`) só liga com mouse de verdade
e sem "reduzir movimento".

**Barras no card largo.** O SVG do `BarChartComponent` ocupa a largura do card e escala junto: com o padrão (560), num
card de 1100 px o texto dobrava. Passe `width:` com a largura de verdade no computador e renderize outro com o padrão no
celular (ex. `css: "hidden md:block"` e `css: "md:hidden"`).

**Padrões que mudaram.** `FormActionsComponent(submit: false)` antes mostrava "Salvar" (o `false` caía no padrão).
`BarChartComponent` com muitos grupos (mais de ~20 no padrão) mostra os rótulos do eixo X de N em N (o ativo sempre
aparece); `label_every: 1` volta a todos. Correções: o rodapé preso do formulário (`.ss-form-actions.is-sticky`) encosta
no fim do diálogo (antes o conteúdo aparecia por baixo dele, no padding do corpo) e a tabela para leitor de tela do
`BarChart`/`AreaChart` fica num `.ss-sr-wrap` recortado (uma `<table>` não encolhe a 1px e empurrava a página para o lado no
celular; o seletor `table.ss-sr` continua valendo).

**Textos novos:** `google.sign_in`, `wallet_card.balance`, `wallet_card.card` (pt-BR, en, es).

### v0.19.0: conformidade (o teste "100% componentes-ui" dos produtos)

Um verificador nos dois lados para o produto rodar num teste próprio: a CI reprova qualquer coisa que tenha peça no
componentes-ui e não use a peça. **Não há lista de exceções**: faltou peça, ela nasce aqui.

- **Rails** (`require "componentes_ui/conformidade"`): `ComponentesUi::Conformidade.verificar(Rails.root)` devolve as
  violações (`regra`, `arquivo`, `linha`, `trecho`) em `app/views`, `app/components`, `app/helpers`, `app/javascript` e
  `app/assets`. Reprova: gem fora de `tag:` (ou por path no lock); `minha_suite_ui`/`Ui::`; classe do DaisyUI; cor da
  paleta do Tailwind e cor literal; `<button>`/`<input>`/`<select>`/`<textarea>`/`<table>`/`<dialog>` crus (até em
  comentário), os helpers que os geram e campo do FormBuilder fora do `ss_*` (`hidden_field` é livre); Chart.js; hover
  do Tailwind 3; CSS além de `@import`/`@source`; JS com classe que não é `ss-*`/`is-*` ou estilo inline.
  ```ruby
  it "o web é 100% componentes_ui" do
    problemas = ComponentesUi::Conformidade.verificar(Rails.root)
    expect(problemas).to be_empty, problemas.join("\n")
  end
  ```
- **Flutter** (`package:componentes_ui/conformidade.dart`): `conferirConformidade(Directory.current)` confere a `lib/`.
  Reprova: o pacote fora de git + `ref:` de tag; widget do Material/Cupertino com par `Ss*` (`AppBar`, botões,
  `AlertDialog`/`showDialog`, `SnackBar`/`ScaffoldMessenger`, `Card`, `ListTile`, `Chip`, `Switch`, `TextField`,
  indicadores de progresso…); cor literal (`Colors.*`, `Color(0x…)`); tipografia literal (`fontSize`/`letterSpacing`
  com número, `fontFamily`, `height`/`wordSpacing` em `TextStyle`); `fl_chart`.
  ```dart
  test('100% componentes_ui', () {
    final problemas = conferirConformidade(Directory.current);
    expect(problemas, isEmpty, reason: problemas.join('\n'));
  });
  ```

### v0.19.0, lado Flutter: imagem em tela cheia, grupo recolhível com subtítulo e espaçamento de texto em token

O que o meu-financeiro-app ainda montava com peça crua do Material ou com número solto no estilo de texto; com isto o
app fica 100% no pacote (zero `AppBar`/`Dialog`/`ExpansionTile`/`Colors.*`/tamanho literal em `lib/`). Tudo aditivo;
a API não quebra. Catálogo: `flutter/test/catalogo_v19.dart` (`ss-image-viewer` novo, estado `subtitulo` no
`ss-collapsible`); testes em `flutter/test/v19_test.dart`.

| Peça | Flutter | No lugar de |
|---|---|---|
| Imagem em tela cheia com zoom | `showSsImageViewer(context, image:, title:, semanticLabel:, actions:, maxScale: 4, useRootNavigator: true)`; a tela `SsImageViewer` é pública | `showDialog(builder: (_) => Dialog(child: InteractiveViewer(child: Image.memory(...))))` (comprovante do lançamento) |
| Grupo recolhível com subtítulo | `SsCollapsible(subtitle:)`: linha apagada embaixo do título, à vista fechado (até 2 linhas) | `Theme(dividerColor: transparent) + ExpansionTile(subtitle:, maintainState: true)` ("Mais opções" do lançamento) |
| Espaçamento de texto | `AppType.leading` (1,4: entrelinha de texto corrido), `AppType.trackingCaps` (0,8: rótulo pequeno em caixa alta), `AppType.trackingWide` (1,4: sobrelinha e dígitos agrupados) | `height: 1.4`, `letterSpacing: .8`/`1.5` soltos no `TextStyle` do produto |

**showSsImageViewer.** Rota por cima de tudo (fade; sem animação com "reduzir movimento"), fundo escuro e a
`SsTopBar(style: dark)` com o × (`SsStrings.close`), o `title` e as `actions` (passe `SsIconButton(color:
AppColors.onDark)`). A imagem fica inteira (`BoxFit.contain`); pinça amplia até `maxScale`, arrastar move, toque duplo
amplia 2,5× no ponto tocado e volta a 1×. O leitor diz o `semanticLabel` (ou o `title`, ou "Imagem") e a dica de zoom;
imagem que não decodifica vira o ícone de imagem quebrada. Bytes da API: `image: MemoryImage(bytes)`.

**SsCollapsible(subtitle:).** Com subtítulo, o título e ele ocupam a linha (a pílula de contagem e o selo vão à
direita). O corpo continua montado fechado (como o `ExpansionTile(maintainState: true)`): campo de formulário lá dentro
guarda o estado e valida.

**Textos novos (pt, en, es):** `SsStrings.image` ("Imagem") e `SsStrings.zoomHint`.

**Padrões que mudaram.** Nenhum.

## v0.18.0: speed dial, diálogo com formulário em frame, ações de linha, rodapé e erros de formulário, combobox com ícone, botão que alterna e o que faltava no app (fase final do meu-financeiro)

O que o Meu Financeiro (web Rails e app Flutter) ainda tinha de genérico por falta de peça aqui; com esta versão os
dois produtos podem ficar 100% no componentes-ui. Tudo aditivo (parâmetro novo sempre opcional); a API não quebra.
Vitrine Rails: "Financeiro (v0.18): speed dial, diálogo, ações de linha" (grupo Tela); catálogo nos dois lados
(`flutter/test/catalogo_v18.dart`; `rails/catalogo/index.html`, seções de `rails/sample/script/catalogo_v018.rb`).

| Peça | Flutter | Rails / CSS | No lugar de |
|---|---|---|---|
| Botão flutuante com várias ações | `SsSpeedDial(actions: [SsSpeedDialAction(label, icon, onPressed, tooltip:)], icon:, openIcon:, label:, tooltip:, extended:, extendedFrom:, onOpenChanged:, useRootNavigator: true)`; `SsFab(iconTurns:)` | `Ss::SpeedDialComponent(items: [{ label:, icon:, href:, turbo_frame:, method:, action:, data:, id: }], label: "Ações rápidas", icon: "plus", position:, lift:, static:, permanent:, id: "ss-speed-dial")` · Stimulus `ss-speed-dial` · `.ss-speed-dial`, `-menu`, `-item`, `-ico`, `-toggle` | `shared/_speed_dial` + `speed_dial_controller.js` + `.mf-speed-dial` (web), `NewTransactionFab` (app) |
| Diálogo com formulário em frame | `showSsSheet` (já cobre) | `Ss::DialogComponent(…, global: true, header: false, clear_on_close:, refresh_on_close:, follow_missing: true)`; `data-ss-dialog-keep-open` no form/botão; `[data-ss-dialog-refresh]` (ou `[data-modal-refresh-on-close]`) na resposta; `[data-ss-dialog-dismiss]` fecha | `modal_controller.js` + `dialog#modal-dialog` do layout |
| Ações de linha (hover no computador, à vista no toque) | — (o app usa deslizar/menu) | `Ss::RowActionsComponent(edit:, destroy:, confirm:, edit_frame: "modal", icons:, reveal: true, method: :delete)` (+ bloco) · `t.actions { \|row\| … }` no DataTable · `.ss-row-actions.is-reveal` | `md:opacity-0 md:group-hover:opacity-100` + `@custom-variant hover`, `mf_row_actions` |
| Tabela | `SsDataTable` (já cobre) | `DataTableComponent(row_attrs: Hash \| ->(row) { { id:, data:, class: } }, empty_art: false)` | `<tr>` à mão com `data-*`, vazio ilustrado numa tabela pequena |
| Resumo de erros | — (o app mostra o erro no campo e no toast) | `Ss::FormErrorsComponent(record:, errors:, title: "Confira os campos", base_only:)` · `.ss-form-errors` | `mf_form_errors` |
| Rodapé do formulário | `SsButtonPair` / `SsButton` (já cobrem) | `Ss::FormActionsComponent(form:, submit: "Salvar", submitting: "Salvando…", cancel: true, cancel_label:, cancel_href:, dialog: true, sticky:, align: :end/:start/:between)` (+ bloco para "Salvar e criar outro") · `.ss-form-actions.is-sticky` | `mf_modal_footer` |
| Combobox com ícone/imagem | `showSsPicker` (já cobre ícone por item) | `ComboboxComponent(options: [{ id:, label:, hint:, icon: "nome", color:, image: url }], input: { title:, data:, aria: })`; a escolhida aparece no campo (`.ss-combobox-lead`) | logo do banco e ícone do perfil que se perderam na migração |
| Popover com atributos no botão | — | `PopoverComponent(trigger_attrs: { title:, data:, aria:, class: })`; com `trigger:`, o `label:` vira também o `title` | `<button popovertarget>` à mão no menu ⋯ da linha |
| Tons | — | `ss_status` aceita `:warn` e `:warning` (sai `data-tone="warning"`; CSS também lê `warn`); Callout, Note, CardHeader, NoticeCard, Collapsible e Block aceitam `:warning` (= `:warn`); `ComponentesUi.tone(t)` normaliza (`warning`→`warn`, `error`→`danger`, `ok`→`success`) | `:warn` virando cinza no `ss_status` e `:warning` virando "info" no Callout |
| Botão de ícone e de alternar | `SsIconButton` (já cobre) | `Ss::IconButtonComponent(icon:, label:, href:, pressed:, pressed_icon:, variant: :ghost/:tonal/:outline/:danger, size:, title:)` · `.ss-icon-btn.is-toggle` + `[aria-pressed]` | `<button class="ss-icon-btn">` à mão |
| Esconder valores (olho) | `SsPrivacyToggle` (já existia) | `Ss::PrivacyToggleComponent(label:, hint:, text:, size:)` (controller `ss-privacy` num ancestral) | `shared/_privacy_button` com `<button>` cru |
| Moldura | — | `AppShellComponent`: a barra de cima sem busca, `top` e `user` some no computador (`.ss-shell-top.is-bare`); `with_top_mobile { … }` só no celular; grupo com `icon:` | faixa vazia no topo do desktop |
| Cores sobre a marca | `SsColors` (já cobre) | Tailwind: `text-on-accent` (e `/80`, `/60`), `bg-on-accent/15`, `ring-on-accent/25`, `bg-accent-solid`, `bg-accent-hover`, `text-info`/`bg-info-soft`, `bg-head`; `bg-grad` (gradiente + texto claro) e `bg-grad-soft`; variável `--on-accent` | `text-white`, `text-white/80`, `bg-white/15`, `.bg-brand-gradient` |
| Campo de dinheiro com controller de fora | `SsMoneyField(controller:, focusNode:, autofocus:, required:, errorText:, calculator: true, onKeypad:, textInputAction:, onSubmitted:)` (`cents`/`onChanged` passam a ser opcionais); `SsMoneyField.parse(texto, formats:)` → centavos | `MoneyInputComponent` (já cobre) | `MoneyField` de `lib/core/ui` (app) |
| Barra de topo de detalhe/formulário | `SsTopBar` (já cobria: `title`, `subtitle` em duas linhas, `titleWidget`, `actions`, `leading`, voltar automático, `onBack`, `bottom`, `centerTitle`, `style:`, `PreferredSizeWidget`) | `Ss::PageComponent` / `TopBarComponent` | `AppBar` cru |
| Aviso sem `BuildContext` (push em segundo plano) | `SsToastHost.navigatorKey = rootKey` + `showSsToastGlobal(msg, icon:, tone:, actionLabel:, onAction:, duration:)` → `bool`, `showSsUndoGlobal(...)` → `Future<bool>` | `Ss::ToastComponent` (já cobre) | `SnackBar` + `appMessengerKey` |
| Botão de texto e carregando | `SsButton.text(label:, icon:, tone:, onPressed:)`, `SsSpinner`, `SsSplash` (já cobriam) | `.ss-btn-ghost`, `.ss-spinner`, `Ss::SplashComponent` | `TextButton`, `CircularProgressIndicator` |

**SsMoneyField com controller.** O controller guarda o texto em reais, sem o símbolo ("1.234,56"): o que o app escreve
(IA, boleto, histórico) aparece no campo, e o que a pessoa digita ou confirma no teclado vai para o controller. Com
`expression: true` a conta ("45+12,5") vira o valor ao sair do campo; sem ela, texto escrito de fora é posto no formato
("81000,00" → "81.000,00"). Do `MoneyField` do app: `label:` igual (passe "Valor" onde ele era o padrão), `isRequired:` →
`required:`, `currency:` → `formats:`, `errorText`, `signed`, `autofocus`, `focusNode`, `onKeypad` iguais; quem não tinha
o botão da calculadora passa `calculator: false`. Leia o valor com `SsMoneyField.parse(c.text)` (aceita "1.234,56",
"1234.56", "45+12,50", "-10").

**SsSpeedDial.** Fechado é um `SsFab` (sem `label`, o círculo com "Ações rápidas" na dica e no leitor, com o estado no
Semantics). Abre numa rota com véu: voltar, toque no véu e o × fecham; a 1ª ação fica mais perto do botão, as ações sobem
com a mola em escada e o + gira até ×; escolher fecha e depois roda a ação; linha da ação com 48 de alvo. Com uma ação
vira o `SsFab` dela; sem ações não desenha. Reduzir movimento abre e fecha sem animação.

**Speed dial no web.** Renderize uma vez, no layout, fora do `<main>` (o `id` estável evita duplicar no morph). A ação
de um item sem `href` (`action: "assistant#toggle"`) só alcança controllers ancestrais: envolva o componente no
elemento do controller do app. Com uma ação só vira o `Ss::FabComponent` dela. O botão tem `aria-expanded`,
`aria-haspopup="menu"` e `aria-controls`; abrir põe o foco na 1ª ação, ↑ ↓ Home End movem, Esc fecha e devolve o foco,
clique fora/Tab para fora/escolher fecham; antes do cache do Turbo ele fecha.

**Diálogo global (o modal do layout).** No layout, um só:
`render Ss::DialogComponent.new(id: "modal-dialog", title: "Formulário", global: true, header: false, size: :lg)`; qualquer
link com `data-turbo-frame="modal"` abre e carrega. Abre também quando o frame enche por turbo-stream, fecha quando
esvazia, limpa o frame ao fechar e fecha antes do cache do Turbo. "Salvar e criar outro": o botão leva
`data-ss-dialog-keep-open` (o redirect para o formulário limpo carrega no frame) e fechar depois disso recarrega a página
de trás (`Turbo.visit(location.href, { action: "replace" })`), a menos que uma visita já esteja em curso (o envio
normal que redireciona a página inteira). Resposta sem o frame (`turbo:frame-missing`) fecha e segue a URL. Cancelar
e o X de um cabeçalho vindo na resposta usam `data-ss-dialog-dismiss` (no lugar do `data-action="modal#close"`); o
`[data-ss-dialog-close]` continua significando "fechar ao carregar esta resposta". Com `header: false` o nome lido vem
de `title:` ou do 1º `h1/h2` da resposta. Esc, X e clique no fundo, como antes.

**Ações de linha.** CSS puro do Tailwind 4: `@media (hover: hover) and (pointer: fine)` esconde as ações
(`opacity: 0`) enquanto a linha (`tr`, `li`, `.ss-item`, `.ss-row`, `.ss-card` ou `[data-ss-row]`) não está com o mouse
nem com o foco, e nunca esconde com um popover/`details` aberto dentro; no toque ficam sempre à vista. O produto pode
tirar o `@custom-variant hover (&:hover)` quando trocar o `md:opacity-0 md:group-hover:opacity-100`.

**Padrões que mudaram.** `Ss::DialogComponent` com `frame_id:` passa a seguir a URL quando a resposta não tem o frame
(antes, o Turbo mostrava "Content missing"; `follow_missing: false` volta). `PopoverComponent` com `trigger:` ganha
`title` igual ao `label:` (a dica do botão de ícone). `ss_status(…, :warn)` passa de cinza para âmbar. O vazio da
`DataTableComponent` e o resto ficam iguais por padrão. No app, nada muda para quem já usa o `SsMoneyField` sem controller. Quem trocar o `MoneyField` do app por `SsMoneyField(expression: true)`: vazio obrigatório diz "Informe um valor", conta que não fecha diz "Conta ou valor inválido", negativo sem `signed: true` é recusado, aparece a dica "0,00" (`hint: ''` tira) e a linha "= R$ 57,50" durante a conta.

**Textos novos:** Rails `speed_dial.label`, `form_errors.title`, `privacy.hide`, `privacy.hint`, `common.edit`,
`common.remove`, `common.saving`, `data_table.actions` (pt-BR, en, es); Flutter `quickActions` (pt, en, es).

## v0.17.1: o botão flutuante na área segura de verdade e o selo do topo fora do herói

Correção da v0.17.0, achada nas capturas do minha-automacao. O `.ss-fab` antigo do `engine.css` vem depois na cascata e
fixava `bottom/right: 1.25rem`, então a área segura e o `lift:` do `Ss::FabComponent` não valiam; agora as regras de posição
usam `.ss-fab:not(.is-static)`. E o `.ss-hero-chip` (selo do topo do painel) fora do `.ss-hero`/`.ss-aurora`/`.is-grad`
passa a ser a pílula em fundo de campo com a tinta normal (antes, branco a 20% sobre a página clara, quase invisível); sobre o
degradê continua igual. Nada quebra.

## v0.17.0: botão flutuante como componente e cabeçalho compacto

O que o minha-automacao pediu ao tirar o "Falar" do topo do painel: o botão flutuante vira componente no web
(antes era só a classe `.ss-fab`) e o cabeçalho ganha a linha de cima e o modo compacto. Tudo aditivo; a API não
quebra. Vitrine Rails: "Botão flutuante e cabeçalho compacto" (grupo Tela); catálogo nos dois lados
(`flutter/test/catalogo_v102.dart`, estados novos do `ss-fab` e do `ss-top-bar`; `rails/catalogo/index.html`,
seções de `rails/sample/script/catalogo_v017.rb`).

| Peça | Flutter | Rails / CSS | No lugar de |
|---|---|---|---|
| Botão flutuante | `SsFab(icon:, label:, tooltip:, onPressed:, extended: true, extendedFrom: 640)`: `extended: false` com `label` = círculo, e o `label` vira a dica e o nome lido; `extendedFrom:` mostra o texto só na tela a partir dessa largura | `Ss::FabComponent(icon:, label:, href: nil, extended: false \| true \| :wide, position: :end \| :start, lift: "4.5rem", pulse: false, static: false, permanent: false, id: "ss-fab")` · `.ss-fab` + `.is-wide`, `.is-start`, `.is-still`, `--ss-fab-lift` | botão "Falar" no topo do painel, `<button class="ss-fab">` à mão |
| Cabeçalho compacto | `SsTopBar(eyebrow: 'Casa · 10 de novembro')`: linha pequena em caixa alta, apagada, acima do título | `Ss::PageComponent(eyebrow:, compact: true)` · `.ss-page.is-compact`, `.ss-page-eyebrow` | herói em degradê no topo do painel |

**Botão flutuante no web.** `label:` é obrigatório: é o `aria-label` e o `title` (no círculo, a dica); na pílula
aparece também ao lado do ícone. `href:` vira `<a>`; sem ele, `<button type="button">`, e a ação vem do `data:` do
app (`data: { action: "assist#open" }`). Fica fixo embaixo, acima da área segura (`env(safe-area-inset-*)`); no
celular sobe sozinho acima da `.ss-sticky-bar`; `lift:` sobe acima de uma barra do app (quiosque, player). A
`.ss-shell-main` ganha espaço embaixo para o fim da página não ficar por baixo do botão. Foco visível, some na
impressão e, por padrão, sem o anel que pulsa (`pulse: true` liga). **Turbo:** renderize uma vez, no layout, fora do
`<main>`; o `id` estável (padrão `ss-fab`) faz o morph casar o mesmo nó em vez de criar outro, e `permanent: true` põe
`data-turbo-permanent` quando o botão guarda estado.

**Padrões que mudaram.** Nenhum no app. No web, `.ss-fab` passa a ler `--ss-fab-lift` no `bottom` (0 sem a
variável: o mesmo lugar de antes) e ganha o anel de foco.

## v0.16.0: legenda, oferta completa, chip removível, alto contraste, capa no cabeçalho, escolha livre, barras divergentes, estrelas e comparação

Etapa 5 da migração do minhas-compras-app e do minhas-viagens-app (`../docs/MIGRACAO-minhas-compras-viagens.md`):
as lacunas médias e os pedidos das etapas 2–4. Tudo aditivo (parâmetro novo sempre opcional); a API não quebra.
Vitrine Rails: grupo "Compras e viagens (v0.16)"; catálogo nos dois lados (`flutter/test/catalogo_v16.dart`,
`rails/catalogo/index.html`, seções de `rails/sample/script/catalogo_v016.rb`).

| Peça | Flutter | Rails / CSS | No lugar de |
|---|---|---|---|
| Legenda de gráfico | `SsChartLegend(items: [SsLegendItem(label, color, value:, line:, dashed:)], alignment:)`: bolinha (ou traço, tracejado) + rótulo com "…" + valor em DM Mono; repetidos uma vez | `Ss::ChartLegendComponent(items: [{ label:, value:, tone: :success/:muted/:s1..:s6 \| color:, line:, dashed: }])` · `.ss-legend` | `ChartLegend` (compras), `_Legend` (viagens) |
| Oferta completa | `SsOfferCard(…, badges: [Widget], meta: String, actions: [Widget], menu: Widget, hit: bool, kind: String, kindIcon:, unit: String, estimate: bool, savings: String, savingsGood: bool, stacked: bool, fill: bool)` | `.ss-offer` + `.is-hit`, `.is-estimate`, `.ss-offer-kind`, `-unit`, `-savings` (`.is-bad`), `-badges`, `-meta`, `-actions` | `McOfferCard`, `MvOfferCard` |
| Chip removível | `SsInputChip(label, icon:, onPressed:, onDeleted:, deleteTooltip:, tooltip:)`: fundo suave da marca, ✕ com alvo 48 ("Remover Lisboa"), rótulo com "…" | `.ss-tag` (já havia) com ícone (`<svg>` antes) e texto num `<span>` com "…" | `InputChip` |
| Série em variante de texto | `SsColors.seriesInk` (mesma ordem de `series`) e `SsColors.inkFor(cor)`: a cor puxada para o `ink` até 4,5:1 (7:1 no alto contraste) sobre superfície, página e campo; `ssContrast(a, b)`, `ssUntilContrast(cor, alvo, fundos, min)` | `--series-ink-1..6` (`color-mix` com `--ink` a 45%) | tons do `MvTone`, tintas do carimbo |
| Alto contraste | `AppTheme.build(b, brand:, highContrast: true)`: `SsBrand.highContrast()` (accent a 7:1 gerado da marca, sólido a 7:1 com branco), `muted` no tom do `ink2`, `line` mais forte; `SsColors.isHighContrast` | `data-ss-contrast="high"` no `<html>` ou num contêiner (todas as paletas, claro e escuro, gerado pelo `paletas/gerar.py`) | `_brandHc` + `HighContrast` (viagens) |
| Cabeçalho com capa | `SsSliverHeader(…, background: Widget, backgroundHeight: 180)`: capa no lugar do título grande, título sempre na barra, capa sobe por baixo da barra e o `bottom` (abas) fica preso | — (só app) | `SliverAppBar` + `FlexibleSpaceBar` (detalhe da viagem) |
| Escolher ou digitar | `showSsPicker(…, allowCustom: true, customOf: (texto) => T, customLabel: (texto) => String, noneLabel: 'Sem loja')` (e `SsPickerSheet` com os mesmos) | `Ss::ComboboxComponent(create: true)` (já havia) | `askStoreName` (`AlertDialog` + `Autocomplete`) |
| Calendário | `showSsDatePicker(context, initialDate:, firstDate:, lastDate:, helpText:, confirmText:, cancelText:, initialEntryMode:, selectableDayPredicate:)` → `Future<DateTime?>` | — (só app; o web usa `<input type="date">`) | `showDatePicker` cru |
| Barras divergentes | `SsDivergingBars(items: [SsDivergingBar(label, value, detail:)], unit: 'p.p.', format:, upIsGood: false)`; `SsDivergingBars.signed(v, f)` | `Ss::DivergingBarsComponent(items: [{ label:, value:, detail: }], unit:, format: ->(v) {}, up_is_good:, label:)` · `.ss-diverging` | `McImpactBars` |
| Validadores de texto | `SsValidators.qty(texto, required: true, allowZero: true, strings:)` e `SsValidators.moneyText(texto, required: false, strings:, formats:)` | — (só app; o web valida no modelo) | `qtyError`, `moneyError` |
| Foto com cor | `SsNetImage(…, placeholderColor: Color)`: degradê da cor (até 35% mais escura) com ícone/iniciais claros no vazio | — (só app) | `NetImage(color:)` / `ImageFallback` (viagens) |
| Linha do tempo | `SsTimelineItem(…, endTime: '11:00', alert: true)`: "09:30 – 11:00"; alerta pinta o horário de vermelho com ⚠ ("Atenção") | `.ss-timeline` com `<time>` e `li.is-alert` | `MvItineraryStop(endTime:, alert:)` |
| Estrelas | `SsRating(value, max: 5, size: 18, onChanged: (int) {}, label:)`: leitura com meia; editável com uma estrela por toque (alvo 48) e ajuste do leitor de tela | `Ss::RatingComponent(value:, max: 5, name:, label:, size: :sm/:md/:lg, id:)`: sem `name:` é o `.ss-stars` (agora com `--max`/`--star-size`); com `name:`, `.ss-rating` com um rádio por estrela (sem JS) | `Stars` (viagens) |
| Comparação | `SsCompareTable(caption:, plans: [SsComparePlan(name, price:, recommended:)], features: [SsCompareFeature(label, values, best:, mono:)], columnWidth: 132, labelWidth: 132)` | `Ss::CompareTableComponent` (já havia) + `best:` (índice da célula em verde) e `mono: false` por linha | `CompareTable` (viagens) |
| Ajustes | `SsFilterChip` com "…" (estourava 35 px a 1,3×); `SsSparkline(target:, markMin:)`; `SsButton(trailingIcon:)` e `SsButton.text(trailingIcon:, tone: SsTone.warning, onDark: true)`; `SsDelta.neutral('0%')`; `SsCountdownRing(warnAt: 2)`; `SsProportionBar(onDark: true, legendValue: SsLegendValue.count)`; `SsReorderableList(primary: false)` | `.ss-chip > span` com "…"; `ss_sparkline(target:, mark_min:)`; `.ss-delta` sem classe já era o neutro; `ss_countdown(warn_at:)` (`data-tone="warn"/"over"`); `.ss-proportion.is-on-dark` | `ActionChip` do assistente, `McSparkline`, "Usar inteira" sobre a câmera, `McSpectrum` |

**Só app (Flutter):** `SsSliverHeader(background:)`, `showSsDatePicker`, `SsValidators.qty`/`moneyText`,
`SsNetImage(placeholderColor:)`, `SsReorderableList(primary:)` e `SsButton.text(tone:, onDark:, trailingIcon:)` (no web o
`.ss-btn` já aceita o `<svg>` antes ou depois do texto). Os demais têm o par no web (tabela).

**Alto contraste.** A conta é a mesma nos dois lados: o accent claro vai para o preto e o escuro para o branco, em passos
de 5%, até 7:1 sobre superfície, página, campo e o suave da marca; o sólido (texto branco) também a 7:1. Gradiente e suaves
ficam. No app, um trecho com alto contraste é um `Theme(data: AppTheme.build(b, brand:, highContrast: true))` em `static
final`. No web, `[data-ss-contrast="high"]` também troca `--muted` por `--ink-2` e engrossa `--line`; o `paletas.css` traz
as regras das 30 paletas (`python3 paletas/gerar.py`).

**Escolha livre.** Com `allowCustom`, a 1ª linha vira "Usar “texto”" quando o texto não é igual (sem acento) a um item, e o
Enter usa o item igual ou o texto. `customOf` é obrigatório quando `T` não é `String`. `noneLabel` aparece com a busca
vazia e devolve `customOf('')` (no `String`, `''`).

**Padrões que mudaram.** O calendário do `SsDateField` passa pelo `showSsDatePicker`: título "Escolher data" e botões
"Cancelar"/"Confirmar" do `SsStrings` (antes, os do Material: "Selecionar data"/"OK"). `SsFilterChip` com rótulo maior que
a largura que sobra termina em "…" em vez de estourar. No `SsOfferCard`, selos, ações e menu ficam acessíveis ao leitor de
tela (o rótulo do cartão é o mesmo de antes, mais tipo, unidade, economia e a linha pequena quando houver). No web,
`.ss-chip` e `.ss-tag` ganham `max-width: 100%` e o texto num `<span>` termina em "…".

**Textos novos:** Flutter `estimateLabel`, `removeItem`, `useCustom`, `enterQuantity`, `invalidNumber`, `notNegative`,
`mustBePositive`, `invalidValue`, `ratingOf`, `starCount`, `recommended`, `included`, `notIncluded`, `attention` (pt, en,
es); Rails `rating.field`, `rating.label`, `rating.star_one`, `rating.star_other` (pt-BR, en, es).

## v0.15.2: badge sem estouro, dinheiro com espaço não separável, moeda por código, litro, espera longa e paletas Azul e Petróleo

Etapa 1 da migração do minhas-compras-app e do minhas-viagens-app (`../docs/MIGRACAO-minhas-compras-viagens.md`).
Parâmetros novos opcionais; a API não quebra. Muda o texto do dinheiro (ver "Padrões que mudaram").

| Peça | Flutter | Rails / CSS |
|---|---|---|
| Selo com rótulo longo (num `Wrap`, coluna estreita) | `SsBadge` termina em "…" em vez de estourar (o leitor de tela lê o rótulo inteiro) | `.ss-badge` com `max-width: 100%` e reticências; com ícone ou ponto, o texto num `<span>` (`<span class="ss-badge ss-badge-dot"><span>Ligada</span></span>`) |
| Dinheiro com espaço não separável ("R$" nunca sozinho no fim da linha) | `SsFormats.prefix`/`suffix` com `SsFormats.nbsp` (U+00A0): `money(123456)` → `R$ 1.234,56` | `ss_money` (e quem formata com ele: CountUp, DataTable, MoneyInput, SplitAllocator); `ComponentesUi::Helpers::NBSP`. O JS da gem (`Intl`) já saía assim |
| Moeda por código ISO | `SsFormats.forCurrency('EUR', {base: SsFormats.brl, symbol:})` → `money(4500, f)` = `€ 45,00`; `SsFormats.symbolFor(iso)`, `SsFormats.currencySymbols`, `SsFormats.currencyCode` | `ss_money(45, currency: "EUR")` (já havia) · mesmo mapa `CURRENCY_SYMBOLS` (US$, €, £, CA$, ¥…; fora dele, o código: `CHF 10,00`) |
| Quantidade com unidade | `SsFormats.qty(1.5, 'l')` → `1,5 L` (litro em maiúscula); `qtyUnit(q, unit)` passa a usar o mesmo | `ss_qty(1.5, "l")` → `1,5 L`, `ss_qty(0.25, "kg")`, `locale:` |
| Espera longa (leitura por IA) | `ssRunBlocking(context, task, label:, art:, showElapsedAfter:, cancelAfter:, onCancel:, elapsedLabel:)`; `SsBlockingIndicator(art:, showElapsedAfter:, cancelAfter:, elapsed:)`; sem `onCancel:`, o Cancelar fecha e o `Future` termina com `SsBlockingCancelled` | — (espera bloqueante é do app) |
| Paletas Azul e Petróleo (30 agora) | `SsBrand.azul`, `SsBrand.petroleo` | `data-palette="azul"`, `data-palette="petroleo"` |

**Paletas.** Azul (Minhas Compras) e Petróleo (Minhas Viagens), família Frias, com os tons do `kBrand` de cada app.
Um ajuste para passar o WCAG: o accent claro do Petróleo é `#0E7983` (o `#0E7C86` dá 4,34:1 sobre a página clara
do Flutter `#EEF0F6`; 2,5% mais escuro dá 4,52:1). O gradiente (`brandTo`) segue `#0E7C86`. O `accentSolid*` sai do
gerador (Azul `#2563EB`/`#326DF0`, Petróleo `#0E7983`/`#12828C`).

**Espera longa.** `showElapsedAfter: Duration(seconds: 8)` mostra "12 s · ainda trabalhando, não feche o app" embaixo do
texto; `cancelAfter: Duration(seconds: 15)` só mostra o Cancelar depois disso. Com `onCancel:` (o app cancela o
`CancelToken`), o cartão diz "Cancelando…" e fecha quando a tarefa termina; sem `onCancel:`, fecha na hora e a tarefa
segue, com o resultado descartado. Tradução do erro da API continua no produto.

**Padrões que mudaram.** O dinheiro do `SsFormats` (`money`, `SsAmount`, `SsMoneyField`, teclado, "= R$ 57,50") e do
`ss_money` sai com **espaço não separável** (U+00A0) entre o símbolo e o número, também no euro (`1.234,56 €`) e no
espanhol do web (`1.234,50 R$`). Quem compara texto em teste ou golden com `'R$ 1.234,56'` (espaço comum) troca por
`'R\$\u00A01.234,56'` (Dart) / `"R$\u00A01.234,56"` (Ruby), ou monta o esperado com `money(...)`/`ss_money(...)`. No web,
o `.ss-badge` só de texto passa a `inline-block` com `vertical-align: middle` (para as reticências).

**Textos novos:** Flutter `waitingElapsed` (pt, en, es); Rails `palettes.azul`, `palettes.petroleo` (pt-BR, en, es).

## v0.15: ícones, diálogo, mês, barras, dinheiro com conta, progresso, chat e confete (fase 0 do meu-financeiro)

O que faltava para o meu-financeiro (web e app) migrar sem peça genérica própria. Tudo aditivo; nada quebra da
v0.14.1 (o `SsAmount` só muda dentro de um `SsPrivacyScope(hidden: true)`). Vitrine Rails: grupo "Financeiro
(v0.15)"; vitrine Flutter: seção "Financeiro (v0.15)"; catálogo nos dois lados.

| Peça | Flutter | Rails / CSS |
|---|---|---|
| Ícone por nome (o nome salvo na API desenha o mesmo nos dois lados) | `Icon(SsIcons.named('credit-card'))`, `SsIcons.named(n, solid: true)`, `SsIcons.has`/`resolve`/`names` | `ss_icon("credit-card", size: :xs/:sm/:md/:lg/nil, variant: :solid, title:, css:)`, `Ss::IconComponent`, `ss_icon?`, `ss_icon_names` · `.ss-icon` |
| Diálogo genérico com formulário num turbo-frame | `showSsSheet` (já cobre) | `Ss::DialogComponent(id:, title:, subtitle:, icon:, frame_id:, size: :sm/:md/:lg, close_on_submit:)` + slot `footer` · Stimulus `ss-dialog` · `.ss-dialog-panel` |
| Seletor de mês ‹ Outubro 2026 › | `SsMonthSwitcher` (já cobre) | `Ss::MonthSwitcherComponent(month:, url: ->(m) {…} \| param: :month, min:, max:, frame:)` · `ss-month-switcher` |
| Barras agrupadas/empilhadas com negativos e linha combinada | `SsBarChart(labels:, series: [SsSeries…], line:, stacked:, format:, active:)` | `Ss::BarChartComponent(labels:, series: [{name:, values:, tone:/color:}], line:, stacked:, format:, active:)` · `.ss-barc` |
| Dinheiro com conta ("45+12,50"), sinal e moeda | `SsMoneyField(expression:, signed:, formats:)`, `showSsAmountKeypad(expression:, signed:, formats:)`, `ssEvalAmount` | `MoneyInputComponent(expression:, signed:, currency:)`, `ComponentesUi::AmountExpression` (`.call`, `.cents`), `ss_amount_expression`, JS `ssAmountExpression` |
| Esconder valores | `SsPrivacyScope(hidden:)` (todo `SsAmount` vira "R$ •••"), `SsPrivate` (borra), `SsPrivacyToggle`, `ssPrivacyMask` | `[data-privacy="on"]` + `ss-privacy` (já havia; agora borra também barras, progresso, resultado da conta e linhas da ação) |
| Linha de progresso (orçamento, limite, meta) | `SsProgressRow(label:, value:, limit:, kind: SsProgressKind.limit/goal, format:, icon:, warnAt:, color:, onTap:)` | `Ss::ProgressRowComponent(label:, value:, limit:, kind: :limit/:goal, format:, icon:, warn_at:, color:, href:)` · `.ss-progress-row[data-tone=ok\|warn\|over\|done]` |
| Chat com o assistente | `SsChatBubble`, `SsThinking`, `SsChatInput` (já cobrem) | `Ss::ChatComponent(id:, url:, name:, placeholder:, thinking:, echo:)` + `with_message(from: :me/:ai, text:, time:)` e slot `empty` · `ss-chat` · `.ss-chat-panel`, `.ss-chat-form` |
| Cartão de ação a confirmar ("lançar R$ 45 no Nubank") | `SsChatActionCard(title:, rows:, icon:, state: SsChatActionState.*, busy:, danger:, onConfirm:, onCancel:)` | `Ss::ChatActionComponent(id:, title:, rows:, icon:, confirm_url:, cancel_url:, state: :pending/:confirmed/:cancelled/:failed, result:, danger:)` · `.ss-chat-action` |
| Seção de formulário | `SsFieldGroup` (já cobre) | `Ss::FormSectionComponent(title:, help:, icon:, divider:, columns:)` · `.ss-form-section` |
| Confete | `showSsConfetti` (já cobre) | `Ss::ConfettiComponent(key:, on: :connect/:click)`, `data-action="ss-confetti#burst"`, `window.ssConfetti()` |

**Ícones (fonte única `rails/icones/`).** Heroicons v1 contorno (MIT, `rails/icones/LICENSE-heroicons`, 230) + 9 de
casa no mesmo traço (os do minha-automacao) + 14 cheios, e `aliases.json` com os nomes da v2 (`magnifying-glass` →
`search`, `banknotes` → `cash`, `x-mark` → `x`…). `python3 rails/icones/gerar.py` (no host) escreve
`rails/lib/componentes_ui/icons.rb` e `flutter/lib/src/v15/icon_names.g.dart`; `--check` falha se atrasados. O
par Material de cada nome fica em `flutter/lib/src/v15/icons.dart` (o teste confere que todo nome da gem tem par).
Nome que não existe vira o `question-mark-circle` nos dois lados. O tamanho do `.ss-icon` tem especificidade zero:
a peça que envolve (`.ss-icon-tile svg`…) e o Tailwind (`size-4`) ganham; para passar a um componente, `size: nil`.
No lugar de: `Ui::IconComponent` + gem `heroicon` (meu-financeiro), `icon()` + `app/assets/images/icons`
(minha-automacao), `categoryIcons` (app do financeiro).

**Diálogo.** Link com `data-turbo-frame="<frame_id>"` abre e carrega; a resposta pode trocar o título
(`data-dialog-title`/`data-dialog-subtitle` no frame) e fechar (`[data-ss-dialog-close]`). Envio que deu certo (2xx/3xx)
fecha; 422 fica aberto com o erro. `elemento.ssDialog.open()/close()`.

**Conta no valor.** Mesmas regras nos três lados (Ruby, JS, Dart): vírgula decimal com 1–2 casas, ponto + 3 dígitos é
milhar ("1.500"), ponto com 1–2 casas é decimal ("12.5"), "1,500" é ambíguo (nulo); + − × ÷ * / e parênteses.

**Textos novos:** Rails `chat.*`, `money_input.invalid`, `month_switcher.*`, `progress_row.*`; Flutter `hiddenValue`,
`showValues`, `hideValues`, `invalidAmount`, `calculator`, `toggleSign`, `progressOf/Left/OverBy/ToGo`, `goalReached`,
`chatAction`, `chatConfirmed`, `chatCancelled`, `chatFailed` (pt, en, es).

**Catálogo web:** as `<section>` da v0.15 saem de `rails/sample/script/catalogo_v015.rb`
(`bin/rails runner script/catalogo_v015.rb` em `sample`), renderizando os componentes de verdade.

## v0.14.1: rótulo com ícone, painel rebaixado e o quadro de arrastar no web

Pedido do minha-automacao (recursos do tile iguais no web e no app; primeira configuração sem painel nem
quadro próprios). Tudo aditivo; nada quebra da v0.14.0. Vitrine Rails: "Painéis (v0.14)"; catálogo nos dois lados.

| Peça | Flutter | Rails / CSS |
|---|---|---|
| Rótulo com ícone (recurso do tile: brilho, modo, nível) | `SsFieldLabel(text, icon:)` | `<span class="ss-label"><svg/>Brilho</span>` (`.ss-label:has(> svg)`) |
| Linha de valor com ícone | `SsValueRow(label, value, icon:)` | `<div class="ss-value-row"><span><svg/>Umidade</span><span>9 %</span></div>` |
| Ícone no slider e no campo −/+ | `SsFieldLabel(icon:)` em cima do `SsSlider`/`SsStepper` | `RangeComponent(icon:)` também na variante padrão, `StepperInputComponent(icon:)` |
| Painel rebaixado (bloco dentro de um passo/card) | `SsCard(soft: true)` | `.ss-card.is-soft` |
| Quadro de arrastar: coluna, título e cartão | `SsKanban` (já cobre) | `.ss-kanban-col` (`.is-over`), `.ss-kanban-head`, `.ss-kanban-card` (`.is-dragging`), `.ss-kanban.is-wrap` (grade em vez de rolar) |

## v0.14: nota, tarefa com comando, tema em amostra e o que sobrava de genérico no produto

Pedido do minha-automacao (nenhuma peça genérica no CSS do produto: painéis, aparência, mapa, mídia, relatório da
migração). Tudo aditivo; nada quebra da v0.13. Vitrine Rails: grupo "Painéis (v0.14)"; vitrine Flutter: seção
"Painéis (v0.14)"; catálogo nos dois lados.

| Peça | Flutter | Rails / CSS |
|---|---|---|
| Nota no lugar do conteúdo ("nada agora", "escolha a fonte"; tom pinta o ícone, aviso pinta a frase) | `SsNote(text, icon:, tone: SsTone.neutral)` | `Ss::NoteComponent(text:, icon:, tone: :muted/:accent/:success/:warn/:danger)` (ou bloco) · `.ss-note[data-tone]` |
| Tarefa com comando (a linha marca, × remove, marcada riscada) | `SsTaskItem(label, done:, onChanged:, onDelete:, deleteTooltip:)` | `.ss-checklist li > button[role=checkbox][aria-checked]` + `.ss-checklist-x` (`aria-disabled` trava) |
| Foto no ícone tonal | `SsIconTile(icon, image:)` (o ícone fica enquanto carrega ou se falhar) | `<span class="ss-icon-tile"><img src alt=""></span>` |
| Ícone âmbar de energia/luz | `SsIconTile(tone: AppColors.aquecFg)` | `.ss-icon-tile.is-heat` (+ `.is-grad`) |
| Tema numa amostra (galeria de temas) | `SsPalettePicker` (já cobre) | `label.ss-swatch > input[type=radio]` (rádio escondido, anel na marcada), `.is-block`, `--p1..--p4`, `--ss-swatch-wall` |
| Botão sobre o gradiente (herói) | `SsIconTile(onGradient:)`/`SsTopBar` (já cobrem) | `.ss-btn.is-on-grad` |
| Item que é botão (foca algo na tela) | `SsListItem(onTap:)` (já cobre) | `button.ss-item` (sem borda, hover, `disabled`) |
| Peça dentro de outro card, sem moldura | — | `css: "is-flush"` no `MediaPlayerComponent`, `JobProgressComponent` (e `.ss-card.is-flush`) |
| Superfície do card por token (tema de vidro do produto) | `SsGlass`/tema (já cobre) | `--ss-card-bg`, `--ss-card-border`, `--ss-card-filter` no `.ss-card` e no `.ss-device` |
| Etiqueta com a cor do usuário | — | `.ss-label-chip` (`--c`) (saiu do minha-automacao) |
| Barras em pílula num card estreito | `SsPillBars(height:)` (já cobre) | `.ss-bars` com `--ss-bars-h`, barra que afina, `.ss-bar.is-empty`, rótulo vazio some |
| Câmera: ação que alterna | `SsCameraTile` (já cobre) | `.ss-cam-actions > [aria-pressed=true]` na cor da marca |

## Verificar

```bash
# Flutter (na raiz do repo)
podman run --rm -v "$PWD":/r -w /r/flutter -v flutter_pub:/root/.pub-cache ghcr.io/cirruslabs/flutter:stable \
  bash -c 'git config --global --add safe.directory "*"; flutter pub get; dart format --set-exit-if-changed lib test example; flutter analyze; flutter test'
# Capturas da densidade (compacta, padrão, confortável; claro e escuro): DENSIDADE_SAIDA=<pasta> flutter test test/densidade_test.dart
# Rails
podman run --rm -v "$PWD":/r -w /r/rails/sample -v cui_sample_gems:/usr/local/bundle localhost/ci-ruby:3.3-suite \
  bash -c 'bundle install --quiet; bin/rails test; bin/rails tailwindcss:build'
# Gerados (no host): python3 paletas/gerar.py --check; python3 rails/icones/gerar.py --check
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
- `v0.20.4` (11/11/2026): seção "v0.20.4". `RepeaterComponent(header:, hide_labels:, columns:)` + `r.row(columns:, data:, class:, **attrs)` ↔ `SsRepeater(header:, flex:)` + `SsRepeater.cells`; `DataTableComponent(stack: false)` ↔ `SsDataTable(stack: false)`; `.ss-figure` e o card do `.ss-stat` só com `.is-card`/`.ss-stat-body` (o `.ss-stat` solto deixa de ganhar fundo de card). A API não quebra.
- `v0.23.4` (14/11/2026): seção "v0.23.4". Stimulus `ss-reveal` (campos conforme a escolha de um select). Nada quebra.
- `v0.23.3` (14/11/2026): seção "v0.23.3". `SegmentedComponent(role:)` e item com `role:`; `.ss-btn-bare` em `:where`. Nada quebra.
- `v0.23.2` (14/11/2026): seção "v0.23.2". Verificador do Flutter pega chamada com tipo record. Nada quebra na API.
- `v0.23.1` (14/11/2026): seção "v0.23.1". `f.ss_swatch_radio`, opção de rádio desligada e `ButtonComponent(form: "id")`. Nada quebra.
- `v0.23.0` (14/11/2026): seção "v0.23.0". `showSsTimePicker`, `Ss::SegmentedComponent`, `ButtonComponent(variant: :bare)`, `f.ss_chip_check_box`/`ss_chip_radio_buttons`, `.ss-anim-*`, `.ss-span-grid` e `.ss-wall`. Nada quebra.
- `v0.22.1` (14/11/2026): seção "v0.22.1". `StickyActionBarComponent(always: true)` não some ao voltar o campo ao original, em Cancelar nem ao enviar (`ss-dirty` com `always`). Nada quebra.
- `v0.22.0` (não lançada): seção "v0.22.0". Tela de entrada "Folhinha": `SsAuthLayout.folhinha(variant:)` ↔ `Ss::AuthLayoutComponent(variant: :sheet | :wall | :pad)`, fonte de exibição (`AppTheme.display` ↔ `--ss-font-display` + `ss_display_font_tag`) e `SsStrings.authPartOf` ↔ `componentes_ui.auth.*`. Nada quebra.
- `v0.21.0` (não lançada, branch `beleza`): seção "v0.21.0". `SsCue` ↔ `.ss-cue` + `ss-cue` + `ss_cue_data` (ligou, abriu, chegou; menos movimento desliga) e `SsDeviceTile(level:)` ↔ `DeviceTileComponent(level:)` (brilho real da lâmpada). Nada quebra.
- `v0.20.2` (11/11/2026): seção "v0.20.2". Projeção tracejada no gráfico de barras: `SsBarChart(projection:, projectionFrom:)` ↔ `Ss::BarChartComponent(projection:, projection_from:)` (legenda tracejada, dica/balão, tabela e `Semantics` para leitor de tela, claro/escuro). Nada quebra.
- `v0.20.1` (11/11/2026): `SsButton(expand: false)` fica do tamanho do texto dentro de `Wrap`/`Align` (antes esticava).
- `v0.20.0` (10/11/2026): seção "v0.20.0" (o que o minhas-vendas e o meu-gestor pediram para chegar a 100%). `f.ss_*(hide_label:)` ↔ `SsTextField(hideLabel:)`, `f.ss_text_field(mask: :document/:phone/:cep)` + `ss-mask` ↔ `SsMask`, `f.ss_radio_buttons(checked:)` ↔ `SsRadioGroup` (novo), `ButtonComponent(variant: :ghost, tone: :danger)` ↔ `SsButton.ghost(tone:)`, `.is-dimmed` ↔ `SsDataRow(dimmed:)`, `Ss::ListItemComponent(subtitle_tone:, value_tone:)` (novo) ↔ `SsListItem(subtitleTone:, valueTone:)`, `KpiCardComponent(value_tone:)` ↔ `SsKpiCard(valueTone:)`, `CardHeaderComponent(eyebrow:)` ↔ `SsCardHeader(eyebrow:)`, `StickyActionBarComponent#with_summary` ↔ `SsStickyActionBar` (novo), `DataTableComponent(row_href:, flat:)` + `t.column(sticky:, header:)` + `t.total`/`t.footer` ↔ `SsDataTable(stickyFirstColumn:, footer:, flat:)` + `SsDataColumn(header:)`, `with_action` na paleta e no combobox ↔ `showSsPicker(actions:)`/`SsPickerAction`, `Ss::RepeaterComponent` + `ss-repeater` ↔ `SsRepeater`, `data-ss-privacy="off"`, item `external:` no `AppShellComponent`, `SsNavItem(badge:)`, `Ss::TextLinkComponent` ↔ `SsLinkText`/`SsTextLink`, `Ss::TermsNoticeComponent` ↔ `SsTermsNotice`, `Ss::EditableValueComponent` ↔ `SsEditableValue`, `Ss::NodeCanvasComponent` + `.ss-node-canvas` (pele do Drawflow, só web) e `GoogleButtonComponent(mode: :gis)`. Correção do `for=` do `f.ss_check_box(id:)`. Nada quebra.
- `v0.19.2` (10/11/2026): seção "v0.19.2" (as últimas caixas genéricas do minhas-compras-app e do minhas-viagens-app). `SsHeroCard.custom`, `SsButton.onGradient(solid:, stacked:)` + `SsButton(stacked:)` ↔ `ButtonComponent(solid:, stacked:)`, `SsCard(stripe:, outline:)` ↔ `.ss-card.has-stripe/.has-outline`, `SsMonogram` ↔ `ss_monogram`, `SsPhotoCard(subtitle:, credit:, onCredit:, selected:, expand:)` ↔ `PhotoCardComponent(subtitle:, credit:, credit_url:, selected:)`, `SsBadge(solid:, mono:)` ↔ `.ss-badge.is-solid/.is-mono`, `SsProseList(ordered:, start:)` ↔ `ol.ss-steps`, `SsDot` ↔ `.ss-dot`, `SsIconBubble(badge:, badgeLabel:)`, `SsQuote` ↔ `.ss-quote`, `SsIllustrationStage`, `SsPageDots`, `SsGlass(tone: SsGlassTone.dark)` ↔ `.ss-glass.is-dark`, `SsSourceChip(trailing:, semanticLabel:)`, texto `photoSource`. Nada quebra.
- `v0.19.1` (10/11/2026): seção "v0.19.1" (o que destrava o minhas-compras-app e o minhas-viagens-app no `conferirConformidade`). `SsTabsView` (conteúdo das abas), `SsTabsUnderline(stacked:)` + `stackedHeight`, `SsTooltip`, `SsDivider.vertical`/`SsDivider(vertical:)` ↔ `.ss-divider.is-vertical`, `SsMenuAction(leading:)`, `SsOverflowMenu(child:)`, `showSsFullscreen`/`SsFullscreenPage`, `AppColors.transparent`, `AppType.solid`/`tight`/`snug`/`trackingTight`/`trackingTitle`, `ssColorFromHex`/`ssTryColorFromHex`/`ssColorFromRgb` (cor que é dado), `ssIconTextStyle`/`ssPaintIcon`, texto `tapToClose`. Verificador: card à mão (Flutter e Rails) e chamada com tipo (`showDialog<void>(`). Nada quebra.
- `v0.19.0` (10/11/2026): seção "v0.19.0" (web 100% do meu-financeiro; só Rails). `Ss::ButtonComponent` (link, botão do JS, envio e `button_to` com `confirm:`; variantes `chip`/`item`/`on_grad`), `Ss::GoogleButtonComponent`, `Ss::WalletCardComponent` + `ss-tilt` (par do `SsWalletCard`), `f.ss_file_field`/`f.ss_color_field`, `DataTableComponent(select_name:, bulk_method:)`, `FormActionsComponent(submit: false)`, `IconButtonComponent(type: :submit)`, `ss_theme_color_tag` e `BarChartComponent(width:, label_every:)`; correções do rodapé preso no diálogo e da tabela para leitor de tela que estourava no celular. Nada quebra. Conformidade: `ComponentesUi::Conformidade.verificar` e `conferirConformidade` (teste "100% componentes-ui" dos produtos, sem exceções). Lado Flutter: `showSsImageViewer`/`SsImageViewer`, `SsCollapsible(subtitle:)`, `AppType.leading`/`trackingCaps`/`trackingWide`, textos `image`/`zoomHint`. Nada quebra.
- `v0.18.0` (10/11/2026): seção "v0.18.0" (fase final do meu-financeiro, web e app). `Ss::SpeedDialComponent` ↔ `SsSpeedDial`, `Ss::DialogComponent(global:, header:, clear_on_close:, refresh_on_close:, follow_missing:)` + `data-ss-dialog-keep-open`/`-refresh`/`-dismiss`, `Ss::RowActionsComponent` e `t.actions` (hover só com mouse, à vista no toque), `DataTableComponent(row_attrs:, empty_art:)`, `Ss::FormErrorsComponent`, `Ss::FormActionsComponent`, `ComboboxComponent` com ícone/imagem por opção e `input:`, `PopoverComponent(trigger_attrs:)`, `ss_status` com `:warn`/`:warning` (e `ComponentesUi.tone`), `Ss::IconButtonComponent`, `Ss::PrivacyToggleComponent`, AppShell sem a barra vazia no computador (`with_top_mobile`, ícone no grupo), utilitários `text-on-accent`/`bg-grad`/`text-info`…; no app `SsMoneyField(controller:, focusNode:, autofocus:, …)` + `SsMoneyField.parse`, `showSsToastGlobal`/`SsToastHost.navigatorKey`, `SsFab(iconTurns:)`. Nada quebra; o diálogo com frame passa a seguir a URL quando a resposta não tem o frame.
- `v0.17.1` (10/11/2026): seção "v0.17.1". `.ss-fab` respeita a área segura e o `lift:` (o do `engine.css` vencia na cascata) e `.ss-hero-chip` fora do herói em fundo de campo. Nada quebra.
- `v0.17.0` (10/11/2026): seção "v0.17.0". `Ss::FabComponent` (o `.ss-fab` como componente: círculo, pílula ou `:wide`, área segura, acima da `.ss-sticky-bar`, `lift:`, id estável para o morph do Turbo) ↔ `SsFab(extended:, extendedFrom:)`, e o cabeçalho compacto `Ss::PageComponent(eyebrow:, compact:)` ↔ `SsTopBar(eyebrow:)`. Nada quebra.
- `v0.16.0` (10/11/2026): seção "v0.16.0" (etapa 5 da migração do minhas-compras e do minhas-viagens). `SsChartLegend` ↔ `Ss::ChartLegendComponent`, `SsOfferCard(badges:, meta:, actions:, menu:, hit:, kind:, unit:, estimate:, savings:, stacked:, fill:)` ↔ `.ss-offer` completa, `SsInputChip` ↔ `.ss-tag`, `SsColors.seriesInk`/`inkFor` ↔ `--series-ink-1..6`, `AppTheme.build(highContrast:)`/`SsBrand.highContrast()` ↔ `data-ss-contrast="high"` (gerado das paletas), `SsSliverHeader(background:)`, `showSsPicker(allowCustom:, noneLabel:)`, `showSsDatePicker`, `SsDivergingBars` ↔ `Ss::DivergingBarsComponent`, `SsValidators.qty`/`moneyText`, `SsNetImage(placeholderColor:)`, `SsTimelineItem(endTime:, alert:)`, `SsRating` ↔ `Ss::RatingComponent`, `SsCompareTable` ↔ `CompareTableComponent(best:, mono:)` e os ajustes (`SsFilterChip` com reticências, `SsSparkline(target:, markMin:)`, `SsButton.text(trailingIcon:, tone:, onDark:)`, `SsDelta.neutral`, `SsCountdownRing(warnAt:)`, `SsProportionBar(onDark:, legendValue:)`, `SsReorderableList(primary:)`). Nada quebra; o calendário do `SsDateField` passa a usar os textos do `SsStrings`.
- `v0.15.2` (10/11/2026): seção "v0.15.2" (etapa 1 da migração do minhas-compras e do minhas-viagens). `SsBadge`/`.ss-badge` com reticências em vez de estourar, dinheiro com espaço não separável nos dois lados, `SsFormats.forCurrency(iso)` ↔ `ss_money(currency:)`, `SsFormats.qty(q, unit)`/`ss_qty` com litro em maiúscula, `ssRunBlocking(art:, showElapsedAfter:, cancelAfter:)` + `SsBlockingCancelled` e as paletas Azul e Petróleo (30). A API não quebra; muda o texto do dinheiro (U+00A0 no lugar do espaço).
- `v0.15.1` (10/11/2026): correção. `ss_number`/`ss_money` e os componentes que formatam com `format(...)` (CountUp, Donut, DataTable com `format: :money`, ProgressRow, BarChart, AreaChart, MoneyInput, relógio, QR, mídia…) quebravam no ViewComponent 3.x, que tem um `format` próprio sem argumentos; agora chamam `Kernel.format`. Nada quebra.
- `v0.15.0` (09/11/2026): seção "v0.15" (fase 0 do meu-financeiro). `ss_icon`/`Ss::IconComponent` ↔ `SsIcons.named` (Heroicons v1 + apelidos da v2, fonte `rails/icones/`), `Ss::DialogComponent` (turbo-frame), `Ss::MonthSwitcherComponent`, `SsBarChart`/`Ss::BarChartComponent` (agrupado, empilhado, negativos, linha), conta e sinal no dinheiro (`SsMoneyField(expression:, signed:, formats:)` ↔ `MoneyInputComponent(expression:, signed:)`, `ComponentesUi::AmountExpression`, `ssEvalAmount`), `SsPrivacyScope`/`SsPrivate`/`SsPrivacyToggle`, `SsProgressRow`/`Ss::ProgressRowComponent`, `Ss::ChatComponent` + `SsChatActionCard`/`Ss::ChatActionComponent`, `Ss::FormSectionComponent` e `Ss::ConfettiComponent`. Nada quebra.
- `v0.14.1` (09/11/2026): seção "v0.14.1". `SsFieldLabel(icon:)`/`SsValueRow(icon:)` ↔ svg no `.ss-label`/`.ss-value-row`, `SsCard(soft:)` ↔ `.ss-card.is-soft`, e no web a coluna, o título e o cartão do quadro de arrastar (`.ss-kanban-col/-head/-card`, `.ss-kanban.is-wrap`). Nada quebra.
- `v0.14.0` (09/11/2026): seção "v0.14". `SsNote`/`Ss::NoteComponent`, `SsTaskItem`/`.ss-checklist [role=checkbox]` + `.ss-checklist-x`, `SsIconTile(image:)`/img no `.ss-icon-tile`, `.ss-icon-tile.is-heat`, tema em `label.ss-swatch > input`, `.ss-btn.is-on-grad`, `button.ss-item`, `is-flush`, tokens `--ss-card-bg/-border/-filter`, `.ss-label-chip`, `.ss-bars` em card estreito e `.ss-cam-actions [aria-pressed]`. Nada quebra.
- `v0.13.0` (09/11/2026): seção "v0.13". `SsSection(icon:)`/`Ss::SectionComponent`, `SsSectionHeader(icon:)`/`Ss::SectionHeaderComponent`, `SsMasonry`/`Ss::MasonryComponent`, `SsAsideLayout`/`Ss::AsideLayoutComponent`, `SsMosaicTile(facts:)`/`Ss::MosaicTileComponent`, `SsPhotoCard`/`Ss::PhotoCardComponent`, chip com `aria-pressed`/`.is-icon`/`.ss-chip-swatch`, `ss_avatar(ring:)` marca a partir de duas cores (`SsBrand.fromColors`, `ssMix` / `ss_brand_style`), texto longo e abertura (`SsProse`/`SsIntro` ↔ `ProseComponent`/`IntroComponent`), grupo de campos com ajuda (`SsFieldGroup` ↔ `ss_fieldset`), `wrapper_class:`/`selected:`/`ss_submit(variant:)` no form builder e `TreeViewComponent(wrap:)`. Nada quebra.
- `v0.12.0` (09/11/2026): seção "v0.12". `SsDeviceTile`/`Ss::DeviceTileComponent` numa linha com o ícone como chave (switch acessível nos dois lados), agenda que não estoura o card (dia inteiro numa linha; `SsDayAgenda(allDay:)` no Flutter), `SsCardHeader`/`Ss::CardHeaderComponent`, `SsKpiCard`/`Ss::KpiCardComponent` e `SsRankList`/`Ss::RankListComponent`. A API não quebra; muda o desenho do tile (a chave saiu da direita).
- `v0.11.0` (05/11/2026): densidade nos dois lados (seção "v0.11"): `SsDensity` (compacta, padrão, confortável) por `AppTheme.build(density:)` e `SsDensityScope`, `SsTapTarget`, `SsDensityPicker`; no web, tokens `--ss-*` trocados por `data-ss-density` no `<html>` ou num contêiner, `ComponentesUi.config.density`, `ss_density_attrs`, `ss_density_head`, `Ss::DensityPickerComponent` + `ss-density`. Os componentes leem tamanho dos tokens. Alguns padrões grandes demais encolheram (tabela na seção). Nada quebra na API; parâmetros de tamanho com padrão literal viraram anuláveis (nulo = da densidade). Roteiro de migração em `docs/MIGRACAO.md`.
- `v0.10.3` (05/11/2026): correções e lacunas da migração do minha-automacao para a v0.10.2 (seção "v0.10.3"): `SsTopBar` na fonte do tema e com o véu do overlay visível, toque longo/duplo no `SsDeviceTile` (⋯ e menu de contexto no web), segurar para falar (`SsMicButton(holdToTalk:)`, `SsChatInput(onMicHoldStart:)`, `MicButtonComponent(hold:, compact:)`), `SsHaptics.light`, `SsIconTile(onGradient:)`/`.is-on-grad`, `SsChipBar(currentIndex:)`/`ss-scroll-current`; no web, `FilterBarComponent` com arrays e query do `url:`, `ss-live` com `display: contents`, `OptionCardComponent(id:, input:, dense:, vertical:)`, chip de caixa de marcar, checklist de linha inteira, `.ss-tag > a`, `SubnavComponent(layout: :tabs)` e `.ss-base`/`.ss-reduce-motion`. Nada quebra.
- `v0.10.2` (05/11/2026): o que faltava para o minha-automacao ficar 100% no pacote e na gem (seção "v0.10.2"): barra de topo, botão de ícone, botão flutuante, carregando/abertura, linhas em card, arrastar para ordenar, zona de perigo, aviso em linha, bloco de código, grupo de comandos, passo numerado, divisor, pergunta de um campo no web, atalhos de seção com menu, chips sólidos e faixa que esmaece, coluna da hora da agenda que cresce, controllers genéricos. Nada quebra; no web o `.ss-subnav` passa a marcar a seção atual (`aria-current=page`) e a esmaecer a borda no celular.
- `v0.10.1` (04/11/2026): o que a migração do minha-automacao pediu (seção "v0.10.1"). Nada quebra; no web, a marca passa a aparecer na barra do celular do `AppShell` (`mobile_brand: false` desliga) e as regras de `.ss-shell[data-collapsed]` ganharam o seletor do `<html>`.
- `v0.10.0` (04/11/2026): peças de casa e automação (tabela da seção "v0.10"), idioma pt/en/es nos dois lados, `--accent-solid`, sucesso/perigo AA. Nada quebra: parâmetros de texto que tinham padrão em português ficaram opcionais (passar String continua valendo); no web, o checkbox e o switch ligado usam `--accent-solid`.
- `v0.9.0` (04/11/2026): paletas, OLED, 58 peças Flutter e 60 componentes Rails (`Ss::*Component` + Stimulus + `ss_form_with`), vitrines Flutter e Rails (seção "v0.9"), movimento com a mola do menu do app em tudo e 28 paletas geradas de `paletas/paletas.json` para os dois lados. A gem passa a depender do `view_component`. Nada quebra da v0.8; no web o `.ss-check` passa a ser desenhado pelo CSS e quatro paletas antigas mudam um pouco de cor (alinhadas ao Flutter).
- `v0.8.0` (02/11/2026): parâmetros que as migrações pediram. `SsListItem(trailing:, dimmed:, onLongPress:, maxLines:)`, `SsTextField(helperText:, minLines:)`, `showSsPrompt(allowEmpty:, maxLines:, maxLength:, message:)`, `SsSearchField(debounce:, suffix:)`, `SsDateField(initialDate:, validator:, showShortcuts:)`, `ssRunBlocking(onCancel:)`, `SsUnsavedGuard(isDirty:)`, `SsSegmented(icons:, disabled:)`, `SsFilterChip(icon:)`, `SsSwitchRow(icon:)`, `SsBadge(icon:)`, `SsCard(tint:)`, `SsMenuAction(checked:, subtitle:)`, `SsOverflowMenu(icon:)`, `SsEmptyState(art:)`, `SsProgress(null)` (indeterminado), `SsChatInput(enabled:, leading:)`, `SsOnboardingPage(action:)`, `showSsPlanLimit(secondaryLabel:, onSecondary:)`, `showSsPicker(initialQuery:)`, `SsCountdownRing(format:, onDark:)` e `SsCountdownRing.mmss`, `SsColors.series` (a 1ª cor é a marca do produto; `AppColors.series[0]` segue violeta). Só Flutter. Nada quebra da v0.7.
- `v0.7.0` (02/11/2026): o que a migração de gestor, compras, viagens, cultivo e financeiro pediu. Novos `SsAsyncSliver` (o `SsAsyncBody` como sliver, para o `SsScreenHeader`), `SsFit`/`SsFitTitle`/`SsButtonPair` (valor e título que encolhem; dois botões que empilham com fonte grande), `SsSectionHeader` (título de bloco com explicação e ação) e `SsValueTile` (linha com nome em 2 linhas e valor que encolhe ou desce). `SsNetImage(provider:)` aceita o provider do app (cache em disco). Correções: o título grande do `SsScreenHeader` cresce com a fonte (estourava em 1,6×) e `SkeletonList`/`SkeletonBox` param com "reduzir movimento". Só Flutter. Nada quebra da v0.6.
- `v0.6.0` (01/11/2026): o que a migração do meu-personal pediu. Novos `SsIconTile` (ícone tonal, `filled`/`circle`), `SsTimeField` e `SsCheckRow`; parâmetros novos, todos opcionais: `SsStepper(label:)`, `SsStatCard(tone:)` (e o número encolhe em vez de estourar a coluna), `SsTextField(suffixText:, textCapitalization:, maxLength:, autofillHints:, focusNode:)`, `SsSearchField(onSubmitted:)`, `SsScreenHeader`/`SsSliverHeader(leading:)` com voltar automático quando a tela pode voltar, `SsScreenHeader(onRefresh:)`, `SsAsyncBody(showRefreshing:)`, `SsEmptyState(compact:)`, `SsShareable(background:)`. Só Flutter (a web já tinha os equivalentes). Nada quebra da v0.5.
- `v0.5.0` (31/10/2026): o que os apps tinham repetido vira pacote (tabela "Peças da v0.5": estados assíncronos, diálogos, folha, desfazer com contagem, faixa offline, campos com validação na hora, dinheiro com teclado próprio, data com atalhos, escolha e busca em folha, contador, deslizar com ação, gráfico de linha com dedo que corre, calendários, linha do tempo, medidor, anel de prazo, progresso com marcador, proporção, status, oferta, imagem de rede, cabeçalho que encolhe, apresentação, primeiros passos, dica, limite de plano, chat com IA, compartilhar como imagem, sincronização, menu ⋮, movimento e vibração por contexto) e extras (odômetro, botão com estados, paleta de comandos, menu de toque longo, seleção múltipla, card que vira tela, antes/depois, kanban com arrasto, valor que voa). O pacote passa a depender de `flutter_riverpod`. Web: classes e helpers equivalentes (`ss_odometer`, `ss_gauge`, `ss_countdown`, `ss_heat`, `ss_status`). Nada quebra da v0.4.
