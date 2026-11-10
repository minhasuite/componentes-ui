module Ss
  # Botão só de ícone (v0.18, o .ss-icon-btn como componente; par do SsIconButton): nome lido e dica
  # obrigatórios. Com pressed: vira um botão de alternar (aria-pressed) que troca o ícone: icon: é o
  # do estado desligado, pressed_icon: o do ligado (o CSS mostra um ou outro pelo aria-pressed; o
  # controller do app só troca o atributo).
  #
  #   render Ss::IconButtonComponent.new(icon: "pencil", label: "Editar", href: edit_path)
  #   render Ss::IconButtonComponent.new(icon: "bell", pressed_icon: "bell-slash", label: "Silenciar", pressed: false,
  #                                      data: { action: "avisos#toggle" })
  #
  # icon:/pressed_icon: nome do ss_icon ou SVG já seguro. href: vira <a>; sem ele, <button type="button">.
  # variant: :ghost (padrão), :tonal, :outline, :danger; size: :md (padrão), :sm. title: troca a dica
  # (padrão = label:, ex. "Ocultar valores (P)").
  # v0.19: type: :submit envia o form (com name:/value:/form: no botão, ex. "marcar como pago" numa
  # agenda); o resto dos atributos (data:, aria:, popovertarget:, style:) vai no elemento.
  class IconButtonComponent < BaseComponent
    VARIANTS = %i[ghost tonal outline danger].freeze

    def initialize(icon:, label:, href: nil, pressed: nil, pressed_icon: nil, variant: :ghost, size: :md, title: nil, type: :button,
                   **rest)
      super(**rest)
      @type = type.to_s == "submit" ? "submit" : "button"
      @icon, @label, @href, @pressed, @pressed_icon = icon, label.to_s, href, pressed, pressed_icon
      @variant = VARIANTS.include?(variant.to_s.to_sym) ? variant.to_s.to_sym : :ghost
      @size = size.to_s == "sm" ? :sm : :md
      @title = title || @label
    end

    def call
      css = classes("ss-icon-btn", ("is-#{@variant}" unless @variant == :ghost), ("is-sm" if @size == :sm),
                    ("is-toggle" if @pressed_icon))
      attrs = root_attrs(class: css, title: @title, "aria-label": @label,
                         "aria-pressed": (@pressed.nil? ? nil : (@pressed ? "true" : "false")))
      body = if @pressed_icon
               safe_join([tag.span(svg(@icon), class: "ss-icon-off", "aria-hidden": "true"),
                          tag.span(svg(@pressed_icon), class: "ss-icon-on", "aria-hidden": "true")])
             else
               svg(@icon)
             end
      @href ? link_to(@href, **attrs) { body } : tag.button(type: @type, **attrs) { body }
    end

    private

    def svg(icon)
      return icon if icon.respond_to?(:html_safe?) && icon.html_safe?

      ss_icon(icon.to_s, size: nil)
    end
  end
end
