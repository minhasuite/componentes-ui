module Ss
  # Dias da semana: sete bolinhas (S T Q Q S S D) que marcam e desmarcam (checkboxes name[]),
  # mais os atalhos "Todos os dias", "Dias úteis" e "Fim de semana" (precisam de JS; sem ele,
  # somem). Os valores são os do ISO (1 = segunda … 7 = domingo); values: troca (ex. %w[mon … sun],
  # sempre de segunda a domingo). first_day: 7 começa no domingo.
  #   render Ss::WeekdayPickerComponent.new(name: "regra[dias]", selected: [1, 2, 3, 4, 5])
  class WeekdayPickerComponent < BaseComponent
    KEYS = %w[mon tue wed thu fri sat sun].freeze
    LETTERS = %w[S T Q Q S S D].freeze
    NAMES = %w[Segunda Terça Quarta Quinta Sexta Sábado Domingo].freeze

    attr_reader :name, :values, :first_day, :id

    def initialize(name:, selected: [], values: (1..7).to_a, first_day: 1, shortcuts: true, legend: nil, hide_legend: false,
                   disabled: false, labels: {}, id: nil, **rest)
      super(**rest)
      @name, @values, @first_day, @shortcuts, @legend, @hide_legend = name, values.map(&:to_s), first_day.to_i, shortcuts, legend, hide_legend
      @selected = Array(selected).map(&:to_s)
      @disabled, @labels = disabled, labels
      @id = id || "ss-wd-#{SecureRandom.hex(3)}"
    end

    def tx(key, default) = @labels[key.to_sym] || I18n.t("componentes_ui.weekday_picker.#{key}", default:)

    def shortcuts? = !!@shortcuts && !@disabled
    def disabled? = !!@disabled
    def legend = @legend || tx(:legend, "Dias da semana")
    def field_name = "#{name}[]"

    # Índices 0..6 (segunda..domingo) na ordem da tela.
    def order = (0..6).map { |i| (first_day - 1 + i) % 7 }

    # Letra e nome do dia saem de date.weekdays_narrow / date.weekdays (0 = domingo) do idioma;
    # labels: { letter_mon:, day_mon: … } troca um a um.
    def day(i)
      wday = (i + 1) % 7
      { value: values[i], checked: @selected.include?(values[i]),
        letter: @labels[:"letter_#{KEYS[i]}"] || narrow_days&.dig(wday) || LETTERS[i],
        name: @labels[:"day_#{KEYS[i]}"] || long_days&.dig(wday)&.then { _1[0].upcase + _1[1..] } || NAMES[i] }
    end

    def narrow_days = (@narrow_days ||= [ss_t("date.weekdays_narrow", default: nil)]).first.then { _1.is_a?(Array) && _1.size == 7 ? _1 : nil }
    def long_days = (@long_days ||= [ss_t("date.weekdays", default: nil)]).first.then { _1.is_a?(Array) && _1.size == 7 ? _1 : nil }

    def shortcut_list
      [[tx(:every_day, "Todos os dias"), values], [tx(:weekdays, "Dias úteis"), values[0, 5]], [tx(:weekend, "Fim de semana"), values[5, 2]]]
    end
  end
end
