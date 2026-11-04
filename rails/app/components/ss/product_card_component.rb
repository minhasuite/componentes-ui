module Ss
  # Card de produto com a imagem vazando acima do card, nome, texto, preço (ss_amount)
  # e botão de ação. Use dentro de .ss-product-grid (grade responsiva).
  #   render Ss::ProductCardComponent.new(name: "Costela-de-adão", text: "Meia-sombra", price: "R$ 89,90",
  #     image_url: url, url: produto_path(p), action: { label: "Adicionar", url: carrinho_path(p), method: :post })
  #   with_image: SVG/imagem própria no lugar de image_url.
  class ProductCardComponent < BaseComponent
    include InView
    renders_one :image

    def initialize(name:, price: nil, text: nil, image_url: nil, url: nil, action: nil, badge: nil, vt: nil, **opts)
      super(**opts)
      @name = name
      @price = price
      @text = text
      @image_url = image_url
      @url = url
      @action = action
      @badge = badge
      @vt = vt
    end

    def before_render
      content # roda o bloco (registra with_image)
    end

    def call
      tag.article(**root_attrs(class: classes("ss-product"), data: in_view_data)) do
        safe_join([
          tag.div(class: "ss-product-img", style: (@vt ? "view-transition-name:#{@vt}-img" : nil)) { image? ? image.to_s : (@image_url ? image_tag(@image_url, alt: "", loading: "lazy") : "") },
          (tag.span(@badge, class: "ss-badge ss-badge-accent ss-product-badge") if @badge),
          tag.h3(@url ? link_to(@name, @url, class: "ss-product-link") : @name, style: (@vt ? "view-transition-name:#{@vt}-title" : nil)),
          (tag.p(@text) if @text),
          tag.div(class: "ss-product-foot") { safe_join([(ss_amount(@price) if @price), action].compact) }
        ].compact)
      end
    end

    private

    def action
      return nil unless @action

      plus = %(<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 5v14M5 12h14" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"/></svg>).html_safe
      if @action[:method] && @action[:method].to_s != "get"
        button_to(@action[:url], method: @action[:method], class: "ss-product-btn", "aria-label": "#{@action[:label]}: #{@name}") { plus }
      else
        link_to(plus, @action[:url], class: "ss-product-btn", "aria-label": "#{@action[:label]}: #{@name}")
      end
    end
  end
end
