module Ss
  # Painel lateral num <dialog> para ver/editar sem sair da lista. Abre:
  #  - por link: <a href="/pedidos/1" data-turbo-frame="<frame_id>"> (o painel abre e mostra "carregando");
  #  - por botão: <button data-ss-drawer-open="<id>">.
  # Esc, o X e o clique no fundo fecham.
  #
  #   render Ss::DrawerComponent.new(id: "painel", title: "Pedido", frame_id: "painel_frame") do
  #     (conteúdo inicial do frame, opcional)
  #   end
  #
  # v1.14.0: detents: [0.33, 0.5, 1] (par do showSsSheet(detents:)): no celular (até 40rem) o painel vira a folha de
  # baixo com essas alturas (fração da tela; a 1ª é onde abre, ou detent: escolhe); arrastar a alça leva de uma à
  # outra e solta com a mola (--ss-bounce), puxar abaixo da menor fecha; na alça, ↑ ↓ (Home/End) andam pelas
  # alturas e o leitor de tela ouve "50% da tela". No computador continua o painel lateral.
  class DrawerComponent < BaseComponent
    renders_one :footer

    def initialize(id: "ss-drawer", title: nil, frame_id: nil, open: false, close_label: nil, width: nil, detents: nil, detent: nil, **opts)
      super(**opts)
      @id = id
      @title = title
      @frame_id = frame_id
      @open = open
      @close_label = close_label || ss_t("common.close", default: "Fechar")
      @width = width
      @detents = detents && detents.map(&:to_f).select { _1.positive? && _1 <= 1 }.uniq.sort.presence
      @detent = @detents && (detent ? @detents.min_by { (_1 - detent.to_f).abs } : @detents.first)
    end

    def detents? = !@detents.nil?
    def detent_pct(v) = (v * 100).round

    def style
      [("--w:#{@width}" if @width), ("--ss-detent:#{@detent}" if detents?)].compact.join(";").presence
    end
  end
end
