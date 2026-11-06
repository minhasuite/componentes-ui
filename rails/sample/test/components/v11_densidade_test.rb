require "test_helper"

# v0.11 · densidade (compacta, padrão, confortável), o par do SsDensity do Flutter: tokens em
# CSS trocados por data-ss-density, config + helpers e o seletor com o controller ss-density.
class V11DensidadeTest < ComponentTest
  GEM = Pathname(ComponentesUi::Engine.root)
  CSS = GEM.join("app/assets/tailwind/componentes_ui")

  include ComponentesUi::Helpers

  teardown { ComponentesUi.config.density = "standard" }

  test "tokens nas três densidades, com o mesmo conjunto de variáveis" do
    css = CSS.join("v11_densidade.css").read
    blocos = {
      "standard" => css[/:root, \[data-ss-density="standard"\] \{(.*?)\n\}/m, 1],
      "compact" => css[/^\[data-ss-density="compact"\] \{(.*?)\n\}/m, 1],
      "comfortable" => css[/^\[data-ss-density="comfortable"\] \{(.*?)\n\}/m, 1]
    }
    blocos.each { |nome, b| assert b, "bloco #{nome}" }
    nomes = blocos.transform_values { |b| b.scan(/(--[\w-]+):/).flatten.sort }
    assert_equal nomes["standard"], nomes["compact"]
    assert_equal nomes["standard"], nomes["comfortable"]
    %w[--ss-control-h --ss-pad-x --ss-gap --ss-row-h --ss-radius --ss-font-scale --ss-card-pad --ss-icon].each do |t|
      assert_includes nomes["standard"], t
    end
    assert_includes css, "@media (pointer: coarse)", "toque no compacto volta a 40 px"
    assert_includes CSS.join("engine.css").read, '@import "./v11_densidade.css";'
  end

  test "padrões de antes nos tokens da densidade padrão" do
    std = CSS.join("v11_densidade.css").read[/:root, \[data-ss-density="standard"\] \{(.*?)\n\}/m, 1]
    { "--ss-control-h" => "2.5rem", "--ss-radius" => "12px", "--ss-radius-card" => "20px", "--ss-card-pad" => "1.25rem",
      "--ss-switch-w" => "46px", "--ss-switch-h" => "28px", "--ss-font-scale" => "1" }.each do |k, v|
      assert_match(/#{Regexp.escape(k)}: #{Regexp.escape(v)};/, std, k)
    end
  end

  test "componentes leem os tokens (nada de altura solta nos controles principais)" do
    engine = CSS.join("engine.css").read
    assert_match(/\.ss-btn \{[^}]*min-height: var\(--ss-control-h\)/m, engine)
    assert_match(/\.ss-input \{[^}]*min-height: var\(--ss-field-h\)/m, engine)
    assert_match(/\.ss-table td \{[^}]*var\(--ss-row-py\)/m, engine)
    assert_includes engine, "width: var(--ss-switch-w); height: var(--ss-switch-h)"
    assert_includes CSS.join("v10_controles.css").read, "var(--ss-switch-w)"
  end

  test "config e helpers" do
    assert_equal "standard", ComponentesUi.config.density
    assert_equal({}, ss_density_attrs)
    assert_equal({ "data-ss-density" => "compact" }, ss_density_attrs("compact"))
    assert_equal "standard", ss_density("enorme")
    ComponentesUi.config.density = "comfortable"
    assert_equal({ "data-ss-density" => "comfortable" }, ss_density_attrs)
    head = ss_density_head
    assert head.html_safe?
    assert_includes head, "localStorage.getItem(\"ss-density\")"
    assert_includes head, "data-ss-density"
  end

  test "seletor: três botões, o atual marcado, textos nos três idiomas" do
    render_inline(Ss::DensityPickerComponent.new)
    assert_selector ".ss-seg.ss-density-picker[role=group][aria-label=Densidade][data-controller='ss-density ss-indicator']"
    assert_selector "button[data-action='ss-density#set']", count: 3
    assert_selector "button[aria-pressed=true][data-ss-density-value-param=standard]", text: "Padrão"
    assert_selector "[data-ss-density-persist-value=true]"

    render_inline(Ss::DensityPickerComponent.new(value: "compact", persist: false, target: "#t", css: "x"))
    assert_selector ".ss-density-picker.x[data-ss-density-persist-value=false][data-ss-density-target-value='#t']"
    assert_selector "button[aria-pressed=true]", text: "Compacta"

    I18n.with_locale(:en) { render_inline(Ss::DensityPickerComponent.new) }
    assert_selector "[aria-label=Density] button", text: "Comfortable"
    I18n.with_locale(:es) { render_inline(Ss::DensityPickerComponent.new) }
    assert_selector "[aria-label=Densidad] button", text: "Estándar"
  end

  test "controller ss-density guarda em ss-density e marca as instâncias juntas" do
    js = GEM.join("app/javascript/componentes_ui/controllers/ss_density_controller.js").read
    assert_includes js, 'localStorage.setItem("ss-density"'
    assert_includes js, "ss-density:change"
    assert_includes js, "data-ss-density"
  end

  test "vitrine da densidade renderiza as três colunas" do
    html = VitrineController.render(template: "vitrine/densidade", layout: false)
    page = Capybara.string(html)
    %w[compact standard comfortable].each { |d| assert page.has_css?("section[data-ss-density=#{d}] .ss-btn") }
    assert page.has_css?(".ss-density-picker", count: 2)
    assert_includes VitrineController::GRUPOS, "Densidade (v0.11)"
  end
end
