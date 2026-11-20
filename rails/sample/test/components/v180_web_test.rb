require "test_helper"

# v1.8 · cartão de conquista: Ss::AchievementCardComponent (par do SsAchievementCard).
class V180WebTest < ComponentTest
  CSS = Pathname(ComponentesUi::Engine.root).join("app/assets/tailwind/componentes_ui")

  test "conquistada: medalhão, título com o nome para o leitor, a regra e o selo com a data" do
    render_inline(Ss::AchievementCardComponent.new(title: "Primeiro turno coberto", description: "Cobriu um turno aberto da escala.",
                                                   earned: true, caption: "em 12/11"))
    assert_selector "article.ss-card.ss-achievement.is-earned"
    assert_selector ".ss-achievement-medal[aria-hidden=true] svg.ss-icon[data-icon=badge-check]"
    assert_selector "h3.ss-achievement-title", text: "Conquista: Primeiro turno coberto"
    assert_selector "h3.ss-achievement-title .ss-sr", text: "Conquista:"
    assert_selector "p.ss-achievement-text", text: "Cobriu um turno aberto da escala."
    assert_selector ".ss-achievement-foot .ss-badge.ss-badge-accent.ss-achievement-seal", text: "Conquistada"
    assert_selector ".ss-achievement-foot .ss-achievement-caption", text: "em 12/11"
    assert_no_selector "[role=progressbar]"
  end

  test "em andamento: barra com role progressbar e o que falta; sem progresso, sem rodapé" do
    render_inline(Ss::AchievementCardComponent.new(title: "30 dias seguidos", description: "Sequência de 30 dias.", icon: "fire",
                                                   progress: 12 / 30.0, progress_label: "12 de 30 dias"))
    assert_selector "article.ss-achievement.is-locked .ss-achievement-medal svg[data-icon=fire]"
    assert_selector ".ss-achievement-progress .ss-progress[role=progressbar][aria-valuenow='40'][aria-valuemin='0'][aria-valuemax='100'][aria-label='Falta: 12 de 30 dias'] .ss-progress-bar[style='width:40%']"
    assert_selector ".ss-achievement-progress small", text: "12 de 30 dias"
    assert_no_selector ".ss-achievement-seal"

    render_inline(Ss::AchievementCardComponent.new(title: "100 no prazo", description: "Conclua 100 checklists.", progress: 3))
    assert_selector ".ss-progress[aria-valuenow='100'][aria-label='100 no prazo']"

    render_inline(Ss::AchievementCardComponent.new(title: "Sem nada", description: "Regra."))
    assert_selector "article.ss-achievement.is-locked"
    assert_no_selector ".ss-achievement-progress"
    assert_no_selector ".ss-achievement-foot"
  end

  test "href vira link e css/atributos extras passam" do
    render_inline(Ss::AchievementCardComponent.new(title: "T", description: "D", href: "/conquistas/1", css: "x", id: "c1"))
    assert_selector "a.ss-card.ss-achievement.x#c1[href='/conquistas/1'] h3", text: "T"
  end

  test "inglês e espanhol" do
    I18n.with_locale(:en) do
      render_inline(Ss::AchievementCardComponent.new(title: "T", description: "D", earned: true))
      assert_selector ".ss-achievement-seal", text: "Earned"
      assert_selector ".ss-sr", text: "Achievement:"
    end
    I18n.with_locale(:es) do
      render_inline(Ss::AchievementCardComponent.new(title: "T", description: "D", progress: 0.5, progress_label: "1 de 2"))
      assert_selector ".ss-progress[aria-label='Falta: 1 de 2']"
    end
  end

  test "CSS: grade auto-fill, só tokens e sem movimento quando pedem" do
    css = CSS.join("v180_conquista_web.css").read
    assert_includes css, "repeat(auto-fill, minmax(min(14rem, 100%), 1fr))"
    assert_includes css, "prefers-reduced-motion"
    assert_no_match(/#[0-9a-f]{3,6}\b/i, css)
    assert_includes CSS.join("engine.css").read, '@import "./v180_conquista_web.css";'
  end
end
