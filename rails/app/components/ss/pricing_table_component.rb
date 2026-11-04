module Ss
  # Planos lado a lado com mensal/anual (sem JS: rádio + :has), plano destacado
  # com .ss-card-grad, recursos e CTA. Para /assinar/<produto>.
  #   render Ss::PricingTableComponent.new(plans: [
  #     { name: "Pro", description: "…", monthly: "R$ 19,90", yearly: "R$ 199,00", yearly_note: "2 meses grátis",
  #       features: ["IA ilimitada", "5 usuários"], cta: { label: "Assinar", url: "/assinar/financeiro?plano=pro", yearly_url: "…&periodo=anual" }, featured: true }])
  class PricingTableComponent < BaseComponent
    include InView
    CHECK = %(<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 12.5l4.5 4.5L19 7.5" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/></svg>).freeze

    attr_reader :plans

    def initialize(plans:, period: :monthly, yearly_badge: nil, **opts)
      super(**opts)
      @plans = plans
      @period = period.to_s
      @yearly_badge = yearly_badge
    end

    def uid = @uid ||= "ss-price-#{object_id}"
    def yearly? = @period == "yearly"
    def any_yearly? = @plans.any? { _1[:yearly] }
    attr_reader :yearly_badge
    def check = CHECK.html_safe
  end
end
