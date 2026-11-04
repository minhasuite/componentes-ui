module Ss
  # Faixas de estado no tempo (v0.10): uma linha por item (liga/desliga, aberto/fechado,
  # os estados de um aspirador em 24 h) com trechos coloridos pelo estado sobre o mesmo
  # intervalo e o eixo do tempo embaixo. Passar o mouse (ou tocar) num trecho mostra o
  # balão com o estado, o horário e a duração; com foco na faixa, ← → andam pelos
  # trechos e o leitor de tela ouve. Mesmo nome e comportamento do SsStateBands (Flutter).
  #
  #   render Ss::StateBandsComponent.new(title: "Luzes e portas", from: 24.hours.ago, to: Time.current,
  #     tones: { "cleaning" => :success },
  #     rows: [{ label: "Luz da sala", current: "Desligada",
  #              segments: [{ from: t1, to: t2, state: "on", label: "Ligada" }, …] }])
  #
  # label_position: :top põe o nome em cima e a faixa na largura toda (alinha com o
  # Ss::TimeSeriesChartComponent, que também aceita bands: e as desenha dentro dele).
  # Tons: accent, success, warn, danger, info, neutral (o resto vai para a paleta de séries).
  class StateBandsComponent < BaseComponent
    include InView

    attr_reader :rows, :from, :to

    def initialize(rows:, from: nil, to: nil, tones: {}, label_position: :side, axis: true, title: nil,
                   locale: nil, embedded: false, texts: {}, **opts)
      super(**opts)
      @rows = rows.map { |r| normalize(r) }
      @tones = tones.to_h.transform_keys(&:to_s)
      @top = label_position.to_s == "top" || embedded
      @axis = axis && !embedded
      @title = title
      @locale = locale
      @embedded = embedded
      @texts = texts.to_h.transform_keys(&:to_sym)
      segs = @rows.flat_map { _1[:segments] }
      @from = from || segs.map { _1[:from] }.min
      @to = to || segs.map { _1[:to] }.max
    end

    def text(key, default) = @texts[key] || ss_t("state_bands.#{key}", default:)

    def empty? = @rows.empty? || @from.nil? || @to.nil? || @to <= @from
    def top? = @top
    def axis? = @axis
    def embedded? = @embedded
    def title = @title

    def tone_map = @tone_map ||= TimeData.tones_of(@rows, @tones)

    def from_ms = TimeData.ms(@from)
    def to_ms = TimeData.ms(@to)

    # Posição do trecho em % da janela (cortado nas pontas).
    def pos(seg)
      span = (to_ms - from_ms).to_f
      a = [[TimeData.ms(seg[:from]), from_ms].max, to_ms].min
      b = [[TimeData.ms(seg[:to]), from_ms].max, to_ms].min
      [((a - from_ms) / span * 100).round(3), ((b - a) / span * 100).round(3)]
    end

    def seg_title(seg)
      "#{seg[:label]} · #{when_text(seg[:from])} – #{ss_date(seg[:to].in_time_zone, :time)} · " \
        "#{TimeData.duration(seg[:to] - seg[:from], locale_now)}"
    end

    # Resumo para o leitor de tela: tempo em cada estado (e o de agora).
    def summary(row)
      tempo = Hash.new(0)
      row[:segments].each do |s|
        a = [s[:from], @from].max
        b = [s[:to], @to].min
        tempo[s[:label]] += (b - a) if b > a
      end
      return "#{row[:label]}: #{text(:no_data, "sem leituras")}" if tempo.empty?

      txt = "#{row[:label]}: #{tempo.map { |k, v| "#{k} #{TimeData.duration(v, locale_now)}" }.join(", ")}"
      row[:current] ? "#{txt}. #{row[:current]}" : txt
    end

    def lang = @locale&.to_s

    private

    def locale_now = @locale || ss_number_locale

    def when_text(t) = ss_date(t.in_time_zone, :day_month_time)

    def normalize(r)
      segs = Array(r[:segments]).map do |s|
        { from: s[:from], to: s[:to], state: s[:state].to_s, label: (s[:label] || s[:state]).to_s }
      end
      { label: r[:label].to_s, current: r[:current], segments: segs.sort_by { _1[:from] } }
    end
  end
end
