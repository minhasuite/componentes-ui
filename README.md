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
      ref: v0.4.0
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
- Fica no app o que depende de API, Riverpod ou plugin: `async_body`, `dialogs`,
  `share_file` e `theme_mode_provider`.

## Acesso (o repo é privado)

Uma chave SSH **só de leitura e só deste repo** (deploy key "CI dos produtos"),
em `minha-infra/vault/ssh/componentes-ui-deploy`. Os produtos continuam usando o
endereço HTTPS acima; quem tem a chave troca por SSH com variáveis do git.

- **CI dos apps:** secret `COMPONENTES_UI_DEPLOY_KEY` em cada repo e o passo
  "Acesso ao componentes-ui" antes do `checkout` de cada job que roda `pub get`
  (já está nos `ci.yml` e `deploy-play.yml` dos 7 apps).
- **Local (container):**

```bash
K=~/projects/minha-infra/vault/ssh/componentes-ui-deploy
docker run --rm -v "$PWD":/app -v flutter_pub:/root/.pub-cache -v "$K":/k:ro -w /app \
  -e GIT_CONFIG_COUNT=2 \
  -e GIT_CONFIG_KEY_0=url.git@github.com:minhasuite/componentes-ui.insteadOf \
  -e GIT_CONFIG_VALUE_0=https://github.com/minhasuite/componentes-ui \
  -e GIT_CONFIG_KEY_1=core.sshCommand \
  -e "GIT_CONFIG_VALUE_1=ssh -i /k -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new" \
  ghcr.io/cirruslabs/flutter:stable bash -lc 'flutter pub get'
```

  Depois do 1º `pub get` o pacote fica no volume `flutter_pub`, e o `--offline` dos
  comandos de cada app volta a funcionar sem a chave.
- **Webs Rails:** secret `COMPONENTES_UI_DEPLOY_KEY` no repo, o mesmo passo no
  `ci-cd.yml` (a qualidade monta o `$RUNNER_TEMP` e repassa os `GIT_CONFIG_*` ao
  `docker run`) e, no `Dockerfile.prod`, `git openssh-client` e
  `RUN --mount=type=secret,id=componentes_ui --mount=type=secret,id=github_known_hosts ... bundle install`
  com `docker build --secret ...`. Modelo pronto: `minhas-vendas` (o secret também
  já está no `meu-gestor`). O devcontainer precisa de `openssh-client`.

## Rails (Tailwind 4, tailwindcss-rails ≥ 4.2)

```ruby
# Gemfile
gem "componentes_ui", git: "https://github.com/minhasuite/componentes-ui.git", tag: "v0.4.0"
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
```

O markup de cada classe nova (`.ss-aurora`, `.ss-stat`, `.ss-bars`, `.ss-seg`,
`.ss-fchip`, `.ss-search`, `.ss-item`, `.ss-toast`, `.ss-seal`) está em
`rails/catalogo/index.html`. Teste dos helpers: `ruby -Ilib test/helpers_test.rb`
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
