module Ss
  # Pergunta de um campo só numa caixa da suíte (v0.10.2, par do showSsPrompt): "Nova seção",
  # "Renomear", "Nome da cena". Dois jeitos:
  #
  # 1. Formulário de verdade (sem JS próprio): url: recebe o campo name: (POST; method: troca).
  #      <%= render Ss::PromptDialogComponent.new(id: "nova-secao", title: "Nova seção", label: "Título",
  #            url: sections_path, name: "section[title]") %>
  #      <button type="button" class="ss-btn ss-btn-primary" data-ss-prompt-open="nova-secao">Nova seção</button>
  #
  # 2. Por JS (sem url:): document.getElementById("renomear").ssPrompt({ value: "Sala", title: "Renomear" })
  #      .then((texto) => …)  // null se cancelou
  #
  # value: (inicial), placeholder:, hint: (texto embaixo do título), required: (padrão true: o OK
  # fica apagado com o campo vazio), max_length:, autocomplete:, ok_label:, cancel_label:.
  # data-ss-prompt-value no botão que abre troca o valor inicial (renomear o item da linha).
  class PromptDialogComponent < BaseComponent
    def initialize(id:, title:, label: nil, url: nil, method: :post, name: "value", value: nil, placeholder: nil, hint: nil,
                   required: true, max_length: nil, autocomplete: "off", ok_label: nil, cancel_label: nil, **opts)
      super(**opts)
      @id, @title, @label, @url, @method, @name, @value = id, title, label, url, method, name, value
      @placeholder, @hint, @required, @max_length, @autocomplete = placeholder, hint, required, max_length, autocomplete
      @ok_label, @cancel_label = ok_label, cancel_label
    end

    attr_reader :id, :title, :hint

    def label = @label || ss_t("prompt_dialog.label", default: "Nome")
    def ok_label = @ok_label || ss_t("prompt_dialog.ok", default: "Confirmar")
    def cancel_label = @cancel_label || ss_t("prompt_dialog.cancel", default: "Cancelar")
    def server? = @url.present?

    def call
      tag.dialog(**root_attrs(id:, class: classes("ss-dialog", "ss-prompt-dialog"), "aria-labelledby": "#{id}-t",
                              data: { controller: "ss-prompt-dialog", ss_prompt_dialog_required_value: @required,
                                      action: "close->ss-prompt-dialog#closed click->ss-prompt-dialog#backdrop" })) do
        form_attrs = server? ? { action: @url, method: "post", "accept-charset": "UTF-8" } : { method: "dialog" }
        tag.form(**form_attrs, data: { action: "submit->ss-prompt-dialog#submit" }) do
          safe_join([
            (hidden_fields if server?),
            tag.div(class: "ss-dialog-body") do
              safe_join([
                tag.h2(title, id: "#{id}-t", data: { ss_prompt_dialog_target: "title" }),
                (tag.p(hint, class: "ss-field-help") if hint),
                tag.label(class: "ss-field", style: "text-align: left") do
                  safe_join([tag.span(label, class: "ss-label"),
                             tag.input(type: "text", class: "ss-input", name: (@name if server?), value: @value, placeholder: @placeholder,
                                       required: @required, maxlength: @max_length, autocomplete: @autocomplete, autofocus: true,
                                       data: { ss_prompt_dialog_target: "input", action: "input->ss-prompt-dialog#sync" })])
                end
              ].compact)
            end,
            tag.div(class: "ss-dialog-actions") do
              safe_join([tag.button(ok_label, type: "submit", value: "ok", class: "ss-btn ss-btn-primary", data: { ss_prompt_dialog_target: "ok" }),
                         tag.button(cancel_label, type: "button", class: "ss-btn ss-btn-ghost", data: { action: "ss-prompt-dialog#cancel" })])
            end
          ].compact)
        end
      end
    end

    private

    def hidden_fields
      token = (helpers.form_authenticity_token rescue nil)
      safe_join([(tag.input(type: "hidden", name: "_method", value: @method.to_s) unless @method.to_s == "post"),
                 (tag.input(type: "hidden", name: "authenticity_token", value: token) if token)].compact)
    end
  end
end
