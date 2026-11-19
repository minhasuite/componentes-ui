module Ss
  # v1.6 · Ajuda da moldura (par do SsHelpMenu): o botão "?" da barra de cima e o popover com "Aprenda" (as videoaulas)
  # e "Novidades" (o que mudou), os dois abrindo em outra aba. Quando há novidade que a pessoa ainda não viu, o botão
  # ganha um ponto e a linha "Novidades" o selo "2 novas"; clicar nela apaga os dois na hora (controller ss-help) e o
  # produto marca como visto no servidor (o news_href costuma ser uma rota do produto que grava e redireciona ao portal).
  # Vai no slot help do Ss::AppShellComponent (à direita da barra de cima, antes do sino).
  #
  #   s.with_help do
  #     render Ss::HelpMenuComponent.new(learn_href: "https://www.minhasuite.com/vendas/aprenda/",
  #                                      news_href: novidades_path, unseen_news: 2)
  #   end
  #
  # news_href: nil esconde "Novidades" (produto que ainda não publicou nenhuma). items: [{ label:, text:, href:, icon:,
  # external: }] entra depois das duas (ex. atalhos do teclado). Textos do I18n (componentes_ui.help.*).
  class HelpMenuComponent < BaseComponent
    def initialize(learn_href:, news_href: nil, unseen_news: 0, items: [], id: "ss-help", label: nil, **rest)
      super(**rest)
      @learn_href = learn_href
      @news_href = news_href
      @unseen = news_href ? unseen_news.to_i.clamp(0, 99) : 0
      @items = Array(items).map { |i| i.to_h.transform_keys(&:to_sym) }
      @id = id.to_s
      @label = label || ss_t("help.title", default: "Ajuda")
    end

    def call
      tag.span(**root_attrs(class: classes("ss-help", "ss-popover-host"), data: { controller: "ss-popover ss-help", ss_help_label_value: @label })) do
        safe_join([trigger, panel])
      end
    end

    private

    def pid = "#{@id}-panel"
    def unseen_text = ss_t("help.unseen", count: @unseen, default: @unseen == 1 ? "1 nova" : "#{@unseen} novas")
    def button_label = @unseen.positive? ? ss_t("help.button_unseen", count: @unseen, label: @label, default: "#{@label}, #{@unseen} novidades não vistas") : @label

    def trigger
      tag.button(type: "button", class: "ss-icon-btn ss-help-btn", popovertarget: pid, "aria-label": button_label, title: @label,
                 style: "anchor-name:--#{pid}", data: { ss_popover_target: "trigger", ss_help_target: "button" }) do
        safe_join([ss_icon("question-mark-circle", size: nil), (tag.span(class: "ss-help-dot", "aria-hidden": "true", data: { ss_help_target: "dot" }) if @unseen.positive?)].compact)
      end
    end

    def panel
      rows = [
        { label: ss_t("help.learn", default: "Aprenda"), text: ss_t("help.learn_note", default: "Videoaulas de cada tela"), href: @learn_href,
          icon: "academic-cap", external: true },
        ({ label: ss_t("help.news", default: "Novidades"), text: ss_t("help.news_note", default: "O que mudou no sistema"), href: @news_href,
           icon: "sparkles", external: true, news: true } if @news_href),
        *@items
      ].compact
      tag.div(id: pid, popover: "auto", class: "ss-popover ss-help-panel", role: "dialog", "aria-label": @label, style: "position-anchor:--#{pid}",
              data: { placement: "bottom-end", ss_popover_target: "panel", ss_help_target: "panel", action: "toggle->ss-popover#place" }) do
        safe_join([tag.p(@label, class: "ss-popover-title"), tag.ul(safe_join(rows.map { row(_1) }), class: "ss-help-list")])
      end
    end

    def row(it)
      external = it.fetch(:external, false)
      tail = if it[:news] && @unseen.positive?
               tag.span(unseen_text, class: "ss-badge ss-badge-accent ss-help-new", data: { ss_help_target: "badge" })
             elsif external
               ss_icon("external-link", size: nil, css: "ss-help-out")
             end
      inner = safe_join([
        tag.span(svg(it[:icon]), class: "ss-icon-tile is-accent"),
        tag.span(class: "ss-help-text") do
          safe_join([tag.span(it[:label], class: "ss-help-title"), (tag.span(it[:text], class: "ss-help-note") if it[:text].present?)].compact)
        end,
        tail,
        (tag.span(" #{ss_t('app_shell.external', default: '(abre em outra aba)')}", class: "ss-sr") if external)
      ].compact)
      attrs = { class: "ss-help-item" }
      attrs.merge!(target: "_blank", rel: "noopener") if external
      attrs[:data] = { action: "ss-help#seen" } if it[:news]
      attrs[:data] = { action: "ss-help#close" } if !it[:news] && external
      tag.li(link_to(inner, it[:href], **attrs))
    end

    def svg(icon)
      return icon if icon.respond_to?(:html_safe?) && icon.html_safe?

      ss_icon(icon.to_s, size: nil)
    end
  end
end
