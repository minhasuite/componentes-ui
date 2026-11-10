module Ss
  # Linha de progresso (v0.15, par do SsProgressRow): rótulo, "gasto de limite", % e a barra no
  # tom do estado. Orçamento por categoria, limite do cartão, meta de economia.
  #
  #   render Ss::ProgressRowComponent.new(label: "Mercado", value: 720, limit: 1000, format: ->(v) { ss_money(v) })
  #   render Ss::ProgressRowComponent.new(label: "Viagem", value: 3000, limit: 3000, kind: :goal, icon: ss_icon("globe-alt", size: nil))
  #
  # kind: :limit (padrão: até warn_at, 0,8, fica na marca ou em color:; dali até 100% aviso;
  # passou de 100% estouro, em vermelho, "R$ 120 acima") ou :goal (100% é sucesso, verde, "Meta
  # batida"). caption: troca o texto da direita embaixo. href: a linha vira link.
  class ProgressRowComponent < BaseComponent
    KINDS = %i[limit goal].freeze

    def initialize(label:, value:, limit:, kind: :limit, format: nil, icon: nil, caption: nil, href: nil, warn_at: 0.8, color: nil, **rest)
      super(**rest)
      @label, @value, @limit = label, value.to_f, limit.to_f
      @kind = KINDS.include?(kind.to_s.to_sym) ? kind.to_s.to_sym : :limit
      @format, @icon, @caption, @href, @warn_at, @color = format, icon, caption, href, warn_at.to_f, color
    end

    def ratio
      return(@value.positive? ? Float::INFINITY : 0.0) unless @limit.positive?

      [@value / @limit, 0.0].max
    end

    # ok | warn | over | done
    def tone
      r = ratio
      return(r >= 1 ? :done : :ok) if @kind == :goal
      return :over if r > 1
      return :warn if r >= @warn_at

      :ok
    end

    def pct = ratio.infinite? ? 100 : (ratio * 100).round
    def width = ([ratio, 1.0].min * 100).round(2)

    def fmt(v)
      return @format.call(v) if @format

      ss_number(v, precision: v % 1 == 0 ? 0 : 2)
    end

    def spent = ss_t("progress_row.of", default: "%{value} de %{limit}", value: fmt(@value), limit: fmt(@limit))

    def caption
      return @caption if @caption

      rest = (@limit - @value).abs
      case tone
      when :over then ss_t("progress_row.over", default: "%{value} acima", value: fmt(rest))
      when :done then ss_t("progress_row.done", default: "Meta batida")
      else @kind == :goal ? ss_t("progress_row.to_go", default: "Faltam %{value}", value: fmt(rest)) : ss_t("progress_row.left", default: "Restam %{value}", value: fmt(rest))
      end
    end

    def call
      head = tag.div(class: "ss-progress-row-head") do
        safe_join([tag.span(safe_join([(tag.span(@icon.to_s.html_safe, class: "ss-progress-row-ico", "aria-hidden": "true") if @icon.present?),
                                       tag.span(@label)].compact), class: "ss-progress-row-label"),
                   tag.span("#{pct}%", class: "ss-progress-row-pct num")])
      end
      bar = tag.div(class: "ss-progress", role: "progressbar", "aria-label": @label, "aria-valuemin": 0, "aria-valuemax": 100,
                    "aria-valuenow": [pct, 100].min, "aria-valuetext": "#{pct}% · #{spent}") do
        tag.div(class: "ss-progress-bar", style: "width:#{width}%#{";background:#{@color}" if @color && tone == :ok}")
      end
      foot = tag.div(class: "ss-progress-row-foot") { safe_join([tag.span(spent, class: "money num"), tag.span(caption)]) }
      attrs = root_attrs(class: classes("ss-progress-row", ("is-link" if @href)), data: { tone: tone, kind: @kind })
      body = safe_join([head, bar, foot])
      @href ? tag.a(body, href: @href, **attrs) : tag.div(body, **attrs)
    end
  end
end
