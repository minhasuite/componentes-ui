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
  # Modo B, extras: params: (campos ocultos do form) e form_data: (v0.10.1, atributos a mais
  # do <form> gerado, como o form: do button_to), por exemplo
  #   form_data: { data: { turbo_frame: "luzes" } }
  # O data-controller do app soma com o ss-switch; os data-ss-switch-* da gem ficam.
  # confirm_title: (v0.10.1) título da caixa de confirmação da suíte (Ss::ConfirmDialogComponent):
  # no Modo B vai em data-turbo-confirm-title; no Modo A, a caixa é usada se estiver na página.
  class SwitchComponent < BaseComponent
    attr_reader :name, :url, :label, :value, :params, :http_method, :confirm, :id

    def initialize(label:, name: nil, checked: false, url: nil, on: nil, disabled: false, confirm: nil,
                   value: "1", unchecked_value: "0", method: :post, params: {}, show_label: false, label_end: false,
                   id: nil, form_data: {}, confirm_title: nil, **rest)
      raise ArgumentError, "Ss::SwitchComponent: passe name: (form) ou url: (comando)" if name.nil? && url.nil?

      super(**rest)
      @label, @name, @url, @value, @params, @http_method, @confirm = label, name, url, value, params, method, confirm
      @checked = on.nil? ? checked : on
      @disabled, @unchecked_value, @show_label, @label_end = disabled, unchecked_value, show_label, label_end
      @id = id || "ss-sw-#{SecureRandom.hex(3)}"
      @form_data = (form_data || {}).to_h.deep_symbolize_keys
      @confirm_title = confirm_title
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
                **root_attrs(data: { controller: "ss-switch", ss_switch_confirm_value: confirm,
                                     ss_switch_confirm_title_value: (@confirm_title if confirm) }.compact)) do
        safe_join([
          tag.span(label, class: ("ss-sr" unless show_label?)),
          (hidden_field_tag(name, @unchecked_value, id: nil) unless @unchecked_value.nil?),
          check_box_tag(name, value, on?, id:, role: "switch", disabled: disabled?, data: { action: "change->ss-switch#confirmChange" })
        ].compact)
      end
    end

    # Modo B: button_to com aria-pressed. A chave vira na hora (ss-switch) e volta se o servidor falhar.
    def command
      button = button_to(url, method: http_method, params:, class: "ss-switch", disabled: disabled?, id:,
                              form_class: "ss-switch-form", form: form_attrs,
                              aria: { pressed: on?.to_s, label: label }, title: (on? ? turn_off_label : turn_on_label),
                              data: { ss_switch_target: "button" }) { tag.span(class: "ss-switch-hit") }
      return tag.span(button, class: classes("ss-switch-wrap"), **root_attrs) unless show_label?

      tag.span(class: classes("ss-switch-cmd"), **root_attrs) { safe_join([tag.span(label, aria: { hidden: true }), button]) }
    end

    # Atributos do <form>: os do app (form_data:) com os da gem por cima; controller e class somam.
    def form_attrs
      own = { controller: "ss-switch", ss_switch_on_label_value: turn_off_label, ss_switch_off_label_value: turn_on_label }
      own[:turbo_confirm] = confirm if confirm
      own[:turbo_confirm_title] = @confirm_title if confirm && @confirm_title
      app = @form_data.except(:data)
      app_data = @form_data[:data].to_h
      own[:controller] = [app_data[:controller], own[:controller]].compact.join(" ")
      app.merge(class: ["ss-switch-form", app[:class]].compact.join(" "), data: app_data.merge(own))
    end

    def turn_on_label = I18n.t("componentes_ui.switch.turn_on", default: "Ligar")
    def turn_off_label = I18n.t("componentes_ui.switch.turn_off", default: "Desligar")
  end
end
