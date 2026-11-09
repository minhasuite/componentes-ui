module Ss
  # Mosaico em colunas (v0.13, par do SsMasonry): os filhos descem em colunas que se encaixam
  # pela altura (column-count do CSS), 1 no celular, 2 a partir de 640 px, 3 de 1024 e 4 de
  # 1440. Nenhum card se parte entre colunas; um Ss::SectionComponent no meio fica grudado no
  # card que vem depois. Filho com display: contents (turbo-frame.contents) vale pelo que tem dentro.
  #
  #   render(Ss::MasonryComponent.new(max: 3)) { safe_join(cards) }
  #
  # max: o máximo de colunas (1 a 4; padrão 4). A ordem é a das colunas (de cima para baixo).
  class MasonryComponent < BaseComponent
    def initialize(max: 4, **rest)
      super(**rest)
      @max = max.to_i.clamp(1, 4)
    end

    def call
      tag.div(content, **root_attrs(class: classes("ss-masonry", ("is-max-#{@max}" if @max < 4))))
    end
  end
end
