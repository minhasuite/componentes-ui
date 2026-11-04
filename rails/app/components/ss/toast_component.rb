module Ss
  # Um aviso da pilha (.ss-toast). Some sozinho em `duration` s (pausa com o mouse
  # em cima ou com foco); com undo_url mostra o anel de contagem e o Desfazer.
  #   turbo_stream.append "ss-toasts", Ss::ToastComponent.new(message: "Pedido excluído", tone: :good,
  #     undo_url: restaurar_pedido_path(p), undo_method: :post)
  # tone: :good, :bad ou nil (marca). sticky: true não some sozinho (fica até fechar).
  # v0.10.1: role: troca o papel (padrão: "alert" no :bad, "status" no resto), ex. role: "alert"
  # num aviso de marca urgente. A posição é da pilha (ToastStackComponent, position: por aviso).
  class ToastComponent < BaseComponent
    ICONS = {
      good: %(<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="10" fill="currentColor" opacity=".18"/><path d="M7.5 12.5l3 3 6-6.5" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/></svg>),
      bad: %(<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="10" fill="currentColor" opacity=".18"/><path d="M12 7v6m0 3.5v.01" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"/></svg>),
      info: %(<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="10" fill="currentColor" opacity=".18"/><path d="M12 11v6m0-9.5v.01" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"/></svg>)
    }.freeze

    def initialize(message:, tone: nil, undo_url: nil, undo_method: :post, undo_label: nil, duration: 5, dismissible: true, sticky: false, role: nil, **opts)
      super(**opts)
      @role = role
      @message = message
      @tone = tone&.to_sym
      @undo_url = undo_url
      @undo_method = undo_method
      @undo_label = undo_label || ss_t("toast.undo", default: "Desfazer")
      @duration = duration
      @dismissible = dismissible
      @sticky = sticky
    end

    def call
      tag.div(**root_attrs(class: classes("ss-toast", ("is-#{@tone}" if %i[good bad].include?(@tone)), ("is-paused" if @sticky)),
                           role: @role || (@tone == :bad ? "alert" : "status"), style: "--ss-toast-d:#{@duration}s",
                           data: { controller: "ss-toast", ss_toast_duration_value: @duration * 1000, ss_toast_sticky_value: @sticky,
                                   action: "mouseenter->ss-toast#pause mouseleave->ss-toast#resume focusin->ss-toast#pause focusout->ss-toast#resume" })) do
        safe_join([
          (@undo_url ? tag.span(@duration, class: "ss-toast-timer num", "aria-hidden": true, data: { ss_toast_target: "timer" }) : ICONS[@tone || :info].html_safe),
          tag.span(@message, class: "ss-toast-msg"),
          undo,
          (tag.button("×", type: "button", class: "ss-toast-close", "aria-label": ss_t("toast.close", default: "Fechar aviso"), data: { action: "ss-toast#close" }) if @dismissible)
        ].compact)
      end
    end

    private

    def undo
      return nil unless @undo_url

      if @undo_method.to_s == "get"
        link_to(@undo_label, @undo_url)
      else
        button_to(@undo_label, @undo_url, method: @undo_method, form: { class: "ss-toast-undo" })
      end
    end
  end
end
