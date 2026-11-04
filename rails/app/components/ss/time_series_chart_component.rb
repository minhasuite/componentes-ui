module Ss
  # Gráfico de séries no tempo (v0.10), o histórico de sensores: várias séries com
  # instantes reais e desiguais, eixo do tempo inteligente (horas num dia, dias numa
  # semana, meses num ano), um eixo Y por unidade (até duas), linha, área ou degrau,
  # legenda que liga e desliga, cursor com balão e faixas de estado embaixo. O desenho
  # é do controller ss-time-chart (SVG no tamanho real, números e datas pelo Intl no
  # idioma da página); o servidor manda os dados e o resumo para o leitor de tela.
  # Mesmo nome e comportamento do SsTimeChart (Flutter).
  #
  #   render Ss::TimeSeriesChartComponent.new(title: "Clima da sala", from: 48.hours.ago, to: Time.current,
  #     series: [{ name: "Sala", unit: "°C", decimals: 1, points: [[t1, 21.4], [t2, 21.9], …] },
  #              { name: "Umidade", unit: "%", points: [[t1, 61], …] }],
  #     bands: [{ label: "Luz", segments: [{ from:, to:, state: "on", label: "Ligada" }] }],
  #     zoom_url: historico_path(sensor_ids: ids))
  #
  # - points: [tempo, valor] ou [tempo, valor, mínimo, máximo] (agregado: faixa clara
  #   atrás da linha) ou { t:, v:, min:, max: }. Valor nil = buraco (a linha quebra).
  # - mode: :line, :area ou :step (degrau, para valores discretos); por série também.
  # - Arrastar com o mouse marca um trecho e aproxima; duplo clique (ou "Ver tudo")
  #   volta. Com zoom_url:, pede ao servidor a janela (?from=&to= em ISO 8601) pelo
  #   Turbo: troca o turbo-frame em volta (ou zoom_frame:) ou visita a página.
  # - zoomed: true (a página já veio na janela pedida) mostra o "Ver tudo", que vai ao reset_url.
  # - loading: true mostra o esqueleto; sem leituras, o estado vazio.
  # - Textos: componentes_ui.time_series_chart.* (texts: { empty: "…" } troca).
  # - legend: true/:auto (padrão: só com 2+ séries), :always (mesmo com uma série) ou
  #   false/:never. show_values: true põe na legenda o último valor de cada série (com a
  #   unidade); com o cursor em cima, o valor acompanha o instante do cursor e volta ao
  #   último ao sair. (v0.10.1, como o SsTimeChart(legend:, showValues:))
  # - time_zone: "America/Sao_Paulo" (v0.10.1): eixo, balão e resumo nesse fuso, não no do
  #   navegador (o padrão continua o do navegador no JS e o Time.zone no servidor).
  class TimeSeriesChartComponent < BaseComponent
    include InView

    attr_reader :title, :height

    def initialize(title:, series: [], from: nil, to: nil, mode: :line, bands: [], band_tones: {}, loading: false,
                   height: 220, legend: true, show_values: false, dual_axis: true, zoom_url: nil, zoom_frame: nil, reset_url: nil,
                   show_title: false, locale: nil, zoomed: false, texts: {}, time_zone: nil, **opts)
      super(**opts)
      @title = title
      @series = series.map { |s| normalize(s) }
      @mode = mode.to_s
      @bands = bands
      @band_tones = band_tones
      @loading = loading
      @height = height
      @legend = legend
      @show_values = show_values
      @dual_axis = dual_axis
      @zoom_url = zoom_url
      @zoom_frame = zoom_frame
      @reset_url = reset_url
      @show_title = show_title
      @zoomed = zoomed
      @locale = locale
      @zone = TimeData.zone(time_zone)
      @texts = texts.to_h.transform_keys(&:to_sym)
      @from, @to = range(from, to)
    end

    def text(key, default, **vars) = @texts[key] || ss_t("time_series_chart.#{key}", default:, **vars)

    def uid = @uid ||= "ss-tc-#{object_id}"
    def loading? = @loading
    # A janela já veio aproximada do servidor (zoom_url): "Ver tudo" aparece e volta pelo reset_url.
    def zoomed? = @zoomed
    def show_title? = @show_title
    def legend?
      case @legend
      when false, nil, :never, "never" then false
      when :always, "always" then @series.any?
      else @series.size > 1
      end
    end

    def show_values? = !!@show_values

    # Último valor da série dentro da janela, já formatado (ou o "—").
    def last_value(s)
      p = s[:points].reverse.find { |pt| pt[:v] && (@from.nil? || pt[:t] >= @from) && (@to.nil? || pt[:t] <= @to) }
      p ? value(p[:v], s) : text(:no_value, "—")
    end
    def series = @series
    def bands? = @bands.any? && !empty_range?

    def empty_range? = @from.nil? || @to.nil? || @to <= @from
    def empty? = empty_range? || (@series.none? { |s| s[:points].any? { _1[:v] } } && @bands.empty?)

    def color(i) = @series[i][:color] || "var(--series-#{i % 6 + 1})"

    # Dados para o controller: [{ name, unit, color, mode, decimals, pts: [[ms, v, min, max]] }].
    def series_json
      @series.each_with_index.map do |s, i|
        { name: s[:name], unit: s[:unit], color: color(i), mode: s[:mode], decimals: s[:decimals],
          pts: s[:points].map { |p| [TimeData.ms(p[:t]), p[:v], p[:min], p[:max]].then { |a| a[2].nil? && a[3].nil? ? a[0, 2] : a } } }
      end.to_json
    end

    def bands_component
      StateBandsComponent.new(rows: @bands, from: @from, to: @to, tones: @band_tones, embedded: true, locale: @locale,
                              time_zone: @zone&.name,
                              data: { ss_time_chart_target: "bands" })
    end

    def controller_data
      in_view_data(
        controller: "ss-time-chart",
        ss_time_chart_series_value: series_json,
        ss_time_chart_from_value: TimeData.ms(@from),
        ss_time_chart_to_value: TimeData.ms(@to),
        ss_time_chart_mode_value: @mode,
        ss_time_chart_dual_value: @dual_axis,
        ss_time_chart_zoom_url_value: @zoom_url,
        ss_time_chart_zoom_frame_value: @zoom_frame,
        ss_time_chart_reset_url_value: @reset_url,
        ss_time_chart_lang_value: @locale&.to_s,
        ss_time_chart_time_zone_value: TimeData.iana(@zone),
        ss_time_chart_empty_value: text(:no_value, "—")
      ).compact
    end

    # Resumo para o leitor de tela: período e mínimo, máximo e último de cada série.
    def summary
      periodo = "#{when_text(@from)} #{text(:until, "a")} #{when_text(@to)}"
      partes = @series.filter_map do |s|
        vs = s[:points].select { |p| p[:v] && p[:t] >= @from && p[:t] <= @to }.map { _1[:v] }
        next if vs.empty?

        v = ->(x) { value(x, s) }
        "#{s[:name]}: #{text(:min, "mínimo")} #{v.(vs.min)}, #{text(:max, "máximo")} #{v.(vs.max)}, #{text(:last, "último")} #{v.(vs.last)}"
      end
      "#{title}, #{periodo}. #{partes.join(". ")}".strip
    end

    # Valor com a unidade e as casas da série (o % vai colado), no idioma da página.
    def value(v, s)
      d = s[:decimals] || TimeData.auto_decimals(v)
      n = ss_number(v, precision: d, locale: @locale)
      n = n.sub(/([.,]\d*?)0+\z/, '\1').sub(/[.,]\z/, "") if d.positive?
      return n if s[:unit].to_s.empty?

      s[:unit] == "%" ? "#{n}%" : "#{n} #{s[:unit]}"
    end

    private

    def when_text(t) = ss_date(TimeData.local(t, @zone), :day_month_time)

    def normalize(s)
      pts = Array(s[:points]).map do |p|
        p.is_a?(Hash) ? { t: p[:t], v: p[:v]&.to_f, min: p[:min]&.to_f, max: p[:max]&.to_f } : { t: p[0], v: p[1]&.to_f, min: p[2]&.to_f, max: p[3]&.to_f }
      end.sort_by { _1[:t] }
      { name: s[:name].to_s, unit: s[:unit].presence, color: s[:color], mode: s[:mode]&.to_s, decimals: s[:decimals], points: pts }
    end

    def range(from, to)
      ts = @series.flat_map { |s| s[:points].map { _1[:t] } }
      segs = @bands.flat_map { |b| Array(b[:segments]) }
      ts += segs.flat_map { |g| [g[:from], g[:to]] }
      [from || ts.min, to || ts.max]
    end
  end
end
