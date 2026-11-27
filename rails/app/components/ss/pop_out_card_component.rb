module Ss
  # Card em que a imagem "vaza" para cima da borda (v1.10, par do SsPopOutCard); embaixo, título, detalhe,
  # preço em DM Mono e o botão redondo de ação (adicionar). O Ss::ProductCardComponent (grade de loja, com selo)
  # continua; este é o do SsPopOutCard, com a mesma API do app.
  #
  #   render Ss::PopOutCardComponent.new(title: "Costela-de-adão", subtitle: "Meia-sombra", price: ss_money(89.9),
  #     image_url: url, url: planta_path(p), add_url: carrinho_path(p))
  #   … { |c| c.with_image { image_tag(...) } }
  #
  # url: o card inteiro vira link (onTap). add_url: o botão de ação (onAdd), com add_method: (:post) e
  # add_params:; add_method: :get vira link. image_height: px (120); pop_out: quanto a imagem passa da borda (44).
  # tone: fundo tonal (:accent | :success | :warn | :danger | :info). action_icon: ("plus"); action_label: o nome
  # lido do botão ("Adicionar: <título>").
  class PopOutCardComponent < BaseComponent
    TONES = %i[accent success warn danger info].freeze
    renders_one :image

    def initialize(title:, subtitle: nil, price: nil, image_url: nil, url: nil, add_url: nil, add_method: :post, add_params: {},
                   image_height: 120, pop_out: 44, tone: nil, action_icon: "plus", action_label: nil, **rest)
      super(**rest)
      @title, @subtitle, @price, @image_url, @url = title, subtitle, price, image_url, url
      @add_url, @add_method, @add_params = add_url, add_method, add_params
      @image_height, @pop_out = image_height.to_i.clamp(40, 400), pop_out.to_i.clamp(0, 200)
      @tone = TONES.include?(tone&.to_sym) ? tone.to_sym : nil
      @action_icon = action_icon
      @action_label = action_label || ss_t("pop_out_card.add", default: "Adicionar")
    end

    def before_render = content

    def call
      tag.article(**root_attrs(class: classes("ss-popout", ("is-link" if @url)), style: "--ih:#{@image_height}px;--po:#{@pop_out}px",
                               data: { tone: @tone }.compact)) do
        safe_join([
          tag.div(class: "ss-popout-img") { image? ? image.to_s : (@image_url ? image_tag(@image_url, alt: "", loading: "lazy") : "") },
          tag.div(class: "ss-popout-body") do
            safe_join([
              tag.h3(@url ? link_to(@title, @url, class: "ss-popout-link") : @title, class: "ss-popout-title"),
              (tag.p(@subtitle, class: "ss-popout-sub") if @subtitle),
              tag.div(class: "ss-popout-foot") { safe_join([(@price ? ss_amount(@price, css: "ss-popout-price") : tag.span), action].compact) }
            ].compact)
          end
        ])
      end
    end

    private

    def action
      return nil unless @add_url

      label = "#{@action_label}: #{@title}"
      ico = ss_icon(@action_icon, size: nil)
      if @add_method.to_s == "get"
        link_to(ico, @add_url, class: "ss-popout-btn", "aria-label": label)
      else
        button_to(@add_url, method: @add_method, params: @add_params, class: "ss-popout-btn", form_class: "ss-popout-form", "aria-label": label) { ico }
      end
    end
  end
end
