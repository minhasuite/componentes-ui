module Ss
  # Excluir de verdade: <dialog class="ss-dialog is-danger"> que só libera o botão
  # quando a pessoa digita o nome (controller ss-confirm). O form vai com method (delete).
  #   render Ss::ConfirmDangerComponent.new(name: "Mercado Bom Preço", url: cliente_path(c),
  #     title: "Excluir cliente?", text: "Some com os pedidos e títulos dele. Não dá para desfazer.")
  class ConfirmDangerComponent < BaseComponent
    attr_reader :name, :url, :title, :text, :trigger_label, :confirm_label

    def initialize(name:, url:, title: "Excluir?", text: "Isso não pode ser desfeito.", method: :delete,
                   trigger_label: "Excluir", confirm_label: "Excluir para sempre", **opts)
      super(**opts)
      @name = name
      @url = url
      @title = title
      @text = text
      @http_method = method
      @trigger_label = trigger_label
      @confirm_label = confirm_label
    end

    def uid = @uid ||= "ss-confirm-#{object_id}"
  end
end
