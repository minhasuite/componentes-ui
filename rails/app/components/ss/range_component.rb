module Ss
  # Slider (.ss-range) com o valor ao lado e marcas opcionais embaixo.
  # format: "R$ %d", "%d%%", "%d km" (sprintf); ticks: [0, 25, 50, 75, 100].
  #   render Ss::RangeComponent.new(name: "desconto", label: "Desconto", value: 10, max: 30, format: "%d%%", ticks: [0, 10, 20, 30])
  class RangeComponent < BaseComponent
    attr_reader :name, :label, :value, :min, :max, :step, :ticks, :fmt, :id

    def initialize(name:, label:, value: 0, min: 0, max: 100, step: 1, ticks: nil, format: "%s", id: nil, **rest)
      super(**rest)
      @name, @label, @value, @min, @max, @step, @ticks, @fmt = name, label, value, min, max, step, ticks, format
      @id = id || "ss-rng-#{SecureRandom.hex(3)}"
    end

    def pct(v = value) = max == min ? 0 : ((v.to_f - min) * 100.0 / (max - min)).round(2)

    def text(v = value) = Kernel.format(fmt, v)
  end
end
