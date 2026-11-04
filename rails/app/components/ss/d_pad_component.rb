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
  # nav_row: false (v0.10.1, SsDPad(navRow:)) tira a linha voltar/início/menu (câmera PTZ); o
  # mute:, se pedido, fica sozinho nela.
  # keys: { ok: "select", home: "KEY_HOME" } (v0.10.1, SsDPad(keys:)) troca o valor enviado
  # (param key=) de cada tecla; o teclado e o data-key continuam pelos nomes da gem.
  # extra_buttons: [{ name: "netflix", label: "Netflix", icon: svg }] (SsDPad(extraButtons:)):
  # botões aprendidos numa linha a mais; cada um manda key=<name> (e o evento com value: name).
  class DPadComponent < BaseComponent
    DEFAULTS = { up: "Cima", down: "Baixo", left: "Esquerda", right: "Direita", ok: "OK", back: "Voltar",
                 home: "Início", menu: "Menu", volume_up: "Aumentar volume", volume_down: "Diminuir volume",
                 mute: "Sem som", channel_up: "Próximo canal", channel_down: "Canal anterior", volume: "VOL",
                 channel: "CH", remote: "Controle remoto" }.freeze
    ICONS = { up: :up, down: :down, left: :left, right: :right, back: :back, home: :home, menu: :menu,
              volume_up: :plus, volume_down: :minus, mute: :volume_off, channel_up: :up, channel_down: :down }.freeze

    attr_reader :url, :param

    def initialize(url: nil, param: :key, method: :post, volume: false, channel: false, mute: false, disabled: false,
                   labels: {}, nav_row: true, keys: {}, extra_buttons: [], **rest)
      super(**rest)
      @url, @param, @method = url, param, method
      @volume, @channel, @mute, @disabled = volume, channel, mute, disabled
      @nav_row = nav_row != false
      @keys = keys.to_h.transform_keys(&:to_sym)
      @extra = Array(extra_buttons).map { |b| b.to_h.transform_keys(&:to_sym) }.select { _1[:name].present? }
      @labels = labels.to_h.transform_keys(&:to_sym)
    end

    def label(key) = @labels[key] || ss_t("d_pad.#{key}", default: DEFAULTS[key])
    def volume? = @volume
    def channel? = @channel
    def mute? = @mute
    def disabled? = @disabled
    def nav_row? = @nav_row
    def extra_buttons = @extra
    def value_of(name) = (@keys[name] || name).to_s

    def key(name, css)
      inner = name == :ok ? tag.span(label(:ok)) : Ss::CasaIcons.svg(ICONS[name])
      opts = { class: "ss-dpad-key #{css}", title: label(name), aria: { label: label(name) }, disabled: disabled?,
               data: { key: name, value: (value_of(name) if @keys.key?(name)), action: "ss-dpad#press" }.compact }
      if url
        button_to(url, method: @method, params: { param => value_of(name) }, form_class: "ss-dpad-form", **opts) { inner }
      else
        tag.button(inner, type: "button", **opts)
      end
    end

    # Botão aprendido: rótulo (e ícone, se vier) numa pílula.
    def extra_key(b)
      name = b[:name].to_s
      inner = safe_join([(b[:icon].to_s.html_safe if b[:icon].present?), tag.span(b[:label] || name)].compact)
      opts = { class: "ss-dpad-key is-extra", title: b[:label] || name, disabled: disabled?,
               data: { key: "extra", value: name, action: "ss-dpad#press" } }
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
