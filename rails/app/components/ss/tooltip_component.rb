module Ss
  # Dica curta no hover e no foco do elemento de dentro; Esc esconde. O controller
  # liga aria-describedby no primeiro elemento focável.
  #   render Ss::TooltipComponent.new(text: "Exportar CSV") do %><button …>…</button><% end
  class TooltipComponent < BaseComponent
    def initialize(text:, placement: :top, **opts)
      super(**opts)
      @text = text
      @placement = placement
    end

    def call
      tid = "ss-tt-#{object_id}"
      tag.span(**root_attrs(class: classes("ss-tooltip-host"), data: { controller: "ss-tooltip", ss_tooltip_id_value: tid, placement: @placement,
                                                                       action: "keydown.esc->ss-tooltip#hide mouseleave->ss-tooltip#reset focusout->ss-tooltip#reset" })) do
        safe_join([content, tag.span(@text, id: tid, role: "tooltip", class: "ss-tooltip")])
      end
    end
  end
end
