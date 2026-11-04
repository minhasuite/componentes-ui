module Ss
  # Gantt leve: uma barra por tarefa numa grade de dias, hoje marcado e o progresso
  # dentro da barra.
  #   render Ss::GanttComponent.new(start: Date.current - 3, days: 14, today: Date.current,
  #     tasks: [{ label: "Levantamento", from: d1, to: d2, progress: 0.6, tone: :accent }])
  class GanttComponent < BaseComponent
    WD = %w[D S T Q Q S S].freeze

    attr_reader :tasks, :start, :days, :today, :label

    def initialize(tasks:, start:, days: 14, today: Date.current, label: "Cronograma", **opts)
      super(**opts)
      @tasks = tasks
      @start = start.to_date
      @days = days
      @today = today
      @label = label
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
    def dm(d) = d.strftime("%d/%m")
  end
end
