module Ss
  # Card de indicador (v0.12, par do SsKpiCard): um número só num card, com o cabeçalho padrão
  # de card (Ss::CardHeaderComponent: rótulo como título, caption: embaixo, ícone tonal à direita),
  # o valor em DM Mono no tamanho de card (não o de herói), variação colorida pelo sentido e
  # minigráfico opcional na base. Para vários números lado a lado numa faixa, use o KpiStrip.
  #
  #   render Ss::KpiCardComponent.new(label: "Gasto do mês", value: "R$ 312,75", money: true, icon: svg,
  #                                   caption: "01/11 a 30/11", delta: "+4%", good: false, hint: "vs. outubro",
  #                                   spark: [3, 5, 4, 8], url: energia_path)
  #
  # money: true põe os centavos menores (ss_amount). good: true/false pinta a variação (verde/vermelho);
  # nil neutro; trend: :up/:down troca a seta (padrão: pelo sinal do delta). url: faz o card todo
  # ser um link. tone: o do ícone (ver CardHeaderComponent).
  class KpiCardComponent < BaseComponent
    def initialize(label:, value:, icon: nil, tone: nil, caption: nil, delta: nil, good: nil, trend: nil, hint: nil,
                   spark: nil, url: nil, money: false, **rest)
      super(**rest)
      @label, @value, @icon, @tone, @caption = label, value, icon, tone, caption
      @delta, @good, @trend, @hint, @spark, @url, @money = delta, good, trend, hint, spark, url, money
    end

    def call
      tag.div(**root_attrs(class: classes("ss-card", "ss-kpi-card", ("is-link" if @url)))) do
        safe_join([
          render(Ss::CardHeaderComponent.new(title: @url ? link_to(@label, @url, class: "ss-kpi-card-link") : @label,
                                             subtitle: @caption, icon: @icon, tone: @tone || :accent)),
          tag.div(@money ? ss_amount(@value) : tag.span(@value, class: "num"), class: "ss-kpi-card-value"),
          (foot if @delta || @hint),
          (tag.div(ss_sparkline(@spark, height: 36), class: "ss-kpi-card-spark") if @spark.to_a.size > 1)
        ].compact)
      end
    end

    private

    def foot
      up = @trend ? @trend.to_s == "up" : !@delta.to_s.strip.start_with?("-", "−")
      tone = @good.nil? ? nil : (@good ? "is-good" : "is-bad")
      sense = @good.nil? ? "" : (@good ? ss_t("kpi_strip.good", default: " (bom)") : ss_t("kpi_strip.bad", default: " (ruim)"))
      tag.div(class: "ss-kpi-card-foot") do
        safe_join([
          (if @delta
             tag.span(class: ["ss-delta", tone].compact.join(" "), "aria-label": ss_t("kpi_strip.delta", default: "Variação %{delta}%{sense}", delta: @delta, sense:)) do
               safe_join([(up ? KpiStripComponent::UP : KpiStripComponent::DOWN).html_safe, @delta])
             end
           end),
          (tag.small(@hint) if @hint)
        ].compact)
      end
    end
  end
end
