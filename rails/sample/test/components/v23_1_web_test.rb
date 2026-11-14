require "test_helper"

# v0.23.1 · amostra de tema no builder, opção de rádio desligada e o form= no botão sem href.
class V231WebTest < ComponentTest
  def form(&blk)
    Capybara.string(ApplicationController.new.view_context.ss_form_with(url: "/x", &blk))
  end

  test "ss_swatch_radio: label.ss-swatch com o rádio, bolinhas, barra e nome" do
    page = form { |f| f.ss_swatch_radio(:theme, "aurora", label: "Aurora", style: "--p1: red", size: :lg, block: true, checked: true) }
    assert page.has_css?("label.ss-swatch.ss-swatch-lg.is-block[style='--p1: red'] > input[type=radio][name=theme][value=aurora][checked]")
    assert page.has_css?("label.ss-swatch .ss-swatch-dots[aria-hidden=true] i", count: 4)
    assert page.has_css?("label.ss-swatch .ss-swatch-bar")
    assert page.has_css?("label.ss-swatch .ss-swatch-name", text: "Aurora")
  end

  test "ss_swatch_radio: sem bolinhas/barra e com conteúdo próprio" do
    page = form { |f| f.ss_swatch_radio(:theme, "", label: "Herdar", dots: 0, bar: false, checked: false) { "<span class='x'>H</span>".html_safe } }
    assert page.has_css?("label.ss-swatch[title=Herdar] > input[type=radio][value='']:not([checked])")
    assert page.has_css?("label.ss-swatch span.x", text: "H")
    assert page.has_no_css?(".ss-swatch-dots")
  end

  test "ss_radio_buttons: 3º item desliga só aquela opção" do
    page = form { |f| f.ss_radio_buttons(:radio, [["Wi-Fi", "wifi"], ["Bluetooth", "ble", { disabled: true }]], label: "Rádio") }
    assert page.has_css?("input[type=radio][value=ble][disabled]")
    assert page.has_css?("input[type=radio][value=wifi]:not([disabled])")
  end

  test "ButtonComponent: form: texto vira o atributo form= do <button>" do
    render_inline(Ss::ButtonComponent.new(label: "Marcar", type: :submit, form: "f1", variant: :bare))
    assert_selector "button.ss-btn-bare[type=submit][form=f1]", text: "Marcar"
    render_inline(Ss::ButtonComponent.new(label: "Apagar", href: "/x", method: :delete, form: { class: "contents" }))
    assert_selector "form.contents button", text: "Apagar"
  end
end
