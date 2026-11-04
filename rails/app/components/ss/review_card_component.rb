module Ss
  # Depoimento: estrelas (aceita meia), texto, avatar (ss_avatar), nome e papel.
  #   render Ss::ReviewCardComponent.new(name: "Carla Mendes", role: "Padaria Central", rating: 4.5, text: "…", date: "out/2026")
  class ReviewCardComponent < BaseComponent
    include InView
    def initialize(name:, text:, rating: 5, role: nil, date: nil, **opts)
      super(**opts)
      @name = name
      @text = text
      @rating = rating.to_f.clamp(0, 5)
      @role = role
      @date = date
    end

    def call
      tag.figure(**root_attrs(class: classes("ss-card", "ss-review"), data: in_view_data)) do
        safe_join([
          tag.span(class: "ss-stars", style: "--v:#{@rating}", role: "img", "aria-label": ss_t("review_card.rating", default: "Nota %{rating} de 5", rating: ss_number(@rating, precision: @rating.to_f % 1 == 0 ? 0 : 1))),
          tag.blockquote(tag.p(@text)),
          tag.figcaption do
            safe_join([ss_avatar(@name, size: 38), tag.span { safe_join([tag.b(@name), (tag.small([@role, @date].compact.join(" · ")) if @role || @date)].compact) }])
          end
        ])
      end
    end
  end
end
