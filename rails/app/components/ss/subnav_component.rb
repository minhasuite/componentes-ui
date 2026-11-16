module Ss
  # Atalhos de seção (v0.10.2): no desktop a faixa .ss-subnav (a atual preenchida); abaixo de
  # 1024 px, com menu: true (padrão), vira um menu (.ss-subnav-menu): a seção atual e, ao abrir,
  # todas numa grade de duas colunas, sem rolar de lado. Sem JS (<details>).
  #
  #   render Ss::SubnavComponent.new(label: "Configurações", items: [
  #     { label: "Geral", href: settings_path, icon: icon("cog"), current: true }, { label: "Usuários", href: users_path }])
  #
  # icon: é o SVG do app (html_safe). current: marca a atual (padrão: current_page?(href)).
  #
  # v0.10.3: layout: :tabs deita a faixa no desktop (abas numa linha com o traço embaixo da
  # atual, no lugar da coluna fixa); no celular continua o menu. A faixa rola até a atual
  # (ss-scroll-current) quando não cabe.
  #
  # v0.28: sem item atual (ex. a raiz de uma página de seções), o menu do celular mostra o rótulo
  # (label:) e não marca o primeiro item como se fosse o atual. count_label: troca o contador
  # ("%{n} seções" por padrão; ex. "%{n} itens"); count_label: false tira.
  class SubnavComponent < BaseComponent
    CHEVRON = %(<svg class="ss-subnav-chevron" viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.2" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="m6 9 6 6 6-6"/></svg>).freeze

    LAYOUTS = %i[column tabs].freeze

    def initialize(items:, label: nil, menu: true, layout: :column, count_label: nil, **opts)
      super(**opts)
      @count_label = count_label
      @items = Array(items).map { _1.to_h.transform_keys(&:to_sym) }
      @label, @menu = label, menu
      @layout = LAYOUTS.include?(layout.to_s.to_sym) ? layout.to_s.to_sym : :column
    end

    def label = @label || ss_t("subnav.label", default: "Seções")

    def current?(i)
      return !!i[:current] if i.key?(:current)

      helpers.current_page?(i[:href]) rescue false
    end

    def current_item = @items.find { current?(_1) }

    def count_text
      return nil if @count_label == false

      @count_label ? Kernel.format(@count_label.to_s, n: @items.size) : ss_t("subnav.more", n: @items.size, default: "%{n} seções")
    end

    def link(i, short: false)
      link_to(i[:href], "aria-current": (current?(i) ? "page" : nil), class: i[:class]) do
        safe_join([i[:icon], (short ? tag.span(i[:label]) : i[:label])].compact)
      end
    end

    def call
      return "".html_safe if @items.empty?

      tag.div(**root_attrs(class: classes("ss-subnav-wrap", ("has-menu" if @menu), ("is-tabs" if @layout == :tabs)))) do
        safe_join([
          tag.nav(safe_join(@items.map { link(_1) }), class: "ss-subnav", "aria-label": label, data: { controller: "ss-scroll-current" }),
          (menu_html if @menu)
        ].compact)
      end
    end

    private

    def menu_html
      cur = current_item
      texto = cur ? cur[:label] : label
      tag.details(class: "ss-subnav-menu") do
        safe_join([
          tag.summary(class: "ss-subnav-current", "aria-label": (cur ? "#{label}: #{cur[:label]}" : label)) do
            safe_join([cur&.dig(:icon), tag.span(texto, class: "ss-subnav-label"),
                       (tag.span(count_text, class: "ss-subnav-count") if count_text), CHEVRON.html_safe].compact)
          end,
          tag.nav(safe_join(@items.map { link(_1, short: true) }), class: "ss-subnav-grid", "aria-label": label)
        ])
      end
    end
  end
end
