module Ss
  # Faixa de 3 a 5 números: rótulo, valor (dinheiro com ss_amount), variação colorida
  # pelo sentido (good: true/false, não pelo sinal) e minigráfico na base.
  # Ao aparecer na tela, o número conta (Ss::CountUpComponent, quando o texto é um
  # número pt-BR: "R$ 48.320,00", "214", "92,4%") e o minigráfico se desenha em cascata.
  # count: false no item (ou no componente) deixa o número parado.
  #
  #   render Ss::KpiStripComponent.new(items: [
  #     { label: "Vendido", value: "R$ 48.320,00", money: true, delta: "+12%", good: true, hint: "vs. out", spark: [3, 5, 4, 8] },
  #     { label: "Pedidos", value: "214", delta: "−3%", good: false }])
  class KpiStripComponent < BaseComponent
    include InView
    UP = %(<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 19V5m-6 6 6-6 6 6" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/></svg>).freeze
    DOWN = %(<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 5v14m-6-6 6 6 6-6" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/></svg>).freeze

    def initialize(items:, label: nil, count: true, **opts)
      super(**opts)
      @items = items
      @label = label || ss_t("kpi_strip.label", default: "Indicadores")
      @count = count
    end

    def call
      tag.div(**root_attrs(class: classes("ss-kpis"), role: "list", "aria-label": @label, data: in_view_data)) do
        safe_join(@items.each_with_index.map { |it, i| item(it, i) })
      end
    end

    private

    def item(it, i)
      tag.div(class: "ss-kpi", role: "listitem", style: "--i:#{i}") do
        safe_join([
          tag.span(it[:label], class: "ss-kpi-label"),
          tag.div(value(it), class: "ss-kpi-value"),
          (foot(it) if it[:delta] || it[:hint]),
          (ss_sparkline(it[:spark], height: 36) if it[:spark].to_a.size > 1)
        ].compact)
      end
    end

    # "R$ 48.320,00" / "214" / "92,4%" → CountUp; o resto (ex. "1,2 mil") fica como texto.
    # NUMBER é o formato pt-BR; number_re monta o mesmo com os separadores do idioma da página.
    NUMBER = /\A(?<pre>[^\d-]*?)(?<n>-?\d{1,3}(?:\.\d{3})*(?:,(?<dec>\d+))?|-?\d+(?:,(?<dec2>\d+))?)(?<suf>\D*)\z/

    def number_re
      @number_re ||= begin
        d = Regexp.escape(ss_t("number.delimiter", locale: ss_number_locale, default: "."))
        s = Regexp.escape(ss_t("number.separator", locale: ss_number_locale, default: ","))
        /\A(?<pre>[^\d-]*?)(?<n>-?\d{1,3}(?:#{d}\d{3})*(?:#{s}(?<dec>\d+))?|-?\d+(?:#{s}(?<dec2>\d+))?)(?<suf>\D*)\z/
      end
    end

    def value(it)
      static = it[:money] ? ss_amount(it[:value]) : tag.span(it[:value], class: "num")
      return static if !@count || it[:count] == false || !(m = it[:value].to_s.strip.match(number_re))

      d = ss_t("number.delimiter", locale: ss_number_locale, default: ".")
      s = ss_t("number.separator", locale: ss_number_locale, default: ",")
      n = m[:n].delete(d).tr(s, ".").to_f
      decimals = (m[:dec] || m[:dec2]).to_s.size
      # v0.15.2: o ss_money separa o símbolo com espaço não separável (o strip não tira).
      pre = m[:pre].to_s.tr("\u00A0", " ")
      suf = m[:suf].to_s.tr("\u00A0", " ")
      sym = ss_currency_symbol
      if it[:money] && ((pre.strip == sym && suf.empty?) || (pre.empty? && suf.strip == sym))
        render(Ss::CountUpComponent.new(value: n, format: :money, decimals:))
      elsif suf == "%" && pre.empty?
        render(Ss::CountUpComponent.new(value: n, format: :percent, decimals:))
      elsif pre.empty? && suf.empty?
        render(Ss::CountUpComponent.new(value: n, format: :decimal, decimals:))
      else
        static
      end
    end

    def foot(it)
      up = it.key?(:trend) ? it[:trend].to_s == "up" : !it[:delta].to_s.strip.start_with?("-", "−")
      tone = it[:good].nil? ? nil : (it[:good] ? "is-good" : "is-bad")
      sense = it[:good].nil? ? "" : (it[:good] ? ss_t("kpi_strip.good", default: " (bom)") : ss_t("kpi_strip.bad", default: " (ruim)"))
      tag.div(class: "ss-kpi-foot") do
        safe_join([
          (tag.span(class: ["ss-delta", tone].compact.join(" "), "aria-label": ss_t("kpi_strip.delta", default: "Variação %{delta}%{sense}", delta: it[:delta], sense:)) { safe_join([(up ? UP : DOWN).html_safe, it[:delta]]) } if it[:delta]),
          (tag.small(it[:hint]) if it[:hint])
        ].compact)
      end
    end
  end
end
