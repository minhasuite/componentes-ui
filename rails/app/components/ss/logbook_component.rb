module Ss
  # Logbook (v0.10): diário de eventos agrupado por dia, com o cabeçalho do dia que gruda
  # no topo ("Hoje", "Ontem", depois a data) e o "carregar mais" no fim. Cada linha tem a
  # hora, o ícone num quadrado tonal, o título (link com href:), o estado em pílula e o
  # detalhe. Mesmo nome e comportamento do SsLogbook (Flutter).
  #
  #   render Ss::LogbookComponent.new(entries: @eventos, more_url: logbook_path(cursor: @proximo))
  #   entries: [{ at:, title:, detail: nil, icon: nil, tone: :accent, state: nil, href: nil }]
  #
  # Página seguinte (Turbo): com more_url, o rodapé é um turbo-frame. lazy: true (padrão)
  # carrega sozinho quando o rodapé aparece; lazy: false mostra o botão "Carregar mais".
  # A action da página seguinte responde com o mesmo componente e frame: o id que o
  # Turbo mandou:
  #   render Ss::LogbookComponent.new(entries: @eventos, more_url: …, frame: request.headers["Turbo-Frame"])
  # O dia que continua da página anterior não repete o cabeçalho (o controller esconde).
  # Falhou a página: o rodapé mostra o erro e "Tentar de novo".
  #
  # Estados: loading: true (linhas-fantasma), sem entries (vazio), error: "…" (com
  # retry_url:), sem more_url (fim: "Início do registro").
  # icon: SVG html_safe do app ou um destes nomes: dot power light door lock alert check user
  # thermo motion. tone: accent success warn danger info neutral.
  class LogbookComponent < BaseComponent
    include InView

    ICONS = {
      "power" => '<path d="M12 3v9M6.3 6.3a8 8 0 1 0 11.4 0"/>',
      "light" => '<path d="M9 18h6M10 21h4M12 3a6 6 0 0 0-3.5 10.9c.6.5 1 1.2 1 2V16h5v-.1c0-.8.4-1.5 1-2A6 6 0 0 0 12 3z"/>',
      "door" => '<path d="M5 21V4a1 1 0 0 1 1-1h12a1 1 0 0 1 1 1v17M3 21h18M15 12h.01"/>',
      "lock" => '<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/>',
      "alert" => '<path d="M12 9v4M12 17h.01M10.3 3.9 2.4 18a2 2 0 0 0 1.7 3h15.8a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z"/>',
      "check" => '<path d="M5 12l5 5 9-10"/>',
      "user" => '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>',
      "thermo" => '<path d="M14 14.8V5a2 2 0 0 0-4 0v9.8a4 4 0 1 0 4 0z"/>',
      "motion" => '<circle cx="13" cy="4" r="2"/><path d="M9 21l2-6 3 3v3M7 12l3-4 4 2 3 3"/>',
      "dot" => '<circle cx="12" cy="12" r="3" fill="currentColor" stroke="none"/>'
    }.freeze
    TONES = %w[accent success warn danger info neutral].freeze

    def initialize(entries:, more_url: nil, frame: nil, lazy: true, loading: false, error: nil, retry_url: nil,
                   now: nil, label: nil, texts: {}, **opts)
      super(**opts)
      @entries = entries.to_a
      @more_url = more_url
      @frame = frame.presence
      @lazy = lazy
      @loading = loading
      @error = error
      @retry_url = retry_url
      @now = now
      @label = label
      @texts = texts.to_h.transform_keys(&:to_sym)
    end

    def text(key, default) = @texts[key] || ss_t("logbook.#{key}", default:)

    def label = @label || text(:label, "Registro de eventos")
    def loading? = @loading
    def error = @error
    def retry_url = @retry_url
    def frame = @frame
    def lazy? = @lazy
    def more_url = @more_url
    def empty? = @entries.empty?

    # Id do turbo-frame da próxima página (estável para o mesmo more_url).
    def next_frame_id = "ss-lb-#{Digest::MD5.hexdigest(@more_url.to_s)[0, 10]}"

    def today = (@now || Time.zone.now).in_time_zone.to_date

    # [[data, [entradas]]] na ordem em que vieram (o mais novo primeiro).
    def days
      @entries.chunk_while { |a, b| a[:at].in_time_zone.to_date == b[:at].in_time_zone.to_date }
              .map { |g| [g.first[:at].in_time_zone.to_date, g] }
    end

    def day_label(d)
      return text(:today, "Hoje") if d == today
      return text(:yesterday, "Ontem") if d == today - 1

      wd = ss_weekdays[d.wday].to_s.delete(".")
      fmt = d.year == today.year ? :day_month : :date
      "#{wd}, #{ss_date(d, fmt)}"
    end

    def tone(e)
      t = e[:tone].to_s
      t = "warn" if t == "warning"
      TONES.include?(t) ? t : "neutral"
    end

    def icon(e)
      i = e[:icon]
      return i if i.respond_to?(:html_safe?) && i.html_safe?

      path = ICONS[i.to_s] || ICONS["dot"]
      %(<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">#{path}</svg>).html_safe
    end

    def time_of(e) = ss_date(e[:at].in_time_zone, :time)
  end
end
