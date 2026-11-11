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
  class RepeaterComponent < BaseComponent
    renders_one :template

    def initialize(add_label: nil, remove_label: nil, min: 0, placeholder: "NEW_RECORD", label: nil, **rest)
      super(**rest)
      @add_label, @remove_label, @min, @placeholder, @label = add_label, remove_label, min.to_i, placeholder, label
    end

    def add_label = @add_label || ss_t("repeater.add", default: "Adicionar")
    def remove_label = @remove_label || ss_t("repeater.remove", default: "Remover linha")

    # Uma linha: os campos do bloco + o × de tirar.
    def row(&block)
      inner = block.binding.receiver.respond_to?(:capture) ? block.binding.receiver.capture(&block) : block.call
      tag.div(class: "ss-repeater-row", data: { ss_repeater_target: "row" }) do
        safe_join([
          tag.div(inner, class: "ss-repeater-fields"),
          tag.button(ss_icon("x", size: :xs), type: "button", class: "ss-icon-btn is-sm ss-repeater-remove", title: remove_label,
                                              "aria-label": remove_label, data: { action: "ss-repeater#remove" })
        ])
      end
    end

    def call
      list = content # roda o bloco (linhas e o template)
      tag.div(**root_attrs(class: classes("ss-repeater"), role: "group", "aria-label": @label,
                           data: { controller: "ss-repeater", ss_repeater_placeholder_value: @placeholder, ss_repeater_min_value: @min,
                                   ss_repeater_added_value: ss_t("repeater.added", default: "Linha adicionada"),
                                   ss_repeater_removed_value: ss_t("repeater.removed", default: "Linha removida") })) do
        safe_join([
          tag.div(list, class: "ss-repeater-list", data: { ss_repeater_target: "list" }),
          (tag.template(template, data: { ss_repeater_target: "template" }) if template?),
          tag.button(type: "button", class: "ss-btn ss-btn-ghost ss-btn-sm ss-repeater-add", data: { action: "ss-repeater#add" }) do
            safe_join([ss_icon("plus", size: :xs), tag.span(add_label)])
          end,
          tag.p(class: "ss-sr", role: "status", data: { ss_repeater_target: "live" })
        ].compact)
      end
    end
  end
end
