module Ss
  # v0.11: escolha de densidade (Compacta, Padrão, Confortável), a mesma peça do
  # SsDensityPicker do Flutter. Um .ss-seg com a pílula que desliza; o controller
  # ss-density põe data-ss-density no <html> (ou no contêiner de target:) e lembra no
  # navegador (chave ss-density). O produto decide se mostra (Aparência, menu).
  #
  #   render Ss::DensityPickerComponent.new                          # no <html>, lembrado
  #   render Ss::DensityPickerComponent.new(target: "#tabela")       # só naquele contêiner
  #   render Ss::DensityPickerComponent.new(persist: false, value: "compact")
  #
  # Para não piscar no carregamento, ponha ss_density_head no <head>.
  class DensityPickerComponent < BaseComponent
    LABELS = { "compact" => "Compacta", "standard" => "Padrão", "comfortable" => "Confortável" }.freeze

    def initialize(value: nil, persist: true, target: nil, label: nil, labels: {}, **opts)
      super(**opts)
      @value = value
      @persist, @target = persist, target
      @label = label
      @labels = labels.to_h.transform_keys(&:to_s)
    end

    def value = ss_density(@value)
    def group_label = @label || ss_t("density_picker.label", default: "Densidade")
    def text(d) = @labels[d] || ss_t("density_picker.#{d}", default: LABELS[d])
    def options = ComponentesUi::DENSITIES

    def data
      { controller: "ss-density ss-indicator", "ss-indicator-selector-value": "button",
        "ss-density-persist-value": @persist, "ss-density-target-value": @target.to_s, "ss-density-default-value": value }
    end
  end
end
