module Ss
  # Cartões empilhados (v1.10, par do SsCardStack): só a borda de cima dos de trás aparece; um clique abre em
  # lista com a mola (passa um pouco e assenta), outro fecha. Clicar no meio do movimento inverte dali.
  #
  #   render(Ss::CardStackComponent.new(card_height: 180)) do |s|
  #     @cartoes.each { |c| s.with_card { render "cartao", cartao: c } }
  #   end
  #
  # card_height: px de cada cartão (180). peek: px da borda que aparece (14). gap: px entre eles aberto (12).
  # initially_open: começa aberto. Evento ss-card-stack:change { open } (o onChanged). O 1º cartão fica na frente.
  # Fechado, um botão cobre a pilha ("Abrir 3 cartões"); aberto, os cartões ficam usáveis (links, botões) e o
  # botão "Fechar cartões" vai para baixo deles. Os de trás ficam inert enquanto fechado.
  # Reduzir movimento: abre e fecha sem animar.
  class CardStackComponent < BaseComponent
    renders_many :cards

    def initialize(card_height: 180, peek: 14, gap: 12, initially_open: false, **rest)
      super(**rest)
      @h, @peek, @gap, @open = card_height.to_i.clamp(40, 800), peek.to_i.clamp(0, 60), gap.to_i.clamp(0, 60), initially_open
    end

    def n = cards.size
    def open_label = ss_t("card_stack.open", count: n, default: "Abrir %{count} cartões")
    def close_label = ss_t("card_stack.close", default: "Fechar cartões")

    def call
      closed_h = (n - 1) * @peek + @h
      open_h = n * @h + (n - 1) * @gap
      style = "--n:#{n};--h:#{@h}px;--peek:#{@peek}px;--gap:#{@gap}px;--hc:#{closed_h}px;--ho:#{open_h}px"
      tag.div(**root_attrs(class: classes("ss-cstack", ("is-open" if @open)), style:,
                           data: { controller: "ss-card-stack", ss_card_stack_open_label_value: open_label,
                                   ss_card_stack_close_label_value: close_label })) do
        safe_join([
          tag.ul(class: "ss-cstack-list", role: "list") do
            safe_join(cards.each_with_index.map do |c, i|
              sc = (1 - 0.05 * i).round(3)
              op = (i > 2 ? 0 : 1 - 0.12 * i).round(3)
              tag.li(c, class: "ss-cstack-card", style: "--i:#{i};--sc:#{sc};--op:#{op};z-index:#{n - i}",
                        inert: (!@open && i.positive?) || nil, data: { ss_card_stack_target: "card" })
            end)
          end,
          tag.button(type: :button, class: "ss-cstack-toggle", "aria-expanded": @open.to_s,
                     data: { action: "ss-card-stack#toggle", ss_card_stack_target: "toggle" }) do
            safe_join([ss_icon("chevron-up", size: nil, css: "ss-cstack-ico"),
                       tag.span(@open ? close_label : open_label, class: "ss-cstack-text", data: { ss_card_stack_target: "text" })])
          end
        ])
      end
    end
  end
end
