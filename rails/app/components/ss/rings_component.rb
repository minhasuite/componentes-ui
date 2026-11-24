module Ss
  # Anéis concêntricos (v1.9, par do SsRings, componente do ss_rings): até 3 anéis de 0 a 1 com ponta arredondada
  # sobre a trilha da mesma cor a 14%, que enchem em cascata quando entram na tela. center: o texto do meio.
  #
  #   render Ss::RingsComponent.new(rings: [{ value: 0.8, label: "Calorias" }, { value: 0.5, label: "Exercício" }], center: "80%")
  #
  # ring: { value:, label: (para o leitor de tela), tone: :accent | :success | :warn | :danger (sem tom, as cores da
  # aurora da marca) }. Leitor de tela: "Calorias 80%, Exercício 50%" (label: troca o nome do conjunto).
  # O ss_rings (helper) continua. Reduzir movimento: já aparecem cheios.
  class RingsComponent < BaseComponent
    include InView
    TONES = { accent: "var(--accent)", success: "var(--success)", warn: "var(--warn)", danger: "var(--danger)" }.freeze
    AURORA = %w[var(--aurora-2) var(--aurora-3) var(--aurora-1)].freeze

    attr_reader :rings

    def initialize(rings:, center: nil, size: 128, stroke: 11, label: nil, **rest)
      super(**rest)
      @rings = Array(rings).first(3).map { |r| r.is_a?(Hash) ? r.transform_keys(&:to_sym) : { value: r } }
      @center, @size, @stroke, @label = center, size.to_i.clamp(48, 400), stroke.to_i.clamp(3, 32), label
    end

    def render? = rings.any?

    def aria
      parts = rings.each_with_index.map { |r, i| "#{r[:label] || (i + 1)} #{(r[:value].to_f.clamp(0, 1) * 100).round}%" }
      [@label, parts.join(", ")].compact.join(": ") + (@center ? " (#{@center})" : "")
    end

    def call
      s = @size / 2.0
      circles = rings.each_with_index.map do |r, i|
        rad = s - @stroke / 2.0 - i * (@stroke + 4)
        color = TONES[r[:tone]&.to_sym] || AURORA[i]
        at = { cx: s, cy: s, r: rad, pathLength: 100 }
        tag.circle(**at, class: "track", style: "stroke:#{color};stroke-width:#{@stroke}") +
          tag.circle(**at, class: "fill", style: "stroke:#{color};stroke-width:#{@stroke};--v:#{(r[:value].to_f.clamp(0, 1) * 100).round(1)};--i:#{i}")
      end
      tag.div(**root_attrs(class: classes("ss-rings ss-rings-c"), role: "img", "aria-label": aria, style: "width:#{@size}px;height:#{@size}px",
                           data: in_view_data)) do
        safe_join([tag.svg(safe_join(circles), viewBox: "0 0 #{@size} #{@size}", "aria-hidden": "true"),
                   (tag.span(@center, "aria-hidden": "true") if @center)].compact)
      end
    end
  end
end
