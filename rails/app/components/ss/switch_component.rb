module Ss
  # Chave sozinha (liga/desliga), com o mesmo movimento do .ss-switch-row (líquido, gota e ✓).
  #
  # Modo A, checkbox dentro de um form (name:):
  #   render Ss::SwitchComponent.new(name: "regra[ativa]", checked: true, label: "Ativa")
  # Modo B, comando (url:): um button_to com aria-pressed; o clique já vira a chave e o
  # servidor confirma (se falhar, ela volta):
  #   render Ss::SwitchComponent.new(url: comando_path(@luz, cmd: "toggle"), on: @luz.on?, label: "Luz da sala")
  #
  # label: vai no aria-label (e ao lado, com show_label: true); confirm: pergunta antes
  # (Modo B pelo data-turbo-confirm; Modo A pelo controller ss-switch).
  class SwitchComponent < BaseComponent
    attr_reader :name, :url, :label, :value, :params, :http_method, :confirm, :id

    def initialize(label:, name: nil, checked: false, url: nil, on: nil, disabled: false, confirm: nil,
                   value: "1", unchecked_value: "0", method: :post, params: {}, show_label: false, label_end: false,
                   id: nil, **rest)
      raise ArgumentError, "Ss::SwitchComponent: passe name: (form) ou url: (comando)" if name.nil? && url.nil?

      super(**rest)
      @label, @name, @url, @value, @params, @http_method, @confirm = label, name, url, value, params, method, confirm
      @checked = on.nil? ? checked : on
      @disabled, @unchecked_value, @show_label, @label_end = disabled, unchecked_value, show_label, label_end
      @id = id || "ss-sw-#{SecureRandom.hex(3)}"
    end

    def command? = url.present?
    def on? = !!@checked
    def disabled? = !!@disabled
    def show_label? = !!@show_label

    def call
      command? ? command : checkbox
    end

    private

    # Modo A: o .ss-switch-row do engine (o ss-motion já toca a troca).
    def checkbox
      tag.label(class: classes("ss-switch-row", "ss-switch-solo", ("is-label-end" if @label_end)), for: id,
                **root_attrs(data: { controller: "ss-switch", ss_switch_confirm_value: confirm }.compact)) do
        safe_join([
          tag.span(label, class: ("ss-sr" unless show_label?)),
          (hidden_field_tag(name, @unchecked_value, id: nil) unless @unchecked_value.nil?),
          check_box_tag(name, value, on?, id:, role: "switch", disabled: disabled?, data: { action: "change->ss-switch#confirmChange" })
        ].compact)
      end
    end

    # Modo B: button_to com aria-pressed. A chave vira na hora (ss-switch) e volta se o servidor falhar.
    def command
      form_data = { controller: "ss-switch", ss_switch_on_label_value: turn_off_label, ss_switch_off_label_value: turn_on_label }
      form_data[:turbo_confirm] = confirm if confirm
      button = button_to(url, method: http_method, params:, class: "ss-switch", disabled: disabled?, id:,
                              form_class: "ss-switch-form", form: { data: form_data },
                              aria: { pressed: on?.to_s, label: label }, title: (on? ? turn_off_label : turn_on_label),
                              data: { ss_switch_target: "button" }) { tag.span(class: "ss-switch-hit") }
      return tag.span(button, class: classes("ss-switch-wrap"), **root_attrs) unless show_label?

      tag.span(class: classes("ss-switch-cmd"), **root_attrs) { safe_join([tag.span(label, aria: { hidden: true }), button]) }
    end

    def turn_on_label = I18n.t("componentes_ui.switch.turn_on", default: "Ligar")
    def turn_off_label = I18n.t("componentes_ui.switch.turn_off", default: "Desligar")
  end
end
