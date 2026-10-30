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
      ref: v0.3.0
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
- **Webs Rails (quando migrarem):** o secret já está no `minhas-vendas` e no
  `meu-gestor`. Falta, na migração, o mesmo passo no `ci-cd.yml` (montando a chave
  no `docker run` da qualidade) e `RUN --mount=type=ssh bundle install` no
  `Dockerfile.prod` com `docker build --ssh`.

## Rails (Tailwind 4, tailwindcss-rails ≥ 4.2)

```ruby
# Gemfile
gem "componentes_ui", git: "https://github.com/minhasuite/componentes-ui.git", tag: "v0.3.0"
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
