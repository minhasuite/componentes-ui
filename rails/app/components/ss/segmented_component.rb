module Ss
  # Seletor segmentado (v0.23, par do SsSegmented): o .ss-seg com a pílula que desliza, montado sem <button>/<a> à mão.
  #
  #   render Ss::SegmentedComponent.new(label: "Período", items: [
  #     { label: "Dia", href: "?p=dia", current: true }, { label: "Semana", href: "?p=semana" }])            (links)
  #   render Ss::SegmentedComponent.new(label: "Andar", scroll: true, items: andares.map { |a|
  #     { label: a.nome, pressed: a == atual, data: { action: "planta#andar", andar: a.id } } })            (botões do JS)
  #   render Ss::SegmentedComponent.new(label: "Modo", items: [{ label: "Frio", name: "mode", value: "cool", type: :submit }])
  #
  # items: label: (ou html: já seguro), icon:, href: (vira <a> com aria-current), sem href vira <button> com aria-pressed
  # (type: :submit + name:/value:/form: envia o form); pressed:/current: marca o escolhido; data:, aria:, title:, id:,
  # disabled: vão no item. label: do grupo é o aria-label (role="group"). scroll: true = itens do tamanho do texto
  # numa faixa que rola (abas leves, ex. andares de uma planta); sem scroll, até 4 itens de largura igual.
  # O JS do produto troca só o aria-pressed/aria-selected/aria-current: a pílula segue pelo CSS.
  # v0.23.3: role: no componente troca o role="group" (ex. "tablist") e role: no item vai nele (ex. "tab", com aria: { selected: }).
  class SegmentedComponent < BaseComponent
    def initialize(items:, label: nil, scroll: false, **rest)
      super(**rest)
      @items, @label, @scroll = items, label, scroll
    end

    def call
      tag.div(**{ role: "group" }.merge(root_attrs(class: classes("ss-seg", ("is-scroll" if @scroll)), "aria-label": @label))) do
        safe_join(@items.map { |i| item(i.to_h) })
      end
    end

    private

    def item(i)
      body = safe_join([(icon_svg(i[:icon]) if i[:icon]), (i[:html] || tag.span(i[:label]))].compact)
      common = { data: i[:data], title: i[:title], id: i[:id], role: i[:role] }.compact
      if i[:href]
        aria = i[:aria].to_h.merge(current: (i[:current] || i[:pressed]) ? "true" : nil).compact
        link_to(i[:href], **common, aria:) { body }
      else
        aria = i[:aria].to_h
        aria = aria.merge(pressed: (i[:pressed] || i[:current]) ? "true" : "false") unless aria.key?(:selected) || aria.key?(:checked)
        type = i[:type].to_s == "submit" ? "submit" : "button"
        tag.button(type:, name: i[:name], value: i[:value], form: i[:form], disabled: i[:disabled], **common, aria:) { body }
      end
    end

    def icon_svg(icon)
      return icon if icon.respond_to?(:html_safe?) && icon.html_safe?

      ss_icon(icon.to_s, size: :xs)
    end
  end
end
