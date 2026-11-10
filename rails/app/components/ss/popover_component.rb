module Ss
  # Popover nativo (Popover API): o botão abre com popovertarget, fecha com Esc ou
  # clique fora. Posição por CSS anchor quando o navegador tem; senão o controller
  # ss-popover calcula (abaixo do botão, vira para cima se faltar espaço).
  #   render Ss::PopoverComponent.new(label: "Detalhes", title: "Como calculamos") do … end
  #   trigger: html próprio para o botão (ex. ícone); placement: :bottom_start/:bottom_end/:top_start.
  #   v0.18: trigger_attrs: {} vai no botão (title:, data: { action:, testid: }, aria:); o aria-label
  #   (com trigger:) e o title padrão seguem o label:. Ex. menu ⋯ de uma linha:
  #   Ss::PopoverComponent.new(label: "Mais ações para #{t.nome}", trigger: ss_icon("dots-vertical"),
  #     trigger_class: "ss-icon-btn is-sm", trigger_attrs: { title: "Mais ações" }, placement: :bottom_end)
  class PopoverComponent < BaseComponent
    def initialize(label:, title: nil, trigger: nil, trigger_class: "ss-btn ss-btn-ghost ss-btn-sm", placement: :bottom_start, id: nil,
                   trigger_attrs: {}, **opts)
      super(**opts)
      @trigger_attrs = trigger_attrs.to_h.transform_keys(&:to_sym)
      @label = label
      @title = title
      @trigger = trigger
      @trigger_class = trigger_class
      @placement = placement.to_s.tr("_", "-")
      @pid = id || "ss-pop-#{object_id}"
    end

    def trigger_html_attrs(anchor)
      attrs = { type: "button", class: [@trigger_class, @trigger_attrs[:class]].compact.join(" "), popovertarget: @pid,
                "aria-label": (@trigger ? @label : nil), title: (@trigger ? @label : nil) }
      attrs.merge!(@trigger_attrs.except(:class, :data, :aria, :type, :popovertarget, :style))
      attrs[:aria] = @trigger_attrs[:aria].to_h if @trigger_attrs[:aria]
      attrs.merge(style: "anchor-name:#{anchor}", data: @trigger_attrs[:data].to_h.merge(ss_popover_target: "trigger"))
    end

    def call
      anchor = "--#{@pid}"
      tag.span(class: "ss-popover-host", data: { controller: "ss-popover" }) do
        safe_join([
          tag.button(@trigger || @label, **trigger_html_attrs(anchor)),
          tag.div(**root_attrs(id: @pid, popover: "auto", class: classes("ss-popover"), role: "dialog", "aria-label": @title || @label,
                               style: "position-anchor:#{anchor}", data: { placement: @placement, ss_popover_target: "panel", action: "toggle->ss-popover#place" })) do
            safe_join([(tag.p(@title, class: "ss-popover-title") if @title), content].compact)
          end
        ])
      end
    end
  end
end
