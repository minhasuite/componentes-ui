module Ss
  # Linhas repetíveis de formulário (v0.20, par do SsRepeater): itens do pedido, telefones, parcelas. Cada
  # linha ganha o × de tirar e o "Adicionar" põe uma linha nova a partir do <template> (Stimulus ss-repeater).
  #
  #   <%= render(Ss::RepeaterComponent.new(add_label: "Adicionar item", min: 1)) do |r| %>
  #     <%= f.fields_for :itens do |i| %>
  #       <%= r.row do %><%= i.ss_text_field :produto %><%= i.ss_number_field :qtd %><%= i.hidden_field :_destroy %><% end %>
  #     <% end %>
  #     <% r.with_template do %>
  #       <%= f.fields_for :itens, Item.new, child_index: "NEW_RECORD" do |i| %>
  #         <%= r.row do %><%= i.ss_text_field :produto %><%= i.ss_number_field :qtd %><% end %>
  #       <% end %>
  #     <% end %>
  #   <% end %>
  #
  # - O marcador NEW_RECORD (placeholder:) vira um número único em cada linha nova (o índice do
  #   accepts_nested_attributes_for).
  # - Tirar: linha que já existe (tem o hidden [_destroy]) é marcada _destroy=1 e escondida; linha nova sai.
  # - min: o × some quando sobram só min linhas. label: nome do grupo para o leitor de tela.
  # - Eventos ss-repeater:add e ss-repeater:remove (detail: { row }) para o app recalcular total.
  #
  # v0.20.3 (par do SsRepeater(header:, flex:)):
  # - columns: as colunas de todas as linhas (e do cabeçalho), em telas a partir de 48rem: um texto de
  #   grid-template-columns ("minmax(0,4fr) 2fr 6rem") ou uma lista de larguras ([4, 2, "6rem"]; número = fr).
  #   No celular as linhas voltam à grade automática (um campo por linha quando não cabe).
  # - header: ["Produto", "Qtd", "Unitário", …]: o cabeçalho uma vez em cima (só em tela larga), na mesma
  #   grade; nil numa posição deixa a célula vazia; { label:, align: :end } alinha à direita. Com header:,
  #   hide_labels: vale true por padrão: os rótulos dos campos (.ss-field > label, legend, .ss-label) ficam só
  #   para o leitor de tela em tela larga e o × fica no meio da linha; no celular os rótulos voltam.
  # - r.row(columns:, class:, data:, id:, …): colunas só dessa linha e atributos no .ss-repeater-row
  #   (data: soma ao alvo do ss-repeater, class: soma). Sem Tailwind de grade no produto:
  #     <%= r.row(data: { auto_price: 1 }) do %> … os campos direto, cada um vira uma coluna … <% end %>
  class RepeaterComponent < BaseComponent
    renders_one :template

    def initialize(add_label: nil, remove_label: nil, min: 0, placeholder: "NEW_RECORD", label: nil, columns: nil, header: nil,
                   hide_labels: nil, **rest)
      super(**rest)
      @add_label, @remove_label, @min, @placeholder, @label = add_label, remove_label, min.to_i, placeholder, label
      @columns, @header = self.class.grid(columns), header
      @hide_labels = hide_labels.nil? ? header.present? : hide_labels
    end

    # columns: → valor do grid-template-columns ("2fr 1fr 6rem"); número vira fr.
    def self.grid(columns)
      case columns
      when nil, "" then nil
      when Array then columns.map { |c| c.is_a?(Numeric) ? "minmax(0, #{c}fr)" : c.to_s }.join(" ")
      else columns.to_s
      end
    end

    def add_label = @add_label || ss_t("repeater.add", default: "Adicionar")
    def remove_label = @remove_label || ss_t("repeater.remove", default: "Remover linha")

    # Uma linha: os campos do bloco + o × de tirar.
    def row(columns: nil, **attrs, &block)
      inner = block.binding.receiver.respond_to?(:capture) ? block.binding.receiver.capture(&block) : block.call
      attrs = attrs.transform_keys(&:to_sym)
      css = ["ss-repeater-row", attrs.delete(:class)].flatten.compact.join(" ")
      data = attrs.delete(:data).to_h.merge(ss_repeater_target: "row")
      cols = self.class.grid(columns)
      tag.div(class: css, data:, **attrs) do
        safe_join([
          tag.div(inner, class: "ss-repeater-fields", style: ("--ss-repeater-cols: #{cols}" if cols)),
          tag.button(ss_icon("x", size: :xs), type: "button", class: "ss-icon-btn is-sm ss-repeater-remove", title: remove_label,
                                              "aria-label": remove_label, data: { action: "ss-repeater#remove" })
        ])
      end
    end

    def call
      list = content # roda o bloco (linhas e o template)
      style = [("--ss-repeater-cols: #{@columns}" if @columns), @attrs[:style]].compact.join("; ").presence
      tag.div(**root_attrs(class: classes("ss-repeater", ("is-labels-hidden" if @hide_labels), ("has-header" if @header.present?)),
                           role: "group", "aria-label": @label, style:,
                           data: { controller: "ss-repeater", ss_repeater_placeholder_value: @placeholder, ss_repeater_min_value: @min,
                                   ss_repeater_added_value: ss_t("repeater.added", default: "Linha adicionada"),
                                   ss_repeater_removed_value: ss_t("repeater.removed", default: "Linha removida") })) do
        safe_join([
          header_html,
          tag.div(list, class: "ss-repeater-list", data: { ss_repeater_target: "list" }),
          (tag.template(template, data: { ss_repeater_target: "template" }) if template?),
          tag.button(type: "button", class: "ss-btn ss-btn-ghost ss-btn-sm ss-repeater-add", data: { action: "ss-repeater#add" }) do
            safe_join([ss_icon("plus", size: :xs), tag.span(add_label)])
          end,
          tag.p(class: "ss-sr", role: "status", data: { ss_repeater_target: "live" })
        ].compact)
      end
    end

    private

    # Cabeçalho único (só visual: os campos continuam com o rótulo para o leitor de tela).
    def header_html
      return nil if @header.blank?

      cells = Array(@header).map do |h|
        h = { label: h } unless h.is_a?(Hash)
        tag.span(h[:label], class: ["ss-repeater-head-cell", ("is-end" if h[:align].to_s == "end")].compact.join(" "))
      end
      tag.div(class: "ss-repeater-head", "aria-hidden": "true") do
        safe_join([tag.div(safe_join(cells), class: "ss-repeater-head-cells"), tag.span(class: "ss-repeater-head-x")])
      end
    end
  end
end
