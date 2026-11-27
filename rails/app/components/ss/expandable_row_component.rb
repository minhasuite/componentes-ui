module Ss
  # Linha que se expande no lugar para a edição rápida (v1.14.0, par do SsExpandableRow): o título, o subtítulo e o
  # valor da linha; "Editar" abre embaixo dela os campos (o bloco) com Salvar e Cancelar, a altura animada
  # (grid-template-rows 0fr → 1fr, --ss-dur-medium) e o foco no 1º campo. Esc ou Cancelar fecham, desfazem o que foi
  # digitado e devolvem o foco ao "Editar"; Salvar envia o formulário (Turbo) e, deu certo, fecha com "Salvo".
  #
  #   <%= render(Ss::ExpandableRowComponent.new(title: "Mercado Exemplo", subtitle: "12/11 · Mercado", value: ss_money(89.9),
  #                                             url: lancamento_path(l), method: :patch)) do %>
  #     <%= label_tag … %><%= text_field_tag "lancamento[descricao]", l.descricao, class: "ss-input" %>
  #   <% end %>
  #
  # url:/method: o formulário em volta dos campos (sem url:, só abre e fecha: o produto cuida do envio).
  # open: true já começa aberta (o erro do servidor voltou). tag: :div/:li. id: o do painel sai dele.
  class ExpandableRowComponent < BaseComponent
    renders_one :leading

    def initialize(title:, subtitle: nil, value: nil, url: nil, method: :patch, open: false, save_label: nil, cancel_label: nil,
                   edit_label: nil, tag: :div, **rest)
      super(**rest)
      @title, @subtitle, @value, @url, @method, @open = title, subtitle, value, url, method, open
      @save_label, @cancel_label, @edit_label, @tag = save_label, cancel_label, edit_label, tag
    end

    def uid = @uid ||= (@attrs[:id] || "ss-xrow-#{object_id}")
    def save_label = @save_label || ss_t("interface.expand_save", default: "Salvar")
    def cancel_label = @cancel_label || ss_t("interface.expand_cancel", default: "Cancelar")
    def edit_label = @edit_label || ss_t("interface.expand_edit", default: "Editar")

    def call
      content_tag(@tag, **root_attrs(id: uid, class: classes("ss-xrow", ("is-open" if @open)),
                                     data: { controller: "ss-expandable-row", ss_expandable_row_saved_value: ss_t("interface.expand_saved", default: "Salvo") })) do
        safe_join([head, panel])
      end
    end

    private

    def head
      tag.div(class: "ss-xrow-head") do
        safe_join([
          (tag.span(leading, class: "ss-xrow-lead") if leading?),
          tag.div(safe_join([tag.strong(@title, class: "ss-xrow-title"), (tag.small(@subtitle, class: "ss-xrow-sub") if @subtitle)].compact), class: "ss-xrow-main"),
          (tag.span(@value, class: "ss-xrow-value num") if @value),
          tag.button(type: "button", class: "ss-btn ss-btn-ghost ss-btn-sm ss-xrow-toggle", "aria-expanded": @open.to_s, "aria-controls": "#{uid}-panel",
                     "aria-label": ss_t("interface.expand_label", default: "Editar %{title}", title: @title),
                     data: { ss_expandable_row_target: "toggle", action: "ss-expandable-row#toggle" }) do
            safe_join([ss_icon("pencil", size: nil), tag.span(edit_label, class: "ss-xrow-edit-text")])
          end,
          tag.span(class: "ss-sr", role: "status", data: { ss_expandable_row_target: "status" })
        ].compact)
      end
    end

    def panel
      fields = safe_join([tag.div(content, class: "ss-xrow-fields"), actions])
      inner = @url ? form_with(url: @url, method: @method, class: "ss-xrow-form", data: { action: "turbo:submit-end->ss-expandable-row#saved" }) { fields } : tag.div(fields, class: "ss-xrow-form")
      tag.div(tag.div(inner, class: "ss-xrow-inner"), id: "#{uid}-panel", class: "ss-xrow-panel", role: "region", "aria-label": @title,
              inert: (@open ? nil : true), data: { ss_expandable_row_target: "panel", action: "keydown->ss-expandable-row#key" })
    end

    def actions
      tag.div(class: "ss-xrow-actions") do
        safe_join([
          tag.button(cancel_label, type: "button", class: "ss-btn ss-btn-ghost", data: { action: "ss-expandable-row#cancel" }),
          tag.button(save_label, type: (@url ? "submit" : "button"), class: "ss-btn ss-btn-primary", data: (@url ? {} : { action: "ss-expandable-row#close" }))
        ])
      end
    end
  end
end
