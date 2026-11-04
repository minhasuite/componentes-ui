module Ss
  # Barra "Salvar · Cancelar" que aparece fixa embaixo quando o form fica sujo, e
  # avisa ao sair com alterações (controller ss-dirty). Vai DENTRO do <form>.
  #   <%= form_with model: @cliente do |f| %> … <%= render Ss::StickyActionBarComponent.new %> <% end %>
  #   render Ss::StickyActionBarComponent.new(message: "Pedido alterado") { botões próprios }
  # always: true mostra sempre (sem esperar alteração).
  class StickyActionBarComponent < BaseComponent
    def initialize(save_label: "Salvar", cancel_label: "Cancelar", message: "Alterações não salvas",
                   confirm: nil, always: false, **opts)
      super(**opts)
      @save_label = save_label
      @cancel_label = cancel_label
      @message = message
      @confirm = confirm
      @always = always
    end
  end
end
