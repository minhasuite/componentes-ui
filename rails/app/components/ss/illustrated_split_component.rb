module Ss
  # Tela de apresentação partida (v1.10, par do SsIllustratedSplit): a ilustração em cima, no fundo suave da marca,
  # e um painel embaixo que sobe numa curva, com os pontinhos de página, título, texto, a ação e a secundária.
  #
  #   render(Ss::IllustratedSplitComponent.new(title: "Seu dinheiro num lugar só", text: "Contas, cartões e metas.",
  #            action_label: "Começar", action_href: cadastro_path, secondary_label: "Já tenho conta",
  #            secondary_href: login_path, page: 0, pages: 3)) { |s| s.with_art { image_tag "intro.svg", alt: "" } }
  #   render Ss::IllustratedSplitComponent.new(title: "Tudo em dia", illustration: :all_done, action_label: "Continuar", action_href: "#")
  #
  # with_art: a ilustração do app; ou illustration: (a do Ss::IllustrationArtComponent). page: (0…) e pages:
  # mostram os pontinhos ("Página 1 de 3" no leitor de tela). As ações são links (action_href:/secondary_href:);
  # sem href, <button type=button> com action_data:/secondary_data:. Ocupa a altura do pai (min-height: 100%).
  class IllustratedSplitComponent < BaseComponent
    renders_one :art

    def initialize(title:, text: nil, illustration: nil, action_label: nil, action_href: nil, action_data: {},
                   secondary_label: nil, secondary_href: nil, secondary_data: {}, page: nil, pages: nil, heading: :h1, **rest)
      super(**rest)
      @title, @text, @illustration, @heading = title, text, illustration, heading
      @action = [action_label, action_href, action_data]
      @secondary = [secondary_label, secondary_href, secondary_data]
      @page, @pages = page&.to_i, pages&.to_i
    end

    def dots
      return nil unless @page && @pages&.positive?

      label = ss_t("illustrated_split.page", page: @page + 1, pages: @pages, default: "Página %{page} de %{pages}")
      tag.div(class: "ss-isplit-dots", role: "img", "aria-label": label) do
        safe_join((0...@pages).map { |i| tag.span(class: ("is-on" if i == @page), "aria-current": (i == @page ? "step" : nil)) })
      end
    end

    def button((label, href, data), cls)
      return nil unless label
      return link_to(label, href, class: cls) if href

      tag.button(label, type: :button, class: cls, data:)
    end

    def call
      artwork = art? ? art : (render(Ss::IllustrationArtComponent.new(@illustration, size: 200)) if @illustration)
      tag.section(**root_attrs(class: classes("ss-isplit"))) do
        safe_join([
          tag.div(artwork, class: "ss-isplit-art"),
          tag.div(class: "ss-isplit-panel") do
            safe_join([
              dots,
              content_tag(@heading, @title, class: "ss-isplit-title"),
              (tag.p(@text, class: "ss-isplit-text") if @text),
              (tag.div(safe_join([button(@action, "ss-btn ss-btn-primary ss-isplit-cta"), button(@secondary, "ss-btn ss-btn-ghost ss-isplit-sec")].compact), class: "ss-isplit-actions") if @action[0] || @secondary[0])
            ].compact)
          end
        ])
      end
    end
  end
end
