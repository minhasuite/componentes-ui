module Ss
  # Ações no fim de uma linha de tabela/lista (v0.18): no computador (dispositivo com hover de
  # verdade: mouse/trackpad) aparecem ao passar o mouse na linha ou ao focar nela; no toque (celular,
  # tablet) ficam sempre à vista. CSS puro do Tailwind 4: @media (hover: hover) and (pointer: fine);
  # nada de @custom-variant hover no produto. Abertas também com o menu (popover/details) aberto.
  #
  #   <%= render Ss::RowActionsComponent.new(edit: edit_conta_path(c), destroy: conta_path(c), confirm: "Remover a conta?") %>
  #   <%= render(Ss::RowActionsComponent.new) do %>…botões e menu próprios…<% end %>
  #
  # edit: URL do Editar (abre no diálogo global: edit_frame: "modal"; nil = navega); destroy: URL do
  # Remover (button_to DELETE; confirm: põe data-turbo-confirm, o Ss::ConfirmDialogComponent global
  # mostra); edit_label:/destroy_label:; icons: true = botões só de ícone (lápis/lixeira) com o rótulo
  # no aria-label e na dica; reveal: false = sempre à vista. O bloco vem depois do Editar e antes do
  # Remover. Na Ss::DataTableComponent, use t.actions { |row| … } (mesma regra).
  #
  # Fora de tabela: a "linha" é o tr, li, .ss-item, .ss-row, .ss-card ou [data-ss-row] mais próximo.
  class RowActionsComponent < BaseComponent
    def initialize(edit: nil, destroy: nil, confirm: nil, edit_label: nil, destroy_label: nil, edit_frame: "modal",
                   icons: false, reveal: true, method: :delete, **rest)
      super(**rest)
      @edit, @destroy, @confirm, @edit_frame, @icons, @reveal, @method = edit, destroy, confirm, edit_frame, icons, reveal, method
      @edit_label = edit_label || ss_t("common.edit", default: "Editar")
      @destroy_label = destroy_label || ss_t("common.remove", default: "Remover")
    end

    def call
      tag.div(**root_attrs(class: classes("ss-row-actions", ("is-reveal" if @reveal)))) do
        safe_join([edit_button, (content if content.present?), destroy_button].compact)
      end
    end

    private

    def edit_button
      return unless @edit

      data = @edit_frame ? { turbo_frame: @edit_frame } : {}
      if @icons
        link_to(@edit, class: "ss-icon-btn is-sm", title: @edit_label, "aria-label": @edit_label, data:) { ss_icon("pencil", size: nil) }
      else
        link_to(@edit_label, @edit, class: "ss-btn ss-btn-ghost ss-btn-sm", data:)
      end
    end

    def destroy_button
      return unless @destroy

      form = { class: "ss-row-actions-form", data: (@confirm ? { turbo_confirm: @confirm, turbo_confirm_tone: "danger" } : {}) }
      if @icons
        button_to(@destroy, method: @method, class: "ss-icon-btn is-sm is-danger", title: @destroy_label, "aria-label": @destroy_label, form:) { ss_icon("trash", size: nil) }
      else
        button_to(@destroy_label, @destroy, method: @method, class: "ss-btn ss-btn-danger ss-btn-sm", form:)
      end
    end
  end
end
