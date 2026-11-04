module Ss
  # Escolher cor de etiqueta/marca: pílula de vidro com círculos (visual do .ss-swatch), radio por baixo.
  # options: [{ value: "verde", label: "Verde", color: "#0f8a5f" }] (a cor é dado do usuário, vai inline).
  #   render Ss::SwatchPickerComponent.new(name: "etiqueta[cor]", options: Etiqueta::CORES, selected: @etiqueta.cor)
  class SwatchPickerComponent < BaseComponent
    attr_reader :name, :options, :selected, :legend

    def initialize(name:, options:, selected: nil, legend: "Cor", **rest)
      super(**rest)
      @name, @selected, @legend = name, selected, legend
      @options = options.map { |o| o.to_h.transform_keys(&:to_sym) }
    end

    def input_id(o) = "#{name.to_s.gsub(/[^a-z0-9]+/i, "_")}_#{o[:value]}"
  end
end
