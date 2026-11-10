module Ss
  # Dinheiro: digita só número (empurra da direita, como caixa), mostra "R$ 1.234,56" com os
  # centavos menores e manda o valor em centavos inteiros no hidden (name:). Moeda em currency:
  # (padrão ComponentesUi.config.currency, BRL) e formato do idioma da página (Intl no navegador).
  #   render Ss::MoneyInputComponent.new(name: "lancamento[valor_cents]", label: "Valor", value_cents: 12990)
  #
  # v0.15 (o mesmo do SsMoneyField):
  # - signed: false trava o sinal (a tecla "-" não inverte; padrão true, como antes);
  # - expression: true aceita conta ("45+12,50", "3×19,90"): o campo fica livre, embaixo aparece
  #   "= R$ 57,50" e o hidden recebe o resultado; ao sair, o texto vira o valor. Conta que não fecha
  #   marca o campo inválido. No servidor, ComponentesUi::AmountExpression faz a mesma conta.
  class MoneyInputComponent < BaseComponent
    attr_reader :name, :label, :value_cents, :help, :id, :required

    def initialize(name:, label:, value_cents: nil, help: nil, required: false, id: nil, currency: nil, signed: true,
                   expression: false, **rest)
      super(**rest)
      @name, @label, @value_cents, @help, @required = name, label, value_cents, help, required
      @currency = currency || ss_currency
      @id = id || "ss-money-#{SecureRandom.hex(3)}"
      @signed = signed
      @expression = expression
    end

    def formatted
      return "" if value_cents.nil?

      cents = value_cents.to_i
      text = ss_money(cents.abs / 100.0, currency: @currency)
      cents.negative? ? "-#{text}" : text
    end

    def placeholder = ss_money(0, currency: @currency)
    def expression? = @expression
    def described_by = [("#{id}-help" if help), ("#{id}-result" if expression?)].compact.join(" ").presence
    def signed? = @signed
    def invalid_text = ss_t("money_input.invalid", default: "Conta ou valor inválido")
    attr_reader :currency
  end
end
