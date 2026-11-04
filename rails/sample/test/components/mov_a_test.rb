require "test_helper"

# Movimento · lote A: o indicador que desliza (ss-indicator) ligado em cada componente,
# e o CSS/JS de toque e seleção presentes na gem.
class MovATest < ComponentTest
  GEM = ComponentesUi::Engine.root
  IND = "[data-controller~='ss-indicator']"

  test "abas: a lista é o indicador (sublinhado) e o .ss-tabs-ink é o alvo" do
    render_inline(Ss::TabsComponent.new(label: "Seções")) do |t|
      t.with_tab(label: "Um") { "1" }
      t.with_tab(label: "Dois") { "2" }
    end
    assert_selector ".ss-tabs-list#{IND}[data-ss-tabs-target='list'][data-ss-indicator-kind-value='line'][data-ss-indicator-selector-value='.ss-tab']"
    assert_selector ".ss-tabs-list .ss-tabs-ink[data-ss-indicator-target='ink']"
  end

  test "barra de filtros: visões salvas com sublinhado lembrado entre páginas" do
    render_inline Ss::FilterBarComponent.new(params: {}, views: [{ label: "Todos", params: {} }, { label: "Pagos", params: { status: "pago" } }])
    assert_selector "nav.ss-fb-views#{IND}[data-ss-indicator-kind-value='line'][data-ss-indicator-key-value='fb-views']"
  end

  test "troca de tema: pílula no tema e anel na paleta" do
    render_inline Ss::ThemeSwitcherComponent.new
    assert_selector ".ss-seg.ss-theme-seg#{IND}[data-ss-indicator-selector-value='button']"
    assert_selector ".ss-theme-pal-grid#{IND}[data-ss-indicator-kind-value='ring'][data-ss-indicator-selector-value='.ss-pal-chip']"
  end

  test "período: anel nos atalhos" do
    render_inline Ss::DateRangeComponent.new(from_name: "de", to_name: "ate")
    assert_selector ".ss-date-chips#{IND}[data-ss-indicator-kind-value='ring']"
  end

  test "passo a passo: o círculo do passo atual é o indicador" do
    render_inline(Ss::WizardComponent.new) do |w|
      w.with_step(title: "Um") { "a" }
      w.with_step(title: "Dois") { "b" }
    end
    assert_selector "ol.ss-wizard-steps#{IND}[data-ss-indicator-selector-value='li > span'][data-ss-indicator-active-value='[aria-current=step] > span'][data-ss-indicator-motion-value='pop']"
    assert_selector ".ss-wizard-steps li", count: 2
  end

  test "configurações e moldura: pílula no menu (a moldura lembra entre páginas)" do
    render_inline(Ss::SettingsLayoutComponent.new) { |s| s.with_section(id: "conta", title: "Conta") }
    assert_selector "nav.ss-settings-nav#{IND}[data-ss-indicator-selector-value='a']"

    render_inline(Ss::AppShellComponent.new(brand: "X", nav: [{ items: [{ label: "Painel", href: "/", current: true }] }])) { "c" }
    assert_selector "nav.ss-shell-nav#{IND}[data-ss-indicator-key-value='shell'] a[aria-current='page']"
  end

  test "cor: anel que desliza entre as bolinhas" do
    render_inline Ss::SwatchPickerComponent.new(name: "cor", selected: "a", options: [{ value: "a", label: "A", color: "#000" }, { value: "b", label: "B", color: "#fff" }])
    assert_selector ".ss-swatch-picker-row#{IND}[data-ss-indicator-kind-value='ring'][data-ss-indicator-selector-value='.ss-swatch-picker-item']"
  end

  test "controller do indicador: values, menos movimento e lembrança entre páginas" do
    js = GEM.join("app/javascript/componentes_ui/controllers/ss_indicator_controller.js").read
    %w[kind selector active toggle key].each { |v| assert_match(/#{v}:/, js) }
    assert_includes js, "prefers-reduced-motion: reduce"
    assert_includes js, "sessionStorage"
    %w[ss_otp ss_tags].each do |c|
      assert_includes GEM.join("app/javascript/componentes_ui/controllers/#{c}_controller.js").read, "prefers-reduced-motion: reduce"
    end
  end

  test "CSS: mola nos indicadores e no toque, e a regra de menos movimento" do
    css = %w[engine v09_fundacao v09_forms v09_layout].map { GEM.join("app/assets/tailwind/componentes_ui/#{_1}.css").read }.join
    assert_includes css, ".ss-ind {"
    assert_match(/\.ss-btn:active:not\(:disabled\) \{ transform: scale\(\.96\); transition: transform 80ms/, css)
    assert_includes css, "@keyframes ss-press-pop"
    assert_match(/\.ss-switch-row input:checked::before \{ left: 21px; right: 3px;/, css)
    assert_match(/prefers-reduced-motion: reduce\) \{\s*\*, \*::before, \*::after \{ transition: none !important; animation: none !important; \}/, css)
  end

  test "minhoca, estalo e festa da seleção: JS checa menos movimento e só toca na troca" do
    ctl = ->(n) { GEM.join("app/javascript/componentes_ui/controllers/#{n}_controller.js").read }
    motion = ctl.("ss_motion")
    assert_includes motion, "prefers-reduced-motion: reduce"
    assert_includes motion, 'document.addEventListener("change"'
    assert_includes motion, "data-ss-anim"
    ind = ctl.("ss_indicator")
    assert_match(/motion:\s*\{ type: String, default: "slide" \}/, ind)
    assert_includes ind, "data-ss-ind-move"
    assert_includes ind, "data-ss-ind-pop"
    %w[ss_indicator ss_tabs ss_wizard].each { |c| assert_includes ctl.(c), "ss_motion_controller" }
    assert_includes ctl.("ss_wizard"), '"--wz-h"'
  end

  test "CSS: chave, caixinha, rádio e passo a passo só animam com data-ss-anim / data-wz" do
    css = %w[engine v09_fundacao v09_forms v09_layout].map { GEM.join("app/assets/tailwind/componentes_ui/#{_1}.css").read }.join
    %w[ss-chk-on ss-chk-burst ss-chk-wobble ss-radio-dot ss-ring-ripple ss-ring-burst ss-sw-on ss-sw-off ss-sw-halo ss-sw-tick ss-worm-glow].each do |k|
      assert_includes css, "@keyframes #{k} "
    end
    %w[--ss-fill --ss-pour --wz-h --wz-t --wz-s].each { |v| assert_includes css, "@property #{v} " }
    # As animações de festa ficam presas ao atributo da troca (nada toca no carregamento).
    css.scan(/animation: ss-(?:chk|radio|sw|ring-ripple)[^;]*;/).each { |a| refute_match(/infinite/, a) }
    assert_match(/input\[type="checkbox"\]\[data-ss-anim="on"\] \{ animation: ss-chk-on/, css)
    assert_match(/\.ss-switch-row input\[data-ss-anim="on"\]::before \{ animation: ss-sw-on/, css)
    assert_includes css, ".ss-wizard-progress[data-wz]"
  end
end
