module Ss
  # Novidades: sino com ponto quando há item não visto + popover com a lista (data,
  # selo "novo"). Abrir marca como lido no navegador (chave "ss-whats-new:<id>").
  #   render Ss::WhatsNewComponent.new(id: "financeiro", items: [
  #     { id: "2026-11-04-ia", date: Date.new(2026, 11, 4), title: "Pergunte à IA", text: "…", url: "…" }])
  # items do mais novo para o mais antigo; o id de cada item é estável.
  class WhatsNewComponent < BaseComponent
    BELL = %(<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M6 16V11a6 6 0 1 1 12 0v5l1.5 2h-15zM10 20a2 2 0 0 0 4 0"/></svg>).freeze

    def initialize(id:, items:, title: "Novidades", **opts)
      super(**opts)
      @id = id
      @items = items
      @title = title
    end

    def call
      pid = "ss-wn-#{@id}"
      tag.span(**root_attrs(class: classes("ss-whats-new", "ss-popover-host"), data: { controller: "ss-whats-new ss-popover", ss_whats_new_key_value: "ss-whats-new:#{@id}" })) do
        safe_join([
          tag.button(type: "button", class: "ss-wn-bell", popovertarget: pid, "aria-label": @title, style: "anchor-name:--#{pid}", data: { ss_popover_target: "trigger", ss_whats_new_target: "bell" }) do
            safe_join([BELL.html_safe, tag.i(class: "ss-wn-dot", hidden: true, data: { ss_whats_new_target: "dot" }), tag.span("", class: "ss-sr", data: { ss_whats_new_target: "srdot" })])
          end,
          tag.div(id: pid, popover: "auto", class: "ss-popover ss-wn-panel", role: "dialog", "aria-label": @title, style: "position-anchor:--#{pid}",
                  data: { placement: "bottom-end", ss_popover_target: "panel", action: "toggle->ss-popover#place toggle->ss-whats-new#seen" }) do
            safe_join([tag.p(@title, class: "ss-popover-title"), tag.ol(safe_join(@items.each_with_index.map { item(_1, _2) }), class: "ss-wn-list")])
          end
        ])
      end
    end

    private

    def item(it, i = 0)
      date = it[:date].respond_to?(:strftime) ? tag.time(it[:date].strftime("%d/%m/%Y"), datetime: it[:date].to_date.iso8601, class: "num") : tag.small(it[:date])
      body = safe_join([tag.span(safe_join([date, tag.span("novo", class: "ss-wn-new", hidden: true, data: { ss_whats_new_target: "badge" })]), class: "ss-wn-meta"),
                        tag.b(it[:title]), (tag.p(it[:text]) if it[:text])].compact)
      tag.li(style: "--i:#{i}", data: { ss_whats_new_target: "item", id: it[:id] }) { it[:url] ? link_to(body, it[:url]) : tag.div(body) }
    end
  end
end
