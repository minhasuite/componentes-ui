# v1.9 · movimento: correções, cores do sistema, tokens únicos, vibração, skeleton e desfazer

Seis entregas, nos dois lados quando a plataforma deixa.

## 1. Correções

### `SsPagedList(onRefresh:)` não quebra mais o layout (Flutter)

A lista vinha embrulhada num `NotificationListener`, e o `SsPullToRefresh` não a reconhecia como rolável:
punha um `SingleChildScrollView` em volta e a `ListView` ficava sem altura ("Vertical viewport was given
unbounded height"). Agora o `SsPagedList` passa `scrollable: true`. Quem contornou com o `SsPullToRefresh`
por fora (o `minhas-vendas-app`, comentário `ponytail:` em `lib/features/notifications/notifications_screen.dart`)
pode voltar ao `onRefresh:`:

```dart
SsPagedList<AppNotification>(items: _items, hasMore: _hasMore, onLoadMore: _more, onRefresh: _reload, itemBuilder: ...)
```

### Erro do campo sem salto no meio do clique (web)

Antes, ao sair de um campo inválido porque se apertou um botão logo abaixo dele, o `ss-validate` mostrava a
mensagem entre o apertar e o soltar. A mensagem empurrava o conteúdo e o clique se perdia. Agora:

- saindo do campo com o ponteiro apertado (ou num toque que acabou de terminar), a marca **espera o clique
  terminar** (`pointerup` e depois `setTimeout 0`). Pelo teclado (Tab), a marca continua na hora;
- o form ganha `data-ss-validate-ready`, e o CSS só mostra a mensagem quando o controller marca
  (`.is-invalid`), não no `:user-invalid` do navegador (que também aparecia no blur). A ajuda fica até lá;
- o envio continua marcando todos os campos e focando o primeiro errado.

Nada muda na marcação: vale para todo `ss_form_with` (o `validate: :ss` é o padrão).

## 2. Cores do sistema (Material You), só no app

`SsAppearanceController(systemColor:)` recebe a cor do sistema, que o app lê. O pacote **não** depende do
`dynamic_color`. Com a cor, a seção de cores do `SsAppearancePanel` ganha a 2ª ficha, "Cores do sistema"
(pt/en/es: `SsStrings.appearanceSystemColors`). A marca sai de `SsBrand.fromColors`, com o accent escurecido
até o branco passar 4,5:1. O JSON guarda `"paleta": "sistema"` (`SsAppearance.sistema`).

```dart
// pubspec do app: dynamic_color
final paleta = await DynamicColorPlugin.getCorePalette(); // null fora do Android 12+
final aparencia = SsAppearanceController(
  brand: SsBrand.ambar,
  systemColor: paleta == null ? null : Color(paleta.primary.get(40)),
  read: () => storage.read(key: 'aparencia'),
  write: (v) => storage.write(key: 'aparencia', value: v),
)..load();
// O papel de parede mudou (ex. no didChangeAppLifecycleState): aparencia.systemColor = nova;
```

- Sem a cor (iOS, Android antigo), a opção não aparece, e quem tinha escolhido "sistema" fica com a cor do app.
- `controller.systemColor = cor` avisa e refaz o tema (o cache do tema leva a cor na chave).
- `controller.systemBrand` devolve a marca montada (ou `null`).

No web não há o que fazer, porque o navegador não expõe a cor do sistema. A paleta continua a do `Ss::ThemeSwitcherComponent`.

## 3. Tokens de movimento únicos

| Flutter (`SsMotion`) | CSS | valor | para quê |
|---|---|---|---|
| `short` (= `fast`) | `--ss-dur-short` (= `--ss-dur-fast`) | 180 ms | cor, opacidade, ícone que troca |
| `medium` (= `base`) | `--ss-dur-medium` (= `--ss-dur-base`) | 280 ms | tamanho, conteúdo que entra, painel |
| `long` (= `slow`) | `--ss-dur-long` | 400 ms | cascata, tela, o que anda longe |
| `standard` | `--ss-ease-standard` | `cubic-bezier(.2, 0, 0, 1)` | de um estado a outro, no lugar |
| `enter` | `--ss-ease-enter` | easeOutCubic `cubic-bezier(.33, 1, .68, 1)` | o que chega |
| `exit` | `--ss-ease-exit` | easeInCubic `cubic-bezier(.32, 0, .67, 0)` | o que sai |
| `spring` | `--ss-ease-spring` (= `--ss-spring`) | easeOutBack `cubic-bezier(.34, 1.56, .64, 1)` | passa do ponto e volta |
| `bounce` | `--ss-bounce` | mola (passa ~12%) | indicador, folha, toque que volta |
| `distSmall` / `distMedium` / `distLarge` | `--ss-dist-small/medium/large` | 4 / 12 / 24 px | empurrão, subida de quem entra, deslize |

Os nomes que têm ritmo próprio continuam: `indicator` 460 ms (`--ss-dur-indicator`), `release` 420 ms, `worm` 520 ms,
`pop`, `stagger` 40 ms.

Os componentes trocaram as durações soltas pelos tokens. A mudança visível é só a uniformização:

- **Flutter:** `Duration(milliseconds: …)` de animação: 150–220 → `short`, 240–300 → `medium`, 380–400 → `long`
  (34 lugares). Ficaram de fora os tempos que não são movimento (debounce, espera do tooltip, atraso) e os de ritmo
  próprio (confete, explosão de 450 ms, contagens);
- **CSS:** nas declarações `transition`/`transition-duration`: `.15s`–`.22s` → `var(--ss-dur-short)`, `.24s`–`.3s` →
  `var(--ss-dur-medium)`, `.38s`/`.4s` → `var(--ss-dur-long)` (181 lugares, em 24 arquivos). As `animation` de
  ritmo próprio (brilho do esqueleto, spinner, mola) ficaram.

Com menos movimento, tudo continua desligado (`MediaQuery.disableAnimations` / `prefers-reduced-motion`).

## 4. Mapa de vibração

| nome | Flutter (`SsHaptics`) | web (`navigator.vibrate`) | onde a suíte usa |
|---|---|---|---|
| `selection` | `selectionClick` | 8 ms | chave (`SsSwitch`, `SsSwitchRow`, `.ss-switch-row`), segmentado (`SsSegmented`, `.ss-seg`), rádio |
| `limit` | `lightImpact` | 14 ms | slider no mínimo ou no máximo (`SsSlider`, `ss-range`) |
| `success` | 2× `lightImpact` | 10, 60, 10 | confirmação (`showSsConfirm`, `ss-confirm-dialog`) |
| `warning` | `mediumImpact` | 24 ms | confirmação perigosa ou de aviso, remoção com desfazer |
| `error` | `heavyImpact` | 30, 50, 30 | aviso de erro (`showSsToast(tone: AppColors.danger)`, `.ss-toast.is-bad`) |

- Flutter: `SsHaptics.enabled = false` desliga tudo (a preferência "Vibração" do app; nos testes também).
  `tick`, `light` e `threshold` continuam (`tick` é o `selection`).
- Web: `import { haptic } from "componentes_ui/controllers/ss_haptics_controller"`. Só vibra com ponteiro de toque
  (`pointer: coarse`) e onde `navigator.vibrate` existe, ou seja, fica desligado no desktop e não faz nada no iOS.
  `<html data-ss-haptics="on">` força e `"off"` desliga. Por data-action:
  `data-controller="ss-haptics" data-action="click->ss-haptics#play" data-ss-haptics-kind-param="success"`.

## 5. Skeleton que vira conteúdo

- **Flutter:** o `SsAsyncBody` passa a usar o `SsSkeletonSwitch`. Do skeleton (ou do erro) para o dado, o conteúdo
  faz um crossfade e sobe 12 px (`SsMotion.medium`, `enter`). Revalidar com o dado na tela não anima. O
  `SsAsyncSliver` faz a lista entrar esmaecendo (`SsSliverEntrance`) quando o dado chega depois do skeleton. O
  sliver não sobe, para não mexer na rolagem. Dado que já estava não anima. As duas peças são públicas:
  `SsSkeletonSwitch(stateKey:, child:)` e `SsSliverEntrance(sliver:, play:)`.
- **Web:** o `Ss::SkeletonComponent(frame:)` liga `data-controller="ss-skeleton"` no `turbo-frame`. Quando o frame
  chega, uma cópia do esqueleto (`.ss-skel-ghost`) fica por cima esmaecendo e o conteúdo entra com `.ss-skel-in`.
  Num Turbo Stream que substitui o `.ss-skel`, ponha `.ss-skel-in` no conteúdo novo.
- Com menos movimento, troca direto. O `SsInlineAsync` (seção dentro de lista) continua trocando seco.

## 6. Ação otimista com desfazer animado

**Flutter, `SsUndoableRemoval`:**

```dart
SsUndoableRemoval(
  key: ValueKey(p.id),
  message: 'Pedido 1042 excluído',
  onCommit: () => api.excluir(p),                    // a exclusão de verdade, depois do desfazer
  onRemoved: () => setState(() => pedidos.remove(p)), // tirou de vez
  builder: (context, remove) => SsListItem(title: p.nome, trailing: IconButton(onPressed: remove, icon: ...)),
)
```

- `remove()` faz o item sair encolhendo (altura, opacidade e escala .94; `medium` com `exit`) e mostra o
  `showSsUndo` (o `SsToast` com Desfazer e a contagem). Enquanto espera, o item fica fora da semântica e do toque.
- Desfez: o item volta crescendo no mesmo lugar (`enter`) e `onUndo` é chamado.
- Não desfez: `onCommit` e depois `onRemoved`. Se `onCommit` falhar, o item volta e aparece um aviso de erro
  (`errorMessage`, ou `SsStrings.genericError`) com a vibração de erro.
- Outros parâmetros: `undoLabel`, `icon`, `duration` (5 s), `bottom`. Também dá para chamar por
  `GlobalKey<SsUndoableRemovalState>().currentState!.remove()`.

**Web, `Ss::UndoableRemovalComponent` + `ss-undoable`:**

```erb
<%= render Ss::UndoableRemovalComponent.new(message: "Pedido 1042 excluído", tag: :li, css: "ss-card ss-card-pad") do %>
  Pedido 1042
  <%= button_to "Excluir", pedido_path(p), method: :delete, class: "ss-btn ss-btn-ghost",
                form: { data: Ss::UndoableRemovalComponent::FORM_DATA } %>
<% end %>
```

- O envio do form para. O item encolhe pelo Web Animations API (`--ss-dur-medium`, `--ss-ease-exit`) e fica `inert`.
  Entra na pilha `#ss-toasts` (criada embaixo, no centro, se a página não tiver) um `.ss-toast` com o anel de
  contagem e Desfazer.
- Desfazer: a animação volta (`--ss-ease-enter`) e o foco volta ao botão. O aviso some sem desfazer: o
  `ss-toast` avisa (evento novo `ss-toast:closed`) e o form vai de verdade (`requestSubmit`). Se der certo, o item
  sai do DOM. Se falhar (`turbo:submit-end` sem sucesso), o item volta e entra um `.ss-toast.is-bad`.
- Se a pessoa sair da página com a remoção pendente, ela é enviada na hora (`fetch` com `keepalive`).
- Opções: `tag:` (`:div`, `:li`, `:tr`), `duration:` (5), `undo_label:`, `error:`. Textos em
  `componentes_ui.undoable_removal.{undo,close,error}` (pt-BR/en/es).
- O servidor não precisa de rota de restaurar, porque nada é apagado antes do fim do aviso.

## Catálogo, vitrine e testes

- Catálogo Flutter: `flutter/test/catalogo_v19_movimento.dart` (`comV19Movimento`). Ele traz as peças novas
  `ss-skeleton-switch` e `ss-undoable-removal`, a entrada `ss-motion` com os tokens e a vibração,
  `ss-appearance-panel` com o estado "cores do sistema" e anotações em `ss-paged-list`, `ss-async-body` e
  `ss-async-sliver`.
- Catálogo web: `rails/catalogo/index.html`, com as seções `ss-motion-tokens`, `ss-undoable`, `ss-skel-in` e `ss-haptics`.
- Vitrine Rails: página "Movimento e vibração (v1.9)" (grupo Acabamento, `movimento_v190`), com os tokens, o
  campo com o botão logo abaixo, o frame com skeleton e a lista com desfazer.
- Testes: `flutter/test/v19_movimento_test.dart` e `rails/sample/test/components/v19_movimento_web_test.rb`.
