module Ss
  # Barra de filtros por GET: visões salvas em abas, busca, chips dos filtros ativos
  # (com × que tira o filtro) e "+ Filtro" com as opções. Tudo é link ou form GET:
  # funciona sem JS, com Turbo e com o botão voltar.
  #
  #   render Ss::FilterBarComponent.new(
  #     views: [{ label: "Todos", params: {} }, { label: "Vencidos esta semana", params: { status: "vencido", periodo: "semana" }, count: 4 }],
  #     filters: [{ param: :status, label: "Situação", options: [["Pago", "pago"], ["Vencido", "vencido"]] }],
  #     search: :q, placeholder: "Buscar cliente ou número")
  class FilterBarComponent < BaseComponent
    IGNORE = %w[page sort dir].freeze

    def initialize(views: [], filters: [], search: :q, placeholder: "Buscar", url: nil, params: nil, **opts)
      super(**opts)
      @views = views
      @filters = filters
      @search = search&.to_s
      @placeholder = placeholder
      @url = url
      @params = params
    end

    def current
      @current ||= (@params || (helpers.request&.query_parameters rescue {}) || {}).to_h.transform_keys(&:to_s).reject { |_, v| v.blank? }
    end

    # Filtros ativos: [{ param:, label:, value_label: }]
    def active
      @filters.filter_map do |f|
        v = current[f[:param].to_s]
        next unless v

        opt = f[:options].find { |(_, val)| val.to_s == v.to_s }
        { param: f[:param].to_s, label: f[:label], value_label: opt ? opt[0] : v }
      end
    end

    def view_current?(view)
      want = view[:params].to_h.transform_keys(&:to_s).transform_values(&:to_s)
      have = current.except(*IGNORE, @search).transform_values(&:to_s)
      want == have
    end

    def href(params)
      q = params.reject { |_, v| v.blank? }.to_query
      q.empty? ? (@url || "?") : "#{@url}?#{q}"
    end
    def view_href(view) = href(view[:params].to_h.transform_keys(&:to_s).merge(@search => current[@search]))
    def remove_href(param) = href(current.except(param, "page"))
    def add_href(param, value) = href(current.except("page").merge(param.to_s => value))
    def clear_href = href({})
    def hidden_params = current.except(@search, "page")
    def query = current[@search]
    def search? = !@search.nil?
    attr_reader :views, :filters, :placeholder, :url
  end
end
