module Ss
  # Dinheiro: digita só número (empurra da direita, como caixa), mostra "R$ 1.234,56" com os
  # centavos menores e manda o valor em centavos inteiros no hidden (name:). Moeda em currency:
  # (padrão ComponentesUi.config.currency, BRL) e formato do idioma da página (Intl no navegador).
  #   render Ss::MoneyInputComponent.new(name: "lancamento[valor_cents]", label: "Valor", value_cents: 12990)
  class MoneyInputComponent < BaseComponent
    attr_reader :name, :label, :value_cents, :help, :id, :required

    def initialize(name:, label:, value_cents: nil, help: nil, required: false, id: nil, currency: nil, **rest)
      super(**rest)
      @name, @label, @value_cents, @help, @required = name, label, value_cents, help, required
      @currency = currency || ss_currency
      @id = id || "ss-money-#{SecureRandom.hex(3)}"
    end

    def formatted
      return "" if value_cents.nil?

      cents = value_cents.to_i
      text = ss_money(cents.abs / 100.0, currency: @currency)
      cents.negative? ? "-#{text}" : text
    end

    def placeholder = ss_money(0, currency: @currency)
    attr_reader :currency
  end
end
