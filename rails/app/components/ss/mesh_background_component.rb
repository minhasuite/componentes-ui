module Ss
  # Fundo de manchas suaves da cor da marca que se movem devagar (v1.14.0, par do SsMeshBackground), para cabeçalhos
  # de destaque (o .ss-hero, o topo de uma tela, o HeroSectionComponent(mesh: true)). Só transform/opacity em
  # gradientes radiais (sem filter: blur: leve para a GPU), uma animação contínua no ritmo --ss-dur-ambient (24 s),
  # parada com reduzir movimento. O texto fica numa camada acima, com véu
  # que garante o contraste:
  #   tone: :deep (padrão) fundo na cor funda da paleta (--brand-deep) e texto branco (≥ 4,5:1);
  #   tone: :soft         fundo da página com as manchas a 20% e o texto na tinta (--ink).
  #
  #   render(Ss::MeshBackgroundComponent.new(css: "ss-card-pad")) { tag.h2("Bom dia, Ana") }
  #   render(Ss::MeshBackgroundComponent.new(tone: :soft, tag: :header)) { … }
  #
  # animate: false deixa as manchas paradas (outra animação contínua já está na tela). Uma por tela.
  class MeshBackgroundComponent < BaseComponent
    TONES = %i[deep soft].freeze

    # As manchas sozinhas (para quem já tem a casca, como o HeroSectionComponent).
    def self.blobs = %(<span class="ss-mesh-blobs" aria-hidden="true"><i></i><i></i><i></i></span>).html_safe

    def initialize(tone: :deep, animate: true, tag: :div, **rest)
      super(**rest)
      @tone = TONES.include?(tone.to_sym) ? tone.to_sym : raise(ArgumentError, "tone: #{TONES.join(", ")}")
      @animate, @tag = animate, tag
    end

    def call
      content_tag(@tag, **root_attrs(class: classes("ss-mesh", "is-#{@tone}", ("is-still" unless @animate)))) do
        safe_join([self.class.blobs, tag.div(content, class: "ss-mesh-body")])
      end
    end
  end
end
