require "test_helper"

# v0.10 (controles da casa): tile de aparelho, chave, slider (extensão do Range), termostato,
# teclado de código, campo −/+ e dias da semana.
class V10ControlesTest < ComponentTest
  test "chave modo A: checkbox com role=switch no .ss-switch-row (mesmo movimento)" do
    render_inline(Ss::SwitchComponent.new(name: "regra[ativa]", checked: true, label: "Ativa"))
    assert_selector "label.ss-switch-row.ss-switch-solo[data-controller=ss-switch]"
    assert_selector "input[type=hidden][name='regra[ativa]'][value='0']", visible: :all
    assert_selector "input[type=checkbox][role=switch][name='regra[ativa]'][value='1'][checked]"
    assert_selector "span.ss-sr", text: "Ativa"
    render_inline(Ss::SwitchComponent.new(name: "x", label: "X", disabled: true, show_label: true, confirm: "Certeza?"))
    assert_selector "input[type=checkbox][disabled]"
    assert_selector "label[data-ss-switch-confirm-value='Certeza?'] > span:not(.ss-sr)", text: "X"
  end

  test "chave modo B: button_to com aria-pressed, confirmação e params" do
    render_inline(Ss::SwitchComponent.new(url: "/pontos/1/comando", on: true, label: "Luz da sala", params: { cmd: "toggle" }, confirm: "Desligar?"))
    assert_selector "form.ss-switch-form[action='/pontos/1/comando'][method=post][data-controller=ss-switch][data-turbo-confirm='Desligar?']"
    assert_selector "form button.ss-switch[aria-pressed=true][aria-label='Luz da sala'][title=Desligar]"
    assert_selector "form input[type=hidden][name=cmd][value=toggle]", visible: :all
    render_inline(Ss::SwitchComponent.new(url: "/x", on: false, label: "Tomada", disabled: true, show_label: true))
    assert_selector ".ss-switch-cmd > span", text: "Tomada"
    assert_selector "button.ss-switch[aria-pressed=false][disabled]"
    assert_raises(ArgumentError) { Ss::SwitchComponent.new(label: "sem nada") }
  end

  test "tile de aparelho: ligado com tom, link de detalhes e chave" do
    render_inline(Ss::DeviceTileComponent.new(name: "Luz da sala", state: "Ligada · 80%", on: true, tone: :heat,
                                              url: "/pontos/1", toggle_url: "/pontos/1/toggle")) { |t| t.with_footer { "rodapé" } }
    assert_selector ".ss-device.is-on[data-status=ready][style*='--tone: #e0952a']"
    assert_selector "a.ss-device-text[href='/pontos/1'] .ss-device-name", text: "Luz da sala"
    assert_selector ".ss-device-state", text: "Ligada · 80%"
    assert_selector ".ss-device-end button.ss-switch[aria-pressed=true][aria-label='Desligar Luz da sala']"
    assert_selector ".ss-device-foot", text: "rodapé"
  end

  test "tile de aparelho: indisponível, enviando, erro e sem permissão" do
    render_inline(Ss::DeviceTileComponent.new(name: "Tomada", state: "Ligada", on: true, status: :unavailable, toggle_url: "/t", wide: true))
    assert_selector ".ss-device.is-wide[data-status=unavailable]:not(.is-on)"
    assert_selector ".ss-device-state", text: "Indisponível"
    assert_selector "button.ss-switch[disabled]"
    render_inline(Ss::DeviceTileComponent.new(name: "Tomada", state: "Ligada", status: :pending, toggle_url: "/t"))
    assert_selector ".ss-device[data-status=pending][aria-busy=true] .ss-device-spin"
    assert_selector ".ss-device-state[data-pending='Enviando…']"
    render_inline(Ss::DeviceTileComponent.new(name: "Tomada", status: :error, error_text: "Sem resposta", toggle_url: "/t"))
    assert_selector ".ss-device[data-status=error] .ss-device-state", text: "Sem resposta"
    assert_no_selector "button.ss-switch[disabled]"
    render_inline(Ss::DeviceTileComponent.new(name: "Portão", status: :locked, toggle_url: "/t"))
    assert_selector ".ss-device-lock[role=img][aria-label='Sem permissão']"
    assert_no_selector "button.ss-switch"
    render_inline(Ss::DeviceTileComponent.new(name: "x", tone: "red;}body{x"))
    assert_no_selector ".ss-device[style]"
  end

  test "range: marcação antiga não muda sem as opções novas" do
    render_inline(Ss::RangeComponent.new(name: "desconto", label: "Desconto", value: 10, max: 30, format: "%d%%", ticks: [0, 10, 20, 30]))
    assert_selector ".ss-range-field[data-controller=ss-range] > input.ss-range[type=range][style='--p:33.33%']"
    assert_no_selector ".ss-range-track, .ss-range-bubble"
    assert_selector "input[data-action='input->ss-range#update']"
  end

  test "range: gradiente kelvin, bolha, fill e envio ao soltar" do
    render_inline(Ss::RangeComponent.new(name: "k", label: "Cor", value: 2700, min: 2000, max: 6500, step: 100, track: :kelvin, bubble: true,
                                         submit: :release, format: "%d K"))
    assert_selector "[data-ss-range-track-value=kelvin][data-ss-range-submit-value=release][data-ss-range-debounce-value='250']"
    assert_selector ".ss-range-track input.ss-range.is-gradient[style*='--range-track:linear-gradient'][data-action*='change->ss-range#commit']"
    assert_selector ".ss-range-bubble", text: "2700 K"
    quente = Ss::RangeComponent.kelvin_hex(2000)
    assert_match(/\A#ff[0-9a-f]{4}\z/, quente)
    assert_operator quente[5, 2].to_i(16), :<, 0x60 # pouco azul: âmbar
    assert_operator Ss::RangeComponent.kelvin_hex(9000)[5, 2].to_i(16), :>, 0xf0
    render_inline(Ss::RangeComponent.new(name: "v", label: "Luz da cozinha", value: 80, variant: :fill, format: "%d%%", disabled: true))
    assert_selector ".ss-range-field.is-fill .ss-range-fillbox[style*='--p:80'] input.ss-range.is-fill[aria-label='Luz da cozinha'][disabled]"
    assert_selector ".ss-range-fill-text.is-on b", text: "Luz da cozinha"
  end

  test "termostato: form, anel, −/+ nos limites e modos" do
    render_inline(Ss::ThermostatComponent.new(name: "value", target: 22.5, current: 20, mode: "heat", url: "/clima/1", max: 30))
    assert_selector "form.ss-thermo[action='/clima/1'][data-controller=ss-thermostat][data-mode=heat][data-hvac=heating][style*='--f:']"
    assert_selector ".ss-thermo-dial[role=slider][aria-valuenow='22.5'][aria-valuetext='22,5°']"
    assert_selector ".ss-thermo-value", text: "22,5°"
    assert_selector ".ss-thermo-now", text: "Agora 20°"
    assert_selector ".ss-thermo-legend", text: "Aquecendo"
    assert_selector "input[type=hidden][name=value][value='22.5']", visible: :all
    assert_selector "fieldset.ss-thermo-modes input[type=radio][name=mode][value=heat][checked]"
    assert_selector ".ss-thermo-mode", count: 4
    render_inline(Ss::ThermostatComponent.new(target: 30, max: 30, mode: "cool", current: 31, pending: true,
                                              modes: [:cool, { value: "dry", label: "Secar", tone: "#14b8a6" }]))
    assert_selector "div.ss-thermo[aria-busy=true][data-hvac=cooling]"
    assert_selector "button[data-ss-thermostat-target=plus][disabled]"
    assert_selector "button[data-ss-thermostat-target=minus]:not([disabled])"
    assert_selector ".ss-thermo-legend", text: "Enviando…"
    assert_selector ".ss-thermo-mode[data-value=dry][style*='--mc: #14b8a6']", text: "Secar"
    render_inline(Ss::ThermostatComponent.new(target: 21, mode: "off"))
    assert_selector ".ss-thermo[data-mode=off] .ss-thermo-dial[aria-disabled=true][tabindex='-1']"
    assert_selector ".ss-thermo-legend", text: "Desligado"
    render_inline(Ss::ThermostatComponent.new(target: 21, disabled: true))
    assert_selector ".ss-thermo.is-disabled input[type=radio][disabled]", count: 4
  end

  test "teclado de código: bolinhas, teclas, ações e estados" do
    render_inline(Ss::CodeKeypadComponent.new(url: "/alarme", name: "code", length: 4,
                                              actions: [{ label: "Armar ausente", name: "cmd", value: "arm_away", primary: true },
                                                        { label: "Armar em casa", name: "cmd", value: "arm_home" }]))
    assert_selector "form.ss-keypad[action='/alarme'][data-controller=ss-code-keypad][data-state=idle][data-ss-code-keypad-length-value='4']"
    assert_selector ".ss-keypad-dots i", count: 4
    assert_selector ".ss-keypad-grid button[data-digit]", count: 10
    assert_selector ".ss-keypad-back[aria-label=Apagar]"
    assert_selector "button[type=submit][name=cmd][value=arm_away].ss-btn-primary[disabled]", text: "Armar ausente"
    assert_selector "input[type=hidden][name=code]", visible: :all
    render_inline(Ss::CodeKeypadComponent.new(error: true))
    assert_selector "div.ss-keypad[data-state=error] .ss-keypad-msg", text: "Código incorreto"
    assert_selector "button[type=submit]", text: "Confirmar"
    render_inline(Ss::CodeKeypadComponent.new(busy: true, length: 6))
    assert_selector ".ss-keypad[data-state=busy][aria-busy=true] .ss-keypad-dots i", count: 6
    assert_no_selector "button[type=submit]"
    render_inline(Ss::CodeKeypadComponent.new(success: true, obscure: false))
    assert_selector ".ss-keypad[data-state=success][data-ss-code-keypad-obscure-value=false] .ss-keypad-msg", text: "Pronto"
  end

  test "campo −/+: limites e desabilitado" do
    render_inline(Ss::StepperInputComponent.new(name: "minutos", label: "Minutos", value: 0, min: 0, max: 120, step: 5, unit: "min"))
    assert_selector "label.ss-label[for]", text: "Minutos"
    assert_selector ".ss-stepper.ss-stepper-input[data-controller=ss-stepper] input[type=number][name=minutos][min='0'][max='120'][step='5'][value='0']"
    assert_selector "button[data-ss-stepper-target=down][aria-label=Diminuir][disabled]"
    assert_selector "button[data-ss-stepper-target=up][aria-label=Aumentar]:not([disabled])"
    assert_selector ".ss-stepper-unit", text: "min"
    render_inline(Ss::StepperInputComponent.new(name: "n", value: 10, max: 10))
    assert_selector "button[data-ss-stepper-target=up][disabled]"
    render_inline(Ss::StepperInputComponent.new(name: "n", value: 3, disabled: true))
    assert_selector "input[disabled]"
    assert_selector "button[disabled]", count: 2
  end

  test "dias da semana: checkboxes name[], ordem e atalhos" do
    render_inline(Ss::WeekdayPickerComponent.new(name: "regra[dias]", selected: [1, 2, 3, 4, 5]))
    assert_selector "fieldset.ss-weekday[data-controller=ss-weekday] input[type=hidden][name='regra[dias][]'][value='']", visible: :all
    assert_selector ".ss-weekday-day input[type=checkbox][name='regra[dias][]']", count: 7
    assert_selector ".ss-weekday-day input[checked]", count: 5
    assert_selector ".ss-weekday-day:first-child input[value='1'][aria-label=Segunda-feira]"
    assert_selector ".ss-weekday-shortcuts[hidden] button[aria-pressed=true]", text: "Dias úteis", visible: :all
    assert_selector ".ss-weekday-shortcuts button[aria-pressed=false]", text: "Todos os dias", visible: :all
    render_inline(Ss::WeekdayPickerComponent.new(name: "d", first_day: 7, values: %w[mon tue wed thu fri sat sun], selected: %w[sun], shortcuts: false))
    assert_selector ".ss-weekday-day:first-child input[value=sun][checked][aria-label=Domingo]"
    assert_no_selector ".ss-weekday-shortcuts"
  end
end
