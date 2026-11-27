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
  #
  # v0.10.1:
  # - collapsed: true começa recolhido (no servidor, sem piscar). A escolha do usuário vale
  #   por cima: o JS grava no localStorage e no cookie "ss_shell_collapsed" (1/0), que o
  #   componente lê no servidor. O estado também fica no <html> (data-ss-shell-collapsed),
  #   que o Turbo (inclusive o morph) não apaga; o CSS olha os dois. Para não piscar o menu
  #   aberto no carregamento, ponha <%= ss_app_shell_head %> no <head> do layout.
  # - with_mark { image_tag "logo.svg" } troca o quadrado de gradiente pela marca do app
  #   (with_logo continua trocando o nome). brand_url: faz da marca um link. No celular a
  #   marca aparece na barra de cima (mobile_brand: false tira).
  # - <main> com tabindex="-1" (pular para o conteúdo); main_class: soma classes;
  #   main_max: "72rem" limita a largura do conteúdo (centralizado).
  # - Item: class: vai no link; { separator: true } (ou divider: true) é uma linha divisória,
  #   no meio dos itens ou entre os grupos. badge: 0 (ou vazio) não aparece.
  #
  # v0.18:
  # - Barra de cima sem nada no computador (search: false, sem top, sem user) não aparece mais
  #   (antes ficava uma faixa vazia); no celular ela segue (menu e marca). with_top_mobile { … } é o
  #   que só aparece na barra do celular (ex. o olho de esconder valores, que no computador mora
  #   no rodapé do menu): não conta para a barra do computador.
  # - v0.20: item externo { label:, href:, external: true } abre em outra aba (target=_blank rel=noopener), com o
  #   ícone de saída ao lado do nome e "(abre em outra aba)" para o leitor de tela.
  # - Grupo com ícone: { title: "Cadastros", icon: ss_icon("folder", size: nil), items: [...] }; o
  #   ícone vai antes do título (com o menu recolhido o grupo segue sendo só a linha divisória).
  # - v0.25: with_bell { render Ss::NotificationBellComponent.new(...) } = o sino de avisos no canto direito da barra
  #   de cima (computador e celular), entre o top e o user; tira "Avisos" do menu lateral.
  # - v1.6: with_help { render Ss::HelpMenuComponent.new(learn_href:, news_href:, unseen_news:) } = o "?" da ajuda
  #   (Aprenda e Novidades) na barra de cima (computador e celular), entre o top e o sino.
  # - v1.13: with_suite { render Ss::SuiteSwitcherComponent.new(products: …) } = os apps da suíte (grade), na barra de
  #   cima ao lado do avatar (entre o sino e o user).
  #
  # v1.14.0 (par do SsNavBar + SsNavScaffold do app):
  # - tabs: [{ label:, icon: "home", href:, current:, badge: }] = a barra de abas de baixo no celular (até 1023 px),
  #   como a do app: o ícone da aba atual passa de contorno para cheio com escala de mola e leve rotação. icon: nome
  #   do ss_icon (contorno e cheio saem do mesmo nome) ou SVG pronto (só o contorno).
  # - tab_transition: true (padrão) = a troca de aba é uma View Transition com nome (fade through no conteúdo, a
  #   barra parada). Precisa do ss_view_transitions_head no <head>; sem suporte ou com reduzir movimento, corte seco.
  #   A peça que aparece nas duas abas leva o mesmo nome com ss_tab_hero("saldo") (par do SsTabHero).
  #
  # v0.24 (auditoria de UX, C02/U14): a troca de empresa só vira menu com 2 ou mais empresas. Com uma só, o nome fica
  # parado (sem seta nem menu; single_tenant: false nem mostra). O nome longo ganha reticências (num <span>, que o
  # grid do rótulo cortava seco) e o nome inteiro no title=.
  class AppShellComponent < BaseComponent
    COOKIE = "ss_shell_collapsed".freeze

    renders_one :logo
    renders_one :mark
    renders_one :user
    renders_one :top
    renders_one :top_mobile
    renders_one :side_footer
    renders_one :bell
    renders_one :help
    renders_one :suite

    attr_reader :nav, :tenants

    def initialize(brand: nil, nav: [], tenants: [], tenant_label: nil, search: true,
                   search_label: nil, side_label: nil, search_action: nil, collapsed: false, brand_url: nil,
                   mobile_brand: true, main_class: nil, main_max: nil, single_tenant: true, tabs: [], tab_transition: true, **opts)
      super(**opts)
      @collapsed = collapsed
      @tabs = Array(tabs).map { _1.to_h.transform_keys(&:to_sym) }
      @tab_transition = tab_transition
      @brand_url = brand_url
      @mobile_brand = mobile_brand
      @main_class = main_class
      @main_max = main_max
      @brand = brand
      @nav = nav
      @tenants = tenants
      @tenant_label = tenant_label
      @single_tenant = single_tenant
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

    # Recolhido no servidor: o cookie da escolha do usuário ("1"/"0") ou o collapsed:.
    def collapsed?
      saved = (request&.cookies&.[](COOKIE) rescue nil).to_s
      %w[0 1].include?(saved) ? saved == "1" : !!@collapsed
    end

    def collapse_button_label = collapsed? ? expand_label : collapse_label

    # Separador no menu: { separator: true } ou { divider: true }.
    def separator?(item) = !!(item[:separator] || item[:divider])

    # Badge com valor: some quando é nil, vazio ou zero.
    def badge?(value) = value.present? && value.to_s.strip != "0"

    def main_attrs
      data = { max: (@main_max ? "" : nil), ss_tab_main: (@tab_transition && tabs? ? "" : nil) }.compact
      { class: ["ss-shell-content", @main_class].compact.join(" "), id: "conteudo", tabindex: "-1",
        data: data.presence, style: (@main_max ? "--shell-main-max:#{ERB::Util.html_escape(@main_max)}" : nil) }.compact
    end

    # v1.14.0: a barra de abas do celular.
    def tabs? = @tabs.any?
    def tabs = @tabs
    def tabs_label = ss_t("app_shell.tabs", default: "Abas")

    # Ícone da aba: contorno e cheio do mesmo nome (o cheio entra na aba atual).
    def tab_icon(it)
      ic = it[:icon]
      return tag.span(it[:label].to_s[0], class: "ss-shell-initial", "aria-hidden": "true") if ic.blank?
      return tag.span(ic, class: "ss-tab-ico") if ic.respond_to?(:html_safe?) && ic.html_safe?

      tag.span(safe_join([ss_icon(ic, size: nil, css: "is-outline"), ss_icon(ic, variant: :solid, size: nil, css: "is-solid")]), class: "ss-tab-ico")
    end

    def tabbar_data = (@tab_transition ? { controller: "ss-tab-transition", action: "click->ss-tab-transition#mark" } : {})

    # Nada para a barra de cima do computador: ela some (CSS, a partir de 1024 px).
    def top_bare? = !@search && !top? && !user? && !bell? && !help? && !suite?

    def top_class = ["ss-shell-top", ("is-bare" if top_bare?)].compact.join(" ")

    def mobile_brand? = @mobile_brand && (@brand.present? || logo?)

    # Marca (quadrado ou a do app) + nome; com brand_url: vira link.
    def brand_tag(css, name: true)
      inner = safe_join([
        tag.span(mark? ? mark : nil, class: ["ss-shell-logo", ("has-mark" if mark?)].compact.join(" "), "aria-hidden": "true"),
        (tag.span(logo? ? logo : @brand, class: "ss-shell-label ss-shell-brand-name") if name)
      ].compact)
      # v0.24: o link da marca tem nome mesmo quando o texto some (barra do celular, menu recolhido).
      @brand_url ? link_to(@brand_url, class: [css.presence, "ss-shell-brand-link"].compact.join(" "), "aria-label": @brand.presence) { inner } : (css.present? ? tag.span(inner, class: css) : inner)
    end

    def shell_data
      { controller: "ss-shell", ss_shell_search_action_value: @search_action, ss_shell_collapse_label_value: collapse_label,
        ss_shell_expand_label_value: expand_label,
        collapsed: (collapsed? ? "" : nil),
        action: "keydown.esc@window->ss-shell#close keydown.ctrl+k@window->ss-shell#search:prevent keydown.meta+k@window->ss-shell#search:prevent" }.compact
    end

    def current_tenant = @tenants.find { _1[:current] } || @tenants.first

    # v0.24: menu de troca só com 2+ empresas; com uma, o nome parado (ou nada com single_tenant: false).
    def tenant_menu? = @tenants.size > 1
    def tenant_single? = @tenants.size == 1 && @single_tenant

    def icon(svg)
      svg if svg.respond_to?(:html_safe?) && svg.html_safe?
    end

    def group_open?(group) = group.fetch(:open, true) || group[:items].any? { _1[:current] }
  end
end
