module Ss
  # Gráfico de área (SVG do servidor): curva suave com gradiente vertical da marca,
  # eixo X com rótulos, guias horizontais e o ponto ativo (linha, marcador e pílula).
  # O controller ss-chart move o ponto com o mouse/dedo e com ← →. Tabela alternativa
  # para leitor de tela.
  #
  #   render Ss::AreaChartComponent.new(title: "Gastos por mês",
  #     points: [["jan", 1200.0], ["fev", 980.5], …], active: 4,
  #     format: ->(v) { number_to_currency(v) })
  #
  # v1.14.7: tudo zero é vazio (o .ss-chart-empty com empty:, ou "Sem dados no período"); treat_zero_as_empty: false
  # desenha a área no chão. As guias são as marcas redondas do ComponentesUi::ChartScale, sem rótulo repetido.
  class AreaChartComponent < BaseComponent
    W = 560
    H = 230
    PT = 34.0
    PB = 30.0
    PX = 14.0

    attr_reader :title, :points

    def initialize(points:, title:, active: nil, format: nil, show_title: false, scrub: false, empty: nil,
                   treat_zero_as_empty: true, **opts)
      super(**opts)
      @empty = empty
      @treat_zero_as_empty = treat_zero_as_empty
      @scrub = scrub
      @points = points.map { |(l, v)| [l.to_s, v.to_f] }
      @title = title
      @active = (active || @points.size - 1).clamp(0, [@points.size - 1, 0].max)
      @format = format
      @show_title = show_title
    end

    def render? = @points.size >= 2

    # v1.14.7: só zeros (com treat_zero_as_empty:): o vazio no lugar do desenho.
    def zero? = @treat_zero_as_empty && ComponentesUi::ChartScale.all_zero?(@points.map(&:last))
    def empty_text = @empty || ss_t("chart.empty", default: "Sem dados no período")

    def uid = @uid ||= "ss-area-#{object_id}"
    def active = @active
    def show_title? = @show_title
    # v1.14.0 (par do SsAreaChart(scrub:)): o balão com o rótulo, a vibração por ponto e o ss-scrub:change.
    def scrub? = @scrub

    def fmt(v)
      return @format.call(v) if @format

      ss_number(v, precision: v % 1 == 0 ? 0 : 2)
    end

    # v1.14.7: a escala redonda; com valores positivos ela não desce do zero.
    def scale
      @scale ||= begin
        lo, hi = @points.map(&:last).minmax
        ComponentesUi::ChartScale.of(lo, hi, zero: false, format: ->(v) { fmt(v) })
      end
    end

    def range = [scale.lo, scale.hi]

    # [x, y] em coordenadas do viewBox.
    def coords
      @coords ||= begin
        lo, hi = range
        span = (hi - lo).zero? ? 1 : hi - lo
        n = @points.size - 1
        @points.each_with_index.map do |(_, v), i|
          [(PX + (W - 2 * PX) * i / n).round(2), (PT + (H - PT - PB) * (1 - (v - lo) / span)).round(2)]
        end
      end
    end

    # Curva suave (Catmull-Rom → Bézier, a mesma conta do ss_sparkline).
    def line_d
      pts = coords
      d = +"M#{pts[0].join(",")}"
      pts.each_cons(2).with_index do |(p1, p2), i|
        p0 = pts[[i - 1, 0].max]
        p3 = pts[[i + 2, pts.size - 1].min]
        c1 = [p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6].map { _1.round(2) }
        c2 = [p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6].map { _1.round(2) }
        d << " C#{c1.join(",")} #{c2.join(",")} #{p2.join(",")}"
      end
      d
    end

    def area_d = "#{line_d} L#{coords[-1][0]},#{H - PB} L#{coords[0][0]},#{H - PB} Z"

    # As guias horizontais com o valor (as marcas da escala).
    def guides
      lo, hi = range
      scale.ticks.map { |v| [(PT + (H - PT - PB) * (1 - (v - lo) / (hi - lo))).round(2), v] }
    end

    # Valor da guia arredondado a 2 algarismos (6.704,64 → 6.700).
    def nice(v)
      return v.round if v.abs < 100

      v.round(-(Math.log10(v.abs).floor - 1))
    end

    def data_points = coords.each_with_index.map { |(x, y), i| [x, y, @points[i][0], fmt(@points[i][1])] }.to_json
    def pct_x(i) = (coords[i][0] / W * 100).round(3)
    # v1.14.0: perto da borda, o balão encosta para dentro (não corta no fim do gráfico).
    def pill_edge(i) = pct_x(i) > 86 ? " is-end" : (pct_x(i) < 14 ? " is-start" : "")
    def pct_y(i) = (coords[i][1] / H * 100).round(3)
  end
end
