module Ss
  # Agenda em lista de vários dias (v0.10.1, mesmo nome do SsAgendaList): um cabeçalho por dia
  # que gruda no topo (como o do Logbook) e os compromissos do dia com a hora, a barra da cor
  # e o título (link com url:). Dia sem nada mostra "Nada neste dia". week_strip: true põe em
  # cima a faixa da semana (ponto nos dias com compromisso, o selected: marcado); cada dia da
  # faixa vai para a âncora #day-<aaaa-mm-dd> da lista ou para o day_url:.
  #
  #   render Ss::AgendaListComponent.new(week_strip: true, selected: Date.current,
  #     days: [{ date: Date.current, label: "Hoje",
  #              events: [{ time: "08:30", title: "Dentista", detail: "Dr. Paulo", tone: :info, url: consulta_path(c) }] },
  #            { date: Date.tomorrow, events: [] }])
  #
  # - time: já formatado por quem chama ("08:30", "15:00–16:00"). v0.10.2: end: ("16:00") vai
  #   embaixo, menor; all_day: true sem time: mostra "Dia todo" (agenda_list.all_day). A coluna
  #   da hora cresce até o texto mais largo da lista (todas alinhadas). color: (cor CSS) ou tone:
  #   :accent (padrão), :info, :warn, :danger, :success, :neutral.
  # - label: do dia é opcional; sem ele, "Hoje"/"Amanhã" (pelo now:) ou o dia da semana; a data
  #   curta vai sempre ao lado.
  # - day_url: proc (->(date) { … }) ou texto com %{date} (ISO); sem ele, a âncora da lista
  #   (dias fora da lista ficam sem link).
  # - empty_label: troca o "Nada neste dia" (agenda_list.empty).
  class AgendaListComponent < BaseComponent
    TONES = { "accent" => "var(--accent)", "info" => "var(--ss-info)", "warn" => "var(--warn)", "danger" => "var(--danger)",
              "critical" => "var(--danger)", "success" => "var(--success)", "neutral" => "var(--muted)" }.freeze

    def initialize(days:, week_strip: false, selected: nil, day_url: nil, empty_label: nil, now: nil, label: nil, **rest)
      super(**rest)
      @days = Array(days).map { |d| normalize(d.to_h.transform_keys(&:to_sym)) }.sort_by { _1[:date] }
      @week_strip, @day_url, @empty_label, @label = week_strip, day_url, empty_label, label
      @now = now
      @selected = (selected || @days.first&.dig(:date) || today).to_date
    end

    attr_reader :days, :selected

    def today = (@now || Time.zone.now).to_date
    def week_strip? = !!@week_strip
    def empty_label = @empty_label || ss_t("agenda_list.empty", default: "Nada neste dia")
    def label = @label || ss_t("agenda_list.label", default: "Agenda")
    def week_label = ss_t("agenda_list.week", default: "Semana")
    def anchor(date) = "day-#{date.iso8601}"

    def day_label(d)
      return d[:label] if d[:label].present?
      return ss_t("agenda_list.today", default: "Hoje") if d[:date] == today
      return ss_t("agenda_list.tomorrow", default: "Amanhã") if d[:date] == today + 1

      ss_weekdays(long: true)[d[:date].wday].to_s
    end

    def short_date(date) = "#{ss_weekdays[date.wday].to_s.delete(".")}, #{ss_date(date, :day_month)}"

    # A semana (domingo a sábado) do selected:.
    def week = (0..6).map { |i| selected - selected.wday + i }

    def events_on?(date) = @days.any? { |d| d[:date] == date && d[:events].any? }

    def week_href(date)
      case @day_url
      when Proc then @day_url.call(date)
      when String then @day_url.gsub("%{date}", date.iso8601)
      else @days.any? { _1[:date] == date } ? "##{anchor(date)}" : nil
      end
    end

    def color(e) = e[:color] || TONES[e[:tone].to_s] || TONES["accent"]

    def all_day?(e) = !!e[:all_day] && e[:time].blank?
    def all_day_label = ss_t("agenda_list.all_day", default: "Dia todo")
    def time_label(e) = all_day?(e) ? all_day_label : e[:time].to_s

    # Largura da coluna da hora (DM Mono .78rem: ~.47rem por caractere, em rem para o "Dia todo"
    # em Manrope ficar na mesma coluna) quando algum horário passa de
    # 5 caracteres ("15:00–16:00"); nil mantém a do CSS.
    def time_width
      n = @days.flat_map { |d| d[:events] }.reject { all_day?(_1) }.flat_map { [_1[:time].to_s.length, _1[:end].to_s.length] }.max.to_i
      "max(2.6rem, calc(#{n} * .47rem + .3rem))" if n > 5
    end

    def root_style = [@attrs[:style], ((w = time_width) ? "--ss-agl-tw: #{w}" : nil)].compact.join("; ").presence

    private

    def normalize(d)
      evs = Array(d[:events]).map do |e|
        e = e.to_h.transform_keys(&:to_sym)
        e[:color] = nil unless e[:color].to_s.match?(/\A[#\w\s(),.%-]+\z/)
        e
      end
      { date: d[:date].to_date, label: d[:label], events: evs }
    end
  end
end
