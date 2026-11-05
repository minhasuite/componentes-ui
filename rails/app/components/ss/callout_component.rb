module Ss
  # Aviso em linha dentro da tela (v0.10.2, par do SsCallout): não some sozinho. tone: :info
  # (padrão), :accent, :success, :warn ou :danger; ícone padrão por tom (icon: false tira,
  # icon: "<svg…>" troca); title: em negrito; o bloco é o corpo (texto, <ul>); with_action
  # põe botões embaixo. warn e danger viram role=alert, o resto role=status.
  #
  #   render(Ss::CalloutComponent.new(tone: :warn, title: "Faltam campos")) { tag.ul { … } }
  class CalloutComponent < BaseComponent
    TONES = %i[info accent success warn danger].freeze
    ICONS = {
      info: %(<path stroke-linecap="round" d="M12 8h.01M11 12h1v4h1"/><circle cx="12" cy="12" r="9"/>),
      accent: %(<path stroke-linecap="round" stroke-linejoin="round" d="M12 3l1.9 4.6L18.5 9l-4.6 1.9L12 15.5l-1.9-4.6L5.5 9l4.6-1.4L12 3zM18 15l.8 2.2L21 18l-2.2.8L18 21l-.8-2.2L15 18l2.2-.8L18 15z"/>),
      success: %(<circle cx="12" cy="12" r="9"/><path stroke-linecap="round" stroke-linejoin="round" d="M8 12.5l2.5 2.5L16 9.5"/>),
      warn: %(<path stroke-linejoin="round" d="M10.3 4.3 2.8 17.5A2 2 0 0 0 4.5 20.5h15a2 2 0 0 0 1.7-3L13.7 4.3a2 2 0 0 0-3.4 0z"/><path stroke-linecap="round" d="M12 10v4M12 17h.01"/>),
      danger: %(<circle cx="12" cy="12" r="9"/><path stroke-linecap="round" d="M12 7.5v5.5M12 16.5h.01"/>)
    }.freeze

    renders_many :actions

    def initialize(tone: :info, title: nil, icon: true, **opts)
      super(**opts)
      @tone = TONES.include?(tone.to_s.to_sym) ? tone.to_s.to_sym : :info
      @title, @icon = title, icon
    end

    def icon_html
      return "".html_safe if @icon == false
      return @icon.to_s.html_safe unless @icon == true

      %(<svg class="ss-callout-ico" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">#{ICONS[@tone]}</svg>).html_safe
    end

    def call
      role = %i[warn danger].include?(@tone) ? "alert" : "status"
      tag.div(**root_attrs(class: classes("ss-callout"), "data-tone": @tone, role:)) do
        safe_join([icon_html, tag.div(class: "ss-callout-body") do
          safe_join([(tag.p(@title, class: "ss-callout-title") if @title), (content if content.present?),
                     (tag.div(safe_join(actions), class: "ss-callout-actions") if actions?)].compact)
        end])
      end
    end
  end
end
