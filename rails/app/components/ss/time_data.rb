module Ss
  # v0.10 (dados): conta compartilhada do gráfico no tempo, das faixas de estado e
  # do logbook (a mesma do Flutter, dados_formato.dart, e do ss_time_axis.js).
  module TimeData
    ON = %w[on open true ligado ligada aberto aberta home playing unlocked detected].freeze
    OFF = %w[off closed false desligado desligada fechado fechada idle locked clear].freeze
    BAD = %w[error erro problem jammed].freeze
    NONE = %w[unavailable unknown indisponível desconhecido].freeze

    module_function

    # time_zone: dos componentes (v0.10.1): nome IANA ("America/Sao_Paulo") ou do Rails
    # ("Brasilia"). nil = o Time.zone do app (e, no JS, o fuso do navegador).
    def zone(name)
      return nil if name.blank?

      ActiveSupport::TimeZone[name.to_s] || raise(ArgumentError, "time_zone desconhecido: #{name}")
    end

    # O instante no fuso (ou no Time.zone).
    def local(t, zone) = zone ? t.in_time_zone(zone) : t.in_time_zone

    # Nome IANA para o Intl do JS.
    def iana(zone) = zone&.tzinfo&.name

    # Instante em ms desde a época (o que o JS usa).
    def ms(t) = (t.to_time.to_f * 1000).round

    # Tom de um estado: o do mapa do app; senão ligado/aberto = accent, desligado/fechado
    # = neutral, erro = danger; o resto nil (vai para a paleta de séries).
    def tone_for(state, tones = {})
      t = tones[state.to_s] || tones[state.to_s.to_sym]
      return t.to_s if t

      s = state.to_s.downcase
      return "accent" if ON.include?(s)
      return "neutral" if OFF.include?(s) || NONE.include?(s)
      return "danger" if BAD.include?(s)

      nil
    end

    # Estado → data-tone de todos os trechos: tom ou "s2".."s6" (paleta de séries,
    # na ordem em que o estado aparece; a s1 é a marca, que já é o "ligado").
    def tones_of(rows, tones = {})
      livre = 1
      rows.each_with_object({}) do |r, out|
        Array(r[:segments]).each do |s|
          k = s[:state].to_s
          next if out.key?(k)

          out[k] = tone_for(k, tones) || begin
            n = livre % 6 + 1
            livre += 1
            "s#{n}"
          end
        end
      end
    end

    # Duração curta: "2 h 30 min", "3 d 4 h" (en: "2h 30m").
    def duration(seconds, locale = I18n.locale)
      en = locale.to_s.start_with?("en")
      u = ->(n, pt, e) { en ? "#{n}#{e}" : "#{n} #{pt}" }
      min = (seconds / 60).floor
      return u.(seconds.floor, "s", "s") if min < 1
      return u.(min, "min", "m") if min < 60

      h = min / 60
      if h < 24
        return (min % 60).zero? ? u.(h, "h", "h") : "#{u.(h, "h", "h")} #{u.(min % 60, "min", "m")}"
      end

      d = h / 24
      (h % 24).zero? ? u.(d, "d", "d") : "#{u.(d, "d", "d")} #{u.(h % 24, "h", "h")}"
    end

    # Casas automáticas pelo tamanho: ≥ 100 → 0, ≥ 10 → 1, abaixo → 2 (zeros do fim somem).
    def auto_decimals(v) = v.abs >= 100 ? 0 : (v.abs >= 10 ? 1 : 2)
  end
end
