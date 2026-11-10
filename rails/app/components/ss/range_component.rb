module Ss
  # Slider (.ss-range) com o valor ao lado e marcas opcionais embaixo.
  # format: "R$ %d", "%d%%", "%d km", "%.1f °C" (como o sprintf); ticks: [0, 25, 50, 75, 100].
  # v0.10.1: o número sai com o separador decimal do idioma ("%.1f" → "21,5" em pt, "21.5" em
  # en), no servidor (ss_t number.separator) e no JS (Intl); sem separador de milhar.
  #   render Ss::RangeComponent.new(name: "desconto", label: "Desconto", value: 10, max: 30, format: "%d%%", ticks: [0, 10, 20, 30])
  #
  # v0.10 (casa), tudo opcional:
  # - track: :brightness | :kelvin | :hue (trilha em gradiente; o seletor pega a cor do ponto) ou
  #   gradient: "linear-gradient(...)" próprio; tone: cor da parte cheia/brilho (:warn, :heat, "#f59e0b").
  # - bubble: true mostra a bolha com o valor em cima do seletor enquanto arrasta.
  # - variant: :fill vira a barra grossa de tile (a parte cheia é o valor), com icon: e o rótulo dentro.
  # - disabled: true; hide_label: true (rótulo só para o leitor de tela).
  # - v0.14.1: icon: também na variante padrão, antes do rótulo (o SsFieldLabel(icon:) do app).
  # - submit: :release envia o form ao soltar (change, com debounce: ms); :input envia arrastando.
  #   Use dentro de um form (ou um button_to/form_with do Turbo):
  #   <%= form_with url: comando_path(p), method: :post do %>
  #     <%= render Ss::RangeComponent.new(name: "value", label: "Brilho", value: 80, format: "%d%%", track: :brightness, variant: :fill, submit: :release) %>
  #   <% end %>
  class RangeComponent < BaseComponent
    TONES = { accent: "var(--accent)", success: "var(--success)", warn: "var(--warn)", danger: "var(--danger)",
              info: "var(--ss-info)", heat: "#e0952a" }.freeze
    TRACKS = %i[brightness kelvin hue].freeze

    attr_reader :name, :label, :value, :min, :max, :step, :ticks, :fmt, :id, :track, :icon, :submit, :debounce

    def initialize(name:, label:, value: 0, min: 0, max: 100, step: 1, ticks: nil, format: "%s", id: nil,
                   track: nil, gradient: nil, tone: nil, bubble: false, variant: :default, icon: nil, disabled: false,
                   hide_label: false, submit: nil, debounce: 250, **rest)
      super(**rest)
      @name, @label, @value, @min, @max, @step, @ticks, @fmt = name, label, value, min, max, step, ticks, format
      @id = id || "ss-rng-#{SecureRandom.hex(3)}"
      @track = TRACKS.include?(track&.to_sym) ? track.to_sym : nil
      @gradient, @tone, @bubble, @variant, @icon, @disabled = gradient, tone, bubble, variant.to_sym, icon, disabled
      @hide_label = hide_label
      @submit = %i[release input].include?(submit&.to_sym) ? submit.to_sym : nil
      @debounce = debounce
    end

    def pct(v = value) = max == min ? 0 : ((v.to_f - min) * 100.0 / (max - min)).round(2)

    # Formato estilo sprintf (%s, %d, %.Nf, %%), com o decimal do idioma.
    def text(v = value)
      fmt.to_s.sub(/%(?:\.(\d+))?([sdf])/) { local_number(v, $2, $1) }.gsub("%%", "%")
    end

    def local_number(v, kind, prec)
      raw = case kind
            when "d" then v.to_f.truncate.to_s
            when "f" then Kernel.format("%.#{(prec || 6).to_i}f", v.to_f)
            else prec ? Kernel.format("%.#{prec.to_i}f", v.to_f) : v.to_s
            end
      return raw unless raw.match?(/\A-?\d+\.\d+\z/)

      raw.sub(".", ss_t("number.separator", default: ","))
    end

    def fill? = @variant == :fill
    def bubble? = !!@bubble
    def disabled? = !!@disabled
    def hide_label? = !!@hide_label
    def gradient? = !track_css.nil?

    # Só a v0.9 (nada novo pedido): a marcação fica igual à de antes.
    def plain? = !fill? && !bubble? && !gradient? && tone_css.nil? && submit.nil?

    def tone_css
      return nil if @tone.nil?
      return TONES[@tone.to_sym] if TONES.key?(@tone.to_s.to_sym)

      @tone.to_s if @tone.to_s.match?(/\A[#\w\s(),.%-]+\z/)
    end

    def track_css
      return @gradient if @gradient.to_s.match?(/\A[#\w\s(),.%-]+\z/)

      case track
      when :brightness
        c = tone_css || "var(--accent)"
        "linear-gradient(to right, color-mix(in srgb, #{c} 14%, #1e1a38), #{c})"
      when :kelvin
        stops = (0..6).map { |i| self.class.kelvin_hex(min + (max - min) * i / 6.0) }
        "linear-gradient(to right, #{stops.join(', ')})"
      when :hue
        "linear-gradient(to right, #{(0..6).map { |i| "hsl(#{i * 60} 100% 50%)" }.join(', ')})"
      end
    end

    # Cor do seletor no valor atual (o JS refaz ao mexer).
    def thumb_css(v = value)
      case track
      when :kelvin then self.class.kelvin_hex(v.to_f)
      when :hue then "hsl(#{v.to_f.round} 100% 50%)"
      when :brightness then "color-mix(in srgb, #{tone_css || 'var(--accent)'} #{[pct(v), 14].max.round}%, #1e1a38)"
      else tone_css
      end
    end

    def style
      parts = ["--p:#{pct}%", "--pn:#{(pct / 100.0).round(4)}"]
      parts << "--range-track:#{track_css}" if gradient?
      parts << "--range-c:#{thumb_css}" if thumb_css
      parts.join(";")
    end

    # Cor aproximada de uma temperatura de cor (Tanner Helland), igual à do SsSlider.kelvinColor.
    def self.kelvin_hex(k)
      t = k.to_f.clamp(1000, 40_000) / 100
      if t <= 66
        r = 255
        g = 99.4708025861 * Math.log(t) - 161.1195681661
        b = t <= 19 ? 0 : 138.5177312231 * Math.log(t - 10) - 305.0447927307
      else
        r = 329.698727446 * ((t - 60)**-0.1332047592)
        g = 288.1221695283 * ((t - 60)**-0.0755148492)
        b = 255
      end
      Kernel.format("#%02x%02x%02x", *[r, g, b].map { |x| x.clamp(0, 255).round })
    end

    def controller_data
      d = { controller: "ss-range", ss_range_format_value: fmt }
      return d if plain?

      d[:ss_range_track_value] = track.to_s if track
      d[:ss_range_tone_value] = tone_css if tone_css && track == :brightness
      d[:ss_range_submit_value] = submit.to_s if submit
      d[:ss_range_debounce_value] = debounce if submit
      d
    end

    def input_classes = ["ss-range", ("is-gradient" if gradient?), ("is-fill" if fill?)].compact.join(" ")
  end
end
