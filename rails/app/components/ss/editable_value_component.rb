module Ss
  # Valor que se edita ao toque (v0.20, par do SsEditableValue): rótulo pequeno, o valor (DM Mono com
  # mono: true) e "editar" na cor da marca; o clique abre a edição do app (href: para um diálogo em
  # turbo-frame, ou data: { action: } sem href). Lido como "Preço novo: R$ 12,90, Editar".
  #   render Ss::EditableValueComponent.new(label: "novo", value: ss_money(12.9), href: edit_preco_path(i), data: { turbo_frame: "modal" })
  # Para editar no lugar (o valor vira campo), use o Ss::InlineEditComponent. align: :end (padrão) ou :start.
  class EditableValueComponent < BaseComponent
    def initialize(value:, label: nil, href: nil, mono: true, edit_label: nil, align: :end, **rest)
      super(**rest)
      @value, @label, @href, @mono, @align = value, label, href, mono, align
      @edit_label = edit_label || ss_t("common.edit", default: "Editar")
    end

    def call
      aria = [(@label ? "#{@label}: #{strip_tags(@value.to_s)}" : strip_tags(@value.to_s)), @edit_label].join(", ")
      attrs = root_attrs(class: classes("ss-editable-value", ("is-start" if @align.to_s == "start")), "aria-label": aria)
      body = safe_join([(tag.small(@label) if @label), tag.span(@value, class: ["ss-editable-value-v", ("num" if @mono)].compact.join(" ")),
                        tag.em(@edit_label.downcase)].compact)
      @href ? link_to(@href, **attrs) { body } : tag.button(type: "button", **attrs) { body }
    end
  end
end
