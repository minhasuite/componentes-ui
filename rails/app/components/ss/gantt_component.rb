module Ss
  # Gantt leve: uma barra por tarefa numa grade de dias, hoje marcado e o progresso
  # dentro da barra.
  #   render Ss::GanttComponent.new(start: Date.current - 3, days: 14, today: Date.current,
  #     tasks: [{ label: "Levantamento", from: d1, to: d2, progress: 0.6, tone: :accent }])
  class GanttComponent < BaseComponent
    WD = %w[D S T Q Q S S].freeze # pt-BR de reserva (o texto sai de componentes_ui.date.weekdays_narrow)

    attr_reader :tasks, :start, :days, :today, :label

    def initialize(tasks:, start:, days: 14, today: Date.current, label: nil, **opts)
      super(**opts)
      @tasks = tasks
      @start = start.to_date
      @days = days
      @today = today
      @label = label || ss_t("gantt.label", default: "Cronograma")
    end

    def dates = (0...@days).map { @start + _1 }

    # Colunas da grade (a 1ª é o rótulo): [início, fim exclusivo], recortado à janela.
    def span_for(task)
      a = (task[:from].to_date - @start).to_i.clamp(0, @days)
      b = ((task[:to].to_date - @start).to_i + 1).clamp(0, @days)
      [a + 2, [b + 2, a + 3].max]
    end

    def visible?(task) = task[:to].to_date >= @start && task[:from].to_date < @start + @days
    def today_col = (d = (@today - @start).to_i).between?(0, @days - 1) ? d + 2 : nil
    def pct(task) = (task[:progress].to_f.clamp(0, 1) * 100).round
    def dm(d) = ss_date(d, :day_month)
    def wd(d) = (@wd ||= ss_t("date.weekdays_narrow", default: nil) || WD)[d.wday]
    def bar_title(t) = ss_t("gantt.bar_title", default: "%{label}: %{from} a %{to}, %{pct}%", label: t[:label], from: dm(t[:from]), to: dm(t[:to]), pct: pct(t))
    def bar_sr(t) = ss_t("gantt.bar_sr", default: "%{label}, de %{from} a %{to}, %{pct}% feito", label: t[:label], from: dm(t[:from]), to: dm(t[:to]), pct: pct(t))
  end
end
