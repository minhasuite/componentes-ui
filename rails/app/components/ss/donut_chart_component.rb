module Ss
  # Rosca em SVG: fatias com a cor das séries (--series-1..6), total no centro e
  # legenda clicável que destaca a fatia (controller ss-donut). exploded: true dá
  # espessuras diferentes (a maior fatia mais grossa), como um gráfico "explodido".
  #
  #   render Ss::DonutChartComponent.new(title: "Para onde foi", center: "R$ 980,00", center_label: "novembro",
  #     slices: [{ label: "Saques", value: 420, text: "R$ 420,00" }, …], exploded: true)
  #
  # v1.14.7: fatias todas zero são o vazio (o .ss-chart-empty com empty:, ou "Sem dados no período");
  # treat_zero_as_empty: false deixa o anel vazio, como antes.
  class DonutChartComponent < BaseComponent
    SIZE = 220
    INNER = 58.0
    WIDTHS = [34, 27, 22, 19, 17, 16].freeze

    attr_reader :title, :center, :center_label

    def initialize(slices:, title:, center: nil, center_label: nil, exploded: false, empty: nil, treat_zero_as_empty: true,
                   **opts)
      super(**opts)
      @any = slices.any?
      @empty = empty
      @treat_zero_as_empty = treat_zero_as_empty
      @slices = slices.reject { _1[:value].to_f <= 0 }
      @title = title
      @center = center
      @center_label = center_label
      @exploded = exploded
    end

    def total = @slices.sum { _1[:value].to_f }

    # v1.14.7: havia fatias, mas nenhuma com valor.
    def zero? = @treat_zero_as_empty && @any && @slices.empty?
    def empty_text = @empty || ss_t("chart.empty", default: "Sem dados no período")

    # Fatias com início e tamanho em % (somam 100), cor, raio e espessura.
    def segments
      t = total
      return [] if t <= 0

      ranks = @slices.each_with_index.sort_by { |s, _| -s[:value].to_f }.map(&:last)
      start = 0.0
      @slices.each_with_index.map do |s, i|
        pct = s[:value].to_f / t * 100
        w = @exploded ? WIDTHS[[ranks.index(i), WIDTHS.size - 1].min] : 26
        seg = { label: s[:label], text: s[:text] || pct_text(pct), pct: pct, start: start,
                color: s[:color] || "var(--series-#{i % 6 + 1})", width: w, r: INNER + w / 2.0, index: i }
        start += pct
        seg
      end
    end

    def dash(seg)
      gap = @slices.size > 1 ? 0.7 : 0
      len = [seg[:pct] - gap, 0.1].max
      "#{len.round(3)} #{(100 - len).round(3)}"
    end

    def pct_text(pct) = "#{ss_number(pct, precision: pct < 10 && pct.round(1) % 1 != 0 ? 1 : 0)}%"
  end
end
