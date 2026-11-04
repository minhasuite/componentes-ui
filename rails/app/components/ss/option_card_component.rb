module Ss
  # Radio ou checkbox como card (ícone, título, descrição); marcado pelo :has(:checked).
  # Agrupe vários num <div class="ss-option-grid" role="radiogroup" aria-label="…">.
  #   render Ss::OptionCardComponent.new(name: "plano", value: "anual", title: "Anual", description: "2 meses grátis", icon: svg)
  class OptionCardComponent < BaseComponent
    attr_reader :name, :value, :title, :description, :icon, :type, :checked, :badge

    def initialize(name:, value:, title:, description: nil, icon: nil, type: :radio, checked: false, badge: nil, **rest)
      super(**rest)
      @name, @value, @title, @description, @icon, @type, @checked, @badge = name, value, title, description, icon, type.to_s, checked, badge
    end
  end
end
