module Ss
  # Cabeçalho de card (v0.12, par do SsCardHeader): título na tipografia padrão de card
  # (.ss-card-title), linha menor embaixo (.ss-card-sub: período, total) e, à direita, o ícone
  # tonal pequeno ou o que vier no slot action (botão, menu). Mesma cara em todos os cards.
  #
  #   render Ss::CardHeaderComponent.new(title: "Consumo por aparelho", subtitle: "Mês · 401,5 kWh",
  #                                      icon: svg, tone: :warn)
  #   render(Ss::CardHeaderComponent.new(title: "Agenda")) { |h| h.with_action { link_to "Ver tudo", agenda_path } }
  #
  # tone: :accent (padrão), :success, :warn, :danger, :info, :muted, :heat (âmbar de energia/luz, o
  # mesmo do DeviceTile) ou uma cor CSS simples.
  # heading: a tag do título (padrão :p; :h2/:h3 quando o card é uma seção da página).
  class CardHeaderComponent < BaseComponent
    TONES = { accent: "var(--accent)", success: "var(--success)", warn: "var(--warn)", danger: "var(--danger)",
              info: "var(--ss-info)", muted: "var(--muted)", heat: "#e0952a" }.freeze

    renders_one :action

    def initialize(title:, subtitle: nil, icon: nil, tone: nil, heading: :p, **rest)
      super(**rest)
      @title, @subtitle, @icon, @tone = title, subtitle, icon, tone
      @heading = %i[p h2 h3 h4 span].include?(heading.to_s.to_sym) ? heading.to_s.to_sym : :p
    end

    def self.tone_css(tone)
      return nil if tone.nil?
      return TONES[tone.to_sym] if TONES.key?(tone.to_s.to_sym)

      tone.to_s if tone.to_s.match?(/\A[#\w\s(),.%-]+\z/)
    end

    def call
      tone = self.class.tone_css(@tone)
      tag.div(**root_attrs(class: classes("ss-card-head"))) do
        safe_join([
          tag.div(class: "ss-card-head-text") do
            safe_join([content_tag(@heading, @title, class: "ss-card-title"),
                       (tag.p(@subtitle, class: "ss-card-sub") if @subtitle.present?)].compact)
          end,
          (action? ? tag.div(action, class: "ss-card-head-action") : nil),
          (if !action? && @icon.present?
             tag.span(@icon.to_s.html_safe, class: "ss-card-head-icon", style: ("--tone: #{tone}" if tone), "aria-hidden": "true")
           end)
        ].compact)
      end
    end
  end
end
