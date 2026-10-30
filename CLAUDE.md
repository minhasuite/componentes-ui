# componentes-ui — guia rápido

Design system Lista Clara compartilhado: `flutter/` (pacote) e `rails/` (gem com
CSS para Tailwind 4). Uso no README. Proposta em `../docs/PROPOSTA.md`.

- **Só o que é comum.** Componente de um produto só fica no produto.
- **Nada de cor fixa da marca nos componentes.** No Flutter a marca vem de
  `SsColors.of(context)` (que lê o `SsBrand` do tema); no CSS, de `var(--accent)`
  e `var(--grad)`. Cores semânticas (sucesso, erro, aviso) são da suíte e não mudam.
- **Mudou, cria tag.** Os produtos apontam para `vX.Y.Z`; nunca para `main`.
  Quebrou a API de um componente: sobe o X e anota na seção "Versões" do README.
- **Componente novo ou mudado = entrada no catálogo** (`flutter/test/catalogo.dart`,
  `rails/catalogo/index.html`) na mesma mudança. A skill `componentes` exporta em SVG.
- Não é deploy: push aqui não publica nada. O produto só muda quando sobe a tag dele.
- Flutter roda só em container (comando no README); o `flutter` do PATH é o do Windows.
