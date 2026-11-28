module Ss
  # Este período × o anterior no mesmo gráfico (v1.14.0, par do SsPeriodCompare): o total do período em DM Mono
  # (rola no odômetro ao trocar), a diferença em destaque (.ss-delta, verde ou vermelha pelo sentido:
  # higher_is_better: false para gasto) e o gráfico de linha com o anterior como linha fantasma tracejada, que se
  # arrasta com o dedo (scrub). A troca de período (periods:, links do Ss::SegmentedComponent) é animada: ao chegar
  # a página ou o turbo-frame novo, a linha desliza do desenho antigo para o novo e o total rola.
  #
  #   render Ss::PeriodCompareComponent.new(title: "Gastos", labels: dias, current: este_mes, previous: mes_passado,
  #     money: true, higher_is_better: false, frame: "comparar",
  #     periods: [{ label: "Semana", href: "?p=semana" }, { label: "Mês", href: "?p=mes", current: true }])
  #
  # total:/previous_total: (padrão: a soma de cada série); format: lambda do valor (padrão ss_money com money:,
  # senão ss_number). current_label:/previous_label: os nomes na legenda e no balão. frame: envolve tudo num
  # <turbo-frame> com esse id e os links do período miram nele. delta: troca o texto da diferença ("+12%").
  # v1.14.7: os dois períodos só com zero mostram o vazio no lugar do gráfico (empty:, ou "Sem dados no período");
  # treat_zero_as_empty: false desenha as linhas no chão.
  class PeriodCompareComponent < BaseComponent
    def initialize(title:, labels:, current:, previous:, total: nil, previous_total: nil, money: false, format: nil,
                   higher_is_better: true, periods: [], frame: nil, current_label: nil, previous_label: nil, delta: nil,
                   height: 200, width: 560, empty: nil, treat_zero_as_empty: true, **rest)
      super(**rest)
      @empty, @treat_zero_as_empty = empty, treat_zero_as_empty
      @title, @labels, @current, @previous = title, labels, current.map { _1&.to_f }, previous.map { _1&.to_f }
      @total = (total || @current.compact.sum).to_f
      @previous_total = (previous_total || @previous.compact.sum).to_f
      @money, @format, @higher, @periods, @frame = money, format, higher_is_better, periods.map(&:to_h), frame
      @current_label, @previous_label, @delta, @height, @width = current_label, previous_label, delta, height, width
    end

    def uid = @uid ||= (@attrs[:id] || "ss-period-#{object_id}")

    def fmt(v)
      return @format.call(v) if @format

      @money ? ss_money(v) : ss_number(v, precision: v.to_f % 1 == 0 ? 0 : 2)
    end

    def current_label = @current_label || ss_t("interface.period_current", default: "Este período")
    def previous_label = @previous_label || ss_t("interface.period_previous", default: "Período anterior")

    # Variação em % (nil sem o anterior).
    def change = @previous_total.zero? ? nil : (@total - @previous_total) / @previous_total.abs * 100

    def delta_text
      return @delta if @delta
      return nil unless (c = change)

      places = c.abs < 10 ? 1 : 0
      r = c.round(places)
      "#{"+" if r.positive?}#{ss_number(r, precision: (r % 1).zero? ? 0 : places)}%"
    end

    def good? = change.nil? || change.zero? ? nil : (change.positive? == @higher)

    def call
      body = tag.section(**root_attrs(id: uid, class: classes("ss-card", "ss-card-pad", "ss-period"),
                                      data: { controller: "ss-period-compare" }, "aria-labelledby": "#{uid}-t")) do
        safe_join([head, chart])
      end
      @frame ? tag.turbo_frame(body, id: @frame) : body
    end

    private

    def head
      tag.header(class: "ss-period-head") do
        safe_join([
          tag.div(class: "ss-period-titles") do
            safe_join([
              tag.h3(@title, id: "#{uid}-t", class: "ss-period-title"),
              tag.div(class: "ss-period-figures") do
                safe_join([
                  render(Ss::OdometerComponent.new(text: fmt(@total), size: nil, cents: @money, css: "ss-period-total", data: { ss_period_compare_target: "total" })),
                  delta_tag
                ].compact)
              end,
              tag.p(ss_t("interface.period_summary", default: "%{current} neste período, %{previous} no anterior",
                         current: fmt(@total), previous: fmt(@previous_total)), class: "ss-period-sub")
            ])
          end,
          (if @periods.any?
             render(Ss::SegmentedComponent.new(label: ss_t("interface.period_choose", default: "Período"), css: "ss-period-seg",
                                               items: @periods.map { |p| p.merge(data: { turbo_frame: @frame }.compact.merge(p[:data].to_h)) }))
           end)
        ].compact)
      end
    end

    def delta_tag
      return nil unless (d = delta_text)

      up = change.to_f >= 0
      tone = good?.nil? ? nil : (good? ? "is-good" : "is-bad")
      sense = good?.nil? ? "" : (good? ? ss_t("kpi_strip.good", default: " (bom)") : ss_t("kpi_strip.bad", default: " (ruim)"))
      tag.span(class: ["ss-delta", "ss-period-delta", tone].compact.join(" "),
               "aria-label": "#{d} #{ss_t("interface.period_vs", default: "em relação ao período anterior")}#{sense}") do
        safe_join([(up ? KpiStripComponent::UP : KpiStripComponent::DOWN).html_safe, d, tag.small(ss_t("interface.period_vs", default: "em relação ao período anterior"), "aria-hidden": "true")])
      end
    end

    def chart
      render(Ss::LineChartComponent.new(title: @title, labels: @labels, scrub: true, height: @height, width: @width,
                                        format: ->(v) { fmt(v) }, css: "ss-period-chart", empty: @empty,
                                        treat_zero_as_empty: @treat_zero_as_empty,
                                        series: [{ name: current_label, values: @current, tone: :accent },
                                                 { name: previous_label, values: @previous, tone: :muted, dashed: true }]))
    end
  end
end
