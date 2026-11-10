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
  #
  # v0.10.1: só cabeçalho. Sem bloco (ou com bloco vazio) não sai o .ss-page-body, e a página
  # não ganha o espaço do gap no fim: render Ss::PageComponent.new(title: "Pedidos").
  #
  # v0.17: eyebrow: põe a linha pequena em caixa alta acima do título (local · data, seção) e
  # compact: true encolhe o cabeçalho (título 1,2 rem, menos espaço): o topo discreto de um painel,
  # com as ações em botões de ícone. Par do SsTopBar(eyebrow:).
  #   render Ss::PageComponent.new(title: "Sala", eyebrow: "Casa · 10 de novembro", compact: true) { |p| p.with_actions { ... } }
  class PageComponent < BaseComponent
    BACK = %(<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M19 12H5m6-6-6 6 6 6"/></svg>).freeze

    renders_one :actions
    renders_one :tabs
    renders_one :filters
    renders_one :badge

    def initialize(title:, subtitle: nil, crumbs: nil, back: nil, back_label: nil, eyebrow: nil, compact: false, **opts)
      super(**opts)
      @title = title
      @subtitle = subtitle
      @crumbs = crumbs
      @back = back
      @back_label = back_label
      @eyebrow = eyebrow.presence
      @compact = compact
    end

    def body? = content.present? && content.to_s.strip.present?

    def back_label = @back_label || ss_t("page.back", default: "Voltar")
  end
end
