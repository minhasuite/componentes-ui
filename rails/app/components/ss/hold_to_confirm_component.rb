module Ss
  # Segurar para confirmar (v1.9, par do SsHoldToConfirm): excluir, encerrar, transferir. O fundo enche da
  # esquerda enquanto o botão fica pressionado (mouse, dedo, Espaço ou Enter); no fim mostra ✓ done_label e
  # envia o formulário. Soltou antes, volta. O clique do leitor de tela confirma direto.
  #
  #   render Ss::HoldToConfirmComponent.new(label: "Segure para excluir", url: cliente_path(c), method: :delete, danger: true)
  #   render Ss::HoldToConfirmComponent.new(label: "Segure para transferir")   # sem url: evento "ss-hold-confirm:confirm"
  #
  # duration: ms para encher (1200). icon: nome do ss_icon ("hand"). danger: vermelho de erro.
  # Sem url: o evento "ss-hold-confirm:confirm" (bubbles); depois de 1,6 s o botão volta ao começo.
  # Reduzir movimento: o fundo enche igual (é o retorno do gesto), sem o encolher do botão.
  class HoldToConfirmComponent < BaseComponent
    attr_reader :label, :icon

    def initialize(label:, url: nil, method: :post, params: {}, done_label: nil, icon: "hand", duration: 1200, danger: false, disabled: false, **rest)
      super(**rest)
      @label, @url, @http_method, @params = label, url, method, params.to_h
      @done_label, @icon, @duration, @danger, @disabled = done_label, icon, duration.to_i.clamp(300, 5000), danger, disabled
    end

    def done_label = @done_label || ss_t("hold_confirm.done", default: "Confirmado")
    def hint = ss_t("hold_confirm.hint", default: "Segure para confirmar")
    def uid = @uid ||= "ss-hold-#{object_id}"

    def call
      button = tag.button(type: "button", **root_attrs(
        class: classes("ss-hold-confirm", ("is-danger" if @danger)), disabled: (@disabled || nil), "aria-describedby": "#{uid}-h",
        data: { controller: "ss-hold-confirm", state: "idle", ss_hold_confirm_duration_value: @duration, ss_hold_confirm_done_label_value: done_label,
                ss_hold_confirm_label_value: label,
                action: "pointerdown->ss-hold-confirm#press pointerup->ss-hold-confirm#release pointerleave->ss-hold-confirm#release " \
                        "pointercancel->ss-hold-confirm#release keydown->ss-hold-confirm#key keyup->ss-hold-confirm#keyup click->ss-hold-confirm#click " \
                        "contextmenu->ss-hold-confirm#menu" }
      )) do
        safe_join([
          tag.span(row(ss_icon(icon, size: nil), label), class: "ss-hold-base"),
          tag.span(row(safe_join([ss_icon(icon, size: nil, css: "ss-hold-ico"), ss_icon("check", size: nil, css: "ss-hold-ok")]),
                       safe_join([tag.span(label, class: "ss-hold-l"), tag.span(done_label, class: "ss-hold-d")])), class: "ss-hold-fill", "aria-hidden": "true"),
          tag.span(label, class: "ss-sr", data: { ss_hold_confirm_target: "name" }),
          tag.span(hint, id: "#{uid}-h", class: "ss-sr")
        ])
      end
      return button unless @url

      form_with(url: @url, method: @http_method, class: "ss-hold-form") do
        safe_join([*@params.map { |k, v| hidden_field_tag(k, v, id: nil) }, button])
      end
    end

    private

    def row(ico, text) = tag.span(safe_join([ico, tag.span(text, class: "ss-hold-text")]), class: "ss-hold-row", "aria-hidden": "true")
  end
end
