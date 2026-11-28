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
      ref: v1.14.3
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
gem "componentes_ui", git: "https://github.com/minhasuite/componentes-ui.git", tag: "v1.5.2"
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
- **Por categoria de uso, iguais nos dois lados** (v1.9): Novidades · Fundação · Navegação e
  moldura · Ações e botões · Formulários e entrada · Listas e tabelas · Dados e gráficos · Cards e
  painéis · Retorno e estados · Movimento e transições · Conversa, IA e avisos · Tempo e agenda ·
  Casa e automação · Comércio e finanças · Mídia e captura · Telas montadas (mesmos nomes, ícones
  `ss_icon`/`SsIcons.named` e ordem). App: `flutter/example/lib/categorias.dart` (mapa slug →
  categoria, reserva por palavra; `flutter/test/categorias_test.dart` falha com peça sem categoria).
  Web: `VitrineController::CATEGORIAS`; a 1ª linha da página leva `grupo:` e, se mistura assuntos,
  `tambem: A; B`; `versao: 1.9` põe em Novidades (`rails/sample/test/vitrine_test.rb` falha com
  grupo fora do menu e abre todas as páginas). Novidades no app: as peças dos `comV19*` do
  catálogo e as marcadas "(v1.9" na descrição.

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

## v1.14.3: o explicar (e as outras folhas) acima da barra de abas e a chave do SsDeviceTile com 48

Só Flutter; o Rails é igual à v1.14.2. Nada muda no desenho, então o catálogo fica como está.

**Folhas e balões pelo `Navigator` raiz.** Numa tela de aba com `Navigator` próprio (o `StatefulShellRoute` do
go_router, dentro do `SsNavScaffold`), o `showModalBottomSheet` abria no `Navigator` da aba: a folha ficava no corpo
e a `SsNavBar` passava na frente dela. Visto no `SsExplain` (toque longo no número) em Relatórios do
minhas-vendas-app. Agora abrem pelo `Navigator` raiz, por cima da barra:

| Onde | O que mudou |
|---|---|
| `showSsSheet(useRootNavigator: true)` e `showSsSheet(detents:)` (`showSsDetentSheet`) | parâmetro novo, padrão `true`; `false` volta ao `Navigator` mais próximo |
| `showSsFilterSheet(useRootNavigator: true)` (e o `SsFilterBar`) | idem |
| `showSsPopover(useRootNavigator: true)` (e o `SsPopover`) | idem; continua ancorado no botão |
| `showSsExplain`/`SsExplain`, `showSsCaptureHub`, `showSsAiActionPreview`, `showSsSinceLastVisit` | passam pelo `showSsSheet`, então herdam |
| `showSsPicker` (folha com busca), `showSsPlanCompare`, a roda de data/hora do iOS (`ssWheelSheet`) | `useRootNavigator: true` fixo |

Diálogos (`showSsConfirm`, `showSsPrompt`), a paleta de comandos, a folha de ações do iOS, o speed dial, o visor de
imagem e o tour já abriam na raiz. Quem fecha a folha com o próprio contexto dela (`Navigator.pop(context)` no
`builder`, `SsSheet`, `SsPopover.close`) não muda; quem fechava com o contexto da **tela** (`Navigator.of(telaCtx).pop()`)
passa a fechar a tela da aba: use o contexto de dentro da folha. O `context.pop()` do go_router fecha a folha (ele
não passa de rota sem página que está por cima do shell).

**`SsDeviceTile`: a chave com 48 no toque e no leitor de tela.** O quadrado do ícone (a chave, com `onToggle:`)
desenha `iconTile + 2` (44 no padrão, 40 no compacto) e já tinha o toque de 48 pelo `SsTapTarget`, mas o nó do leitor
de tela era o do desenho, e o `ssA11yAudit` reprovava. Agora é `SsTapTarget(semantics: true)` por fora do `Semantics`
da chave: o nó tem 48 × 48, o desenho não muda. Nos apps, tire o "sem `ssA11yAudit`" dos testes de tela com tiles.
O `DeviceTileComponent` do web fica como está (o alvo de 44 px do web, v0.24).

Testes: `flutter/test/v1143_test.dart` (as folhas e o balão abertos de uma tela de aba com `Navigator` próprio no
`SsNavScaffold`, o toque no meio da barra caindo na folha, e o `ssA11yAudit` do tile no padrão e no compacto).

## v1.14.2: desfazer do arquivar e as arquivadas na central, iOS na CI e a origem do logo da Apple

Nada quebra: tudo o que entra é opcional. Sem os parâmetros novos, a central fica como na v1.14.1.

| Flutter | Rails | O que faz |
|---|---|---|
| `SsNotificationCenter(archive:, unarchive:)` | `Ss::NotificationCenterComponent(archive_undo: true)` | o aviso "Notificação arquivada" ganha "Desfazer" com a contagem. No app, arquivar vai ao servidor na hora e desfazer chama o `unarchive`; o item volta crescendo ao mesmo lugar (a animação do `SsUndoableRemoval`) e, se o `unarchive` falhar, sai de novo com o aviso de erro. No web, o aviso vira `ss-undoable`: sai encolhendo, e o PATCH do `archive_href:` só vai quando o tempo passa sem desfazer (desfazer não vai ao servidor). Sem `unarchive:`/`archive_undo:`, o aviso fica sem botão, como antes |
| `SsNotificationCenter(loadArchived: (page) → SsNotificationPage, initialView: SsNotificationView.inbox\|archived)`, `SsNotificationCenterController.show(view)`/`.view` | `Ss::NotificationCenterComponent(archived_url:, inbox_url:, archived: true)` | "Caixa de entrada \| Arquivadas" no topo (`SsSegmented` ↔ `Ss::SegmentedComponent` com links). Nas arquivadas não aparece a faixa de não lidas nem o ponto, e o sino não as conta. O vazio é próprio ("Nenhuma notificação arquivada"). No app a aba relê ao abrir |
| `SsNotificationCenter(unarchive:)` nas arquivadas | item `unarchive_href:` (ou `unarchive_url:`; `unarchive_method:`, padrão PATCH) com `archived: true` | "Desarquivar": no app, deslizar para a esquerda (também ação do leitor de tela); o item sai, a caixa de entrada é relida e, se falhar, ele volta com o aviso. No web, um botão de ícone (`inbox`) no lugar de ler e arquivar |

Textos novos em pt, en e es: `SsStrings.notifInbox`, `notifArchivedTab`, `notifUnarchive`, `notifUnarchived`,
`notifArchivedEmptyTitle`, `notifArchivedEmptyText` ↔ `componentes_ui.notification_center.inbox`, `archived_tab`,
`tabs`, `unarchive`, `archived`, `archived_empty`, `archived_empty_text`. CSS: `v1142_web.css` (`.ss-ncenter-tabs`).

```dart
SsNotificationCenter(
  load: repo.pagina,                          // a caixa de entrada
  loadArchived: (p) => repo.pagina(p, arquivadas: true),
  markRead: repo.marcarLida,
  archive: repo.arquivar,
  unarchive: repo.desarquivar,                // liga o "Desfazer" e o "Desarquivar"
  onOpen: (n) => context.push(rota(n)),
)
```

```erb
<%= render Ss::NotificationCenterComponent.new(archived: params[:arquivadas].present?, archive_undo: true,
      archived_url: notificacoes_path(arquivadas: 1), inbox_url: notificacoes_path, items: @avisos.map { |a|
        { id: a.id, title: a.title, at: a.created_at, unread: a.read_at.nil?, href: abrir_path(a), method: :patch,
          archive_href: arquivar_path(a), unarchive_href: desarquivar_path(a) } }) %>
```

**Ao subir nos produtos: tirar o `showSsUndo` por cima do aviso do pacote.** Os apps abrem um `showSsUndo` próprio
no quadro seguinte ao `archive:`, porque o pacote só mostrava "Notificação arquivada". O do meu-financeiro-app, por
exemplo, faz assim. Com a v1.14.2 o desfazer passa a ser da central, e o contorno deixa dois avisos de desfazer:

```dart
// Antes (contorno; o do meu-financeiro-app, notifications_screen.dart):
Future<void> _archive(String id) async {
  await api.postData<dynamic>('/notifications/$id/archive');
  WidgetsBinding.instance.addPostFrameCallback((_) => _offerUndo(id));
}
Future<void> _offerUndo(String id) async {
  if (!await showSsUndo(context, 'Notificação arquivada', icon: Icons.archive_outlined) || !mounted) return;
  await api.postData<dynamic>('/notifications/$id/unarchive');
  await _center.refresh();                    // o item voltava pela releitura, sem animação
}

// Depois: só as duas chamadas. A central mostra o desfazer e devolve o item ao lugar.
SsNotificationCenter(
  archive: (id) => api.postData<dynamic>('/notifications/$id/archive'),
  unarchive: (id) => api.postData<dynamic>('/notifications/$id/unarchive'),
  // …
)
```

O que sai: o `_offerUndo` (o `showSsUndo` no `addPostFrameCallback`) e o `refresh()` depois de desarquivar. O
endpoint de desarquivar é o que o contorno já chamava. Se algum produto não tiver, deixe `unarchive:` de fora até
criar, e o aviso fica como na v1.14.1. Para a aba, o produto precisa listar as arquivadas (por exemplo
`GET /api/v1/notifications?archived=1`) e passar `loadArchived:`. No web, `archive_undo: true` basta, porque o
arquivar só vai ao servidor depois do tempo. Quem já mostra `Ss::ToastComponent(undo_url:)` no redirect do arquivar
pode tirar esse aviso e ligar o `archive_undo:`, ou manter o aviso e deixar o `archive_undo:` desligado.

**iOS na CI.** `.github/workflows/ios.yml` compila a vitrine para iOS em release e sem assinatura
(`flutter build ios --release --no-codesign` em `flutter/example`) num `macos-latest` do GitHub, gratuito porque o
repo é público, em push na `main`, em tag `v*` e à mão. Não publica nada e não usa segredo: serve para provar que o
pacote compila no iOS. O `flutter/example/ios` foi criado com `flutter create --platforms=ios .` (bundle
`com.minhasuite.componentes`, o mesmo id do Android). Até o primeiro push na `main` o job não tinha rodado nenhuma
vez.

**Logo da Apple: continua o do Simple Icons.** O logo oficial ("Sign in with Apple Logo", PNG/PDF/SVG em
developer.apple.com/design/resources, num `.dmg`) baixa sem login, mas vem sob a *Apple Design Resources License*.
Ela só permite os recursos "para maquetes de interface de software que roda só em macOS, iOS, watchOS ou tvOS",
proíbe usá-los para outro sistema, embuti-los em software, redistribuí-los e modificá-los. Este pacote é público
(Apache 2.0) e desenha o botão no Android e no web, então o oficial não entra. O `SsAppleButton` e o
`Ss::AppleButtonComponent` ficam com o glifo do Simple Icons, agora com a origem num comentário. No iOS, quem
quiser o botão oficial usa o `SignInWithAppleButton` do plugin `sign_in_with_apple` (desenhado pelo sistema); no
web, o botão do Sign in with Apple JS.

Catálogo: estados `abas`, `arquivadas`, `arquivadas-vazio` e `desfazer` do `ss-notification-center` nos dois
lados (`flutter/test/catalogo_v19_produto.dart`, `rails/catalogo/index.html` gerado por
`rails/sample/script/catalogo_v19_produto.rb`). `paridade.yml`: sem par novo (a nota fica no par do `SsNotificationCenter`). Testes: `flutter/test/v1142_test.dart` e `rails/sample/test/components/v1_14_2_web_test.rb`.

## v1.14.1: subtítulo no comando, número à direita no campo e a saída dos testes da v1.14.0

Correção pequena, nos dois lados. Nada quebra na API; muda um padrão: o `SsMoneyField` passa a alinhar o valor à
direita, como o `.ss-money` do web já fazia (`textAlign: TextAlign.start` volta ao de antes).

| Flutter | Rails | O que faz |
|---|---|---|
| `SsCommand(icon, label, subtitle: 'Sala')` (na `showSsCommandPalette`/`SsCommandPalette` e na busca do `SsSideMenu(search: SsSideMenuSearch(…))`) | `Ss::CommandPaletteComponent(groups: [{ items: [{ label:, subtitle:, hint:, url: }] }])` (já existia desde a v0.10.1; agora com `aria-label`) | a 2ª linha do item, menor e apagada (o cômodo de um aparelho, a loja de um cliente); entra na busca ("quarto" acha os do quarto, com o trecho destacado também nela) e no que o leitor de tela diz: "Luz do teto, Quarto" (no web, "rótulo, subtítulo, dica"; sem o `aria-label` as duas linhas saíam coladas) |
| `SsTextField(textAlign: TextAlign.end)`; `SsMoneyField(textAlign:)` (padrão `TextAlign.end`) | `f.ss_text_field :qtd, align: :end` (e `:center`; vale em todo `f.ss_*` de texto: põe `.ss-input-end`/`.ss-input-center` no input, `v1141_web.css`); o `Ss::MoneyInputComponent` já vem à direita | número, quantidade, preço e % à direita dentro do campo, como na coluna da tabela (regra da `ui-design`) |
| `SsAdaptiveScaffold(tabTransition:)` (repassa ao `SsNavScaffold`; `null` é o corte seco) | — | a troca de aba da casca adaptável também se desliga (antes só o `SsNavScaffold` aceitava) |
| `find.ssValue('R$ 4.870,00')` (em `package:componentes_ui/testing.dart`) | — | acha o valor com ou sem odômetro (o `SsOdometer` com esse texto ou um `Text` igual) |

**Ao subir nos produtos: os testes que a v1.14.0 pode ter quebrado.**

- *KPI e cartão de número (app).* O `SsKpiCard`, o `SsStatCard`, o `SsPeriodCompare` e o `SsAmount(animate: true)`
  desenham cada dígito numa coluna, então `find.text('R$ 4.870,00')` deixa de achar. Escolha uma saída:
  ```dart
  import 'package:componentes_ui/testing.dart';
  expect(find.ssValue(r'R$ 4.870,00'), findsOneWidget);            // 1) não depende do odômetro
  final h = tester.ensureSemantics();                               // 2) pelo leitor de tela
  expect(find.bySemanticsLabel(RegExp(r'R\$ 4\.870,00')), findsWidgets); // RegExp: o card lê "Receita, R$ 4.870,00"
  h.dispose();
  const SsKpiCard(label: 'Receita', value: r'R$ 4.870,00', animate: false); // 3) no app ou só no teste: o texto de antes
  ```
  `find.bySemanticsLabel('R$ 4.870,00')` com texto exato não acha (o nome do card junta rótulo, valor e legenda).
  Reduzir movimento (`disableAnimations`) tira a rolagem, mas os dígitos continuam em colunas: não serve de saída.
- *KPI (web).* O `KpiCardComponent` vira o `Ss::OdometerComponent`: o texto do card fica com os rolos ("0123456789…").
  Procure `assert_selector "[data-ss-odometer-text-value='R$ 4.870,00']"` ou `assert_selector ".ss-kpi-card-value
  .ss-sr", text: "R$ 4.870,00"`, ou passe `animate: false`.
- *Troca de aba (app).* Teste que toca a aba e procura a tela nova com um `pump()` só vê a tela a meio caminho
  (opacidade < 1, mas ela já está na árvore). Use `pumpAndSettle()`, ou desligue: `SsNavScaffold(tabTransition: null)`
  ou `SsAdaptiveScaffold(tabTransition: null)`.
- *Outros padrões da v1.14.0 que têm chave:* o arrastar dos gráficos (`scrub: false` em `SsLineChart`,
  `SsAreaChart`, `SsBarChart`, `SsTimeChart`) e o ícone animado da barra (`SsNavItem(animatedIcon: false)`).

Catálogo: o estado "subtitulo" do `showSsCommandPalette` e "numero-direita" do `SsTextField`
(`flutter/test/catalogo_extras.dart`, `catalogo_onda2.dart`); o web não muda à vista (o subtítulo já estava no
catálogo). `paridade.yml`: sem par novo. Testes: `flutter/test/v1141_test.dart` e
`rails/sample/test/components/v1_14_1_web_test.rb`.

## v1.14.0: interface e animação (gráfico que se arrasta, período × anterior, linha que se expande, folha com 3 alturas, fundo de manchas, check que se desenha, cartão que inclina e a troca de aba)

A suíte mais bonita e agradável, nos dois lados com o mesmo nome. Tudo pelos tokens de movimento da v1.9 (`SsMotion` ↔
`--ss-dur-*`/`--ss-ease-*`/`--ss-bounce`; o teste reprova duração solta), com "reduzir movimento" desligando tudo
(`MediaQuery.disableAnimations` / `prefers-reduced-motion`) e **no máximo uma animação contínua por tela** (o fundo de
manchas ou o esqueleto, nunca os dois). Tokens novos de ritmo próprio: `SsMotion.pulse` (1,1 s) ↔ `--ss-dur-pulse` e
`SsMotion.ambient` (24 s) ↔ `--ss-dur-ambient`. Nada quebra na API: os parâmetros novos são opcionais. Duas mudanças
de padrão: o `SsKpiCard`/`SsStatCard` ↔ `KpiCardComponent` passam a rolar o número no odômetro (`animate: true`) e o
`SsNavScaffold` troca de aba com o eixo compartilhado (`tabTransition:`).

| Flutter | Rails | O que faz |
|---|---|---|
| `scrub:` (padrão `true`) e `onScrub: (int?)` em `SsLineChart`, `SsAreaChart`, `SsBarChart`; `SsTimeChart(scrub:)` com o `onScrub(DateTime?)` de sempre; `SsScrubDetector(onScrub:, onEnd:)` e `SsScrubDetector.indexAt` para o gráfico do produto | `scrub: true` (padrão `false`) em `LineChartComponent`, `AreaChartComponent`, `BarChartComponent` (em pé) e `TimeSeriesChartComponent`; controller `ss-scrub`, evento `ss-scrub:change` `{ index, label }` (`{ index, time }` no tempo; `index: null` ao soltar) | marcador que segue o dedo ou o mouse, valor e data no balão, vibração a cada ponto (`SsHaptics.selection` ↔ `haptic("selection")`), ← → Home End no web e o índice para a tela inteira acompanhar |
| `SsPeriodCompare(labels:, current:, previous:, title:, currentLabel:, previousLabel:, format:, higherIsBetter:, currentTotal:, previousTotal:, periods:, period:, onPeriodChanged:, onScrub:, card:)` | `Ss::PeriodCompareComponent(title:, labels:, current:, previous:, total:, previous_total:, money:, format:, higher_is_better: true, periods: [{ label:, href:, current: }], frame:, current_label:, previous_label:, delta:)` (`ss-period-compare`) | este período × o anterior no mesmo gráfico (o anterior como linha fantasma tracejada), o total no odômetro com o `SsDelta` (verde quando o sentido é bom) e a troca de período animada; arrastando, o número vira o do ponto contra o mesmo ponto do anterior |
| `SsExpandableRow(title:, subtitle:, value:, icon:, leading:, editor:, onSave: () → bool?, onCancel:, expanded:, onExpandedChanged:)` | `Ss::ExpandableRowComponent(title:, subtitle:, value:, url:, method: :patch, open:, save_label:, cancel_label:, edit_label:)` + bloco com os campos e slot `leading` (`ss-expandable-row`) | a linha se expande no lugar para a edição rápida: altura animada, foco no 1º campo, Salvar (o `false` mantém aberta para o erro), Cancelar e Esc devolvem o foco à linha |
| `SsSelectable`/`SsSelectionBar` (já animados: a barra sobe com a mola e o contador é o `SsOdometer`; agora com o `SsHaptics.selection`) | `Ss::SelectionBarComponent(actions: [{ label:, icon:, url:, method:, danger:, confirm: } \| { label:, href: }], name: "ids[]", label:)` + bloco com a lista (`.ss-select-item` ou `data-ss-selection-target=item\|all`), `ss-selection` (`ss-selection:change { ids, count }`) | seleção em massa: marcar com Shift (intervalo), a barra de ações entrando animada, o contador com odômetro, Esc limpa |
| `showSsSheet(detents: [.33, .5, 1], initialDetent:)`, `SsDetentSheet`, `showSsDetentSheet` | `Ss::DrawerComponent(detents: [0.33, 0.5, 1], detent:)` (no celular; alça `role=slider`, evento `ss-drawer:detent`) | folha com alturas fixas: arrastar a alça leva entre elas e, ao soltar, assenta com uma mola de verdade (a velocidade conta); abaixo da menor, fecha; ↑ ↓ na alça e "50% da tela" no leitor de tela |
| `SsNavItem(animatedIcon: true)` | `AppShellComponent(tabs: [{ label:, icon:, href:, current:, badge: }])`: a barra inferior do celular | ao virar a aba atual, o ícone chega girando ~20° com a mola e passa do contorno ao cheio |
| `SsMeshBackground(child:, colors:, animate:, radius:, veil:)`, `SsHeroCard(mesh: true)` / `SsHeroCard.custom(mesh: true)` | `Ss::MeshBackgroundComponent(tone: :deep\|:soft, animate: true)`, `HeroSectionComponent(mesh: true)` | manchas suaves da marca andando devagar atrás do cabeçalho de destaque; só gradientes radiais (sem desfoque), parado com reduzir movimento; o véu sobe sozinho até o texto claro passar de 4,5:1 em toda paleta (`SsMeshBackground.veilFor`, testado nas 30) |
| `SsKpiCard(animate: true)`, `SsStatCard(animate: true)`, `SsAmount(animate: false)` | `KpiCardComponent(animate: true)`, `ss_amount(text, animate: false)` (o `ss-odometer` da v1.9) | odômetro como padrão: o número parte dos zeros ao entrar e cada dígito gira ao mudar |
| `SsScreenHeader(collapseTint: true)` / `SsSliverHeader(collapseTint:)` | `PageComponent(collapse_tint: true)` (liga o `shrink`; `animation-timeline: scroll()`) | o título grande vira o pequeno e o fundo passa de transparente à superfície com sombra, junto com a rolagem |
| `SsSuccessCheck(size:, color:, filled:, play:, haptic:, sound:, label:, onDone:)`, `SsSounds.player = (SsSound s) => …` | `Ss::SuccessCheckComponent(size:, label:, sound: false, haptic: true)`, `.mark(css:)`, `ss-success-check` (`ssSuccess(el, { sound })`, evento `ss:sound { name: "success" }` no `window`) | o ✓ que se desenha (círculo e traço, com um pulinho), `SsHaptics.success` e o som curto opcional (o app fornece o player; o pacote só o gancho). Já no fim do `SsMorphButton`, do `SsSwipeToConfirm` e do `SsPixCard` pago (no web, `sound:` nos três) |
| `SsTiltCard(child:, enabled:, glass:, maxTilt: 6, radius:, shine:)` | `Ss::TiltCardComponent(glass: true, dense: false, href:)` (o `ss-tilt` responde ao toque; `data-ss-tilt-off`) | cartão de destaque que inclina ao toque ou ao mouse, com o reflexo de vidro seguindo; desligado com reduzir movimento e em tela de dados densos |
| `SsSharedAxisTransition(transitionKey:, index:, axis: SsSharedAxis.fadeThrough\|horizontal\|vertical)`, `SsTabHero(tag:, child:)`, `SsNavScaffold(tabTransition: SsSharedAxis.fadeThrough)` (padrão; `null` volta ao corte seco) | `AppShellComponent(tab_transition: true)` (`ss-tab-transition`, View Transitions com nome) + `ss_tab_hero(nome)` → `{ style:, data: }` (precisa do `ss_view_transitions_head`) | a troca de aba aparece esmaecendo e crescendo (fade through) em vez do corte seco; a peça com a mesma `tag` nas duas abas voa do lugar antigo ao novo |
| `SsSkeleton.of(child)` | `ss_skeleton_for(partial, count: 1, label:, css:, **locals)` | o esqueleto no formato real: sai da própria árvore (app: mede o widget e desenha um bloco por linha de texto, imagem, avatar e ícone tonal e o contorno dos cards; web: renderiza o partial e troca texto e imagem por blocos com o Nokogiri), com o pulso da v1.9; fora do toque e do leitor de tela ("Carregando…") |

**Limites.** O web do `ss_skeleton_for` precisa que o partial renderize com dados de exemplo nos `locals` (sem banco).
O scrub não vale para as barras deitadas. No app, a troca de aba anima só a chegada (o `IndexedStack` guarda as duas
telas; não há como pintar as duas juntas sem remontar), e o `SsTabHero` voa entre vagas de `IndexedStack`/`Offstage`.
O fundo de manchas do web não pausa fora da tela (só anima `transform`, o que é barato).

**Textos.** pt-BR, en e es: `SsInterfaceStrings` (`SsInterfaceStrings.of(context)`) ↔ `componentes_ui.interface.*` (as
mesmas chaves em snake_case; o teste do Flutter confere as chaves da gem). Acessibilidade: alvos de 48/44 (a alça da
folha tem 48), rótulos e valores no leitor de tela (a alça diz a altura; o comparador lê "R$ 4.870,00 neste período,
R$ 4.150,00 no anterior"), regiões vivas no que muda sozinho, `ssA11yAudit` nos testes novos.

**Ao subir nos produtos.** Teste que procura o valor de um `SsKpiCard`/`SsStatCard` com `find.text` passa a
`find.bySemanticsLabel` (os dígitos do odômetro são colunas) ou usa `animate: false`; o mesmo vale para o
`KpiCardComponent` no web (`animate: false`). Quem não quiser a troca de aba animada passa `tabTransition: null`.

**Onde cada peça entra nos produtos:**

- **meu-financeiro**: `SsPeriodCompare` em "Gastos do mês" (novembro × outubro, `higherIsBetter: false`); scrub com
  `onScrub` no gráfico de gastos para o total e a lista do dia acompanharem; `SsExpandableRow` no extrato para mudar o
  valor e a categoria sem abrir o lançamento; `SsTiltCard` no cartão de crédito; `SsHeroCard(mesh: true)` no saldo do
  início; `SsTabHero` do saldo entre Início e Extrato.
- **minhas-vendas**: `SsPeriodCompare` e scrub no painel de vendas (semana × anterior); seleção em massa
  (`SelectionBarComponent` com Shift) em pedidos e títulos; `SsExpandableRow` na quantidade e no desconto do item do
  pedido; `SsSuccessCheck` no pedido enviado e no Pix pago do PDV; `showSsSheet(detents:)` nos filtros do app de vendas
  externas.
- **meu-gestor**: `SsPeriodCompare` nos indicadores e metas; `SsSkeleton.of`/`ss_skeleton_for` nos cards de insight;
  `PageComponent(collapse_tint:)` nas telas longas de fluxo.
- **minhas-compras** e **minhas-viagens**: `showSsSheet(detents:)` no mapa/lista de ofertas e no "Onde comer";
  `SsTiltCard` no cartão da viagem e da conquista; `SsSuccessCheck` ao salvar o cupom lido.
- **meu-personal**, **meu-cultivo** e **meu-tempo**: `SsSuccessCheck` no treino concluído, na rega feita e no quiz
  respondido; `SsHeroCard(mesh: true)` no cabeçalho do dia; scrub nos gráficos de evolução.
- **Todos os apps**: o ícone animado da barra e a troca de aba com eixo compartilhado já vêm com a tag
  (`SsNavScaffold`); `SsScreenHeader(collapseTint: true)` nas telas principais; odômetro nos KPIs.

`paridade.yml`: 9 pares novos (`SsScrubDetector` → `js:ss-scrub`, `SsPeriodCompare`, `SsExpandableRow`, `SsDetentSheet`,
`SsMeshBackground`, `SsSuccessCheck`, `SsTiltCard`, `SsSharedAxisTransition`, `SsTabHero` → `helper:ss_tab_hero`),
`SsSelectionBar` ganha `Ss::SelectionBarComponent` e `js:ss-selection`, `SsSkeleton` ganha `helper:ss_skeleton_for`, e
3 apis (`SsSounds` → `js:ss-success-check`, `showSsDetentSheet`, `SsInterfaceStrings`). Vitrines: Novidades '1.14' e
as categorias "Movimento e transições", "Dados e gráficos", "Listas e tabelas", "Navegação e moldura" e "Retorno e
estados" (`rails/sample/app/views/vitrine/pecas_v1140.html.erb`). Catálogo: `flutter/test/catalogo_v1140.dart`
(`comV1140`) e as seções do `rails/catalogo/index.html` geradas por `rails/sample/script/catalogo_v1140.rb`. Testes:
`flutter/test/v1140_test.dart` e `rails/sample/test/components/v1_14_0_web_test.rb`. Capturas do web da v1.12, v1.13 e
v1.14 em 390 e 1440, claro e escuro, pela vitrine num container com o Playwright (`mcr.microsoft.com/playwright:v1.56.1-noble`).

## v1.13.0: confiança na IA e suíte (explicar o valor, prévia da IA, desde a última visita, continuar no outro aparelho, a suíte, o conflito, o valor falado e o modo discreto automático)

Peças que nenhum design system de mercado traz prontas, nos dois lados com o mesmo nome. Nada quebra na API: as peças
são novas e os parâmetros que entraram em peças antigas são opcionais. O pacote só **apresenta**: os dados, a IA,
gravar, desfazer, a lista de produtos, o reconhecimento de voz e os sensores são do produto (callback no app,
endpoint no web).

| Flutter | Rails | O que faz |
|---|---|---|
| `SsExplain(value:, title:, formula:, items: [SsExplainItem(label, value, subtitle:, onTap:)], more:, onMore:, onAskAi: () → Future<String>, onCancelAi:, child:)`, `SsExplainPanel(aiAnswer:)`, `showSsExplain` | `Ss::ExplainComponent(value:, title:, formula:, items: [{ label:, value:, href:, hint: }], more:, more_href:, ai_url:)` + bloco (`ss-explain`) | de onde vem o número: toque longo no app (e a ação "Ver de onde vem este valor" do leitor de tela), "?" no foco ou no hover no web; o valor, a fórmula ("Soma dos 23 lançamentos de nov"), o que compõe com link, "e mais N" e "Explicar com IA" com o `SsThinking`/`.ss-thinking` e Cancelar (a resposta que chega depois de cancelar é descartada) |
| `SsAiActionPreview(changes: [SsAiChange(id:, title:, subtitle:, fields: [SsFieldDiff(label, before:, after:)], selected:)], onApply:, onUndo:, onAdjust:, onCancel:)`, `showSsAiActionPreview` | `Ss::AiActionPreviewComponent(changes:, apply_url:, method:, param: "changes", adjust_href:, cancel_href:)` (`ss-ai-preview`) | o antes e depois campo a campo antes de a IA aplicar: removido (vermelho, riscado), novo (verde) e alterado (âmbar), sempre com o nome escrito; marcar e desmarcar cada alteração ("2 de 3 marcadas"), Aplicar (com a contagem), Ajustar, Cancelar; depois, o aviso "N alterações aplicadas · Desfazer" (`showSsUndo` ↔ `Ss::ToastComponent(undo_url:)`) |
| `SsChatActionCard(onReview:, reviewLabel:)` | `Ss::ChatActionComponent(review_dialog: "id")` | "Ver alterações" na ação que o assistente sugeriu: abre a prévia (folha no app, `Ss::DialogComponent` no web) |
| `SsSinceLastVisit(since:, items: [SsSinceItem(value:, label:, icon:, tone:, onTap:, actionLabel:)], store: SsLastVisit(read:, write:), autoHide:)`, `showSsSinceLastVisit` | `Ss::SinceLastVisitComponent(since:, items:, storage_key:, auto_hide:, src:)` (`ss-since`) | "Desde ontem às 18h: 3 pedidos novos, R$ 1.240 recebidos, 1 tarefa atrasada", com os números rolando (`SsOdometer(rollIn:)` ↔ `Ss::OdometerComponent(roll_in:)`) e uma ação em cada item; some em 12 s (não com o leitor de tela ligado) ou no "Entendi" e grava a visita (armazenamento do app ↔ `localStorage["ss-last-visit"]`; com `src:`, o web busca o resumo com o `%{since}` guardado) |
| `SsContinueOn(url:, target: SsContinueTarget.computer\|phone, onShare:)`, `showSsContinueOn`, `SsHandoff.link/encode/decode` | `Ss::ContinueOnComponent(url:, target: :phone\|:computer, state:, handoff_url:, form:)`, `ComponentesUi::Handoff`, `ss_handoff_link` (`ss-continue-on`) | "Continuar no celular" (web: QR do link profundo da tela atual) e "Continuar no computador" (app: o link e o QR); o estado (filtros, rascunho) vai no link em JSON base64url, igual nos dois lados (`docs/v1130/handoff.json`); no web, com `handoff_url:` + `form:`, o rascunho do formulário vai ao endpoint do produto, que devolve `{ url:, svg: }` (`Ss::ContinueOnComponent.payload(url)`) |
| `SsSuiteSwitcher(products: [SsSuiteProduct(id:, name:, icon:, color:, lastUsedAt:, badge:, active:, current:, description:, onOpen:, onDiscover:)])`, `SsSuiteSwitcher.section(context, …)` (menu lateral), `showSsSuiteSwitcher` | `Ss::SuiteSwitcherComponent(products: [{ id:, name:, icon:, color:, href:, last_used_at:, badge:, active:, current:, description:, discover_href: }])` no slot novo `with_suite` do `Ss::AppShellComponent` (ao lado do avatar) | os apps que a conta usa (ícone na cor do produto, nome, "Usado há 3 dias"/"Você está aqui", selo de avisos lido como "3 avisos") e "Conhecer" os outros; o pacote não sabe quais produtos existem |
| `SsConflictResolver(fields: [SsConflictField(key:, label:, mine:, theirs:)], onResolve: (Map<String, SsConflictSide>), mineAt:, theirsAt:, theirsBy:)`, `SsSyncPanel(conflictCount:, onResolveConflicts:)` | `Ss::ConflictResolverComponent(fields:, url:, method: :patch, param: "resolve", mine_at:, theirs_at:, theirs_by:)` (`ss-conflict`) | "Sua versão" × "Versão do servidor" campo a campo (só os diferentes; os iguais viram uma linha), "Ficar com a minha"/"Ficar com a do servidor" e "Salvar escolha"; no app abre da linha "2 registros em conflito · Resolver" do `SsSyncPanel`; no web serve ao registro velho (`lock_version`) |
| `SsSpeech.parseAmountPtBr(texto)`, `SsMoneyField(onVoice: () → Future<String?>)`, `SsSpokenAmount` | `ComponentesUi::Speech.parse_amount`, `ss_spoken_amount`, `Ss::MoneyInputComponent(voice: true)` (`ss-spoken-amount`, `ss_speech.js`) | o valor falado em centavos: "cento e vinte e três e cinquenta" → 123,50; "mil e duzentos reais" → 1.200,00; "dois mil e quinhentos e noventa centavos" → 2.500,90; "R$ 12,50" e "doze e meio" → 12,50. Os 86 casos de `docs/v1130/fala.json` passam no Dart, no Ruby e no JS. O microfone aparece no campo; o reconhecimento é do app (no web, o `SpeechRecognition` do navegador, quando existe, ou o evento `ss-spoken-amount:text` do produto) |
| `SsPrivacyScope(hidden:, auto: SsPrivacyAuto(signals: [SsPrivacySignal('face_down')], background:, blurSnapshot:))`, `SsPrivacyScope.autoReasonsOf` | `data-ss-privacy-auto-value="true"` no `ss-privacy` (evento `ss-privacy:auto` { reason, on }) | modo discreto automático: os valores somem enquanto um sinal do app está ligado (celular virado para baixo, tela compartilhada), com o app fora da frente (e a miniatura dos recentes desfocada) e, no web, na aba escondida (`visibilitychange`) e quando a própria página compartilha a tela (`getDisplayMedia`) |

**Regras do valor falado.** Grupos de até 999 por extenso, com "mil/milhão/bilhão" multiplicando (em ordem decrescente);
a palavra que não cabe mais no grupo começa os centavos ("doze e cinquenta", "cem e cinquenta" = 100,50); "reais"
fecha os reais; "centavos" no fim de um número de mil ou mais separa a dezena final (abaixo de mil conta ao pé da
letra: "noventa e nove centavos" = 0,99); "e meio" é 50 centavos, menos depois de "mil"/"milhão" ("um milhão e meio");
"vírgula" como na escrita; algarismos soltos ou misturados ("2 mil e 500", "1,5 mil", "12.50"); "menos" no começo.
A frase que não fecha ("mil mil", centavos acima de 99, "1234,567") dá `null`/`nil` e o campo avisa sem mexer no valor.

**Textos.** pt-BR, en e es: `SsTrustStrings` (`SsTrustStrings.of(context)`) ↔ `componentes_ui.trust.*` (as mesmas
chaves em snake_case). Acessibilidade: alvos de 48/44, rótulos do leitor de tela em toda peça (o diff é falado como
"Categoria. Alterado. Antes: Outros. Depois: Mercado"), regiões vivas no que muda sozinho, reduzir movimento e
durações só pelos tokens (`SsMotion` ↔ `--ss-dur-*`; o teste reprova duração solta); `ssA11yAudit` nos testes novos.

**Onde cada peça entra nos produtos:**

- **meu-financeiro**: `SsExplain` nos totais do mês, no saldo e nos pontos do gráfico de gastos (com o "Explicar com
  IA" do assistente); `SsAiActionPreview` na recategorização e na conciliação que a IA sugere; `SsMoneyField(onVoice:)`
  no lançamento rápido; `SsPrivacyScope(auto:)` no app inteiro; `SsSinceLastVisit` na abertura ("2 lançamentos do
  cartão, 1 conta vence amanhã").
- **minhas-vendas**: `SsSinceLastVisit` no painel ("3 pedidos novos, R$ 1.240 recebidos"); `SsConflictResolver` no
  app de vendas externas (pedido mudado offline e no escritório), aberto do `SsSyncPanel`; `SsContinueOn` do pedido no
  celular para o computador e do relatório do web para o celular; `SsExplain` nos KPIs do painel e na comissão.
- **meu-gestor**: `SsExplain` nos insights e indicadores (de onde vem a meta, o ranking); `SsAiActionPreview` antes de
  a IA mexer em fluxo, escala ou checklist; `SsSuiteSwitcher` com o minhas-vendas ao lado.
- **minhas-compras** e **minhas-viagens**: `SsAiActionPreview` no cadastro por foto/cupom (o que a IA leu × o que já
  estava) e `SsMoneyField(onVoice:)` no gasto da viagem.
- **Todos os produtos**: `SsSuiteSwitcher` no menu lateral (`SsSuiteSwitcher.section`) e no web ao lado do avatar
  (`with_suite`), com a lista que vem da API de licenças (`licencas`).

`paridade.yml`: 9 pares novos (`SsExplain`, `SsExplainPanel`, `SsAiActionPreview`, `SsSinceLastVisit`, `SsContinueOn`,
`SsSuiteSwitcher`, `SsConflictResolver`, `SsSpokenAmount` → `js:ss-spoken-amount`; `SsPrivacyScope` ganha o
`js:ss-privacy`) e 8 apis (`SsSpeech`, `SsHandoff`, `SsTrustStrings`, `SsLastVisit` e os `showSs*`). Vitrines: Novidades
'1.13' e as categorias "Conversa, IA e avisos", "Navegação e moldura", "Retorno e estados" e "Formulários e entrada"
(`rails/sample/app/views/vitrine/pecas_v1130.html.erb`). Catálogo: `flutter/test/catalogo_v1130.dart` (`comV1130`) e as
seções do `rails/catalogo/index.html` geradas por `rails/sample/script/catalogo_v1130.rb`. Testes:
`flutter/test/v1130_test.dart` e `rails/sample/test/components/v1_13_0_web_test.rb`.

**Ao subir nos produtos:** nada a trocar. Quem já usa `SsPrivacyScope` ganha o automático passando `auto:`; o
`SsMoneyField` só mostra o microfone com `onVoice:`.

## v1.12.0: Kit Brasil (Pix, boleto, NF-e, CEP, CPF/CNPJ) e o colar inteligente

Peças do Brasil nos dois lados, com o mesmo nome e a mesma conta. Nada quebra na API; tudo é novo. O pacote só
**exibe e confere**: gerar a cobrança, saber que pagou, buscar CEP/CNPJ e abrir a câmera são do produto (callback no
app, endpoint no web). Sem pacote nem gem nova: o QR Code é um gerador pequeno próprio (puro-Dart `SsQrCode` e Ruby
`ComponentesUi::Qr`, modo byte, versões 1 a 40, correção M, a mesma matriz nos dois, conferida módulo a módulo e
lida por um decodificador de QR na verificação).

| Flutter | Rails | O que faz |
|---|---|---|
| `SsPixCard(code:, amountCents:, receiver:, expiresAt:, status: SsPixStatus.waiting\|paid\|expired, qr:, onCopy:, onExpired:, onRegenerate:)` | `Ss::PixCardComponent(code:, amount_cents:, receiver:, expires_at:, status:, qr:, regenerate_href:)` | QR gerado do copia e cola (ou o pronto do PSP), valor e recebedor (lidos do BR Code se não vierem), validade com contagem (zera → expirado sozinho), "Copiar código" com retorno, pago com o ✓ na mola (`SsMotion.spring`/`--ss-bounce`, reduzir movimento desliga) e expirado com "Gerar outro código" |
| `SsPixKeyField(type:, onChanged: (chave, tipo))` | `f.ss_pix_key(:campo, type:)` (`ss-pix-key`) | detecta CPF, CNPJ, telefone, e-mail ou aleatória enquanto digita, mostra o tipo embaixo, formata ao sair; a chave da API sai de `SsBr.pixKeyNormalize`/`Br.pix_key_normalize` |
| `SsBoletoField(onChanged:, onScan:)` + `SsBoletoMask` | `f.ss_boleto(:campo)` (`ss-boleto`) | linha digitável de 47 (bancário) ou 48 (arrecadação) com máscara, DV módulo 10/11, valor e vencimento embaixo (vencido em âmbar); colar o código de barras de 44 vira a linha; no app, "Ler código de barras" pelo `onScan` (a câmera é do app) |
| `SsCepField(onLookup: (cep) → SsAddress?, street:, district:, city:, state:, onAddress:, autoLookup:)` | `f.ss_cep(:campo, lookup_url: "/cep/%{cep}", fill: { street: "id", … })` (`ss-cep`) | máscara e, com os 8 dígitos, o endpoint do produto preenche os campos ligados; não achou/falhou diz e deixa preencher; resposta velha não passa por cima |
| `SsDocumentField(kind: SsDocumentKind.any\|cpf\|cnpj, onLookup: (cnpj) → razão?)` | `f.ss_document(:campo, kind:, lookup_url: "/cnpj/%{cnpj}")` (`ss-document`) | o `mask: :document` com detecção CPF/CNPJ (o alfanumérico de 2026 também: DV com ASCII − 48), DV e a razão social embaixo |
| `SsNfeCard(accessKey:, issuer:, issuerCnpj:, issuedAt:, amountCents:, status: SsNfeStatus.*, qrUrl:, onOpen:)` | `Ss::NfeCardComponent(access_key:, issuer:, issuer_cnpj:, issued_at:, amount_cents:, status:, qr_url:, open_href:)` | chave em 11 blocos de 4 com copiar e o DV conferido (errado: aviso), modelo/número/série/CNPJ lidos da chave, data, valor, situação e o QR da consulta |
| `SsSmartPaste(actions: {SsPasteType.boleto: [SsPasteAction('Pagar', (m) => …, primary: true)]}, onDetected:)` | `Ss::SmartPasteComponent(actions: { boleto: [{ label:, href: "…%{value}", method:, icon:, primary: }] })` (`ss-smart-paste`) | o colar inteligente (abaixo) |
| `SsQrImage(data:, size:, semanticLabel:)` / `SsQrCode.encode` | `ss_qr_svg(texto, label:)` / `ComponentesUi::Qr` | o QR, módulo escuro em fundo claro em qualquer tema |

**Colar inteligente.** A pessoa cola qualquer coisa e o cartão diz o que é ("Isso parece um boleto de R$ 123,45 com
vencimento em 10/12/2026") com as ações que o produto registrou para o tipo. O detector é puro e igual nos três
lados: `SsPasteDetector.detect(texto) → SsPasteMatch` (Dart), `ComponentesUi::PasteDetector.detect` (Ruby, para o
servidor e a 1ª pintura) e `ssDetect` do `ss_br.js` (o retorno ao vivo no Stimulus). Tipos, na ordem: `pix` (copia e
cola, BR Code EMV com CRC16), `url` (com a chave da NFC-e dentro vira `nfe`), `date`, os só de números (`boleto`
47/48, `nfe` ou código de barras 44, `cnpj`, `cpf` ou `phone` 11, `phone` 10, `cep`), `phone` (+55), `email`,
`pix_key` (aleatória), `cnpj` alfanumérico, `money` (R$), `url` (domínio solto) e `text`. `valid` diz se o DV (ou o
CRC, ou a data) confere; com DV errado o cartão avisa e não mostra ação. CPF, CNPJ, telefone e e-mail válidos têm
`also: [pix_key]`, então mostram também as ações de chave Pix. `fields` tem as mesmas chaves nos três (`amount_cents`,
`due_date`, `name`, `key`, `uf`, `model_name`, `domain`…). Os 57 exemplos de `docs/v1120/exemplos.json` (gerados por
`rails/sample/script/exemplos_v1120.rb`, com DV calculado e sem dados de pessoas reais, mais as matrizes do QR) passam
nos três: no teste do Dart, no do Ruby e no `rails/sample/test/js/ss_br_check.mjs` (node; o teste Ruby roda quando há
node no PATH).

**Contas e formatadores.** `SsBr` (Dart) ↔ `ComponentesUi::Br` (Ruby) ↔ `ss_br.js`: `cpfValid`, `cnpjValid`
(alfanumérico), `documentKind`, `phoneValid`/`phoneE164`, `pixKeyType`, `mod10`, `mod11Bank`, `mod11Dv`,
`boletoLineFromBarcode`; `SsBoleto.parse` (vencimento pelo fator, no ciclo novo de 22/02/2025 quando é o mais perto de
hoje), `SsNfeKey.parse`, `SsPixCode.parse`/`build` (o copia e cola estático, para exemplo e Pix de balcão sem PSP).
Formatadores: `SsFormats.brl.cpf/cnpj/cep/phoneBr/boleto/nfeKey` ↔ `ss_cpf`, `ss_cnpj`, `ss_cep`, `ss_phone_br`,
`ss_boleto`, `ss_nfe_key` (e `ss_document`, `ss_paste_summary`).

**Textos.** pt-BR, com en e es só traduzindo a interface (o formato do dado continua o brasileiro): `SsBrStrings`
(`SsBrStrings.of(context)`, pelo idioma do `SsStrings`) ↔ `componentes_ui.br.*` (as mesmas chaves em snake_case; os
moldes da frase do colar vão ao JS). Acessibilidade: alvos de 48/44 (`--ss-target`), retorno embaixo dos campos como
região viva, QR com nome no leitor de tela, `ssA11yAudit` nos testes novos (padrão e compacto); movimento pelos tokens.

**Quem se beneficia:**

- **minhas-vendas**: `SsPixCard` no PDV e no pedido (Pix da cobrança), `SsBoletoField` nas contas a pagar,
  `SsNfeCard` na entrada pela NF-e e no pedido faturado, `SsDocumentField` com a razão social no cadastro de cliente e
  fornecedor, `SsCepField` no endereço.
- **meu-gestor**: `SsNfeCard` no recebimento de compra (NF-e × pedido) e o colar inteligente para conferir a chave.
- **meu-financeiro**: `SsBoletoField` e `SsSmartPaste` para lançar boleto, Pix (copia e cola ou chave) e valor colados;
  `SsPixKeyField` nos favorecidos.
- **minhas-compras**: `SsNfeCard` e o colar com a URL do QR da NFC-e do cupom (vira `nfe` com a chave).

Vitrine: `rails/sample/app/views/vitrine/pecas_v1120.html.erb` em "Comércio e finanças" e "Formulários e entrada"
(Novidades da v1.12), com os endpoints de exemplo `/demo/cep/:cep` e `/demo/cnpj/:cnpj`. Catálogo:
`flutter/test/catalogo_v1120.dart` (`comV1120`) e as seções `ss-pix-card`, `ss-nfe-card`, `ss-smart-paste` e
`ss-br-fields` do `rails/catalogo/index.html` (`rails/sample/script/catalogo_v1120.rb`). `paridade.yml`: 8 pares novos
e 8 apis. Testes: `flutter/test/v1120_test.dart` e `rails/sample/test/components/v1_12_0_web_test.rb`.

## v1.11.0: adaptativa (o pacote pronto para os apps irem ao iOS sem perder o padrão da suíte)

Os apps da suíte rodam no iOS com o mesmo pacote. Nada quebra na API: os parâmetros novos são opcionais e, no
Android, nenhum desenho muda. No iOS, as peças abaixo trocam o desenho e o comportamento pelo do sistema, com a
mesma API e a mesma volta. Tudo foi testado no Fedora, sem Mac, com `ThemeData(platform: TargetPlatform.iOS)` e
`debugDefaultTargetPlatformOverride` nos testes de widget (`flutter/test/v1110_test.dart`).

**Detecção e saída.** `SsPlatform.of(context)` lê `Theme.of(context).platform` (iOS e macOS contam como Apple);
`SsPlatform.cupertino(context, adaptive:)` decide. Toda peça adaptativa tem `adaptive` (padrão `true`); `false` fica
no desenho da suíte. Para o app inteiro: `MaterialApp(builder: (c, child) => SsPlatformScope(adaptive: false, child:
child!))`, que também prende a rolagem (sem elástico). `SsPlatform.backIcon` (o "‹" no iOS), `SsPlatform.scrollPhysics`
e `SsPlatform.actionSheetMax` (8). No web, `ss_platform`/`ss_apple_platform?` dizem a plataforma pelo User-Agent
(o desenho web não muda).

**Peças Cupertino.** No Flutter 3.50, o `package:flutter/cupertino.dart` está obsoleto (como o Material, saiu do SDK):
as peças vêm do pacote `cupertino_ui` (^1.1.1), de que o `material_ui` já dependia; o pacote passa a depender dele
direto. Os apps não importam nada do Cupertino: a conformidade continua reprovando `Cupertino*` no app.

| Peça | No iOS (com `adaptive`) |
|---|---|
| `AppTheme.build` | `CupertinoPageTransitionsBuilder` no iOS e no macOS (voltar de arrastar da borda); o Android segue o voltar preditivo |
| `SsSwitch` / `SsSwitchRow` | desenho e arrasto do `CupertinoSwitch`, trilha na cor da marca, alvo de 48 e o mesmo haptic; a linha não espalha tinta |
| `showSsDatePicker` / `showSsTimePicker` / `SsDateField` / `SsTimeField` | a roda do `CupertinoDatePicker` numa folha (Cancelar, título, Confirmar na cor da marca), com os limites, o `selectableDayPredicate`, 24 h e dia/mês/ano pelo idioma |
| `showSsPicker` | com `items:` de até 8 (sem `load`, `allowCustom`, `noneLabel`, `actions`, `itemBuilder`): a folha de ação do iOS com o `title`; o resto segue a folha de busca |
| `SsOverflowMenu` / `SsContextMenu` | a folha de ação (`CupertinoActionSheet`): destrutiva em vermelho, ✓ das marcadas, Cancelar separado; o ⋮ vira ⋯ |
| `showSsConfirm` | `CupertinoAlertDialog`: Cancelar à esquerda; com `danger`, a confirmação é a destrutiva (vermelha) e o Cancelar fica em negrito |
| listas do pacote | rolagem com elástico (`BouncingScrollPhysics`), que o `ScrollConfiguration` do `MaterialApp` já tira da plataforma do tema; `SsPlatformScope(adaptive: false)` prende |
| `SsPullToRefresh` | `CupertinoSliverRefreshControl` como 1ª fatia (`ListView`, `GridView`, `CustomScrollView` e conteúdo solto); quem monta a própria rolagem (`SingleChildScrollView`, `NestedScrollView`, `SsSelfScrolling`) fica com o indicador da suíte. `SsScreenHeader(onRefresh:)` põe o controle do iOS logo abaixo do cabeçalho |
| `SsHaptics` | seleção → `selectionClick`; sucesso, aviso e erro → `successNotification`/`warningNotification`/`errorNotification` (um toque, o `UINotificationFeedbackGenerator`); `SsHaptics.adaptive = false` volta ao mapa do Android |
| `SsSheet` / `showSsSheet` | o × de fechar no canto (lá não há voltar do sistema); `showClose:` força ou tira; `dismissible: false` não tem × |
| `SsScreenHeader` / `SsTopBar` | o "‹" do iOS no voltar automático |
| `SsNavBar` | continua a da suíte (é a marca); já soma o `viewPadding.bottom` (o home indicator, 34) |

**Voltar no iOS e o menu lateral.** No iOS, voltar é arrastar da borda esquerda, justo onde ficam a alça e a faixa do
`SsSideMenuHost`. Com `adaptive` e no iOS:

- **rota empilhada** (a tela do host está por cima de outra, ou um `Navigator` de dentro do `child` pode voltar, como
  o `ShellRoute` do go_router com uma tela aberta, lido pela `NavigationNotification`): a alça e a faixa saem, a dica
  ao abrir não roda e o voltar do sistema vence. O menu ainda abre por `SsSideMenuHostState.open()`;
  `SsSideMenuHostState.yieldsToBack` diz se cedeu;
- **telas principais** (a raiz): a alça fica, como no Android;
- `SsSideMenuHost(adaptive: false)` / `SsNavScaffold(adaptive: false)` deixa a alça sempre.

Toda tela empilhada do pacote tem voltar ou fechar visível: `SsScreenHeader` e `SsTopBar` (voltar automático com
`canPop`), `SsFullscreenPage` (×) e `SsSheet` (× no iOS; no Android, o voltar do sistema). Ilha dinâmica e texto
grande: o `SsScreenHeader` desce pelo `MediaQuery.padding.top`, o `SsTopBar` e a `SsFullscreenPage` ficam no
`AppBar` do `Scaffold` (área segura), a folha abre com `useSafeArea` e fica abaixo da ilha; os testes conferem com
`padding.top = 59`, `bottom = 34` e texto 1,6×.

**Entrar com a Apple.** `SsAppleButton(onPressed:, style: black|white|outline, label: continueWith|signIn, text:)` no
desenho das Human Interface Guidelines: logo da Apple (o glifo em SVG de 24 × 24, o mesmo `<path>` nos dois lados),
"Continuar com a Apple"/"Entrar com a Apple" (pt, en, es: `SsStrings.appleContinue`/`appleSignIn`), altura 50 e raio
14 como o `SsGoogleButton`; sem `style`, preto no claro e branco no escuro. `SsAppleButton.icon` é o quadrado só com o
logo. Espaço na entrada: `SsAuthLayout(providers: [SsGoogleButton(onTap: g), SsAppleButton.icon(onPressed: a)])` (vale
no `.cartaz` e no `.folhinha`; a linha é o `SsAuthProviders`). Web: `Ss::AppleButtonComponent(href:, label: :continue |
:sign_in | "texto", style: :black | :white | :outline, method: :post | :get, compact:)` e o slot `with_provider` do
`Ss::AuthLayoutComponent` (`.ss-auth-providers`). Sem `href:`, é um `<button type=button>` para o Sign in with Apple JS,
que fica com o produto (script, `AppleID.auth.init` e o clique). O texto usa a Manrope do tema, não a SF do sistema.

**Compras no iOS.** No iOS, recurso digital (plano Pro/Max, cota de IA, conteúdo) **só pode ser vendido pela compra
dentro do app da Apple** (StoreKit; diretriz 3.1.1 da App Store): nada de botão, link ou texto levando ao checkout web
(`/assinar/<produto>` das Licenças, Mercado Pago). As peças de plano não amarram a loja: `SsPlanOffer(ctaLabel:,
onBuy:)` e `SsPlansView(onRestore:, onManage:)` recebem o texto e a ação do app (no iOS, a compra da Apple e o
"Restaurar compras"). Nada no pacote abre URL nem leva a checkout web (conferido em `lib/`). Venda de bem ou serviço
físico (pedido do minhas-vendas) continua fora da regra.

**Checklist do que um app da suíte precisa para ir ao iOS** (o pacote cobre o desenho; o resto é do app):

- [ ] **Mac ou runner macOS**: o build do iOS (`flutter build ipa`) só roda no macOS com Xcode. Nesta máquina (Fedora)
      não há; a CI precisa de um runner `macos-*` do GitHub ou de um Mac na rede. O desenho se confere aqui pelos testes.
- [ ] **Entrar com a Apple**: app com entrada pelo Google precisa oferecer também uma entrada com a mesma proteção de
      privacidade (diretriz 4.8); a da Apple é a que passa sem discussão. Capability "Sign in
      with Apple" no Xcode, o `sign_in_with_apple` no app, o Services ID e a chave no Apple Developer, e o backend que
      valida o `identityToken`. Na tela, `SsAppleButton` no `providers:`.
- [ ] **Compra pela Apple**: produtos e assinaturas no App Store Connect, `in_app_purchase` (StoreKit 2), validação do
      recibo no servidor e o aviso às Licenças. Nenhum caminho para o checkout web no iOS. "Restaurar compras" visível.
- [ ] **Textos de permissão no `Info.plist`** (em pt-BR, dizendo para quê): `NSCameraUsageDescription` (foto, cupom),
      `NSPhotoLibraryUsageDescription`, `NSMicrophoneUsageDescription` (ditado), `NSLocationWhenInUseUsageDescription`,
      `NSFaceIDUsageDescription` (biometria do `SsLockScreen`), `NSContactsUsageDescription` se usar. Sem o texto, o
      app cai ao pedir.
- [ ] **Rede local**: o que fala com aparelho na rede (minha-automacao, impressora) precisa de
      `NSLocalNetworkUsageDescription` e do `NSBonjourServices` com os tipos (`_hap._tcp` etc.); HTTP sem TLS precisa
      de exceção no `NSAppTransportSecurity`.
- [ ] **HealthKit** (meu-personal): capability HealthKit, `NSHealthShareUsageDescription`/`NSHealthUpdateUsageDescription`
      e o pacote `health` no lugar do Health Connect do Android.
- [ ] **WidgetKit**: o widget da tela inicial do iOS é uma extensão em Swift (WidgetKit) com App Group para ler os dados
      do app (`home_widget`); o widget Android não serve lá.
- [ ] **Push**: APNs (chave .p8 no Firebase) e a capability Push Notifications.
- [ ] **TestFlight**: conta Apple Developer (US$ 99/ano), app no App Store Connect, assinatura (certificado e perfil),
      build pela CI no macOS e o teste interno no TestFlight antes da revisão; a ficha pede capturas do iPhone (6,9") e,
      se o app roda no iPad, do iPad (13").
- [ ] **Exclusão de conta dentro do app** (diretriz 5.1.1(v)), como já pede a Play.

Fora desta versão: a roda e a folha de ação usam o desenho do iOS mas com a fonte do tema (a SF não está no pacote
nem nos testes); a `SsNavBar`, a alça e a casca continuam as da suíte; o `SsDateField` segue com os chips de atalho.

### Acertos da v1.10 (web)

- `--ss-viewer-bg` (o fundo do visor de foto) sem `black`: `color-mix(…, var(--side))`.
- `CurvedHeaderComponent(tone: :dark)` quase sumia no tema escuro (o `--side` é quase a página): agora
  `color-mix(in srgb, var(--side) 82%, var(--ink))`, que levanta no escuro e quase não muda no claro.
- As ondas do `PulseAvatarComponent` quase não apareciam no claro: 34% da cor e um aro de 1,5 px; no escuro, as de antes.

O `paridade.yml` ficou com 298 pares, 13 apis, 34 só app, 10 só web e nenhuma dívida (novos: `SsAppleButton` ↔
`Ss::AppleButtonComponent`, `SsAuthProviders` ↔ `Ss::AuthLayoutComponent`, `SsPlatform` ↔ `helper:ss_platform` e
`SsPlatformScope` só app). Catálogo: `flutter/test/catalogo_v1110.dart` (`comV1110`; o `Estado(plataforma:)` força a
plataforma do estado, também na vitrine do app) e as seções `ss-apple-btn`, `ss-curved-v1110` e `ss-pulse-v1110` do
`rails/catalogo/index.html` (`rails/sample/script/catalogo_v1110.rb`). Vitrine web: `pecas_v1110` em "Novidades
(v1.11)". Testes: `flutter/test/v1110_test.dart` e `rails/sample/test/components/v1_11_0_web_test.rb`.

## v1.10.0: a dívida de paridade zerada (21 pares web e 5 peças novas no app)

A regra da suíte é web e app com as mesmas funcionalidades, e o `paridade.yml` diz qual peça de um lado responde pela do
outro. Esta versão fecha o que estava anotado como dívida: as seções `divida:` e `divida_app:` ficam vazias (`{}`), e os
dois testes de paridade (`flutter/test/v19_paridade_web_test.dart` e `rails/sample/test/components/v19_paridade_web_web_test.rb`)
cobram que continue assim. Nada quebra na API. O `Ss::EmptyStateComponent(illustration:)` passa a ler o SVG do
`Ss::IllustrationArtComponent`, com a mesma saída.

### Web: os pares Rails das 21 peças que só existiam no Flutter

Componente, Stimulus e CSS (`rails/app/assets/tailwind/componentes_ui/v1100_web.css`, importado no `engine.css`). O CSS
usa só tokens, com `--on-accent` no lugar do branco e as durações dos `--ss-dur-*`, e respeita a densidade, o alvo de 44
(`--ss-target`) e o reduzir movimento. Os textos ficam em `componentes_ui.*` (pt/en/es), os mesmos do `SsStrings`.
Vitrine: `rails/sample/app/views/vitrine/pecas_v1100.html.erb`. Catálogo: `rails/catalogo/index.html` (gerado por
`rails/sample/script/catalogo_v1100.rb`).

| Flutter | Rails | Controller |
|---|---|---|
| `SsAttachBar` | `Ss::AttachBarComponent(items: [{ icon:, label:, accept:/name:/form: (arquivo) \| href: \| data: (botão), tone: 1..6, color: }], size:)` | — (CSS) |
| `SsCardStack` | `Ss::CardStackComponent(card_height:, peek:, gap:, initially_open:)` + `with_card`; evento `ss-card-stack:change { open }` | `ss-card-stack` |
| `SsCurvedHeader` | `Ss::CurvedHeaderComponent(title:, subtitle:, tone: :brand\|:dark, curve:, overlap:, back_href:, back_label:, heading:)` + `with_leading`/`with_action`/`with_bottom`; conteúdo que sobe: `.ss-curved-body` | — |
| `SsDial` | `Ss::DialComponent(value:, name:, min:, max:, step:, label:, caption:, format: "%.1f°", size:, ticks:, disabled:)`; `role=slider`, hidden `name:`, `ss-dial:change { value }` | `ss-dial` |
| `SsDuoStat` | `Ss::DuoStatComponent(items: [{ label:, value:, icon:, href: }] × 2, index:, name:)`; `ss-duo:change { index }` | `ss-duo` |
| `SsFloatingBars` | `Ss::FloatingBarsComponent(values:, labels:, selected:, format: :qty\|:money\|:integer\|lambda\|"%…", title:, value:, height:, href: "…%{index}")`; `ss-floating-bars:change { index }` | `ss-floating-bars` + `ss-in-view` |
| `SsGoalCard` | `Ss::GoalCardComponent(text:, action_label:, href:, icon:, action_data:)` + `with_art` | `ss-in-view` |
| `SsHexButton` | `Ss::HexButtonComponent(href:, label:, icon:, size:, type:, form:, name:, value:, disabled:)` | — |
| `SsIllustratedSplit` | `Ss::IllustratedSplitComponent(title:, text:, illustration:, action_label:, action_href:, secondary_label:, secondary_href:, page:, pages:, heading:)` + `with_art` | — |
| `SsIllustrationArt` | `Ss::IllustrationArtComponent(:empty\|:offline\|:no_results\|:all_done\|:error, size:)`; o `EmptyStateComponent::ILLUSTRATIONS` agora lê daqui (API igual) | — (CSS do v1.9) |
| `SsIllustrationStage` | `Ss::IllustrationStageComponent(height:, padding:)` + bloco | — |

| `SsImageViewer` / `showSsImageViewer` | `Ss::ImageViewerComponent(src:, title:, semantic_label:, max_scale:, thumb_size:, inline:)` + `with_trigger`, `with_action` | `ss-image-viewer` |
| `SsMonthGrid` | `Ss::MonthGridComponent(month:, selected:, url: "…%{date}", name:, month_url: "…%{month}", markers:, today:, turbo_frame:)` | `ss-month-grid` |
| `SsPeoplePicker` | `Ss::PeoplePickerComponent(people:, name:, selected:, add_url:, add_label:, legend:)` (checkbox por pessoa) | — (CSS `:has(:checked)`) |
| `SsPopOutCard` | `Ss::PopOutCardComponent(title:, subtitle:, price:, image_url:, url:, add_url:, add_method:, add_params:, image_height:, pop_out:, tone:, action_icon:, action_label:)` + `with_image` | — |
| `SsProfileHero` | `Ss::ProfileHeroComponent(name:, photo_url:, status:, online:, metrics: [[valor, rótulo]])` + `with_leading`, `with_action` | — |
| `SsPulseAvatar` | `Ss::PulseAvatarComponent(name:, active:, size:, tone:, status:)` (bloco troca o avatar) | — |
| `SsRecurringCard` | `Ss::RecurringCardComponent(schedule:, amount:, time:, destination:, done:, url:, menu_url:)` + `with_menu` | `ss-odometer` (valor) |
| `SsShapeIcon` | `Ss::ShapeIconComponent(icon:, shape: :losango\|:hexagono, tone:, filled:, size:, label:)`; `Ss::ShapeIconComponent.path(shape, s)` | — |
| `SsThumbRail` | `Ss::ThumbRailComponent(images:, selected:, target:, url: "…%{index}", thumb_size:, height:)` | `ss-thumb-rail` |
| `SsVerticalSlider` | `Ss::VerticalSliderComponent(name:, value:, min:, max:, step:, label:, suffix:, precision:, format:, height:, width:, tone:, disabled:)` | `ss-vslider` |


Notas:

- Textos novos: `card_stack.open/close`, `curved_header.back`, `hex_button.start`, `illustrated_split.page`,
  `image_viewer.*`, `month_grid.*` e os das outras peças do lote B (ver `componentes_ui.pt-BR.yml`, no fim).
- O `Ss::PopOutCardComponent` segue a API do `SsPopOutCard` (o cartão de planta e produto do app). O
  `Ss::ProductCardComponent` (a grade da loja, com selo) continua separado e agora tem o `SsProductCard` como par.
- O fundo do visor de imagem é `--ss-viewer-bg`: a marca funda misturada ao preto, como o `headerDarkBg` do app.
- O `SsImageViewer` no web é um `<dialog>` com zoom por roda, pinça, duplo clique, botões e teclado (+ − 0 e setas).
  Também dá para arrastar a foto ampliada, e o Esc fecha. O `SsMonthGrid` usa links (`url:`) ou botões com `name:`,
  e o PageUp/PageDown troca o mês.

### App: os pares Flutter que faltavam (`flutter/lib/src/v1100/`)

Saíram do `so_web` o `FilterBarComponent`, o `JobProgressComponent`, o `TreeViewComponent` e o `PopoverComponent`,
porque o celular também precisa deles. O `ProductCardComponent` saiu do `divida_app`.

| Rails | Flutter |
|---|---|
| `Ss::ProductCardComponent` | `SsProductCard(name:, price:, text:, image:/imageUrl:, onTap:, action: SsProductAction(label, onPressed, icon:), badge:, overhang: 64)` |
| `Ss::FilterBarComponent` | `SsFilterBar(filters: [SsFilterGroup(param:, label:, options: [SsFilterOption(label, value)], multiple:)], values: SsFilterValues, onChanged:, views: [SsFilterView(label, values:, count:)], count:, onSearch:, searchHint:)` |
| `Ss::FilterBarComponent` | `SsFilterSheet(filters:, values:, count:, onApply:, title:)` e `showSsFilterSheet(context, …) → Future<SsFilterValues?>`: "Mostrar N resultados" ao vivo (o `count` pode ser assíncrono, e a resposta velha não passa por cima da nova), chips do que está ativo e "Limpar filtros". Utilitários em `SsFilters.active/toggle/remove/same/count` |
| `Ss::JobProgressComponent` | `SsJobProgress(title:, state: SsJobState.queued\|running\|done\|failed, progress:, steps:, currentStep:, stages: [SsJobStage(name, status:, duration:, durationLabel:, detail:)], total:, detail:, error:, onOpenResult:, resultLabel:, onRetry:, onCancel:, cancelling:, flush:)` |
| `Ss::TreeViewComponent` | `SsTreeView(nodes: [SsTreeNode(label, id:, value:, count:, children:, open:, onTap:)], label:, wrap:, selection: none\|single\|multiple, selected:, onSelectionChanged:)`. No modo múltiplo, o galho marca as folhas e fica "misturado" quando só parte está marcada |
| `Ss::PopoverComponent` | `SsPopover(label:, child:, title:, icon:, triggerBuilder:, placement: bottomStart\|bottomEnd\|topStart, maxWidth: 352)`, `showSsPopover(anchorCtx, …)` e `SsPopover.close(ctx)`: ancorado, com seta, fecha ao tocar fora, no voltar e no Esc, e abre para cima quando falta espaço embaixo |

Textos novos no `SsStrings` (pt/en/es): `filters`, `filtersActive`, `filterClear`, `filterShow`, `filterRemove`,
`filterButton`, `filterShowResults`, `jobQueued`, `jobRunning`, `jobDone`, `jobFailed`, `jobError`, `jobResult`,
`jobTotal`, `jobStageDone`, `jobStageFailed`, `jobStageSkipped`, `jobStageRunning`, `jobStagePending`, `treeLabel` e
`treeCount`.

Ficou assim o `paridade.yml`: 296 pares, 12 apis, 33 só app, 10 só web e nenhuma dívida (antes eram 269 pares, 10
apis, 14 só web, 21 dívidas web e 1 dívida app). As vitrines passam a mostrar a v1.10 em "Novidades"
(`versaoNovidades`/`NOVIDADES`). Catálogo: `flutter/test/catalogo_v1100.dart` (`comV1100`). Testes:
`flutter/test/v1100_test.dart` (com `ssA11yAudit`) e `rails/sample/test/components/v1_10_0_web_test.rb`.

## v1.9.3: o que a conferência no emulador dos 8 apps achou

Conferência das peças v1.9 nos 8 apps, no emulador Android, em 27/11/2026. Nada quebra na API; `SsSideRail(edgeToEdge:)`,
`SsSideMenuHost.gestureFreeLeft`, `SsNavBar.minLabelSize`, `SsQuota.quotaText`, `ssJoinSentences` e o `target:` do
`Ss::ButtonComponent` são novos.

- **`SsSideMenuHost`: a alça e a faixa de arrastar saem da faixa de gesto do sistema.** No Android com navegação por
  gestos, o arraste que começa nos primeiros ~24 dp da borda é o "voltar" do sistema e não chega ao app: arrastar a alça,
  como o tour manda, voltava e fechava o app na 1ª aba. O Flutter 3.50 não tem como pedir a exclusão do gesto (o
  `View.setSystemGestureExclusionRects` do Android não está no canal da plataforma; conferido no `flutter.jar` do engine),
  então a alça e a faixa começam em `SsSideMenuHost.gestureFreeLeft(mq)` (`systemGestureInsets.left` + `padding.left`).
  Com gesto, a pílula fica solta da borda, com as duas pontas arredondadas; tocar nela abre o menu e arrastar a partir dela
  também. Na navegação por botões, no iOS e nos testes (inset 0) continua colada na borda. A pílula passa a ficar por cima
  dos primeiros pixels do conteúdo (lista com margem de 16), em opacidade baixa.
- **`SsAdaptiveScaffold`/`SsSideRail` na tela larga**: cada aba do trilho é um nó do leitor de tela com o toque
  (`"Início, aba 1 de 5"`, selecionada, o mesmo texto da `SsNavBar`). Antes o `excludeSemantics` tirava o toque e o
  Android não listava as abas. `railHeader`/`railFooter` são grupos próprios. Com `edgeToEdge: true` (o
  `SsAdaptiveScaffold` liga) o trilho pinta sob a barra de status, a de navegação e o recorte da esquerda, e afasta o
  conteúdo pelo `MediaQuery.padding`; antes o `SafeArea` deixava uma faixa clara no topo.
- **`SsNotificationBell`**: um nó só, "Notificações, 3 não lidas", com o plural de `SsStrings.notifUnreadCount`
  ("1 não lida"; en "Notifications, 3 unread"; es "Notificaciones, 1 no leída"), com o número de verdade acima de 99.
  Antes o leitor lia só o "3" do selo. **Padrão que mudou:** o nome padrão era "Avisos" e agora é `SsStrings.notifications`
  (`label:` passou a `String?`). Quem quer "Avisos" passa `label: 'Avisos'`. Teste que procurava a dica
  `'Avisos, 3 não lidos'` passa a procurar `'Notificações, 3 não lidas'`. No web o sino segue "Avisos" (é o título
  visível do popover) e ganhou o singular: "Avisos, 1 não lido" (`componentes_ui.bell.unread_single`, também no
  `ss-bell` ao atualizar a contagem).
- **Selo largo** ("12", "99+") no `SsIconButton(badge:)`: cresce para a esquerda (a ponta direita fica onde fica a do selo de
  um dígito). O sino limita a escala de texto do selo a 1,3×. Com texto 1,6× o "99+" era cortado na borda do botão.
- **`SsNavBar` com texto 1,6×**: o rótulo da aba encolhe só ele até caber, com 2 de respiro de cada lado e piso em
  `SsNavBar.minLabelSize` (10). Só abaixo do piso termina em "…". Antes saía "Lançam…" e "Assisten…". Ícone e alvo de toque
  não mudam.
- **`SsStatCard`**: o rótulo quebra em até 3 linhas em vez de cortar. Se a palavra mais longa não cabe ao lado do ícone
  (2 colunas de 360 a 1,6×), o ícone sobe e o rótulo fica com a largura toda, sem partir a palavra.
- **`SsNotificationTile`**: o texto do leitor não repete a pontuação ("Chegou o boleto. 10:30", e não "boleto.. 10:30"):
  `ssJoinSentences`.
- **`SsQuota`**: números a partir de 1.000 com o milhar do `SsFormats` ("36 de 1.500 este mês"; "1,500" com
  `SsFormats.usd`). O `SsStrings.quotaUsed` continua recebendo inteiros (`SsQuota.quotaText`).
- **Alvos de 48**: `SsFilterChip` também na largura (rótulo curto como "Pix" dava 41). No `SsTextField` o nó do campo
  tem 48 (no compacto media 33), menos com `suffix:`, para o botão de dentro (mostrar senha) continuar um nó próprio.
- **Web, `Ss::ButtonComponent(target:)`**: no link (`<a>`), com `rel="noopener"` (`rel:` troca). Em `<button>`/`button_to`
  não tem efeito. No `Ss::NotificationCenterComponent`, a ação `:get` com URL externa (http/https de outro host) abre em
  outra aba (`target="_blank" rel="noopener"`, sem o `data-turbo-frame`); `target:` na ação troca.
- Catálogo: estados `fora-do-gesto` (`ss-side-menu`), `ate-o-topo` (`ss-side-rail`), `texto-1-6` (`ss-nav-bar`,
  `ss-stat-card`, `ss-notification-bell`) e `cota-milhar` (`ss-plan`), em `flutter/test/catalogo_v19_3.dart`. Testes:
  `flutter/test/v193_test.dart` e `rails/sample/test/components/v1_9_3_web_test.rb`.

**Ao subir nos apps:** o texto do tour que diz "arraste da borda" continua valendo (a faixa de arrastar começa logo
depois da faixa do sistema), mas "toque na alça" é o caminho que sempre funciona; teste de app que procurava o sino por
`'Avisos, N não lidos'` muda para `'Notificações, N não lidas'` (ou passe `label:`).

## v1.9.2: alvos de 48 que faltavam, anexos no assistente, chave do botão central e o aviso rico

Achados dos apps ao adotar a v1.9.1 (`ssA11yAudit`) e o que a minha-automacao precisa para trocar a página de avisos feita
à mão. Nada quebra; o que entra na API é opcional.

- **Alvo de 48** (o desenho é o mesmo; o toque e o nó do leitor de tela crescem por fora, com o `SsTapTarget(semantics: true)`):
  `SsSearchField` (o campo media 44, 36 no compacto; o ✕ Limpar também), `SsListItem` com `leading:` e sem subtítulo (44: o
  nó da linha passa a 48; com `trailing:`, que pode ter botão próprio, a linha cresce até 48 para não fundir os nós), a ação
  do `SsSection` ("Ver todos", 40) e a do `SsSectionHeader(action:)` (uma ação só; `Row`/`Wrap` de ações ficam como estão,
  cada botão com o próprio alvo). Na varredura das peças v1.9: o "CANCELAR" do `SsWizard` (`SsStepTopBar`) e o "Tentar de
  novo" da mensagem com erro do `SsAssistantView` (40 no compacto), e o véu do `SsTour`, que era um nó tocável sem nome.
  `SsNotificationCenter`, `SsCaptureHub`, `SsWhatsNewList`, `SsAdaptiveScaffold` e `SsSyncPanel` passaram sem achado.
- **`SsAssistantView(attachments:, onRemoveAttachment:)`**: os anexos pendentes (`SsChatAttachment`) em chips na barra do
  campo, como no `SsChatInput`; com anexo, enviar vale sem texto (o `onSend` recebe `''`). O botão de anexar continua no
  `inputLeading:`. Web: o `Ss::AssistantComponent` não tem envio de arquivo, então não há par (fica como dívida, se um produto
  pedir).
- **Chave do botão central**: `SsNavBar(centerKey:)` ou `SsNavCenter(..., key:)`, para o `SsTour` apontar para ele
  (`SsTourStep(target: centro, …)`).
- **Aviso rico** no `SsNotificationCenter` ↔ `Ss::NotificationCenterComponent`, tudo opcional por aviso:

  | | Flutter (`SsNotificationItem`) | Web (item do `items:`) |
  |---|---|---|
  | Nível | `level: SsNotificationLevel.info/.warning/.critical` | `level: :info/:warning/:critical` |
  | Foto | `image:` (widget do app, ex. `SsNetImage`) | `image:` (URL), `image_alt:` |
  | Respostas | `actions: [SsNotificationAction('Fechar', () => …, icon:)]` | `actions: [{ label:, href:, method: (:patch; :get = link), params:, icon: }]` |
  | Silenciar | `onMute:`, `muteLabel:` (escolher as horas é do app) | `mute: { href:, method:, params:, label: }` ou `mute: { options: [{ label:, href: }] }` (menu) |

  Aviso e crítico ganham o tom semântico (âmbar, vermelho) no ícone e no contorno, o ícone do nível e o selo "Aviso"/"Crítico"
  (no leitor de tela também); `info` fica como antes; `icon:`/`tone:` passados ganham. A foto vai embaixo do texto (16:9) e os
  botões numa faixa embaixo, alinhados ao texto (o 1º cheio, os outros fantasma, "Silenciar" por último). No app, responder dá o
  aviso por lido (como abrir) e, com botões, o topo continua o toque de abrir e cada botão é um nó próprio. Textos novos:
  `SsStrings.notifLevelInfo/Warning/Critical`, `notifMute` ↔ `componentes_ui.notification_center.level_*`, `mute`.
- Catálogo: estados `rico` (`ss-notification-center`) e `anexos` (`ss-assistant`); vitrine Rails "Central de notificações,
  assistente e captura" com o aviso rico. Testes: `flutter/test/v192_alvos_test.dart` (o `v192_test.dart` é da v0.19.2) e
  `rails/sample/test/components/v1_9_2_web_test.rb`.

**Ao subir nos apps:** a minha-automacao troca a folha com o `SsNoticeCard` (aberta ao tocar o aviso com botões, foto ou
silenciar) pelos campos novos do `SsNotificationItem`, e o `/notificacoes` do web pelos do `Ss::NotificationCenterComponent`.

## v1.9.1: alvos de toque de 48 e a cota com texto grande

Achados do `ssA11yAudit` nos apps (meu-personal-app e meu-cultivo-app, 27/11/2026). Nada quebra e o desenho é o mesmo;
o que entra na API é opcional (`semantics:`, `handleKey:`, `itemKeys:`).

- `SsTapTarget(semantics: true)`: além do toque, o nó do leitor de tela (e da auditoria) tem a área de `minSize`; a
  semântica do filho vira um nó só. Ligado onde o filho é um alvo só: cada segmento do `SsSegmented`, cada aba do
  `SsTabsUnderline`/`SsCountTabs`, `SsFilterChip` (e os atalhos do `SsAssistantView`), `SsButton` em todas as variantes
  (`small`, `.text`; com isso o "Marcar todas como lidas" do `SsNotificationCenter`, o botão do `SsPlanLocked` e os do
  `SsChatActionCard`), `SsChoiceField`/`SsTimeField`, − + do `SsStepper` e o `SsMorphButton`. O `SsButton` passa a ter 48
  de largura de toque também (um "Ok" curto). Peça com vários tocáveis dentro (chip com ✕, a faixa inteira) fica sem.
- Faixa de atalhos do `SsAssistantView`: 48 de altura com o chip no meio, para a rolagem não cortar o alvo.
- `SsQuota`: o texto quebra em até 2 linhas e termina em "…" (estourava com rótulo longo e texto 1,6×).
- `SsTour` alcança a alça do menu e as abas: `SsSideMenuHost(handleKey:)` / `SsNavScaffold(handleKey:)` e
  `SsNavBar(itemKeys:)` (uma `GlobalKey` por aba), para usar em `SsTourStep(target:)`.
- `ssA11yAudit` não trava mais quando o teste trocou o `FlutterError.onError` por um que não repassa ao binding (o
  `flutter_test` esperava até o tempo limite): a falha é registrada direto no teste, que falha na hora com a lista.
- Web, no celular (`pointer: coarse`): cada opção do `.ss-seg` e o `.ss-chip` tocável ganham a área de `--ss-target`
  invisível em volta (o desenho não muda) e o `.ss-btn` chega a `--ss-target` de altura, como o `.ss-btn-sm` já fazia.
- `test/v191_alvos_test.dart`: o `ssA11yAudit` nas peças interativas mais usadas, no compacto e no padrão.

## v1.9.0: movimento, transições, peças repetidas dos apps, paridade e as vitrines por categoria

Pedido do usuário em 24/11/2026 (lista de melhorias de componentes, animação e UI/UX). Tudo aditivo:
nenhuma API mudou de forma incompatível. A API completa de cada área está em `docs/v19/`.

| Área | Flutter | Web | Doc |
|---|---|---|---|
| Peças que os apps repetiam | `SsNotificationCenter` (+ `SsNotificationTile`), `SsAssistantView`, `SsCaptureHub`/`showSsCaptureHub` | `NotificationCenterComponent`, `AssistantComponent` (`ss-assistant`, polling), `CaptureHubComponent` | `docs/v19/produto.md` |
| Movimento | tokens `SsMotion.short/medium/long`, `standard/enter/exit/spring`, distâncias; `SsHaptics` (selection, limit, success, warning, error); skeleton que vira conteúdo no `SsAsyncBody`; `SsUndoableRemoval`; "Cores do sistema" no `SsAppearanceController(systemColor:)` | `--ss-dur-*`, `--ss-ease-*`, `--ss-dist-*`; `ss-haptics`; `ss-skeleton`; `UndoableRemovalComponent` (`ss-undoable`) | `docs/v19/movimento.md` |
| Transições | `SsOpenContainer`/`SsOpenRoute`/`SsOpenPage` (lista → detalhe), voltar preditivo no `AppTheme.build` (o app põe `android:enableOnBackInvokedCallback="true"`), gráficos que deslizam entre dados, `SsEmptyState(illustration:)`, `SsCelebrate(kind:, gate:)` | View Transitions (`ss_view_transitions_head`, `ss_view_transition_name`), animações por rolagem (`animation-timeline`), `EmptyStateComponent(illustration:)`, `CelebrateComponent` | `docs/v19/transicoes.md` |
| Peças do web no app | `SsGantt`, `SsTour`, `SsWizard`, `SsDateRangeField`, `SsOtpField`, `SsTagField`, `SsAuditTrail`, `SsReviewCard`, `SsPersonCard`, `SsBentoGrid`, `SsWhatsNew`, `SsSkeleton`, `SsSplitView`/`SsAdaptiveScaffold` | `WizardComponent(with_summary, save_later_label:)` | `docs/v19/paridade_app.md` |
| Peças do app no web | `SsNavBar(hideOnScroll:)`, `SsSideMenu(search:)` (Ctrl+K), `SsSyncStatus`/`SsSyncPanel`, `SsListItem(contextActions:, swipeStart:, swipeEnd:)`, `ssA11yAudit(tester)` (testing.dart) | `SwipeToConfirm`, `HoldToConfirm`, `SnapCarousel`, `StoryRing`, `Odometer`, `MorphButton`, `Burst`, `HeatCalendar`, `BigRing`, `Rings`, `DateStrip`, `SplitSlider`, `SyncStatus` | `docs/v19/paridade_web.md` |
| Paridade | `paridade.yml` na raiz: o par de cada peça (ou a exceção com motivo, ou a dívida). O teste dos dois lados falha com peça num lado só sem registro | | `paridade.yml` |
| Vitrines | Por categoria de uso (16, iguais nos dois lados); `example/lib/categorias.dart` + `test/categorias_test.dart` (peça sem categoria falha) | 1ª linha da página: `grupo:`, `tambem:`, `versao:`; `test/vitrine_test.rb` (página fora do menu falha) | — |
| Correções | `SsPagedList(onRefresh:)` sem altura infinita | `ss-validate` não engole o clique do botão logo abaixo do campo | — |

**Demonstração:** https://demo.minhasuite.com (vitrine web; `/app/` = vitrine do app; `/componentes-demo.apk`),
atualizada a cada push na `main` pelo `.github/workflows/demo.yml`; cada tag anexa o APK à release.

**Ao subir nos apps:** `android:enableOnBackInvokedCallback="true"` no manifesto; trocar central de avisos,
aba do assistente e folha de captura feitas à mão pelas peças; `ssA11yAudit` nos testes de tela; tirar o
contorno `ponytail:` do `SsPagedList` (minhas-vendas-app).

## v1.8.3: chat sem `required` no campo

Achado da gravação das aulas do meu-gestor (23/11/2026): o balão "Preencha este campo." voltou no `Ss::ChatComponent`
ao parar o mouse no campo vazio. O `novalidate` da v1.4.1 barra o balão do envio, mas o Chrome mostra a mensagem de
validação ao passar o mouse em todo campo `required` inválido, com ou sem `novalidate`. O textarea troca `required`
por `aria-required="true"` (o leitor de tela continua sabendo); o envio vazio segue barrado pelo `ss-chat`. Nada quebra
na API; teste de produto que procurava `textarea[required]` no chat passa a procurar `[aria-required=true]`.

## v1.8.2: tempo relativo sem quebrar o número da unidade e ranking em 2 linhas

Achados das telas de "Pediram e não tinha" (minhas-vendas e meu-gestor, 22–23/11/2026):

- **Tempo relativo com espaço não separável** (U+00A0) entre o número e a unidade, nos dois lados: `timeAgo` e
  `SsStrings.ago*` (pt/en/es), `SsCameraTile.formatAge`, `SsTimeFormat.duration` ↔ `Ss::CameraTileComponent`
  (`camera_tile.age_*` nos locales e no padrão). "há 14 h" não deixa mais o "h" sozinho na linha de baixo.
  **Padrão que mudou:** teste de produto que compara `timeAgo(...)` com `'há 2 h'` (espaço comum) quebra; compare com
  `'há 2\u00A0h'` ou monte o esperado com o próprio `timeAgo`.
- **`SsRankList` / `RankListComponent`: o nome vai a até 2 linhas** (antes 1 linha com "…", que cortava com texto
  1,6×). No web, `.ss-rank-label` com `line-clamp: 2` e o nome inteiro no `title`. Nada muda na API.

## v1.8.1: a linha de progresso não corta o valor

`SsProgressRow`: a linha de baixo ("R$ 35,00 de R$ 40,00" e "Restam…") quebra quando não cabe, em vez de cortar o valor
com reticências (texto 1,6×, valores longos em reais), e o rótulo vai a 2 linhas. Achado no orçamento de prêmios do
Meu Gestor. Nada muda na API.

## v1.8.0: cartão de conquista

Pedido do meu-gestor (gamificação, fase 2: "Meus pontos" › Conquistas, web e app), genérico para qualquer produto. Tudo
aditivo; nada quebra. Testes em `rails/sample/test/components/v180_web_test.rb` e `flutter/test/v180_test.dart` (com
`CONQUISTA_SAIDA=<pasta>` grava as capturas: 360 em 2 colunas, claro, escuro, OLED e texto 1,6×); CSS em
`v180_conquista_web.css`; vitrine `pecas_v180`; catálogo `ss-achievement` nos dois lados (`rails/sample/script/catalogo_v180.rb`,
`flutter/test/catalogo_v180.dart`).

| Peça | Web | Flutter |
|---|---|---|
| Cartão | `Ss::AchievementCardComponent(title:, description:, icon: "trophy", earned: false, caption: nil, progress: nil, progress_label: nil, href: nil)` (`.ss-card.ss-achievement` + `.is-earned`/`.is-locked`) | `SsAchievementCard(title:, description:, icon: Icons.verified_outlined, earned: false, caption:, progress:, progressLabel:, onTap:)` |
| Grade | `.ss-achievement-grid` (auto-fill, mínimo 14rem; uma coluna em 390) | `Row`/`Wrap` do app (sem altura fixa, serve em 2 colunas de 360) |
| Textos | `componentes_ui.achievement.{label,earned,missing}` (pt/en/es) | `SsStrings.achievementLabel`, `achievementEarned`, `achievementMissing` (obrigatórios no construtor, como os da v1.6) |

- **Conquistada** (`earned`): medalhão na cor da marca (`--accent`/`accentText` sobre `--accent-soft`), título em `ink`,
  o selo "Conquistada" e o `caption` ("em 12/11").
- **Ainda não**: medalhão apagado (`--field` com contorno `--line`, ícone `muted`); com `progress` (0 a 1) a barra fina
  (`.ss-progress` com `role="progressbar"` e "Falta: 12 de 30 dias" / `SsProgress`) e o `progress_label`. Sem progresso, sem rodapé.
- **Ícone**: o padrão é o "trophy" do conjunto da suíte, que é apelido do `badge-check` (Heroicons v1 não tem troféu):
  `ss_icon("trophy")` no web e `SsIcons.named('trophy')` (= `Icons.verified_outlined`) no Flutter, o mesmo desenho.
- **Leitor de tela**: no Flutter um nó só, "Conquista: título. Conquistada em 12/11. A regra." (ou "Falta: 12 de 30 dias.");
  no web o título leva "Conquista:" em `.ss-sr`. Com `href`/`onTap` o cartão é link/botão.
- **Texto grande**: nada tem altura fixa; o selo quebra depois do ícone, nunca no meio da palavra.

```erb
<div class="ss-achievement-grid">
  <%= render Ss::AchievementCardComponent.new(title: "Primeiro turno coberto", description: "Cobriu um turno aberto.", earned: true, caption: "em 12/11") %>
  <%= render Ss::AchievementCardComponent.new(title: "30 dias seguidos", description: "Sequência de 30 dias.", icon: "fire", progress: 0.4, progress_label: "12 de 30 dias") %>
</div>
```

```dart
SsAchievementCard(title: '30 dias seguidos', description: 'Sequência de 30 dias.', icon: SsIcons.named('fire'),
  progress: 12 / 30, progressLabel: '12 de 30 dias')
```

## v1.7.1: o botão do Google sem caixa branca no escuro

`Ss::GoogleButtonComponent(mode: :gis)` no tema escuro: o Chrome pintava de branco o fundo do iframe do Google (a página
em `color-scheme: dark`, a do botão em light), e ficava uma caixa branca em volta da pílula, bem à vista no papel escuro
do `:cartaz`. Todo iframe do GIS (`accounts.google.com/gsi/`, do componente ou montado pelo produto) passa a usar
`color-scheme: light` e o fundo volta a ser transparente. Só CSS (`v20_web.css`);
teste em `v170_web_test.rb`. Nada quebra.

## v1.7.0: tela de entrada "Cartaz + papel"

A proposta B escolhida pelo usuário em 19/11/2026 (`propostas/cartaz-landings-login/`): a entrada abre como as capas dos
vídeos e o portal, em cartaz na cor do produto, e o formulário fica no papel do Lista Clara. Aditivo: `:sheet`, `:wall` e
`:pad` (a Folhinha) seguem iguais. Testes em `rails/sample/test/components/v170_web_test.rb` e `flutter/test/v170_test.dart`
(com `CARTAZ_SAIDA=<pasta>` grava as capturas de 390 e 1440 em claro, escuro, OLED, alto contraste e texto 1,6×); CSS em
`v170_cartaz_web.css`; vitrine `pecas_v170` (`?tela=1` abre sozinha, com `?tema=claro|escuro|oled`, `?paleta=<slug>`,
`?contraste=alto`, `?produto=gestor|financeiro|central`, `?erro=1`); catálogo `ss-auth-cartaz` nos dois lados
(`rails/sample/script/catalogo_v170.rb`, `flutter/test/catalogo_v170.dart`).

| Peça | Web | Flutter |
|---|---|---|
| Tela de entrada | `Ss::AuthLayoutComponent(variant: :cartaz, layout: :split, word:, facts:, icon:)` + os parâmetros de sempre (`product:`, `tagline:`, `title:`, `subtitle:`, `brand:`, `brand_href:`, `links:`) | `SsAuthLayout.cartaz(product:, title:, subtitle:, tagline:, word:, layout: SsCartazLayout.split, facts:, icon:, brand:, footer:, children:)` (widget `SsAuthCartaz`) |
| Cores do cartaz | `--brand-deep`, `--brand-from` e `--brand-to` por `data-palette` no `paletas.css` (gerado; a violeta no `:root`) e no `ss_brand_style`/`ComponentesUi.brand_css` | `SsColors.brandDeep/brandFrom/brandTo` (já existiam) e `SsCartazColors.of(context)` com a conta pronta |
| Fontes | `--ss-font-display` (Big Shoulders Display 900, `ss_display_font_tag`) e `--font-mono` (DM Mono 500, já no `ss_font_tags`) | `AppTheme.display` e `AppTheme.number` |

- **O cartaz:** a marca, o ícone e o nome do produto, o `tagline:` grande na fonte de exibição, a linha de dados `facts:`
  em DM Mono e a palavra gigante `word:` cortada pela borda (padrão: a última palavra do `product:` em minúsculas). A palavra
  é decorativa: `aria-hidden` / `ExcludeSemantics`. O `h1` é o título do papel.
- **Cor:** `--brand-deep` no claro; no escuro e no OLED, `--brand-deep` a 52% com a `--page`, a mesma regra do portal. O
  `gerar.py` reprova paleta com texto branco abaixo de 7:1 ou texto secundário (branco a 82%) abaixo de 4,5:1 sobre o cartaz,
  no claro, no escuro do web e do Flutter e no OLED. As 30 paletas passam.
- **O papel:** `--page` / `c.page`, sem caixa em volta; no web os campos e o botão do Google ficam em `--surface`. Em cima,
  "Parte da MinhaSuite" em DM Mono (`componentes_ui.auth.part_of` / `SsStrings.authPartOf`, pt/en/es; nenhum texto novo).
- **Celular:** abaixo de 860 px no web (840 no Flutter) o cartaz vira uma faixa de 240 px em cima, sem a linha de dados, e o
  papel desce. Sem rolagem lateral em 390.
- **Movimento:** ao abrir, uma passada de cor varre o cartaz uma vez (1 s) e a palavra entra deslizando. "Reduzir
  movimento" desliga (`prefers-reduced-motion` / `MediaQuery.disableAnimations`). `motion:`, `error:`, `date:` e `note:` não
  valem no `:cartaz`.
- **Acessibilidade:** foco visível em branco sobre o cartaz e na cor da marca no papel; alto contraste deixa o texto
  secundário do cartaz em branco inteiro.

```erb
<%= render(Ss::AuthLayoutComponent.new(product: "Minhas Vendas", tagline: "A venda não para.", variant: :cartaz,
                                       word: "vendas", facts: %w[Web Windows Caixa App], icon: "chart-bar",
                                       title: content_for(:auth_title) || "Entrar", subtitle: content_for(:auth_subtitle),
                                       brand_href: "https://www.minhasuite.com/", links: [["Termos", terms_path]])) do %>
  …
<% end %>
```

```dart
SsAuthLayout.cartaz(product: 'Minhas Vendas', tagline: 'A venda não para.', word: 'vendas',
  facts: const ['Web', 'Windows', 'Caixa', 'App'], title: 'Entrar', subtitle: 'no Minhas Vendas', children: [...])
```

**Padrões que mudaram.** Nenhum. Para trocar a Folhinha pelo cartaz no produto, mude `variant: :wall` para `variant: :cartaz`
e passe `word:`/`facts:`/`icon:` se quiser; o resto do layout de entrada fica igual.

## v1.6.0: ajuda na moldura e no menu lateral (Aprenda e Novidades)

Fase 1 do portal de aulas e novidades (www.minhasuite.com/&lt;produto&gt;/aprenda e /novidades), pedido em 18/11/2026 para
o minhas-vendas e o meu-gestor; serve a qualquer produto com portal. Tudo aditivo; nada quebra. Testes em
`rails/sample/test/components/v160_web_test.rb` e `flutter/test/v160_test.dart`; CSS em `v160_ajuda_web.css`; vitrine
`pecas_v160`; catálogo `ss-help` (`rails/sample/script/catalogo_v160.rb`) e `ss-help-menu` (`flutter/test/catalogo_v160.dart`).

| Peça | Web | Flutter |
|---|---|---|
| Ajuda | `Ss::HelpMenuComponent(learn_href:, news_href:, unseen_news:, items:)` no slot novo `with_help` do `Ss::AppShellComponent` (barra de cima, antes do sino, no computador e no celular): botão "?" com o ponto da marca quando há novidade não vista e o popover com **Aprenda** (videoaulas) e **Novidades**, os dois em outra aba; o selo "2 novas" na linha. Clicar em Novidades apaga ponto e selo na hora (Stimulus `ss-help`) e fecha o popover. `news_href: nil` esconde Novidades | `SsHelpMenu.section(context, onLearn:, onNews:, unseenNews:, extra:)`: a `SsSideMenuSection` "Ajuda" com as mesmas duas linhas e o mesmo selo. Sem `onNews`, só Aprenda |
| Linha que abre fora | `{ external: true }` já existia no menu (v0.20) | `SsSideMenuItem(external: true)`: ícone de saída à direita e "abre no navegador" no leitor de tela |
| Selo em texto na linha do menu | `.ss-badge.ss-badge-accent` | `SsSideMenuItem(badgeLabel: '2 novas')`: `SsBadge` na cor da marca; ganha do `badge:` (contagem vermelha) e do ícone de saída |
| Textos | `componentes_ui.help.*` (pt/en/es) | `SsStrings.helpTitle`, `helpLearn`, `helpLearnNote`, `helpNews`, `helpNewsNote`, `helpNewsUnseen(n)`, `opensOutside` (obrigatórios no construtor, como os da v1.3) |

Guardar o "visto até" é do produto (por usuário, no servidor): o `news_href`/`onNews` passa por uma rota do produto que
grava e leva ao portal. Ponto e selo são da marca, não o vermelho do sino: novidade não é alerta.

```erb
<% s.with_help do %>
  <%= render Ss::HelpMenuComponent.new(learn_href: "https://www.minhasuite.com/vendas/aprenda/",
                                       news_href: (novidades_path if portal.news?), unseen_news: portal.unseen) %>
<% end %>
```

```dart
SsSideMenu(sections: [
  ...,
  SsHelpMenu.section(context, onLearn: () => abrir(aprenda), onNews: temNovidade ? abrirNovidades : null, unseenNews: 2),
])
```

## v1.5.2: sino de avisos no topo, o selo como componente e o tile de aparelho que empilha quando estreito

Pedidos do minha-automacao (branches `shell-sino` e `paineis-ia`, feitos no branch `onda7` como v0.25.0 e juntados ao `main` na v1.5.2 em 18/11/2026; CSS em `v152_sino_web.css`, catálogo Flutter em `catalogo_sino.dart`, testes em `sino_test.dart` e `sino_web_test.rb`). Tudo aditivo; nada quebra.

### Sino de avisos e selo

Pedido do minha-automacao (notificações no padrão de mercado e selos iguais em toda tela).

- **Web** `Ss::NotificationBellComponent` (par do `SsNotificationBell`): o sino com o contador de não lidos (0 some,
  acima de 99 vira "99+") e o popover com os últimos avisos, "marcar todas como lidas" (`read_all_href:`, PATCH),
  engrenagem das preferências (`settings_href:`) e "ver todos" (`all_href:`). Lista por `items:` ou por `src:`
  (`<turbo-frame>` lazy, recarregado ao reabrir; a URL devolve o `Ss::NotificationListComponent.new(frame_id:, items:)`).
  Contador vivo por `count_url:` (JSON `{ count }`) a cada `every:` ms, com a aba visível, ao voltar e ao abrir;
  controller `ss-bell` dispara `ss-bell:change` (`{ count }`). Item com `method:` vira `button_to` (abrir marca como lido).
- `Ss::AppShellComponent#with_bell { … }`: o sino no canto direito da barra de cima (computador e celular), entre o
  `top` e o `user`; a barra do computador não some com só o sino.
- `Ss::BadgeComponent` (par do `SsBadge`): o `.ss-badge` como componente (tone:, icon:, dot:, solid:, mono:, href:
  com `link_data:`); `a.ss-badge` ganhou o contorno da marca ao passar.
- **Flutter** `SsNotificationBell(count:, onPressed:)`: o `SsIconButton` com o número no selo e o nome lido com a
  contagem (`label:`, `unreadLabel:`).
- Vitrine "Sino de avisos e selo (v0.25)"; testes em `rails/sample/test/components/v25_web_test.rb` e
  `flutter/test/v25_test.dart`; CSS em `v25_web.css`; catálogo Flutter em `flutter/test/catalogo_v25.dart`, web por
  `rails/sample/script/catalogo_v025.rb`; catálogo `ss-bell`, `ss-badge-c` e `ss-notification-bell`.

### Tile de aparelho bem estreito

- `Ss::DeviceTileComponent`/`SsDeviceTile` bem estreitos (abaixo de 10rem / 150 px, ex. 3 por linha numa coluna de 1/3)
  empilham: ícone e ⋯ em cima, nome (até 2 linhas) e estado embaixo, em vez de cortar o nome em "Vi g…". Só CSS
  (contêiner `ss-device`, em `v23_web.css`) e layout do Flutter; testes em `flutter/test/v10_controles_test.dart`,
  catálogo `flutter/test/catalogo_v10_controles.dart` e `rails/catalogo/index.html`.

## v1.5.1: a entrada mais calma

Pedido do usuário em 17/11/2026 (login com cores fortes). Só CSS, em `v151_web.css`; a marcação não muda e vale para
todas as variações do `Ss::AuthLayoutComponent`.

| O quê | Como fica |
|---|---|
| Faixa do produto (`.ss-auth-band`) | Fundo `--accent-soft`, fio de 3px em `--accent` e o nome em `--accent` (era bloco sólido em `--accent-solid` com texto branco) |
| Botão principal na entrada (`.ss-auth .ss-btn-primary`) | Cor sólida `--accent-solid`, sem o degradê, a sombra colorida e o brilho que passa. Fora da entrada o botão segue igual |
| Carimbo do `motion: true` | Na cor do produto (`--accent`), não mais em `--danger` |
| Sombra da folha | Mais leve |

Teste: `rails/sample/test/components/v151_web_test.rb`. O par no Flutter (`SsAuthLayout.folhinha`) segue com a faixa
sólida: dívida aberta, junto com a do `motion:`.

## v1.4.1: chat sem o balão nativo, scrollspy da seção certa e `ss-reveal` com rádios

Achados das videoaulas do meu-gestor (17/11/2026). Só web; nada quebra na API. Teste em
`rails/sample/test/components/v141_web_test.rb` (falha na v1.4.0); catálogo: comportamentos novos em `ss-chat-panel` e
`ss-settings`.

| Peça | O que mudou |
|---|---|
| `Ss::ChatComponent` | O formulário tem `novalidate`: com o campo vazio, parar o mouse nele fazia o Chrome mostrar o balão "Preencha este campo." (o `required` continua para o leitor de tela; o `ss-chat` já não envia vazio) |
| `ss-scrollspy` (`SettingsLayoutComponent`) | A seção marcada é a última cujo topo passou da linha de leitura (30% da janela, no máximo 200 px); no fim da página, a última. Antes valia a primeira seção visível numa faixa, e a de cima, ainda com a borda à vista, ganhava (recarregar em `#vendas` marcava "Plano"). A âncora da URL marca a dela ao abrir; clicar no menu marca na hora |
| `ss-reveal` | O `source` pode ser um grupo de rádios: vale o valor do marcado. `f.ss_radio_buttons(..., data: { ss_reveal_target: "source", action: "change->ss-reveal#update" })` |

## v1.4.0: a folhinha da entrada reage (`AuthLayoutComponent(motion: true)`)

Pedido do usuário em 17/11/2026 (landings e login mais vivos). Só web, aditivo: sem `motion:` nada muda. O par no
Flutter (`SsAuthLayout.folhinha`) fica para depois e é dívida aberta.

| O quê | Como fica |
|---|---|
| `motion: true` (só `variant: :wall`) | Ao enviar o formulário ou tocar em "Entrar com o Google", a folhinha se solta do pino e cai; por baixo aparece a folha seguinte (mesma largura e altura) com a saudação da hora (Bom dia até 12h, Boa tarde até 18h, Boa noite), "Abrindo o &lt;produto&gt;…" com a barra enchendo e o carimbo "Em dia". O envio **não espera** a animação |
| `error: true` | A folha treme ao abrir. Use quando a página volta com o erro de login (ex.: `error: flash[:alert].present?`). Se o Turbo devolver falha sem trocar a página, a folha volta ao pino e treme |
| Reduzir movimento | A folha só some, nada treme; carimbo e barra já aparecem prontos |
| Textos | `componentes_ui.auth.greetings`, `opening` (`%{product}`) e `stamp`, em pt/en/es |

Peças: controlador `ss-auth` (`ss_auth_controller.js`), CSS em `v140_web.css`, teste em
`rails/sample/test/components/v140_web_test.rb`, vitrine `pecas_v140` (envie o formulário; `?erro=1` abre tremendo),
catálogo `ss-auth-motion` (`rails/sample/script/catalogo_v140.rb`).

```erb
<%= render(Ss::AuthLayoutComponent.new(product: "Meu Gestor", tagline: "A loja em dia, sem planilha.", title: "Entrar",
                                       variant: :wall, motion: true, error: flash[:alert].present?)) do %>
  …
<% end %>
```

## v1.3.1: `SsMenuView(appearanceController:)`

A tela de configurações dos apps mostra a aparência completa (`SsAppearancePanel`: tema, preto total, cores e
densidade) no lugar do seletor simples de tema, sem duplicar. `themeMode`/`onThemeMode` deixam de ser obrigatórios
(sem `appearanceController`, o seletor simples segue igual).

## v1.3.0: aparência em todos os produtos e a alça do menu na borda

Pedido do usuário em 17/11/2026. Tudo aditivo, menos o botão de menu automático da v1.1, que sai.

| O quê | Como fica |
|---|---|
| Botão de menu nos cabeçalhos | **Sai** (era da v1.1): `SsScreenHeader`/`SsTopBar` voltam a mostrar só a seta de voltar. A dica ao abrir o app e a alça bastam |
| Alça do menu | Pílula pequena na cor da marca, **sempre à vista** na borda esquerda com o menu fechado (tom suave). No fim da dica ao abrir o app ela pulsa duas vezes e assenta. Tocar abre o menu; o arraste que começa nela também. Só a área da alça recebe o toque (o resto da borda segue com a tela) |
| Aparência no app | `SsAppearance` (paleta, tema, preto total, densidade; `toJson`/`fromJson`), `SsAppearanceController(brand:, read:, write:)` (guarda onde o app disser e monta os temas em cache; o `MaterialApp` ouve: `theme: c.theme(Brightness.light)`, `darkTheme: c.theme(Brightness.dark)`, `themeMode: c.value.themeMode`) e `SsAppearancePanel(controller:)`, a seção pronta: tema, preto total, cores (a **Cor do app** primeiro, depois as 30 paletas) e densidade. Textos novos no `SsStrings`: `appearanceTheme`, `appearanceOled`, `appearanceOledHint`, `appearanceColors`, `appearanceAppColor` |
| Aparência no web | `Ss::ThemeSwitcherComponent(app_palette: "ambar")`: a 1ª ficha é a "Cor do app" (a paleta do produto) e a violeta vira ficha comum. `ss_theme_head` no `<head>` (antes do CSS) guarda a paleta do produto em `data-palette-default` e aplica tema, paleta e OLED escolhidos antes da 1ª pintura. No controlador `ss-theme`, "none" volta para a paleta do produto, não para a violeta |

```dart
final aparencia = SsAppearanceController(
  brand: SsBrand.ambar,
  read: () => storage.read(key: 'aparencia'),
  write: (v) => storage.write(key: 'aparencia', value: v),
)..load();
// Configurações › Aparência:
SsAppearancePanel(controller: aparencia)
```

```erb
<%# <head>, antes do stylesheet %>
<%= ss_theme_head %>
<%# configurações %>
<%= render Ss::ThemeSwitcherComponent.new(app_palette: "ambar") %>
```

## v1.2.2: o rótulo do campo é o nome dele no leitor de tela

Achado 17 das videoaulas do minhas-vendas (app). O `SsTextField` só dava o rótulo ao campo com `hideLabel: true`; com o
rótulo visível (o `SsFieldLabel` acima da caixa), o campo ficava sem nome fora de lista e, dentro de `ListView`, o
rótulo só chegava como dica do `EditText`. Agora, sempre que há `label:`, o campo leva `Semantics(label:)` e o rótulo
visível fica em `ExcludeSemantics` (não é lido duas vezes). Vale para o `SsMoneyField` (que monta um `SsTextField`); no
`SsChoiceField` e no `SsTimeField` o botão já dizia rótulo e valor, e o rótulo visível passa a ficar fora da semântica.
Teste: `flutter/test/v122_test.dart` (dentro e fora de `ListView`). Catálogo: comportamento novo em `ss-text-field`,
`ss-money-field`, `ss-choice-field` e `ss-time-field` (`flutter/test/catalogo_v122.dart`). Só Flutter.

**Padrões que mudaram.** Teste de app que achava o rótulo como texto solto na semântica (`find.bySemanticsLabel('CNPJ')`
num nó que não é o campo) passa a achar o próprio campo (o nó do `EditableText` com o rótulo).

## v1.2.1: linha do tempo sem passo escondido e o stepper com vírgula

Dois achados da loja online do minhas-vendas. Testes em `rails/sample/test/components/v121_web_test.rb`; CSS em
`v121_web.css`; catálogo: seções `ss-htl-v121` e `ss-stepper-decimals` (`rails/sample/script/catalogo_v121.rb`). Só web.

| Peça | O que mudou |
|---|---|
| `Ss::TimelineHorizontalComponent` (`.ss-htl`) | Cada marco tinha 12,5rem fixos e a lista rolava de lado: na ficha do pedido online a 1536 px "Entregue" ficava fora do cartão e, no celular (acompanhamento público), só "Recebido" e "Confirmado" apareciam. Agora os marcos **dividem a largura** (o texto quebra; nada rola) e, quando a própria lista tem **menos de 36rem** (container query: cartão estreito ou celular), ela **fica em pé**: um marco por linha, a bolinha à esquerda e o fio descendo até a próxima. Mesma marcação; só CSS. O Flutter não tem a peça horizontal (o `SsTimeline` já é em pé) |
| `Ss::StepperInputComponent(decimals: N)` | Par do `SsStepper(decimals:)`. Com `decimals:` (> 0) o campo vira texto com `inputmode=decimal` e mostra o número no idioma da página com N casas ("0,5" em pt-BR; o `<input type=number>` do Chromium mostrava "0.5"). O `ss-stepper` lê e escreve pelo `Intl` com o `lang` do `<html>` ("0,5" e "0.5" valem), faz o −/+ (texto não tem `stepUp`) e prende em `min:`/`max:` (vão em `data-min`/`data-max`/`data-step`). **Ao servidor vai o ponto**: o `name:` fica num `<input type=hidden>` ("0.5", target `raw`) atualizado a cada mudança; o campo visível não tem `name`. Quem lê o `event.target.value` do `change` recebe o texto do idioma ("0,5"); quem lê `form.elements[name]`, o ponto. Sem `decimals:`, igual a antes |

**Padrões que mudaram.** A linha do tempo horizontal deixa de rolar: quem contava com a rolagem (muitos marcos num
espaço curto) passa a ver os marcos estreitos com o texto quebrado ou, abaixo de 36rem, a lista em pé.

## v1.2.0: linha de item compacta no celular, foco fora da barra do topo, eixo que não cola e o nome da caixa da linha

O que a auditoria de UX de novembro (V02, P03, U03) e as videoaulas (achado 14) do minhas-vendas acharam nas peças
genéricas. Tudo aditivo na API (parâmetros novos, opcionais): por isso 1.2. Testes em
`rails/sample/test/components/v120_web_test.rb` e `flutter/test/v120_test.dart`; CSS em `v120_web.css`; catálogo:
seções `ss-repeater-compact` e `ss-v120-correcoes` em `rails/catalogo/index.html` (`rails/sample/script/catalogo_v120.rb`)
e os estados `compacto`/`compacto-aberto` do `ss-repeater` e `doze-meses` do `ss-bar-chart` (`flutter/test/catalogo_v120.dart`).

| Peça | Flutter | Rails / CSS | No lugar de |
|---|---|---|---|
| Linha compacta do repetidor | `SsRepeater(mobile: SsRepeaterMobile.compact, compactBelow: 768)` + `SsRepeater.cells([SsRepeaterCell(produto), SsRepeaterCell(lote, role: SsRepeaterRole.detail), SsRepeaterCell(qtd, role: SsRepeaterRole.inline)], detailsOpen:)`; compacto, o cabeçalho some e os campos mostram o rótulo com `hideLabel: !SsRepeater.compactOf(context)`; as células recolhidas continuam montadas (texto e validador do `Form`); `detailsOpen: true` abre (campo com erro). Texto `SsStrings.repeaterDetails` (opcional no construtor) | `RepeaterComponent(mobile: :compact, details_label:)` + `r.cell(:primary \| :inline \| :detail) { … }` dentro do `r.row`: abaixo de 48rem `primary` na linha inteira, `inline` lado a lado numa linha, `detail` atrás do botão "Detalhes" da linha (`.ss-repeater-more`, `aria-expanded`, Stimulus `ss-repeater#details` põe `.is-open`); detalhe com erro aparece fechado; em tela larga a `.ss-repeater-cell` é `display: contents` e nada muda. Texto `componentes_ui.repeater.details` | 7 campos empilhados por item do pedido no celular |
| Foco e âncora abaixo da barra do topo | — | `html:has(.ss-shell-top) { scroll-padding-top: var(--ss-top-room) }`: a altura da `.ss-shell-top` (a mesma conta do `min-height`/`padding` dela, na densidade) + área segura + respiro; sem barra no computador (`.is-bare`, ≥1024px), 0 | o produto medir a barra à mão (`scrollBy` com a altura da `.ss-shell-top` no caixa do minhas-vendas) |
| Rótulos do eixo X que não colam | `ssAxisLabelStep(labels, slot:, style:)`: o passo sai da largura medida do maior rótulo (antes 44 px fixos) e a contagem parte do `active` | `BarChartComponent`/`LineChartComponent`: `label_every` automático pela largura do maior rótulo (~8,7 unidades por letra + 8; antes 26 fixas) e a partir do `active:`; `label_every:` ainda força | "MARABR" nos doze meses em 360 px |
| Nome da caixa de seleção da linha | (o `SsDataTable` não tem seleção) | `DataTableComponent(selectable: true, select_label:)`: "Selecionar <título da linha>" (coluna `mobile: :title` ou a 1ª coluna, sem HTML); `select_label: ->(row) { "…" }` (texto inteiro) ou `:campo` (entra no "Selecionar %{name}"); sem texto, "Selecionar linha N" (posição). Textos `data_table.select_named` pt/en/es | "Selecionar linha 0b6f3f5e-…" (o uuid) |

Uso no pedido (minhas-vendas): `RepeaterComponent.new(..., mobile: :compact)` e, na linha, `r.cell(:primary) { produto }`,
`r.cell(:detail) { descrição + lote }`, `r.cell(:inline) { qtd + unitário }`, `r.cell(:detail) { desconto }`,
`r.cell(:inline) { total }`. O par Flutter existe, mas o app do minhas-vendas monta o pedido em folhas próprias (sem
`SsRepeater`): fica para quem usar o repetidor no app.

**Padrões que mudaram.**

- **Rótulos do eixo X do `BarChartComponent`/`LineChartComponent`/`SsBarChart`:** com `active:`, a contagem de N em N
  parte do ativo (antes do 1º, e o ativo era desenhado além da conta, colado no vizinho): com 30 dias e `active: 9` saem
  15 rótulos, não 16. Rótulo longo ("Seg 10/11") sai de N em N onde antes saía inteiro e encostado (web) ou cortado em
  "Se…" (Flutter). Teste de produto que contava os rótulos do eixo pode mudar.
- **`aria-label` da caixa de cada linha** do `DataTableComponent(selectable: true)`: de "Selecionar linha <id>" para
  "Selecionar <título>". Teste de produto que procurava a caixa pelo rótulo antigo precisa do novo.
- **`scroll-padding-top`** no `html` de toda página com a moldura: âncora (`#campo`), `scrollIntoView()` sem opções e o
  foco que rola a página param abaixo da barra do topo. Contorno do produto que somava a altura da barra à mão fica
  redundante (rolaria duas vezes).

## v1.1.0: menu lateral mais bonito e com o botão nas telas principais

Pedido do usuário em 17/11/2026 (os apps tiram a aba "Mais" da barra de baixo e põem as opções dela no menu lateral).
Tudo aditivo na API; muda o desenho do `SsSideMenu` e o cabeçalho das telas principais.

| O quê | Como fica |
|---|---|
| Linhas amarelas embaixo do título | O painel do `SsSideMenuHost` fica dentro de um `Material` (transparente). Sem ele, o texto do cabeçalho ganhava o sublinhado amarelo duplo de depuração do Flutter: o host fica por cima do `Scaffold` |
| Cabeçalho | Cartão no gradiente da marca com o ícone do app (`SsSideMenu(icon:)`, num quadrado translúcido; ou `leading:`), o nome na fonte de exibição (`AppTheme.display`, branco) e a conta (`subtitle:`) embaixo, com dois círculos claros de acabamento |
| Versões | No pé, num tom apagado (`muted2`): `<title> <version> · componentes_ui <ssComponentesUiVersion>`. `SsSideMenu(version: '1.4.0 (123)')` vem do app (`package_info_plus`); `ssComponentesUiVersion` é constante do pacote (o teste confere com o pubspec) |
| Dica ao abrir o app | Sai a pílula "Arraste para abrir o menu" (rápida demais para ler); ficam a fresta com os ícones e a borda que pisca. `SsStrings.sideMenuHint` continua, sem uso |
| Botão de menu | `SsScreenHeader` e `SsTopBar` numa tela principal (sem voltar) dentro de um `SsSideMenuHost` ganham sozinhos o botão de menu no lugar da seta (`Icons.menu_rounded`, "Abrir o menu"). Com `leading:` próprio, vale o do app |

## v1.0.2: `find.ssTooltip` com um alvo só por tooltip

Na v1.0.1 ele achava o `Tooltip` e o `RawTooltip` de dentro (o `tap` reclamava de dois alvos). Agora segue a regra do
`find.byTooltip`: o `RawTooltip` pela semântica, e o `Tooltip` só quando fica fora da semântica ou sem mensagem.

## v1.0.1: `find.ssTooltip` para os testes dos apps (material_ui)

`package:componentes_ui/testing.dart` (só em `test/`): `find.ssTooltip(Pattern)`, o `find.byTooltip` que acha também o
`Tooltip` do `material_ui`. O do `flutter_test` olha o `RawTooltip` pela semântica e, com `excludeFromSemantics: true`
(o `SsHeaderAction`), só o `Tooltip` do Material do SDK, outro tipo desde o 3.50: o teste que tocava o sino ou uma ação
do cabeçalho deixa de achar. Troque `find.byTooltip(` por `find.ssTooltip(` (mesmo comportamento) e importe o
`testing.dart`. O `ssPreloadFonts` também sai por ele. O `flutter_test` passou para `dependencies` do pacote (só esse
arquivo o importa; o app não leva nada a mais).

## v1.0.0: Flutter 3.50 e o Material fora do SDK (`material_ui`)

O Flutter 3.50 (11/11/2026) descontinuou `package:flutter/material.dart` e `cupertino.dart`: o Material
virou o pacote `material_ui`, e o `flutter analyze` reprova cada import antigo (`deprecated_member_use`).
Os apps da suíte estavam presos na 3.47.9 por isso. **Quebra a API** (por isso a 1.0): o `ThemeData`,
`TextTheme`, `ColorScheme`… do `material_ui` são **outros tipos** que os do SDK, então o pacote e o app
precisam estar do mesmo lado. Só Flutter; a gem não muda (a versão sobe junto porque a tag é uma só).

| O quê | Como fica |
|---|---|
| Import | `package:material_ui/material_ui.dart` (reexporta `package:flutter/widgets.dart`) no lugar de `package:flutter/material.dart`. Migração: `dart fix --apply --code=migrate_design_widgets` |
| SDK | `environment: sdk ^3.14.0, flutter >=3.50.0` (no pacote); a CI do app vai para `flutter-version: 3.50.0` |
| Localização | `localizationsDelegates: [SsStrings.delegate, ...GlobalMaterialLocalizations.delegates]` (o `GlobalMaterialLocalizations` do `material_ui`); o import do `flutter_localizations` sai (dá `ambiguous_import`) |
| Tema | `AppTheme` monta a Manrope estilo a estilo (`GoogleFonts.manrope(textStyle:)`): o `GoogleFonts.manropeTextTheme` devolve o `TextTheme` do SDK. Pacote de terceiros que devolve tipo do Material do SDK tem o mesmo problema |
| Testes | `ssPreloadFonts()` (novo): no Flutter 3.50 a fonte que termina de carregar no meio do teste agenda o aviso "fontes do sistema mudaram" e o `testWidgets` reprova com "An animation is still running even after the widget tree was disposed". Todo app põe em `test/flutter_test_config.dart`: |
| Conformidade | regra nova `material-sdk`: `conferirConformidade` reprova `package:flutter/material.dart` em `lib/` |

```dart
// test/flutter_test_config.dart
import 'dart:async';
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await ssPreloadFonts();
  await testMain();
}
```

Roteiro por app: `pubspec` com `ref: v1.0.0` e `material_ui: ^1.11.1` → `dart fix --apply --code=migrate_design_widgets`
→ delegates de localização → `test/flutter_test_config.dart` → `flutter-version: 3.50.0` no `ci.yml` e no
`deploy-play.yml` → `flutter analyze` e `flutter test` na 3.50.

A imagem `ghcr.io/cirruslabs/flutter` parou na 3.44.0: para rodar local, monte uma com o SDK oficial por cima dela
(`FROM ghcr.io/cirruslabs/flutter:stable` + `rm -rf /sdks/flutter` + o `flutter_linux_3.50.0-stable.tar.xz` de
`storage.googleapis.com/flutter_infra_release` em `/sdks`) e use `localhost/flutter:3.50.0` nos comandos abaixo.

## v0.28.1: etiqueta do grupo recolhível com fundo opaco (AA)

`Ss::CollapsibleComponent(label:, tone:)`: a etiqueta à direita do título (`.ss-collapse-label`) tinha o
fundo na cor do tom a 14% sobre transparente, e o contraste dependia do que estivesse atrás (4,08–4,40:1
sobre a página clara, medido pela auditoria do meulog no "on" de sucesso). Agora o fundo é o suave opaco do
tom, o mesmo dos selos (`--success-soft`, `--warn-soft`, `--danger-soft`, `--accent-soft`; `--field` no
neutro; info misturado à superfície). Mudança só de cor, sem API.

## v0.28.0: texto apagado AA, faixa de status por dia, busca solta e o que o meulog montou à mão

A segunda rodada do meulog: o que a migração dele montou com peças existentes vira peça ou parâmetro, e o texto
apagado passa a 4,5:1 sobre superfície tingida. Vitrine Rails: "Monitor de erros (v0.28)"; catálogo: `ss-day-strip`,
`ss-filter-input`, `ss-v28-correcoes` (web) e `ss-day-strip` + os estados v0.28 de `ss-bar-chart`, `ss-list-item` (Flutter).

| Peça / parâmetro | Web (Rails) | Flutter |
|---|---|---|
| Faixa de status por dia (página de status; dias com respiro, sem dado vazado) | `Ss::DayStripComponent(days:, title:, start_label:, end_label:, height:, show_title:)`; dia `{ date:, tone: :ok/:warn/:bad/:none, text:, label: }` | `SsDayStrip(days:, title:, startLabel:, endLabel:, height:, showTitle:)` + `SsDay(label, SsDayTone.x, text:)` |
| Busca solta do `ss-filter`, sem `<form>` | `Ss::FilterInputComponent(label:, placeholder:, id:, value:)` (já sai com `data-ss-filter-target="input"` e Esc) | — (o app usa `SsSearchField`) |
| Topo fixo da escala (pequenos múltiplos) | `BarChartComponent(max:)`, `LineChartComponent(max:)` | `SsBarChart(max:)`, `SsLineChart(max:)` |
| Nome do QR para o leitor de tela | `QrCardComponent(qr_label:)` | `SsQrCard(qrLabel:)` |
| Título em 2 linhas / subtítulo inteiro | `CardHeaderComponent(wrap: true)`; `ListItemComponent(subtitle_wrap: true)` (sem ele, o texto inteiro no `title=`) | `SsCardHeader(titleMaxLines:)` (já havia); `SsListItem(subtitleMaxLines:)` |
| Ordenar com rótulo de ação | `DataTableComponent`: o link diz "Total: ordenar decrescente" (I18n `data_table.sort_action`) | — |
| Menu de seções sem item atual | `SubnavComponent`: mostra o `label:`; `count_label:` ("%{n} itens"; `false` tira) | — |
| Fonte extra de uma página | `ss_display_font_tag(self_hosted: true)` no slot `:ss_head`; o layout chama `ss_page_head` no `<head>` | — |
| `ss_select(multiple: true, include_hidden: false)` | aceito (sem o `""` escondido) | — |

```erb
<%= render Ss::DayStripComponent.new(title: "Disponibilidade, 30 dias", start_label: "há 30 dias", end_label: "hoje",
      days: leituras.map { |d| { date: d.dia, tone: d.tom, text: d.resumo } }) %>
<div data-controller="ss-filter">
  <%= render Ss::FilterInputComponent.new(label: "Buscar no manual", placeholder: "Filtrar os verbetes") %>
  <% verbetes.each do |v| %><%= render Ss::ListItemComponent.new(title: v.titulo, data: { ss_filter_target: "item" }) %><% end %>
</div>
<%= render Ss::BarChartComponent.new(title: classe, labels: dias, series: [{ name: classe, values: v }], max: maior_de_todos) %>
<%# na página que precisa da fonte de exibição (o layout tem <%= ss_page_head %> no <head>): %>
<% content_for :ss_head, ss_display_font_tag(self_hosted: true) %>
```

**Correções (web):** `MasonryComponent` não despeja mais o card mais alto numa coluna a mais quando o pai define a
altura (`align-self: start; height: auto`); `AsideLayoutComponent` não alarga a página com filho largo (colunas
`minmax(0, 1fr)`); `.ss-value-row` quebra o valor longo em vez de estourar a 390 px; `f.ss_fieldset` funciona dentro da
seção com `form:` do `SettingsLayoutComponent` (antes `NoMethodError`: o builder chamava o helper no componente).

**Padrões que mudaram.**
- **Texto apagado (web, claro):** `--muted` de `#6e6a88` para `#615e78` (mesmo matiz, mais escuro). Media 3,74–4,44:1
  sobre o brilho do fundo da página (o `--glow` da marca + o azul do canto) e sobre o suave da marca (o × do
  `.ss-fb-chip`, o `.ss-collapse-label`); agora o pior caso, nas 30 paletas, é 4,51:1 (Neon pop, sobre o brilho). O
  escuro/OLED do web (`#9a96b8`, pior 4,72:1) e o Flutter (`#636981` claro, pior 4,52:1; `#9aa0bd` escuro, 5,17:1) já
  passavam e não mudam. O `paletas/gerar.py --check` passa a conferir o texto apagado nos dois lados, nos três temas e
  em todas as paletas (página, superfície, campo, suave e brilho), e que o valor é o do `engine.css`/`app_theme.dart`.
- `SubnavComponent` sem item atual mostrava o primeiro item como atual no menu do celular; agora mostra o rótulo.
- `SsStrings` ganhou `qrLabel`, `dayStripOk`, `dayStripWarn`, `dayStripBad`, `dayStripNone` (obrigatórios no
  construtor, como os da v0.26/v0.27): quem monta um `SsStrings` à mão precisa passá-los (o `copyWith` não).

## v0.27.0: menu lateral com a dica de arrastar e a casca única das abas

Pedido do usuário em 16/11/2026 para todos os apps. Só Flutter: o gesto de arrastar da borda e a barra de abas com o
círculo são do app (no web o menu lateral já é o do `Ss::AppShellComponent`). Tudo aditivo. Catálogo: `ss-side-menu`
(aberto, espiando, borda) e `ss-nav-scaffold` (`flutter/test/catalogo_v27.dart`). Testes: `flutter/test/v27_test.dart`.

| Peça | O que faz |
|---|---|
| `SsNavScaffold(body:, navBar:, sideMenu:)` | **Casca única das abas**: no lugar de `PopScope` + `Scaffold(bottomNavigationBar: SsNavBar(...))` no `MainShell` de cada app. A **faixa acima da barra** (os 22 px onde o círculo sobe) **fica transparente**: o corpo vai até a borda da barra e passa por trás dela, em vez de uma tira do fundo cortando a lista (com a sombra da barra mudando dentro dela a cada troca de aba). O corpo recebe `MediaQuery.padding.bottom = SsNavBar.rise`, então lista com padding padrão e `SafeArea` não ficam embaixo do círculo. O voltar do sistema fecha o menu; fora da 1ª aba vai para ela (`backToFirstTab`); na 1ª, sai |
| `SsSideMenuHost(menu:, child:)` | Menu lateral por cima da tela: abre arrastando da borda esquerda (a faixa fica depois de `systemGestureInsets`, sem brigar com o voltar do Android) ou por `SsSideMenuHost.maybeOf(context)?.open()`; abre com a mola da suíte, fecha arrastando, tocando fora, no voltar ou ao tocar numa linha. **Dica a cada abertura do app** (`peek`, uma vez por processo): o painel abre uma fresta com a coluna de ícones, a pílula "Arraste para abrir o menu" entra com mola e a seta cutuca duas vezes, o painel volta e a borda pisca duas vezes na cor da marca. Não segura o toque (tocar na fresta abre). Sem dica com "reduzir movimento" |
| `SsSideMenu(title:, subtitle:, leading:, sections:, footer:)` | O painel: cabeçalho, seções (`SsSideMenuSection(items, title:)`) de `SsSideMenuItem(icon, label, activeIcon:, subtitle:, onTap:, selected:, badge:, danger:)`, linhas que entram em cascata conforme o painel abre. No `SsNavScaffold` as abas entram como 1ª seção (`tabsInMenu`), com a atual marcada |

Textos novos no `SsStrings` (pt/en/es): `sideMenu`, `sideMenuOpen`, `sideMenuHint`.

```dart
// MainShell de cada app (o mesmo desenho em todos):
return SsNavScaffold(
  body: navigationShell,
  navBar: SsNavBar(items: _tabs, currentIndex: navigationShell.currentIndex, onTap: _go),
  sideMenu: const SsSideMenu(title: 'Minhas Vendas', sections: [/* atalhos do app, opcional */]),
);
```

**Padrões que mudaram:** nada muda sem `SsNavScaffold`. Quem trocar o `Scaffold` pelo `SsNavScaffold` passa a ter o
conteúdo por trás da faixa do círculo: o fim da lista precisa do respiro normal (o `padding` padrão do `ListView` já
lê os 22 px; `ListView(padding: EdgeInsets.all(16))` explícito fica com 16 + nada, então o último item pode passar por
trás do círculo: some com `safeListPadding`/`SsFab.clearance` ou somando `MediaQuery.paddingOf(context).bottom`).

## v0.27.0 (meulog): gráficos sem Chart.js, ícones de monitor de erros e fontes sem CDN

O que a migração do meulog (monitor de erros self-hosted, Bootstrap → componentes-ui) pediu. Tudo aditivo: sem os
parâmetros novos, nada muda. Vitrine Rails: "Monitor de erros (v0.27)" (`pecas_v027`); catálogo: `ss-linec`,
`ss-barc-horizontal`, `ss-chart-mark`, `ss-icon-v27` (`rails/sample/script/catalogo_v027.rb`) e, no Flutter, os estados
novos em `ss-line-chart`/`ss-bar-chart` (`flutter/test/catalogo_v27_graficos.dart`). Testes:
`rails/sample/test/components/v27_web_test.rb`, `flutter/test/v27_graficos_test.dart`.

| Peça | Flutter | Rails / CSS |
|---|---|---|
| Linhas por categoria (retas, várias séries, anterior tracejada, áreas empilhadas, vazio) | `SsLineChart(curved: false, markers:, empty:)` + `SsSeries(dashed: true)` (empilhado só no web) | `Ss::LineChartComponent(labels:, series:, title:, stacked:, format:, height:, width:, label_every:, legend:, show_title:, active:, dots:, markers:, empty:)` · `.ss-linec` |
| Barras deitadas (rótulo longo à esquerda com reticências, valor no fim) | `SsBarChart(horizontal: true)` | `BarChartComponent(horizontal: true)` · `.ss-barc.is-horizontal` |
| Cor por valor numa série (a categoria "Outros" apagada) | `SsSeries(colors: [null, …, c.muted])` | série `{ tones: [nil, …, :muted] }` ou `{ colors: [nil, "var(--…)"] }` |
| Marcas verticais (deploy, incidente, nota) | `markers: [SsChartMarker(at:, label:, kind: SsChartMarkerKind.deploy)]` em `SsBarChart` e `SsLineChart` | `markers: [{ at:, label:, kind: :deploy/:incident/:note }]` em `BarChartComponent` e `LineChartComponent` · `.ss-chart-mark` |
| Vazio do gráfico | `empty:` → `SsChartEmpty` | `empty:` → `.ss-chart-empty` |
| Ícones do monitor de erros | `SsIcons.named('bug')` … | `ss_icon("bug")` … |
| Fontes servidas pelo app (rede fechada) | — (o pacote já empacota) | `ss_font_tags(self_hosted: true)` |

```erb
<%= render Ss::LineChartComponent.new(title: "Ocorrências por dia", labels: dias, width: 1100,
      series: [{ name: "Agora", values: agora }, { name: "Semana anterior", values: antes, tone: :muted, dashed: true }],
      markers: deploys.map { { at: _1.dia, label: _1.versao, kind: :deploy } }, empty: "Sem dados no período") %>
<%= render Ss::BarChartComponent.new(title: "Erros por classe", horizontal: true, labels: classes,
      series: [{ name: "Ocorrências", values: totais, tones: [*Array.new(classes.size - 1), :muted] }]) %>
```

**Marcas.** Traço tracejado de cima a baixo no rótulo `at:` e o nome no alto (DM Mono 11); deploy em `--ss-info`,
incidente em `--danger`, nota em `--muted` (kind desconhecido = nota). Duas no mesmo rótulo empilham o texto e a área de
cima cresce 13 px por linha. Entram na dica do rótulo, numa coluna "Marcas" da tabela do leitor de tela (pt/en/es:
`componentes_ui.chart.markers` e `chart.marker.*`) e, no Flutter, no rótulo de semântica. Não valem no deitado.

**Fontes sem CDN.** `ss_font_tags` junta o que cada layout escrevia à mão:

```erb
<%= ss_font_tags %>                                    <%# Google Fonts, como antes (padrão) %>
<%= ss_font_tags(self_hosted: true) %>                 <%# Manrope 400–800 e DM Mono 400/500 da própria gem %>
<%= ss_font_tags(self_hosted: true, display: true) %>  <%# e a Big Shoulders Display (tela de entrada) %>
```

Os woff2 ficam em `rails/app/assets/fonts/componentes_ui/` (OFL 1.1, com as licenças ao lado) e os `@font-face` em
`rails/app/assets/stylesheets/componentes_ui/fonts.css` / `fonts_display.css`, servidos pelo **Propshaft** (fora do
Tailwind): ele troca cada `url()` pelo caminho com digest. O helper ainda faz `preload` da Manrope 400 e 700. Nenhuma
requisição sai do app (a vitrine passou a carregar assim; CSP `font-src 'self'` basta).

**Ícones.** 16 novos no `ss_icon`/`SsIcons` (desenho do Lucide, ISC, `rails/icones/LICENSE-lucide`, redesenhado no traço
24/2 do conjunto): `activity`, `bug`, `git-branch`, `git-merge`, `robot`, `broadcast`, `webhook`, `tree-structure`,
`signpost`, `stack`, `brackets-curly`, `file-code`, `file-csv`, `hard-drives`, `gauge`, `compass`. Apelidos novos
(nomes do Lucide e do Phosphor): `heartbeat`/`pulse` → activity, `bot` → robot, `network`/`tree-view`/`flow` →
tree-structure, `layers` → stack, `braces`/`code-json` → brackets-curly, `file-spreadsheet` → file-csv,
`hard-drive`/`server-stack` → hard-drives, `kanban`/`columns` → view-boards, `palette` → color-swatch, `prohibit` → ban,
`funnel` → filter, `arrows-merge`/`git-pull-request` → git-merge, `live`/`radio` → broadcast e, do Phosphor, `gear`,
`gear-six`, `list`, `list-bullets`, `house`, `info`, `warning`, `warning-circle`, `warning-octagon`, `copy`,
`pencil-simple`, `note-pencil`, `notebook`, `book`, `arrows-clockwise`, `envelope`, `globe-hemisphere-west`, `moon-stars`,
`buildings`, `currency-circle-dollar`, `chart-line-up`, `shield-warning`, `puzzle-piece`, `package`, `paperclip`,
`upload-simple`, `tray-arrow-down`, `lightbulb`, `question`, `bookmark-simple`, `door-open`, `caret-*`,
`sliders-horizontal`, `hand-pointing`, `map-trifold`, `list-checks`, `squares-four`, `arrows-left-right`, `file-text`,
`clipboard-text`, `user-circle-gear`, `trash-simple`, `magnifying-glass-plus`.

**Padrões que mudaram:** nenhum. `SsSeries` ganhou `dashed:` e `colors:` opcionais; `SsLineChart` continua curvo por
padrão (`curved: false` é o que o web faz).

**Contraste do menu (web).** A auditoria de acessibilidade do meulog mediu os títulos de grupo do
`AppShellComponent` (`.ss-nav summary`, 45% da tinta do menu) em 3,4–3,9:1 e o rótulo "Empresa/Conta"
da troca de empresa (50%) em 4,0–4,3:1, abaixo de 4,5. Os dois passam a 62% (≥ 5,6:1 no claro e no
escuro); o hover do título de grupo vai a 85%. Mudança só de cor, sem API.

## v0.26.0: conversa entre pessoas (cliente e atendente)

Pedido do minhas-vendas (atendimento do WhatsApp: a atendente da loja conversa com o cliente). O chat da suíte só sabia
"eu × assistente de IA"; agora a mesma peça desenha uma conversa entre pessoas. Tudo aditivo: sem os parâmetros novos, o
chat é o da v0.25. Catálogo: estados `pessoas` e `situacoes` no `ss-chat` e o `ss-chat-divider` novo
(`flutter/test/catalogo_v26.dart`); seções `ss-chat-pessoas`, `ss-chat-divider` e `ss-bubble-media` em
`rails/catalogo/index.html` (`rails/sample/script/catalogo_v026.rb`). Testes: `flutter/test/v26_test.dart` e
`rails/sample/test/components/v26_web_test.rb`. CSS em `v26_web.css`.

| Peça | Flutter | Rails / CSS |
|---|---|---|
| A outra pessoa | `SsChatBubble(fromMe: false, aiMark: false)`: à esquerda, na superfície, **sem** o ✦ (o horário encosta na bolha) | `Ss::ChatComponent::Message.new(from: :them, ...)` → `.ss-bubble.is-them[data-from=them]` |
| Quem escreveu | `author: 'Ana · pelo celular'`: legenda pequena em negrito no alto da bolha (apagada; no meu, branco translúcido) | `author: "Ana · pelo celular"` → `<span class="ss-bubble-author">` no alto da bolha |
| Situação | `SsChatStatus.sending/sent/delivered/read/failed` (novos: `delivered` ✓✓ apagado, `read` ✓✓ em `accentText`); nome no leitor de tela por `SsStrings.chatDelivered`/`chatRead` | `status: :sending/:sent/:delivered/:read/:failed` → `<small class="num ss-bubble-foot"><span class="ss-bubble-time">…</span><span class="ss-bubble-status" data-status="read"><svg/><span class="ss-sr">Lida</span></span></small>`; `:failed` mostra "Não enviada" à vista no tom de perigo (na bolha da marca, numa pílula da superfície); lida na marca (`--accent`; na bolha da marca, `--on-accent` cheio). Textos em `chat.status.*` (pt-BR, en, es) |
| Separador de dia | `SsChatDivider(label: 'Hoje')` | `Ss::ChatDividerComponent.new(label: "Hoje")` → `<div class="ss-chat-divider" role="separator" aria-label="Hoje"><span>Hoje</span></div>` |
| Mídia na bolha | `child:` (já existia) | `<img>`/`<video controls>`/`<audio controls>` com `class="ss-bubble-media"` (até a largura da bolha; o áudio com 16rem no mínimo) e documento como `<a class="ss-bubble-file"><svg/><span>nome.pdf</span><span class="ss-bubble-file-meta">PDF · 84 KB</span></a>` |

Assinaturas:

```ruby
Ss::ChatComponent::Message.new(from: :me | :ai | :them, text: nil, time: nil, status: nil, author: nil, **rest)  # status: :sending, :sent, :delivered, :read, :failed
Ss::ChatDividerComponent.new(label:, **rest)
```

```dart
enum SsChatStatus { sending, sent, delivered, read, failed }
SsChatBubble({String? text, Widget? child, required bool fromMe, String? time, SsChatStatus? status, String? author, bool aiMark = true})
SsChatDivider({required String label})
```

**O bloco do `Ss::ChatComponent` entra dentro do log.** O que vem no bloco é renderizado dentro do `.ss-chat`
(`id="<id>-messages"`, `role="log"`), depois do slot `messages`: dá para intercalar mensagens e separadores renderizando
direto, e o Turbo Stream `append` em `Ss::ChatComponent.messages_id(id)` continua caindo no mesmo lugar. O slot `empty` só
aparece sem mensagem nenhuma (nem no slot, nem no bloco).

```erb
<%= render(Ss::ChatComponent.new(id: "conversa", url: conversa_mensagens_path(@conversa), echo: false, placeholder: "Responder")) do %>
  <% @mensagens.group_by(&:dia).each do |dia, msgs| %>
    <%= render Ss::ChatDividerComponent.new(label: dia) %>
    <% msgs.each do |m| %>
      <%= render Ss::ChatComponent::Message.new(from: m.da_loja? ? :me : :them, author: m.autor, text: m.texto, time: m.hora, status: m.situacao) %>
    <% end %>
  <% end %>
<% end %>
```

```dart
ListView(children: [
  const SsChatDivider(label: 'Hoje'),
  SsChatBubble(text: m.texto, fromMe: m.daLoja, aiMark: false, author: m.autor, time: m.hora, status: m.situacao),
]);
```

Com `echo: true` (padrão) a bolha da pessoa entra na hora ao enviar, como antes; numa conversa entre pessoas costuma ser
melhor `echo: false` e a resposta do envio (`turbo_stream.append`) trazer a mensagem com `status: :sending`/`:sent`, e
depois um `replace` dela quando chegar entregue/lida. O "pensando" (`thinking:`) é da IA: numa conversa entre pessoas não
precisa ligar.

**Como cada produto adota:** subir a tag; nada muda sem os parâmetros novos. **Padrões que mudaram:** nenhum (o bloco do
`ChatComponent` antes era ignorado; agora entra no log). **Textos novos:** Rails `chat.status.{sending,sent,delivered,read,failed}`,
Flutter `SsStrings.chatDelivered` e `chatRead` (pt, en, es).

## v0.25.2: o botão do cabeçalho com selo tem nome no leitor de tela

Achado das videoaulas do meu-gestor (15/11/2026): no `SsHeaderAction` com `badge`, o leitor de tela lia só o número do
selo ("7") e o botão ficava sem nome (conferido pelo `uiautomator` no emulador), embora o produto passasse
`tooltip: 'Notificações, 7 novas'`. Agora o nome do botão é o `tooltip`, uma vez só (o `Tooltip` fica fora da semântica e o
ícone com o selo vira só visual); o balão do toque longo continua. Teste que reproduz (falha na v0.25.1):
`flutter/test/ss_header_action_test.dart`. Só Flutter; o web não muda.

**Como cada produto adota:** subir a tag; nada de código. Quem usa selo no `SsHeaderAction` deve pôr no `tooltip` o que o
número quer dizer ("Notificações, 7 novas"), porque o número sozinho não é mais lido.

**Padrões que mudaram.** O `tooltip` do `SsHeaderAction` é o rótulo do botão no leitor de tela (antes ia como dica, e o
selo virava o rótulo).

## v0.25.1: o rótulo da barra de abas volta para a Manrope

Regressão da v0.25.0: o rótulo das abas da `SsNavBar` ficava num `AnimatedDefaultTextStyle` com um `TextStyle` novo, sem
família; ele troca o estilo herdado inteiro, então o rótulo saía na fonte do sistema no celular (e em caixinhas nas capturas
de teste, que não têm fonte do sistema). Agora o estilo do rótulo leva a família do tema
(`Theme.of(context).textTheme.bodyMedium?.fontFamily`, o mesmo padrão do `SsTabBar`). Teste que reproduz (falha na v0.25.0):
"rótulo da aba usa a fonte do tema" em `flutter/test/ss_nav_bar_test.dart`. Conferido no Flutter 3.44 e 3.47.9. Só Flutter;
o web não muda.

**Como cada produto adota:** subir a tag; nada de código. Apps com `SsNavBar` na v0.25.0 (minhas-vendas-app, meu-gestor-app)
devem subir; conferir uma captura da barra com o rótulo na Manrope.

**Padrões que mudaram.** Nenhum (volta ao desenho pretendido na v0.25.0).

## v0.25.0: rodada 5 da auditoria de UX (grupo recolhível no celular e a barra de abas do app)

Três achados de peça genérica: o grupo recolhível que alargava a página no celular (minhas-vendas, onda 2: Configurações ›
Vendas e preços em 390 px) e a barra de abas do app (meu-gestor-app: a aba ativa sem rótulo; o círculo dela sumindo no
escuro). Testes que reproduzem cada achado (falham na v0.24.0): `rails/sample/test/components/v25_web_test.rb` e
`flutter/test/v25_test.dart`. Catálogo: `flutter/test/catalogo_v25.dart` (estados e comportamentos novos em `ss-nav-bar` e
`ss-collapsible`) e a seção `ss-collapsible-v25` em `rails/catalogo/index.html` (`rails/sample/script/catalogo_v025.rb`).
CSS em `v25_web.css`; conferido no Chromium em 390 e 1440 (claro e escuro) e no Flutter 3.44 e 3.47.9.

| Achado | Rails / CSS | Flutter |
|---|---|---|
| Título do grupo recolhível não quebra e alarga a página (735 px num celular de 390) | `CollapsibleComponent`: o `.ss-collapse-title` quebra linha (até 2, depois reticências; `overflow-wrap: anywhere`) com o texto inteiro no `title=`; `.ss-collapse` com `min-width: 0; max-width: 100%` (cabe no pai mesmo como item de grid/flex); seta, contagem e selo não encolhem | `SsCollapsible`: título em até 2 linhas (era 1), o mesmo do web |
| A aba ativa da barra vira só ícone (sem "Hoje") | — (o web não tem barra de abas embaixo) | `SsNavBar`: **todas as abas mostram o rótulo**; o da aba atual fica no lugar dela, embaixo do círculo, na tinta da marca (`accentText`, negrito); só o ícone dela sai da barra (está no círculo). Leitor de tela: "Hoje, aba 1 de 4", selecionada, agora **com a ação de tocar** no nó da aba (o `excludeSemantics` tirava a do `InkResponse`) |
| O círculo da aba ativa (surface sobre surface) quase some no escuro | — | `SsNavBar`: anel de 2 px (`SsNavBar.ringWidth`) na `SsNavBar.ringColor(c)` = `c.inkFor(c.accent)` (≥ 4,5:1 sobre a barra e a página em todas as 30 paletas, claro, escuro e OLED; 7:1 no alto contraste; o mínimo de borda é 3:1) e, no escuro/OLED, miolo em `field` (um degrau acima da barra). De quebra: com contagem (`badge:`) na aba atual, o ícone do círculo ficava preso no canto de cima; agora fica no centro |

**Como cada produto adota** (subir a tag; nada de código obrigatório):

- **minhas-vendas (web):** Configurações › Vendas e preços ("Avançado: kit, margem e vencimento") deixa de alargar a página
  em 390 px só com a tag. Conferir em 390 e 1440 as telas com `CollapsibleComponent`.
- **meu-gestor-app:** a barra de abas mostra "Hoje" na aba ativa e o círculo aparece no escuro/OLED só com a tag. Teste de
  widget do produto que procurava o rótulo da aba atual com `findsNothing` (ou que contava `find.text('Hoje')`) passa a achá-lo.
- **Outros apps com `SsNavBar`** (meu-financeiro, meu-personal, meu-cultivo, minhas-compras, minhas-viagens, minhas-vendas-app):
  recebem o rótulo da aba ativa, o anel e o ícone centrado ao subir a tag; conferir a barra em claro, escuro e OLED.
- **Outros webs com `CollapsibleComponent`:** o título passa a quebrar em vez de cortar numa linha.

**Padrões que mudaram.**

- **`SsNavBar`**: a aba atual mostra o rótulo (antes o lugar dela na barra ficava vazio) e o círculo ganha anel na cor da
  marca em todo tema (no claro também: o anel substitui a separação que só a sombra fazia); no escuro o miolo do círculo é
  `field` em vez de `surface`. Cada aba no leitor de tela agora tem a ação de tocar.
- **`SsCollapsible` / `CollapsibleComponent`**: título em até 2 linhas (antes 1 linha com reticências; no web o nowrap
  podia alargar a página).

## v0.24.0: o que a auditoria de UX de novembro achou nas peças genéricas (minhas-vendas e meu-gestor)

Os achados marcados como componentes-ui nos relatórios `minhas-vendas-workspace/docs/auditoria-ux-2026-11/RELATORIO.md`
(C01–C04) e `meu-gestor-workspace/docs/auditoria-ux-2026-11/RELATORIO.md` (B05, B06, B07, B10, B13, B16, B18, U07, U08, U14).
Quase tudo é aditivo; o que muda desenho padrão está em "Padrões que mudaram". Testes que reproduzem cada achado (falham na
v0.23.6): `rails/sample/test/components/v24_web_test.rb` e `flutter/test/v24_test.dart`. Vitrine Rails "Auditoria de UX (v0.24)"
(`?empresas=1|2` mostra a troca de empresa). Catálogo: `flutter/test/catalogo_v24.dart` (`ss-ai-insight-card` novo e estados/
comportamentos em `ss-data-table`, `ss-button`, `ss-fab`, `ss-choice-field`, `ss-menu`) e as seções `ss-data-table-compact`,
`ss-actions-v24`, `ss-settings-v24`, `ss-shell-tenant` e `ss-ai-card-v24` em `rails/catalogo/index.html`
(`rails/sample/script/catalogo_v024.rb`). CSS em `v24_web.css`; conferido no Chromium (390 com toque, 1440 e 1536).

| Achado | Rails / CSS | Flutter |
|---|---|---|
| C01 lista no celular vira cartões enormes | `DataTableComponent(mobile: :compact)` + `t.column(..., mobile: :title \| :value \| :meta \| :badge \| :hide)`: abaixo de 640 px, uma linha de lista em duas linhas (título e valor em cima; metas com `·` e o selo embaixo). Sem papel: 1ª coluna = título, 1ª de dinheiro = valor, resto = meta; ações no fim, seleção/expansão antes do título; o total vira "Total ……… valor". `stack: false` vence | `SsDataTable(mobile: SsDataTableMobile.compact)` + `SsDataColumn(mobile: SsDataSlot.title \| value \| meta \| badge \| hide)` (sem papel: 1ª = título, 1ª `numeric` = valor) |
| C02/U14 seletor de empresa com uma empresa só; nome cortado seco | `AppShellComponent`: menu de troca só com 2+ empresas; com uma, o nome parado (`.ss-shell-tenant.is-single`, sem seta nem menu); `single_tenant: false` esconde. Nome em `.ss-shell-tenant-name` com reticências e o nome inteiro no `title=` | — (o app não tem a moldura do web) |
| C04/E02/B07 Configurações numa página com vários Salvar | `SettingsLayoutComponent`: `s.with_section(..., form: { model:, url:, method: }, save_label:, save_always:)` faz da área um formulário (com `ss-validate`) com o próprio Salvar numa `StickyActionBarComponent` que só aparece quando aquela área muda (campos pelo `sec.form`); `href:` + `current:` fazem do menu a navegação entre áreas em páginas (sem scrollspy, só a atual aparece) | — (no app, Configurações é o `SsMenuView`) |
| C04/E02b/V02 `.ss-actions` flutua sobre o campo | `.ss-actions` vira faixa opaca de largura inteira (`grid-column: 1 / -1`), presa embaixo só dentro do próprio form; a página com barra fixa ganha `scroll-padding-bottom` e os campos `scroll-margin-bottom` (`--ss-bar-room`): o foco por Tab, o 1º campo com erro e a âncora param acima da barra | `SsStickyActionBar` já vai no `bottomNavigationBar:` (reserva o espaço); nada a mudar |
| B10 a busca rápida precisa de dois Esc | `ss-command`: **um Esc fecha**, com ou sem texto (o padrão de VS Code, GitHub, Linear e das paletas cmdk; antes o 1º Esc do `input type="search"` só limpava). Ao fechar, o foco volta a quem abriu (ou sai do campo) e os atalhos de uma tecla (`?`, `g p`) respondem de novo | — |
| B05/B06 Pergunte à IA transborda; tabela da resposta cortada | `.ss-chat-empty` não passa da largura do painel (perguntas de exemplo quebram linha); `.ss-bubble` com tabela ocupa a largura e a tabela (`DataTableComponent` ou `<table>` solta) rola de lado dentro dela, sem partir palavra | — |
| U07 toques de 32 px no celular | Só com `@media (pointer: coarse)`: `.ss-btn-sm`, `.ss-tab`, `.ss-subnav a`, `.ss-settings-nav a`, paginação e itens da troca de empresa com `min-height: var(--ss-target)` (44; 48 no confortável); `.ss-icon-btn`, `.ss-dt-toggle` e `.ss-shell-collapse` ganham área de toque invisível de 44 sem mudar o desenho. Busca da barra de cima com `aria-label`; link da marca com o nome | já era 48 (`SsTapTarget`) |
| B13 balão "Preencha este campo" ao passar o mouse | Causa: o Chrome mostra a mensagem de validação como dica do campo inválido enquanto o form valida sozinho. `ss_form_with(validate: :ss)` (padrão) liga o Stimulus `ss-validate`: põe `novalidate` no form (pelo JS: sem JS fica a validação do navegador), confere ao sair do campo e ao enviar, mostra a mensagem em `.ss-field-error` (cria se o campo não tinha), foca o 1º errado e para o envio; `formnovalidate` envia sem conferir. `validate: :native` deixa como era | — |
| U08/U12 botão flutuante cobre o conteúdo | Página com `.ss-fab`/`.ss-speed-dial` ganha `scroll-padding-bottom` (o foco não para embaixo dele) e, fora da moldura, folga no fim do `<body>` (na moldura ela já vinha no `.ss-shell-main`) | `SsFab.clearance(context)` e `safeListPadding(context, fab: true)`: a folga do botão no fim da lista |
| B16 IA trava a tela | `AiInsightCardComponent(thinking: true, cancel: { label:, url:, method: } \| { label:, data: })` e `thinking_hint:` ("Pode continuar usando a tela."; `""` tira) | **novo** `SsAiInsightCard` (par do componente web): selo IA, `confidence`, `whenText`, `title`, `text`/`child`, `sources`, `onApply`/`onDismiss` e `thinking` com a espera dentro do cartão, segundos depois de `showElapsedAfter` (5 s) e `onCancel`. Textos `SsStrings.aiBadge`, `aiThinking`, `aiThinkingHint`, `aiApply`, `aiDismiss`, `aiSources`, `aiConfidence` |
| B16 "Explicar com IA" sem nó próprio | — | `SsButton` é nó próprio de acessibilidade (`Semantics(container:, button:, enabled:)`) |
| B18 teclado reabre sozinho | — | `SsMenuView`: tocar fora da busca solta o foco dela, e abrir um item (`SsMenuCard`/`SsMenuRow`) solta o foco antes; `SsChoiceField`, `SsDateField`/`SsDateTimeField` e `SsTimeField` soltam o foco antes de abrir a folha (fechar não reabre o teclado) |

**Como cada produto adota** (subir a tag; o resto é opcional e por tela):

- **minhas-vendas (web):** listas de Pedidos, Produtos, Caixas, Contas… com `mobile: :compact` e o papel de cada coluna (C01/U01);
  Configurações em áreas com `SettingsLayoutComponent(form:)` ou `href:` (E02, C04); `.ss-actions` e o seletor de empresa
  passam a valer sozinhos ao subir a tag (E02b, V02, C02). Conferir as telas com `.ss-actions` (Configurações, Novo pedido,
  Novo produto) em 390 e 1440.
- **meu-gestor (web):** Configurações (Regras, Precificação) com uma área por formulário (`form:`) ou em páginas (B07);
  o Pergunte à IA, a busca rápida e a troca de empresa melhoram só com a tag (B05, B06, B10, U14); alvos de 44 no celular
  e a validação sem balão também (U07, B13). Quem usava `form_with` cru continua com o balão: troque por `ss_form_with`.
- **meu-gestor-app:** trocar o `AiThinking` local da Sugestão de compra e da Revisão de preços pelo `SsAiInsightCard(thinking:,
  onCancel:)` e o `explainWithAiButton` (Semantics à mão) por `SsButton`; tirar os `leave(...)`/`unfocus()` do `more_screen.dart`
  e os `Listener(onPointerDown: unfocus)` do `dynamic_form.dart`/`new_card_screen.dart` (o pacote faz); listas com FAB com
  `safeListPadding(context, fab: true)` (U12).
- **Outros produtos:** recebem o `.ss-actions` novo, o seletor de empresa, o alvo de toque, o Esc da paleta, o chat e a
  validação do `ss_form_with` ao subir a tag; `mobile: :compact` e `SsAiInsightCard` quando quiserem.

**Padrões que mudaram.**

- **`.ss-actions`**: de pílula translúcida do tamanho dos botões (`width: fit-content`, `backdrop-filter`) para faixa opaca
  (`--surface`) de largura inteira, `grid-column: 1 / -1`, presa a `0,75 rem` do fim. Quem punha `md:col-span-*` na barra
  continua igual (a faixa já ocupa a linha).
- **`ss_form_with`** liga o `ss-validate` (o form fica `novalidate` pelo JS): sem o balão nativo no envio nem a dica ao passar o
  mouse; a mensagem aparece embaixo do campo. `validate: :native` volta ao de antes.
- **`AppShellComponent`** com uma empresa: o nome parado no lugar do `<details>` com um item só.
- **`AiInsightCardComponent(thinking: true)`** ganha a linha "Pode continuar usando a tela." (`thinking_hint: ""` tira).
- **No celular (`pointer: coarse`)**, `.ss-btn-sm`, abas (`.ss-tab`, `.ss-subnav a`, `.ss-settings-nav a`) e a paginação da
  tabela ficam com 44 px de altura (eram 32–36). No computador, nada.
- **Paleta de comandos**: o 1º Esc fecha (antes limpava o texto).
- **Flutter**: `SsButton` vira nó próprio no leitor de tela (teste de produto que procurava o rótulo do botão junto com o texto
  do cartão precisa olhar o botão sozinho); `SsChoiceField`/`SsChoiceField`/`SsTimeField` e o `SsMenuView` soltam o foco do
  campo de texto ao abrir a folha ou o item.

## v0.23.5: área segura do celular (`viewport-fit=cover`)

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
podman run --rm --security-opt label=disable -v "$PWD":/r -w /r/flutter -v flutter_pub350:/root/.pub-cache localhost/flutter:3.50.0 \
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

- `v1.14.3` (28/11/2026): seção "v1.14.3". Só Flutter: `showSsSheet`/`showSsFilterSheet`/`showSsPopover(useRootNavigator: true)` (e as folhas que passam por eles, como o `showSsExplain`) abrem pelo `Navigator` raiz, por cima da barra de abas do `SsNavScaffold`; a chave do `SsDeviceTile` com nó de 48 (`SsTapTarget(semantics: true)`). Desenho igual, catálogo sem mudança.
- `v1.14.2` (27/11/2026): seção "v1.14.2". `SsNotificationCenter(unarchive:, loadArchived:, initialView:)` ↔ `Ss::NotificationCenterComponent(archive_undo:, archived_url:, inbox_url:, archived:)` e `unarchive_href:` por aviso (desfazer do arquivar e a aba Arquivadas), o job do iOS na CI (`ios.yml`) e a origem do logo da Apple escrita (o oficial não entra por licença). Migração: tirar o `showSsUndo` dos apps.
- `v1.14.1` (27/11/2026): seção "v1.14.1". `SsCommand(subtitle:)` (paleta e busca do `SsSideMenu`) ↔ `aria-label` no item com `subtitle:` do `Ss::CommandPaletteComponent`, `SsTextField(textAlign:)`/`SsMoneyField(textAlign:)` ↔ `f.ss_*(align: :end)`, `SsAdaptiveScaffold(tabTransition:)` e `find.ssValue` no `testing.dart`. Muda o padrão do `SsMoneyField` (valor à direita).
- `v1.14.0` (27/11/2026): seção "v1.14.0" (interface e animação). Scrub nos gráficos (`SsScrubDetector` ↔ `ss-scrub`), `SsPeriodCompare` ↔ `Ss::PeriodCompareComponent`, `SsExpandableRow` ↔ `Ss::ExpandableRowComponent`, `Ss::SelectionBarComponent` + `ss-selection`, `showSsSheet(detents:)` ↔ `DrawerComponent(detents:)`, ícone animado na barra, `SsMeshBackground` ↔ `Ss::MeshBackgroundComponent`, odômetro padrão no KPI, `collapseTint`/`collapse_tint`, `SsSuccessCheck` ↔ `Ss::SuccessCheckComponent` (+ `SsSounds`/`ss:sound`), `SsTiltCard` ↔ `Ss::TiltCardComponent`, `SsSharedAxisTransition`/`SsTabHero` ↔ View Transitions + `ss_tab_hero`, `SsSkeleton.of` ↔ `ss_skeleton_for`. Nada quebra na API; muda o padrão do KPI (odômetro) e da troca de aba do `SsNavScaffold`.
- `v1.13.0` (27/11/2026): seção "v1.13.0" (confiança na IA e suíte).
- `v1.12.0` (27/11/2026): seção "v1.12.0" (Kit Brasil). `SsPixCard` ↔ `Ss::PixCardComponent`, `SsNfeCard` ↔ `Ss::NfeCardComponent`, `SsSmartPaste` ↔ `Ss::SmartPasteComponent` (detector igual em Dart, Ruby e JS), `SsPixKeyField`/`SsBoletoField`/`SsCepField`/`SsDocumentField` ↔ `f.ss_pix_key`/`ss_boleto`/`ss_cep`/`ss_document`, QR puro (`SsQrCode`/`SsQrImage` ↔ `ComponentesUi::Qr`/`ss_qr_svg`), `SsBr` ↔ `ComponentesUi::Br` e os formatadores `SsFormats.cpf/cnpj/cep/phoneBr/boleto/nfeKey` ↔ `ss_*`. Nenhuma dependência nova. Nada quebra na API.
- `v1.11.0` (27/11/2026): seção "v1.11.0" (adaptativa). `SsPlatform`/`SsPlatformScope` e `adaptive:` nas peças: no iOS, `CupertinoSwitch`, roda de data e hora, folha de ação (`showSsPicker` curto, `SsOverflowMenu`, `SsContextMenu`), `CupertinoAlertDialog` no `showSsConfirm`, `CupertinoSliverRefreshControl`, haptics do iOS, × na `SsSheet`, transição do iOS no tema e a alça do menu que cede ao voltar do sistema em rota empilhada. `SsAppleButton` ↔ `Ss::AppleButtonComponent`, `SsAuthLayout(providers:)` ↔ `with_provider`, `ss_platform`. Dependência nova: `cupertino_ui`. Nada quebra na API; no Android o desenho não muda.
- `v1.10.0` (27/11/2026): seção "v1.10.0". Dívida de paridade zerada: 21 pares Rails das peças do Flutter e `SsProductCard`, `SsFilterBar`/`SsFilterSheet`, `SsJobProgress`, `SsTreeView` e `SsPopover` no app. Nada quebra na API.
- `v1.8.3` (24/11/2026): seção "v1.8.3". Chat sem `required` no campo (só `aria-required`): some o balão nativo ao parar o mouse. Nada quebra na API.
- `v1.8.2` (23/11/2026): seção "v1.8.2". Tempo relativo com U+00A0 entre número e unidade (Flutter e Rails) e nome do ranking em até 2 linhas. Nada quebra na API; teste que compara o texto com espaço comum precisa do U+00A0.
- `v1.7.1` (19/11/2026): seção "v1.7.1". Botão do Google (GIS) sem a caixa branca do iframe no tema escuro. Só web, só CSS. Nada quebra.
- `v1.7.0` (19/11/2026): seção "v1.7.0". Tela de entrada "Cartaz + papel": `Ss::AuthLayoutComponent(variant: :cartaz, layout: :split, word:, facts:, icon:)` ↔ `SsAuthLayout.cartaz(...)` (`SsAuthCartaz`, `SsCartazLayout`, `SsCartazColors`); `--brand-deep/--brand-from/--brand-to` no `paletas.css` e no `brand_css`; o `gerar.py` confere o contraste do cartaz. Nada quebra na API.
- `v1.6.0` (18/11/2026): seção "v1.6.0". Ajuda na moldura: `Ss::HelpMenuComponent` (Stimulus `ss-help`) no slot `help` do `Ss::AppShellComponent` ↔ `SsHelpMenu.section`; `SsSideMenuItem(external:, badgeLabel:)`; textos novos obrigatórios no `SsStrings` (`help*`, `opensOutside`). Nada quebra na API.
- `v1.5.1` (17/11/2026): seção "v1.5.1". Entrada mais calma: faixa do produto em tom suave, botão principal sólido na entrada e carimbo na cor do produto. Só web, só CSS. Nada quebra na API.
- `v1.5.0` (17/11/2026): `SsChatInput(attachments: [SsChatAttachment(nome, icon:, onRemove:)])`: anexos pendentes como chips com × acima do campo; com anexo, enviar vale com o campo vazio (`onSend('')`) e o anexo só vai no toque do enviar. Corrige `ssComponentesUiVersion` (a v1.4.2 saiu com 1.4.1). Só Flutter. Nada quebra na API.
- `v1.4.2` (17/11/2026): `SsNavScaffold` com o teclado aberto não reserva mais a faixa da barra: o corpo vai até o teclado (antes ficava um vão vazio entre o campo e o teclado, ex. o chat). Só Flutter. Nada quebra na API.
- `v1.4.1` (17/11/2026): seção "v1.4.1". `ChatComponent` com `novalidate`, `ss-scrollspy` pela linha de leitura e `ss-reveal` com rádios. Nada quebra na API.
- `v1.2.2` (17/11/2026): seção "v1.2.2". O rótulo dos campos (`SsTextField`, `SsMoneyField`) é o nome do campo no leitor de tela, dentro e fora de lista, sem leitura dupla; `SsChoiceField`/`SsTimeField` sem o rótulo repetido. Só Flutter. Nada quebra na API.
- `v1.2.1` (17/11/2026): seção "v1.2.1". `TimelineHorizontalComponent` sem rolagem (marcos dividem a largura; em pé abaixo de 36rem) e `StepperInputComponent(decimals:)` com vírgula pelo idioma da página e o ponto num hidden. Nada quebra na API.
- `v1.2.0` (17/11/2026): seção "v1.2.0" (auditoria de UX e videoaulas do minhas-vendas). `RepeaterComponent(mobile: :compact, details_label:)` + `r.cell(:primary/:inline/:detail)` ↔ `SsRepeater(mobile: SsRepeaterMobile.compact, compactBelow:)` + `SsRepeaterCell(role:)` + `SsRepeater.compactOf`/`cells(detailsOpen:)` e o texto `repeaterDetails`; `scroll-padding-top` com a barra do topo da moldura (`--ss-top-room`); rótulos do eixo X pela largura do maior rótulo e a partir do ativo (`BarChart`, `LineChart`, `SsBarChart`, `ssAxisLabelStep`); `DataTableComponent(select_label:)` e a caixa da linha com o título, nunca o id. Nada quebra na API; ver "Padrões que mudaram".
- `v0.1.0` (30/10/2026): primeira versão (base: minhas-vendas e meu-gestor).
- `v0.2.0` (30/10/2026): `SsNavBar`, a barra de abas com o item atual num círculo encaixado num recorte que desliza.
- `v0.3.0` (30/10/2026): `.ss-kanban` na gem (vinha do minhas-vendas e do meu-gestor); `SsNavBar` sem exigir `extendBody`.
- `v0.4.0` (31/10/2026): componentes "únicos" nos dois lados — aurora (`SsAuroraCard`, `SsAuroraBackground`, `.ss-aurora`), indicador (`SsStatCard`, `SsAmount`, `SsDelta`), gráficos (`SsSparkline`, `SsRings`, `SsPillBars`), `SsSegmented`, `SsFilterChip`/`SsChipBar`, `SsSearchField`, `SsListItem`/`SsGroupHeader`, `SsAvatar`/`SsAvatarStack`, `showSsToast`, `SsSeal`, `SsPressable`, `SsCountUp`; helpers Rails (`ss_amount`, `ss_sparkline`, `ss_rings`, `ss_avatar`). `SsNavBar`: a bolinha **pula** em arco (achata, estica, pousa). `SsButton` encolhe ao toque e tem brilho no topo. Botões do menu e dos planos voltam a usar a Manrope.
- `v0.20.4` (11/11/2026): seção "v0.20.4". `RepeaterComponent(header:, hide_labels:, columns:)` + `r.row(columns:, data:, class:, **attrs)` ↔ `SsRepeater(header:, flex:)` + `SsRepeater.cells`; `DataTableComponent(stack: false)` ↔ `SsDataTable(stack: false)`; `.ss-figure` e o card do `.ss-stat` só com `.is-card`/`.ss-stat-body` (o `.ss-stat` solto deixa de ganhar fundo de card). A API não quebra.
- `v1.5.2` (18/11/2026): seção "v1.5.2" (era a v0.25.0 do branch `onda7`). `Ss::NotificationBellComponent` + `Ss::NotificationListComponent` (Stimulus `ss-bell`) ↔ `SsNotificationBell`; slot `bell` no `Ss::AppShellComponent`; `Ss::BadgeComponent` (par do `SsBadge`) e `a.ss-badge` com contorno ao passar; `Ss::DeviceTileComponent`/`SsDeviceTile` bem estreitos empilham. Nada quebra.
- `v0.28.2` (16/11/2026): `SsSearchField` (e a busca do `showSsPicker`) e o número do `SsStepper` sem borda nenhuma: o `InputDecoration.collapsed` herdava o `focusedBorder` do tema e desenhava um contorno dentro da caixa ao focar. Nada quebra.
- `v0.28.1` (16/11/2026): seção "v0.28.1". Etiqueta do `CollapsibleComponent` com o fundo suave opaco do tom (AA independente do fundo atrás). Nada quebra.
- `v0.28.0` (16/11/2026): seção "v0.28.0" (a segunda rodada do meulog). `--muted` claro do web a `#615e78` (AA sobre superfície tingida; conferido no `gerar.py`); `Ss::DayStripComponent` ↔ `SsDayStrip` (novo); `Ss::FilterInputComponent` (novo); `max:` no BarChart/LineChart ↔ `SsBarChart`/`SsLineChart(max:)`; `QrCardComponent(qr_label:)` ↔ `SsQrCard(qrLabel:)`; `CardHeaderComponent(wrap:)`; `ListItemComponent(subtitle_wrap:)` ↔ `SsListItem(subtitleMaxLines:)`; ordenar com rótulo de ação; `SubnavComponent(count_label:)` e sem item atual; `ss_display_font_tag(self_hosted:)` + `ss_page_head`; `ss_select(include_hidden:)`; correções do Masonry, AsideLayout, `.ss-value-row` e `f.ss_fieldset` no SettingsLayout. Novos textos obrigatórios no `SsStrings`.
- `v0.27.0` (16/11/2026), parte do meulog: seção "v0.27.0 (meulog)". `Ss::LineChartComponent` (novo) ↔ `SsLineChart(curved:, markers:, empty:)` + `SsSeries(dashed:, colors:)`; `BarChartComponent(horizontal:, markers:, empty:)` + `tones:`/`colors:` por valor ↔ `SsBarChart(horizontal:, markers:, empty:)`; `SsChartMarker`/`SsChartEmpty`; 16 ícones (Lucide) e apelidos do Phosphor; `ss_font_tags(self_hosted:, display:)` com Manrope e DM Mono servidas pela gem. Nada quebra.
- `v0.26.0` (15/11/2026): seção "v0.26.0" (conversa entre pessoas). `Ss::ChatComponent::Message(from: :them, author:, status:)` ↔ `SsChatBubble(aiMark: false, author:)` e `SsChatStatus.delivered`/`read`; `Ss::ChatDividerComponent` ↔ `SsChatDivider`; `.ss-bubble-media`/`.ss-bubble-file`; o bloco do `ChatComponent` entra dentro do log. Nada quebra.
- `v0.25.2` (15/11/2026): seção "v0.25.2". O `SsHeaderAction` com selo tem o `tooltip` como nome no leitor de tela (antes lia só o número). Nada quebra.
- `v0.25.1` (14/11/2026): seção "v0.25.1". O rótulo das abas da `SsNavBar` volta a usar a Manrope do tema (na v0.25.0 caía na fonte do sistema). Nada quebra.
- `v0.25.0` (14/11/2026): seção "v0.25.0" (rodada 5 da auditoria de UX). `CollapsibleComponent`/`SsCollapsible` com título em até 2 linhas que não alarga a página; `SsNavBar` com o rótulo da aba ativa, anel `SsNavBar.ringColor`/`ringWidth` (3:1 em claro, escuro e OLED), miolo `field` no escuro, ação de tocar no nó de cada aba e o ícone com contagem centrado. Nada quebra na API.
- `v0.24.0` (14/11/2026): seção "v0.24.0" (auditoria de UX de novembro). `DataTableComponent(mobile: :compact)` + `t.column(mobile:)` ↔ `SsDataTable(mobile: SsDataTableMobile.compact)` + `SsDataColumn(mobile: SsDataSlot.*)`; `AppShellComponent` com troca de empresa só com 2+ empresas e nome com reticências (`single_tenant:`); `SettingsLayoutComponent` com `form:`/`save_label:`/`save_always:` e `href:`/`current:` por seção; `.ss-actions` em faixa de largura inteira e folga de foco das barras fixas e do botão flutuante; paleta de comandos fecha com um Esc; chat que não transborda; alvo de toque de 44 px no celular; `ss_form_with(validate:)` + Stimulus `ss-validate`; `AiInsightCardComponent(cancel:, thinking_hint:)` ↔ `SsAiInsightCard` (novo); `SsFab.clearance`/`safeListPadding(fab:)`; `SsButton` como nó próprio de acessibilidade; `SsMenuView`, `SsChoiceField`, `SsDateField` e `SsTimeField` não devolvem o foco ao campo de texto. A API não quebra; ver "Padrões que mudaram".
- `v0.23.6` (14/11/2026): tela de entrada na parede (`Ss::AuthLayoutComponent(variant: :wall)`) no celular: a folha volta a ter a margem de cima (o `margin: auto` virava 0) e o furo do prego não sobe na marca. Só CSS; nada quebra.
- `v0.23.5` (14/11/2026): área segura do celular (`viewport-fit=cover`) na moldura, toasts, barras e gavetas. Nada quebra.
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
