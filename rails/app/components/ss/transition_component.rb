module Ss
  # Nome de View Transition para um elemento "voar" da lista para o detalhe (Turbo +
  # <meta name="view-transition" content="same-origin">). Mesmo name nas duas telas.
  #   render Ss::TransitionComponent.new(name: "produto-#{p.id}-img", kind: :img) { image_tag … }
  #   <h1 style="<%= Ss::TransitionComponent.style("produto-#{p.id}-title") %>">  (só o estilo)
  # kind: :img (.ss-vt-img) ou :title (.ss-vt-title) ajustam a curva/duração.
  class TransitionComponent < BaseComponent
    def self.style(name) = "view-transition-name:#{name.to_s.parameterize}"

    def initialize(name:, kind: nil, tag_name: :div, **opts)
      super(**opts)
      @name = name
      @kind = kind
      @tag_name = tag_name
    end

    def call
      content_tag(@tag_name, content, **root_attrs(class: classes("ss-vt", ("ss-vt-#{@kind}" if @kind)), style: self.class.style(@name)))
    end
  end
end
