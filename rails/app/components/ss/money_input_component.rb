module Ss
  # Dinheiro em BRL: digita só número (empurra da direita, como caixa), mostra "R$ 1.234,56" com os
  # centavos menores e manda o valor em centavos inteiros no hidden (name:).
  #   render Ss::MoneyInputComponent.new(name: "lancamento[valor_cents]", label: "Valor", value_cents: 12990)
  class MoneyInputComponent < BaseComponent
    attr_reader :name, :label, :value_cents, :help, :id, :required

    def initialize(name:, label:, value_cents: nil, help: nil, required: false, id: nil, **rest)
      super(**rest)
      @name, @label, @value_cents, @help, @required = name, label, value_cents, help, required
      @id = id || "ss-money-#{SecureRandom.hex(3)}"
    end

    def formatted
      return "" if value_cents.nil?

      cents = value_cents.to_i
      reais = (cents.abs / 100).to_s.reverse.scan(/\d{1,3}/).join(".").reverse
      "#{"-" if cents.negative?}R$ #{reais},#{format("%02d", cents.abs % 100)}"
    end
  end
end
