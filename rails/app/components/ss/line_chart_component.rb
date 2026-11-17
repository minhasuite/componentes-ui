module Ss
  # Gráfico de linhas por categoria (v0.27, par do SsLineChart): SVG do servidor, sem biblioteca. Uma ou
  # várias séries sobre os mesmos rótulos (dias, semanas), em linha **reta** de ponto a ponto (curva suave
  # inventa valor entre dois dias). Mesma pele e tokens do BarChartComponent: guias com o valor, rótulos do
  # eixo X de N em N quando não cabem, legenda só com 2+ séries, dica nativa (<title>) por rótulo e tabela
  # para leitor de tela.
  #
  #   render Ss::LineChartComponent.new(title: "Ocorrências por dia",
  #     labels: %w[10/11 11/11 12/11 13/11 14/11],
  #     series: [{ name: "Agora", values: [12, 19, 8, 24, 17] },
  #              { name: "Semana anterior", values: [10, 11, 9, 14, 12], tone: :muted, dashed: true }],
  #     markers: [{ at: "12/11", label: "v2.3.1", kind: :deploy }], empty: "Sem dados no período")
  #
  # Série: { name:, values:, color: "var(--…)" ou tone: :accent/:success/:danger/:warn/:muted, dashed: true }.
  # dashed: traço fino e tracejado (a referência, ex. o período anterior). nil num valor = buraco na linha.
  # Sem cor, --series-1..6 (a 1ª é a marca).
  # - stacked: true empilha as séries em áreas (a de cima soma as de baixo); a dica e a tabela mostram o
  #   valor de cada série, não a soma.
  # - width:/label_every:/height:/format:/legend:/show_title:/active: como no BarChartComponent.
  # - markers: marcas verticais (deploy, incidente, nota); ver Ss::ChartMarkers.
  # - empty: texto quando não há rótulo nem valor (sem empty:, não desenha nada).
  # - v0.28: max: fixa o topo da escala (pequenos múltiplos na mesma escala), como no BarChartComponent.
  class LineChartComponent < BaseComponent
    include ChartMarkers

    W = 560
    PT = 26.0
    PB = 28.0
    PX = 14.0
    TONES = BarChartComponent::TONES

    attr_reader :title, :labels, :series

    def initialize(labels:, series:, title:, stacked: false, format: nil, height: 240, active: nil, show_title: false,
                   legend: true, width: W, label_every: nil, markers: [], empty: nil, dots: nil, max: nil, **rest)
      super(**rest)
      @max = max&.to_f
      @labels = labels.map(&:to_s)
      @series = series.each_with_index.map { |s, i| normalize(s, "var(--series-#{i % 6 + 1})") }
      @stacked = stacked
      @format = format
      @h = height.to_i.clamp(120, 600)
      @w = width.to_i.clamp(280, 1600)
      @label_every = label_every&.to_i&.clamp(1, 100)
      @active = active
      @show_title = show_title
      @legend = legend
      @empty = empty
      @dots = dots
      init_markers(markers)
      @h += marker_pad.round if markers?
    end

    def render? = data? || @empty.present?
    def data? = labels.any? && series.any? { |s| s[:values].any? { !_1.nil? } }
    def empty_text = @empty

    def h = @h
    def w = @w
    def pt = PT + marker_pad
    def stacked? = @stacked
    def show_title? = @show_title
    def legend? = @legend && series.size > 1
    def active?(i) = @active == i

    # Pontos visíveis: com poucos rótulos (até 14) ou dots: true.
    def dots? = @dots.nil? ? labels.size <= 14 : @dots

    # v1.2: a mesma conta do BarChartComponent (largura do maior rótulo; parte do grupo ativo).
    def label_every
      return @label_every if @label_every
      return 1 if labels.empty?

      room = BarChartComponent::X_CHAR * labels.map(&:size).max + BarChartComponent::X_GAP
      [(room / slot).ceil, 1].max
    end
    def show_label?(i) = active?(i) || ((i - (@active || 0).to_i) % label_every).zero?

    def fmt(v)
      return @format.call(v) if @format

      ss_number(v, precision: v.to_f % 1 == 0 ? 0 : 2)
    end

    def x(i)
      return (w / 2.0).round(2) if labels.size == 1

      (PX + (w - 2 * PX) * i / (labels.size - 1).to_f).round(2)
    end

    # Largura de cada faixa de rótulo (a área de passar o mouse).
    def slot = labels.size == 1 ? (w - 2 * PX) : (w - 2 * PX) / (labels.size - 1).to_f
    def cx(i) = x(i)

    def range
      @range ||= begin
        vals = [0.0]
        labels.each_index do |i|
          col = series.map { _1[:values][i] }.compact
          stacked? ? (vals << col.select(&:positive?).sum << col.select(&:negative?).sum) : vals.concat(col)
        end
        lo, hi = vals.minmax
        hi = 1.0 if lo.zero? && hi.zero?
        pad = (hi - lo) * 0.08
        # v0.28: max: fixa o topo da escala (pequenos múltiplos na mesma escala). Valor acima do max
        # alarga a escala em vez de vazar do desenho.
        top = @max ? [@max, hi].max : (hi.positive? ? hi + pad : 0.0)
        [lo.negative? ? lo - pad : 0.0, top]
      end
    end

    def y(v)
      lo, hi = range
      (pt + (h - pt - PB) * (hi - v) / (hi - lo)).round(2)
    end

    def guides
      lo, hi = range
      marks = [hi, (hi + lo) / 2, lo].uniq.reject { |v| (v / (hi - lo)).abs < 0.12 }
      (marks.map { |v| [y(v), nice(v), false] } << [y(0), 0, true]).uniq { _1[0] }
    end

    def nice(v)
      return v.round if v.abs < 100

      v.round(-(Math.log10(v.abs).floor - 1))
    end

    # Topo acumulado de cada série (empilhado): [[v ou nil por rótulo], …] na ordem das séries.
    def tops
      @tops ||= begin
        acc = Array.new(labels.size, 0.0)
        series.map do |s|
          labels.each_index.map do |i|
            v = s[:values][i]
            v.nil? ? acc[i] : (acc[i] += v)
          end
        end
      end
    end

    # Caminho da série k: linha (com buracos nos nil) ou, no empilhado, o topo dela.
    def line_d(k)
      vals = stacked? ? tops[k] : series[k][:values]
      d = +""
      pen = false
      vals.each_with_index do |v, i|
        if v.nil?
          pen = false
          next
        end
        d << "#{pen ? "L" : "M"}#{x(i)},#{y(v)} "
        pen = true
      end
      d.strip
    end

    # Área entre o topo da série k e o da de baixo (ou o zero), no empilhado.
    def area_d(k)
      top = tops[k]
      base = k.zero? ? Array.new(labels.size, 0.0) : tops[k - 1]
      fwd = labels.each_index.map { |i| "#{x(i)},#{y(top[i])}" }
      back = labels.each_index.to_a.reverse.map { |i| "#{x(i)},#{y(base[i])}" }
      "M#{fwd.join(" L")} L#{back.join(" L")} Z"
    end

    def points(k)
      vals = stacked? ? tops[k] : series[k][:values]
      labels.each_index.filter_map { |i| (v = series[k][:values][i]) && [x(i), y(vals[i]), v] }
    end

    def tip(i)
      [labels[i], *series.map { |s| "#{s[:name]}: #{s[:values][i].nil? ? "—" : fmt(s[:values][i])}" },
       *markers.select { _1[:index] == i }.map { "#{_1[:label]} (#{marker_kind_label(_1[:kind])})" }].join("\n")
    end

    def marker_x(m) = x(m[:index])

    def uid = @uid ||= "ss-linec-#{object_id}"

    private

    def normalize(s, fallback)
      s = s.to_h.transform_keys(&:to_sym)
      color = s[:color] || TONES[s[:tone]&.to_sym] || fallback
      { name: s[:name].to_s, values: Array(s[:values]).map { _1&.to_f }, color:, dashed: s[:dashed] == true }
    end
  end
end
