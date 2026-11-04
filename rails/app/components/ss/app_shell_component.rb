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
  #
  # v0.10: search_action: "id-do-dialog" faz a busca (botão e Ctrl+K) abrir aquele
  # <dialog> (ex. o Ss::CommandPaletteComponent); sem ele, abre o 1º dialog.ss-command.
  # Antes de abrir, dispara "ss-shell:search" (cancelável, detail: { action }), para o
  # app tratar do seu jeito. Os textos (menu, recolher, buscar…) vêm do I18n
  # (componentes_ui.app_shell.*); os parâmetros continuam valendo por cima.
  class AppShellComponent < BaseComponent
    renders_one :logo
    renders_one :user
    renders_one :top
    renders_one :side_footer

    attr_reader :nav, :tenants

    def initialize(brand: nil, nav: [], tenants: [], tenant_label: nil, search: true,
                   search_label: nil, side_label: nil, search_action: nil, **opts)
      super(**opts)
      @brand = brand
      @nav = nav
      @tenants = tenants
      @tenant_label = tenant_label
      @search = search || search_action.present?
      @search_label = search_label
      @side_label = side_label
      @search_action = search_action
    end

    # Textos: o parâmetro do app ou o do idioma (pt-BR no default:).
    def tenant_label = @tenant_label || ss_t("app_shell.tenant", default: "Empresa")
    def search_label = @search_label || ss_t("app_shell.search", default: "Buscar…")
    def side_label = @side_label || ss_t("app_shell.menu", default: "Menu principal")
    def collapse_label = ss_t("app_shell.collapse", default: "Recolher menu")
    def expand_label = ss_t("app_shell.expand", default: "Expandir menu")
    def open_label = ss_t("app_shell.open", default: "Abrir menu")
    def badge_label(n) = ss_t("app_shell.badge", count: n, default: "%{count} novos")

    def shell_data
      { controller: "ss-shell", ss_shell_search_action_value: @search_action, ss_shell_collapse_label_value: collapse_label,
        ss_shell_expand_label_value: expand_label,
        action: "keydown.esc@window->ss-shell#close keydown.ctrl+k@window->ss-shell#search:prevent keydown.meta+k@window->ss-shell#search:prevent" }.compact
    end

    def current_tenant = @tenants.find { _1[:current] } || @tenants.first

    def icon(svg)
      svg if svg.respond_to?(:html_safe?) && svg.html_safe?
    end

    def group_open?(group) = group.fetch(:open, true) || group[:items].any? { _1[:current] }
  end
end
