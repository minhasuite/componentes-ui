module Ss
  # Escolher cor de etiqueta/marca: pílula de vidro com círculos (visual do .ss-swatch), radio por baixo.
  # options: [{ value: "verde", label: "Verde", color: "#0f8a5f" }] (a cor é dado do usuário, vai inline).
  #   render Ss::SwatchPickerComponent.new(name: "etiqueta[cor]", options: Etiqueta::CORES, selected: @etiqueta.cor)
  #
  # v0.10: free: true acrescenta a ficha "Personalizada", que abre o <input type=color> do
  # navegador; o radio dela leva o hex escolhido (#rrggbb) como valor. Se selected: é um hex
  # fora das opções, a ficha já vem marcada com ele. Textos do I18n (componentes_ui.swatch_picker.*).
  class SwatchPickerComponent < BaseComponent
    HEX = /\A#\h{6}\z/

    attr_reader :name, :options, :selected

    def initialize(name:, options:, selected: nil, legend: nil, free: false, free_label: nil, **rest)
      super(**rest)
      @name, @selected, @legend, @free, @free_label = name, selected, legend, free, free_label
      @options = options.map { |o| o.to_h.transform_keys(&:to_sym) }
    end

    def legend = @legend || ss_t("swatch_picker.legend", default: "Cor")
    def free? = @free
    def free_label = @free_label || ss_t("swatch_picker.custom", default: "Personalizada")
    def free_pick_label = ss_t("swatch_picker.pick", default: "Escolher outra cor")

    def input_id(o) = "#{name.to_s.gsub(/[^a-z0-9]+/i, "_")}_#{o[:value]}"
    def free_id = "#{name.to_s.gsub(/[^a-z0-9]+/i, "_")}_livre"

    # A ficha livre vem marcada quando o valor salvo não é uma das opções.
    def free_checked? = free? && selected.present? && options.none? { _1[:value].to_s == selected.to_s }

    def free_hex
      return selected.to_s.downcase if free_checked? && selected.to_s.match?(HEX)

      options.map { _1[:color].to_s }.find { _1.match?(HEX) } || "#5a45e8"
    end
  end
end
