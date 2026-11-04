module Ss
  # Lista à esquerda, detalhe à direita num turbo-frame. Os links da lista usam
  # data-turbo-frame="<frame_id>" (o controller marca o item atual). No celular empilha:
  # com detalhe carregado, o detalhe vira a tela, com o botão de voltar.
  #
  #   render Ss::SplitViewComponent.new(frame_id: "pedido") do |s|
  #     s.with_list { render partial: "pedidos/linha", collection: @pedidos }   # <a href=… data-turbo-frame="pedido">
  #     s.with_detail { render @pedido if @pedido }                           # conteúdo inicial do frame
  #     s.with_empty { "Escolha um pedido" }
  #   end
  class SplitViewComponent < BaseComponent
    renders_one :list
    renders_one :detail
    renders_one :empty

    def initialize(frame_id: "detalhe", back_label: "Voltar", list_label: "Lista", **opts)
      super(**opts)
      @frame_id = frame_id
      @back_label = back_label
      @list_label = list_label
    end
  end
end
