module Ss
  # Comparação de planos/fornecedores: coluna recomendada destacada, ✓/— por linha
  # (ou o texto do valor) e cabeçalho fixo.
  #   render Ss::CompareTableComponent.new(caption: "Planos",
  #     plans: [{ name: "Grátis", price: "R$ 0" }, { name: "Pro", price: "R$ 19,90/mês", recommended: true }],
  #     features: [{ label: "Lançamentos", values: ["50/mês", "Ilimitado"] }, { label: "IA", values: [false, true] }])
  class CompareTableComponent < BaseComponent
    YES = %(<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 12.5l4.5 4.5L19 7.5" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/></svg>).freeze

    def initialize(plans:, features:, caption:, max_height: nil, **opts)
      super(**opts)
      @plans = plans
      @features = features
      @caption = caption
      @max_height = max_height
    end

    def call
      tag.div(**root_attrs(class: classes("ss-card", "ss-compare-t"), style: (@max_height ? "max-height:#{@max_height}" : nil))) do
        tag.table(class: "ss-table") do
          safe_join([
            tag.caption(@caption, class: "ss-sr"),
            tag.thead(tag.tr(safe_join([tag.td(""), *@plans.map { head(_1) }]))),
            tag.tbody(safe_join(@features.map { feature(_1) }))
          ])
        end
      end
    end

    private

    def rec?(i) = @plans[i][:recommended]

    def head(p)
      tag.th(scope: "col", class: ("is-rec" if p[:recommended])) do
        safe_join([(tag.span(ss_t("compare_table.recommended", default: "Recomendado"), class: "ss-compare-t-tag") if p[:recommended]), tag.b(p[:name]), (tag.small(p[:price], class: "num") if p[:price])].compact)
      end
    end

    def feature(f)
      tag.tr do
        safe_join([tag.th(f[:label], scope: "row"), *f[:values].each_with_index.map { |v, i| tag.td(value(v), class: ("is-rec" if rec?(i))) }])
      end
    end

    def value(v)
      case v
      when true then tag.span(safe_join([YES.html_safe, tag.span(ss_t("compare_table.included", default: "Incluído"), class: "ss-sr")]), class: "ss-compare-yes")
      when false, nil then tag.span(safe_join([tag.span("—", "aria-hidden": true), tag.span(ss_t("compare_table.not_included", default: "Não incluído"), class: "ss-sr")]), class: "ss-compare-no")
      else tag.span(v, class: "num")
      end
    end
  end
end
