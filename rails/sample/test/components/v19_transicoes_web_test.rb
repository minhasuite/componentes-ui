require "test_helper"

# v1.9 · transições: lista → detalhe (View Transitions), gráficos, rolagem, estados vazios ilustrados
# e a regra de comemoração (par do SsOpenContainer, SsChartTransition, SsIllustrationArt e SsCelebrate).
class V19TransicoesWebTest < ComponentTest
  CSS = Pathname(ComponentesUi::Engine.root).join("app/assets/tailwind/componentes_ui")
  JS = Pathname(ComponentesUi::Engine.root).join("app/javascript/componentes_ui/controllers")

  Pedido = Struct.new(:id) do
    def model_name = ActiveModel::Name.new(self.class, nil, "Pedido")
    def to_param = id.to_s
  end

  test "ss_view_transition_name/attrs e o meta do head" do
    view = vc_test_controller.view_context
    assert_equal "ss-pedido-12-card", view.ss_view_transition_name(Pedido.new(12))
    assert_equal "ss-pedido-12-title", view.ss_view_transition_name(Pedido.new(12), :title)
    assert_equal "ss-cliente-ana-maria-card", view.ss_view_transition_name("Cliente Ana Maria")
    attrs = view.ss_view_transition_attrs(Pedido.new(12))
    assert_equal "view-transition-name: ss-pedido-12-card", attrs[:style]
    assert_equal({ ss_vt: "card" }, attrs[:data])
    assert_equal '<meta name="view-transition" content="same-origin">', view.ss_view_transitions_head
    assert view.ss_view_transitions_head.html_safe?
  end

  test "PageComponent: o cabeçalho leva o nome do card e shrink encolhe ao rolar" do
    render_inline(Ss::PageComponent.new(title: "Pedido 12", view_transition: Pedido.new(12), shrink: true))
    assert_selector ".ss-page.is-shrink > header.ss-page-head[data-ss-vt=card][style='view-transition-name: ss-pedido-12-card'] h1", text: "Pedido 12"

    render_inline(Ss::PageComponent.new(title: "Pedidos"))
    assert_selector "header.ss-page-head:not([style]):not([data-ss-vt])"
    assert_no_selector ".ss-page.is-shrink"
  end

  test "EmptyStateComponent(illustration:): as cinco artes animadas, erro como alerta" do
    %i[empty offline no_results all_done error].each do |ill|
      render_inline(Ss::EmptyStateComponent.new(title: "T", illustration: ill))
      assert_selector ".ss-empty-state[data-illustration='#{ill}'] .ss-empty-art.is-anim[data-illustration='#{ill}'] svg[aria-hidden=true] .ss-ill-symbol"
    end
    assert_selector ".ss-empty-state[role=alert]"
    render_inline(Ss::EmptyStateComponent.new(title: "T", illustration: :all_done))
    assert_no_selector "[role=alert]"
    assert_selector ".ss-ill-check[pathlength='1']"

    # Sem illustration (ou desconhecida), como antes.
    render_inline(Ss::EmptyStateComponent.new(title: "T", variant: :busca, illustration: :xyz))
    assert_selector ".ss-empty-art:not(.is-anim) .ss-ill-lens"
  end

  test "CelebrateComponent: tipo, auto, texto do anúncio e aria-live" do
    render_inline(Ss::CelebrateComponent.new(kind: :goal)) { "R$ 500" }
    assert_selector "div.ss-celebrate.is-goal[data-controller=ss-celebrate][data-ss-celebrate-kind-value=goal][data-ss-celebrate-auto-value=true][data-ss-celebrate-text-value='Meta batida!']", text: "R$ 500"
    assert_selector ".ss-celebrate .ss-sr[aria-live=polite][data-ss-celebrate-target=live]"

    render_inline(Ss::CelebrateComponent.new(kind: :firstUse, achieved: false))
    assert_selector ".ss-celebrate.is-first-use[data-ss-celebrate-kind-value=first_use][data-ss-celebrate-auto-value=false]"

    render_inline(Ss::CelebrateComponent.new(kind: "streak", on: :click, tag_name: :span, css: "x"))
    assert_selector "span.ss-celebrate.is-streak.x[data-ss-celebrate-auto-value=false]"

    assert_raises(ArgumentError) { Ss::CelebrateComponent.new(kind: :birthday) }
  end

  test "ConfettiComponent(kind:) liga a regra de uma por sessão" do
    render_inline(Ss::ConfettiComponent.new(kind: :first_use))
    assert_selector ".ss-confetti[data-ss-confetti-kind-value=first_use]", visible: :all
    render_inline(Ss::ConfettiComponent.new)
    assert_no_selector "[data-ss-confetti-kind-value]", visible: :all
  end

  test "inglês e espanhol" do
    I18n.with_locale(:en) do
      render_inline(Ss::CelebrateComponent.new(kind: :streak))
      assert_selector "[data-ss-celebrate-text-value='Streak kept!']"
    end
    I18n.with_locale(:es) do
      render_inline(Ss::CelebrateComponent.new(kind: :first_use))
      assert_selector "[data-ss-celebrate-text-value='¡Primer paso dado!']"
    end
  end

  test "JS: sessionStorage por tipo e o confete importado" do
    js = JS.join("ss_celebrate_controller.js").read
    assert_includes js, 'from "componentes_ui/controllers/ss_confetti_controller"'
    assert_includes js, "prefers-reduced-motion"
    confete = JS.join("ss_confetti_controller.js").read
    assert_includes confete, "export function ssCelebrationClaim"
    assert_includes confete, "sessionStorage"
    assert_includes confete, "ss-celebrate:${kind}"
  end

  test "CSS: view transitions, gráficos, rolagem com @supports, só tokens e sem movimento quando pedem" do
    css = CSS.join("v19_transicoes.css").read
    assert_includes css, '[data-ss-vt="card"] { view-transition-class: ss-card; }'
    assert_includes css, "::view-transition-group(*.ss-card)"
    assert_includes css, "@supports (animation-timeline: scroll())"
    assert_includes css, "@supports (animation-timeline: view())"
    assert_includes css, "transition: d .52s"
    assert_includes css, "stroke-dasharray .52s"
    assert_includes css, "ss-donut-turn"
    assert_includes css, "prefers-reduced-motion: reduce"
    assert_no_match(/#[0-9a-f]{3,6}\b/i, css)
    assert_includes CSS.join("engine.css").read, '@import "./v19_transicoes.css";'
  end
end
