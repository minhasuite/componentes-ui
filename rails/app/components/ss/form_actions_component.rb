module Ss
  # Rodapé de formulário (v0.18): Cancelar + o botão que envia (+ o que vier no bloco, ex. "Salvar e
  # criar outro"), alinhados à direita. Dentro do Ss::DialogComponent fica preso no fim do painel
  # (sticky) e o Cancelar fecha o diálogo; numa página, cancel_href: faz do Cancelar um link.
  #
  #   <%= render Ss::FormActionsComponent.new(form: f) %>                                   (Cancelar · Salvar)
  #   <%= render(Ss::FormActionsComponent.new(form: f, submit: "Criar")) do %>
  #     <button type="submit" name="save_and_new" value="1" class="ss-btn ss-btn-outline" data-ss-dialog-keep-open>Salvar e criar outro</button>
  #   <% end %>
  #   <%= render Ss::FormActionsComponent.new(form: f, dialog: false, cancel_href: pedidos_path) %>
  #
  # form: o form builder (sem ele, <button type="submit">); submit: texto (padrão "Salvar"); submitting:
  # texto enquanto envia (data-turbo-submits-with; padrão "Salvando…"; false tira); cancel: false tira o
  # Cancelar; cancel_label:; dialog: true (padrão) = Cancelar com data-ss-dialog-dismiss e preso no fim
  # do painel; sticky: false solta; align: :end (padrão), :start, :between.
  # v0.19: submit: false tira o botão de enviar (a ação vem no bloco, ex. um Ss::ButtonComponent com
  # method: :post fora de formulário: "Cancelar · Aplicar em 12").
  class FormActionsComponent < BaseComponent
    ALIGN = %i[end start between].freeze

    def initialize(form: nil, submit: nil, submitting: nil, cancel: true, cancel_label: nil, cancel_href: nil, dialog: true,
                   sticky: nil, align: :end, **rest)
      super(**rest)
      @form, @cancel, @cancel_href, @dialog = form, cancel, cancel_href, dialog
      @no_submit = submit == false
      @submit = submit || ss_t("common.save", default: "Salvar")
      @submitting = submitting.nil? ? ss_t("common.saving", default: "Salvando…") : submitting
      @cancel_label = cancel_label || ss_t("common.cancel", default: "Cancelar")
      @sticky = sticky.nil? ? dialog : sticky
      @align = ALIGN.include?(align.to_s.to_sym) ? align.to_s.to_sym : :end
    end

    def call
      tag.div(**root_attrs(class: classes("ss-form-actions", ("is-sticky" if @sticky), ("is-#{@align}" unless @align == :end)))) do
        safe_join([cancel_button, content, submit_button].compact)
      end
    end

    private

    def cancel_button
      return unless @cancel
      return link_to(@cancel_label, @cancel_href, class: "ss-btn ss-btn-ghost") if @cancel_href

      tag.button(@cancel_label, type: "button", class: "ss-btn ss-btn-ghost", data: ({ ss_dialog_dismiss: "" } if @dialog))
    end

    def submit_button
      return if @no_submit

      data = @submitting ? { turbo_submits_with: @submitting } : {}
      return @form.button(@submit, type: "submit", class: "ss-btn ss-btn-primary", data:) if @form

      tag.button(@submit, type: "submit", class: "ss-btn ss-btn-primary", data:)
    end
  end
end
