require "test_helper"

# v0.15.2 · o que a migração do minhas-compras e do minhas-viagens pediu: dinheiro com
# espaço não separável (igual ao SsFormats e ao Intl), moeda por código ISO, litro em
# maiúscula (ss_qty), .ss-badge que não estoura e as paletas Azul e Petróleo.
class V152WebTest < ComponentTest
  include ComponentesUi::Helpers

  NB = "\u00A0".freeze
  CSS = Pathname(ComponentesUi::Engine.root).join("app/assets/tailwind/componentes_ui")

  test "ss_money separa o símbolo com espaço não separável nos três idiomas" do
    assert_equal "R$#{NB}1.234,50", ss_money(1234.5)
    assert_equal "-R$#{NB}0,05", ss_money(-0.05)
    assert_equal "R$1,234.50", ss_money(1234.5, locale: :en)
    assert_equal "1.234,50#{NB}R$", ss_money(1234.5, locale: :es)
    refute_includes ss_money(10), " "
  end

  test "ss_money em qualquer moeda ISO, com o mesmo mapa do SsFormats.forCurrency" do
    assert_equal "US$#{NB}12,00", ss_money(12, currency: "USD")
    assert_equal "€#{NB}45,00", ss_money(45, currency: "eur")
    assert_equal "£#{NB}1.500,00", ss_money(1500, currency: "GBP")
    assert_equal "CHF#{NB}10,00", ss_money(10, currency: "CHF")
    assert_equal "¥#{NB}10,00", ss_money(10, currency: "JPY")
  end

  test "ss_qty: sem zeros inúteis e litro em maiúscula" do
    assert_equal "1,5 L", ss_qty(1.5, "l")
    assert_equal "2 L", ss_qty(2, "L")
    assert_equal "0,25 kg", ss_qty(0.25, "kg")
    assert_equal "500 ml", ss_qty(500, "ml")
    assert_equal "3", ss_qty(3)
    assert_equal "0,125", ss_qty(0.125)
    assert_equal "—", ss_qty(nil, "l")
    assert_equal "1.5 L", ss_qty(1.5, "l", locale: :en)
  end

  test "componentes que formatam dinheiro saem com o espaço não separável" do
    render_inline(Ss::CountUpComponent.new(value: 48320.5, format: :money))
    assert_includes page.find(".ss-sr").text(normalize_ws: false), "R$#{NB}48.320,50"
    render_inline(Ss::KpiStripComponent.new(items: [{ label: "Vendido", value: ss_money(1), money: true }]))
    assert_selector ".ss-kpis .ss-kpi-value .ss-count-up[data-controller=ss-count-up]"
  end

  test ".ss-badge não estoura: limita à largura e termina em reticências" do
    css = CSS.join("engine.css").read
    assert_match(/\.ss-badge \{ max-width: 100%; min-width: 0; overflow: hidden; text-overflow: ellipsis; \}/, css)
    assert_includes css, ".ss-badge:not(:has(> *)):not(.ss-badge-dot) { display: inline-block;"
    assert_includes css, ".ss-badge > span { min-width: 0; overflow: hidden; text-overflow: ellipsis; }"
  end

  test "paletas Azul e Petróleo nos dois lados (30) e com nome nos três idiomas" do
    assert_equal 30, ComponentesUi::PALETAS.size
    assert_equal "Azul", ComponentesUi::PALETAS["azul"]
    assert_equal "Petróleo", ComponentesUi::PALETAS["petroleo"]
    paletas = CSS.join("paletas.css").read
    assert_includes paletas, %(:root[data-palette="azul"] {)
    assert_includes paletas, %(:root[data-palette="petroleo"] {)
    assert_match(/:root\[data-palette="azul"\] \{[^}]*--accent: #2563eb;/, paletas)
    assert_equal "Blue", I18n.with_locale(:en) { ss_palette_name("azul") }
    assert_equal "Petrol blue", I18n.with_locale(:en) { ss_palette_name("petroleo") }
    assert_equal "Petróleo", I18n.with_locale(:es) { ss_palette_name("petroleo") }
  end
end
