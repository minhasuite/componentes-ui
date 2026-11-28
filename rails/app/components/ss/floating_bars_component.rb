module Ss
  # Barras verticais grandes num card na cor da marca (v1.10, par do SsFloatingBars): as outras translúcidas e a
  # escolhida cheia (--on-accent) com o valor numa etiqueta em cima. Clicar escolhe. title: e value: no topo.
  # Cada barra sobe com a mola, uma depois da outra, quando o card entra na tela.
  #
  #   render Ss::FloatingBarsComponent.new(title: "Gastos", value: ss_money(1820), values: [320, 410, 280, 520, 290],
  #                                         labels: %w[Jul Ago Set Out Nov], format: :money)
  #
  # selected: índice (padrão: o último). format: :qty (padrão), :money, :integer, um lambda ou um Kernel.format.
  # height: px do card (260). Cada barra é um <button aria-pressed> "Out: R$ 520,00"; com href: (um "…%{index}"),
  # vira link. Evento ss-floating-bars:change { index }. Reduzir movimento: as barras já aparecem.
  # v1.14.7: tudo zero mostra o texto do vazio no lugar das barras (empty:, ou "Sem dados no período");
  # treat_zero_as_empty: false desenha as barras no mínimo.
  class FloatingBarsComponent < BaseComponent
    include InView

    def initialize(values:, labels:, selected: nil, format: :qty, title: nil, value: nil, height: 260, href: nil, empty: nil,
                   treat_zero_as_empty: true, **rest)
      super(**rest)
      @empty = empty
      @treat_zero_as_empty = treat_zero_as_empty
      @values = Array(values).map(&:to_f)
      @labels = Array(labels).map(&:to_s)
      raise ArgumentError, "Ss::FloatingBarsComponent: values: e labels: com o mesmo tamanho" unless @values.size == @labels.size

      @selected = (selected || @values.size - 1).to_i.clamp(0, [@values.size - 1, 0].max)
      @format, @title, @value, @href = format, title, value, href
      @height = height.to_i.clamp(140, 640)
    end

    def fmt(v)
      case @format
      when Proc then @format.call(v)
      when :money then ss_money(v)
      when :integer then ss_number(v.round)
      when String then Kernel.format(@format, v)
      else ss_qty(v)
      end
    end

    def call
      hi = @values.max.to_f
      tag.div(**root_attrs(class: classes("ss-fbars"), style: "--h:#{@height}px",
                           data: in_view_data(controller: "ss-in-view ss-floating-bars"))) do
        safe_join([
          ((@title || @value) ? tag.div(class: "ss-fbars-head") { safe_join([(tag.span(@title, class: "ss-fbars-title") if @title), (tag.span(@value, class: "ss-fbars-total num") if @value)].compact) } : nil),
          if zero?
            tag.p(@empty || ss_t("chart.empty", default: "Sem dados no período"), class: "ss-fbars-empty")
          else
            tag.div(class: "ss-fbars-row", role: "group", "aria-label": @title) do
              safe_join(@values.each_with_index.map { |v, i| bar(v, i, hi) })
            end
          end
        ].compact)
      end
    end

    def zero? = @treat_zero_as_empty && @values.any? && ComponentesUi::ChartScale.all_zero?(@values)

    private

    def bar(v, i, hi)
      on = i == @selected
      f = hi.positive? ? (v / hi).clamp(0.0, 1.0) : 0.0
      body = safe_join([
        tag.span(class: "ss-fbars-slot", "aria-hidden": "true") do
          tag.span(tag.span(fmt(v), class: "ss-fbars-tag num"), class: "ss-fbars-bar", style: "--f:#{f.round(4)}")
        end,
        tag.span(@labels[i], class: "ss-fbars-label", "aria-hidden": "true")
      ])
      attrs = { class: ["ss-fbars-item", ("is-on" if on)].compact.join(" "), style: "--i:#{[i, 12].min}", "aria-label": "#{@labels[i]}: #{fmt(v)}",
                data: { ss_floating_bars_target: "bar", index: i, action: "ss-floating-bars#pick" } }
      if @href
        link_to(body, Kernel.format(@href, index: i), **attrs, "aria-current": (on ? "true" : nil))
      else
        tag.button(body, **attrs, type: :button, "aria-pressed": on.to_s)
      end
    end
  end
end
