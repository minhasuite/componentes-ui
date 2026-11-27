module Ss
  # v1.13.0 "confiança na IA e suíte" (par do SsSuiteSwitcher): os produtos da suíte que a conta usa (ícone na cor de
  # cada um, nome, último acesso e o selo de avisos) e "Conhecer" os que ela ainda não usa. Abre num popover pelo botão
  # de grade; na moldura vai ao lado do avatar: Ss::AppShellComponent#with_suite. Recebe a lista por parâmetro: a gem não
  # sabe quais produtos existem (quem sabe é a central de Licenças, que o produto consulta).
  #
  #   <% s.with_suite do %>
  #     <%= render Ss::SuiteSwitcherComponent.new(products: [
  #           { id: "vendas", name: "Minhas Vendas", icon: "shopping-bag", color: "#0f766e", href: "https://minhasvendas.…",
  #             last_used_at: 2.hours.ago, current: true },
  #           { id: "gestor", name: "Meu Gestor", icon: "chart-bar", color: "#5a45e8", href: "…", badge: 3, last_used_at: 3.days.ago },
  #           { id: "financeiro", name: "Meu Financeiro", icon: "cash", color: "#2563eb", active: false,
  #             description: "Dinheiro pessoal em ordem", discover_href: "https://www.minhasuite.com/financeiro" }]) %>
  #   <% end %>
  #
  # color: é dado (a marca de cada produto, #rrggbb); vai inline como --ss-suite-c. Inválida, o ícone fica na marca da
  # página. Onde entra: na moldura de todos os webs da suíte (minhas-vendas, meu-gestor, meu-financeiro, licenças).
  class SuiteSwitcherComponent < BaseComponent
    def initialize(products:, label: nil, now: nil, **opts)
      super(**opts)
      @products = Array(products).map { _1.to_h.transform_keys(&:to_sym) }
      @label = label
      @now = now
    end

    def t(key, **o) = ss_t("trust.#{key}", **o)
    def label = @label || t("suite_open")
    def uid = @uid ||= "ss-suite-#{object_id}"
    def yours = @products.reject { _1[:active] == false }
    def discover = @products.select { _1[:active] == false }
    def news? = yours.any? { _1[:badge].to_i.positive? }
    def color_style(p) = p[:color].to_s.downcase.match?(ComponentesUi::HEX) ? "--ss-suite-c:#{p[:color].to_s.downcase}" : nil
    def badge_text(n) = n == 1 ? t("suite_badge_one") : t("suite_badge", count: n)

    def used(p)
      return t("suite_current") if p[:current]
      return t("suite_never") unless p[:last_used_at]

      t("suite_used", ago: ss_trust_ago(p[:last_used_at], now: @now || Time.current))
    end

    def trigger
      safe_join([ss_icon("view-grid", size: nil), (tag.span(class: "ss-suite-dot", "aria-hidden": true) if news?)].compact)
    end
  end
end
