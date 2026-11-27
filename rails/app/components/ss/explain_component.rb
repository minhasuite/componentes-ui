module Ss
  # v1.13.0 "confiança na IA e suíte" (par do SsExplain): envolve um valor, KPI ou ponto de gráfico e diz de onde ele
  # vem. No foco ou com o mouse em cima aparece o botão "?" (no toque, sempre à vista); ele abre um popover com o valor,
  # a fórmula/origem ("Soma dos 23 lançamentos de nov"), a lista do que compõe o valor (com link) e, com ai_url:,
  # "Explicar com IA" (o produto responde JSON { text: "…" }; enquanto pensa, os pontinhos e "Cancelar"). O pacote só
  # apresenta: os dados e a IA são do produto.
  #
  #   <%= render(Ss::ExplainComponent.new(value: ss_money(1240), title: "Gastos de novembro",
  #         formula: "Soma dos 23 lançamentos de nov", items: top.map { { label: _1.descricao, value: ss_money(_1.valor), href: lancamento_path(_1) } },
  #         more: 20, more_href: lancamentos_path(mes: "2026-11"), ai_url: explicar_gastos_path)) do %>
  #     <%= render Ss::KpiCardComponent.new(...) %>
  #   <% end %>
  #
  # Onde entra: meu-financeiro (KPI de gastos do mês, saldo e o ponto do gráfico), minhas-vendas (painel de vendas,
  # comissão), meu-gestor (os números dos insights), minhas-compras (total do cupom).
  class ExplainComponent < BaseComponent
    attr_reader :value, :title, :formula, :items, :more, :more_href, :ai_url, :ai_method

    def initialize(value:, title: nil, formula: nil, items: [], more: nil, more_href: nil, ai_url: nil, ai_method: :post, **opts)
      super(**opts)
      @value = value
      @title = title
      @formula = formula
      @items = Array(items).map { _1.to_h.transform_keys(&:to_sym) }
      @more = more.to_i.positive? ? more.to_i : nil
      @more_href = more_href
      @ai_url = ai_url
      @ai_method = ai_method.to_s.upcase
    end

    def t(key, **o) = ss_t("trust.#{key}", **o)
    def uid = @uid ||= "ss-explain-#{object_id}"
    def trigger_label = "#{t("explain_open")}: #{ActionController::Base.helpers.strip_tags(value.to_s)}"
  end
end
