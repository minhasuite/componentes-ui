module Ss
  # Teclado de código (PIN do alarme): bolinhas dos dígitos, teclado 3×4 e apagar. O código vai
  # no hidden name:. Com length:, envia sozinho ao completar; sem ele, o botão de enviar (ou os
  # botões de actions:, cada um um submit com name/value próprios: "Armar ausente", "Armar em casa").
  #
  #   render Ss::CodeKeypadComponent.new(url: alarme_path, name: "code", length: 4,
  #            actions: [{ label: "Armar ausente", name: "cmd", value: "arm_away", primary: true },
  #                      { label: "Armar em casa", name: "cmd", value: "arm_home" }])
  #
  # Estados: vazio, digitando, error: "Código incorreto" (treme e limpa ao conectar; também se o
  # envio pelo Turbo falhar), busy: true (travado, enviando) e success: true (✓).
  # Sem url:, é só o bloco dentro do form de quem chama. obscure: false mostra os dígitos.
  class CodeKeypadComponent < BaseComponent
    BACK = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M9 5h11a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H9l-6-7z"/><path d="M12.5 9.5l5 5M17.5 9.5l-5 5"/></svg>'.freeze

    attr_reader :name, :length, :max_length, :url, :http_method, :title, :actions, :id

    def initialize(name: "code", length: nil, max_length: 8, obscure: true, url: nil, method: :post, actions: [],
                   title: nil, error: nil, busy: false, success: false, submit_label: nil, labels: {}, id: nil, **rest)
      super(**rest)
      @name, @length, @max_length, @obscure, @url, @http_method = name, length, max_length, obscure, url, method
      @actions, @title, @error, @busy, @success, @submit_label, @labels = actions, title, error, busy, success, submit_label, labels
      @id = id || "ss-keypad-#{SecureRandom.hex(3)}"
    end

    def tx(key, default) = @labels[key.to_sym] || I18n.t("componentes_ui.code_keypad.#{key}", default:)

    def obscure? = !!@obscure
    def form? = url.present?

    def state
      return "error" if @error.present?
      return "busy" if @busy
      return "success" if @success

      "idle"
    end

    def message
      case state
      when "error" then @error == true ? tx(:error, "Código incorreto") : @error
      when "success" then tx(:success, "Pronto")
      when "busy" then ""
      else ""
      end
    end

    def submit_label = @submit_label || tx(:submit, "Confirmar")

    # Botão de enviar só sem tamanho fixo e sem ações próprias.
    def submit_button? = length.nil? && actions.empty?

    def dots = length || 4

    def root_options
      opts = { class: classes("ss-keypad"), id:, tabindex: 0 }
      if form?
        opts[:action] = url
        opts[:method] = http_method.to_s == "get" ? "get" : "post"
      end
      root_attrs(**opts, aria: { busy: ("true" if state == "busy"), label: @title || tx(:label, "Teclado de código") }.compact, data: {
        controller: "ss-code-keypad", state:,
        ss_code_keypad_length_value: length.to_i, ss_code_keypad_max_value: length || max_length,
        ss_code_keypad_obscure_value: obscure?, ss_code_keypad_error_text_value: tx(:error, "Código incorreto"),
        ss_code_keypad_success_text_value: tx(:success, "Pronto"),
        action: "keydown->ss-code-keypad#key"
      })
    end

    def method_tag
      return unless form?

      safe_join([
        (hidden_field_tag("_method", http_method, id: nil) unless %w[get post].include?(http_method.to_s)),
        hidden_field_tag("authenticity_token", helpers.form_authenticity_token, id: nil)
      ].compact)
    rescue StandardError
      nil
    end

    def back_icon = BACK.html_safe
  end
end
