module Ss
  # Base dos componentes da gem. Convenções:
  # - Só classes .ss-* (CSS em app/assets/tailwind/componentes_ui) e tokens: nada de cor solta.
  # - Comportamento em controller Stimulus da gem (data-controller="ss-x").
  # - `css:` acrescenta classes do app no elemento raiz; `**attrs` vira atributo HTML.
  class BaseComponent < ViewComponent::Base
    # Os helpers da gem (ss_amount, ss_sparkline, ss_avatar...) também dentro dos componentes:
    # o on_load(:action_view) da engine não chega neles.
    include ComponentesUi::Helpers

    def initialize(css: nil, **attrs)
      @css = css
      @attrs = attrs
    end

    private

    # Classes do elemento raiz: as do componente + as do app.
    def classes(*base)
      [*base, @css].flatten.compact.reject { |c| c.to_s.empty? }.join(" ")
    end

    # Atributos extras do elemento raiz (data:, aria:, id: ...), para tag.div(**root_attrs).
    def root_attrs(**own)
      merged = @attrs.merge(own) { |key, a, b| key == :data || key == :aria ? a.to_h.merge(b.to_h) : b }
      merged
    end
  end
end
