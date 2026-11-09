module Ss
  # Conteúdo + coluna lateral (v0.13, par do SsAsideLayout): no computador (≥ 1024 px) o
  # principal ocupa 2/3 e a coluna da direita (mín. 18rem) gruda no topo ao rolar; abaixo disso,
  # a coluna desce para baixo do principal. Resumo de pedido, painel com a lateral, detalhe.
  #
  #   render Ss::AsideLayoutComponent.new(label: "Resumo") do |l|
  #     l.with_main { … }
  #     l.with_aside { … }
  #   end
  #
  # label: o nome da coluna lateral para o leitor de tela (padrão "Coluna lateral").
  class AsideLayoutComponent < BaseComponent
    renders_one :main
    renders_one :aside

    def initialize(label: nil, **rest)
      super(**rest)
      @label = label || ss_t("aside_layout.label", default: "Coluna lateral")
    end

    def call
      tag.div(**root_attrs(class: classes("ss-aside-layout"))) do
        safe_join([tag.div(main, class: "ss-aside-layout-main"),
                   (tag.aside(aside, class: "ss-aside-layout-side", "aria-label": @label) if aside?)].compact)
      end
    end
  end
end
