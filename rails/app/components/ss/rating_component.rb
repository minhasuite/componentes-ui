module Ss
  # Estrelas (v0.16, par do SsRating). Leitura: o .ss-stars (aceita meia, "4,5"). Com name:, vira
  # campo do formulário: um rádio por estrela (1..max), sem JS, setas do teclado trocam a nota e o
  # hover acende até a estrela sob o mouse.
  #
  #   render Ss::RatingComponent.new(value: 4.5)
  #   render Ss::RatingComponent.new(name: "review[rating]", value: @review.rating, label: "Sua nota")
  #
  # max: 5 (padrão); label: nome do campo para o leitor de tela (padrão rating.field "Nota");
  # size: :sm (1rem), :md (1.2rem, padrão), :lg (2rem).
  class RatingComponent < BaseComponent
    SIZES = { sm: "1rem", md: "1.2rem", lg: "2rem" }.freeze
    STAR = %(<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 2.5l2.9 6 6.6.8-4.9 4.6 1.3 6.6L12 17.3l-5.9 3.2 1.3-6.6L2.5 9.3l6.6-.8z"/></svg>).freeze

    def initialize(value: 0, max: 5, name: nil, label: nil, size: :md, id: nil, **rest)
      super(**rest)
      @max = [max.to_i, 1].max
      @value = value.to_f.clamp(0, @max)
      @name, @label = name, label
      @size = SIZES[size.to_s.to_sym] || SIZES[:md]
      @id = id || "ss-rating-#{SecureRandom.hex(3)}"
    end

    def rating_text
      v = ss_number(@value, precision: (@value % 1).zero? ? 0 : 1)
      ss_t("rating.label", default: "Nota %{rating} de %{max}", rating: v, max: @max)
    end

    def star_text(n)
      n == 1 ? ss_t("rating.star_one", default: "1 estrela") : ss_t("rating.star_other", default: "%{n} estrelas", n:)
    end

    def call
      style = "--v: #{@value.round(2)}; --max: #{@max}; --star-size: #{@size}"
      return tag.span(**root_attrs(class: classes("ss-stars"), style:, role: "img", "aria-label": rating_text)) unless @name

      checked = @value.round
      tag.fieldset(**root_attrs(class: classes("ss-rating"), style: "--star-size: #{@size}")) do
        safe_join([tag.legend(@label || ss_t("rating.field", default: "Nota"), class: "ss-sr"),
                   *(1..@max).map do |n|
                     safe_join([tag.input(type: "radio", name: @name, value: n, id: "#{@id}-#{n}", checked: n == checked),
                                tag.label(for: "#{@id}-#{n}", title: star_text(n)) { safe_join([STAR.html_safe, tag.span(star_text(n), class: "ss-sr")]) }])
                   end])
      end
    end
  end
end
