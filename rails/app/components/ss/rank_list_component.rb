module Ss
  # Lista ranqueada com barra (v0.12, par do SsRankList): posição, nome, valor e fatia de cada
  # item, com a barra proporcional ao maior (o 1º cheio) e uma linha menor opcional (custo, detalhe).
  # O 1º lugar ganha a posição cheia na cor. Serve a "consumo por aparelho", "mais vendidos",
  # "categorias que mais gastam". Vai dentro de um card (com o Ss::CardHeaderComponent em cima).
  #
  #   render Ss::RankListComponent.new(tone: :warn, label: "Consumo por aparelho", items: [
  #     { label: "Ar-condicionado", value: "163,6 kWh", amount: 163.6, share: "41%", caption: "R$ 155,44", url: aparelho_path(a) },
  #     { label: "Chuveiro", value: "128 kWh", amount: 128, share: "32%" }])
  #
  # amount: número da barra (sem ele, sem barra); share: texto da fatia ao lado do valor ("41%").
  # numbered: false tira a posição. tone: :accent (padrão), :success, :warn, :danger, :info, :heat ou uma
  # cor CSS simples. label: nome da lista no leitor de tela (padrão rank_list.label "Ranking").
  class RankListComponent < BaseComponent
    def initialize(items:, tone: nil, numbered: true, label: nil, **rest)
      super(**rest)
      @items = Array(items).map { |i| i.to_h.transform_keys(&:to_sym) }
      @tone, @numbered = tone, numbered
      @label = label
    end

    def label = @label || ss_t("rank_list.label", default: "Ranking")

    def call
      top = @items.filter_map { |i| i[:amount]&.to_f }.max.to_f
      tone = Ss::CardHeaderComponent.tone_css(@tone)
      tag.ol(**root_attrs(class: classes("ss-rank", ("is-plain" unless @numbered)), "aria-label": label,
                          style: [("--tone: #{tone}" if tone), @attrs[:style]].compact.join("; ").presence)) do
        safe_join(@items.each_with_index.map { |it, i| item(it, i, top) })
      end
    end

    private

    def item(it, i, top)
      w = it[:amount] && top.positive? ? [(it[:amount].to_f / top * 100).round(1), 2].max : nil
      tag.li(class: "ss-rank-item", style: "--i: #{[i, 10].min}#{"; --w: #{w}%" if w}") do
        safe_join([
          (tag.span(i + 1, class: "ss-rank-n num", "aria-hidden": "true") if @numbered),
          tag.div(class: "ss-rank-body") do
            safe_join([
              tag.p(class: "ss-rank-top") do
                safe_join([
                  it[:url] ? link_to(it[:label], it[:url], class: "ss-rank-label ss-rank-link") : tag.span(it[:label], class: "ss-rank-label"),
                  tag.span(class: "ss-rank-value num") { safe_join([tag.b(it[:value]), (tag.small(" · #{it[:share]}") if it[:share].present?)].compact) }
                ])
              end,
              (tag.span(tag.i, class: "ss-rank-bar", "aria-hidden": "true") if w),
              (tag.small(it[:caption], class: "ss-rank-caption num") if it[:caption].present?)
            ].compact)
          end
        ].compact)
      end
    end
  end
end
