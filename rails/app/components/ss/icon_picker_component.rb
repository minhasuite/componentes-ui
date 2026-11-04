module Ss
  # Grade de ícones com busca e anel no escolhido. Os ícones vêm do app como [nome, svg] (o
  # produto usa o SVG dele). O escolhido vai num input hidden com o nome (name:).
  #
  #   render Ss::IconPickerComponent.new(name: "ponto[icone]", value: "lightbulb", allow_none: true,
  #            icons: [["lightbulb", icon_svg("lightbulb")], ["fan", icon_svg("fan")], …])
  #
  # Busca sem acento e sem caixa ("-" e "_" valem espaço), no controller ss-icon-picker. A grade é
  # um radiogroup: setas andam, Enter/Espaço escolhem. Ao escolher dispara "change" no hidden.
  #
  # v0.10.1: rótulo por ícone (vai no title e no aria-label no lugar do nome cru, e também
  # entra na busca). Além de [nome, svg], valem [nome, svg, rótulo] e
  # { name:, svg:, label: }; ou icon_labels: { "fan" => "Ventilador" } com os pares de sempre.
  class IconPickerComponent < BaseComponent
    DEFAULTS = { search: "Buscar ícone", none: "Sem ícone", empty: "Nenhum ícone com “%{q}”", label: "Ícone" }.freeze

    attr_reader :name, :value, :icons, :id

    def initialize(name:, icons:, value: nil, allow_none: false, id: nil, labels: {}, icon_labels: {}, **rest)
      super(**rest)
      @name, @value, @allow_none = name, value.presence, allow_none
      names = icon_labels.to_h.transform_keys(&:to_s)
      # Cada ícone vira [nome, svg, rótulo] (o rótulo cai no nome quando não vem).
      @icons = Array(icons).map do |i|
        n, svg, lbl = i.is_a?(Hash) ? i.transform_keys(&:to_sym).values_at(:name, :svg, :label) : i
        [n.to_s, svg.to_s, (lbl.presence || names[n.to_s].presence || n).to_s]
      end
      @id = id || "ss-ip-#{name.to_s.parameterize}"
      @labels = labels.to_h.transform_keys(&:to_sym)
    end

    def label(key) = @labels[key] || ss_t("icon_picker.#{key}", default: DEFAULTS[key])
    def allow_none? = @allow_none

    # Texto de busca do ícone: nome sem acento, separadores viram espaço.
    def self.normalize(s) = I18n.transliterate(s.to_s.downcase).tr("-_", "  ").strip

    def search_key(n, label = nil) = self.class.normalize([n, (label if label.to_s != n.to_s)].compact.join(" "))
    def selected?(n) = n.to_s == value.to_s
    def none_selected? = value.nil?

    def root_data
      own = @attrs.to_h[:data].to_h
      { controller: [own[:controller] || own["controller"], "ss-icon-picker"].compact.join(" ") }
    end
  end
end
