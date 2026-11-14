module Ss
  # Barra "Salvar · Cancelar" que aparece fixa embaixo quando o form fica sujo, e
  # avisa ao sair com alterações (controller ss-dirty). Vai DENTRO do <form>.
  #   <%= form_with model: @cliente do |f| %> … <%= render Ss::StickyActionBarComponent.new %> <% end %>
  #   render Ss::StickyActionBarComponent.new(message: "Pedido alterado") { botões próprios }
  # always: true mostra sempre (sem esperar alteração), também depois de voltar ao valor original,
  # Cancelar ou enviar (v0.22.1: data-ss-dirty-always-value; o "sujo" só cuida do aviso ao sair).
  # v0.20: with_summary { … } põe conteúdo livre à esquerda no lugar da mensagem (o resumo do pedido:
  # "3 itens · R$ 120,00"), sem o ponto amarelo; par do SsStickyActionBar(summary:).
  #   render(Ss::StickyActionBarComponent.new(always: true)) do |b|
  #     b.with_summary { tag.span("3 itens") + ss_amount(ss_money(120)) }
  #     render Ss::ButtonComponent.new(label: "Fechar pedido", type: :submit, size: :sm)
  #   end
  class StickyActionBarComponent < BaseComponent
    renders_one :summary
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
