module Ss
  # Quadro de cotações (compra/venda) com ícone, linha destacada e variação pelo sentido.
  # Preço que muda (morph do Turbo, stream ou JS) rola como caça-níquel (ss-count-up no modo vigia).
  #   render Ss::PriceBoardComponent.new(caption: "Metais", head: %w[Metal Compra Venda],
  #     rows: [{ name: "Ouro", icon: svg_ou_iniciais, buy: "R$ 48,96", sell: "R$ 44,70", delta: "+1,2%", good: true, highlight: true }])
  class PriceBoardComponent < BaseComponent
    def initialize(rows:, caption:, head: nil, show_caption: false, **opts)
      super(**opts)
      @rows = rows
      @caption = caption
      @head = head || [ss_t("price_board.item", default: "Item"), ss_t("price_board.buy", default: "Compra"), ss_t("price_board.sell", default: "Venda")]
      @show_caption = show_caption
    end

    def call
      tag.div(**root_attrs(class: classes("ss-card", "ss-prices"), data: { controller: ["ss-count-up", @attrs.to_h.dig(:data, :controller)].compact.join(" "), ss_count_up_watch_value: "td.num" })) do
        tag.table(class: "ss-table") do
          safe_join([
            tag.caption(@caption, class: @show_caption ? "ss-dt-caption" : "ss-sr"),
            tag.thead(tag.tr(safe_join([tag.th(@head[0], scope: "col"), tag.th(@head[1], scope: "col", class: "r"), tag.th(@head[2], scope: "col", class: "r"),
                                        (tag.th(tag.span(ss_t("price_board.delta", default: "Variação"), class: "ss-sr"), scope: "col", class: "r") if @rows.any? { _1[:delta] })].compact))),
            tag.tbody(safe_join(@rows.map { row(_1) }))
          ])
        end
      end
    end

    private

    def row(r)
      tone = r[:good].nil? ? nil : (r[:good] ? "is-good" : "is-bad")
      tag.tr(class: ("is-highlight" if r[:highlight]), "aria-current": (r[:highlight] ? "true" : nil)) do
        safe_join([
          tag.th(scope: "row") { tag.span(class: "ss-prices-name") { safe_join([tag.span(r[:icon] || r[:name].to_s[0], class: "ss-prices-icon", "aria-hidden": true), r[:name]]) } },
          tag.td(r[:buy], class: "r num"),
          tag.td(r[:sell], class: "r num"),
          (tag.td(r[:delta] ? tag.span(r[:delta], class: ["ss-delta", tone].compact.join(" ")) : "", class: "r") if @rows.any? { _1[:delta] })
        ].compact)
      end
    end
  end
end
