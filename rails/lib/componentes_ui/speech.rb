module ComponentesUi
  # v1.13.0 "confiança na IA e suíte": o valor falado em centavos (par do SsSpeech.parseAmountPtBr do Flutter e do
  # ssParseAmount do ss_speech.js). O reconhecimento de voz é do navegador ou do app; aqui só se converte o texto.
  # Os mesmos casos (docs/v1130/fala.json) passam nos três lados.
  #
  #   ComponentesUi::Speech.parse_amount("cento e vinte e três e cinquenta") # => 12350
  #   ComponentesUi::Speech.parse_amount("mil e duzentos reais")             # => 120000
  #   ComponentesUi::Speech.parse_amount("doze e meio")                      # => 1250
  #   ComponentesUi::Speech.parse_amount("R$ 12,50")                         # => 1250
  #
  # Regras (as mesmas do Dart): grupos de até 999 por extenso, com mil/milhão/bilhão em ordem decrescente; a palavra
  # que não cabe mais no grupo começa os centavos ("doze e cinquenta" = 12,50; "cem e cinquenta" = 100,50);
  # "real/reais/conto(s)" fecham os reais; "centavos" no fim de um número de mil ou mais separa a dezena final como
  # centavos (abaixo de mil conta ao pé da letra); "e meio" = 50 centavos (depois de mil/milhão, metade dele);
  # "vírgula" separa os centavos como na escrita; algarismos valem ("R$ 1.234,56", "12,5", "2 mil e 500", "1,5 mil");
  # "menos" no começo deixa negativo. nil quando não há número ou a frase não fecha.
  module Speech
    UNITS = { "zero" => 0, "um" => 1, "uma" => 1, "dois" => 2, "duas" => 2, "tres" => 3, "quatro" => 4, "cinco" => 5,
              "seis" => 6, "sete" => 7, "oito" => 8, "nove" => 9 }.freeze
    TEENS = { "dez" => 10, "onze" => 11, "doze" => 12, "treze" => 13, "catorze" => 14, "quatorze" => 14, "quinze" => 15,
              "dezesseis" => 16, "dezasseis" => 16, "dezessete" => 17, "dezassete" => 17, "dezoito" => 18,
              "dezenove" => 19, "dezanove" => 19 }.freeze
    TENS = { "vinte" => 20, "trinta" => 30, "quarenta" => 40, "cinquenta" => 50, "cincoenta" => 50, "sessenta" => 60,
             "setenta" => 70, "oitenta" => 80, "noventa" => 90 }.freeze
    HUNDREDS = { "cento" => 100, "duzentos" => 200, "duzentas" => 200, "trezentos" => 300, "trezentas" => 300,
                 "quatrocentos" => 400, "quatrocentas" => 400, "quinhentos" => 500, "quinhentas" => 500,
                 "seiscentos" => 600, "seiscentas" => 600, "setecentos" => 700, "setecentas" => 700,
                 "oitocentos" => 800, "oitocentas" => 800, "novecentos" => 900, "novecentas" => 900 }.freeze
    SCALES = { "mil" => 1000, "milhao" => 1_000_000, "milhoes" => 1_000_000, "bilhao" => 1_000_000_000,
               "bilhoes" => 1_000_000_000 }.freeze
    REAIS = %w[real reais conto contos].freeze
    CENTAVOS = %w[centavo centavos].freeze
    WORDS = (UNITS.keys + TEENS.keys + TENS.keys + HUNDREDS.keys + ["cem"] + SCALES.keys).freeze

    def self.parse_amount(text) = Parser.new(text.to_s).run

    # Um grupo de até 999: value e o nível mais baixo já preenchido (3 centena, 2 dezena, 1 unidade; 4 vazio; 0 fechado).
    class Group
      attr_accessor :value, :min_level

      def initialize = reset
      def empty? = @min_level == 4

      def add(v, level, closes: false)
        return false if level >= @min_level

        @value += v
        @min_level = closes ? 1 : level
        true
      end

      def set(v)
        @value = v
        @min_level = 0
      end

      def reset
        @value = 0
        @min_level = 4
      end
    end

    class Parser
      FROM = "áàâãäéèêëíìîïóòôõöúùûüç".freeze
      TO = "aaaaaeeeeiiiiooooouuuuc".freeze

      def initialize(text)
        @text = text
        @mode = :reais
        @total = 0
        @group = Group.new
        @cents = Group.new
        @last_scale = nil
        @last_was_scale = false
        @seen = false
        @neg = false
        @raw_cents = nil
        @numeric_frac = nil
        @decimal = []
        @decimal_digits = +""
        @decimal_only_digits = true
      end

      def run
        folded = @text.downcase.tr(FROM, TO).gsub("r$", " ").gsub("−", "-")
        folded.scan(/\d+(?:[.,]\d+)*|[a-z]+|-/).each { |t| return nil unless step(t) }
        finish
      end

      private

      def self.thousands(t)
        parts = t.split(".", -1)
        return nil if parts.drop(1).any? { _1.length != 3 }

        Integer(parts.join, 10)
      rescue ArgumentError
        nil
      end

      # "1.234,56" → [1234, 56]; "12,5" → [12, 50]; "1.500" → [1500, nil]; "12.50" → [12, 50]; inválido → nil.
      def numeric(t)
        frac = ->(f) { f.empty? || f.length > 2 ? nil : f.ljust(2, "0").to_i }
        if t.include?(",")
          i = t.rindex(",")
          whole, f = t[0...i], t[(i + 1)..]
          return nil if whole.include?(",")

          w = Parser.thousands(whole.empty? ? "0" : whole)
          c = frac.call(f)
          return w.nil? || c.nil? ? nil : [w, c]
        end
        if t.include?(".")
          parts = t.split(".", -1)
          if parts.length == 2 && parts[1].length <= 2
            c = frac.call(parts[1])
            return c.nil? ? nil : [parts[0].to_i, c]
          end
          w = Parser.thousands(t)
          return w.nil? ? nil : [w, nil]
        end
        [t.to_i, nil]
      end

      def step(t)
        if t == "menos" || t == "-"
          @neg = true unless @seen
          return true
        end
        return number(t) if t.match?(/\A\d/)
        return word(UNITS[t], 1) if UNITS.key?(t)
        return word(TEENS[t], 2, closes: true) if TEENS.key?(t)
        return word(TENS[t], 2) if TENS.key?(t)
        return word(HUNDREDS[t], 3) if HUNDREDS.key?(t)
        return word(100, 3, closes: true) if t == "cem"
        return scale(SCALES[t]) if SCALES.key?(t)
        return mark_reais if REAIS.include?(t)
        return mark_centavos if CENTAVOS.include?(t)
        return meio if %w[meio meia].include?(t)

        if t == "virgula"
          return false if @mode != :reais || !@seen

          @mode = :decimal
          return true
        end
        true
      end

      def word(v, level, closes: false)
        case @mode
        when :reais
          @seen = true
          if @group.add(v, level, closes:)
            @last_was_scale = false
            return true
          end
          return false if @group.empty?

          @mode = :cents
          @cents.add(v, level, closes:)
        when :cents then @cents.add(v, level, closes:)
        when :decimal
          @decimal_only_digits = false if level != 1
          @decimal << [v, closes ? 2 : level]
          @decimal_digits << v.to_s
          true
        else false
        end
      end

      def number(t)
        n = numeric(t)
        return false if n.nil?

        whole, frac = n
        case @mode
        when :reais
          @seen = true
          if @group.empty?
            @group.set(whole)
            @last_was_scale = false
            if frac
              @cents.set(frac)
              @numeric_frac = frac
            end
            return true
          end
          return false if frac || whole > 99 || !@cents.empty?

          @mode = :cents
          @cents.set(whole)
          true
        when :cents
          return false if frac || whole > 99 || !@cents.empty?

          @cents.set(whole)
          true
        when :decimal
          return false if frac

          @decimal_digits << t
          @decimal << [whole, whole < 10 ? 1 : 2]
          true
        else false
        end
      end

      def scale(s)
        return false if @mode != :reais
        return false if @last_scale && s >= @last_scale

        mult = @group.empty? ? 1 : @group.value
        @total += mult * s
        if @numeric_frac
          @total += @numeric_frac * s / 100
          @numeric_frac = nil
          @cents.reset
        end
        @group.reset
        @last_scale = s
        @last_was_scale = true
        @seen = true
        true
      end

      def mark_reais
        return true unless @seen

        case @mode
        when :reais
          @mode = :cents
          @numeric_frac = nil
          true
        when :decimal
          close_decimal
          @mode = :end
          true
        when :cents then !@numeric_frac.nil? || @cents.empty?
        else true
        end
      end

      def mark_centavos
        return true unless @seen

        case @mode
        when :cents
          @mode = :end
          true
        when :reais
          return false if @numeric_frac

          if @total.positive?
            c = @group.value % 100
            @group.value -= c
            @cents.set(c)
          else
            @raw_cents = @group.value
            @group.reset
          end
          @mode = :end
          true
        else false
        end
      end

      def meio
        case @mode
        when :reais
          if !@seen
            @raw_cents = 50
            @seen = true
          elsif @last_was_scale && @group.empty?
            @total += @last_scale / 2
          else
            return false unless @cents.empty?

            @cents.set(50)
          end
          @mode = :end
          true
        when :cents
          return false unless @cents.empty?

          @cents.set(50)
          @mode = :end
          true
        else false
        end
      end

      def close_decimal
        return true if @decimal.empty?

        if @decimal_only_digits
          @cents.set("#{@decimal_digits}00"[0, 2].to_i)
        else
          g = Group.new
          @decimal.each { |(v, level)| return false unless g.add(v, level, closes: level == 2 && v >= 10 && v < 20) }
          return false if g.value > 99

          @cents.set(g.value)
        end
        @decimal.clear
        true
      end

      def finish
        return nil unless @seen
        return nil if @mode == :decimal && !close_decimal
        return nil if @cents.value > 99

        reais = @total + @group.value
        cents = reais * 100 + @cents.value + (@raw_cents || 0)
        @neg ? -cents : cents
      end
    end
  end

  # v1.13.0: o estado da tela no link do "Continuar no outro aparelho" (par do SsHandoff): JSON compacto em
  # base64url sem "=". O produto serializa (filtros, rascunho); o pacote só leva no link.
  #   ComponentesUi::Handoff.link("https://x/pedidos?pagina=2", { filtros: { status: "aberto" } })
  #   ComponentesUi::Handoff.decode(params[:s]) # => Hash ou nil
  module Handoff
    def self.encode(state) = Base64.urlsafe_encode64(JSON.generate(state), padding: false)

    def self.decode(text)
      return nil if text.blank?

      h = JSON.parse(Base64.urlsafe_decode64(text.to_s + ("=" * ((4 - text.to_s.length % 4) % 4))))
      h.is_a?(Hash) ? h : nil
    rescue ArgumentError, JSON::ParserError
      nil
    end

    def self.link(base, state, param: "s")
      return base.to_s if state.blank?

      "#{base}#{base.to_s.include?("?") ? "&" : "?"}#{param}=#{encode(state)}"
    end
  end
end
