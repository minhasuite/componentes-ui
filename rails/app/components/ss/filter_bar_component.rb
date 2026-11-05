module Ss
  # Barra de filtros por GET: visões salvas em abas, busca, chips dos filtros ativos
  # (com × que tira o filtro) e "+ Filtro" com as opções. Tudo é link ou form GET:
  # funciona sem JS, com Turbo e com o botão voltar.
  #
  #   render Ss::FilterBarComponent.new(
  #     views: [{ label: "Todos", params: {} }, { label: "Vencidos esta semana", params: { status: "vencido", periodo: "semana" }, count: 4 }],
  #     filters: [{ param: :status, label: "Situação", options: [["Pago", "pago"], ["Vencido", "vencido"]] }],
  #     search: :q, placeholder: "Buscar cliente ou número")
  #
  # v0.10.3:
  # - Filtro de vários valores: { param: :tag, multiple: true, options: [...] } usa tag[] na URL;
  #   cada valor vira um chip (o × tira só aquele) e "+ Filtro" acrescenta. Valor em array
  #   (?tag[]=a&tag[]=b) também é lido em filtro simples (um chip por valor).
  # - A busca leva todos os filtros ativos em campos escondidos, arrays (name[]) e hashes
  #   (name[k]) inclusive.
  # - url: com query ("/pontos?site_id=3") mantém esses parâmetros em todo link, na busca e no
  #   "Limpar filtros" (que tira só os filtros, não o site_id).
  class FilterBarComponent < BaseComponent
    IGNORE = %w[page sort dir].freeze

    def initialize(views: [], filters: [], search: :q, placeholder: nil, url: nil, params: nil, **opts)
      super(**opts)
      @views = views
      @filters = filters
      @search = search&.to_s
      @placeholder = placeholder || ss_t("filter_bar.placeholder", default: "Buscar")
      @path, query = url.to_s.split("?", 2)
      @path = nil if url.nil?
      @base = query.present? ? Rack::Utils.parse_nested_query(query) : {}
      @params = params
    end

    # Parâmetros fixos do url: (ficam em todo link e no "Limpar filtros").
    attr_reader :base

    def current
      @current ||= base.merge(
        (@params || (helpers.request&.query_parameters rescue {}) || {}).to_h.deep_stringify_keys
      ).reject { |_, v| blank_value?(v) }
    end

    def multiple?(f) = !!f[:multiple]

    # Valores de um parâmetro como lista (aceita "a", ["a", "b"] e { "0" => "a" }).
    def values_of(param)
      v = current[param.to_s]
      list = case v
             when Array then v
             when Hash then v.values
             when nil then []
             else [v]
             end
      list.map(&:to_s).reject(&:blank?)
    end

    # Filtros ativos: [{ param:, label:, value_label:, value: }] — um por valor.
    def active
      @filters.flat_map do |f|
        values_of(f[:param]).map do |v|
          opt = f[:options].find { |(_, val)| val.to_s == v }
          { param: f[:param].to_s, label: f[:label], value_label: opt ? opt[0] : v, value: v }
        end
      end
    end

    def view_current?(view)
      want = normalize(view[:params].to_h.deep_stringify_keys)
      have = normalize(current.except(*IGNORE, @search, *base.keys))
      want == have
    end

    def href(params)
      q = params.reject { |_, v| blank_value?(v) }.to_query
      q.empty? ? (@path || "?") : "#{@path}?#{q}"
    end
    def view_href(view) = href(base.merge(view[:params].to_h.deep_stringify_keys).merge(@search => current[@search]))

    # Tira o filtro (ou só aquele valor, quando há vários).
    def remove_href(param, value = nil)
      rest = values_of(param) - [value.to_s]
      p = current.except(param.to_s, "page")
      p[param.to_s] = rest if value && rest.any?
      href(p)
    end

    def add_href(param, value, multiple: false)
      v = multiple ? (values_of(param) | [value.to_s]) : value
      href(current.except("page").merge(param.to_s => v))
    end

    def option_current?(f, value) = values_of(f[:param]).include?(value.to_s)
    def clear_href = href(base)

    # Campos escondidos da busca: [[nome, valor]], com name[] e name[k] para array e hash.
    def hidden_fields
      q = current.except(@search, "page").to_query
      q.split("&").map { |kv| kv.split("=", 2).map { |x| CGI.unescape(x.to_s) } }
    end
    def hidden_params = current.except(@search, "page")
    def query = current[@search]
    def search? = !@search.nil?
    def url = @path
    attr_reader :views, :filters, :placeholder

    private

    def blank_value?(v)
      case v
      when Array then v.all? { blank_value?(_1) }
      when Hash then v.values.all? { blank_value?(_1) }
      else v.blank?
      end
    end

    def normalize(h) = h.transform_values { |v| v.is_a?(Array) ? v.map(&:to_s).sort : v.is_a?(Hash) ? v.transform_values(&:to_s) : v.to_s }
  end
end
