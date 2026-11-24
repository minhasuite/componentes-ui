module Ss
  # Percentual grande num anel fino com marcações em volta, estilo termostato (v1.9, par do SsBigRing): as
  # marcações até o valor acendem na cor da marca (uma a cada 5 é maior); enche e conta quando entra na tela.
  #
  #   render Ss::BigRingComponent.new(value: 0.72, caption: "da meta")
  #   render Ss::BigRingComponent.new(value: umidade / 100.0, caption: "umidade", tone: :success, size: 160)
  #
  # value: 0 a 1. tone: :accent (padrão) | :success | :warn | :danger. ticks: marcações (60). size: px (200).
  # Leitor de tela: "72% da meta". Reduzir movimento: já aparece cheio.
  class BigRingComponent < BaseComponent
    include InView
    TONES = %i[accent success warn danger].freeze

    attr_reader :value

    def initialize(value:, caption: nil, size: 200, ticks: 60, tone: :accent, **rest)
      super(**rest)
      @value = value.to_f.clamp(0.0, 1.0)
      @caption, @size, @ticks = caption, size.to_i.clamp(96, 480), ticks.to_i.clamp(12, 120)
      @tone = TONES.include?(tone&.to_sym) ? tone.to_sym : :accent
    end

    def pct = (value * 100).round
    def label = [("#{pct}%"), @caption].compact.join(" ")

    def svg
      ticks = (0...@ticks).map do |k|
        a = -Math::PI / 2 + 2 * Math::PI * k / @ticks
        big = (k % 5).zero?
        r1, r2 = 98.0, big ? 89.0 : 93.0
        on = k.to_f / @ticks < value
        delay = value.zero? ? 0 : ((k.to_f / @ticks) / value * 900).round
        tag.line(x1: (100 + Math.cos(a) * r1).round(2), y1: (100 + Math.sin(a) * r1).round(2), x2: (100 + Math.cos(a) * r2).round(2),
                 y2: (100 + Math.sin(a) * r2).round(2), class: ["ss-bigring-tick", ("is-big" if big), ("is-on" if on)].compact.join(" "),
                 style: (on ? "--t:#{delay}ms" : nil))
      end
      arc = tag.circle(cx: 100, cy: 100, r: 78, pathLength: 100, class: "ss-bigring-track") +
            tag.circle(cx: 100, cy: 100, r: 78, pathLength: 100, class: "ss-bigring-arc", style: "--v:#{(value * 100).round(2)}")
      knob = value.positive? ? tag.g(tag.circle(cx: 100, cy: 22, r: 6), class: "ss-bigring-knob", style: "--deg:#{(value * 360).round(2)}deg") : nil
      tag.svg(safe_join([*ticks, arc, knob].compact), viewBox: "0 0 200 200", "aria-hidden": "true")
    end

    def call
      tag.figure(**root_attrs(class: classes("ss-bigring"), role: "img", "aria-label": label, style: "--s:#{@size}px",
                              data: in_view_data.merge(tone: @tone))) do
        safe_join([
          svg,
          tag.span(class: "ss-bigring-center", "aria-hidden": "true") do
            safe_join([tag.span(safe_join([render(Ss::CountUpComponent.new(value: pct, duration: 900)), tag.small("%")]), class: "ss-bigring-n num"),
                       (tag.span(@caption, class: "ss-bigring-cap") if @caption)].compact)
          end
        ])
      end
    end
  end
end
