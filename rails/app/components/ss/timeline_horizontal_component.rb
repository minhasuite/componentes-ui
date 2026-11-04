module Ss
  # Marcos numa linha horizontal com rolagem (encaixa no marco).
  #   render Ss::TimelineHorizontalComponent.new(items: [{ title: "Pedido", date: "02/11", text: "…", state: :done }, …])
  # state: :done (feito), :current (agora), nil (a seguir).
  class TimelineHorizontalComponent < BaseComponent
    include InView
    def initialize(items:, label: nil, **opts)
      super(**opts)
      @items = items
      @label = label || ss_t("timeline.label", default: "Linha do tempo")
    end

    def call
      tag.ol(**root_attrs(class: classes("ss-htl"), "aria-label": @label, tabindex: 0, data: in_view_data(stagger: true))) do
        safe_join(@items.map do |it|
          state = it[:state]&.to_s
          tag.li(class: ("is-#{state}" if state), "aria-current": (state == "current" ? "step" : nil)) do
            safe_join([tag.i(aria: { hidden: true }), tag.small(it[:date], class: "num"), tag.b(it[:title]), (tag.p(it[:text]) if it[:text]),
                       (tag.span(state == "done" ? ss_t("timeline.done", default: "feito") : ss_t("timeline.current", default: "agora"), class: "ss-sr") if state)].compact)
          end
        end)
      end
    end
  end
end
