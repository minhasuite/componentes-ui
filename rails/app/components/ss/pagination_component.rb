module Ss
  # Paginação solta (fora da DataTable): anterior, números com reticências e próxima, no
  # visual do pager da tabela (.ss-dt-pager) com o anel que desliza (ss-indicator).
  #   render Ss::PaginationComponent.new(page: @pagy.page, pages: @pagy.pages, url: ->(p) { pedidos_path(page: p) })
  #   render Ss::PaginationComponent.new(page: 3, pages: 12, params: request.query_parameters, total: 230)
  # Sem url: nem params:, usa a query da requisição e troca só o param (padrão :page).
  # Com 1 página ou menos, não renderiza nada. Textos do I18n (componentes_ui.pagination.*).
  class PaginationComponent < BaseComponent
    attr_reader :page, :pages

    def initialize(page:, pages:, url: nil, params: nil, param: :page, total: nil, around: 1, label: nil, **opts)
      super(**opts)
      @pages = pages.to_i
      @page = page.to_i.clamp(1, [@pages, 1].max)
      @url = url
      @params = params
      @param = param.to_s
      @total = total
      @around = around.to_i
      @label = label
    end

    def render? = pages > 1

    def call
      tag.nav(**root_attrs(class: classes("ss-dt-pager", "ss-pagination"), "aria-label": @label || ss_t("pagination.label", default: "Paginação"),
                           data: { controller: "ss-indicator", ss_indicator_key_value: "pagination" })) do
        safe_join([total_tag, prev_tag, *items.map { |n| item_tag(n) }, next_tag].compact)
      end
    end

    # Janela de páginas: 1 … 4 5 6 … 20 (a mesma conta do pager da DataTable).
    def items
      nums = ([1, pages] + ((page - @around)..(page + @around)).to_a).select { _1.between?(1, pages) }.uniq.sort
      nums.each_with_index.flat_map { |n, i| i.positive? && n - nums[i - 1] > 1 ? [:gap, n] : [n] }
    end

    def href(n)
      return @url.call(n) if @url.respond_to?(:call)

      base = (@params || (helpers.request&.query_parameters rescue nil) || {}).to_h.transform_keys(&:to_s)
      query = base.merge(@param => n).to_query
      "#{@url.is_a?(String) ? @url : ""}?#{query}"
    end

    private

    def total_tag
      return unless @total

      tag.span(ss_t("pagination.total", count: @total, default: "%{count} itens"), class: "ss-dt-total num")
    end

    def prev_tag
      label = ss_t("pagination.previous", default: "Página anterior")
      page > 1 ? link_to("‹", href(page - 1), rel: "prev", "aria-label": label) : tag.span("‹", "aria-disabled": "true", "aria-label": label)
    end

    def next_tag
      label = ss_t("pagination.next", default: "Próxima página")
      page < pages ? link_to("›", href(page + 1), rel: "next", "aria-label": label) : tag.span("›", "aria-disabled": "true", "aria-label": label)
    end

    def item_tag(n)
      return tag.span("…", class: "ss-dt-gap", "aria-hidden": "true") if n == :gap

      aria = ss_t("pagination.page", page: n, default: "Página %{page}")
      tag.a(n, href: href(n), class: "num", "aria-label": aria, "aria-current": (n == page ? "page" : nil))
    end
  end
end
