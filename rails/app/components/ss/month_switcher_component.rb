module Ss
  # ‹ Outubro 2026 › (v0.15, par do SsMonthSwitcher): troca de mês por link (sem JS para
  # funcionar). As setas vão ao mês vizinho; o título, fora do mês atual, volta para ele. min:/max:
  # travam as setas. O título novo entra deslizando do lado da troca (ss-month-switcher) e ← →
  # com o foco na peça trocam o mês.
  #
  #   render Ss::MonthSwitcherComponent.new(month: @mes)                       # ?month=2026-10 na URL atual
  #   render Ss::MonthSwitcherComponent.new(month: @mes, param: :mes, frame: "lancamentos")
  #   render Ss::MonthSwitcherComponent.new(month: @mes, url: ->(m) { relatorio_path(m.strftime("%Y-%m")) })
  #
  # month: Date/Time ou "AAAA-MM". url: lambda que recebe o 1º dia do mês e devolve o caminho
  # (padrão: a URL atual com param= "AAAA-MM", mantendo os outros parâmetros). frame: id do
  # turbo-frame que os links trocam (data-turbo-frame) e data-turbo-action="advance".
  class MonthSwitcherComponent < BaseComponent
    def initialize(month:, url: nil, param: :month, min: nil, max: nil, frame: nil, today: nil, label: nil, **rest)
      super(**rest)
      @month = self.class.parse(month) || Date.today.beginning_of_month
      @url = url
      @param = param.to_s
      @min = self.class.parse(min)
      @max = self.class.parse(max)
      @frame = frame
      @today = (today || Date.today).to_date.beginning_of_month
      @label = label
    end

    # "2026-10", Date, Time ou nil → 1º dia do mês.
    def self.parse(v)
      case v
      when nil, "" then nil
      when Date, Time, DateTime then v.to_date.beginning_of_month
      else
        m = v.to_s.match(/\A(\d{4})-(\d{1,2})/)
        m && Date.new(m[1].to_i, m[2].to_i.clamp(1, 12), 1)
      end
    end

    def month = @month
    def prev_month = @month.prev_month
    def next_month = @month.next_month
    def current? = @month == @today
    def allowed?(m) = (@min.nil? || m >= @min) && (@max.nil? || m <= @max)

    def title_of(m)
      name = ss_months[m.month - 1].to_s
      "#{name[0].to_s.upcase}#{name[1..]} #{m.year}"
    end

    def href(m)
      return @url.call(m) if @url

      query = request.query_parameters.merge(@param => m.strftime("%Y-%m"))
      "#{request.path}?#{query.to_query}"
    end

    def link_data(dir)
      { ss_month_dir: dir, turbo_frame: @frame, turbo_action: ("advance" if @frame), action: "ss-month-switcher#go" }.compact
    end

    def label = @label || ss_t("month_switcher.label", default: "Mês")
    def prev_label = ss_t("month_switcher.previous", default: "Mês anterior")
    def next_label = ss_t("month_switcher.next", default: "Próximo mês")
    def current_label = ss_t("month_switcher.current", default: "Voltar ao mês atual")

    def chevron(d) = %(<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="#{d}"/></svg>).html_safe
  end
end
