module Ss
  # Seleção em massa (v1.14.0, par do SsSelectable + SsSelectionBar): o bloco é a lista com as caixas dos itens
  # (input type=checkbox com data-ss-selection-target="item", ou a classe .ss-select-item, e o value = id); a barra
  # escura (.ss-selection-bar) sobe com a mola quando há marcados, com o contador no odômetro, "Limpar seleção" e as
  # ações. Shift + clique marca (ou desmarca) o intervalo desde o último clicado; a caixa "todos" (target all) marca a
  # página inteira e fica indeterminada no meio. Esc limpa. O leitor de tela ouve "3 selecionados".
  #
  #   <%= render(Ss::SelectionBarComponent.new(name: "ids[]", actions: [
  #         { label: "Arquivar", icon: "archive", url: arquivar_pedidos_path, method: :patch },
  #         { label: "Excluir", icon: "trash", url: excluir_pedidos_path, method: :delete, danger: true, confirm: "Excluir os marcados?" },
  #         { label: "Exportar", icon: "download", href: exportar_pedidos_path }])) do %>
  #     <% pedidos.each do |p| %><label class="ss-check"><input type="checkbox" class="ss-select-item" value="<%= p.id %>"> …</label><% end %>
  #   <% end %>
  #
  # Ação com url: vira um <form> (method:, confirm: pede confirmação) que leva um campo name: por item marcado; com
  # href: um link que leva os ids na query (?ids[]=1&ids[]=2). Evento ss-selection:change { ids, count }.
  class SelectionBarComponent < BaseComponent
    def initialize(actions: [], name: "ids[]", label: nil, **rest)
      super(**rest)
      @actions = actions.map { _1.to_h.transform_keys(&:to_sym) }
      @name, @label = name, label
    end

    def call
      tag.div(**root_attrs(class: classes("ss-selection"), data: { controller: "ss-selection", ss_selection_name_value: @name,
                                                                    ss_selection_one_value: ss_t("data_table.selected_one", default: "selecionado"),
                                                                    ss_selection_many_value: ss_t("data_table.selected", default: "selecionados") })) do
        safe_join([content, tag.p(ss_t("interface.selection_range_hint", default: "Shift + clique marca o intervalo"), class: "ss-sr"), bar])
      end
    end

    private

    def bar
      tag.div(class: "ss-selection-bar", role: "region", "aria-label": (@label || ss_t("data_table.selected", default: "selecionados")), hidden: true,
              data: { ss_selection_target: "bar" }) do
        safe_join([
          render(Ss::OdometerComponent.new(text: "0", size: "1em", cents: false, css: "ss-selection-count", data: { ss_selection_target: "count" })),
          tag.span(ss_t("data_table.selected", default: "selecionados"), class: "ss-selection-word", data: { ss_selection_target: "word" }),
          *@actions.map { action(_1) },
          tag.button(type: "button", class: "ss-selection-clear", "aria-label": ss_t("data_table.clear_selection", default: "Limpar seleção"),
                     title: ss_t("data_table.clear_selection", default: "Limpar seleção"), data: { action: "ss-selection#clear" }) { ss_icon("x", size: nil) }
        ])
      end
    end

    def action(a)
      body = safe_join([(ss_icon(a[:icon], size: nil) if a[:icon]), tag.span(a[:label])].compact)
      css = ("is-danger" if a[:danger])
      if a[:href]
        link_to(a[:href], class: css, data: { action: "ss-selection#follow" }) { body }
      else
        form_with(url: a[:url], method: a[:method] || :post, class: "ss-selection-form",
                  data: { action: "submit->ss-selection#fill", turbo_confirm: a[:confirm] }.compact) do
          tag.button(type: "submit", class: css) { body }
        end
      end
    end
  end
end
