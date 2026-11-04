module Ss
  # Cabeçalho + corpo de uma tela: migalhas, voltar, título com selo, subtítulo, ações, abas e filtros.
  #   render Ss::PageComponent.new(title: "Pedidos", subtitle: "Abril", crumbs: [["Início", "/"], ["Pedidos"]]) do |p|
  #     p.with_actions { link_to "Novo", new_pedido_path, class: "ss-btn ss-btn-primary" }
  #     p.with_tabs { render Ss::TabsComponent.new(...) }
  #     p.with_filters { form ... }
  #     ...corpo...
  #   end
  #
  # v0.10: back: (url) põe o link "Voltar" antes do título (back_label: troca o texto;
  # o padrão vem do I18n, componentes_ui.page.back) e with_badge põe um selo ao lado do título:
  #   render Ss::PageComponent.new(title: "Sala", back: comodos_path) { |p| p.with_badge { tag.span("Online", class: "ss-badge ss-badge-accent") } }
  class PageComponent < BaseComponent
    BACK = %(<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M19 12H5m6-6-6 6 6 6"/></svg>).freeze

    renders_one :actions
    renders_one :tabs
    renders_one :filters
    renders_one :badge

    def initialize(title:, subtitle: nil, crumbs: nil, back: nil, back_label: nil, **opts)
      super(**opts)
      @title = title
      @subtitle = subtitle
      @crumbs = crumbs
      @back = back
      @back_label = back_label
    end

    def back_label = @back_label || ss_t("page.back", default: "Voltar")
  end
end
