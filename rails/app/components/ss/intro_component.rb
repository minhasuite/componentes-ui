module Ss
  # Parágrafo de abertura (v0.13, par do SsIntro): uma ou duas frases do que a aba ou a seção faz,
  # apagado e com medida curta, antes do conteúdo.
  #
  #   render Ss::IntroComponent.new(text: "Aqui ficam as regras que avisam quando algo sai do normal.")
  #   render(Ss::IntroComponent.new) { safe_join(["Veja ", link_to("a ajuda", ajuda_path), "."]) }
  class IntroComponent < BaseComponent
    def initialize(text: nil, **rest)
      super(**rest)
      @text = text
    end

    def call = tag.p(content.presence || @text, **root_attrs(class: classes("ss-intro")))
  end
end
