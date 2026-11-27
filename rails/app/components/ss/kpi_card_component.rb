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
  # v0.20: value_tone: :danger/:success/:warning/:accent pinta o valor (saldo negativo, meta batida); par do
  # SsKpiCard(valueTone:).
  # v1.14.0: animate: true (o padrão, par do SsKpiCard(animate:)): o valor é o Ss::OdometerComponent, que rola cada
  # dígito ao mudar (morph do Turbo, turbo_stream, JS no data-ss-odometer-text-value). animate: false volta ao texto
  # parado (o ss_amount de antes).
  class KpiCardComponent < BaseComponent
    def initialize(label:, value:, icon: nil, tone: nil, caption: nil, delta: nil, good: nil, trend: nil, hint: nil,
                   spark: nil, url: nil, money: false, value_tone: nil, animate: true, **rest)
      super(**rest)
      @label, @value, @icon, @tone, @caption = label, value, icon, tone, caption
      @value_tone = value_tone && ComponentesUi.tone(value_tone).to_s
      @delta, @good, @trend, @hint, @spark, @url, @money = delta, good, trend, hint, spark, url, money
      @animate = animate
    end

    def call
      tag.div(**root_attrs(class: classes("ss-card", "ss-kpi-card", ("is-link" if @url)))) do
        safe_join([
          render(Ss::CardHeaderComponent.new(title: @url ? link_to(@label, @url, class: "ss-kpi-card-link") : @label,
                                             subtitle: @caption, icon: @icon, tone: @tone || :accent)),
          tag.div(value_html, class: "ss-kpi-card-value", data: { tone: @value_tone }.compact),
          (foot if @delta || @hint),
          (tag.div(ss_sparkline(@spark, height: 36), class: "ss-kpi-card-spark") if @spark.to_a.size > 1)
        ].compact)
      end
    end

    private

    def value_html
      return render(Ss::OdometerComponent.new(text: @value.to_s, size: "1em", cents: @money, css: "ss-kpi-odo")) if @animate && @value.to_s.match?(/\d/)

      @money ? ss_amount(@value) : tag.span(@value, class: "num")
    end

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
