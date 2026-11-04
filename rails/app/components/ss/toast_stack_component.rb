module Ss
  # Pilha de avisos no canto (põe uma vez no layout). O app empilha com Turbo Stream:
  #   <%= render Ss::ToastStackComponent.new %>                      (no layout)
  #   turbo_stream.append "ss-toasts", Ss::ToastComponent.new(...)   (na resposta)
  #   Ss::ToastStackComponent.append(turbo_stream, message: "Salvo", tone: :good)  (atalho)
  # Os flashes da requisição podem entrar já renderizados: Ss::ToastStackComponent.new(toasts: [{ message: notice, tone: :good }]).
  class ToastStackComponent < BaseComponent
    TARGET = "ss-toasts".freeze

    def self.append(turbo_stream, **toast) = turbo_stream.append(TARGET, Ss::ToastComponent.new(**toast))

    def initialize(toasts: [], position: :bottom_right, **opts)
      super(**opts)
      @toasts = toasts
      @position = position.to_s.tr("_", "-")
    end

    def call
      tag.div(**root_attrs(id: TARGET, class: classes("ss-toasts"), data: { position: @position }, "aria-live": "polite", "aria-relevant": "additions")) do
        safe_join([*@toasts.map { render(Ss::ToastComponent.new(**_1)) }, content].compact)
      end
    end
  end
end
