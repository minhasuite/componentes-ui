module Ss
  # Mosaico de blocos (Explore): grade de 4 colunas no desktop, 2 no tablet, 1 no celular.
  # Os blocos sobem em cascata ao aparecer na tela (ss-in-view).
  #   render Ss::BentoGridComponent.new do |g|
  #     g.with_block(cols: 2, rows: 2, tone: :grad) { … }   # tone: nil (superfície), :soft, :grad (o momento de luz), :image
  #     g.with_block { … }
  #   end
  class BentoGridComponent < BaseComponent
    include InView
    class Block < ViewComponent::Base
      TONES = %i[soft grad image ink].freeze

      def initialize(cols: 1, rows: 1, tone: nil, href: nil, css: nil, **attrs)
        @cols = cols.to_i.clamp(1, 4)
        @rows = rows.to_i.clamp(1, 4)
        @tone = tone&.to_sym
        @href = href
        @css = css
        @attrs = attrs
      end

      def call
        klass = ["ss-bento-cell", ("is-#{@tone}" if TONES.include?(@tone)), @css].compact.join(" ")
        opts = @attrs.merge(class: klass, style: "--c:#{@cols};--r:#{@rows}")
        @href ? link_to(content, @href, **opts) : tag.div(content, **opts)
      end
    end

    renders_many :blocks, Block

    def initialize(columns: 4, **opts)
      super(**opts)
      @columns = columns
    end

    def call
      tag.div(safe_join(blocks), **root_attrs(class: classes("ss-bento"), style: "--cols:#{@columns}", data: in_view_data(stagger: true)))
    end
  end
end
