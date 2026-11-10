module Ss
  # Nota (v0.14, par do SsNote): a frase curta e apagada no lugar do conteúdo de um card ou de uma
  # seção ("Nenhum alerta aberto", "Escolha o medidor", "Sem leituras"), com ícone opcional. Não é o
  # estado vazio ilustrado (EmptyStateComponent): é uma linha.
  #
  #   render Ss::NoteComponent.new(text: "Nenhum alerta aberto", icon: svg, tone: :success)
  #   render(Ss::NoteComponent.new(icon: svg, tone: :danger)) { "O robô parou: #{erro}" }
  #
  # tone: :muted (padrão), :accent, :success, :warn, :danger. O tom pinta o ícone; :warn e :danger
  # pintam a frase também e viram role="status" (é aviso). Sem margem: o contêiner põe (css: "mt-2").
  class NoteComponent < BaseComponent
    TONES = %i[muted accent success warn danger].freeze

    def initialize(text: nil, icon: nil, tone: :muted, **rest)
      super(**rest)
      @text, @icon = text, icon
      tone = ComponentesUi.tone(tone)
      @tone = TONES.include?(tone) ? tone : :muted
    end

    def call
      alert = %i[warn danger].include?(@tone)
      tag.p(**root_attrs(class: classes("ss-note"), data: ({ tone: @tone } unless @tone == :muted), role: ("status" if alert))) do
        safe_join([(tag.span(@icon.to_s.html_safe, class: "ss-note-ico", "aria-hidden": "true") if @icon.present?),
                   tag.span(content.presence || @text)].compact)
      end
    end
  end
end
