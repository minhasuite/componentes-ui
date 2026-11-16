module Ss
  # Separador de dia numa conversa (v0.26, par do SsChatDivider): rótulo pequeno numa pílula, centrado entre
  # duas linhas finas. Vai dentro do log do Ss::ChatComponent (bloco), entre as mensagens.
  #
  #   <%= render Ss::ChatDividerComponent.new(label: "Hoje") %>
  #   <div class="ss-chat-divider" role="separator" aria-label="Hoje"><span>Hoje</span></div>
  class ChatDividerComponent < BaseComponent
    def initialize(label:, **rest)
      super(**rest)
      @label = label
    end

    def call
      tag.div(**root_attrs(class: classes("ss-chat-divider"), role: "separator", "aria-label": @label)) { tag.span(@label) }
    end
  end
end
