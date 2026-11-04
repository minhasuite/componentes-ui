module Ss
  # Faixa de 3–4 vantagens com divisórias curvas (plantas web).
  #   render Ss::FeatureStripComponent.new(tone: :deep) do |f|     # tone: :surface (padrão) ou :deep (base escura da marca)
  #     f.with_feature(title: "Offline", text: "Vende sem internet", icon: svg)
  #   end
  class FeatureStripComponent < BaseComponent
    include InView
    class Feature < ViewComponent::Base
      def initialize(title:, text: nil, icon: nil)
        @title = title
        @text = text
        @icon = icon
      end

      def call
        icon = (tag.span(@icon, class: "ss-feature-icon", "aria-hidden": "true") if @icon.respond_to?(:html_safe?) && @icon.html_safe?)
        tag.li(safe_join([icon, tag.h3(@title), (tag.p(@text) if @text), content].compact), class: "ss-feature")
      end
    end

    renders_many :features, Feature

    def initialize(tone: :surface, label: nil, **opts)
      super(**opts)
      @tone = tone.to_sym
      @label = label
    end

    def call
      tag.ul(safe_join(features), **root_attrs(class: classes("ss-features", ("is-deep" if @tone == :deep)), "aria-label": @label, data: in_view_data(stagger: true)))
    end
  end
end
