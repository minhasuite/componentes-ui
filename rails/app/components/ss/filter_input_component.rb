module Ss
  # Campo de busca solto para o ss-filter (v0.28): filtra a lista que já está na página, sem ir ao
  # servidor e sem <form> em volta (antes o produto embrulhava num ss_form_with GET só para hospedar o
  # campo). Lupa, rótulo só para o leitor de tela, Esc limpa. Vai dentro do data-controller="ss-filter".
  #
  #   <div data-controller="ss-filter">
  #     <%= render Ss::FilterInputComponent.new(label: "Buscar no manual", placeholder: "Filtrar os verbetes") %>
  #     … itens com data-ss-filter-target="item" …
  #   </div>
  #
  # label: o nome do campo (leitor de tela; padrão "Buscar na lista", do I18n); placeholder: (padrão o label);
  # id: (padrão gerado); value: começa preenchido (o ss-filter já aplica ao conectar). O resto vira atributo
  # do .ss-search (css:, data:).
  class FilterInputComponent < BaseComponent
    LUPA = %(<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path stroke-linecap="round" d="m20 20-3.5-3.5"/></svg>).freeze

    def initialize(label: nil, placeholder: nil, id: nil, value: nil, **rest)
      super(**rest)
      @label, @placeholder, @id, @value = label, placeholder, id, value
    end

    def label = @label.presence || ss_t("filter_input.label", default: "Buscar na lista")
    def input_id = @id || "ss-filter-input-#{object_id}"

    def call
      tag.div(**root_attrs(class: classes("ss-search", "ss-filter-input"), role: "search")) do
        safe_join([
          LUPA.html_safe,
          tag.label(label, for: input_id, class: "ss-sr"),
          tag.input(type: "search", id: input_id, value: @value, placeholder: @placeholder.presence || label, autocomplete: "off",
                    data: { ss_filter_target: "input", action: "input->ss-filter#apply keydown.esc->ss-filter#clear" })
        ])
      end
    end
  end
end
