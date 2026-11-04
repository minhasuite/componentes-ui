module Ss
  # Moldura do app: menu lateral recolhível (grupos, ícone, badge), barra de cima com
  # busca (abre a <dialog class="ss-command"> da página, se houver; Ctrl+K também),
  # troca de empresa e o slot do usuário. No celular o menu vira gaveta.
  #
  #   render Ss::AppShellComponent.new(brand: "Minhas Vendas",
  #       nav: [{ title: "Vendas", items: [{ label: "Pedidos", href: pedidos_path, icon: svg, badge: 3, current: true }] }],
  #       tenants: [{ name: "Loja Centro", href: "/t/1", current: true }, { name: "Loja Sul", href: "/t/2" }]) do |s|
  #     s.with_user { ss_avatar(current_user.name) }
  #     s.with_top { link_to "Novo pedido", new_pedido_path, class: "ss-btn ss-btn-primary ss-btn-sm" }
  #     yield
  #   end
  #
  # icon: SVG já seguro (html_safe). Item sem title = itens soltos, sem grupo.
  # Estado recolhido fica no localStorage ("ss-shell-collapsed").
  class AppShellComponent < BaseComponent
    renders_one :logo
    renders_one :user
    renders_one :top
    renders_one :side_footer

    attr_reader :nav, :tenants

    def initialize(brand: nil, nav: [], tenants: [], tenant_label: "Empresa", search: true,
                   search_label: "Buscar…", side_label: "Menu principal", **opts)
      super(**opts)
      @brand = brand
      @nav = nav
      @tenants = tenants
      @tenant_label = tenant_label
      @search = search
      @search_label = search_label
      @side_label = side_label
    end

    def current_tenant = @tenants.find { _1[:current] } || @tenants.first

    def icon(svg)
      svg if svg.respond_to?(:html_safe?) && svg.html_safe?
    end

    def group_open?(group) = group.fetch(:open, true) || group[:items].any? { _1[:current] }
  end
end
