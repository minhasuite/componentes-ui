module Ss
  # Campo numérico com −/+ em volta (o .ss-stepper do engine com um input de verdade).
  #   render Ss::StepperInputComponent.new(name: "regra[minutos]", label: "Minutos", value: 5, min: 0, max: 120, step: 5, unit: "min")
  # Nos limites, o botão do lado trava; segurar −/+ repete. disabled: true apaga tudo (botões
  # travados, só o valor). Rótulos dos botões (aria-label/title): decrease_label:/increase_label:
  # (v0.10.1, nomes do SsStepper; less_label:/more_label: continuam), padrão stepper_input.less/more.
  # Não envia sozinho: o form é de quem chama (escute o change do input).
  # v0.14.1: icon: (svg) antes do rótulo, como o SsFieldLabel(icon:) do app.
  # v1.2.1 (par do SsStepper(decimals:)): decimals: N (> 0) mostra o número no idioma da página ("0,5" em pt-BR,
  # "0.5" em en) com N casas: o campo vira texto com inputmode=decimal (o <input type=number> do Chromium mostra
  # "0.5" mesmo em pt-BR) e o ss-stepper lê e escreve pelo Intl com o lang do <html>; −/+ e os limites continuam.
  # Ao servidor vai sempre o ponto: o name: fica num <input type=hidden> ("0.5"), atualizado a cada mudança; o
  # campo visível não tem name. Quem lê o event.target do change recebe o texto do idioma ("0,5").
  class StepperInputComponent < BaseComponent
    attr_reader :name, :label, :value, :min, :max, :step, :unit, :id

    def initialize(name:, value: 0, min: nil, max: nil, step: 1, unit: nil, label: nil, disabled: false, hide_label: false,
                   less_label: nil, more_label: nil, decrease_label: nil, increase_label: nil, id: nil, icon: nil, decimals: nil, **rest)
      super(**rest)
      @name, @value, @min, @max, @step, @unit, @label = name, value, min, max, step, unit, label
      @disabled, @hide_label, @icon = disabled, hide_label, icon
      @less_label, @more_label = decrease_label || less_label, increase_label || more_label
      @id = id || "ss-stp-#{SecureRandom.hex(3)}"
      @decimals = decimals.to_i.positive? ? decimals.to_i : nil
    end

    def decimal? = !@decimals.nil?
    # O valor com ponto (o que vai ao servidor) e o do idioma da página (o que a pessoa vê).
    def raw_value = value.nil? || value.to_s == "" ? "" : Kernel.format("%.#{@decimals}f", value.to_f)
    def shown_value = raw_value == "" ? "" : ss_number(value.to_f, precision: @decimals)

    def disabled? = !!@disabled
    def at_min? = !min.nil? && value.to_f <= min.to_f
    def at_max? = !max.nil? && value.to_f >= max.to_f
    def less_label = @less_label || I18n.t("componentes_ui.stepper_input.less", default: "Diminuir")
    def more_label = @more_label || I18n.t("componentes_ui.stepper_input.more", default: "Aumentar")

    def call
      tag.div(class: classes("ss-field", "ss-stepper-field"), **root_attrs) do
        safe_join([
          (tag.label(safe_join([(@icon.to_s.html_safe if @icon.present?), label].compact), for: id, class: ["ss-label", ("ss-sr" if @hide_label)]) if label),
          tag.div(class: "ss-stepper ss-stepper-input", data: { controller: "ss-stepper", ss_stepper_decimals_value: @decimals }.compact) do
            safe_join([
              button(:down, "−", less_label, disabled? || at_min?),
              (decimal? ? decimal_input : number_input),
              (tag.span(unit, class: "ss-stepper-unit", aria: { hidden: true }) if unit),
              button(:up, "+", more_label, disabled? || at_max?)
            ].compact)
          end
        ].compact)
      end
    end

    private

    def number_input
      tag.input(type: "number", id:, name:, value:, min:, max:, step:, inputmode: step.to_s.include?(".") ? "decimal" : "numeric",
                class: "num", disabled: disabled?, aria: { label: (label ? nil : name.to_s) }.compact,
                data: { ss_stepper_target: "input", action: "input->ss-stepper#sync change->ss-stepper#clamp" })
    end

    # v1.2.1: texto no idioma da página + o hidden com o ponto (o name:).
    def decimal_input
      safe_join([
        tag.input(type: "text", id:, value: shown_value, inputmode: "decimal", autocomplete: "off", class: "num", disabled: disabled?,
                  aria: { label: (label ? nil : name.to_s) }.compact,
                  data: { ss_stepper_target: "input", min:, max:, step:, action: "input->ss-stepper#sync change->ss-stepper#clamp" }.compact),
        tag.input(type: "hidden", name:, value: raw_value, disabled: disabled?, data: { ss_stepper_target: "raw" })
      ])
    end

    def button(dir, sym, text, off)
      tag.button(sym, type: "button", aria: { label: text }, title: text, disabled: off,
                      data: { ss_stepper_target: dir.to_s, action: "pointerdown->ss-stepper#hold pointerup->ss-stepper#release pointerleave->ss-stepper#release pointercancel->ss-stepper#release click->ss-stepper##{dir}" })
    end
  end
end
