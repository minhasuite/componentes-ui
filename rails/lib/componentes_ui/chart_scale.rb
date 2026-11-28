module ComponentesUi
  # v1.14.7: a escala dos gráficos, uma conta só para todas as peças (par do SsChartScale do Flutter, com os mesmos
  # casos de teste nos dois lados). De lo a hi em passos "redondos" (1, 2, 2,5 ou 5 × 10ⁿ), com as guias em ticks.
  #
  # - zero: true (barras) põe o zero dentro; top: o topo mínimo (o max: das peças, pequenos múltiplos).
  # - Valores iguais (todos 3) ou minúsculos (0,001) também saem com passo redondo.
  # - format: (o texto do app, que pode arredondar: "1 min") faz o passo crescer até nenhum rótulo se repetir.
  #
  #   ComponentesUi::ChartScale.of(0, 5.4).ticks          # => [0.0, 2.0, 4.0, 6.0]
  #   ComponentesUi::ChartScale.all_zero?([0, 0, nil])     # => true (o gráfico mostra o vazio)
  module ChartScale
    MANTISSAS = [1.0, 2.0, 2.5, 5.0, 10.0].freeze

    Result = Struct.new(:lo, :hi, :step, :ticks) do
      # As guias menos o zero (que tem a linha própria nas barras).
      def guides = ticks.reject(&:zero?)
    end

    module_function

    # Tira o ruído do ponto flutuante (0.30000000000000004 → 0.3).
    def clean(v)
      v = v.to_f
      return 0.0 if v.zero?
      return v unless v.finite?

      Float(format("%.12g", v))
    end

    # O menor passo redondo maior ou igual a raw.
    def nice_step(raw)
      raw = raw.to_f
      return 1.0 if !raw.finite? || raw <= 0

      mag = 10.0**Math.log10(raw).floor
      MANTISSAS.each do |m|
        s = clean(m * mag)
        return s if s >= raw * (1 - 1e-9)
      end
      clean(10 * mag)
    end

    # O passo redondo logo acima (1 → 2 → 2,5 → 5 → 10).
    def next_step(step) = nice_step(step * (1 + 1e-6))

    # Casas decimais para escrever as guias de um passo sem repetir (2,5 → 1; 0,25 → 2; 0,001 → 3; 50 → 0).
    def decimals(step)
      step = step.to_f
      return 0 if !step.finite? || step <= 0

      (0...12).each do |d|
        m = step * 10**d
        return d if (m - m.round).abs < 1e-6 * [1, m.abs].max
      end
      12
    end

    # Tudo zero ou nil (ou nada): o gráfico mostra o vazio.
    def all_zero?(values) = Array(values).all? { |v| v.nil? || v.to_f.zero? }

    def of(min, max, intervals: 3, zero: true, top: nil, format: nil)
      lo = min.to_f.finite? ? min.to_f : 0.0
      hi = max.to_f.finite? ? max.to_f : 0.0
      lo, hi = hi, lo if lo > hi
      if zero
        lo = [lo, 0.0].min
        hi = [hi, 0.0].max
      end
      hi = [hi, top.to_f].max if top && top.to_f.finite?
      if hi == lo
        if hi.zero?
          hi = 1.0
        else
          d = hi.abs * 0.1
          lo -= d
          hi += d
        end
      end
      n = [intervals.to_i, 1].max
      step = nice_step((hi - lo) / n)
      last = nil
      40.times do
        a = clean(((lo / step) + 1e-9).floor * step)
        b = clean(((hi / step) - 1e-9).ceil * step)
        bands = [((b - a) / step).round, 1].max
        ticks = (0..bands).map { |i| clean(a + step * i) }
        last = Result.new(a, b == a ? a + step : b, step, ticks)
        if bands > n
          step = next_step(step)
          next
        end
        if format
          texts = ticks.map { |v| format.call(v) }
          if texts.uniq.size < texts.size
            step = next_step(step)
            next
          end
        end
        return last
      end
      last
    end
  end
end
