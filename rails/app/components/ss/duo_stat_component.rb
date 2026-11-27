module Ss
  # Duas estatísticas lado a lado (v1.10, par do SsDuoStat): despesa × receita. A ativa ganha o fundo no gradiente
  # da marca e o texto claro; clicar na outra troca (a pílula de fundo passa de um lado para o outro com a mola e o
  # ícone gira).
  #
  #   render Ss::DuoStatComponent.new(index: 0, items: [
  #     { label: "Despesas", value: ss_money(3210.4), icon: "arrow-up", href: "?lado=despesas" },
  #     { label: "Receitas", value: ss_money(5100), icon: "arrow-down", href: "?lado=receitas" }])
  #
  # items: exatamente 2, cada um label:, value: (texto pronto), icon: (opcional) e href: (vira link com
  # aria-current; sem href, <button aria-pressed> que troca no próprio lugar). name: põe o índice num hidden para o
  # formulário. Evento ss-duo:change { index }. Reduzir movimento: troca sem deslizar.
  class DuoStatComponent < BaseComponent
    def initialize(items:, index: 0, name: nil, **rest)
      super(**rest)
      @items = Array(items).first(2).map { |i| i.to_h.symbolize_keys }
      raise ArgumentError, "Ss::DuoStatComponent: items: precisa de 2 itens" unless @items.size == 2

      @index = index.to_i.clamp(0, 1)
      @name = name
    end

    def call
      tag.div(**root_attrs(class: classes("ss-duo"), role: "group", style: "--x:#{@index}",
                           data: { controller: "ss-duo", ss_duo_index_value: @index })) do
        safe_join([
          tag.span(class: "ss-duo-pill", "aria-hidden": "true"),
          *@items.each_with_index.map { |it, i| side(it, i) },
          (tag.input(type: "hidden", name: @name, value: @index, data: { ss_duo_target: "input" }) if @name)
        ].compact)
      end
    end

    private

    def side(it, i)
      on = i == @index
      body = safe_join([
        (ss_icon(it[:icon], size: nil, css: "ss-duo-ico") if it[:icon]),
        tag.span(class: "ss-duo-text") { safe_join([tag.span(it[:label], class: "ss-duo-label"), tag.span(it[:value], class: "ss-duo-value num")]) }
      ].compact)
      attrs = { class: ["ss-duo-side", ("is-on" if on)].compact.join(" "), "aria-label": "#{it[:label]}: #{it[:value]}",
                data: { ss_duo_target: "side", index: i, action: "ss-duo#pick" } }
      if it[:href]
        link_to(body, it[:href], **attrs, "aria-current": (on ? "true" : nil))
      else
        tag.button(body, **attrs, type: :button, "aria-pressed": on.to_s)
      end
    end
  end
end
