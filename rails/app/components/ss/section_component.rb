module Ss
  # Título de seção em versalete (v0.13, par do SsSection): o .ss-section com ícone opcional
  # antes do texto e uma ação à direita (link "Ver tudo", botão). Abre um grupo de cards ou de
  # linhas; para um título maior, com linha de explicação, use o SectionHeaderComponent.
  #
  #   render Ss::SectionComponent.new(title: "Sala", icon: svg)
  #   render(Ss::SectionComponent.new(title: "Avisos", heading: :h3)) { |s| s.with_action { link_to "Ver tudo", avisos_path } }
  #
  # heading: a tag do título (padrão :h2; :h3/:h4/:p dentro de um card ou de outra seção).
  class SectionComponent < BaseComponent
    HEADINGS = %i[h2 h3 h4 p span].freeze

    renders_one :action

    def initialize(title:, icon: nil, heading: :h2, **rest)
      super(**rest)
      @title, @icon = title, icon
      @heading = HEADINGS.include?(heading.to_s.to_sym) ? heading.to_s.to_sym : :h2
    end

    def call
      tag.div(**root_attrs(class: classes("ss-section-row"))) do
        safe_join([
          content_tag(@heading, class: "ss-section") do
            safe_join([(tag.span(@icon.to_s.html_safe, class: "ss-section-ico", "aria-hidden": "true") if @icon.present?),
                       tag.span(@title, class: "ss-section-text")].compact)
          end,
          (tag.div(action, class: "ss-section-action") if action?)
        ].compact)
      end
    end
  end
end
