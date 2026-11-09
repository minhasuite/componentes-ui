module Ss
  # Cabeçalho de bloco (v0.13, par do SsSectionHeader): título maior (1,15rem / 800) com ícone
  # tonal opcional, uma linha de explicação embaixo e a ação à direita. É o título que separa
  # partes de uma tela (um bloco de cards, um texto); o de dentro do card é o CardHeaderComponent
  # e o rótulo em versalete é o SectionComponent.
  #
  #   render Ss::SectionHeaderComponent.new(title: "Andar de cima", subtitle: "3 cômodos", icon: svg)
  #   render(Ss::SectionHeaderComponent.new(title: "Cenas")) { |h| h.with_action { link_to "Nova", nova_path, class: "ss-btn ss-btn-sm" } }
  #
  # heading: a tag do título (padrão :h2). icon: svg (o componente dimensiona), na cor da marca.
  class SectionHeaderComponent < BaseComponent
    HEADINGS = %i[h1 h2 h3 h4 p].freeze

    renders_one :action

    def initialize(title:, subtitle: nil, icon: nil, heading: :h2, **rest)
      super(**rest)
      @title, @subtitle, @icon = title, subtitle, icon
      @heading = HEADINGS.include?(heading.to_s.to_sym) ? heading.to_s.to_sym : :h2
    end

    def call
      tag.div(**root_attrs(class: classes("ss-section-head"))) do
        safe_join([
          (tag.span(@icon.to_s.html_safe, class: "ss-section-head-ico", "aria-hidden": "true") if @icon.present?),
          tag.div(class: "ss-section-head-text") do
            safe_join([content_tag(@heading, @title, class: "ss-section-head-title"),
                       (tag.p(@subtitle, class: "ss-section-head-sub") if @subtitle.present?)].compact)
          end,
          (tag.div(action, class: "ss-section-head-action") if action?)
        ].compact)
      end
    end
  end
end
