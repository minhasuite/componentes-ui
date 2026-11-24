module Ss
  # Remoção otimista com desfazer animado (v1.9, par do SsUndoableRemoval): embrulha o item e liga o controller
  # ss-undoable. O form de remover dentro dele leva FORM_DATA (ou data-action="submit->ss-undoable#remove"):
  # ao enviar, o item sai encolhendo, o aviso com "Desfazer" e a contagem entra na pilha (#ss-toasts) e, se o
  # tempo passar sem desfazer, o form vai de verdade. Falhou: o item volta e aparece o aviso de erro.
  #
  #   <%= render Ss::UndoableRemovalComponent.new(message: "Pedido 1042 excluído", tag: :li, css: "ss-list-item") do %>
  #     …
  #     <%= button_to "Excluir", pedido_path(p), method: :delete, class: "ss-btn ss-btn-ghost",
  #                   form: { data: Ss::UndoableRemovalComponent::FORM_DATA } %>
  #   <% end %>
  #
  # tag: o elemento do item (:div padrão, :li numa lista, :tr numa tabela). duration: segundos do desfazer (5).
  # error: o texto do aviso de falha. Os textos padrão vêm do idioma da página (componentes_ui.undoable_removal).
  class UndoableRemovalComponent < BaseComponent
    FORM_DATA = { action: "submit->ss-undoable#remove" }.freeze

    def initialize(message:, tag: :div, duration: 5, undo_label: nil, error: nil, **rest)
      super(**rest)
      @message, @tag, @duration = message, tag.to_sym, duration
      @undo_label, @error = undo_label, error
    end

    def call
      content_tag(@tag, content, **root_attrs(class: classes("ss-undoable"), data: {
        controller: "ss-undoable",
        ss_undoable_message_value: @message,
        ss_undoable_label_value: @undo_label || ss_t("undoable_removal.undo", default: "Desfazer"),
        ss_undoable_close_value: ss_t("undoable_removal.close", default: "Fechar aviso"),
        ss_undoable_error_value: @error || ss_t("undoable_removal.error", default: "Não deu para concluir. Tente de novo."),
        ss_undoable_duration_value: @duration
      }))
    end
  end
end
