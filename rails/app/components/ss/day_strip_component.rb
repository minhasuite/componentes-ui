module Ss
  # Faixa de status por dia (v0.28, par do SsDayStrip): N dias lado a lado, um traço por dia, como numa
  # página de status. Lê-se padrão, não valor: "cai toda segunda", "caiu uma vez no dia 12". Os dias têm
  # respiro entre si (não encostam), a dica de cada um traz a data e o texto, e o leitor de tela recebe uma
  # tabela (dia, situação).
  #
  #   render Ss::DayStripComponent.new(title: "Disponibilidade, 30 dias", start_label: "há 30 dias", end_label: "hoje",
  #     days: [{ date: Date.new(2026, 11, 1), tone: :ok, text: "100% no ar" },
  #            { date: Date.new(2026, 11, 2), tone: :warn, text: "2 falhas em 288" },
  #            { date: Date.new(2026, 11, 3), tone: :bad, text: "fora 3 h" },
  #            { date: Date.new(2026, 11, 4), tone: :none }])
  #
  # Dia: { date: (Date ou texto), tone: :ok | :warn | :bad | :none, text: "…" (a dica e a tabela),
  # label: "…" (no lugar da data formatada) }. tone :none = sem dado (traço vazado, não verde: "não olhei"
  # não é "estava no ar"). start_label:/end_label: as pontas embaixo (padrão: a primeira e a última data).
  # height: a altura dos traços (padrão 32). show_title: mostra o título em cima (senão só para o leitor).
  class DayStripComponent < BaseComponent
    TONES = %i[ok warn bad none].freeze

    attr_reader :title, :days

    def initialize(days:, title:, start_label: nil, end_label: nil, height: 32, show_title: false, **rest)
      super(**rest)
      @title = title
      @days = Array(days).map do |d|
        d = d.to_h.transform_keys(&:to_sym)
        tone = d[:tone].to_s.to_sym
        d.merge(tone: TONES.include?(tone) ? tone : :none)
      end
      @start_label, @end_label = start_label, end_label
      @height = height.to_i.clamp(12, 96)
      @show_title = show_title
    end

    def render? = days.any?

    def day_label(d)
      return d[:label].to_s if d[:label].present?

      d[:date].respond_to?(:strftime) ? ss_date(d[:date]) : d[:date].to_s
    end

    def tone_label(tone) = ss_t("day_strip.#{tone}", default: { ok: "No ar", warn: "Instável", bad: "Fora", none: "Sem dado" }[tone])
    def tip(d) = [day_label(d), tone_label(d[:tone]), d[:text].presence].compact.join(" · ")
    def start_label = @start_label || day_label(days.first)
    def end_label = @end_label || day_label(days.last)

    def call
      tag.figure(**root_attrs(class: classes("ss-day-strip"), style: "--ss-day-h: #{@height}px")) do
        safe_join([
          tag.figcaption(title, class: (@show_title ? "ss-day-strip-title" : "ss-sr")),
          tag.div(class: "ss-day-strip-days", "aria-hidden": "true") do
            safe_join(days.map { |d| tag.span(class: "ss-day", data: { tone: d[:tone] }, title: tip(d)) })
          end,
          tag.div(safe_join([tag.span(start_label), tag.span(end_label)]), class: "ss-day-strip-ends", "aria-hidden": "true"),
          tag.table(class: "ss-sr") do
            safe_join([
              tag.caption(title),
              tag.thead(tag.tr(safe_join([tag.th(ss_t("day_strip.day", default: "Dia"), scope: "col"),
                                          tag.th(ss_t("day_strip.status", default: "Situação"), scope: "col")]))),
              tag.tbody(safe_join(days.map do |d|
                tag.tr(safe_join([tag.th(day_label(d), scope: "row"),
                                  tag.td([tone_label(d[:tone]), d[:text].presence].compact.join(" · "))]))
              end))
            ])
          end
        ])
      end
    end
  end
end
