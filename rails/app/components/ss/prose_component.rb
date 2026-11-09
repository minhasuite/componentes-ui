module Ss
  # Texto longo (v0.13, par do SsProse): termos, privacidade, ajuda, página pública. Parágrafos,
  # títulos, listas, links e citações com a medida de leitura (70ch) e a tipografia da suíte.
  #
  #   render(Ss::ProseComponent.new) { simple_format(texto) }
  #   render(Ss::ProseComponent.new(tag: :article, css: "mx-auto")) do … end
  class ProseComponent < BaseComponent
    TAGS = %i[div article section main].freeze

    def initialize(tag: :div, **rest)
      super(**rest)
      @tag = TAGS.include?(tag.to_s.to_sym) ? tag.to_s.to_sym : :div
    end

    def call = content_tag(@tag, content, **root_attrs(class: classes("ss-prose")))
  end
end
