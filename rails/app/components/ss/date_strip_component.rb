module Ss
  # Faixa horizontal com os dias do mês (v1.9, par do SsDateStrip): o dia escolhido é uma pílula alta na cor da
  # marca que desliza com mola até o dia novo (no morph do Turbo e no clique), e a faixa rola até ele. Pontinhos
  # nos dias com evento. O cabeçalho "Novembro 2026 ⌄" abre o calendário do navegador para pular de mês.
  #
  #   render Ss::DateStripComponent.new(selected: @dia, url: "/agenda?dia=%{date}",
  #     markers: { Date.new(2026, 11, 12) => [:accent], Date.new(2026, 11, 14) => [:success, :danger] })
  #
  # url: o endereço de cada dia, com %{date} (aaaa-mm-dd). markers: { Date => [tons] } (até 3; :accent, :success,
  # :warn, :danger). today: (padrão Date.current). show_header: false tira o cabeçalho. turbo_frame: os links
  # trocam só esse frame. Teclado: Tab entra no dia escolhido; ← → andam entre os dias.
  class DateStripComponent < BaseComponent
    TONES = %i[accent success warn danger muted].freeze

    attr_reader :selected

    def initialize(selected:, url:, markers: {}, today: nil, show_header: true, turbo_frame: nil, **rest)
      super(**rest)
      @selected = selected.to_date
      @url, @today, @show_header, @frame = url.to_s, (today || Date.current).to_date, show_header, turbo_frame
      @markers = markers.to_h.each_with_object({}) { |(k, v), h| h[k.to_date] = Array(v).map(&:to_sym).select { |t| TONES.include?(t) }.first(3) }
    end

    def days = (selected.beginning_of_month..selected.end_of_month).to_a
    def href(d) = @url.gsub("%{date}", d.iso8601)
    def month_title = "#{ss_months[selected.month - 1].to_s.capitalize} #{selected.year}"

    def day_label(d)
      parts = ["#{ss_weekdays(long: true)[d.wday]}, #{d.day}"]
      parts << ss_t("date_strip.today", default: "hoje") if d == @today
      n = @markers[d]&.size.to_i
      parts << ss_t("date_strip.events", default: n == 1 ? "1 evento" : "%{count} eventos", count: n) if n.positive?
      parts.join(", ")
    end

    def call
      tag.nav(**root_attrs(class: classes("ss-date-strip"), "aria-label": ss_t("date_strip.label", default: "Dias de %{month}", month: month_title),
                           data: { controller: "ss-date-strip", ss_date_strip_url_value: @url, ss_date_strip_frame_value: @frame }.compact)) do
        safe_join([(header if @show_header), strip].compact)
      end
    end

    private

    def header
      label = ss_t("date_strip.open_calendar", default: "Mês: %{month}. Abrir calendário", month: month_title)
      tag.div(class: "ss-date-strip-head") do
        safe_join([
          tag.button(safe_join([tag.span(month_title), ss_icon("chevron-down", size: nil)]), type: "button", class: "ss-date-strip-month",
                     "aria-label": label, data: { action: "ss-date-strip#pick" }),
          tag.input(type: "date", value: selected.iso8601, class: "ss-date-strip-picker", tabindex: "-1", "aria-hidden": "true",
                    data: { ss_date_strip_target: "picker", action: "change->ss-date-strip#jump" })
        ])
      end
    end

    def strip
      tag.div(class: "ss-date-strip-days", style: "--i:#{selected.day - 1}", data: { ss_date_strip_target: "scroller", action: "keydown->ss-date-strip#key" }) do
        safe_join([tag.span(class: "ss-date-strip-pill", "aria-hidden": "true"),
                   *days.map do |d|
                     dots = @markers[d].to_a
                     tag.a(href: href(d), class: "ss-date-strip-day", "aria-label": day_label(d), "aria-current": (d == selected ? "date" : nil),
                           tabindex: (d == selected ? nil : "-1"),
                           data: { today: (d == @today ? "" : nil), turbo_frame: @frame, ss_date_strip_target: "day", index: d.day - 1,
                                   action: "click->ss-date-strip#choose" }.compact) do
                       safe_join([tag.small(ss_weekdays[d.wday]), tag.b(d.day, class: "num"),
                                  tag.span(safe_join(dots.map { |t| tag.i(data: { tone: t }) }), class: "ss-date-strip-dots", "aria-hidden": "true")])
                     end
                   end])
      end
    end
  end
end
