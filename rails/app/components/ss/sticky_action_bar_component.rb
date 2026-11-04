module Ss
  # Barra "Salvar · Cancelar" que aparece fixa embaixo quando o form fica sujo, e
  # avisa ao sair com alterações (controller ss-dirty). Vai DENTRO do <form>.
  #   <%= form_with model: @cliente do |f| %> … <%= render Ss::StickyActionBarComponent.new %> <% end %>
  #   render Ss::StickyActionBarComponent.new(message: "Pedido alterado") { botões próprios }
  # always: true mostra sempre (sem esperar alteração).
  class StickyActionBarComponent < BaseComponent
    def initialize(save_label: nil, cancel_label: nil, message: nil,
                   confirm: nil, always: false, **opts)
      super(**opts)
      @save_label = save_label || ss_t("common.save", default: "Salvar")
      @cancel_label = cancel_label || ss_t("common.cancel", default: "Cancelar")
      @message = message || ss_t("sticky_action_bar.message", default: "Alterações não salvas")
      # Pergunta ao sair com o form sujo (o controller ss-dirty usa no confirm()).
      @confirm = confirm || ss_t("sticky_action_bar.confirm", default: "Há alterações não salvas. Sair mesmo assim?")
      @always = always
    end
  end
end
