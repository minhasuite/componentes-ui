module Ss
  # Legenda de gráfico (v0.16, par do SsChartLegend): cor da série + rótulo + valor opcional, em
  # linhas que quebram; rótulo longo termina em "…". line: true troca a bolinha por um traço
  # (série de linha) e dashed: true o deixa tracejado (alvo, média).
  #
  #   render Ss::ChartLegendComponent.new(items: [
  #     { label: "Atacadão", tone: :s1 },
  #     { label: "menor", value: ss_money(2148), tone: :success },
  #     { label: "alvo", value: ss_money(1990), tone: :muted, line: true, dashed: true }])
  #
  # tone: :accent, :success, :warn, :danger, :info, :muted, :s1..:s6 (--series-1..6) ou color: (cor CSS).
  # Sem cor, a série pela posição (--series-1..6).
  class ChartLegendComponent < BaseComponent
    SERIES = (1..6).to_h { [:"s#{_1}", "var(--series-#{_1})"] }.freeze

    def initialize(items:, **rest)
      super(**rest)
      @items = Array(items).map { |i| i.to_h.transform_keys(&:to_sym) }.uniq
    end

    def self.color(it, i)
      tone = it[:color] || it[:tone]
      SERIES[tone.to_s.to_sym] || Ss::CardHeaderComponent.tone_css(tone) || "var(--series-#{i % 6 + 1})"
    end

    def call
      tag.ul(**root_attrs(class: classes("ss-legend"))) do
        safe_join(@items.each_with_index.map do |it, i|
          tag.li(class: [("is-line" if it[:line]), ("is-dashed" if it[:dashed])].compact.join(" ").presence,
                 style: "--c: #{self.class.color(it, i)}") do
            safe_join([tag.i("aria-hidden": "true"), tag.span(it[:label]),
                       (tag.b(it[:value], class: "num") if it[:value].present?)].compact)
          end
        end)
      end
    end
  end
end
