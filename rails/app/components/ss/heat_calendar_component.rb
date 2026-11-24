module Ss
  # Constância estilo contribuições do GitHub (v1.9, par do SsHeatCalendar): uma coluna por semana, de domingo
  # a sábado, em 5 níveis da cor da marca. As últimas weeks semanas até end_date (hoje), ou só o mês month:.
  # Clicar (ou focar) num dia mostra o valor dele embaixo; legenda "menos ▢▢▢▢▢ mais".
  #
  #   render Ss::HeatCalendarComponent.new(values: treinos.group(:dia).count, weeks: 18)
  #   render Ss::HeatCalendarComponent.new(values: gastos_por_dia, month: Date.new(2026, 11), format: :money)
  #
  # values: { Date | "aaaa-mm-dd" => número }. Nível = fração do maior valor em 4 faixas (o mesmo ssHeatLevel do
  # Flutter e do ss_heat). format: :qty (padrão), :integer, :money ou um lambda (valor → texto).
  # Teclado: um só ponto de tab; ← → andam uma semana, ↑ ↓ um dia. legend: false tira a legenda.
  # O ss_heat (helper, só a grade) continua.
  class HeatCalendarComponent < BaseComponent
    attr_reader :values, :first_day, :last_day

    def initialize(values:, weeks: 18, month: nil, end_date: nil, format: :qty, legend: true, label: nil, currency: nil, **rest)
      super(**rest)
      @values = values.to_h.each_with_object({}) { |(k, v), h| h[k.is_a?(Date) ? k : Date.parse(k.to_s)] = v.to_f }
      @month = month&.to_date
      @last_day = @month ? @month.end_of_month : (end_date || Date.current).to_date
      @first_day = @month ? @month.beginning_of_month : @last_day - (weeks.to_i.clamp(1, 60) * 7 - 1)
      @format, @legend, @label, @currency = format, legend, label, currency
    end

    def max = @max ||= values.values.max.to_f

    def self.level(v, max)
      return 0 if v.nil? || v <= 0 || max <= 0

      (v / max * 4).ceil.clamp(1, 4)
    end

    def text(v)
      return ss_t("heat_calendar.nothing", default: "nada") if v.nil?
      return @format.call(v) if @format.respond_to?(:call)

      case @format.to_s
      when "money" then ss_money(v, currency: @currency || ss_currency)
      when "integer" then ss_number(v)
      else ss_qty(v)
      end
    end

    def label = @label || ss_t("heat_calendar.label", default: "Constância")
    def weeks = (((last_day + (6 - last_day.wday)) - (first_day - first_day.wday)).to_i + 1) / 7

    def call
      grid_start = first_day - first_day.wday
      focus_day = values.keys.select { |d| d.between?(first_day, last_day) }.max || last_day
      cells = (0...(weeks * 7)).map do |i|
        d = grid_start + i
        next tag.span(class: "ss-heatcal-pad") unless d.between?(first_day, last_day)

        v = values[d]
        tag.button(type: "button", class: "ss-heatcal-day", tabindex: (d == focus_day ? "0" : "-1"), "aria-pressed": "false",
                   "aria-label": "#{ss_date(d)}: #{text(v)}", title: "#{ss_date(d, :day_month)}: #{text(v)}",
                   data: { level: self.class.level(v, max), date: d.iso8601, ss_heat_calendar_target: "day",
                           action: "click->ss-heat-calendar#pick focus->ss-heat-calendar#pick keydown->ss-heat-calendar#key" })
      end
      tag.figure(**root_attrs(class: classes("ss-heatcal", ("is-month" if @month)), style: "--weeks:#{weeks}", data: { controller: "ss-heat-calendar" })) do
        safe_join([
          tag.figcaption(label, class: "ss-sr"),
          tag.div(safe_join(cells), class: "ss-heatcal-grid", role: "group", "aria-label": label),
          tag.div(class: "ss-heatcal-foot") do
            safe_join([tag.p("", class: "ss-heatcal-out num", "aria-live": "polite", data: { ss_heat_calendar_target: "out" }), (legend if @legend)].compact)
          end
        ])
      end
    end

    private

    def legend
      tag.span(safe_join([tag.span(ss_t("heat_calendar.less", default: "menos")), *(0..4).map { |n| tag.i(data: { level: n }) },
                          tag.span(ss_t("heat_calendar.more", default: "mais"))]), class: "ss-heatcal-legend", "aria-hidden": "true")
    end
  end
end
