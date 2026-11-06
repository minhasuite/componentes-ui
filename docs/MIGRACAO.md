# Migrar um produto para o componentes-ui

Roteiro tirado da migração do minha-automacao (web Rails + app Flutter, v0.3 → v0.10.3,
04–05/11/2026; plano em `../../docs/MIGRACAO-minha-automacao.md`). Vale para qualquer
produto da suíte. Regra de fundo (skill `lista-clara`): **peça genérica nasce aqui, nunca no
produto**; o produto só monta peças e guarda o que é do domínio dele.

## 1. Levantar

Rode no repo do produto e guarde os números (são a régua do "%" no fim).

**Web (Rails):**

```bash
# CSS do produto (meta: só domínio; a cópia da Lista Clara some)
wc -l app/assets/tailwind/*.css app/assets/stylesheets/*.css 2>/dev/null | tail -1
grep -c '^\s*\.ss-' app/assets/tailwind/application.css          # .ss-* copiados (meta: 0)
# Utilitários Tailwind crus nas views (candidatos a .ss-* ou Ss::*Component)
grep -rhoE 'class="[^"]*\b(p|px|py|m|mt|mb|gap|text|bg|rounded|shadow|border|w|h)-[a-z0-9./\[\]-]+' app/views | wc -l
grep -rlE 'rounded-(xl|2xl)|shadow-(md|lg)|bg-white|text-gray-' app/views       # cara de "card/botão à mão"
# Stimulus do produto (meta: só domínio)
ls app/javascript/controllers/*_controller.js | wc -l
grep -l 'clipboard\|theme\|privacy\|poll\|reload\|filter\|autosubmit\|sortable' app/javascript/controllers/*.js
```

**App (Flutter):**

```bash
grep -rhoE '\bSs[A-Z][A-Za-z]*\(|showSs[A-Za-z]*\(' lib | wc -l                    # peças do pacote
grep -rhoE '\b(AppBar|ElevatedButton|FilledButton|TextButton|OutlinedButton|IconButton|FloatingActionButton|TextFormField|TextField|ListTile|SwitchListTile|Switch|Checkbox|Slider|Chip|FilterChip|ChoiceChip|DropdownButton(FormField)?|SegmentedButton|AlertDialog|SnackBar|CircularProgressIndicator|PopupMenuButton|TabBar|Card|Divider)\(' lib | wc -l   # Material cru
grep -rnE 'Color\(0x|Colors\.[a-z]' lib | grep -v '_test' | wc -l                  # cor solta
ls lib/core/ui lib/core/theme 2>/dev/null                                          # cópias locais (meta: só o ui.dart que reexporta)
```

Classifique cada achado em três colunas: **já existe** (troca direta; tabela "Peças da v0.5" e
seções de versão do README), **falta e é genérico** (vai para a gem/pacote), **domínio** (fica).

## 2. Lacunas: gem e pacote primeiro, com tag

1. Peça que falta e serviria a outro produto entra aqui, **nos dois lados com o mesmo nome**
   (`SsX` ↔ `Ss::XComponent`/`.ss-x`), com catálogo (`flutter/test/catalogo*.dart`,
   `rails/catalogo/index.html`), vitrine, teste e textos pt/en/es (`SsStrings`, `config/locales`).
2. Parâmetro novo é opcional; quebrar API sobe o X (README, "Versões").
3. Tag `vX.Y.Z` (nunca `main`). Só depois mexa no produto.

O minha-automacao foi em três rodadas (v0.10.1 → v0.10.2 → v0.10.3): cada subida no produto
achou lacunas que viraram a tag seguinte. Planeje assim: migre, anote o que faltou, feche na gem.

## 3. Produto: web e app (cada um é deploy)

- **Bump conservador.** `Gemfile` com `tag: "vX.Y.Z"` e `bundle update componentes_ui
  --conservative` (não arrasta o resto do lock); `pubspec.yaml` com `ref: vX.Y.Z` e
  `flutter pub upgrade componentes_ui`. Confira o lock: só a gem/pacote mudou.
- **Web:** `@import "../builds/tailwind/componentes_ui";` no `application.css`, apaga a cópia dos
  `.ss-*`, `eagerLoadControllersFrom("componentes_ui/controllers", application)`, troca os
  controllers genéricos pelos `ss-*`, renomeia colisões com prefixo do produto (`ma-`, `dw-`…),
  ícone do produto entra pelo `icon:` dos componentes (SVG pronto).
- **App:** `core/ui/ui.dart` só reexporta o pacote; tema por `AppTheme.build(b, brand:, oled:,
  density:)` num `static final`; `SsStrings.delegate` nos `localizationsDelegates`; apaga
  `lib/core/ui/ss_*`, `lib/core/theme` e `assets/google_fonts`.
- Escreva no `CLAUDE.md` do produto a seção "Componentes": o que é Ss primeiro, o que fica
  fora de propósito e as armadilhas abaixo.

## 4. O que fica no domínio

Fica no produto o que **não serviria a outro produto** ou depende da API/plugin dele, sempre
montado com peças e tokens da suíte (sem hex, sem `.ss-*` próprio):

- desenho do domínio (planta baixa, mapa e marcadores, editor do painel, telas dirigidas pelo
  servidor, cartão de crédito, kanban de um fluxo);
- plugins e mídia nativa (`RTCVideoView`, `Image.memory` da câmera, `FlutterMap`, câmera,
  compartilhar, scanner): o pacote devolve escolha/bytes e o app chama o plugin;
- regras do produto (tradução de erro da API, `CancelToken`, `runCommand`, risco de comando);
- `Scaffold`/`MaterialApp`, `Tooltip` informativo e gestos de arrastar do domínio.

Se um segundo produto precisar, sobe para cá.

## 5. Armadilhas já pisadas

- **`render(X.new) { }` vs `render X.new { }`:** sem os parênteses do `render`, o `{ }` vai para o
  `.new` e o conteúdo some. Use `render(Ss::XComponent.new(...)) { ... }` ou `do … end`.
- **Chave do localStorage:** a gem usa `ss-theme`, `ss-palette`, `ss-oled`, `ss-density`. Ao
  trocar o controller do produto, migre a chave antiga uma vez no `<head>` (o minha-automacao lê
  `theme` e grava `ss-theme`); "esconder valores" pode manter a chave dele com
  `data-ss-privacy-key-value`.
- **App híbrido (`AppScreen`, web lida pelo app):** mudar markup quebra o parser do app. Rode os
  testes de request do appweb e mantenha os blocos que o app lê (`ss-poll`/`ss-reload` viram
  `poll`/`reload`).
- **`.ss-base` / `.ss-inputs` no `<body>`:** são opt-in (tiram o marcador do `<summary>`, cortam
  animação com menos movimento, desenham caixas soltas). Sem eles, `<details>` e checkbox crus
  ficam com o visual do navegador.
- **Turbo morph e `<head>`:** estado da moldura vai no `<html>` antes da 1ª pintura:
  `ss_app_shell_head` (menu recolhido) e `ss_density_head` (densidade) no `<head>`, nunca em
  `connect()` de controller (pisca e se perde no morph).
- **Testes Flutter:** registre `SsStrings.delegate` no `MaterialApp` dos testes (senão os rótulos
  saem do idioma do `Localizations`), e use `AppTheme.light/dark` (as fontes vêm do pacote).
- **Capturas:** trocar de tela com `pumpWidget` reaproveita o `Navigator`; monte um `SizedBox`
  antes. `SsSection` desenha em CAIXA ALTA (procure assim). Fonte do sistema em golden = falta
  `textTheme` do tema (foi o bug do `SsTopBar` na v0.10.3).
- **`AppTheme.number`**, nunca `fontFamily: 'DM Mono'` (com as fontes empacotadas não existe).
- **Utilitário Tailwind dinâmico** (largura, cor calculada) vai inline ou no `safelist`.

## 6. Conferir antes de dar por pronto

- [ ] CI do produto verde (lint, testes, build da imagem/APK); `bin/rails tailwindcss:build` sem erro.
- [ ] Web com Playwright (skill `verify-ui`): 390 e 1440 px, claro e escuro, sem rolagem
      horizontal (`scrollWidth > innerWidth`), contraste AA (axe) nas telas mexidas.
- [ ] App: suítes de captura (claro/escuro, pt/en/es) olhadas uma a uma; `flutter build apk
      --release` (minify) e, se mexeu em plugin ou inicialização, emulador (skill `emulador-android`).
- [ ] Densidade: as telas principais em `compact` e `comfortable` (web: `data-ss-density` no
      `<html>`; app: `AppTheme.build(b, density:)`), sem corte nem estouro.
- [ ] `CLAUDE.md` do produto com a seção "Componentes" e a tag em uso; PROPOSTA atualizada.

## 7. Medir o "%"

Repita os comandos do passo 1 e compare:

| Métrica | Como | Meta |
|---|---|---|
| App: Ss vs Material | `Ss…(` / (`Ss…(` + Material cru) | ≥ 95%; o resto listado como "fora de propósito" |
| App: cor solta | `Color(0x`/`Colors.` fora de teste | só as que vêm do servidor/domínio |
| Web: CSS do produto | linhas de `app/assets/**/*.css` sem o `@import` da gem | só domínio, cada arquivo diz no topo o que guarda |
| Web: `.ss-*` próprios | `grep -c '^\s*\.ss-'` no CSS do produto | 0 |
| Web: Stimulus do produto | `ls app/javascript/controllers/*_controller.js` | só domínio (o minha-automacao ficou com 16: câmera/voz, mapa, planta, quiosque, editor, primeira configuração, login) |

Registre os números de antes e depois na mensagem do commit de migração e no `CLAUDE.md`.
