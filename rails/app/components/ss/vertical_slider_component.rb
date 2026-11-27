module Ss
  # Slider de pé (termostato, volume, luz) (v1.10, par do SsVerticalSlider): trilha alta em pílula que enche de
  # baixo e o valor escrito no seletor, em DM Mono. Arrastar ou clicar muda; setas e o leitor de tela sobem e
  # descem step:.
  #
  #   render Ss::VerticalSliderComponent.new(name: "volume", value: 40, label: "Volume", suffix: "%")
  #   render Ss::VerticalSliderComponent.new(name: "temp", value: 21.5, min: 16, max: 30, step: 0.5, suffix: "°",
  #     precision: 1, tone: :warn, label: "Temperatura")
  #
  # É um <input type=range> de verdade, em pé (vai no formulário com name:; input/change como em qualquer
  # campo); o desenho fica por cima. suffix: e precision: formam o texto ("21,5°", também o aria-valuetext);
  # format: lambda troca o texto inicial (o JS usa suffix/precision ao mexer). height: e width: px (220 × 64).
  # tone: :accent | :success | :warn | :danger. disabled: apagado e sem mexer.
  class VerticalSliderComponent < BaseComponent
    TONES = %i[accent success warn danger].freeze

    def initialize(name:, value:, min: 0, max: 100, step: 1, label: nil, suffix: "", precision: 0, format: nil,
                   height: 220, width: 64, tone: :accent, disabled: false, id: nil, **rest)
      super(**rest)
      @name, @label, @suffix, @precision, @format, @disabled, @id = name, label, suffix.to_s, precision.to_i, format, disabled, id
      @min, @max, @step = min.to_f, max.to_f, step.to_f
      @value = value.to_f.clamp(@min, [@min, @max].max)
      @height, @width = height.to_i.clamp(96, 600), width.to_i.clamp(44, 160)
      @tone = TONES.include?(tone&.to_sym) ? tone.to_sym : :accent
    end

    def fraction = @max == @min ? 0.0 : ((@value - @min) / (@max - @min)).clamp(0.0, 1.0)
    def text = @format ? @format.call(@value) : "#{ss_number(@value, precision: @precision)}#{@suffix}"

    def num(v) = (v % 1).zero? ? v.to_i : v

    def call
      tag.div(**root_attrs(class: classes("ss-vslider", ("is-disabled" if @disabled)),
                           style: "--h:#{@height}px;--w:#{@width}px;--f:#{fraction.round(4)}",
                           data: { controller: "ss-vslider", tone: @tone, ss_vslider_suffix_value: @suffix,
                                   ss_vslider_precision_value: @precision, ss_vslider_locale_value: ss_intl_locale })) do
        safe_join([
          tag.span(class: "ss-vslider-fill", "aria-hidden": "true"),
          tag.span(tag.output(text, class: "num", data: { ss_vslider_target: "out" }), class: "ss-vslider-thumb", "aria-hidden": "true"),
          tag.input(type: "range", name: @name, id: @id, value: num(@value), min: num(@min), max: num(@max), step: num(@step),
                    class: "ss-vslider-input", disabled: @disabled, "aria-label": @label, "aria-valuetext": text,
                    "aria-orientation": "vertical", data: { ss_vslider_target: "input", action: "input->ss-vslider#input" })
        ])
      end
    end
  end
end
