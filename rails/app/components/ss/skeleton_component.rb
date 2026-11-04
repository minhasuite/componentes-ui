module Ss
  # Esqueleto de carregamento com brilho que passa: shape :line, :table, :card, :list.
  # Com frame: vira o recheio de um <turbo-frame loading="lazy"> que busca o conteúdo.
  #   render Ss::SkeletonComponent.new(shape: :table, rows: 5)
  #   render Ss::SkeletonComponent.new(shape: :list, frame: { id: "ultimos", src: ultimos_path })
  class SkeletonComponent < BaseComponent
    def initialize(shape: :line, lines: 3, rows: 4, cols: 4, frame: nil, label: "Carregando…", **opts)
      super(**opts)
      @shape = shape.to_sym
      @lines = lines
      @rows = rows
      @cols = cols
      @frame = frame
      @label = label
    end

    def call
      body = tag.div(**root_attrs(class: classes("ss-skel", "is-#{@shape}"), role: "status", "aria-busy": "true")) do
        safe_join([tag.span(@label, class: "ss-sr"), shape])
      end
      return body unless @frame

      tag.turbo_frame(body, id: @frame[:id], src: @frame[:src], loading: @frame.fetch(:loading, "lazy"))
    end

    private

    def bar(css = nil, w = nil) = tag.i(class: css, style: (w ? "width:#{w}" : nil))
    WIDTHS = %w[92% 78% 64% 85% 56% 70%].freeze

    def shape
      case @shape
      when :table
        safe_join([tag.div(safe_join(Array.new(@cols) { bar }), class: "ss-skel-row is-head"),
                   *Array.new(@rows) { |r| tag.div(safe_join(Array.new(@cols) { |c| bar(nil, WIDTHS[(r + c) % 6]) }), class: "ss-skel-row") }])
      when :card
        safe_join([bar("ss-skel-media"), bar("ss-skel-title", "60%"), *Array.new(@lines) { |i| bar(nil, WIDTHS[i % 6]) }])
      when :list
        safe_join(Array.new(@rows) { |i| tag.div(safe_join([bar("ss-skel-dot"), tag.span(safe_join([bar(nil, WIDTHS[i % 6]), bar("ss-skel-sub", "40%")])), bar("ss-skel-val")]), class: "ss-skel-item") })
      else
        safe_join(Array.new(@lines) { |i| bar(nil, i == @lines - 1 ? "55%" : WIDTHS[i % 6]) })
      end
    end
  end
end
