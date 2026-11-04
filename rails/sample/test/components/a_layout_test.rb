require "test_helper"

# Lote A · Fundação e Layout: um render por componente.
class ALayoutTest < ComponentTest
  SVG = '<svg viewBox="0 0 24 24"><path d="M4 4h16"/></svg>'.html_safe

  test "migalhas: último item é a página atual, sem link" do
    render_inline Ss::BreadcrumbsComponent.new(items: [["Início", "/"], ["Pedidos", "/pedidos"], ["Pedido 1042"]])
    assert_selector "nav.ss-crumbs[aria-label] ol li", count: 3
    assert_selector "a[href='/pedidos']", text: "Pedidos"
    assert_selector "li:last-child span[aria-current='page']", text: "Pedido 1042"
    assert_no_selector "li:last-child a"
  end

  test "página: título, subtítulo, migalhas, ações, abas, filtros e corpo" do
    render_inline(Ss::PageComponent.new(title: "Pedidos", subtitle: "Abril", crumbs: [["Início", "/"], ["Pedidos"]])) do |p|
      p.with_actions { "<a class='novo'>Novo</a>".html_safe }
      p.with_tabs { "abas" }
      p.with_filters { "filtros" }
      "corpo"
    end
    assert_selector ".ss-page h1.ss-page-title", text: "Pedidos"
    assert_selector ".ss-page-sub", text: "Abril"
    assert_selector ".ss-page .ss-crumbs"
    assert_selector ".ss-page-actions a.novo"
    assert_selector ".ss-page-tabs", text: "abas"
    assert_selector ".ss-page-filters", text: "filtros"
    assert_selector ".ss-page-body", text: "corpo"
  end

  test "moldura: menu com grupo, item atual, badge, empresa, busca e usuário" do
    nav = [{ items: [{ label: "Painel", href: "/", icon: SVG, current: true }] },
           { title: "Vendas", items: [{ label: "Pedidos", href: "/pedidos", badge: 3 }] }]
    render_inline(Ss::AppShellComponent.new(brand: "Minhas Vendas", nav: nav,
                    tenants: [{ name: "Loja Centro", href: "/t/1", current: true }, { name: "Loja Sul", href: "/t/2" }])) do |s|
      s.with_user { "Ana" }
      s.with_top { "topo" }
      "conteúdo"
    end
    assert_selector ".ss-shell[data-controller='ss-shell']"
    assert_selector "aside.ss-shell-side .ss-shell-brand-name", text: "Minhas Vendas"
    assert_selector "nav.ss-nav a[aria-current='page'][href='/'] svg"
    assert_selector "details[open] summary", text: "Vendas"
    assert_selector "a[href='/pedidos'] .ss-nav-badge", text: "3"
    assert_selector "a[href='/pedidos'] .ss-shell-initial", text: "P"
    assert_selector ".ss-shell-tenant summary", text: "Loja Centro"
    assert_selector ".ss-shell-tenant-item", count: 2, visible: :all
    assert_selector "button.ss-shell-search[data-action='ss-shell#search']"
    assert_selector "button.ss-shell-collapse[aria-expanded='true'][aria-controls='ss-shell-side']"
    assert_selector ".ss-shell-top-end", text: "Ana"
    assert_selector "main.ss-shell-content", text: "conteúdo"
  end

  test "lista + detalhe: frame com vazio e botão voltar" do
    render_inline(Ss::SplitViewComponent.new(frame_id: "pedido")) do |s|
      s.with_list { "<a href='/p/1' data-turbo-frame='pedido'>1</a>".html_safe }
      s.with_empty { "Escolha" }
    end
    assert_selector ".ss-split[data-controller='ss-split-view'][data-ss-split-view-frame-value='pedido']"
    assert_selector ".ss-split-list a[data-turbo-frame='pedido']"
    assert_selector "turbo-frame#pedido .ss-split-empty", text: "Escolha"
    assert_selector "button.ss-split-back[data-action='ss-split-view#back']"
  end

  test "lista + detalhe: com detalhe inicial não mostra o vazio" do
    render_inline(Ss::SplitViewComponent.new) { |s| s.with_list { "x" }; s.with_detail { "Pedido 1" } }
    assert_selector "turbo-frame#detalhe", text: "Pedido 1"
    assert_no_selector ".ss-split-empty"
  end

  test "painel lateral: dialog com título, fechar, frame e rodapé" do
    render_inline(Ss::DrawerComponent.new(id: "painel", title: "Pedido", frame_id: "painel_frame")) do |d|
      d.with_footer { "rodapé" }
      "inicial"
    end
    assert_selector "dialog#painel.ss-drawer-panel[aria-labelledby='painel-title'][data-controller='ss-drawer']", visible: :all
    assert_selector "h2#painel-title", text: "Pedido", visible: :all
    assert_selector "form[method='dialog'] button[aria-label='Fechar']", visible: :all
    assert_selector "turbo-frame#painel_frame", text: "inicial", visible: :all
    assert_selector "footer.ss-drawer-foot", text: "rodapé", visible: :all
  end

  test "mosaico: blocos com span e tom" do
    render_inline(Ss::BentoGridComponent.new) do |g|
      g.with_block(cols: 2, rows: 2, tone: :grad) { "Destaque" }
      g.with_block(href: "/x", tone: :soft) { "Link" }
      g.with_block(cols: 9) { "Limite" }
    end
    assert_selector ".ss-bento .ss-bento-cell", count: 3
    assert_selector ".ss-bento-cell.is-grad[style*='--c:2;--r:2']", text: "Destaque"
    assert_selector "a.ss-bento-cell.is-soft[href='/x']"
    assert_selector ".ss-bento-cell[style*='--c:4']", text: "Limite"
  end

  test "herói: palavra destacada em em (cor), ações, mídia e textura" do
    render_inline(Ss::HeroSectionComponent.new(kicker: "MV", title: "Venda mais no balcão", highlight: "Venda mais", text: "Texto", texture: true)) do |h|
      h.with_actions { "<a class='cta'>Começar</a>".html_safe }
      h.with_media { "<img alt=''>".html_safe }
    end
    assert_selector "section.ss-hero-section.has-media"
    assert_selector "h1.ss-hero-section-title em.ss-hero-section-hl", text: "Venda mais"
    assert_selector "h1", text: "Venda mais no balcão"
    assert_selector ".ss-hero-section-actions a.cta"
    assert_selector ".ss-hero-section-media img"
    assert_selector ".ss-texture[aria-hidden='true']", visible: :all
  end

  test "faixa de vantagens: itens e tom escuro" do
    render_inline(Ss::FeatureStripComponent.new(tone: :deep)) do |f|
      f.with_feature(title: "Offline", text: "Sem sinal", icon: SVG)
      f.with_feature(title: "Pix")
    end
    assert_selector "ul.ss-features.is-deep li.ss-feature", count: 2
    assert_selector ".ss-feature-icon svg"
    assert_selector ".ss-feature h3", text: "Offline"
  end

  test "abas: painel, frame preguiçoso e aria" do
    render_inline(Ss::TabsComponent.new(label: "Seções", id: "abas")) do |t|
      t.with_tab(label: "Itens") { "lista de itens" }
      t.with_tab(label: "Histórico", id: "hist", frame_src: "/historico")
    end
    assert_selector ".ss-tabs[data-controller='ss-tabs'] [role='tablist'][aria-label='Seções']"
    assert_selector "button[role='tab'][aria-selected='true'][aria-controls='abas-itens']", text: "Itens"
    assert_selector "button[role='tab'][aria-selected='false'][tabindex='-1']", text: "Histórico"
    assert_selector "#abas-itens[role='tabpanel']", text: "lista de itens"
    assert_selector "#abas-hist[hidden] turbo-frame#abas-hist-frame[src='/historico'][loading='lazy']", visible: :all
    assert_selector ".ss-tabs-ink"
  end

  test "abas como links: navegação com aria-current" do
    render_inline(Ss::TabsComponent.new(label: "Situação")) do |t|
      t.with_tab(label: "Todos", href: "/a", current: true, badge: 9)
      t.with_tab(label: "Pagos", href: "/b")
    end
    assert_selector "[role='navigation'] a.ss-tab[aria-current='page'][href='/a'] .ss-tab-badge", text: "9"
    assert_no_selector "[role='tabpanel']"
  end

  test "barra de salvar: controller ss-dirty e botões padrão" do
    render_inline Ss::StickyActionBarComponent.new(message: "Alterado")
    assert_selector ".ss-sticky-bar[data-controller='ss-dirty'][role='region']", visible: :all
    assert_selector "button[type='submit']", text: "Salvar", visible: :all
    assert_selector "button[data-action='ss-dirty#reset']", text: "Cancelar", visible: :all
    render_inline Ss::StickyActionBarComponent.new(always: true)
    assert_selector ".ss-sticky-bar[data-visible]"
  end

  test "configurações: menu de seções, linhas com ação e com link" do
    render_inline(Ss::SettingsLayoutComponent.new(title: "Configurações")) do |s|
      s.with_section(id: "conta", title: "Conta", description: "Seus dados", icon: SVG) do |sec|
        sec.with_item(title: "Nome", description: "No recibo") { "<button>Editar</button>".html_safe }
        sec.with_item(title: "Privacidade", href: "/priv")
        sec.with_item(title: "Excluir", danger: true)
      end
      s.with_section(id: "pref", title: "Preferências")
    end
    assert_selector ".ss-settings[data-controller='ss-scrollspy'] nav a[href='#conta'][aria-current] svg"
    assert_selector "nav a[href='#pref']", text: "Preferências"
    assert_selector "section#conta[aria-labelledby='conta-titulo'] h2", text: "Conta"
    assert_selector ".ss-settings-row .ss-settings-action button", text: "Editar"
    assert_selector "a.ss-settings-row[href='/priv'] .ss-settings-chev"
    assert_selector ".ss-settings-row.is-danger", text: "Excluir"
  end

  test "folha de impressão: cabeçalho, partes, tabela, totais e rodapé" do
    render_inline(Ss::PrintLayoutComponent.new(title: "Pedido", number: "1042", date: "04/11/2026",
                    company: { name: "Loja Centro", lines: ["CNPJ 1"] }, customer: { name: "Mercado", lines: ["CPF 2"] },
                    columns: [["Item"], ["Total", :r]], rows: [["Arroz", "R$ 50,00"]],
                    totals: [["Subtotal", "R$ 50,00"], ["Total", "R$ 50,00", :strong]])) do |p|
      p.with_notes { "Obrigado" }
      p.with_footer { "Sem valor fiscal" }
    end
    assert_selector "article.ss-print .ss-print-title", text: "Pedido"
    assert_selector ".ss-print-doc .num", text: "Nº 1042"
    assert_selector ".ss-print-brand strong", text: "Loja Centro"
    assert_selector ".ss-print-party strong", text: "Mercado"
    assert_selector ".ss-print-table th.r", text: "Total"
    assert_selector ".ss-print-table td.r.num", text: "R$ 50,00"
    assert_selector ".ss-print-totals .is-strong dd", text: "R$ 50,00"
    assert_selector ".ss-print-notes", text: "Obrigado"
    assert_selector ".ss-print-foot", text: "Sem valor fiscal"
  end

  test "troca de tema: Auto/Claro/Escuro/OLED e paletas em swatch" do
    render_inline Ss::ThemeSwitcherComponent.new
    assert_selector "[data-controller='ss-theme'][role='group'] .ss-seg button", count: 4
    assert_selector "button[data-ss-theme-theme-param='dark'][data-ss-theme-oled-param='true']", text: "OLED"
    assert_selector "button[data-ss-theme-theme-param='dark'][data-ss-theme-oled-param='false']", text: "Escuro"
    assert_selector "button.ss-pal-chip[data-swatch='eucalipto'][data-ss-theme-palette-param='eucalipto'][title='Eucalipto']"
    assert_selector "button.ss-pal-chip[data-swatch='violeta'][data-ss-theme-palette-param='none']"
    assert_selector "button.ss-pal-chip", count: ComponentesUi::PALETAS.size
    assert_selector ".ss-theme-pal-grid.is-grouped .ss-theme-pal-fam", count: ComponentesUi::PALETA_FAMILIAS.size
    assert_selector ".ss-theme-pal-head [data-ss-theme-target='name']", text: "Violeta"
    render_inline Ss::ThemeSwitcherComponent.new(palettes: false, oled: false)
    assert_selector ".ss-seg button", count: 3
    assert_no_selector ".ss-pal-chip"
    # Lista curta ("violeta" vale como "none"): sem grupos.
    render_inline Ss::ThemeSwitcherComponent.new(palettes: %w[violeta eucalipto marple])
    assert_selector "button.ss-pal-chip", count: 3
    assert_selector "button.ss-pal-chip[data-ss-theme-palette-param='none']"
    assert_no_selector ".ss-theme-pal-fam"
    # Compacto: faixa rolável, sem cabeçalho nem grupos.
    render_inline Ss::ThemeSwitcherComponent.new(compact: true)
    assert_selector ".ss-theme-switcher.is-compact button.ss-pal-chip", count: ComponentesUi::PALETAS.size
    assert_no_selector ".ss-theme-pal-head"
    assert_no_selector ".ss-theme-pal-fam"
  end

  test "base: css: e atributos extras chegam no elemento raiz" do
    render_inline Ss::BentoGridComponent.new(css: "minha", id: "mosaico", data: { teste: "1" })
    assert_selector ".ss-bento.minha#mosaico[data-teste='1']"
  end
end
