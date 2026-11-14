require "test_helper"

# v0.23 · o que o minha-automacao pediu para ficar 100% na gem: seletor segmentado, botão sem desenho, chips de marcar,
# movimento para ilustração, grade por tela e papel de parede.
class V23WebTest < ComponentTest
  CSS = Pathname(ComponentesUi::Engine.root).join("app/assets/tailwind/componentes_ui")

  test "SegmentedComponent: links com aria-current e botões com aria-pressed" do
    render_inline(Ss::SegmentedComponent.new(label: "Período", items: [{ label: "Dia", href: "/d", current: true }, { label: "Semana", href: "/s" }]))
    assert_selector "div.ss-seg[role=group][aria-label='Período']"
    assert_selector "a[href='/d'][aria-current=true]", text: "Dia"
    assert_selector "a[href='/s']:not([aria-current])", text: "Semana"

    render_inline(Ss::SegmentedComponent.new(label: "Andar", scroll: true, items: [
      { label: "Térreo", pressed: true, data: { action: "planta#andar" } }, { label: "1º", type: :submit, name: "f", value: "1" }]))
    assert_selector "div.ss-seg.is-scroll"
    assert_selector "button[type=button][aria-pressed=true][data-action='planta#andar']", text: "Térreo"
    assert_selector "button[type=submit][name=f][value='1'][aria-pressed=false]", text: "1º"
  end

  test "SegmentedComponent: aria-selected do item vence o aria-pressed (abas do JS)" do
    render_inline(Ss::SegmentedComponent.new(items: [{ label: "A", aria: { selected: "true" } }]))
    assert_selector "button[aria-selected=true]:not([aria-pressed])"
  end

  test "ButtonComponent(variant: :bare): botão sem desenho com o conteúdo livre" do
    render_inline(Ss::ButtonComponent.new(variant: :bare, type: :submit, name: "style", value: "glass")) { "<span class='x'>Vidro</span>".html_safe }
    assert_selector "button.ss-btn-bare[type=submit][name=style][value=glass] span.x", text: "Vidro"
    assert_no_selector ".ss-btn-bare.ss-btn"
  end

  test "FormBuilder: ss_chip_check_box e ss_chip_radio_buttons no .ss-chip" do
    view = ApplicationController.new.view_context
    html = view.ss_form_with(url: "/x") do |f|
      f.ss_chip_check_box("rooms[]", label: "Sala", checked_value: "sala", unchecked_value: nil, checked: true) +
        f.ss_chip_radio_buttons(:mode, [["Limpar", "clean"], ["Aspirar", "vacuum"]], label: "Modo", hide_label: true, checked: "vacuum")
    end
    page = Capybara.string(html)
    assert page.has_css?("label.ss-chip > input[type=checkbox][name='rooms[]'][value=sala][checked]")
    assert page.has_no_css?("input[type=hidden][name='rooms[]']")
    assert page.has_css?("label.ss-chip", text: "Sala")
    assert page.has_css?("fieldset.ss-chip-group legend.ss-label.ss-sr", text: "Modo")
    assert page.has_css?(".ss-chips label.ss-chip > input[type=radio][name=mode][value=vacuum][checked]")
    assert page.has_css?(".ss-chips label.ss-chip > input[type=radio][name=mode][value=clean]:not([checked])")
  end

  test "CSS: movimento, grade por tela, papel de parede e as peças novas, importados no engine" do
    css = CSS.join("v23_web.css").read
    %w[.ss-anim-spin .ss-anim-float .ss-anim-draw .ss-anim-path .ss-anim-shuttle .ss-span-grid .ss-span-flags .ss-hide-mobile
       .ss-wall .ss-wall-glass .ss-btn-bare .ss-seg.is-scroll .ss-chip-group].each { |c| assert_includes css, c }
    assert_includes css, '[data-ss-screen="mobile"] .ss-span'
    assert_match(/prefers-reduced-motion: reduce\) \{\n\s+\.ss-anim-spin/, css)
    assert_no_match(/#\h{3,8}\b/, css.gsub(%r{/\*.*?\*/}m, ""))
    assert_includes CSS.join("engine.css").read, %(@import "./v23_web.css";)
  end
end
