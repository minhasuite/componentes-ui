require "test_helper"

# v1.3 · aparência em todos os produtos: "Cor do app" no seletor e o tema aplicado antes da 1ª pintura.
class V130WebTest < ComponentTest
  include ComponentesUi::Helpers
  test "app_palette: a 1ª ficha é a Cor do app (paleta do produto) e a violeta vira ficha comum" do
    render_inline(Ss::ThemeSwitcherComponent.new(app_palette: "ambar"))
    chips = page.all(".ss-pal-chip")
    primeira = chips.first
    assert_equal "none", primeira["data-ss-theme-palette-param"]
    assert_equal "ambar", primeira["data-swatch"]
    assert_equal "Cor do app", primeira["aria-label"]
    # A do produto não se repete; a violeta continua escolhível pelo nome.
    assert_equal 1, chips.count { |c| c["data-swatch"] == "ambar" }
    assert chips.any? { |c| c["data-ss-theme-palette-param"] == "violeta" }
    assert_selector ".ss-theme-pal-head strong", text: "Cor do app"
  end

  test "sem app_palette, a padrão segue a violeta (como antes)" do
    render_inline(Ss::ThemeSwitcherComponent.new)
    primeira = page.all(".ss-pal-chip").first
    assert_equal "none", primeira["data-ss-theme-palette-param"]
    assert_equal ComponentesUi::PALETA_PADRAO, primeira["data-swatch"]
  end

  test "Cor do app nos três idiomas" do
    %w[en es].each do |loc|
      I18n.with_locale(loc) do
        render_inline(Ss::ThemeSwitcherComponent.new(app_palette: "ambar"))
        refute_equal "Cor do app", page.all(".ss-pal-chip").first["aria-label"], loc
      end
    end
  end

  test "ss_theme_head: guarda a paleta do produto e aplica tema, paleta e OLED antes da pintura" do
    head = ss_theme_head
    assert head.html_safe?
    assert_includes head, "data-ss-theme-head"
    assert_includes head, "paletteDefault"
    %w[ss-theme ss-palette ss-oled].each { |k| assert_includes head, %(localStorage.getItem("#{k}")) }
  end
end
