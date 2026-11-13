require "test_helper"

# v0.22 · tela de entrada "Folhinha" (Ss::AuthLayoutComponent ↔ SsAuthLayout.folhinha) e a fonte de exibição.
class V22WebTest < ComponentTest
  CSS = Pathname(ComponentesUi::Engine.root).join("app/assets/tailwind/componentes_ui")
  include ComponentesUi::Helpers

  def folha(**opts, &blk)
    render_inline(Ss::AuthLayoutComponent.new(product: "Meu Gestor", tagline: "A loja em dia.", title: "Entrar",
                                              subtitle: "no Meu Gestor", **opts)) { blk ? blk.call : "<form id='f'></form>".html_safe }
  end

  test "sheet (padrão): marca, data do dia, título, conteúdo do produto e faixa" do
    folha(date: Date.new(2026, 11, 13), note: "bom dia")
    assert_selector "main.ss-auth.is-sheet"
    assert_selector ".ss-auth-brand", text: "MinhaSuite"
    assert_selector ".ss-auth-month", text: "Novembro"
    assert_selector ".ss-auth-year", text: "2026"
    assert_selector ".ss-auth-dateline .ss-auth-day", text: "13"
    assert_selector ".ss-auth-dateline strong", text: "Sexta-feira"
    assert_selector ".ss-auth-dateline", text: "bom dia"
    assert_selector "h1.ss-auth-title", text: "Entrar"
    assert_selector ".ss-auth-sub", text: "no Meu Gestor"
    assert_selector ".ss-auth-body form#f"
    assert_selector ".ss-auth-band strong", text: "Meu Gestor"
    assert_selector ".ss-auth-band span", text: "A loja em dia."
    assert_no_selector ".ss-auth-links"
  end

  test "domingo sai marcado; variante desconhecida vira sheet" do
    folha(date: Date.new(2026, 11, 15), variant: :xyz)
    assert_selector "main.ss-auth.is-sheet .ss-auth-day.is-sunday", text: "15"
  end

  test "wall: folhinha grande escondida do leitor e o formulário no painel com 'Parte da'" do
    folha(variant: :wall, date: Date.new(2026, 1, 1), links: [["Termos", "/termos"]])
    assert_selector "main.ss-auth.is-wall"
    assert_selector ".ss-auth-wall .ss-auth-sheet[aria-hidden='true'] .ss-auth-day", text: "1"
    assert_selector ".ss-auth-wall .ss-auth-weekday", text: "Quinta-feira"
    assert_selector ".ss-auth-panel .ss-auth-part", text: "Parte da MinhaSuite"
    assert_selector ".ss-auth-panel .ss-auth-body form#f"
    assert_selector ".ss-auth-panel nav.ss-auth-links a[href='/termos']", text: "Termos"
  end

  test "pad: faixa em cima, folha de hoje e a de amanhã por baixo (virada de mês)" do
    folha(variant: :pad, date: Date.new(2026, 11, 30))
    assert_selector "main.ss-auth.is-pad .ss-auth-pad > .ss-auth-band:first-child strong", text: "Meu Gestor"
    assert_selector ".ss-auth-pad .ss-auth-sheet .ss-auth-dateline", text: "Segunda-feira, Novembro"
    assert_selector ".ss-auth-under[aria-hidden='true'] .ss-auth-day", text: "1"
    assert_selector ".ss-auth-under", text: "Terça-feira"
  end

  test "marca com link, marca própria, css: e atributos extras" do
    render_inline(Ss::AuthLayoutComponent.new(product: "X", title: "Entrar", brand: "Loja", brand_href: "/", css: "extra", id: "entrada"))
    assert_selector "main#entrada.ss-auth.extra a.ss-auth-brand[href='/']", text: "Loja"
  end

  test "textos em inglês e espanhol" do
    I18n.with_locale(:en) { folha(date: Date.new(2026, 11, 13), variant: :wall) }
    assert_selector ".ss-auth-weekday", text: "Friday"
    assert_selector ".ss-auth-part", text: "Part of MinhaSuite"
    I18n.with_locale(:es) { folha(date: Date.new(2026, 11, 13)) }
    assert_selector ".ss-auth-month", text: "Noviembre"
    assert_selector ".ss-auth-dateline strong", text: "Viernes"
  end

  test "ss_display_font_tag: Big Shoulders 800 e 900, com e sem preconnect" do
    html = ss_display_font_tag
    assert_includes html, "family=Big+Shoulders+Display:wght@800;900"
    assert_includes html, 'rel="preconnect"'
    refute_includes ss_display_font_tag(preconnect: false), "preconnect"
  end

  test "CSS da v0.22: só tokens, três variações e a fonte de exibição" do
    css = CSS.join("v22_web.css").read
    %w[.ss-auth.is-wall .ss-auth-pad .ss-auth-day.is-sunday --ss-font-display --accent-solid --on-accent --danger --page --surface].each { assert_includes css, _1 }
    assert_includes CSS.join("engine.css").read, '@import "./v22_web.css"'
    # Cor solta só no recorte do picote (máscara, não aparece na tela).
    assert_equal ["#000", "#000"], css.scan(/#[0-9a-fA-F]{3,8}\b/)
  end
end
