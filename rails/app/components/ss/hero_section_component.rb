module Ss
  # Topo de landing: kicker, título com uma palavra destacada (na cor da marca, nunca
  # gradiente no texto), texto, botões e mídia à direita, com brilho atrás.
  #   render Ss::HeroSectionComponent.new(kicker: "Minhas Vendas", title: "Venda mais no balcão e na rua",
  #       highlight: "Venda mais", text: "…", texture: true) do |h|
  #     h.with_actions { link_to "Começar", "/assinar", class: "ss-btn ss-btn-primary" }
  #     h.with_media { image_tag "mockup.png", alt: "" }
  #   end
  class HeroSectionComponent < BaseComponent
    renders_one :actions
    renders_one :media

    def initialize(title:, kicker: nil, highlight: nil, text: nil, texture: false, heading: :h1, **opts)
      super(**opts)
      @title = title
      @kicker = kicker
      @highlight = highlight
      @text = text
      @texture = texture
      @heading = heading
    end

    def title_html
      return @title unless @highlight.present? && @title.include?(@highlight)

      before, after = @title.split(@highlight, 2)
      safe_join([before, tag.em(@highlight, class: "ss-hero-section-hl"), after])
    end
  end
end
