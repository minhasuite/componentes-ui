module Ss
  # Player de mídia: capa, título, subtítulo, anterior/tocar/próxima, progresso com tempos, volume
  # e a fonte ("Spotify · Sala"). Os comandos são formulários (button_to) para as URLs do app.
  #
  #   render Ss::MediaPlayerComponent.new(title: "Águas de Março", subtitle: "Elis & Tom", art_url: capa,
  #            state: :playing, position: 97, duration: 212, volume: 0.45, source: "Spotify · Sala",
  #            play_url: midia_path(p, cmd: :play), pause_url: midia_path(p, cmd: :pause),
  #            previous_url: …, next_url: …, volume_url: midia_path(p, cmd: :volume), seek_url: …)
  #
  # state: :idle | :playing | :paused | :buffering | :unavailable. position/duration em segundos.
  # volume_url/seek_url: o slider manda o formulário ao soltar (param volume 0..100 / position em s).
  # Tocando, o controller ss-media faz o tempo andar até o próximo render (Turbo Stream do app).
  # power: true (ligado) / false (desligado) / nil (sem botão) + power_url: (v0.10.1, como o
  # SsMediaPlayer(power:, onPower:)): botão liga/desliga no canto (button_to, aria-pressed);
  # funciona parado (idle), trava com unavailable. Rótulo: media_player.power_on/power_off.
  # Também da v0.10.1 (SsMediaPlayer(volumeParam:, onVolumeUp/Down:, muted:, onMute:, mediaPicker:)):
  # - volume_param: nome do param do slider de volume (padrão "volume").
  # - volume_up_url:/volume_down_url: botões −/+ de volume (para aparelho sem volume absoluto).
  # - mute_url: + muted: botão de mudo no lugar do ícone do volume (aria-pressed = muted).
  # - slot with_media_picker { … }: o que tocar (fontes, playlists) embaixo dos controles.
  class MediaPlayerComponent < BaseComponent
    STATES = %i[idle playing paused buffering unavailable].freeze

    renders_one :media_picker
    DEFAULTS = { play: "Tocar", pause: "Pausar", previous: "Anterior", next: "Próxima", volume: "Volume",
                 progress: "Posição", idle: "Nada tocando", unavailable: "Indisponível", buffering: "Carregando",
                 power_on: "Ligar", power_off: "Desligar", mute: "Silenciar", unmute: "Tirar do mudo",
                 volume_up: "Aumentar volume", volume_down: "Diminuir volume" }.freeze

    attr_reader :subtitle, :art_url, :state, :source, :duration, :volume, :method

    def initialize(title: nil, subtitle: nil, art_url: nil, state: :idle, position: nil, duration: nil, volume: nil,
                   source: nil, play_url: nil, pause_url: nil, previous_url: nil, next_url: nil, volume_url: nil,
                   seek_url: nil, method: :post, labels: {}, power: nil, power_url: nil, volume_param: "volume",
                   volume_up_url: nil, volume_down_url: nil, mute_url: nil, muted: false, **rest)
      super(**rest)
      @title, @subtitle, @art_url, @source = title, subtitle, art_url, source
      @state = STATES.include?(state.to_s.to_sym) ? state.to_s.to_sym : :idle
      @position, @duration = position&.to_i, duration&.to_i
      @volume = volume.nil? ? nil : volume.to_f.clamp(0.0, 1.0)
      @urls = { play: play_url, pause: pause_url, previous: previous_url, next: next_url, volume: volume_url, seek: seek_url }
      @method = method
      @power, @power_url = power, power_url
      @volume_param, @muted, @mute_url = volume_param.presence || "volume", muted, mute_url
      @urls.merge!(volume_up: volume_up_url, volume_down: volume_down_url)
      @labels = labels.to_h.transform_keys(&:to_sym)
    end

    def label(key) = @labels[key] || ss_t("media_player.#{key}", default: DEFAULTS[key])
    def url(key) = @urls[key]
    def off? = state == :unavailable
    def active? = !off? && state != :idle
    def playing? = %i[playing buffering].include?(state)
    def position = (@position || 0).clamp(0, duration || 0)
    def pct = duration.to_i.positive? ? (position * 100.0 / duration).round(2) : 0

    def title
      return @title if @title.present?

      off? ? label(:unavailable) : (state == :idle ? label(:idle) : "")
    end

    # 3:07 ou 1:02:03.
    def self.fmt(sec)
      sec = sec.to_i
      h, m, s = sec / 3600, (sec % 3600) / 60, sec % 60
      h.positive? ? format("%d:%02d:%02d", h, m, s) : format("%d:%02d", m, s)
    end

    def fmt(sec) = self.class.fmt(sec)
    def icon(name) = Ss::CasaIcons.svg(name)

    # Botão de comando: form com button_to; sem URL (ou indisponível), botão desabilitado.
    def command(key, icon_name, css:, text: nil)
      lbl = text || label(key)
      inner = safe_join([icon(icon_name), tag.span(lbl, class: "ss-sr")])
      if url(key) && active_for?(key)
        button_to(url(key), method:, class: css, form_class: "ss-media-form", title: lbl, aria: { label: lbl }) { inner }
      else
        tag.button(inner, type: "button", class: css, disabled: true, title: lbl, aria: { label: lbl })
      end
    end

    def volume_param = @volume_param
    def muted? = !!@muted
    def volume_steps? = url(:volume_up).present? || url(:volume_down).present?
    def volume_row? = !volume.nil? || volume_steps? || @mute_url.present?
    def volume_icon = icon(muted? || volume.to_f.zero? && !volume.nil? ? :volume_off : :volume)

    # Mudo: button_to com aria-pressed; sem mute_url, só o ícone.
    def mute_button
      return volume_icon unless @mute_url

      lbl = label(muted? ? :unmute : :mute)
      opts = { class: "ss-media-btn ss-media-mute#{" is-on" if muted?}", title: lbl, aria: { label: lbl, pressed: muted?.to_s } }
      return tag.button(volume_icon, type: "button", disabled: true, **opts) if off?

      button_to(@mute_url, method:, form_class: "ss-media-form", **opts) { volume_icon }
    end

    def volume_step(key, icon_name)
      return unless url(key)

      lbl = label(key)
      opts = { class: "ss-media-btn ss-media-step", title: lbl, aria: { label: lbl } }
      return tag.button(icon(icon_name), type: "button", disabled: true, **opts) if off?

      button_to(url(key), method:, form_class: "ss-media-form", **opts) { icon(icon_name) }
    end

    def power? = !@power.nil?
    def power_on? = !!@power

    # Liga/desliga: aria-pressed com o estado; o rótulo diz o que o clique faz.
    def power_button
      lbl = label(power_on? ? :power_off : :power_on)
      css = ["ss-media-btn", "ss-media-power", ("is-on" if power_on?)].compact.join(" ")
      opts = { class: css, title: lbl, aria: { label: lbl, pressed: power_on?.to_s } }
      if @power_url && !off?
        button_to(@power_url, method:, form_class: "ss-media-form", **opts) { icon(:power) }
      else
        tag.button(icon(:power), type: "button", disabled: true, **opts)
      end
    end

    def active_for?(key) = %i[play pause].include?(key) ? !off? : active?

    def play_key = playing? ? :pause : :play
    def play_label = state == :buffering ? label(:buffering) : label(play_key)

    def root_data
      own = @attrs.to_h[:data].to_h
      ctrl = [own[:controller] || own["controller"], "ss-media"].compact.join(" ")
      { state:, controller: ctrl, ss_media_playing_value: (state == :playing || nil),
        ss_media_position_value: position, ss_media_duration_value: duration }.compact
    end
  end
end
