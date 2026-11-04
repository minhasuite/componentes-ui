module Ss
  # Pontos/fidelidade: pontos grandes, nível em selo, barra até o próximo nível e a
  # lista "gasto → +pontos". Ao aparecer, os pontos contam e a barra enche com mola.
  #   render Ss::LevelCardComponent.new(points: 4860, level: 3, next_at: 6000, next_label: "nível 4",
  #     items: [{ label: "Uber", spent: "R$ 8,60", points: 24 }])
  class LevelCardComponent < BaseComponent
    include InView
    def initialize(points:, level:, next_at: nil, next_label: nil, items: [], points_label: nil, level_label: nil, **opts)
      super(**opts)
      @points = points
      @level = level
      @next_at = next_at
      @next_label = next_label
      @items = items
      @points_label = points_label || ss_t("level_card.points", default: "pontos")
      @level_label = level_label || ss_t("level_card.level", default: "nível")
    end

    def call
      tag.article(**root_attrs(class: classes("ss-card", "ss-level"), data: in_view_data)) do
        safe_join([head, (bar if @next_at), (list if @items.any?)].compact)
      end
    end

    private

    def n(v) = v.is_a?(Numeric) ? ss_number(v) : v.to_s

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
          tag.div(class: "ss-progress", role: "progressbar", "aria-valuenow": @points, "aria-valuemin": 0, "aria-valuemax": @next_at, "aria-label": ss_t("level_card.to_next", default: "Até o próximo nível")) { tag.div(class: "ss-progress-bar", style: "width:#{(v * 100).round(1)}%") },
          tag.small { remaining }
        ])
      end
    end

    # "Faltam <b>1.140</b> para o nível 4" com o número em negrito, no idioma da página.
    def remaining
      target = @next_label || ss_t("level_card.next_level", default: "próximo nível")
      before, after = ss_t("level_card.remaining", default: "Faltam %{n} para o %{target}", n: "\u0000", target:).split("\u0000", 2)
      safe_join([before, tag.b(n([@next_at - @points, 0].max), class: "num"), after])
    end

    def list
      tag.table(class: "ss-level-list") do
        safe_join([
          tag.caption(ss_t("level_card.caption", default: "Como você ganhou"), class: "ss-sr"),
          tag.thead(tag.tr(safe_join([tag.th(ss_t("level_card.transaction", default: "Transação"), scope: "col"), tag.th(ss_t("level_card.spent", default: "Gasto"), scope: "col", class: "r"), tag.th(ss_t("level_card.earned", default: "Ganhou"), scope: "col", class: "r")]))),
          tag.tbody(safe_join(@items.map { |i| tag.tr(safe_join([tag.th(i[:label], scope: "row"), tag.td(i[:spent], class: "r num"), tag.td("+#{n(i[:points])}", class: "r num ss-level-plus")])) }))
        ])
      end
    end
  end
end
