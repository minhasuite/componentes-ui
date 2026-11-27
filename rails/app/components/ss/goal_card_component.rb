module Ss
  # Card de meta/convite (v1.10, par do SsGoalCard): ilustração (ou ícone grande num brilho da marca) em cima,
  # texto curto centrado e uma ação em texto sublinhado na cor da marca ("Criar meta"). Quando entra na tela, a
  # arte brota com a mola e o sublinhado se desenha do meio para as pontas, depois da arte.
  #
  #   render Ss::GoalCardComponent.new(text: "Junte para a viagem de julho.", action_label: "Criar meta", href: new_meta_path)
  #   render(Ss::GoalCardComponent.new(text: "…", action_label: "Começar")) { |c| c.with_art { render Ss::IllustrationArtComponent.new(:empty, size: 96) } }
  #
  # href: a ação é link; sem href, <button type=button> (data:/form: vão no action_data:). icon: ss_icon
  # quando não há with_art ("flag"). Reduzir movimento: já aparece pronto.
  class GoalCardComponent < BaseComponent
    include InView
    renders_one :art

    def initialize(text:, action_label:, href: nil, icon: "flag", action_data: {}, **rest)
      super(**rest)
      @text, @action_label, @href, @icon, @action_data = text, action_label, href, icon, action_data
    end

    def call
      tag.div(**root_attrs(class: classes("ss-goal"), data: in_view_data)) do
        safe_join([
          tag.div(art? ? art : ss_icon(@icon, size: nil, css: "ss-goal-ico"), class: "ss-goal-art", "aria-hidden": (art? ? nil : "true")),
          tag.p(@text, class: "ss-goal-text"),
          action
        ])
      end
    end

    private

    def action
      label = safe_join([tag.span(@action_label), tag.span(class: "ss-goal-line", "aria-hidden": "true")])
      return link_to(label, @href, class: "ss-goal-action") if @href

      tag.button(label, type: :button, class: "ss-goal-action", data: @action_data)
    end
  end
end
