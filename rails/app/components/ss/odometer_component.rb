module Ss
  # Número que rola por dígito (v1.9, par do SsOdometer): cada dígito é uma coluna 0–9 que gira até o novo e
  # assenta com mola, subindo quando o valor aumentou e descendo quando caiu, em cascata da direita para a
  # esquerda (35 ms entre as casas). Vírgula, ponto e "R$" ficam parados; casa nova entra com fade; os centavos
  # ficam menores, como no ss_amount. O Ss::CountUpComponent continua sendo o "conta de 0 até o valor".
  #
  #   render Ss::OdometerComponent.new(text: ss_money(total))
  #   render Ss::OdometerComponent.new(text: "214", size: "2.5rem", roll_in: true)
  #
  # Trocar o texto (morph do Turbo, ou JS em data-ss-odometer-text-value) rola. roll_in: parte do 0 quando entra
  # na tela. size: tamanho da fonte (CSS; padrão 2rem). Leitor de tela: o texto inteiro, avisado ao mudar.
  # Reduzir movimento: troca sem rolar.
  class OdometerComponent < BaseComponent
    attr_reader :text

    def initialize(text:, size: nil, roll_in: false, cents: true, **rest)
      super(**rest)
      @text, @size, @roll_in, @cents = text.to_s, size, roll_in, cents
    end

    # [principal, centavos] como no ss_amount ("R$ 1.234,56" → ["R$ 1.234", ",56"]).
    def parts
      return [text, ""] unless @cents

      sep = Regexp.escape(ss_t("number.separator", locale: ss_number_locale, default: ","))
      m = text.match(/\A(.*?)(#{sep}\d{2})(\s*[^\d\s][^\d]*)?\z/m)
      m ? [m[1] + m[3].to_s, m[2]] : [text, ""]
    end

    def call
      main, cents = parts
      size = @size.is_a?(Numeric) ? "#{@size}px" : @size
      data = { controller: "ss-odometer", ss_odometer_text_value: text, ss_odometer_roll_in_value: (@roll_in || nil),
               ss_odometer_separator_value: ss_t("number.separator", locale: ss_number_locale, default: ",") }.compact
      digits = (main + cents).count("0-9")
      k = digits
      cols = lambda do |str|
        safe_join(str.chars.map do |ch|
          next tag.span(ch, class: "ss-odo-ch") unless ch.match?(/\d/)

          k -= 1
          tag.span(tag.span("0123456789" * 3, class: "ss-odo-reel"), class: "ss-odo-col", style: "--pos:#{10 + ch.to_i};--k:#{k}")
        end)
      end
      tag.span(**root_attrs(class: classes("ss-odo"), style: (size && "--ss-odo-size:#{ERB::Util.h(size)}"), data:)) do
        safe_join([
          tag.span(text, class: "ss-sr", "aria-live": "polite", data: { ss_odometer_target: "sr" }),
          tag.span(safe_join([cols.call(main), (tag.small(cols.call(cents), class: "ss-odo-cents") if cents.present?)].compact),
                   class: "ss-odo-n num", "aria-hidden": "true", data: { ss_odometer_target: "out" })
        ])
      end
    end
  end
end
