require "test_helper"

# v1.7 · tela de entrada "Cartaz + papel" (Ss::AuthLayoutComponent(variant: :cartaz, layout: :split) ↔ SsAuthLayout.cartaz)
# e as cores do cartaz no paletas.css (--brand-deep/--brand-from/--brand-to).
class V170WebTest < ComponentTest
  CSS = Pathname(ComponentesUi::Engine.root).join("app/assets/tailwind/componentes_ui")

  def cartaz(**opts, &blk)
    render_inline(Ss::AuthLayoutComponent.new(product: "Minhas Vendas", tagline: "A venda não para.", title: "Entrar",
                                              subtitle: "no Minhas Vendas", variant: :cartaz, **opts)) { blk ? blk.call : "<form id='f'></form>".html_safe }
  end

  test "cartaz: marca, produto, tagline grande, palavra gigante escondida do leitor e o papel com o formulário" do
    cartaz(facts: %w[Web Windows Caixa App], icon: "chart-bar", brand_href: "/", links: [["Termos", "/termos"]])
    assert_selector "main.ss-auth.is-cartaz.is-split"
    assert_selector ".ss-auth-poster a.ss-auth-brand[href='/']", text: "MinhaSuite"
    assert_selector ".ss-auth-poster .ss-auth-product svg.ss-icon[data-icon='chart-bar'][aria-hidden='true']"
    assert_selector ".ss-auth-poster .ss-auth-product span", text: "Minhas Vendas"
    assert_selector ".ss-auth-poster p.ss-auth-slogan", text: "A venda não para."
    assert_selector ".ss-auth-poster .ss-auth-word[aria-hidden='true']", text: "vendas"
    assert_selector ".ss-auth-poster .ss-auth-sweep[aria-hidden='true']"
    assert_selector ".ss-auth-facts span", count: 4
    assert_selector ".ss-auth-facts i[aria-hidden='true']", count: 3
    assert_selector ".ss-auth-paper .ss-auth-part", text: "Parte da MinhaSuite"
    assert_selector ".ss-auth-paper h1.ss-auth-title", text: "Entrar"
    assert_selector ".ss-auth-paper .ss-auth-sub", text: "no Minhas Vendas"
    assert_selector ".ss-auth-paper .ss-auth-body form#f"
    assert_selector ".ss-auth-paper nav.ss-auth-links a[href='/termos']", text: "Termos"
    # Sem folhinha: nada de data, faixa ou movimento da :wall.
    assert_no_selector ".ss-auth-sheet, .ss-auth-band, .ss-auth-day"
    assert_selector "h1", count: 1
  end

  test "word: padrão é a última palavra do produto em minúsculas; dada, vale a dada" do
    cartaz
    assert_selector ".ss-auth-word", text: "vendas"
    render_inline(Ss::AuthLayoutComponent.new(product: "Meu Financeiro", title: "Entrar", variant: :cartaz))
    assert_selector ".ss-auth-word", text: "financeiro"
    cartaz(word: "Venda")
    assert_selector ".ss-auth-word", text: "venda"
  end

  test "sem tagline, ícone e facts, nada sobra vazio; layout desconhecido vira split; motion: não liga o ss-auth" do
    render_inline(Ss::AuthLayoutComponent.new(product: "Central", title: "Entrar", variant: :cartaz, layout: :xyz, motion: true, error: true))
    assert_selector "main.ss-auth.is-cartaz.is-split"
    assert_no_selector ".ss-auth-slogan, .ss-auth-facts, .ss-auth-product svg"
    assert_no_selector "main[data-controller]"
    assert_selector ".ss-auth-product", text: "Central"
  end

  test "as variações antigas seguem iguais" do
    render_inline(Ss::AuthLayoutComponent.new(product: "Meu Gestor", title: "Entrar", variant: :wall, date: Date.new(2026, 11, 19)))
    assert_selector "main.ss-auth.is-wall:not(.is-split) .ss-auth-wall .ss-auth-day", text: "19"
    assert_no_selector ".ss-auth-poster"
  end

  test "textos em inglês e espanhol" do
    I18n.with_locale(:en) { cartaz }
    assert_selector ".ss-auth-part", text: "Part of MinhaSuite"
    I18n.with_locale(:es) { cartaz(links: [["Términos", "#"]]) }
    assert_selector ".ss-auth-part", text: "Parte de MinhaSuite"
    assert_selector "nav.ss-auth-links[aria-label='Enlaces de la página']"
  end

  test "paletas.css: as cores do cartaz em todas as paletas (a padrão no :root)" do
    css = CSS.join("paletas.css").read
    # O cabeçalho fecha antes da 1ª regra (texto solto fora do comentário engolia o :root da padrão).
    assert_operator css.index("*/"), :<, css.index(":root {")
    refute_match(%r{\*/\s*\n\s+v1\.7}, css)
    assert_match(/^:root \{[^}]*--brand-deep: #3b2bb0; --brand-from: #7b5cff; --brand-to: #5a45e8;/, css)
    ComponentesUi::PALETAS.each_key do |slug|
      next if slug == ComponentesUi::PALETA_PADRAO

      assert_match(/:root\[data-palette="#{slug}"\] \{[^}]*--brand-deep: #\h{6};/, css, slug)
    end
  end

  test "ss_brand_style também leva as cores do cartaz" do
    css = ComponentesUi.brand_css("#0284c7", "#14b8a6")
    assert_includes css, "--brand-deep: color-mix(in srgb, #0284c7 65%, #000)"
    assert_includes css, "--brand-to: #14b8a6"
  end

  test "CSS da v1.7: só tokens, escuro e OLED pela página, alto contraste, reduzir movimento e celular" do
    css = CSS.join("v170_cartaz_web.css").read
    assert_includes CSS.join("engine.css").read, '@import "./v170_cartaz_web.css";'
    %w[--brand-deep --brand-from --brand-to --on-accent --page --surface --muted --font-mono --ss-font-display
       prefers-reduced-motion data-ss-contrast max-width:\ 860px :focus-visible].each { assert_includes css, _1 }
    assert_includes css, "color-mix(in srgb, var(--brand-deep) 52%, var(--page))"
    assert_empty css.scan(/#[0-9a-fA-F]{3,8}\b/), "cor solta no CSS do cartaz"
  end

  test "v1.7.1: o iframe do botão do Google (GIS) não ganha caixa branca no escuro" do
    assert_includes CSS.join("v20_web.css").read, %(iframe[src*="accounts.google.com/gsi/"] { color-scheme: light; })
  end
end
