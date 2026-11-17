require "test_helper"

# v1.2.1 · correções do minhas-vendas (loja online): linha do tempo que escondia passos e o stepper com vírgula.
class V121WebTest < ComponentTest
  CSS = Pathname(ComponentesUi::Engine.root).join("app/assets/tailwind/componentes_ui")
  JS = Pathname(ComponentesUi::Engine.root).join("app/javascript/componentes_ui/controllers")

  # ── TimelineHorizontalComponent: nenhum passo fora do cartão ──
  test "linha do tempo: marcos dividem a largura (sem 12,5rem fixos nem rolagem) e ficam em pé abaixo de 36rem" do
    assert_includes CSS.join("engine.css").read, '@import "./v121_web.css";'
    css = CSS.join("v121_web.css").read
    assert_includes css, ".ss-htl { container: ss-htl / inline-size; flex-wrap: wrap; overflow-x: visible; scroll-snap-type: none; }"
    assert_includes css, ".ss-htl li { flex: 1 1 0; min-width: 0; overflow-wrap: anywhere; }"
    assert_includes css, "@container ss-htl (max-width: 36rem)"
    assert_includes css, ".ss-htl li { flex: 0 0 100%; grid-template-columns: 1.1rem minmax(0, 1fr);"
    assert_match(/\.ss-htl li > i::after \{ left: calc\(\.55rem - 1px\); right: auto; top: 1\.3rem; bottom: -1\.1rem; width: 2px;/, css)
    # A marcação não muda (só CSS): ol.ss-htl com o passo atual em aria-current.
    render_inline(Ss::TimelineHorizontalComponent.new(items: [{ title: "Recebido", state: :done }, { title: "Saiu", state: :current }, { title: "Entregue" }]))
    assert_selector "ol.ss-htl > li", count: 3
    assert_selector "ol.ss-htl > li.is-current[aria-current=step]", text: "Saiu"
  end

  # ── StepperInputComponent(decimals:) ──
  test "stepper decimals: texto no idioma da página com inputmode decimal e o ponto num hidden com o name" do
    render_inline(Ss::StepperInputComponent.new(name: "q_1", label: "Quantidade", value: 0.5, min: 0, max: 3, step: 0.5, unit: "kg", decimals: 1))
    assert_selector ".ss-stepper[data-controller=ss-stepper][data-ss-stepper-decimals-value='1']"
    vis = page.find("input[type=text][data-ss-stepper-target=input]")
    assert_equal "0,5", vis[:value]
    assert_equal "decimal", vis[:inputmode]
    assert_nil vis[:name]
    assert_equal %w[0 3 0.5], [vis["data-min"], vis["data-max"], vis["data-step"]]
    hid = page.find("input[type=hidden][data-ss-stepper-target=raw]", visible: :all)
    assert_equal ["q_1", "0.5"], [hid[:name], hid[:value]]
    assert_no_selector "input[type=number]"
    assert_selector "label[for='#{vis[:id]}']", text: "Quantidade"
    I18n.with_locale(:en) do
      render_inline(Ss::StepperInputComponent.new(name: "q", value: 2, step: 0.5, decimals: 1))
      assert_equal "2.0", page.find("input[type=text]")[:value]
      assert_equal "2.0", page.find("input[type=hidden]", visible: :all)[:value]
    end
  end

  test "stepper sem decimals continua o <input type=number> com o name; o JS faz a conta e o hidden" do
    render_inline(Ss::StepperInputComponent.new(name: "minutos", value: 5, min: 0, max: 120, step: 5))
    assert_selector "input[type=number][name=minutos][value='5'][step='5']"
    assert_no_selector "input[type=hidden]", visible: :all
    assert_no_selector "[data-ss-stepper-decimals-value]"
    js = JS.join("ss_stepper_controller.js").read
    assert_includes js, 'static targets = ["input", "down", "up", "raw"]'
    assert_includes js, "new Intl.NumberFormat(this.lang, { minimumFractionDigits: this.decimalsValue"
    assert_includes js, 'this.rawTarget.value = n === null ? "" : n.toFixed(this.decimalsValue)'
  end
end
