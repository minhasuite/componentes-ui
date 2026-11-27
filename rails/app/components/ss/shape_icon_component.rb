module Ss
  # Ícone dentro de um losango ou hexágono de cantos arredondados (v1.10, par do SsShapeIcon). Tonal (a cor a
  # 14%, 22% no escuro, ícone na cor) ou filled: (forma cheia, ícone em --on-accent). Sem tone:, a marca.
  #
  #   render Ss::ShapeIconComponent.new(icon: "bolt")
  #   render Ss::ShapeIconComponent.new(icon: "check", shape: :hexagono, tone: :success, filled: true, size: 64)
  #
  # shape: :losango (padrão) | :hexagono. tone: :accent | :success | :warn | :danger | :info. size: px (52).
  # label: o nome lido (sem label: é decoração, aria-hidden). O contorno é o mesmo do SsShapeIcon.pathFor:
  # Ss::ShapeIconComponent.path(shape, size) (o HexButtonComponent usa o mesmo).
  class ShapeIconComponent < BaseComponent
    SHAPES = %i[losango hexagono].freeze
    TONES = %i[accent success warn danger info].freeze

    # O contorno (d do <path>) num quadrado de lado s: vértices no círculo de raio s/2, começando no topo, e os
    # cantos arredondados cortando perto de cada vértice (k) com uma curva por ele.
    def self.path(shape, s = 100)
      n = shape.to_sym == :hexagono ? 6 : 4
      k = n == 4 ? 0.24 : 0.2
      r = s / 2.0
      pts = (0...n).map { |i| a = -Math::PI / 2 + i * 2 * Math::PI / n; [r + Math.cos(a) * r, r + Math.sin(a) * r] }
      lerp = ->(p, q, t) { [p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t] }
      fmt = ->(p) { p.map { |v| v.round(2) }.join(" ") }
      d = +""
      pts.each_with_index do |p, i|
        a = lerp.(p, pts[(i - 1) % n], k)
        b = lerp.(p, pts[(i + 1) % n], k)
        d << (i.zero? ? "M#{fmt.(a)}" : "L#{fmt.(a)}") << "Q#{fmt.(p)} #{fmt.(b)}"
      end
      d << "Z"
    end

    def initialize(icon:, shape: :losango, tone: nil, filled: false, size: 52, label: nil, **rest)
      super(**rest)
      @icon, @filled, @label = icon, filled, label
      @shape = SHAPES.include?(shape&.to_sym) ? shape.to_sym : :losango
      @tone = TONES.include?(tone&.to_sym) ? tone.to_sym : :accent
      @size = size.to_i.clamp(16, 256)
    end

    def call
      a11y = @label ? { role: "img", "aria-label": @label } : { "aria-hidden": "true" }
      tag.span(**root_attrs(class: classes("ss-shape-icon", ("is-filled" if @filled)), style: "--s:#{@size}px",
                            data: { shape: @shape, tone: @tone }, **a11y)) do
        safe_join([
          tag.svg(tag.path(d: self.class.path(@shape)), viewBox: "0 0 100 100", class: "ss-shape-icon-bg", "aria-hidden": "true"),
          ss_icon(@icon, size: nil, css: "ss-shape-icon-ico")
        ])
      end
    end
  end
end
