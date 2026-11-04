module Ss
  # Painel lateral num <dialog> para ver/editar sem sair da lista. Abre:
  #  - por link: <a href="/pedidos/1" data-turbo-frame="<frame_id>"> (o painel abre e mostra "carregando");
  #  - por botão: <button data-ss-drawer-open="<id>">.
  # Esc, o X e o clique no fundo fecham.
  #
  #   render Ss::DrawerComponent.new(id: "painel", title: "Pedido", frame_id: "painel_frame") do
  #     (conteúdo inicial do frame, opcional)
  #   end
  class DrawerComponent < BaseComponent
    renders_one :footer

    def initialize(id: "ss-drawer", title: nil, frame_id: nil, open: false, close_label: "Fechar", width: nil, **opts)
      super(**opts)
      @id = id
      @title = title
      @frame_id = frame_id
      @open = open
      @close_label = close_label
      @width = width
    end
  end
end
