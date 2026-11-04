module Ss
  # Tabela de dados: colunas declaradas, ordenação por link (?sort=&dir=), colunas
  # que se escondem (lembradas no navegador), densidade, linha expansível, seleção
  # em massa com a barra flutuante, paginação por link, vazio, cabeçalho fixo e,
  # no celular, uma linha vira um card.
  #
  #   <%= render Ss::DataTableComponent.new(rows: @pedidos, id: "pedidos", caption: "Pedidos",
  #         sort: params[:sort], dir: params[:dir], selectable: true, bulk_url: lote_pedidos_path,
  #         pagination: { page: 2, pages: 9 }) do |t| %>
  #     <% t.column :cliente, "Cliente", sortable: true %>
  #     <% t.column :total, "Total", format: :money, sortable: true %>
  #     <% t.column :status, "Situação" do |p| %><%= ss_status(p.status, MAPA) %><% end %>
  #     <% t.expansion do |p| %>…detalhe…<% end %>
  #     <% t.bulk_actions do %><button class="is-danger" formaction="…">Excluir</button><% end %>
  #   <% end %>
  #
  # A ordenação é do servidor (o app ordena a consulta); sort_rows: true ordena um array em memória.
  class DataTableComponent < BaseComponent
    Column = Struct.new(:key, :label, :align, :sortable, :format, :hideable, :block, keyword_init: true)

    attr_reader :columns, :id, :caption

    def initialize(rows:, id:, caption:, sort: nil, dir: nil, sort_rows: false, selectable: false, bulk_url: nil,
                   row_id: :id, density: :comfortable, pagination: nil, params: nil, empty: "Nada por aqui ainda.",
                   max_height: nil, show_caption: false, tools: true, **opts)
      super(**opts)
      @rows = rows.to_a
      @id = id
      @caption = caption
      @sort = sort.presence&.to_s
      @dir = dir.to_s == "desc" ? "desc" : "asc"
      @sort_rows = sort_rows
      @selectable = selectable
      @bulk_url = bulk_url
      @row_id = row_id
      @density = density.to_s == "compact" ? "compact" : "comfortable"
      @pagination = pagination
      @params = params
      @empty = empty
      @max_height = max_height
      @show_caption = show_caption
      @tools = tools
      @columns = []
    end

    def column(key, label, align: nil, sortable: false, format: nil, hideable: true, &block)
      align ||= %i[money number].include?(format) ? :right : :left
      @columns << Column.new(key: key.to_s, label:, align: align.to_sym, sortable:, format:, hideable:, block:)
      nil
    end

    def expansion(&block) = (@expansion = block) && nil
    def bulk_actions(&block) = (@bulk = block) && nil

    def before_render
      content # roda o bloco: registra colunas, expansão e ações
    end

    # Linhas na ordem de exibição.
    def rows
      return @rows unless @sort_rows && @sort && (col = @columns.find { _1.key == @sort })

      sorted = @rows.sort_by { |r| v = value_of(r, col.key); [v.nil? ? 1 : 0, v.is_a?(String) ? v.downcase : v || 0] }
      @dir == "desc" ? sorted.reverse : sorted
    end

    def aria_sort(col)
      return nil unless col.sortable
      return "none" unless @sort == col.key

      @dir == "desc" ? "descending" : "ascending"
    end

    # Link do cabeçalho: mesma coluna alterna o sentido; outra coluna começa em asc. Volta à página 1.
    def sort_href(col)
      dir = @sort == col.key && @dir == "asc" ? "desc" : "asc"
      query(sort: col.key, dir:, page: nil)
    end

    def page_href(n) = query((@pagination[:param] || :page) => n)

    def cell(row, col)
      return capture_block(col.block, row) if col.block

      v = value_of(row, col.key)
      case col.format
      when :money then v.nil? ? "—" : ss_amount(v.is_a?(Numeric) ? brl(v) : v.to_s)
      when :date then v.respond_to?(:strftime) ? tag.time(v.strftime("%d/%m/%Y"), datetime: v.to_date.iso8601) : v.to_s
      when :number then v.is_a?(Numeric) ? number_with_delimiter(v, delimiter: ".", separator: ",") : v.to_s
      else v.to_s
      end
    end

    def cell_class(col)
      [("r" if col.align == :right), ("num" if %i[money number date].include?(col.format))].compact.join(" ").presence
    end

    def expansion? = !@expansion.nil?
    def expansion_for(row) = capture_block(@expansion, row)
    def bulk? = !@bulk.nil?
    def bulk_html = capture_block(@bulk)
    def selectable? = @selectable
    def span = @columns.size + (@selectable ? 1 : 0) + (expansion? ? 1 : 0)
    def row_key(row, i) = (value_of(row, @row_id) || i).to_s
    def form_id = "#{@id}-bulk"

    # Janela de páginas: 1 … 4 5 6 … 20.
    def page_items
      page = @pagination[:page].to_i
      pages = @pagination[:pages].to_i
      nums = ([1, pages] + ((page - 1)..(page + 1)).to_a).select { _1.between?(1, pages) }.uniq.sort
      nums.each_with_index.flat_map { |n, i| i.positive? && n - nums[i - 1] > 1 ? [:gap, n] : [n] }
    end

    private

    def value_of(row, key)
      case row
      when Hash then row.key?(key.to_sym) ? row[key.to_sym] : row[key.to_s]
      else row.respond_to?(key) ? row.public_send(key) : nil
      end
    end

    def current_params
      @current_params ||= (@params || (helpers.request&.query_parameters rescue {}) || {}).to_h.transform_keys(&:to_s)
    end

    def query(changes)
      merged = current_params.merge(changes.transform_keys(&:to_s)).reject { |_, v| v.nil? || v == "" }
      "?#{merged.to_query}"
    end

    def brl(v) = number_to_currency(v, unit: "R$ ", separator: ",", delimiter: ".", format: "%u%n", negative_format: "−%u%n")

    # Bloco vindo do ERB do app: captura no template que o escreveu.
    def capture_block(block, *args)
      receiver = block.binding.receiver
      receiver.respond_to?(:capture) ? receiver.capture(*args, &block) : block.call(*args)
    end
  end
end
