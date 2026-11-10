require "bigdecimal"

module ComponentesUi
  # Valor digitado como conta (v0.15; o mesmo do Ss::MoneyInputComponent(expression: true) e do
  # SsMoneyField(expression: true)): "45+12,50-3", "3*19,90", "(10+5)/3". Só números, + - * / × ÷ −
  # e parênteses, nada de eval. Devolve BigDecimal com 2 casas, ou nil se não fecha.
  #
  # Número no formato pt-BR: vírgula é decimal (1 ou 2 casas); ponto seguido de exatamente 3
  # dígitos é milhar ("1.500" = 1500); ponto com 1 ou 2 casas é decimal ("12.5"). Com
  # decimal: "." (en) inverte: ponto decimal, vírgula de milhar.
  #
  #   ComponentesUi::AmountExpression.call("45+12")          # => 0.57e2
  #   ComponentesUi::AmountExpression.cents("R$ 1.234,56")   # => 123456
  class AmountExpression
    TOKEN = %r{\s*([\d.,]+|[-+*/()])}

    def self.number(text, decimal: ",")
      s = text.to_s.strip
      s = s.tr(",.", ".,") if decimal == "."
      case s
      when /\A[1-9]\d{0,2}(\.\d{3})+(,\d{1,2})?\z/ then BigDecimal(s.delete(".").tr(",", "."))
      when /\A\d+(,\d{1,2})?\z/ then BigDecimal(s.tr(",", "."))
      when /\A\d+\.\d{1,2}\z/ then BigDecimal(s)
      when /\A,\d{1,2}\z/ then BigDecimal("0#{s.tr(",", ".")}")
      end
    end

    def self.call(text, decimal: ",")
      return BigDecimal(text.to_s).round(2) if text.is_a?(Numeric)

      s = text.to_s.tr("×÷−", "*/-").gsub(/[^\d.,+\-*\/()\s]/, "").strip
      return if s.empty?

      tokens = s.scan(TOKEN).flatten
      return unless tokens.join == s.delete(" ")

      new(tokens, decimal).parse
    rescue ZeroDivisionError, ArgumentError, FloatDomainError
      nil
    end

    # Em centavos inteiros (o que a API da suíte guarda), ou nil.
    def self.cents(text, decimal: ",")
      v = call(text, decimal:)
      v && (v * 100).round.to_i
    end

    # Tem operador (é conta, não só número)?
    def self.expression?(text) = text.to_s.strip.sub(/\A-/, "").match?(%r{[-+*/×÷−()]})

    def initialize(tokens, decimal)
      @tokens = tokens
      @decimal = decimal
    end

    def parse
      value = expr
      @tokens.empty? && value.finite? ? value.round(2) : nil
    end

    private

    def expr
      value = term
      value = @tokens.shift == "+" ? value + term : value - term while %w[+ -].include?(@tokens.first)
      value
    end

    def term
      value = factor
      value = @tokens.shift == "*" ? value * factor : value / factor while %w[* /].include?(@tokens.first)
      value
    end

    def factor
      tok = @tokens.shift
      case tok
      when "-" then -factor
      when "(" then expr.tap { raise ArgumentError unless @tokens.shift == ")" }
      when nil then raise ArgumentError
      else AmountExpression.number(tok, decimal: @decimal) || raise(ArgumentError)
      end
    end
  end
end
