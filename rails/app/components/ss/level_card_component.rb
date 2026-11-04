module Ss
  # Pontos/fidelidade: pontos grandes, nível em selo, barra até o próximo nível e a
  # lista "gasto → +pontos". Ao aparecer, os pontos contam e a barra enche com mola.
  #   render Ss::LevelCardComponent.new(points: 4860, level: 3, next_at: 6000, next_label: "nível 4",
  #     items: [{ label: "Uber", spent: "R$ 8,60", points: 24 }])
  class LevelCardComponent < BaseComponent
    include InView
    def initialize(points:, level:, next_at: nil, next_label: nil, items: [], points_label: "pontos", level_label: "nível", **opts)
      super(**opts)
      @points = points
      @level = level
      @next_at = next_at
      @next_label = next_label
      @items = items
      @points_label = points_label
      @level_label = level_label
    end

    def call
      tag.article(**root_attrs(class: classes("ss-card", "ss-level"), data: in_view_data)) do
        safe_join([head, (bar if @next_at), (list if @items.any?)].compact)
      end
    end

    private

    def n(v) = number_with_delimiter(v, delimiter: ".")

    def head
      tag.div(class: "ss-level-head") do
        safe_join([
          tag.div(class: "ss-level-points") { safe_join([tag.b(@points.is_a?(Numeric) ? render(Ss::CountUpComponent.new(value: @points)) : n(@points), class: "num"), tag.span(@points_label)]) },
          tag.span(class: "ss-level-seal", "aria-label": "#{@level_label} #{@level}") { safe_join([tag.small(@level_label), tag.b(@level, class: "num")]) }
        ])
      end
    end

    def bar
      v = (@points.to_f / @next_at).clamp(0, 1)
      tag.div(class: "ss-level-next") do
        safe_join([
          tag.div(class: "ss-progress", role: "progressbar", "aria-valuenow": @points, "aria-valuemin": 0, "aria-valuemax": @next_at, "aria-label": "Até o próximo nível") { tag.div(class: "ss-progress-bar", style: "width:#{(v * 100).round(1)}%") },
          tag.small { safe_join(["Faltam ", tag.b(n([@next_at - @points, 0].max), class: "num"), " para o #{@next_label || "próximo nível"}"]) }
        ])
      end
    end

    def list
      tag.table(class: "ss-level-list") do
        safe_join([
          tag.caption("Como você ganhou", class: "ss-sr"),
          tag.thead(tag.tr(safe_join([tag.th("Transação", scope: "col"), tag.th("Gasto", scope: "col", class: "r"), tag.th("Ganhou", scope: "col", class: "r")]))),
          tag.tbody(safe_join(@items.map { |i| tag.tr(safe_join([tag.th(i[:label], scope: "row"), tag.td(i[:spent], class: "r num"), tag.td("+#{n(i[:points])}", class: "r num ss-level-plus")])) }))
        ])
      end
    end
  end
end
