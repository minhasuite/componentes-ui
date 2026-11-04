module Ss
  # Tile de aparelho da casa: ícone, nome e estado em texto ("Ligada · 80%"). O nome é um link
  # para os detalhes (url:) que cobre o tile todo; toggle_url: põe a chave rápida à direita
  # (Ss::SwitchComponent modo B). Rodapé opcional (slider, chips) no slot footer.
  #
  #   render Ss::DeviceTileComponent.new(name: "Luz da sala", state: "Ligada · 80%", on: true, icon: svg,
  #            url: ponto_path(p), toggle_url: comando_path(p, cmd: "toggle"), tone: :warn) do |t|
  #     t.with_footer { render Ss::RangeComponent.new(...) }
  #   end
  #
  # status: :ready | :unavailable (apagado e tracejado) | :pending (anel girando) | :error (vermelho,
  # error_text:) | :locked (cadeado, sem chave). tone: :accent (padrão), :success, :warn, :danger,
  # :info, :heat ou uma cor CSS ("#f59e0b", "var(--x)"). wide: true deita o tile numa linha.
  #
  # v0.10.1:
  # - Modo aperto (comando, portão, script, botão): action_url: liga o modo (mode: :press fica
  #   implícito). Tocar no tile faz POST em action_url: com action_params: (action_method: troca),
  #   em vez de ligar/desligar ou abrir os detalhes. confirm: + confirm_title: pedem confirmação
  #   (a Ss::ConfirmDialogComponent mostra). action_label: (leitor de tela; padrão
  #   device_tile.run "Acionar %{name}").
  # - confirm_title: também vale para a chave (toggle_url:).
  # - link_data: data-* do link de detalhes (ex. { turbo_frame: "_top" }).
  # - Cor real da luz: tone: "rgb(255, 200, 120)" (qualquer cor CSS simples já valia).
  class DeviceTileComponent < BaseComponent
    STATUSES = %i[ready unavailable pending error locked].freeze
    TONES = { accent: "var(--accent)", success: "var(--success)", warn: "var(--warn)", danger: "var(--danger)",
              info: "var(--ss-info)", heat: "#e0952a" }.freeze
    # Ícone padrão: lâmpada (o app passa o dele).
    BULB = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M9 18h6M10 21h4M12 3a6 6 0 0 0-3.5 10.9c.6.4 1 1.1 1 1.8V16h5v-.3c0-.7.4-1.4 1-1.8A6 6 0 0 0 12 3z"/></svg>'.freeze
    LOCK = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/></svg>'.freeze

    renders_one :footer

    attr_reader :name, :state, :url, :toggle_url, :toggle_params, :toggle_method, :status, :error_text

    def initialize(name:, state: nil, on: false, status: :ready, icon: nil, url: nil, toggle_url: nil, toggle_params: {},
                   toggle_method: :post, tone: nil, wide: false, error_text: nil, confirm: nil,
                   unavailable_label: nil, pending_label: nil, error_label: nil, locked_label: nil, details_label: nil,
                   link_data: {}, action_url: nil, action_params: {}, action_method: :post, action_label: nil, confirm_title: nil, **rest)
      super(**rest)
      @link_data, @action_url, @action_params, @action_method = link_data.to_h, action_url, action_params.to_h, action_method
      @action_label, @confirm_title = action_label, confirm_title
      @name, @state, @on, @icon, @url = name, state, on, icon, url
      @toggle_url, @toggle_params, @toggle_method, @confirm = toggle_url, toggle_params, toggle_method, confirm
      @status = STATUSES.include?(status.to_s.to_sym) ? status.to_s.to_sym : :ready
      @tone, @wide, @error_text = tone, wide, error_text
      @labels = { unavailable: unavailable_label, pending: pending_label, error: error_label, locked: locked_label, details: details_label }
    end

    def on? = @on && status != :unavailable
    def wide? = !!@wide
    def icon = (@icon || BULB).html_safe
    def lock_icon = LOCK.html_safe

    # Cor do aparelho: um dos tons da suíte ou uma cor CSS simples (nada que feche o style).
    def tone_css
      return nil if @tone.nil?
      return TONES[@tone.to_sym] if TONES.key?(@tone.to_s.to_sym)

      @tone.to_s if @tone.to_s.match?(/\A[#\w\s(),.%-]+\z/)
    end

    def label(key)
      @labels[key] || I18n.t("componentes_ui.device_tile.#{key}", default: DEFAULTS[key])
    end
    DEFAULTS = { unavailable: "Indisponível", pending: "Enviando…", error: "Não respondeu", locked: "Sem permissão",
                 details: "Abrir detalhes de %{name}", turn_on: "Ligar %{name}", turn_off: "Desligar %{name}",
                 run: "Acionar %{name}" }.freeze

    def details_label = label(:details).gsub("%{name}", name.to_s)

    def state_line
      case status
      when :unavailable then label(:unavailable)
      when :error then error_text || label(:error)
      else state.to_s
      end
    end

    def toggle? = toggle_url.present? && status != :locked && !press?
    def press? = @action_url.present?
    def link_data = @link_data.presence
    def action_label = @action_label || I18n.t("componentes_ui.device_tile.run", default: DEFAULTS[:run], name:)
    def press_disabled? = %i[unavailable pending locked].include?(status)

    # Tile de aperto: o texto vira o botão de um button_to que cobre o tile.
    def press_button(&)
      data = { turbo_confirm: @confirm, turbo_confirm_title: (@confirm_title if @confirm) }.compact
      button_to(@action_url, method: @action_method, params: @action_params, class: "ss-device-text ss-device-press",
                             disabled: press_disabled?, "aria-label": action_label, form: { class: "ss-device-press-form", data: }, &)
    end

    def switch
      key = on? ? :turn_off : :turn_on
      text = I18n.t("componentes_ui.device_tile.#{key}", default: DEFAULTS[key], name:)
      Ss::SwitchComponent.new(url: toggle_url, on: on?, label: text, method: toggle_method, params: toggle_params,
                              confirm: @confirm, confirm_title: @confirm_title, disabled: %i[unavailable pending].include?(status))
    end

    def root_classes = classes("ss-device", ("is-on" if on?), ("is-wide" if wide?), ("is-press" if press?))
  end
end
