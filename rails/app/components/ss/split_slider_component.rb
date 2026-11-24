module Ss
  # Divide um valor entre pessoas (v1.9, par do SsSplitSlider): uma linha por pessoa (avatar, nome e valor em DM Mono)
  # com um slider de marcas pontilhadas. Com locked (soma travada, o padrão), mexer numa linha redistribui o resto
  # entre as outras na proporção que já tinham, para fechar total; sem ele, cada uma vai livre de 0 a total e o
  # rodapé mostra quanto falta ou sobra. Em centavos (o Ss::SplitAllocatorComponent é o de porcentagem).
  #
  #   render Ss::SplitSliderComponent.new(name: "divisao", total: 75_086,
  #     entries: [{ key: "eu", name: "Eu", cents: 25_000 }, { key: "ana", name: "Ana", cents: 25_043 }, { key: "bia", name: "Bia", cents: 25_043 }])
  #
  # Cada linha manda name[key] = centavos. step: passo em centavos (100 = R$ 1,00). marks: pontinhos na trilha.
  # Teclado e leitor de tela: o range nativo, com o valor em dinheiro (aria-valuetext).
  class SplitSliderComponent < BaseComponent
    attr_reader :name, :total, :entries

    def initialize(name:, total:, entries:, locked: true, step: 100, marks: 8, show_total: true, currency: nil, legend: nil, **rest)
      super(**rest)
      @name, @total = name, total.to_i
      @entries = Array(entries).map { |e| e.to_h.transform_keys(&:to_sym) }.each_with_index.map { |e, i| e.merge(key: (e[:key] || i).to_s, cents: e[:cents].to_i.clamp(0, @total)) }
      @locked, @step, @marks, @show_total = locked, [step.to_i, 1].max, marks.to_i.clamp(0, 40), show_total
      @currency, @legend = currency || ss_currency, legend
    end

    # O mesmo SsSplitSlider.redistribute: põe values[index] = value e divide o resto entre as outras na proporção
    # delas; os centavos do arredondamento vão um para cada, a partir da maior. A soma fecha total.
    def self.redistribute(values, index, value, total)
      v = value.to_i.clamp(0, total)
      out = values.dup
      out[index] = v
      others = (0...values.size).to_a - [index]
      return out.tap { |o| o[index] = total } if others.empty?

      rest = total - v
      sum = others.sum { |i| values[i] }
      used = 0
      others.each do |i|
        part = sum.zero? ? rest / others.size : (values[i] * rest.to_f / sum).floor
        out[i] = part
        used += part
      end
      order = others.sort_by { |i| -out[i] }
      k = 0
      while used < rest
        out[order[k % order.size]] += 1
        used += 1
        k += 1
      end
      out
    end

    def money(cents) = ss_money(cents / 100.0, currency: @currency)
    def legend = @legend || ss_t("split_slider.legend", default: "Divisão")
    def uid = @uid ||= "ss-split-#{object_id}"

    def foot_text
      diff = total - entries.sum { |e| e[:cents] }
      total_t = ss_t("split_slider.total", default: "Total %{amount}", amount: money(total))
      return total_t if @locked || diff.zero?

      key = diff.positive? ? "missing" : "over"
      "#{total_t} · #{ss_t("split_slider.#{key}", default: diff.positive? ? "Falta %{amount}" : "Sobra %{amount}", amount: money(diff.abs))}"
    end

    def call
      tag.fieldset(**root_attrs(class: classes("ss-split-slider"), data: { controller: "ss-split-slider", ss_split_slider_total_value: total,
        ss_split_slider_locked_value: @locked, ss_split_slider_step_value: @step, ss_split_slider_currency_value: @currency,
        ss_split_slider_total_text_value: ss_t("split_slider.total", default: "Total %{amount}"),
        ss_split_slider_missing_value: ss_t("split_slider.missing", default: "Falta %{amount}"),
        ss_split_slider_over_value: ss_t("split_slider.over", default: "Sobra %{amount}") })) do
        safe_join([
          tag.legend(legend, class: "ss-sr"),
          *entries.each_with_index.map { |e, i| row(e, i) },
          (tag.p(foot_text, class: "ss-split-slider-foot num", "aria-live": "polite", data: { ss_split_slider_target: "foot" }) if @show_total)
        ].compact)
      end
    end

    private

    def row(e, i)
      id = "#{uid}-#{i}"
      pct = total.zero? ? 0 : (e[:cents] * 100.0 / total).round(2)
      tag.div(class: "ss-split-slider-row", style: "--c:var(--series-#{i % 6 + 1})") do
        safe_join([
          tag.div(class: "ss-split-slider-head") do
            safe_join([ss_avatar(e[:name], size: 32), tag.label(e[:name], for: id), tag.output(money(e[:cents]), for: id, class: "num", data: { ss_split_slider_target: "out" })])
          end,
          tag.input(type: "range", id:, min: 0, max: total, step: @step, value: e[:cents], class: "ss-split-slider-range",
                    "aria-valuetext": money(e[:cents]), style: "--p:#{pct}%;--marks:#{@marks}",
                    data: { ss_split_slider_target: "range", index: i, action: "input->ss-split-slider#move" }),
          tag.input(type: "hidden", name: "#{name}[#{e[:key]}]", value: e[:cents], data: { ss_split_slider_target: "field" })
        ])
      end
    end
  end
end
