module Ss
  # Arrastar a bolinha até o fim para confirmar (v1.9, par do SsSwipeToConfirm): pagar, fechar o pedido, encerrar.
  # Evita o clique sem querer. Passou de 85%: gruda no fim, mostra carregando enquanto o formulário vai e termina
  # em ✓ done_label. Se o servidor recusar (turbo:submit-end sem sucesso), a bolinha volta.
  #
  #   render Ss::SwipeToConfirmComponent.new(label: "Deslize para pagar R$ 120,00", url: pagamento_path(p), method: :post)
  #   render Ss::SwipeToConfirmComponent.new(label: "Encerrar o caixa", id: "fechar")   # sem url: só o evento
  #
  # Sem url:, dispara "ss-swipe-confirm:confirm" (detail: { done(), fail() }); quem chamar event.preventDefault()
  # responde com done()/fail(); sem resposta, conclui na hora. params: viram campos escondidos do formulário.
  # Teclado e leitor de tela: a bolinha é um botão; Enter/Espaço (ou o toque do leitor) confirma direto.
  # done: true já começa concluído (a tela recarregou depois de pago). disabled: apagado e parado.
  # Reduzir movimento: sem a mola da volta.
  # v1.14.0: o ✓ da bolinha é o Ss::SuccessCheckComponent.mark (se desenha ao concluir), com a vibração de sucesso;
  # sound: true dispara o gancho `ss:sound` { name: "success" }.
  class SwipeToConfirmComponent < BaseComponent
    attr_reader :label, :icon

    def initialize(label:, url: nil, method: :post, params: {}, done_label: nil, icon: "arrow-right", done: false, disabled: false, sound: false, **rest)
      super(**rest)
      @label, @url, @http_method, @params = label, url, method, params.to_h
      @done_label, @icon, @done, @disabled = done_label, icon, done, disabled
      @sound = sound
    end

    def done_label = @done_label || ss_t("swipe_confirm.done", default: "Pronto")
    def hint = ss_t("swipe_confirm.hint", default: "Arraste até o fim para confirmar")
    def state = @done ? "done" : "idle"
    def uid = @uid ||= "ss-swipe-#{object_id}"

    def call
      data = { controller: "ss-swipe-confirm", state:, ss_swipe_confirm_done_label_value: done_label, ss_swipe_confirm_label_value: label, ss_swipe_confirm_sound_value: (@sound || nil),
               ss_swipe_confirm_loading_value: ss_t("swipe_confirm.loading", default: "Confirmando…") }
      attrs = root_attrs(class: classes("ss-swipe-confirm", ("is-disabled" if @disabled)), data:)
      return tag.div(**attrs) { body } unless @url

      form_with(url: @url, method: @http_method, **attrs) do
        safe_join([*@params.map { |k, v| hidden_field_tag(k, v, id: nil) }, body])
      end
    end

    private

    def body
      thumb = tag.button(type: "button", class: "ss-swipe-thumb", disabled: (@disabled || nil), "aria-label": (@done ? done_label : label),
                         "aria-describedby": (@done ? nil : "#{uid}-h"), data: { ss_swipe_confirm_target: "thumb",
                         action: "pointerdown->ss-swipe-confirm#down click->ss-swipe-confirm#click" }) do
        safe_join([ss_icon(icon, size: nil, css: "ss-swipe-ico"), tag.span(class: "ss-swipe-spin", "aria-hidden": "true"), Ss::SuccessCheckComponent.mark(css: "ss-swipe-ok")])
      end
      tag.div(class: "ss-swipe-track", data: { ss_swipe_confirm_target: "track" }) do
        safe_join([
          tag.span(class: "ss-swipe-trail", "aria-hidden": "true"),
          tag.span(label, class: "ss-swipe-label", "aria-hidden": "true"),
          tag.span(done_label, class: "ss-swipe-done", "aria-hidden": "true"),
          thumb,
          tag.span(hint, id: "#{uid}-h", class: "ss-sr"),
          tag.span(class: "ss-sr", role: "status", data: { ss_swipe_confirm_target: "status" })
        ])
      end
    end
  end
end
