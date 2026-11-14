module Ss
  # Lista curta de avisos (v0.25): o miolo do Ss::NotificationBellComponent, também devolvido pela URL src: do sino
  # (com frame_id:, embrulhado no <turbo-frame> que ele espera). Cada item: ícone no quadradinho do tom, título
  # (negrito quando não lido), texto em até duas linhas, quando e o ponto de não lido.
  #
  #   render Ss::NotificationListComponent.new(frame_id: "ss-bell-list", items: [
  #     { title: "Portão aberto", text: "Há 10 min", time: "há 2 min", href: aviso_lido_path(a), method: :patch, unread: true,
  #       icon: "bell", tone: :danger }])
  #
  # href: sem method: vira <a>; com method: (:patch, :post…) vira um button_to (ex. abrir marca como lida e leva ao
  # destino). empty: texto da lista vazia (componentes_ui.bell.empty).
  class NotificationListComponent < BaseComponent
    TONES = %i[accent success warn danger muted].freeze

    def initialize(items: [], empty: nil, frame_id: nil, **rest)
      super(**rest)
      @items = Array(items).map { |i| i.to_h.transform_keys(&:to_sym) }
      @empty = empty
      @frame_id = frame_id
    end

    def call
      body = if @items.empty?
               tag.p(@empty || ss_t("bell.empty", default: "Nenhum aviso por aqui."), class: "ss-bell-empty")
             else
               tag.ul(safe_join(@items.map { item(_1) }), **root_attrs(class: classes("ss-bell-list")))
             end
      @frame_id ? content_tag("turbo-frame", body, id: @frame_id, target: "_top") : body
    end

    private

    def item(it)
      css = ["ss-bell-item", ("is-unread" if it[:unread])].compact.join(" ")
      inner = safe_join([
        (tag.span(svg(it[:icon]), class: ["ss-icon-tile", ("is-#{it[:tone]}" if TONES.include?(it[:tone]&.to_sym))].compact.join(" ")) if it[:icon].present?),
        tag.span(class: "ss-bell-text") do
          safe_join([tag.span(it[:title], class: "ss-bell-title"), (tag.span(it[:text], class: "ss-bell-note") if it[:text].present?),
                     (tag.span(it[:time], class: "ss-bell-time") if it[:time].present?)].compact)
        end,
        (tag.span(tag.span(ss_t("bell.unread_one", default: "não lido"), class: "ss-sr"), class: "ss-bell-dot") if it[:unread])
      ].compact)
      row = if it[:href] && it[:method].present? && it[:method].to_s != "get"
              render(ButtonComponent.new(href: it[:href], method: it[:method], variant: :bare, css: css, form: { class: "contents" })) { inner }
            elsif it[:href]
              link_to(it[:href], class: css) { inner }
            else
              tag.div(inner, class: css)
            end
      tag.li(row)
    end

    def svg(icon)
      return icon if icon.respond_to?(:html_safe?) && icon.html_safe?

      ss_icon(icon.to_s, size: nil)
    end
  end
end
