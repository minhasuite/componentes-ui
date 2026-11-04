module Ss
  # Card de clima: temperatura, ícone e texto da condição, mín/máx, umidade, vento e a faixa de
  # previsão (por hora ou por dia). Só recebe dados; não chama rede.
  #
  #   render Ss::WeatherCardComponent.new(temperature: 27, condition: :partly_cloudy, location: "São Paulo",
  #            min: 19, max: 29, humidity: 62, wind: 14,
  #            forecast: [{ label: "15h", condition: :rain, temp: 25, precip: 70 }, { label: "Ter", condition: :clear, temp: 30, min: 20 }])
  #
  # condition: :clear | :clear_night | :partly_cloudy | :cloudy | :rain | :storm | :snow | :fog | :wind.
  # Ícones em SVG simples (cores semânticas: sol âmbar, chuva azul, nuvem neutra).
  # rain_chance: 70 (v0.10.1, SsWeatherCard(rainChance:)): chance de chuva de agora, com a gota,
  # ao lado da condição (texto para o leitor: weather_card.rain_chance).
  # feels_like: 30 (SsWeatherCard(feelsLike:)) entra na linha de mín/máx ("Sensação 30°").
  # Previsão: cada item aceita rain_chance: (igual ao precip:); no diário (com min:) a chance
  # aparece numa linha a mais, com a gota.
  class WeatherCardComponent < BaseComponent
    CONDITIONS = %i[clear clear_night partly_cloudy cloudy rain storm snow fog wind].freeze
    DEFAULTS = { clear: "Céu limpo", clear_night: "Noite limpa", partly_cloudy: "Parcialmente nublado",
                 cloudy: "Nublado", rain: "Chuva", storm: "Tempestade", snow: "Neve", fog: "Neblina", wind: "Ventania",
                 min: "Mín", max: "Máx", humidity: "Umidade", wind_label: "Vento", forecast: "Previsão",
                 rain_chance: "Chance de chuva", feels_like: "Sensação" }.freeze

    SUN = '<circle class="ss-wx-sun" cx="12" cy="12" r="4.5"/><g class="ss-wx-sun-l"><path d="M12 2.5v2.2M12 19.3v2.2M2.5 12h2.2M19.3 12h2.2M5.3 5.3l1.6 1.6M17.1 17.1l1.6 1.6M5.3 18.7l1.6-1.6M17.1 6.9l1.6-1.6"/></g>'.freeze
    CLOUD = '<path class="ss-wx-cloud" d="M7 19h10.5a4 4 0 0 0 .6-7.95A6 6 0 0 0 6.6 10.2 4.4 4.4 0 0 0 7 19z"/>'.freeze
    ICONS = {
      clear: SUN,
      clear_night: '<path class="ss-wx-moon" d="M19.5 14.5A8 8 0 0 1 9.5 4.5a8 8 0 1 0 10 10z"/>',
      partly_cloudy: '<g transform="translate(4 -3) scale(.75)">' + SUN + '</g><path class="ss-wx-cloud" d="M6 21h9.5a3.6 3.6 0 0 0 .5-7.15A5.4 5.4 0 0 0 5.6 13.1 4 4 0 0 0 6 21z"/>',
      cloudy: CLOUD,
      rain: '<g transform="translate(0 -3)">' + CLOUD + '</g><path class="ss-wx-drop" d="M8.5 19.5l-1 2.5M12.5 19.5l-1 2.5M16.5 19.5l-1 2.5"/>',
      storm: '<g transform="translate(0 -3)">' + CLOUD + '</g><path class="ss-wx-bolt" d="M13 15l-3 4.5h3l-1.5 4 4-5.5h-3l1.5-3z"/>',
      snow: '<g class="ss-wx-snow"><path d="M12 3v18M4.2 7.5l15.6 9M4.2 16.5l15.6-9"/><path d="M9.5 4.5 12 6l2.5-1.5M9.5 19.5 12 18l2.5 1.5"/></g>',
      fog: '<path class="ss-wx-fog" d="M4 9h16M6 13h12M4 17h16"/>',
      wind: '<path class="ss-wx-fog" d="M3 8h11a3 3 0 1 0-3-3M3 12h16a3 3 0 1 1-3 3M3 16h8"/>'
    }.freeze

    attr_reader :location, :humidity, :wind, :forecast, :unit, :wind_unit

    def initialize(temperature:, condition:, condition_text: nil, location: nil, min: nil, max: nil, humidity: nil,
                   wind: nil, forecast: [], unit: "°", wind_unit: "km/h", labels: {}, rain_chance: nil, feels_like: nil, **rest)
      super(**rest)
      @temperature, @condition_text, @location = temperature, condition_text, location
      @condition = cond(condition)
      @min, @max, @humidity, @wind, @unit, @wind_unit = min, max, humidity, wind, unit, wind_unit
      @forecast = Array(forecast).map { |f| f.to_h.transform_keys(&:to_sym).merge(condition: cond(f.to_h.transform_keys(&:to_sym)[:condition])) }
      @labels = labels.to_h.transform_keys(&:to_sym)
      @rain_chance = rain_chance.nil? ? nil : rain_chance.to_i.clamp(0, 100)
      @feels_like = feels_like
    end

    attr_reader :rain_chance

    def rain_text = "#{label(:rain_chance)} #{rain_chance}%"

    def label(key) = @labels[key] || ss_t("weather_card.#{key}", default: DEFAULTS[key])
    def t(v) = "#{v.to_f.round}#{unit}"
    def temperature = t(@temperature)
    def condition = @condition
    def condition_text = @condition_text || label(@condition)
    def min_max = [("#{label(:max)} #{t(@max)}" if @max), ("#{label(:min)} #{t(@min)}" if @min),
                   ("#{label(:feels_like)} #{t(@feels_like)}" unless @feels_like.nil?)].compact.join("  ·  ")

    # Chance de chuva do item da previsão (rain_chance: ou precip:).
    def rain_of(f) = f[:rain_chance] || f[:precip]

    def self.icon(condition, size: 32)
      c = CONDITIONS.include?(condition.to_s.to_sym) ? condition.to_s.to_sym : :cloudy
      %(<svg class="ss-wx-ico" width="#{size}" height="#{size}" viewBox="0 0 24 24" fill="none" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false">#{ICONS[c]}</svg>).html_safe
    end

    def icon(c, size: 32) = self.class.icon(c, size:)

    def forecast_aria(f)
      [f[:label], label(f[:condition]), t(f[:temp]) + (f[:min] ? " / #{t(f[:min])}" : ""), ("#{rain_of(f)}%" if rain_of(f))].compact.join(", ")
    end

    private

    def cond(c) = CONDITIONS.include?(c.to_s.to_sym) ? c.to_s.to_sym : :cloudy
  end
end
