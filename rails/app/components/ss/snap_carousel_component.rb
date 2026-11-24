module Ss
  # Carrossel que para em cada item (v1.9, par do SsSnapCarousel): o do meio maior, os vizinhos cortados nas bordas
  # e encolhidos (scroll-snap do navegador). Indicador de bolinhas (a ativa vira pílula) ou "2/5", e as setas de
  # anterior/próximo para quem usa mouse ou teclado (o celular arrasta).
  #
  #   render(Ss::SnapCarouselComponent.new(label: "Ofertas da semana", height: 220)) do |c|
  #     ofertas.each { |o| c.with_slide { render Ss::ProductCardComponent.new(...) } }
  #   end
  #
  # peek: fração da largura que cada item ocupa (0,78, como o viewportFraction). indicator: :dots | :counter | :none.
  # initial: índice do item que abre no meio. Muda o item: evento "ss-carousel:change" (detail: { index }).
  # Teclado: com o foco na faixa, ← e → andam um item. Leitor de tela: cada item é "Item 2 de 5".
  # Reduzir movimento: sem encolher os vizinhos e sem rolagem animada.
  class SnapCarouselComponent < BaseComponent
    INDICATORS = %i[dots counter none].freeze
    renders_many :slides

    def initialize(label:, height: 220, peek: 0.78, indicator: :dots, initial: 0, **rest)
      super(**rest)
      @label, @height, @initial = label, height, initial.to_i
      @peek = peek.to_f.clamp(0.4, 1.0)
      @indicator = INDICATORS.include?(indicator&.to_sym) ? indicator.to_sym : :dots
    end

    def render? = slides?

    def call
      n = slides.size
      start = @initial.clamp(0, n - 1)
      height = @height.is_a?(Numeric) ? "#{@height}px" : @height.to_s
      style = "--ss-carousel-h:#{ERB::Util.h(height)};--ss-carousel-peek:#{(@peek * 100).round(2)}%"
      tag.section(**root_attrs(class: classes("ss-carousel"), style:, "aria-roledescription": ss_t("carousel.roledescription", default: "carrossel"),
                               "aria-label": @label, data: { controller: "ss-carousel", ss_carousel_index_value: start,
                                                             ss_carousel_of_value: ss_t("carousel.of", default: "%{n} de %{total}") })) do
        safe_join([
          tag.div(class: "ss-carousel-track", tabindex: "0", data: { ss_carousel_target: "track", action: "scroll->ss-carousel#scrolled keydown->ss-carousel#key" }) do
            safe_join(slides.each_with_index.map do |s, i|
              tag.div(s.to_s, class: "ss-carousel-slide", role: "group", "aria-roledescription": ss_t("carousel.slide", default: "item"),
                              "aria-label": ss_t("carousel.item_of", default: "Item %{n} de %{total}", n: i + 1, total: n),
                              data: { ss_carousel_target: "slide", current: (i == start ? "" : nil) }.compact)
            end)
          end,
          (foot(n, start) unless @indicator == :none)
        ].compact)
      end
    end

    private

    def arrow(dir)
      label = dir == :prev ? ss_t("carousel.prev", default: "Anterior") : ss_t("carousel.next", default: "Próximo")
      tag.button(ss_icon(dir == :prev ? "chevron-left" : "chevron-right", size: nil), type: "button", class: "ss-icon-btn ss-carousel-arrow",
                 "aria-label": label, title: label, data: { action: "ss-carousel##{dir}", ss_carousel_target: dir })
    end

    def foot(n, start)
      mid = if @indicator == :counter
        tag.span("#{start + 1}/#{n}", class: "ss-carousel-count num", "aria-live": "polite", data: { ss_carousel_target: "count" })
      else
        tag.span(safe_join(Array.new(n) { |i| tag.i(data: { current: (i == start ? "" : nil) }.compact) }), class: "ss-carousel-dots", "aria-hidden": "true",
                 data: { ss_carousel_target: "dots" })
      end
      tag.div(safe_join([arrow(:prev), mid, arrow(:next)]), class: "ss-carousel-foot")
    end
  end
end
