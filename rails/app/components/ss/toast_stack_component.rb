module Ss
  # Pilha de avisos no canto (põe uma vez no layout). O app empilha com Turbo Stream:
  #   <%= render Ss::ToastStackComponent.new %>                      (no layout)
  #   turbo_stream.append "ss-toasts", Ss::ToastComponent.new(...)   (na resposta)
  #   Ss::ToastStackComponent.append(turbo_stream, message: "Salvo", tone: :good)  (atalho)
  # Os flashes da requisição podem entrar já renderizados: Ss::ToastStackComponent.new(toasts: [{ message: notice, tone: :good }]).
  #
  # v0.10.1: cada aviso de toasts: aceita role: (vai para o ToastComponent) e position:
  # (:top_center, :bottom_left…). Aviso com posição diferente da pilha sai numa pilha à parte,
  # id "ss-toasts-<posição>" (ex. ss-toasts-top-center), que também recebe turbo_stream.append.
  class ToastStackComponent < BaseComponent
    TARGET = "ss-toasts".freeze

    def self.target_for(position) = "#{TARGET}-#{position.to_s.tr("_", "-")}"

    def self.append(turbo_stream, **toast) = turbo_stream.append(TARGET, Ss::ToastComponent.new(**toast))

    def initialize(toasts: [], position: :bottom_right, **opts)
      super(**opts)
      @toasts = toasts
      @position = position.to_s.tr("_", "-")
    end

    def call
      groups = @toasts.map { _1.to_h.transform_keys(&:to_sym) }.group_by { (_1[:position] || @position).to_s.tr("_", "-") }
      main = tag.div(**root_attrs(id: TARGET, class: classes("ss-toasts"), data: { position: @position }, "aria-live": "polite", "aria-relevant": "additions")) do
        safe_join([*toast_tags(groups.delete(@position)), content].compact)
      end
      extra = groups.map do |pos, list|
        tag.div(safe_join(toast_tags(list)), id: self.class.target_for(pos), class: "ss-toasts", data: { position: pos }, "aria-live": "polite", "aria-relevant": "additions")
      end
      safe_join([main, *extra])
    end

    private

    def toast_tags(list) = Array(list).map { render(Ss::ToastComponent.new(**_1.except(:position))) }
  end
end
