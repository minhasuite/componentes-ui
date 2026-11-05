module Ss
  # Atalhos de seção (v0.10.2): no desktop a faixa .ss-subnav (a atual preenchida); abaixo de
  # 1024 px, com menu: true (padrão), vira um menu (.ss-subnav-menu): a seção atual e, ao abrir,
  # todas numa grade de duas colunas, sem rolar de lado. Sem JS (<details>).
  #
  #   render Ss::SubnavComponent.new(label: "Configurações", items: [
  #     { label: "Geral", href: settings_path, icon: icon("cog"), current: true }, { label: "Usuários", href: users_path }])
  #
  # icon: é o SVG do app (html_safe). current: marca a atual (padrão: current_page?(href)).
  class SubnavComponent < BaseComponent
    CHEVRON = %(<svg class="ss-subnav-chevron" viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.2" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="m6 9 6 6 6-6"/></svg>).freeze

    def initialize(items:, label: nil, menu: true, **opts)
      super(**opts)
      @items = Array(items).map { _1.to_h.transform_keys(&:to_sym) }
      @label, @menu = label, menu
    end

    def label = @label || ss_t("subnav.label", default: "Seções")

    def current?(i)
      return !!i[:current] if i.key?(:current)

      helpers.current_page?(i[:href]) rescue false
    end

    def current_item = @items.find { current?(_1) } || @items.first

    def link(i, short: false)
      link_to(i[:href], "aria-current": (current?(i) ? "page" : nil), class: i[:class]) do
        safe_join([i[:icon], (short ? tag.span(i[:label]) : i[:label])].compact)
      end
    end

    def call
      return "".html_safe if @items.empty?

      tag.div(**root_attrs(class: classes("ss-subnav-wrap", ("has-menu" if @menu)))) do
        safe_join([
          tag.nav(safe_join(@items.map { link(_1) }), class: "ss-subnav", "aria-label": label),
          (menu_html if @menu)
        ].compact)
      end
    end

    private

    def menu_html
      cur = current_item
      tag.details(class: "ss-subnav-menu") do
        safe_join([
          tag.summary(class: "ss-subnav-current", "aria-label": "#{label}: #{cur[:label]}") do
            safe_join([cur[:icon], tag.span(cur[:label], class: "ss-subnav-label"),
                       tag.span(ss_t("subnav.more", n: @items.size, default: "%{n} seções"), class: "ss-subnav-count"), CHEVRON.html_safe].compact)
          end,
          tag.nav(safe_join(@items.map { link(_1, short: true) }), class: "ss-subnav-grid", "aria-label": label)
        ])
      end
    end
  end
end
