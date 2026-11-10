module Ss
  # Barras divergentes (v0.16, par do SsDivergingBars): o que subiu vai para a direita, o que caiu
  # para a esquerda de um eixo no meio, proporcional ao maior |valor|. Nome em cima da barra, valor
  # com sinal em DM Mono e detalhe opcional embaixo. Subir é ruim (vermelho) por padrão (inflação,
  # gasto); up_is_good: true inverte. As barras crescem do eixo em cascata (mola).
  #
  #   render Ss::DivergingBarsComponent.new(unit: "p.p.", items: [
  #     { label: "Café torrado", value: 1.8, detail: "+32% · 9% da cesta" },
  #     { label: "Tomate", value: -0.6 }])
  #
  # format: ->(v) { … } troca o texto do valor (padrão: sinal, 1 casa e unit:).
  class DivergingBarsComponent < BaseComponent
    include InView

    def initialize(items:, format: nil, unit: nil, up_is_good: false, label: nil, **rest)
      super(**rest)
      @items = Array(items).map { |i| i.to_h.transform_keys(&:to_sym) }
      @format, @unit, @up_is_good, @label = format, unit, up_is_good, label
    end

    def render? = @items.any?

    def text(v)
      return @format.call(v) if @format
      n = v.to_f
      s = n.abs < 0.05 ? "0" : "#{n.positive? ? "+" : "−"}#{ss_number(n.abs, precision: 1)}"
      [s, @unit].compact.join(" ")
    end

    def call
      top = [@items.map { _1[:value].to_f.abs }.max, 1e-9].max
      tag.ul(**root_attrs(class: classes("ss-diverging"), "aria-label": @label, data: in_view_data)) do
        safe_join(@items.each_with_index.map do |it, i|
          v = it[:value].to_f
          tone = v.zero? ? "flat" : ((v.positive? == @up_is_good) ? "good" : "bad")
          f = (v / top).clamp(-1, 1).round(3)
          tag.li(style: "--i: #{[i, 10].min}; --f: #{f.abs}", data: { tone:, side: (v.negative? ? "down" : "up") }) do
            safe_join([
              tag.div(safe_join([tag.b(it[:label]), tag.span(text(it[:value]), class: "num")]), class: "ss-diverging-head"),
              (tag.small(it[:detail]) if it[:detail].present?),
              tag.div(tag.i, class: "ss-diverging-bar", "aria-hidden": "true")
            ].compact)
          end
        end)
      end
    end
  end
end
