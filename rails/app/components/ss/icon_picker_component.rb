module Ss
  # Grade de ícones com busca e anel no escolhido. Os ícones vêm do app como [nome, svg] (o
  # produto usa o SVG dele). O escolhido vai num input hidden com o nome (name:).
  #
  #   render Ss::IconPickerComponent.new(name: "ponto[icone]", value: "lightbulb", allow_none: true,
  #            icons: [["lightbulb", icon_svg("lightbulb")], ["fan", icon_svg("fan")], …])
  #
  # Busca sem acento e sem caixa ("-" e "_" valem espaço), no controller ss-icon-picker. A grade é
  # um radiogroup: setas andam, Enter/Espaço escolhem. Ao escolher dispara "change" no hidden.
  class IconPickerComponent < BaseComponent
    DEFAULTS = { search: "Buscar ícone", none: "Sem ícone", empty: "Nenhum ícone com “%{q}”", label: "Ícone" }.freeze

    attr_reader :name, :value, :icons, :id

    def initialize(name:, icons:, value: nil, allow_none: false, id: nil, labels: {}, **rest)
      super(**rest)
      @name, @value, @allow_none = name, value.presence, allow_none
      @icons = Array(icons).map { |(n, svg)| [n.to_s, svg.to_s] }
      @id = id || "ss-ip-#{name.to_s.parameterize}"
      @labels = labels.to_h.transform_keys(&:to_sym)
    end

    def label(key) = @labels[key] || ss_t("icon_picker.#{key}", default: DEFAULTS[key])
    def allow_none? = @allow_none

    # Texto de busca do ícone: nome sem acento, separadores viram espaço.
    def self.normalize(s) = I18n.transliterate(s.to_s.downcase).tr("-_", "  ").strip

    def search_key(n) = self.class.normalize(n)
    def selected?(n) = n.to_s == value.to_s
    def none_selected? = value.nil?

    def root_data
      own = @attrs.to_h[:data].to_h
      { controller: [own[:controller] || own["controller"], "ss-icon-picker"].compact.join(" ") }
    end
  end
end
