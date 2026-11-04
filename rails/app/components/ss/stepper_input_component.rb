module Ss
  # Campo numérico com −/+ em volta (o .ss-stepper do engine com um input de verdade).
  #   render Ss::StepperInputComponent.new(name: "regra[minutos]", label: "Minutos", value: 5, min: 0, max: 120, step: 5, unit: "min")
  # Nos limites, o botão do lado trava; segurar −/+ repete. disabled: true apaga tudo.
  class StepperInputComponent < BaseComponent
    attr_reader :name, :label, :value, :min, :max, :step, :unit, :id

    def initialize(name:, value: 0, min: nil, max: nil, step: 1, unit: nil, label: nil, disabled: false, hide_label: false,
                   less_label: nil, more_label: nil, id: nil, **rest)
      super(**rest)
      @name, @value, @min, @max, @step, @unit, @label = name, value, min, max, step, unit, label
      @disabled, @hide_label, @less_label, @more_label = disabled, hide_label, less_label, more_label
      @id = id || "ss-stp-#{SecureRandom.hex(3)}"
    end

    def disabled? = !!@disabled
    def at_min? = !min.nil? && value.to_f <= min.to_f
    def at_max? = !max.nil? && value.to_f >= max.to_f
    def less_label = @less_label || I18n.t("componentes_ui.stepper_input.less", default: "Diminuir")
    def more_label = @more_label || I18n.t("componentes_ui.stepper_input.more", default: "Aumentar")

    def call
      tag.div(class: classes("ss-field", "ss-stepper-field"), **root_attrs) do
        safe_join([
          (tag.label(label, for: id, class: ["ss-label", ("ss-sr" if @hide_label)]) if label),
          tag.div(class: "ss-stepper ss-stepper-input", data: { controller: "ss-stepper" }) do
            safe_join([
              button(:down, "−", less_label, disabled? || at_min?),
              tag.input(type: "number", id:, name:, value:, min:, max:, step:, inputmode: step.to_s.include?(".") ? "decimal" : "numeric",
                        class: "num", disabled: disabled?, aria: { label: (label ? nil : name.to_s) }.compact,
                        data: { ss_stepper_target: "input", action: "input->ss-stepper#sync change->ss-stepper#clamp" }),
              (tag.span(unit, class: "ss-stepper-unit", aria: { hidden: true }) if unit),
              button(:up, "+", more_label, disabled? || at_max?)
            ].compact)
          end
        ].compact)
      end
    end

    private

    def button(dir, sym, text, off)
      tag.button(sym, type: "button", aria: { label: text }, title: text, disabled: off,
                      data: { ss_stepper_target: dir.to_s, action: "pointerdown->ss-stepper#hold pointerup->ss-stepper#release pointerleave->ss-stepper#release pointercancel->ss-stepper#release click->ss-stepper##{dir}" })
    end
  end
end
