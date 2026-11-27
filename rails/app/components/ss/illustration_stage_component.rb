module Ss
  # Palco de uma ilustração (v1.10, par do SsIllustrationStage): degradê suave da cor da marca descendo para a
  # cor da página, raio de folha, e a ilustração encolhida para caber em height: (assim o botão do passo cabe
  # sem rolar). Só tokens (--accent-soft → --page).
  #
  #   render(Ss::IllustrationStageComponent.new) { render Ss::IllustrationArtComponent.new(:empty) }
  #   render(Ss::IllustrationStageComponent.new(height: 160, padding: "1.5rem 0")) { image_tag "passo.svg", alt: "" }
  #
  # height: px da área da ilustração (112). padding: respiro CSS em volta (padrão: 12px em cima e embaixo).
  class IllustrationStageComponent < BaseComponent
    def initialize(height: 112, padding: nil, **rest)
      super(**rest)
      @height = height.to_i.clamp(32, 640)
      @padding = padding
    end

    def call
      style = ["--h:#{@height}px", ("--pad:#{@padding}" if @padding)].compact.join(";")
      tag.div(**root_attrs(class: classes("ss-ill-stage"), style:)) { tag.div(content, class: "ss-ill-stage-fit") }
    end
  end
end
