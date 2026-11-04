module Ss
  # Popover nativo (Popover API): o botão abre com popovertarget, fecha com Esc ou
  # clique fora. Posição por CSS anchor quando o navegador tem; senão o controller
  # ss-popover calcula (abaixo do botão, vira para cima se faltar espaço).
  #   render Ss::PopoverComponent.new(label: "Detalhes", title: "Como calculamos") do … end
  #   trigger: html próprio para o botão (ex. ícone); placement: :bottom_start/:bottom_end/:top_start.
  class PopoverComponent < BaseComponent
    def initialize(label:, title: nil, trigger: nil, trigger_class: "ss-btn ss-btn-ghost ss-btn-sm", placement: :bottom_start, id: nil, **opts)
      super(**opts)
      @label = label
      @title = title
      @trigger = trigger
      @trigger_class = trigger_class
      @placement = placement.to_s.tr("_", "-")
      @pid = id || "ss-pop-#{object_id}"
    end

    def call
      anchor = "--#{@pid}"
      tag.span(class: "ss-popover-host", data: { controller: "ss-popover" }) do
        safe_join([
          tag.button(@trigger || @label, type: "button", class: @trigger_class, popovertarget: @pid, "aria-label": (@trigger ? @label : nil),
                                         style: "anchor-name:#{anchor}", data: { ss_popover_target: "trigger" }),
          tag.div(**root_attrs(id: @pid, popover: "auto", class: classes("ss-popover"), role: "dialog", "aria-label": @title || @label,
                               style: "position-anchor:#{anchor}", data: { placement: @placement, ss_popover_target: "panel", action: "toggle->ss-popover#place" })) do
            safe_join([(tag.p(@title, class: "ss-popover-title") if @title), content].compact)
          end
        ])
      end
    end
  end
end
