module Ss
  # Insight da IA: selo "IA", borda viva na cor da marca (gira devagar; para com menos
  # movimento), texto, fontes/evidências recolhíveis, ações Aplicar/Ignorar e o estado
  # "pensando" (thinking: true) com .ss-thinking enquanto a resposta não chega.
  #   render Ss::AiInsightCardComponent.new(title: "Gasto com mercado subiu 18%",
  #     sources: [{ label: "42 lançamentos de out", url: "…" }], confidence: "alta",
  #     apply: { label: "Criar meta de R$ 900", url: metas_path, method: :post }, dismiss: { url: ignorar_path, method: :post }) do
  #     Texto do insight (pode ter <b>, links…)
  #   end
  class AiInsightCardComponent < BaseComponent
    SPARK = %(<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 2.5l2 5.5 5.5 2-5.5 2-2 5.5-2-5.5L4.5 10 10 8zM19 15l.9 2.1L22 18l-2.1.9L19 21l-.9-2.1L16 18l2.1-.9z" fill="currentColor"/></svg>).freeze

    attr_reader :title, :sources, :apply, :dismiss, :confidence, :when_text

    def initialize(title: nil, text: nil, sources: [], apply: nil, dismiss: nil, thinking: false, confidence: nil, when_text: nil, thinking_text: "Analisando seus dados…", **opts)
      super(**opts)
      @title = title
      @text = text
      @sources = sources
      @apply = apply
      @dismiss = dismiss
      @thinking = thinking
      @confidence = confidence
      @when_text = when_text
      @thinking_text = thinking_text
    end

    def thinking? = @thinking
    def body = content.presence || @text
    attr_reader :thinking_text
    def spark = SPARK.html_safe

    def action(a, css, default_label)
      label = a[:label] || default_label
      if a[:method] && a[:method].to_s != "get"
        button_to(label, a[:url], method: a[:method], class: css, form: { class: "ss-ai-form" })
      else
        link_to(label, a[:url], class: css)
      end
    end
  end
end
