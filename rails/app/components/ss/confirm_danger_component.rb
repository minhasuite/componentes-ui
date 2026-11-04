module Ss
  # Excluir de verdade: <dialog class="ss-dialog is-danger"> que só libera o botão
  # quando a pessoa digita o nome (controller ss-confirm). O form vai com method (delete).
  #   render Ss::ConfirmDangerComponent.new(name: "Mercado Bom Preço", url: cliente_path(c),
  #     title: "Excluir cliente?", text: "Some com os pedidos e títulos dele. Não dá para desfazer.")
  class ConfirmDangerComponent < BaseComponent
    attr_reader :name, :url, :title, :text, :trigger_label, :confirm_label, :cancel_label

    def initialize(name:, url:, title: nil, text: nil, method: :delete,
                   trigger_label: nil, confirm_label: nil, cancel_label: nil, **opts)
      super(**opts)
      @name = name
      @url = url
      @title = title || ss_t("confirm_danger.title", default: "Excluir?")
      @text = text || ss_t("confirm_danger.text", default: "Isso não pode ser desfeito.")
      @http_method = method
      @trigger_label = trigger_label || ss_t("confirm_danger.trigger", default: "Excluir")
      @confirm_label = confirm_label || ss_t("confirm_danger.confirm", default: "Excluir para sempre")
      @cancel_label = cancel_label || ss_t("common.cancel", default: "Cancelar")
    end

    # "Digite <b>nome</b> para confirmar" com o nome em negrito (escapado).
    def type_to_confirm
      before, after = ss_t("confirm_danger.type", default: "Digite %{name} para confirmar", name: "\u0000").split("\u0000", 2)
      safe_join([before, tag.b(name), after])
    end

    def uid = @uid ||= "ss-confirm-#{object_id}"
  end
end
