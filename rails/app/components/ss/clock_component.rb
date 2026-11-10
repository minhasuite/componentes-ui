module Ss
  # Relógio digital grande com data e o ponto dos segundos opcional. O servidor desenha a hora
  # inicial (now:, padrão Time.current) e o controller ss-clock anda de segundo em segundo com
  # Intl no idioma da página (<html lang>), ou no locale: dado.
  #
  #   render Ss::ClockComponent.new(seconds: true)
  #   render Ss::ClockComponent.new(now: Time.zone.parse("2026-11-04 14:32"), fixed: true)  # parado
  #
  # hour12: true mostra AM/PM. time_zone: "America/Sao_Paulo" (Intl) para mostrar outro fuso.
  # seconds: true é o ponto que pisca; seconds: :digits (v0.10.1, SsClock(seconds: digits))
  # mostra os segundos em dígitos menores depois dos minutos ("14:32 :07").
  # fit: true (v0.10.1) ocupa a largura da caixa e encolhe para caber (container query): hora e
  # data diminuem num card estreito (~160 px, grade de 2 colunas) em vez de vazar; size: é o teto.
  class ClockComponent < BaseComponent
    WEEKDAYS = %w[domingo segunda-feira terça-feira quarta-feira quinta-feira sexta-feira sábado].freeze
    MONTHS = %w[janeiro fevereiro março abril maio junho julho agosto setembro outubro novembro dezembro].freeze

    attr_reader :now

    def initialize(now: nil, seconds: false, date: true, hour12: false, fixed: false, locale: nil, time_zone: nil,
                   size: nil, fit: false, **rest)
      super(**rest)
      @now = now || Time.current
      @seconds, @date, @hour12, @fixed, @locale, @tz, @size = seconds, date, hour12, fixed, locale, time_zone, size
      @fit = fit
    end

    def digits? = @seconds.to_s == "digits"
    def dot? = @seconds && !digits?

    def hh = @hour12 ? ((now.hour % 12).zero? ? 12 : now.hour % 12).to_s : Kernel.format("%02d", now.hour)
    def mm = Kernel.format("%02d", now.min)
    def ampm = (@hour12 ? (now.hour < 12 ? "AM" : "PM") : nil)

    # Data no idioma pela tradução da gem (date.weekdays/months) ou pt-BR: "quarta-feira, 4 de novembro".
    def date_text
      wd = ss_t("date.weekdays", default: nil) || WEEKDAYS
      wd = WEEKDAYS unless wd.is_a?(Array) && wd.size == 7
      ms = ss_t("date.months", default: nil) || MONTHS
      ms = MONTHS unless ms.is_a?(Array) && ms.size == 12
      tpl = ss_t("clock.date", default: "%{weekday}, %{day} de %{month}")
      I18n.interpolate(tpl, weekday: wd[now.wday], day: now.day, month: ms[now.month - 1])
    end

    def aria_text = ["#{hh}:#{mm}#{":#{Kernel.format("%02d", now.sec)}" if digits?}#{" #{ampm}" if ampm}", (date_text if @date)].compact.join(", ")

    def call
      own = @attrs.to_h[:data].to_h
      data = @fixed ? {} : { controller: [own[:controller] || own["controller"], "ss-clock"].compact.join(" "),
                             ss_clock_hour12_value: (@hour12 || nil), ss_clock_date_value: @date,
                             ss_clock_locale_value: @locale, ss_clock_zone_value: @tz }.compact
      style = "--clock-size: #{@size.to_i}px" if @size
      tag.div(**root_attrs(class: classes("ss-clock", ("is-seconds" if @seconds), ("is-digits" if digits?), ("is-fit" if @fit)), style:, data:,
                           role: "timer", aria: { live: "off", label: aria_text })) do
        safe_join([
          tag.span(class: "ss-clock-time num", "aria-hidden": true) do
            safe_join([tag.span(hh, data: { ss_clock_target: "h" }), tag.span(":", class: "ss-clock-colon"),
                       tag.span(mm, data: { ss_clock_target: "m" }),
                       (tag.small(Kernel.format("%02d", now.sec), class: "ss-clock-sec", data: { ss_clock_target: "s" }) if digits?),
                       (tag.i(class: "ss-clock-dot", data: { ss_clock_target: "dot", on: now.sec.even? }) if dot?),
                       (tag.small(ampm, class: "ss-clock-ampm", data: { ss_clock_target: "ampm" }) if ampm)].compact)
          end,
          (tag.span(date_text, class: "ss-clock-date", "aria-hidden": true, data: { ss_clock_target: "date" }) if @date)
        ].compact)
      end
    end
  end
end
