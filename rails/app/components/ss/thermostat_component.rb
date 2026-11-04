module Ss
  # Termostato: anel de 270° com o alvo grande no centro, a temperatura atual embaixo (e um
  # tracinho no anel), botões −/+ e chips de modo. A cor do anel segue o modo: heat âmbar,
  # cool azul (--ss-info), off cinza, os outros na marca (ou o tone: do modo).
  #
  #   render Ss::ThermostatComponent.new(name: "value", target: 22.5, current: 20, mode: "heat",
  #            url: comando_path(@clima), mode_name: "mode", action: :heating)
  #
  # Com url:, vira um <form> (method:) e envia sozinho: −/+ e arrasto depois de debounce: ms
  # parado; o modo na hora. Sem url:, é só o campo (hidden name: e rádios mode_name:) dentro do
  # form de quem chama. action: :heating | :cooling | :idle | :off (o que o aparelho faz agora;
  # padrão: deduzido do modo e da temperatura). modes: [:off, :heat, :cool, :auto] ou hashes
  # { value:, label:, tone:, icon: }. pending: true mostra "Enviando…"; disabled: true apaga.
  #
  # v0.10.1 (como o SsThermostat(color:, tone:, showModes:, currentLabel:)):
  # - color: (cor CSS) ou tone: (:accent, :info, :warn, :danger, :success, :neutral, :heat,
  #   :cool) pinta o anel sem depender do modo; color: ganha de tone:, e os dois ganham do modo.
  # - show_modes: false esconde os chips de modo (o modo atual continua no hidden mode_name:).
  # - current_label: troca a linha da temperatura atual inteira ("Agora 22°" → o que vier).
  # - adjust_when_off: true deixa mudar o alvo (−/+, arrasto, teclado) com o modo off.
  # - format: segue o Kernel.format também no JS (o %% vira %).
  class ThermostatComponent < BaseComponent
    ICONS = {
      "off" => '<path d="M12 3v8M6.3 6.8a8 8 0 1 0 11.4 0"/>',
      "heat" => '<path d="M12 3c1 3 4 4.5 4 8.5a4 4 0 0 1-8 0c0-1.7.8-2.8 1.7-3.7.3 1.4 1 2.2 1.8 2.2C11.5 7.6 10.7 5.4 12 3z"/><path d="M12 21a6 6 0 0 0 6-6"/>',
      "cool" => '<path d="M12 2v20M4.9 6.5l14.2 11M4.9 17.5l14.2-11M9 4l3 2 3-2M9 20l3-2 3 2"/>',
      "auto" => '<path d="M20 12a8 8 0 0 1-14.3 4.9M4 12A8 8 0 0 1 18.3 7.1"/><path d="M18 3v4.2h-4.2M6 21v-4.2h4.2"/>'
    }.freeze
    MODE_LABELS = { "off" => "Desligado", "heat" => "Aquecer", "cool" => "Resfriar", "auto" => "Auto" }.freeze
    ACTIONS = %i[off heating cooling idle].freeze
    # Arco de 270° (de 135° a 405°) num círculo de raio 84 centrado em (100, 100).
    ARC = "M 40.6 159.4 A 84 84 0 1 1 159.4 159.4".freeze
    TONES = { "accent" => "var(--accent)", "info" => "var(--ss-info)", "warn" => "var(--warn)", "danger" => "var(--danger)",
              "critical" => "var(--danger)", "success" => "var(--success)", "neutral" => "var(--muted)",
              "heat" => "var(--thermo-heat)", "cool" => "var(--thermo-cool)" }.freeze

    attr_reader :name, :target, :current, :min, :max, :step, :unit, :mode, :mode_name, :url, :http_method, :id, :debounce

    def initialize(target:, name: "target", current: nil, min: 7, max: 35, step: 0.5, unit: "°C", mode: "heat",
                   modes: %i[off heat cool auto], mode_name: "mode", action: nil, url: nil, method: :post,
                   pending: false, disabled: false, draggable: true, debounce: 700, format: nil, id: nil,
                   label: nil, labels: {}, color: nil, tone: nil, show_modes: true, current_label: nil,
                   adjust_when_off: false, **rest)
      super(**rest)
      @name, @target, @current, @min, @max, @step, @unit = name, target.to_f, current&.to_f, min.to_f, max.to_f, step.to_f, unit
      @mode, @mode_name, @url, @http_method = mode.to_s, mode_name, url, method
      @modes_in, @action, @pending, @disabled, @draggable, @debounce = modes, action, pending, disabled, draggable, debounce
      @format, @label, @labels = format, label, labels
      @ring = safe_css(color) || TONES[tone.to_s]
      @show_modes, @current_label = show_modes, current_label
      @adjust_when_off = adjust_when_off
      @id = id || "ss-thermo-#{SecureRandom.hex(3)}"
    end

    def tx(key, default) = @labels[key.to_sym] || I18n.t("componentes_ui.thermostat.#{key}", default:)

    def modes
      @modes ||= Array(@modes_in).map do |m|
        h = m.is_a?(Hash) ? m.transform_keys(&:to_sym) : { value: m.to_s }
        v = h[:value].to_s
        { value: v, label: h[:label] || tx("mode_#{v}", MODE_LABELS[v] || v.humanize), tone: safe_css(h[:tone]),
          icon: h[:icon] || (ICONS[v] && %(<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">#{ICONS[v]}</svg>)) }
      end
    end

    def off? = mode == "off"
    # Desligado e sem adjust_when_off: o alvo fica travado.
    def locked? = disabled? || (off? && !@adjust_when_off)
    def pending? = !!@pending
    def disabled? = !!@disabled
    def form? = url.present?

    def action
      a = @action&.to_sym
      return a if ACTIONS.include?(a)
      return :off if off?
      return :idle if current.nil?
      return :heating if %w[heat auto].include?(mode) && current < target - 0.25
      return :cooling if %w[cool auto].include?(mode) && current > target + 0.25

      :idle
    end

    def legend
      return tx(:pending, "Enviando…") if pending?

      { off: tx(:off, "Desligado"), heating: tx(:heating, "Aquecendo"), cooling: tx(:cooling, "Resfriando"), idle: tx(:idle, "No alvo") }[action]
    end

    def frac(v) = max == min ? 0 : ((v - min) / (max - min)).clamp(0, 1).round(4)

    # "22,5°" (pt/es) ou "22.5°" (en), no idioma da página; format: "%.1f °C" troca.
    def text(v)
      return Kernel.format(@format, v) if @format

      n = (v % 1).zero? ? ss_number(v, precision: 0) : ss_number(v.round(1), precision: 1)
      "#{n}°"
    end

    def current_mode_tone = modes.find { |m| m[:value] == mode }&.dig(:tone)
    def show_modes? = @show_modes != false && modes.any?

    def style
      s = ["--f:#{frac(target)}"]
      s << "--cf:#{frac(current)}" if current
      ring = @ring || current_mode_tone
      s << "--thermo-c:#{ring}" if ring
      s.join(";")
    end

    def root_tag = form? ? :form : :div

    def root_options
      opts = { class: classes("ss-thermo", ("is-disabled" if disabled?), ("is-adjust-off" if @adjust_when_off)), style:, id: }
      if form?
        opts[:action] = url
        opts[:method] = http_method.to_s == "get" ? "get" : "post"
        opts[:"accept-charset"] = "UTF-8"
      end
      root_attrs(**opts, aria: { busy: ("true" if pending?) }.compact, data: {
        controller: "ss-thermostat", mode:, hvac: action,
        ss_thermostat_min_value: min, ss_thermostat_max_value: max, ss_thermostat_step_value: step,
        ss_thermostat_debounce_value: debounce, ss_thermostat_draggable_value: @draggable && !disabled?,
        ss_thermostat_format_value: @format.to_s, ss_thermostat_color_value: @ring.to_s,
        ss_thermostat_adjust_when_off_value: !!@adjust_when_off,
        ss_thermostat_off_label_value: tx(:off, "Desligado"), ss_thermostat_pending_label_value: tx(:pending, "Enviando…")
      })
    end

    def method_tag
      return unless form?

      safe_join([
        (hidden_field_tag("_method", http_method, id: nil) unless %w[get post].include?(http_method.to_s)),
        hidden_field_tag("authenticity_token", helpers.form_authenticity_token, id: nil)
      ].compact)
    rescue StandardError
      nil
    end

    def safe_css(v) = v.to_s.match?(%r{\A[#\w\s(),.%/-]+\z}) ? v.to_s : nil

    def step_icon(sign) = %(<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" aria-hidden="true"><path d="M5 12h14#{sign == :plus ? 'M12 5v14' : ''}"/></svg>).html_safe
  end
end
