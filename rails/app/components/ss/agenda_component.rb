module Ss
  # Agenda de dia ou semana: horários à esquerda, linhas tracejadas, blocos
  # posicionados pelo início/fim com cor tonal (tone: accent/success/warn/danger/info),
  # linha do "agora" e eventos sobrepostos lado a lado.
  #
  #   render Ss::AgendaComponent.new(days: [Date.current], from: 8, to: 20, now: Time.current,
  #     events: [{ title: "Visita", sub: "Mercado Bom Preço", starts_at: t1, ends_at: t2, tone: :success, url: "…" }])
  class AgendaComponent < BaseComponent
    WEEKDAYS = %w[dom seg ter qua qui sex sáb].freeze

    attr_reader :days, :from, :to

    def initialize(events:, days: [Date.current], from: 8, to: 20, now: Time.current, label: nil, hour_height: 64, **opts)
      super(**opts)
      @events = events
      @days = Array(days)
      @from = from
      @to = to
      @now = now
      @label = label || ss_t("agenda.label", default: "Agenda")
      @hour_height = hour_height
    end

    def week? = @days.size > 1
    def hours = (@from...@to).to_a
    def total_min = (@to - @from) * 60.0

    def events_on(day) = @events.select { _1[:starts_at].to_date == day }

    # Posição de cada evento do dia, em % da coluna: top/height pelo horário,
    # left/width pela coluna dentro do grupo de eventos que se sobrepõem.
    def layout(events)
      sorted = events.sort_by { [_1[:starts_at], -(_1[:ends_at] - _1[:starts_at])] }
      placed = []
      cluster = []
      cluster_end = nil
      flush = lambda do
        cols = []
        cluster.each do |item|
          c = cols.index { |last_end| last_end <= item[:event][:starts_at] } || cols.size
          cols[c] = item[:event][:ends_at]
          item[:col] = c
        end
        cluster.each { |item| item[:cols] = cols.size }
        placed.concat(cluster)
        cluster = []
      end
      sorted.each do |e|
        flush.call if cluster_end && e[:starts_at] >= cluster_end
        cluster << { event: e }
        cluster_end = [cluster_end, e[:ends_at]].compact.max
        cluster_end = e[:ends_at] if cluster.size == 1
      end
      flush.call
      placed.map do |p|
        e = p[:event]
        top = minutes(e[:starts_at]).clamp(0, total_min)
        bottom = minutes(e[:ends_at]).clamp(0, total_min)
        w = 100.0 / p[:cols]
        { event: e, top: pct(top), height: pct([bottom - top, 15].max), left: (w * p[:col]).round(3), width: w.round(3) }
      end
    end

    def now_top(day)
      return nil unless @now && @now.to_date == day

      m = minutes(@now)
      m.between?(0, total_min) ? pct(m) : nil
    end

    def hhmm(t) = ss_date(t, :time)
    # Dias da semana do idioma (WEEKDAYS fica como o pt-BR, por compatibilidade).
    def weekdays = @weekdays ||= ss_weekdays
    def day_label(d) = "#{weekdays[d.wday]} #{d.day}"
    def now_text = ss_t("agenda.now", default: "Agora, %{time}", time: hhmm(@now))
    def today?(d) = @now && d == @now.to_date
    attr_reader :label, :hour_height

    private

    def minutes(t) = (t.hour * 60 + t.min) - @from * 60.0
    def pct(m) = (m / total_min * 100).round(3)
  end
end
