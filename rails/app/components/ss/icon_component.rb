module Ss
  # Ícone do conjunto da gem (v0.15): SVG inline na cor do texto, o mesmo do helper ss_icon.
  # Par do SsIcons.named (Flutter), que devolve o ícone do Material com o mesmo nome.
  #
  #   render Ss::IconComponent.new(name: "credit-card")
  #   render Ss::IconComponent.new(name: "star", variant: :solid, size: :xs, css: "text-warn", title: "Principal")
  #
  # name: nome da v1 ou da v2 do Heroicons ("magnifying-glass" vale "search"); desconhecido vira
  # "question-mark-circle". size: :xs, :sm (padrão), :md, :lg ou nil (quem envolve dimensiona).
  class IconComponent < BaseComponent
    def initialize(name:, variant: :outline, size: :sm, title: nil, **rest)
      super(**rest)
      @name, @variant, @size, @title = name, variant, size, title
    end

    def call = ss_icon(@name, variant: @variant, size: @size, css: @css, title: @title)
  end
end
