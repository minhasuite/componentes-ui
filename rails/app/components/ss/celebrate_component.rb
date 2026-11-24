module Ss
  # Comemoração de conquista com a regra da suíte (v1.9, par do SsCelebrate(kind:) do Flutter):
  # tipos :goal (meta batida), :streak (sequência mantida) e :first_use (primeiro uso); no máximo
  # uma por sessão por tipo (sessionStorage "ss-celebrate:<tipo>", a mesma regra do
  # SsCelebrationGate). Meta e primeiro uso soltam o confete da suíte; sequência dá o pulo e o
  # estouro em volta do conteúdo (sem confete). O leitor de tela ouve "Meta batida!" (aria-live).
  # Nada de movimento com prefers-reduced-motion (o anúncio continua).
  #
  #   <%= render Ss::CelebrateComponent.new(kind: :goal, achieved: meta.batida?) do %>
  #     <%= render Ss::KpiCardComponent.new(...) %>
  #   <% end %>
  #   <%= render(Ss::CelebrateComponent.new(kind: :first_use, on: :click)) do %>
  #     <button data-action="ss-celebrate#celebrate">Salvar</button>
  #   <% end %>
  #
  # achieved: falso não comemora (o conteúdo sai igual). on: :connect (padrão, ao aparecer) ou
  # :click (só pelo data-action="ss-celebrate#celebrate"). Por JS: o evento "ss:celebrate" no elemento.
  class CelebrateComponent < BaseComponent
    KINDS = %w[goal streak first_use].freeze
    TEXTS = { "goal" => "Meta batida!", "streak" => "Sequência mantida!", "first_use" => "Primeiro passo dado!" }.freeze

    # Normaliza o tipo (:firstUse, "first-use" e :first_use valem o mesmo); desconhecido = nil.
    def self.kind(value)
      return nil if value.nil?

      k = value.to_s.gsub(/([a-z])([A-Z])/, '\1_\2').tr("-", "_").downcase
      KINDS.include?(k) ? k : nil
    end

    def initialize(kind:, achieved: true, on: :connect, tag_name: :div, **rest)
      super(**rest)
      @kind = self.class.kind(kind) or raise ArgumentError, "kind: use #{KINDS.join(", ")}"
      @achieved = achieved
      @on = on.to_s == "click" ? "click" : "connect"
      @tag_name = tag_name
    end

    def announcement = ss_t("celebrate.#{@kind}", default: TEXTS[@kind])

    def call
      data = { controller: "ss-celebrate", ss_celebrate_kind_value: @kind,
               ss_celebrate_auto_value: @achieved && @on == "connect", ss_celebrate_text_value: announcement }
      content_tag(@tag_name, **root_attrs(class: classes("ss-celebrate", "is-#{@kind.tr("_", "-")}"), data: data)) do
        safe_join([content, tag.span(class: "ss-sr", aria: { live: "polite" }, data: { ss_celebrate_target: "live" })])
      end
    end
  end
end
