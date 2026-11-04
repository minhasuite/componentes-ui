module Ss
  # Número que conta de 0 até o valor quando entra na tela (IntersectionObserver,
  # controller ss-count-up). Sem JS ou com menos movimento, mostra o valor final.
  #   render Ss::CountUpComponent.new(value: 48320.5, format: :money)   # R$ 48.320,50 (ss_amount)
  #   render Ss::CountUpComponent.new(value: 214, suffix: " pedidos")
  # format: :money, :integer, :decimal (decimals:), :percent.
  # roll: true → quando o valor muda (morph do Turbo ou JS trocando data-ss-count-up-value-value),
  # os dígitos rolam como caça-níquel e assentam com mola; sem roll, conta do antigo ao novo.
  class CountUpComponent < BaseComponent
    def initialize(value:, format: :integer, decimals: nil, prefix: nil, suffix: nil, duration: 900, roll: false, **opts)
      super(**opts)
      @value = value.to_f
      @format = format.to_sym
      @decimals = decimals || (%i[money].include?(@format) ? 2 : (@format == :decimal ? 1 : 0))
      @prefix = prefix
      @suffix = suffix
      @duration = duration
      @roll = roll
    end

    def text
      n = number_with_precision(@value, precision: @decimals, delimiter: ".", separator: ",")
      case @format
      when :money then "R$ #{n}"
      when :percent then "#{n}%"
      else n
      end
    end

    def call
      data = { controller: "ss-count-up", ss_count_up_value_value: @value, ss_count_up_decimals_value: @decimals,
               ss_count_up_format_value: @format, ss_count_up_duration_value: @duration, ss_count_up_roll_value: (@roll || nil) }.compact
      inner = @format == :money ? ss_amount(text, css: "ss-count-up-n") : tag.span(text, class: "ss-count-up-n num")
      tag.span(**root_attrs(class: classes("ss-count-up"), data:)) do
        safe_join([@prefix, tag.span(text, class: "ss-sr"), tag.span(inner, "aria-hidden": true, data: { ss_count_up_target: "out" }), @suffix].compact)
      end
    end
  end
end
