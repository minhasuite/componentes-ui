module Ss
  # Cabeçalho + corpo de uma tela: migalhas, título, subtítulo, ações, abas e filtros.
  #   render Ss::PageComponent.new(title: "Pedidos", subtitle: "Abril", crumbs: [["Início", "/"], ["Pedidos"]]) do |p|
  #     p.with_actions { link_to "Novo", new_pedido_path, class: "ss-btn ss-btn-primary" }
  #     p.with_tabs { render Ss::TabsComponent.new(...) }
  #     p.with_filters { form ... }
  #     ...corpo...
  #   end
  class PageComponent < BaseComponent
    renders_one :actions
    renders_one :tabs
    renders_one :filters

    def initialize(title:, subtitle: nil, crumbs: nil, **opts)
      super(**opts)
      @title = title
      @subtitle = subtitle
      @crumbs = crumbs
    end
  end
end
