module Ss
  # Ingresso/comprovante: recortes semicirculares nas laterais e linha tracejada
  # entre o topo (conteúdo) e a base (with_stub). Imprime limpo (sem sombra).
  #   render Ss::TicketCardComponent.new do |t| %> …topo… <% t.with_stub do %> …base… <% end %><% end
  class TicketCardComponent < BaseComponent
    renders_one :stub

    def initialize(tone: nil, **opts)
      super(**opts)
      @tone = tone
    end

    def call
      tag.article(**root_attrs(class: classes("ss-ticket", ("is-accent" if @tone.to_s == "accent")))) do
        safe_join([tag.div(content, class: "ss-ticket-top"), (tag.div(stub, class: "ss-ticket-stub") if stub?)].compact)
      end
    end
  end
end
