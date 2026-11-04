require "test_helper"

class AFormComponentsTest < ComponentTest
  test "combobox: role, aria e hidden" do
    render_inline Ss::ComboboxComponent.new(name: "p[cliente_id]", label: "Cliente", options: [{ id: 1, label: "Ana" }], create: true, value: 1, text: "Ana")
    assert_selector "[data-controller=ss-combobox][data-ss-combobox-create-value=true]"
    assert_selector "input[role=combobox][aria-expanded=false][aria-autocomplete=list][value=Ana]"
    assert_selector "ul[role=listbox][hidden]", visible: :all
    assert_selector "input[type=hidden][name='p[cliente_id]'][value='1']", visible: :all
  end

  test "combobox por url" do
    render_inline Ss::ComboboxComponent.new(name: "c", label: "Cliente", url: "/clientes.json")
    assert_selector "[data-ss-combobox-url-value='/clientes.json']"
  end

  test "dinheiro: formata e manda centavos" do
    render_inline Ss::MoneyInputComponent.new(name: "v", label: "Valor", value_cents: 123456)
    assert_selector "input.ss-money[value='R$ 1.234,56'][inputmode=numeric]"
    assert_selector ".ss-money-view .ss-amount small", text: ",56"
    assert_selector "input[type=hidden][name=v][value='123456']", visible: :all
  end

  test "período com atalhos" do
    render_inline Ss::DateRangeComponent.new(from_name: "de", to_name: "ate", from: "2026-11-01")
    assert_selector "fieldset.ss-date-range input[type=date][name=de][value='2026-11-01']"
    assert_selector "input[type=date][name=ate]"
    assert_selector ".ss-date-chips button[data-ss-date-range-range-param]", count: 4
  end

  test "divisão soma 100 e mostra valor" do
    render_inline Ss::SplitAllocatorComponent.new(name: "d", total: 10_000, items: [{ key: "a", label: "A", value: 1 }, { key: "b", label: "B", value: 2 }])
    values = page.all("input[type=range]").map { |i| i[:value].to_i }
    assert_equal 100, values.sum
    assert_selector "input[name='d[a]'].ss-range"
    assert_selector ".ss-allot-out small", text: "R$"
  end

  test "arquivos com direct upload" do
    render_inline Ss::FileDropComponent.new(name: "anexos[]", accept: "image/*", direct_upload_url: "/rails/active_storage/direct_uploads")
    assert_selector "label.ss-file-drop-zone input[type=file][multiple][accept='image/*'][data-direct-upload-url]", visible: :all
    assert_selector "ul.ss-file-list", visible: :all
  end

  test "edição no lugar local e com url" do
    render_inline Ss::InlineEditComponent.new(value: "Ana", name: "c[nome]", label: "Nome")
    assert_selector "button.ss-inline-edit-view[aria-label='Editar Nome: Ana']", text: "Ana"
    assert_selector "form[hidden] input[name='c[nome]'][value=Ana]", visible: :all
    render_inline Ss::InlineEditComponent.new(value: "Ana", name: "c[nome]", label: "Nome", url: "/clientes/1")
    assert_selector "form[action='/clientes/1'] input[name=_method][value=patch]", visible: :all
    assert_selector "[data-ss-inline-edit-remote-value=true]"
  end

  test "passo a passo" do
    render_inline(Ss::WizardComponent.new(draft_key: "x")) do |w|
      w.with_step(title: "Um") { "primeiro" }
      w.with_step(title: "Dois") { "segundo" }
    end
    assert_selector "[data-controller=ss-wizard][data-ss-wizard-key-value=x]"
    assert_selector ".ss-wizard-steps li", count: 2
    assert_selector ".ss-wizard-steps li[aria-current=step]", text: "Um"
    assert_selector "section.ss-wizard-panel", text: "primeiro"
    assert_selector "section.ss-wizard-panel[hidden]", visible: :all, text: "segundo"
  end

  test "código OTP" do
    render_inline Ss::OtpInputComponent.new(name: "codigo", length: 4)
    assert_selector ".ss-otp-boxes input[maxlength='1']", count: 4
    assert_selector "input[autocomplete=one-time-code]", count: 1
    assert_selector "input[type=hidden][name=codigo]", visible: :all
  end

  test "cor" do
    render_inline Ss::SwatchPickerComponent.new(name: "cor", selected: "b", options: [{ value: "a", label: "A", color: "#000" }, { value: "b", label: "B", color: "#fff" }])
    assert_selector ".ss-swatch-picker-item input[type=radio][name=cor]", count: 2, visible: :all
    assert_selector "input[value=b][checked]", visible: :all
    assert_selector ".ss-swatch-picker-item[style*='--c:#fff']"
  end

  test "etiquetas" do
    render_inline Ss::TagInputComponent.new(name: "tags", label: "Etiquetas", values: %w[a b])
    assert_selector ".ss-tag", count: 2
    assert_selector "button[aria-label='Remover a']"
    assert_selector "input[type=hidden][name=tags][value='a,b']", visible: :all
  end

  test "card de opção" do
    render_inline Ss::OptionCardComponent.new(name: "plano", value: "anual", title: "Anual", description: "2 meses", checked: true)
    assert_selector "label.ss-option-card input[type=radio][value=anual][checked]"
    assert_selector ".ss-option-card-body strong", text: "Anual"
    render_inline Ss::OptionCardComponent.new(name: "a[]", value: "x", title: "X", type: :checkbox)
    assert_selector "label.ss-option-card.is-check input[type=checkbox]"
  end

  test "slider com valor e marcas" do
    render_inline Ss::RangeComponent.new(name: "d", label: "Desconto", value: 10, max: 40, format: "%d%%", ticks: [0, 20, 40])
    assert_selector "input[type=range].ss-range[value='10'][style*='--p:25.0%'][aria-valuetext='10%']"
    assert_selector "output.ss-range-out", text: "10%"
    assert_selector ".ss-range-ticks span", count: 3
  end
end
