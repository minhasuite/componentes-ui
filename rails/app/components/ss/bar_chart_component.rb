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
  # v1.14.0: scrub: true (par do SsBarChart(scrub:)): marcador e balão seguem o dedo/mouse por grupo, vibra a cada
  # grupo e avisa `ss-scrub:change` { index } (só nas barras em pé).
  # Sem cor, --series-1..6 (a 1ª é a marca). active: índice do grupo em destaque (rótulo forte).
  #
  # v0.19: width: a largura do desenho (viewBox; padrão 560). O SVG ocupa a largura do card e escala
  # junto: num card largo (painel no computador), passe a largura de verdade (ex. 1100) para o texto
  # não crescer; no celular, renderize outro com a largura padrão (ex. com hidden/md:block). Com muitos
  # grupos (30 dias), os rótulos do eixo X saem de N em N para não encostar (label_every: força o N).
  #
  # v0.20: projection: uma segunda linha, tracejada, para o que ainda vai acontecer (ex. saldo projetado
  # de hoje até o fim do mês). Mesmo formato da série ({ name:, values:, tone:/color: }; sem cor, a da
  # linha); nil num valor = sem ponto. projection_from: N ignora os valores antes do índice N (assim a
  # mesma lista pode vir inteira). Entra na legenda (traço tracejado), na dica do grupo e na tabela
  # para leitor de tela. Para a linha real parar onde a projeção começa, passe nil nos dias seguintes.
  #
  #   render Ss::BarChartComponent.new(..., line: { name: "Saldo", values: real_ate_hoje },
  #     projection: { name: "Projeção", values: projetado }, projection_from: Date.current.day - 1)
  #
  # v0.27 (meulog):
  # - horizontal: true deita as barras (uma linha por rótulo, rótulo à esquerda): para categoria de nome
  #   longo (classe de exceção, rota). O rótulo que não cabe termina em "…" e o nome inteiro fica na dica
  #   (<title>). A altura sai do número de linhas (height: é ignorado); line:, projection: e markers: não
  #   valem no deitado.
  # - Cor por valor numa série: tones: [nil, …, :muted] (ou colors: ["var(--…)", …]); nil = a cor da série.
  #   Ex.: a última categoria "Outros" apagada, para não parecer o maior item.
  # - empty: "Sem dados no período" desenha o vazio (texto no lugar do gráfico) quando não há rótulo ou
  #   nenhum valor; sem empty:, nada aparece (como antes).
  # - markers: marcas verticais (deploy, incidente, nota) por rótulo; ver Ss::ChartMarkers.
  #
  #   render Ss::BarChartComponent.new(title: "Erros por classe", horizontal: true,
  #     labels: ["ActiveRecord::RecordNotFound", "Net::ReadTimeout", "Outros"],
  #     series: [{ name: "Ocorrências", values: [120, 48, 30], tones: [nil, nil, :muted] }], empty: "Sem dados")
  #
  # v0.28: max: fixa o topo da escala (o eixo vai de 0 até max), para pequenos múltiplos lado a lado na
  # mesma escala: comparar a altura de duas barras de gráficos diferentes só é honesto com o mesmo topo.
  # Um valor acima do max alarga a escala (nunca vaza do desenho). Par do SsBarChart(max:).
  #   render Ss::BarChartComponent.new(title: "EAccessViolation", labels: dias, series: [...], max: maior_de_todos)
  class BarChartComponent < BaseComponent
    include ChartMarkers

    W = 560
    PT = 26.0
    PB = 28.0
    PX = 14.0
    ROW = 30.0
    TONES = { accent: "var(--accent)", success: "var(--success)", danger: "var(--danger)", warn: "var(--warn)", muted: "var(--muted)" }.freeze

    attr_reader :title, :labels, :series, :line, :projection

    def initialize(labels:, series:, title:, line: nil, stacked: false, format: nil, height: 240, active: nil,
                   show_title: false, legend: true, width: W, label_every: nil, projection: nil, projection_from: nil,
                   horizontal: false, empty: nil, markers: [], max: nil, scrub: false, **rest)
      super(**rest)
      @title = title # v1.14.0: o título (figcaption, a tabela do leitor de tela e o rótulo do scrub) saía vazio.
      @max = max&.to_f
      @scrub = scrub
      @labels = labels.map(&:to_s)
      @series = series.each_with_index.map { |s, i| normalize(s, "var(--series-#{i % 6 + 1})") }
      @line = line && normalize(line, "var(--ink)")
      @projection = projection && normalize(projection, @line ? @line[:color] : "var(--muted)")
      if @projection && projection_from
        from = projection_from.to_i
        @projection[:values] = @projection[:values].each_with_index.map { |v, i| i < from ? nil : v }
      end
      @stacked = stacked
      @format = format
      @h = height.to_i.clamp(120, 600)
      @w = width.to_i.clamp(280, 1600)
      @label_every = label_every&.to_i&.clamp(1, 100)
      @active = active
      @show_title = show_title
      @legend = legend
      @horizontal = horizontal
      @empty = empty
      if horizontal
        @line = @projection = nil
        @h = (PT + PB + ROW * labels.size).round
      end
      init_markers(horizontal ? [] : markers)
      @h += marker_pad.round if markers?
    end

    def render? = data? || @empty.present?

    # Há o que desenhar: rótulo e ao menos um valor.
    def data? = labels.any? && series.any? { |s| s[:values].any? { !_1.nil? } }
    def empty_text = @empty
    def horizontal? = @horizontal

    # Topo da área de desenho (as marcas empurram para baixo).
    def pt = PT + marker_pad

    def h = @h
    def w = @w

    # De quantos em quantos rótulos do eixo X mostrar (v0.19): sem label_every:, o que cabe sem
    # encostar; o grupo ativo sempre mostra o dele.
    # v1.2: a conta usa a largura do maior rótulo (versalete em negrito, ~8,7 unidades por letra + 8 de
    # respiro) e não mais 26 unidades fixas: em 360 px os doze meses ("MAR", "ABR") colavam ("MARABR").
    # E a contagem parte do grupo ativo (active:, ex. o mês atual): o vizinho dele nunca encosta.
    X_CHAR = 8.7
    X_GAP = 8.0
    def label_room = labels.map(&:size).max.to_i * X_CHAR + X_GAP
    def label_every = @label_every || (labels.empty? ? 1 : [(label_room / slot).ceil, 1].max)
    def show_label?(i) = active?(i) || ((i - (@active || 0).to_i) % label_every).zero?
    def stacked? = @stacked
    def show_title? = @show_title
    def legend? = @legend && (series.size + (line ? 1 : 0) + (projection ? 1 : 0)) > 1
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
          vals << projection[:values][i] if projection && projection[:values][i]
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

    # ── Deitado (v0.27) ──────────────────────────────────────────────
    # Coluna dos rótulos à esquerda (~34% da largura), barras no resto, valor no fim da barra.
    def label_w = (w * 0.34).round(2)
    def label_chars = [(label_w / 7.2).floor, 4].max
    def short_label(l) = l.size > label_chars ? "#{l[0, label_chars - 1].rstrip}…" : l
    def value_w = 56.0
    def hx(v)
      lo, hi = range
      left = PX + label_w
      (left + (w - left - PX - value_w) * (v - lo) / (hi - lo)).round(2)
    end
    def zero_x = hx(0)
    def row_y(i) = (PT + ROW * i).round(2)

    # Barras de uma linha deitada: [x, y, w, h, série, valor, cor].
    def hbars(i)
      gh = ROW * 0.62
      top = PT + ROW * i + (ROW - gh) / 2
      list = if stacked?
               up = down = 0.0
               series.filter_map do |s|
                 v = s[:values][i]
                 next if v.nil? || v.zero?

                 base = v.positive? ? up : down
                 v.positive? ? (up = base + v) : (down = base + v)
                 [top, gh, base, base + v, s, v]
               end
             else
               bh = (gh - 2 * (series.size - 1)) / series.size
               series.each_with_index.filter_map do |s, k|
                 v = s[:values][i]
                 next if v.nil? || v.zero?

                 [top + k * (bh + 2), bh, 0, v, s, v]
               end
             end
      list.map do |(ty, th, from, to, s, v)|
        l, r = [hx(from), hx(to)].minmax
        [l, ty.round(2), [r - l, 1].max.round(2), th.round(2), s, v, color_at(s, i)]
      end
    end

    # Onde escrever o valor da linha (fim da maior barra) e o total (soma no empilhado).
    def hvalue(i)
      vals = series.map { _1[:values][i] }.compact
      return nil if vals.empty?

      stacked? ? vals.sum : vals.max_by(&:abs)
    end
    def hvalue_x(i) = [hx([hvalue(i).to_f, 0].max), zero_x].max + 6

    def hguides
      lo, hi = range
      [lo, (lo + hi) / 2, hi].uniq.map { |v| [hx(v), nice(v)] }
    end

    # Cor do valor i da série (tones:/colors: por valor, ou a da série).
    def color_at(s, i) = s[:colors][i] || s[:color]

    # ── Marcas (v0.27) ────────────────────────────────────────────────
    def marker_x(m) = cx(m[:index])

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
          rect(left, gw, base, top, s, v, i)
        end
      else
        bw = (gw - 2 * (series.size - 1)) / series.size
        series.each_with_index.filter_map do |s, k|
          v = s[:values][i]
          next if v.nil? || v.zero?

          rect(left + k * (bw + 2), bw, 0, v, s, v, i)
        end
      end
    end

    # Topo, base e o meio (menos o que cai em cima da linha do zero) + a linha do zero.
    def guides
      lo, hi = range
      marks = [hi, (hi + lo) / 2, lo].uniq.reject { |v| (v / (hi - lo)).abs < 0.12 }
      (marks.map { |v| [y(v), nice(v), false] } << [zero_y, 0, true]).uniq { _1[0] }
    end

    def line_points = points_of(line)
    def line_d = path_of(line_points)
    def projection_points = points_of(projection)
    def projection_d = path_of(projection_points)

    # Dica do grupo: rótulo + cada série (e a linha).
    def tip(i)
      rows = series.map { |s| "#{s[:name]}: #{s[:values][i].nil? ? "—" : fmt(s[:values][i])}" }
      rows << "#{line[:name]}: #{fmt(line[:values][i])}" if line && line[:values][i]
      rows << "#{projection[:name]}: #{fmt(projection[:values][i])}" if projection && projection[:values][i]
      rows.concat(markers.select { _1[:index] == i }.map { "#{_1[:label]} (#{marker_kind_label(_1[:kind])})" })
      [labels[i], *rows].join("\n")
    end

    def table_markers? = markers?

    def nice(v)
      return v.round if v.abs < 100

      v.round(-(Math.log10(v.abs).floor - 1))
    end

    def uid = @uid ||= "ss-barc-#{object_id}"

    # v1.14.0: o arrastar (ss-scrub), em % do desenho; o ponto vai na linha (line:) quando há.
    def scrub? = @scrub && data? && !horizontal?
    def scrub_points
      labels.each_index.map do |i|
        lv = line && line[:values][i]
        rows = series.map { |s| [s[:name], color_at(s, i), s[:values][i].nil? ? "—" : fmt(s[:values][i])] }
        rows << [line[:name], line[:color], fmt(lv)] if lv
        rows << [projection[:name], projection[:color], fmt(projection[:values][i])] if projection && projection[:values][i]
        [(cx(i) * 100.0 / w).round(2), (lv ? (y(lv) * 100.0 / h).round(2) : nil), labels[i], rows]
      end
    end

    private

    def points_of(s) = s ? labels.each_index.filter_map { |i| (v = s[:values][i]) && [cx(i), y(v)] } : []
    def path_of(pts) = pts.map.with_index { |(px, py), k| "#{k.zero? ? "M" : "L"}#{px},#{py}" }.join(" ")

    def normalize(s, fallback)
      s = s.to_h.transform_keys(&:to_sym)
      color = s[:color] || TONES[s[:tone]&.to_sym] || fallback
      colors = Array(s[:colors]).presence || Array(s[:tones]).map { |t| t && TONES[t.to_sym] }
      { name: s[:name].to_s, values: Array(s[:values]).map { _1&.to_f }, color:, colors: }
    end

    def rect(x, w, from, to, s, v, i)
      top, bottom = [y(from), y(to)].minmax
      [x.round(2), top, w.round(2), [bottom - top, 1].max.round(2), s, v, color_at(s, i)]
    end
  end
end
