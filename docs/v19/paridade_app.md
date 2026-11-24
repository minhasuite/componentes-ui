# v1.9 · paridade_app — os pares no app das peças que só existiam no web

Treze peças tinham só o lado Rails. Agora cada uma tem o par no Flutter com o mesmo nome
(`Ss::XComponent` ↔ `SsX`), os mesmos parâmetros e os mesmos estados. O código fica em
`flutter/lib/src/v19/paridade_app/`, exportado no fim de `componentes_ui.dart`. No web, só o
wizard mudou (ganhou o que o app tem).

| Web | App | Observação |
|---|---|---|
| `Ss::GanttComponent` | `SsGantt` + `SsGanttTask` | nomes fixos à esquerda, dias rolam de lado |
| `Ss::TourComponent` | `SsTour` + `SsTourStep` | alvo por `GlobalKey`; "mostrar uma vez" com `SsSeenStore` |
| `Ss::WizardComponent` | `SsWizard` + `SsWizardStep` | reaproveita `SsStepTopBar` e `SsStepHeading` |
| `Ss::DateRangeComponent` | `SsDateRangeField`, `showSsDateRangePicker`, `SsDateRangeShortcut` | |
| `Ss::OtpInputComponent` | `SsOtpField` | colar e `AutofillHints.oneTimeCode` |
| `Ss::TagInputComponent` | `SsTagField` | chips são o `SsInputChip` (o `.ss-tag`) |
| `Ss::AuditTrailComponent` | `SsAuditTrail` + `SsAuditEntry`/`SsAuditChange` | mesma conta de diferença (`diff`) |
| `Ss::ReviewCardComponent` | `SsReviewCard` | estrelas são o `SsRating` |
| `Ss::PersonCardComponent` | `SsPersonCard` | `SsAvatar`, `SsAvatarStack`, `SsPrivate` |
| `Ss::BentoGridComponent` | `SsBentoGrid` + `SsBentoBlock`/`SsBentoTone` | 4/2/1 colunas como o CSS |
| `Ss::WhatsNewComponent` | `SsWhatsNew` + `SsWhatsNewItem`, `SsWhatsNewList` | folha no lugar do popover |
| `Ss::SkeletonComponent` | `SsSkeleton` + `SsSkeletonShape` | `SkeletonList`/`SkeletonBox` continuam |
| `Ss::SplitViewComponent` | `SsSplitView` + `SsAdaptiveScaffold` | quebra em 840 (`ssWideBreakpoint`) |

O que já existia e foi reaproveitado, sem duplicar: `SsStepTopBar` (topo "2 / 4" com a barra
minhoca) e `SsStepHeading` (título numerado) no wizard; `SsInputChip` nas etiquetas; `SsRating`
no depoimento; `SsAvatar`/`SsAvatarStack` na pessoa e no histórico; `SsFilterChip` nos atalhos do
período; `SsNavScaffold` + `SsNavBar` e `SsSideRail` na casca adaptável; `showSsSheet`/`SsSheet`
nas novidades. O `SsTip` é outra coisa (dica solta dispensável) e ficou como está. `SkeletonList`
e `SkeletonBox` cobrem lista de cartões e bloco fixo; o `SsSkeleton` cobre as formas do web
(linha, tabela, cartão, lista) e serve de `loading:` do `SsAsyncBody`.

## "Mostrar uma vez": `SsSeenStore`

Tour e novidades lembram o que a pessoa já viu num armazenamento que **o app injeta** (o
componente não depende de `shared_preferences`):

```dart
class PrefsSeenStore extends SsSeenStore {
  PrefsSeenStore(this.prefs);
  final SharedPreferences prefs;
  @override
  Future<String?> read(String key) async => prefs.getString(key);
  @override
  Future<void> write(String key, String value) => prefs.setString(key, value);
}
```

As chaves e os valores são os do `localStorage` do web: `ss-tour:<id>` = `"1"` e
`ss-whats-new:<id>` = lista de ids em JSON. `SsMemorySeenStore` serve para teste e vitrine.

## API do app

```dart
SsGantt(start: hoje.subtract(const Duration(days: 3)), days: 14, tasks: [
  SsGanttTask(label: 'Levantamento', from: d1, to: d2, progress: .6, tone: SsTone.accent),
]);

SsTour(id: 'painel-v2', store: prefs, autostart: true, steps: [
  SsTourStep(target: kpisKey, title: 'Seus números', text: 'Aqui ficam os indicadores do mês.'),
], child: tela);
// pelo botão "Ver tour": tourKey.currentState!.start()  ou  SsTour.show(context, steps: …)

SsWizard(
  steps: [SsWizardStep(title: 'Dados', builder: (_) => SsTextField(label: 'Nome', validator: …)),
          SsWizardStep(title: 'Plano', validate: () => plano != null, builder: …)],
  summary: (_) => ResumoPedido(…),             // passo final "Revisão"
  onSaveForLater: (passo) => salvarRascunho(passo), // "Salvar e continuar depois"
  initialStep: rascunho?.passo ?? 0,
  onSubmit: () async => api.criar(…),
  onCancel: () => context.pop(),
);

SsDateRangeField(value: periodo, onChanged: (p) => setState(() => periodo = p));
final p = await showSsDateRangePicker(context, initialRange: periodo);

SsOtpField(length: 6, onCompleted: (code) => confirmar(code), errorText: erro);
SsTagField(label: 'Etiquetas', values: tags, onChanged: (v) => setState(() => tags = v));

SsAuditTrail(entries: [SsAuditEntry(who: 'Ana Souza', action: 'alterou o pedido 1042', at: quando,
  changes: [SsAuditChange('Valor', from: 'R\$ 1.250,00', to: 'R\$ 1.320,00')])]);

SsReviewCard(name: 'Carla Mendes', role: 'Padaria Central', rating: 4.5, text: '…', date: 'out/2026');
SsPersonCard(name: 'Ana Souza', role: 'Vendedora', status: SsTone.success,
  metrics: [('Vendido', 'R\$ 48 mil')], team: ['Bruno', 'Caio'], actions: [SsButton(…)], onTap: abrir);

SsBentoGrid(blocks: [SsBentoBlock(cols: 2, rows: 2, tone: SsBentoTone.grad, child: …), SsBentoBlock(child: …)]);

SsWhatsNew(id: 'financeiro', store: prefs, items: novidades, autoShow: true); // no actions do topo

SsSkeleton(shape: SsSkeletonShape.table, rows: 5, cols: 4);

SsAdaptiveScaffold(items: abas, currentIndex: i, onTap: (v) => setState(() => i = v),
  body: SsSplitView(list: lista, detail: atual == null ? null : Detalhe(atual!, key: ValueKey(atual!.id)),
                    onBack: () => setState(() => atual = null)));
```

## Comportamento (igual nos dois lados)

- **Gantt:** barra de `from` a `to` (inclusive) recortada na janela; hoje com coluna tingida e o
  número no círculo; o progresso pinta a barra até `progress`. Leitor de tela: "Projeto, de 02/11 a
  05/11, 60% feito". A barra cresce da esquerda (para com "reduzir movimento").
- **Tour:** véu com recorte e anel da marca no alvo; o recorte vai de um alvo ao outro com mola e o
  alvo rola para a vista; "1 de 3", Pular (não no último), Voltar (não no primeiro), Próximo /
  Concluir. Passo sem alvo montado é pulado. Voltar do sistema = Pular (Esc no web). Concluir ou
  pular grava o "já vi". `useRootNavigator: false` cobre só o navegador mais próximo.
- **Wizard:** cada passo tem `Form` próprio: os `validator` seguram o Avançar (o `checkValidity` do
  web) e `validate:` é a conferência extra. Os passos ficam montados (voltar não perde nada). No
  último o botão vira `submitLabel` e fica ocupado até `onSubmit` terminar.
- **Período:** atalhos Hoje, 7 dias (conta hoje), Este mês (mês inteiro), Mês passado; o que bate
  com o período fica marcado. Chaves do web: `today`, `7d`, `month`, `last_month`.
- **Código:** por baixo é um campo só (teclado numérico, colar, autofill do SMS); só dígitos, corta
  em `length`; completo chama `onCompleted` (o `ss-otp:complete`).
- **Etiquetas:** confirmar no teclado ou vírgula vira chip; colar "a, b" vira duas; repetida (sem
  diferenciar maiúsculas) não entra; ✕ tira; apagar no campo vazio tira a última.
- **Histórico:** avatar + fio, "quem ação quando", e cada campo de → para com só o trecho que mudou
  riscado/verde; vazio em itálico. Leitor de tela: "Valor: R$ 1.250,00 para R$ 1.320,00".
- **Novidades:** ponto no sino com não vistas ("Novidades, 2 novas"); abrir marca tudo como visto e
  a lista mostra "NOVO" nos que eram novos. `autoShow` abre a folha sozinha uma vez.
- **Lista + detalhe:** lado a lado a partir de 840 (o web quebra em 1024, pelo CSS); no celular o
  detalhe vira a tela com Voltar, e o voltar do sistema chama `onBack`. `SsAdaptiveScaffold` troca
  a `SsNavBar` pelo `SsSideRail` a partir de 840 (voltar do sistema leva à 1ª aba nos dois).

## O que mudou no web

`Ss::WizardComponent` (modo cliente) ganhou os dois pares do `SsWizard`:

```erb
<%= render Ss::WizardComponent.new(draft_key: "novo-cliente", save_later_label: true) do |w| %>
  <% w.with_step(title: "Dados") { … } %>
  <% w.with_summary { render "resumo" } %>   <%# passo final "Revisão" %>
<% end %>
```

- `with_summary`: vira o último passo, "Revisão" (`componentes_ui.wizard.review`), com ponto e
  progresso contando ele.
- `save_later_label:` (`true` usa `componentes_ui.wizard.save_later`): um `submit` com
  `formnovalidate`, `name="save_later"` (troque com `save_later_name:`) e `value="1"`; o controller
  do app vê o parâmetro, grava o rascunho e redireciona. Fica entre Voltar e Avançar; no celular
  (≤ 520) desce para uma linha própria (`v19_paridade_app.css`).
- No modo servidor (`current:`) os dois são ignorados (o form é do app).

## Textos

`SsStrings` (pt/en/es, com padrão em pt no construtor): `tourCount`, `tourNext`, `tourDone`,
`wizardNext`, `wizardSubmit`, `wizardReview`, `wizardSaveLater`, `wizardStep`, `dateRangeLabel`,
`dateRangeFrom`, `dateRangeTo`, `dateRangeShortcuts`, `dateRange7d`, `dateRangeMonth`,
`dateRangeLastMonth`, `otpLabel`, `otpDigit`, `tagFieldHint`, `tagFieldChosen`, `auditTrailLabel`,
`auditTrailEmpty`, `auditTrailTo`, `personTeam`, `whatsNewNew`, `ganttLabel`, `ganttBar`,
`splitList`, `splitEmpty` (os `{n}`, `{total}`, `{label}`… o componente troca com `ssFill`).
Reaproveitados: `skip`, `back`, `today`, `helpNews`, `helpNewsUnseen`, `ratingOf`, `removeItem`,
`loadingEllipsis`, `confirm`, `cancel`. Rails: `componentes_ui.wizard.review` e
`componentes_ui.wizard.save_later` (pt-BR/en/es).

## Testes, catálogo e vitrine

- Flutter: `test/v19_paridade_app_test.dart` (29 testes) e `test/catalogo_v19_paridade_app.dart`
  (`comV19ParidadeApp`, 13 entradas, encadeado no `catalogo`; aparece na vitrine pelo catálogo).
- Rails: `sample/test/components/v19_paridade_app_web_test.rb` (inclui a conferência de que cada
  peça só-web tem o par `SsX` no Flutter), estado novo do `ss-wizard` em `rails/catalogo/index.html`
  e a demo da vitrine `formularios_fluxo` com `with_summary` e `save_later_label: true`.

## Fora desta entrega

- Lista + detalhe quebra em 840 no app e 1024 no web (cada lado segue a convenção da plataforma).
- Novidades no app é folha (o popover do web não cabe no celular); o `autoShow` é só do app.
- O "apagar no campo vazio tira a última etiqueta" só funciona com teclado físico (teclado virtual
  não manda a tecla quando o campo está vazio).
