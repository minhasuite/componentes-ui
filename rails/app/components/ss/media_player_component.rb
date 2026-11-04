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
  class MediaPlayerComponent < BaseComponent
    STATES = %i[idle playing paused buffering unavailable].freeze
    DEFAULTS = { play: "Tocar", pause: "Pausar", previous: "Anterior", next: "Próxima", volume: "Volume",
                 progress: "Posição", idle: "Nada tocando", unavailable: "Indisponível", buffering: "Carregando" }.freeze

    attr_reader :subtitle, :art_url, :state, :source, :duration, :volume, :method

    def initialize(title: nil, subtitle: nil, art_url: nil, state: :idle, position: nil, duration: nil, volume: nil,
                   source: nil, play_url: nil, pause_url: nil, previous_url: nil, next_url: nil, volume_url: nil,
                   seek_url: nil, method: :post, labels: {}, **rest)
      super(**rest)
      @title, @subtitle, @art_url, @source = title, subtitle, art_url, source
      @state = STATES.include?(state.to_s.to_sym) ? state.to_s.to_sym : :idle
      @position, @duration = position&.to_i, duration&.to_i
      @volume = volume.nil? ? nil : volume.to_f.clamp(0.0, 1.0)
      @urls = { play: play_url, pause: pause_url, previous: previous_url, next: next_url, volume: volume_url, seek: seek_url }
      @method = method
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
