module Ss
  # Grade do mês para escolher o dia (v1.10, par do SsMonthGrid): 7 colunas começando no domingo, hoje com anel,
  # o escolhido com o fundo da marca (dá um pulinho com a mola), até 3 pontinhos de marcador embaixo do dia e os
  # dias de fora do mês apagados (fora do foco e do leitor de tela).
  #
  #   render Ss::MonthGridComponent.new(month: @mes, selected: @dia, url: "/agenda?dia=%{date}",
  #     month_url: "/agenda?mes=%{month}", markers: { Date.new(2026, 11, 12) => [:accent, :success] })
  #   render Ss::MonthGridComponent.new(month: Date.current, name: "pedido[entrega]")   # campo de formulário
  #
  # url: o endereço de cada dia com %{date} (aaaa-mm-dd): o dia é link (onSelect). Sem url:, o dia é botão: marca,
  # grava no input escondido name: e dispara ss-month-grid:select { date }. month_url: com %{month} (aaaa-mm),
  # o mês vizinho (onMonthChanged) por PageUp/PageDown ou arrastando para o lado. markers: { Date => [tons] }
  # (:accent, :success, :warn, :danger, :muted). today: (Date.current). turbo_frame: os links trocam só o frame.
  # Teclado: um ponto de Tab (o escolhido, ou hoje); ← → um dia, ↑ ↓ uma semana, Home/End começo/fim da semana.
  class MonthGridComponent < BaseComponent
    TONES = %i[accent success warn danger muted].freeze

    attr_reader :month, :selected, :today

    # Dias que a grade mostra: do domingo antes do dia 1 ao sábado depois do último (5 ou 6 semanas), o ssMonthDays.
    def self.days(month)
      first = month.to_date.beginning_of_month
      last = first.end_of_month
      (first - first.wday..last + (6 - last.wday)).to_a
    end

    def initialize(month:, selected: nil, url: nil, name: nil, month_url: nil, markers: {}, today: nil, turbo_frame: nil, **rest)
      super(**rest)
      @month = month.to_date.beginning_of_month
      @selected = selected&.to_date
      @url, @name, @month_url, @frame = url&.to_s, name, month_url&.to_s, turbo_frame
      @today = (today || Date.current).to_date
      @markers = markers.to_h.each_with_object({}) { |(k, v), h| h[k.to_date] = Array(v).map(&:to_sym).select { |t| TONES.include?(t) }.first(3) }
    end

    def month_title = "#{ss_months[month.month - 1].to_s.capitalize} #{month.year}"
    def href(d) = @url.gsub("%{date}", d.iso8601)
    def month_href(m) = @month_url&.gsub("%{month}", m.strftime("%Y-%m"))

    # O dia que recebe o Tab: o escolhido (se está no mês), hoje (se está), ou o dia 1.
    def focus_day
      [selected, today].find { |d| d && d.month == month.month && d.year == month.year } || month
    end

    def day_label(d)
      parts = [ss_date(d)]
      parts << ss_t("month_grid.today", default: "hoje") if d == today
      n = @markers[d]&.size.to_i
      parts << ss_t("month_grid.markers", default: n == 1 ? "1 marcador" : "%{count} marcadores", count: n) if n.positive?
      parts.join(", ")
    end

    def call
      tag.div(**root_attrs(class: classes("ss-month-grid"), role: "group",
                           "aria-label": ss_t("month_grid.label", default: "Calendário de %{month}", month: month_title),
                           data: { controller: "ss-month-grid", action: "keydown->ss-month-grid#key",
                                   ss_month_grid_prev_value: month_href(month.prev_month), ss_month_grid_next_value: month_href(month.next_month),
                                   ss_month_grid_frame_value: @frame }.compact)) do
        safe_join([
          (tag.input(type: "hidden", name: @name, value: selected&.iso8601, data: { ss_month_grid_target: "input" }) if @name),
          tag.div(class: "ss-month-grid-head", "aria-hidden": "true") { safe_join(initials.map { |w| tag.span(w) }) },
          tag.div(class: "ss-month-grid-days") { safe_join(self.class.days(month).map { |d| cell(d) }) }
        ].compact)
      end
    end

    private

    def initials
      list = ss_t("date.weekdays_narrow", default: nil)
      list.is_a?(Array) && list.size == 7 ? list : ss_weekdays.map { |w| w.to_s[0].to_s.upcase }
    end

    def cell(d)
      dots = tag.span(safe_join(@markers[d].to_a.map { |t| tag.i(data: { tone: t }) }), class: "ss-month-grid-dots", "aria-hidden": "true")
      num = tag.b(d.day, class: "ss-month-grid-n num")
      if d.month != month.month
        return tag.span(safe_join([num, dots]), class: "ss-month-grid-day is-out", "aria-hidden": "true")
      end

      attrs = { class: ["ss-month-grid-day", ("is-today" if d == today)].compact.join(" "), "aria-label": day_label(d),
                tabindex: (d == focus_day ? nil : "-1"),
                data: { date: d.iso8601, ss_month_grid_target: "day", turbo_frame: (@frame if @url) }.compact }
      if @url
        link_to(safe_join([num, dots]), href(d), **attrs, "aria-current": (d == selected ? "date" : nil))
      else
        tag.button(safe_join([num, dots]), type: "button", **attrs, "aria-pressed": (d == selected).to_s,
                   data: attrs[:data].merge(action: "ss-month-grid#choose"))
      end
    end
  end
end
