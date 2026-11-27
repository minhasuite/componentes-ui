module Ss
  # Botão hexagonal na cor da marca com seta e brilho (v1.10, par do SsHexButton): a ação do herói.
  #
  #   render Ss::HexButtonComponent.new(href: novo_pedido_path)
  #   render Ss::HexButtonComponent.new(label: "Continuar", icon: "check", size: 64)   # <button type=button>
  #   render Ss::HexButtonComponent.new(label: "Enviar", type: :submit, form: "f-pedido")
  #
  # href: vira link; sem href, <button> (type: :button padrão, form:, name:, value:). label: o nome falado
  # (padrão "Começar"). icon: nome do ss_icon ("arrow-right"). size: px (72; nunca menor que o alvo de 44).
  # Aperta (escala .92) ao clicar; reduzir movimento: sem escala.
  class HexButtonComponent < BaseComponent
    def initialize(href: nil, label: nil, icon: "arrow-right", size: 72, type: :button, form: nil, name: nil, value: nil,
                   disabled: false, **rest)
      super(**rest)
      @href, @icon, @type, @form, @name, @value, @disabled = href, icon, type, form, name, value, disabled
      @label = label.presence || ss_t("hex_button.start", default: "Começar")
      @size = [size.to_i, 44].max
    end

    def call
      inner = safe_join([tag.span(class: "ss-hex-shape", "aria-hidden": "true"), ss_icon(@icon, size: nil, css: "ss-hex-ico")])
      attrs = root_attrs(class: classes("ss-hex"), style: "--s:#{@size}px", "aria-label": @label, title: @label)
      if @href && !@disabled
        link_to(inner, @href, **attrs)
      else
        tag.button(inner, **attrs, type: @type, form: @form, name: @name, value: @value, disabled: @disabled || nil)
      end
    end
  end
end
