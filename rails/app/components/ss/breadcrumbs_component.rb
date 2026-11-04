module Ss
  # Migalhas: onde a pessoa está. O último item é a página atual (sem link).
  #   render Ss::BreadcrumbsComponent.new(items: [["Início", root_path], ["Pedidos", pedidos_path], ["Pedido 1042"]])
  class BreadcrumbsComponent < BaseComponent
    def initialize(items:, label: "Você está em", **opts)
      super(**opts)
      @items = items.map { |i| i.is_a?(Hash) ? [i[:label], i[:href]] : Array(i) }
      @label = label
    end

    def call
      lis = @items.each_with_index.map do |(text, href), idx|
        last = idx == @items.size - 1
        inner = if href && !last
          link_to(text, href)
        else
          tag.span(text, "aria-current": (last ? "page" : nil))
        end
        tag.li(inner)
      end
      tag.nav(**root_attrs(class: classes("ss-crumbs"), "aria-label": @label)) { tag.ol(safe_join(lis)) }
    end

    def render? = @items.any?
  end
end
