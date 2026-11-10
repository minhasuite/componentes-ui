module Ss
  # Grupo recolhível (<details>): cabeçalho com seta, contagem e um selo colorido opcional; o corpo
  # abre com a mola (::details-content + interpolate-size; sem suporte, abre direto).
  #
  #   render Ss::CollapsibleComponent.new(title: "Sala de estar", count: 6, label: "2 ligados", tone: :success, open: true) do
  #     …
  #   end
  #
  # tone do selo: :accent | :info | :warn | :success | :danger. icon: svg antes do título.
  class CollapsibleComponent < BaseComponent
    TONES = %i[accent info warn success danger neutral].freeze

    attr_reader :title, :count, :label

    def initialize(title:, count: nil, label: nil, tone: :accent, icon: nil, open: false, **rest)
      super(**rest)
      @title, @count, @label, @icon, @open = title, count, label, icon, open
      @tone = TONES.include?(t = (tone.to_s == "warning" ? :warn : tone.to_s.to_sym)) ? t : :accent
    end

    def call
      tag.details(**root_attrs(class: classes("ss-collapse"), open: @open)) do
        safe_join([
          tag.summary(class: "ss-collapse-head") do
            safe_join([
              tag.span(Ss::CasaIcons.svg(:chevron), class: "ss-collapse-chev", "aria-hidden": true),
              (tag.span(@icon.to_s.html_safe, class: "ss-collapse-ico", "aria-hidden": true) if @icon),
              tag.span(title, class: "ss-collapse-title"),
              (tag.span(count, class: "ss-collapse-count num") unless count.nil?),
              (tag.span(label, class: "ss-collapse-label", data: { tone: @tone }) if label)
            ].compact)
          end,
          tag.div(content, class: "ss-collapse-body")
        ])
      end
    end
  end
end
