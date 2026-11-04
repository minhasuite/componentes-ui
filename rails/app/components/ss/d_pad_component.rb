module Ss
  # Controle remoto: cruz (cima, baixo, esquerda, direita) com OK no meio, voltar/início/menu e,
  # opcional, as gangorras de volume e canal.
  #
  #   render Ss::DPadComponent.new(url: remoto_path(tv), volume: true, channel: true)
  #
  # Com url:, cada tecla é um button_to (POST) com o param key= (up, down, left, right, ok, back,
  # home, menu, volume_up, volume_down, mute, channel_up, channel_down). Sem url, as teclas só
  # disparam o evento "ss-dpad:key" (detail: { key }) para o JS do app. Com foco no controle, as
  # setas do teclado, Enter (ok) e Esc (back) apertam a tecla certa (controller ss-dpad).
  class DPadComponent < BaseComponent
    DEFAULTS = { up: "Cima", down: "Baixo", left: "Esquerda", right: "Direita", ok: "OK", back: "Voltar",
                 home: "Início", menu: "Menu", volume_up: "Aumentar volume", volume_down: "Diminuir volume",
                 mute: "Sem som", channel_up: "Próximo canal", channel_down: "Canal anterior", volume: "VOL",
                 channel: "CH", remote: "Controle remoto" }.freeze
    ICONS = { up: :up, down: :down, left: :left, right: :right, back: :back, home: :home, menu: :menu,
              volume_up: :plus, volume_down: :minus, mute: :volume_off, channel_up: :up, channel_down: :down }.freeze

    attr_reader :url, :param

    def initialize(url: nil, param: :key, method: :post, volume: false, channel: false, mute: false, disabled: false,
                   labels: {}, **rest)
      super(**rest)
      @url, @param, @method = url, param, method
      @volume, @channel, @mute, @disabled = volume, channel, mute, disabled
      @labels = labels.to_h.transform_keys(&:to_sym)
    end

    def label(key) = @labels[key] || ss_t("d_pad.#{key}", default: DEFAULTS[key])
    def volume? = @volume
    def channel? = @channel
    def mute? = @mute
    def disabled? = @disabled

    def key(name, css)
      inner = name == :ok ? tag.span(label(:ok)) : Ss::CasaIcons.svg(ICONS[name])
      opts = { class: "ss-dpad-key #{css}", title: label(name), aria: { label: label(name) }, disabled: disabled?,
               data: { key: name, action: "ss-dpad#press" } }
      if url
        button_to(url, method: @method, params: { param => name }, form_class: "ss-dpad-form", **opts) { inner }
      else
        tag.button(inner, type: "button", **opts)
      end
    end

    def root_data
      own = @attrs.to_h[:data].to_h
      { controller: [own[:controller] || own["controller"], "ss-dpad"].compact.join(" "),
        action: "keydown->ss-dpad#keydown" }
    end
  end
end
