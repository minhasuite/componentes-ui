module Ss
  # Botão giratório (v1.10, par do SsDial): arco de 270° com marcações, progresso na cor da marca e o valor grande
  # no centro. Arrastar em volta (mouse ou dedo) ou clicar no arco muda; setas, PageUp/PageDown, Home/End e o
  # leitor de tela também (é um role=slider). O valor vai num <input type=hidden name:> para o formulário.
  #
  #   render Ss::DialComponent.new(name: "volume", value: 40, label: "Volume", caption: "Sala")
  #   render Ss::DialComponent.new(name: "temp", value: 22.5, min: 16, max: 30, step: 0.5, format: "%.1f°", size: 180)
  #
  # format: o do Kernel.format ("%d%%", "%.1f°"), também no JS; sem ele, o número no idioma da página com as
  # casas do step. ticks: marcações (40; uma a cada 5 é maior). disabled: apaga e não muda.
  # Eventos: input e change no hidden (bubbles) e ss-dial:change { value }. Reduzir movimento: sem transição.
  class DialComponent < BaseComponent
    START, SWEEP = 135.0, 270.0

    attr_reader :value

    def initialize(value:, name: nil, min: 0, max: 100, step: 1, label: nil, caption: nil, format: nil, size: 220, ticks: 40,
                   disabled: false, id: nil, **rest)
      super(**rest)
      @min, @max, @step = min.to_f, max.to_f, step.to_f
      @max = @min if @max < @min
      @value = value.to_f.clamp(@min, @max)
      @name, @label, @caption, @format, @disabled, @id = name, label, caption, format, disabled, id
      @size, @ticks = size.to_i.clamp(120, 480), ticks.to_i.clamp(8, 120)
    end

    def fraction = (@max == @min ? 0.0 : (@value - @min) / (@max - @min))

    def decimals = (@step % 1).zero? ? 0 : @step.to_s.split(".").last.size

    def text(v = @value)
      return Kernel.format(@format, v) if @format.present?

      ss_number(v, precision: decimals)
    end

    def point(deg, r) = [(100 + Math.cos(deg * Math::PI / 180) * r).round(2), (100 + Math.sin(deg * Math::PI / 180) * r).round(2)]

    def svg
      f = fraction
      ticks = (0..@ticks).map do |k|
        a = START + SWEEP * k / @ticks
        big = (k % 5).zero?
        x1, y1 = point(a, 98)
        x2, y2 = point(a, big ? 88 : 92)
        tag.line(x1:, y1:, x2:, y2:, class: ["ss-dial-tick", ("is-big" if big)].compact.join(" "),
                 style: "--k:#{(k.to_f / @ticks).round(4)}")
      end
      sx, sy = point(START, 74)
      ex, ey = point(START + SWEEP, 74)
      arc = "M #{sx} #{sy} A 74 74 0 1 1 #{ex} #{ey}"
      tag.svg(safe_join([*ticks, tag.path(d: arc, class: "ss-dial-track", pathLength: 100),
                         tag.path(d: arc, class: "ss-dial-arc", pathLength: 100),
                         tag.circle(cx: 100, cy: 100, r: 56, class: "ss-dial-knob")]),
              viewBox: "0 0 200 200", class: "ss-dial-svg", "aria-hidden": "true")
    end

    def call
      tag.div(**root_attrs(class: classes("ss-dial", ("is-disabled" if @disabled)), style: "--s:#{@size}px;--f:#{fraction.round(4)}",
                           data: { controller: "ss-dial", ss_dial_min_value: @min, ss_dial_max_value: @max, ss_dial_step_value: @step,
                                   ss_dial_format_value: @format, ss_dial_decimals_value: decimals, action: "pointerdown->ss-dial#down keydown->ss-dial#key" })) do
        safe_join([
          tag.div(class: "ss-dial-face", role: "slider", tabindex: (@disabled ? -1 : 0), id: @id, "aria-label": @label,
                  "aria-valuemin": @min.to_s.sub(/\.0\z/, ""), "aria-valuemax": @max.to_s.sub(/\.0\z/, ""),
                  "aria-valuenow": @value.to_s.sub(/\.0\z/, ""), "aria-valuetext": text, "aria-disabled": (@disabled ? "true" : nil),
                  data: { ss_dial_target: "face" }) do
            safe_join([
              svg,
              tag.span(class: "ss-dial-center", "aria-hidden": "true") do
                safe_join([tag.span(text, class: "ss-dial-value num", data: { ss_dial_target: "out" }),
                           (tag.span(@caption, class: "ss-dial-cap") if @caption)].compact)
              end
            ])
          end,
          (tag.input(type: "hidden", name: @name, value: @value.to_s.sub(/\.0\z/, ""), data: { ss_dial_target: "input" }) if @name)
        ].compact)
      end
    end
  end
end
