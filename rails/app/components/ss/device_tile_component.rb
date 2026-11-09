module Ss
  # Tile de aparelho da casa: ícone, nome e estado em texto ("Ligada · 80%"). O nome é um link
  # para os detalhes (url:) que cobre o tile todo; toggle_url: faz do ícone a chave rápida
  # (v0.12; antes era um Ss::SwitchComponent à direita). Rodapé opcional (slider, chips) no slot footer.
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
  #
  # v0.10.3 (par do SsDeviceTile(onLongPress:) do Flutter): more_url: põe o botão ⋯ ("Mais opções
  # de %{name}", more_label: troca) à direita e liga o menu de contexto do tile (clique direito ou
  # toque longo no celular) a ele. No modo aperto, url: vira o more_url (os detalhes, que o toque
  # não abre mais). more_data: data-* do link (ex. { turbo_frame: "modal" }). O toque duplo do app
  # não tem par no web (o duplo clique seleciona texto): é só do app.
  #
  # v0.12 (par do SsDeviceTile do Flutter): uma linha só. O ícone é a chave (toggle_url:): tocar no
  # quadrado do ícone liga/desliga (button role="switch" + aria-checked, Enter/Espaço, rótulo =
  # nome; title "Ligar"/"Desligar"); ligado, o quadrado fica cheio na cor (tone:), desligado, claro
  # com contorno. O nome e o estado ficam à direita do ícone (onde era a chave); ⋯, cadeado e ▶ no
  # fim. Pendente ("Enviando…"), erro, confirm:/confirm_title:, indisponível (chave travada),
  # sem permissão (ícone sem chave + cadeado) e modo aperto continuam iguais; wide: segue aceito
  # (o tile já é deitado). O form da chave tem data-controller="ss-switch" (o app reconhece).
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
                   link_data: {}, action_url: nil, action_params: {}, action_method: :post, action_label: nil, confirm_title: nil,
                   more_url: nil, more_label: nil, more_data: {}, **rest)
      super(**rest)
      @more_url, @more_label, @more_data = more_url, more_label, more_data.to_h
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
                 run: "Acionar %{name}", more: "Mais opções de %{name}" }.freeze

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
    def more_url = @more_url || (url if press?)
    def more? = more_url.present?
    def more_data = @more_data.presence
    def more_label = @more_label || I18n.t("componentes_ui.device_tile.more", default: DEFAULTS[:more], name:)
    def more_icon = Ss::CasaIcons.svg(:dots)

    def press_disabled? = %i[unavailable pending locked].include?(status)

    # Tile de aperto: o texto vira o botão de um button_to que cobre o tile.
    def press_button(&)
      data = { turbo_confirm: @confirm, turbo_confirm_title: (@confirm_title if @confirm) }.compact
      button_to(@action_url, method: @action_method, params: @action_params, class: "ss-device-text ss-device-press",
                             disabled: press_disabled?, "aria-label": action_label, form: { class: "ss-device-press-form", data: }, &)
    end

    def toggle_text(key) = I18n.t("componentes_ui.device_tile.#{key}", default: DEFAULTS[key], name:)
    def toggle_disabled? = %i[unavailable pending].include?(status)

    # v0.12: o quadrado do ícone é a chave (button_to com role=switch). O ss-switch vira na hora,
    # marca o tile "pending" e volta se o servidor falhar.
    def icon_toggle(&)
      form_data = { controller: "ss-switch", ss_switch_on_label_value: toggle_text(:turn_off), ss_switch_off_label_value: toggle_text(:turn_on) }
      form_data[:turbo_confirm] = @confirm if @confirm
      form_data[:turbo_confirm_title] = @confirm_title if @confirm && @confirm_title
      button_to(toggle_url, method: toggle_method, params: toggle_params, class: "ss-device-ico ss-device-toggle", disabled: toggle_disabled?,
                            form_class: "ss-device-toggle-form", form: { data: form_data }, role: "switch",
                            aria: { checked: on?.to_s, label: name }, title: toggle_text(on? ? :turn_off : :turn_on),
                            data: { ss_switch_target: "button" }, &)
    end

    def root_classes = classes("ss-device", ("is-on" if on?), ("has-toggle" if toggle?), ("is-wide" if wide?), ("is-press" if press?), ("has-more" if more?))

    # Menu de contexto (clique direito / toque longo) segue o ⋯; junta com o controller do app.
    def root_data
      own = @attrs.to_h[:data].to_h
      data = { status: }
      return data unless more?

      data.merge(controller: [own[:controller] || own["controller"], "ss-device"].compact.join(" "),
                 action: [own[:action] || own["action"], "contextmenu->ss-device#more"].compact.join(" "))
    end
  end
end
