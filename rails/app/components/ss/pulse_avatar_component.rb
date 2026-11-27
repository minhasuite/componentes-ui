module Ss
  # Avatar com ondas concêntricas pulsando enquanto active: (v1.10, par do SsPulseAvatar): "IA ouvindo",
  # "chamando", "sincronizando". Inativo, as ondas somem; com "reduzir movimento", ficam dois anéis parados.
  #
  #   render Ss::PulseAvatarComponent.new(name: "Ana Souza", status: "chamando")
  #   render Ss::PulseAvatarComponent.new(name: "Assistente", status: "ouvindo", tone: :success) { ss_icon("sparkles") }
  #
  # size: diâmetro do avatar em px (72); a peça ocupa o dobro (o espaço das ondas). tone: :accent | :success |
  # :warn | :danger. O bloco troca o avatar (ícone da IA). Leitor de tela: "Ana Souza, chamando", avisado ao
  # mudar (role=status). Trocar active: no morph do Turbo liga e desliga as ondas.
  class PulseAvatarComponent < BaseComponent
    TONES = %i[accent success warn danger].freeze

    def initialize(name: nil, active: true, size: 72, tone: :accent, status: nil, **rest)
      super(**rest)
      @name, @active, @status = name, active, status
      @size = size.to_i.clamp(24, 240)
      @tone = TONES.include?(tone&.to_sym) ? tone.to_sym : :accent
    end

    def label = [@name, @status].compact.reject { |s| s.to_s.empty? }.join(", ")

    def call
      tag.span(**root_attrs(class: classes("ss-pulse", ("is-active" if @active)), style: "--s:#{@size}px", data: { tone: @tone })) do
        safe_join([
          tag.span(class: "ss-pulse-waves", "aria-hidden": "true") { safe_join(3.times.map { |k| tag.i(style: "--n:#{k}") }) },
          tag.span(class: "ss-pulse-face", "aria-hidden": "true") { content.presence || ss_avatar(@name.to_s, size: @size) },
          tag.span(label, class: "ss-sr", role: "status")
        ])
      end
    end
  end
end
