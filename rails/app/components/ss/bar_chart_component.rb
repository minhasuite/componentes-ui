module Ss
  # Gráfico de barras (v0.15, par do SsBarChart): SVG do servidor, sem biblioteca. Barras
  # agrupadas (uma por série, lado a lado) ou empilhadas (stacked: true), com valores negativos
  # (a linha do zero separa: positivo sobe, negativo desce) e uma linha opcional por cima
  # (line:, ex. saldo do mês sobre receitas × despesas). Guias com o valor, rótulo embaixo,
  # legenda, dica nativa (<title>) por grupo e tabela para leitor de tela.
  #
  #   render Ss::BarChartComponent.new(title: "Receitas × despesas",
  #     labels: %w[jun jul ago set out nov],
  #     series: [{ name: "Receitas", values: [5200, 4800, 5100, 5300, 4900, 5600], tone: :success },
  #              { name: "Despesas", values: [-4100, -5200, -3900, -4700, -5000, -4300], tone: :danger }],
  #     line: { name: "Saldo", values: [1100, -400, 1200, 600, -100, 1300] },
  #     stacked: true, format: ->(v) { ss_money(v) })
  #
  # Série: { name:, values:, color: "var(--…)" ou tone: :accent/:success/:danger/:warn/:muted }.
  # Sem cor, --series-1..6 (a 1ª é a marca). active: índice do grupo em destaque (rótulo forte).
  #
  # v0.19: width: a largura do desenho (viewBox; padrão 560). O SVG ocupa a largura do card e escala
  # junto: num card largo (painel no computador), passe a largura de verdade (ex. 1100) para o texto
  # não crescer; no celular, renderize outro com a largura padrão (ex. com hidden/md:block). Com muitos
  # grupos (30 dias), os rótulos do eixo X saem de N em N para não encostar (label_every: força o N).
  class BarChartComponent < BaseComponent
    W = 560
    PT = 26.0
    PB = 28.0
    PX = 14.0
    TONES = { accent: "var(--accent)", success: "var(--success)", danger: "var(--danger)", warn: "var(--warn)", muted: "var(--muted)" }.freeze

    attr_reader :title, :labels, :series, :line

    def initialize(labels:, series:, title:, line: nil, stacked: false, format: nil, height: 240, active: nil,
                   show_title: false, legend: true, width: W, label_every: nil, **rest)
      super(**rest)
      @labels = labels.map(&:to_s)
      @series = series.each_with_index.map { |s, i| normalize(s, "var(--series-#{i % 6 + 1})") }
      @line = line && normalize(line, "var(--ink)")
      @stacked = stacked
      @format = format
      @h = height.to_i.clamp(120, 600)
      @w = width.to_i.clamp(280, 1600)
      @label_every = label_every&.to_i&.clamp(1, 100)
      @active = active
      @show_title = show_title
      @legend = legend
    end

    def render? = labels.any? && series.any?

    def h = @h
    def w = @w

    # De quantos em quantos rótulos do eixo X mostrar (v0.19): sem label_every:, o que cabe sem
    # encostar (~26 unidades por rótulo); o grupo ativo sempre mostra o dele.
    def label_every = @label_every || [((labels.size * 26.0) / (w - 2 * PX)).ceil, 1].max
    def show_label?(i) = active?(i) || (i % label_every).zero?
    def stacked? = @stacked
    def show_title? = @show_title
    def legend? = @legend && (series.size + (line ? 1 : 0)) > 1
    def active?(i) = @active == i

    def fmt(v)
      return @format.call(v) if @format

      ss_number(v, precision: v.to_f % 1 == 0 ? 0 : 2)
    end

    # Extremos com o zero sempre dentro (empilhado: soma dos positivos e dos negativos).
    def range
      @range ||= begin
        vals = [0.0]
        labels.each_index do |i|
          col = series.map { _1[:values][i] }.compact
          if stacked?
            vals << col.select(&:positive?).sum << col.select(&:negative?).sum
          else
            vals.concat(col)
          end
          vals << line[:values][i] if line && line[:values][i]
        end
        lo, hi = vals.minmax
        hi = 1.0 if lo.zero? && hi.zero?
        pad = (hi - lo) * 0.08
        [lo.negative? ? lo - pad : 0.0, hi.positive? ? hi + pad : 0.0]
      end
    end

    def y(v)
      lo, hi = range
      (PT + (h - PT - PB) * (hi - v) / (hi - lo)).round(2)
    end

    def zero_y = y(0)
    def slot = (w - 2 * PX) / labels.size.to_f
    def cx(i) = (PX + slot * (i + 0.5)).round(2)

    # Retângulos de um grupo: [x, y, w, h, série, valor].
    def bars(i)
      gw = slot * 0.72
      left = PX + slot * i + (slot - gw) / 2
      if stacked?
        up = down = 0.0
        series.filter_map do |s|
          v = s[:values][i]
          next if v.nil? || v.zero?

          base = v.positive? ? up : down
          top = base + v
          v.positive? ? (up = top) : (down = top)
          rect(left, gw, base, top, s, v)
        end
      else
        bw = (gw - 2 * (series.size - 1)) / series.size
        series.each_with_index.filter_map do |s, k|
          v = s[:values][i]
          next if v.nil? || v.zero?

          rect(left + k * (bw + 2), bw, 0, v, s, v)
        end
      end
    end

    # Topo, base e o meio (menos o que cai em cima da linha do zero) + a linha do zero.
    def guides
      lo, hi = range
      marks = [hi, (hi + lo) / 2, lo].uniq.reject { |v| (v / (hi - lo)).abs < 0.12 }
      (marks.map { |v| [y(v), nice(v), false] } << [zero_y, 0, true]).uniq { _1[0] }
    end

    def line_points = line ? labels.each_index.filter_map { |i| (v = line[:values][i]) && [cx(i), y(v)] } : []
    def line_d = line_points.map.with_index { |(px, py), k| "#{k.zero? ? "M" : "L"}#{px},#{py}" }.join(" ")

    # Dica do grupo: rótulo + cada série (e a linha).
    def tip(i)
      rows = series.map { |s| "#{s[:name]}: #{s[:values][i].nil? ? "—" : fmt(s[:values][i])}" }
      rows << "#{line[:name]}: #{fmt(line[:values][i])}" if line && line[:values][i]
      [labels[i], *rows].join("\n")
    end

    def nice(v)
      return v.round if v.abs < 100

      v.round(-(Math.log10(v.abs).floor - 1))
    end

    def uid = @uid ||= "ss-barc-#{object_id}"

    private

    def normalize(s, fallback)
      s = s.to_h.transform_keys(&:to_sym)
      color = s[:color] || TONES[s[:tone]&.to_sym] || fallback
      { name: s[:name].to_s, values: Array(s[:values]).map { _1&.to_f }, color: }
    end

    def rect(x, w, from, to, s, v)
      top, bottom = [y(from), y(to)].minmax
      [x.round(2), top, w.round(2), [bottom - top, 1].max.round(2), s, v]
    end
  end
end
