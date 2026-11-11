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
  #
  # v0.18:
  # - row_attrs: atributos de cada <tr>: Hash fixo ou ->(row) { { id: dom_id(row), data: { edit_url: … }, class: "…" } }
  #   (data:/aria: somam aos da tabela; class: soma).
  # - empty_art: false = vazio compacto, só a frase, sem a ilustração (tabela dentro de um card).
  # - t.actions(label: "Ações", reveal: true) { |row| … }: última coluna com as ações da linha, no hover
  #   do computador e sempre à vista no toque (as regras do Ss::RowActionsComponent); a célula não entra
  #   na escolha de colunas.
  #
  # v0.19:
  # - select_name: o nome das caixas da seleção (padrão "ids[]"; ex. "pedido_ids[]" para o controller do app).
  # - bulk_method: o método do form da barra de seleção (padrão :post; :patch, :delete). Os botões da barra
  #   podem trocar o destino com formaction: (Ss::ButtonComponent(type: :submit, formaction:, name:, value:)).
  #
  # v0.20 (o que o minhas-vendas e o meu-gestor pediram; pares do SsDataTable):
  # - row_href: ->(row) { pedido_path(row) } (ou um texto fixo): a linha inteira vira link (tr.is-link com
  #   data-href e tabindex=0). Clique fora de <a>, <button>, campo, <summary>/<details> navega (Turbo quando
  #   houver); Enter com o foco na linha também; Ctrl/⌘ ou o botão do meio abrem em outra aba. A 1ª coluna
  #   continua sendo o link de verdade para o leitor de tela (ponha um link_to nela). Par: SsDataRow(onTap:).
  # - t.column(..., sticky: true): a coluna fica parada ao rolar de lado (só a 1ª coluna de dados; com
  #   selectable:/expansão a caixa e a seta rolam). Par: SsDataTable(stickyFirstColumn: true).
  # - t.column(..., header: "<b>…</b>" ou html_safe): o cabeçalho montado no lugar do texto; o label: continua
  #   no rótulo do celular e na escolha de colunas. Par: SsDataColumn(header:).
  # - t.total(:valor, ss_amount(…)) ou t.total(:valor) { |rows| … }: a linha de total no <tfoot> (negrito, fundo
  #   do campo); a 1ª coluna sem total recebe "Total" (componentes_ui.data_table.total; t.total(:cliente, "Geral")
  #   troca). t.footer { |rows| … }: um <tfoot> livre numa célula só. Par: SsDataTable(footer:).
  # - flat: true: sem a moldura de card (tabela dentro de um card com título). Par: SsDataTable(flat: true).
  # - v0.20.4: stack: false mantém a tabela no celular (rola de lado, a coluna sticky: funciona) em vez de virar
  #   um card por linha (escala de 14 dias, grade de horários). Par: SsDataTable(stack: false).
  # - Linha apagada: row_attrs: ->(r) { { class: ("is-dimmed" if r.inativo?) } } (tr.is-dimmed). Par: SsDataRow(dimmed:).
  class DataTableComponent < BaseComponent
    Column = Struct.new(:key, :label, :align, :sortable, :format, :hideable, :block, :sticky, :header, keyword_init: true)

    attr_reader :columns, :id, :caption

    def initialize(rows:, id:, caption:, sort: nil, dir: nil, sort_rows: false, selectable: false, bulk_url: nil,
                   row_id: :id, density: :comfortable, pagination: nil, params: nil, empty: nil, currency: nil,
                   max_height: nil, show_caption: false, tools: true, row_attrs: nil, empty_art: true, select_name: "ids[]",
                   bulk_method: :post, row_href: nil, flat: false, stack: true, **opts)
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
      @empty = empty || ss_t("data_table.empty", default: "Nada por aqui ainda.")
      @currency = currency
      @max_height = max_height
      @show_caption = show_caption
      @tools = tools
      @row_attrs = row_attrs
      @empty_art = empty_art
      @select_name = select_name.to_s
      @bulk_method = bulk_method.to_s.downcase.presence || "post"
      @row_href = row_href
      @flat = flat
      @stack = stack
      @totals = {}
      @columns = []
    end

    def flat? = @flat
    def stack? = @stack

    def column(key, label, align: nil, sortable: false, format: nil, hideable: true, sticky: false, header: nil, &block)
      align ||= %i[money number].include?(format) ? :right : :left
      @columns << Column.new(key: key.to_s, label:, align: align.to_sym, sortable:, format:, hideable:, block:,
                             sticky: sticky && @columns.empty?, header:)
      nil
    end

    # Linha de total (v0.20): t.total(:valor, "R$ 10") ou t.total(:valor) { |rows| … }.
    def total(key, value = nil, &block)
      @totals[key.to_s] = block || value
      nil
    end

    # <tfoot> livre (v0.20): t.footer { |rows| … } numa célula que ocupa a linha.
    def footer(&block) = (@footer = block) && nil

    def totals? = @totals.any?
    def footer? = !@footer.nil?
    def footer_html = capture_block(@footer, rows)

    # Célula do total da coluna: o valor dado, ou "Total" na 1ª coluna sem valor.
    def total_cell(col)
      v = @totals[col.key]
      return (v.respond_to?(:call) ? capture_block(v, rows) : v) if @totals.key?(col.key)

      tt("total", default: "Total") if col.equal?(@columns.first)
    end

    def header_html(col) = col.header.nil? ? col.label : col.header

    def expansion(&block) = (@expansion = block) && nil

    # Coluna de ações da linha (v0.18): cabeçalho só para leitor de tela, células à direita.
    def actions(label: nil, reveal: true, &block)
      label ||= tt("actions", default: "Ações")
      reveal_block = lambda do |row|
        inner = capture_block(block, row)
        tag.div(inner, class: ["ss-row-actions", ("is-reveal" if reveal)].compact.join(" "))
      end
      @columns << Column.new(key: "_actions", label:, align: :right, sortable: false, format: :actions, hideable: false, block: reveal_block)
      nil
    end

    def empty_class = @empty_art ? "ss-empty" : "ss-empty ss-empty-plain is-compact"

    # Atributos do <tr> da linha: os do app (row_attrs:) + o alvo do ss-table.
    def tr_attrs(row)
      extra = @row_attrs.respond_to?(:call) ? @row_attrs.call(row) : @row_attrs
      extra = extra.to_h.transform_keys(&:to_sym)
      data = extra.delete(:data).to_h.merge(ss_table_target: "row")
      href = @row_href.respond_to?(:call) ? @row_href.call(row) : @row_href
      if href.present?
        data[:href] = href
        data[:action] = [data[:action], "click->ss-table#go auxclick->ss-table#go keydown->ss-table#go"].compact.join(" ")
        extra[:class] = [extra[:class], "is-link"].compact.join(" ")
        extra[:tabindex] ||= 0
      end
      { **extra, data: }
    end
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
      return col.block.call(row) if col.format == :actions
      return capture_block(col.block, row) if col.block

      v = value_of(row, col.key)
      case col.format
      when :money then v.nil? ? "—" : ss_amount(v.is_a?(Numeric) ? brl(v) : v.to_s)
      when :date then v.respond_to?(:strftime) ? tag.time(ss_date(v), datetime: v.to_date.iso8601) : v.to_s
      when :number then v.is_a?(Numeric) ? ss_number(v, precision: v.is_a?(Integer) ? 0 : decimals_of(v)) : v.to_s
      else v.to_s
      end
    end

    def cell_class(col)
      [("r" if col.align == :right), ("num" if %i[money number date].include?(col.format)),
       ("ss-dt-actions" if col.format == :actions), ("is-sticky" if col.sticky)].compact.join(" ").presence
    end

    def expansion? = !@expansion.nil?
    def expansion_for(row) = capture_block(@expansion, row)
    def bulk? = !@bulk.nil?
    def bulk_html = capture_block(@bulk)
    def selectable? = @selectable
    def span = @columns.size + (@selectable ? 1 : 0) + (expansion? ? 1 : 0)
    def row_key(row, i) = (value_of(row, @row_id) || i).to_s
    def form_id = "#{@id}-bulk"
    def select_name = @select_name
    def bulk_method = @bulk_method.to_sym

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

    # Dinheiro no idioma da página e na moeda (currency: ou ComponentesUi.config.currency).
    def brl(v) = ss_money(v, currency: @currency, minus: "−")

    # Casas decimais de um número não inteiro (até 6): 2.5 → 1, 1234.56 → 2.
    def decimals_of(v)
      s = v.to_f.round(6).to_s
      s.include?("e") ? 2 : [s.split(".").last.sub(/0+\z/, "").size, 0].max
    end

    # Texto da tabela (componentes_ui.data_table.*), com o pt-BR de reserva.
    def tt(key, **opts) = ss_t("data_table.#{key}", **opts)

    # Bloco vindo do ERB do app: captura no template que o escreveu.
    def capture_block(block, *args)
      receiver = block.binding.receiver
      receiver.respond_to?(:capture) ? receiver.capture(*args, &block) : block.call(*args)
    end
  end
end
