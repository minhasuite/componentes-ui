module Ss
  # Cartão que inclina levemente (v1.14.0, par do SsTiltCard): ao passar o mouse e enquanto o dedo está no cartão,
  # gira até ~6° seguindo o ponteiro, com o reflexo de vidro (o brilho e o filete do .ss-glass) andando junto. Para
  # cartão de destaque: cartão de crédito, plano, conquista. Desligado com reduzir movimento e com dense: true (tela
  # de dados densos: o cartão fica parado e sem reflexo). Ss::WalletCardComponent já inclina assim.
  #
  #   render(Ss::TiltCardComponent.new(href: plano_path)) { … }
  #   render(Ss::TiltCardComponent.new(glass: false, css: "ss-card-pad")) { … }
  #
  # glass: o reflexo (padrão true). href: o cartão todo vira link (foco visível; Enter abre). tag: :div/:article/:li.
  class TiltCardComponent < BaseComponent
    def initialize(glass: true, dense: false, href: nil, tag: :div, **rest)
      super(**rest)
      @glass, @dense, @href, @tag = glass, dense, href, tag
    end

    def call
      data = @dense ? { ss_tilt_off: "" } : { controller: "ss-tilt" }
      attrs = root_attrs(class: classes("ss-card", "ss-tilt-card", ("is-glass" if @glass && !@dense), ("is-dense" if @dense)), data:)
      body = safe_join([tag.div(content, class: "ss-tilt-body"), (tag.span(class: "ss-tilt-glare", "aria-hidden": "true") if @glass && !@dense)].compact)
      @href ? link_to(@href, **attrs) { body } : content_tag(@tag, body, **attrs)
    end
  end
end
