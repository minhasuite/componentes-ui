require "test_helper"

# v1.5.1 · a entrada mais calma: faixa do produto em tom suave, botão sólido e carimbo na cor do produto (só CSS).
class V151WebTest < ComponentTest
  CSS = Pathname(ComponentesUi::Engine.root).join("app/assets/tailwind/componentes_ui")

  test "faixa suave, botão sólido na entrada e carimbo na cor do produto" do
    engine = CSS.join("engine.css").read
    assert_includes engine, '@import "./v151_web.css";'
    assert engine.index('@import "./v151_web.css";') > engine.index('@import "./v140_web.css";'), "v151 precisa vir depois da v140"
    css = CSS.join("v151_web.css").read
    assert_includes css, ".ss-auth-band { background: var(--accent-soft); color: var(--ink-2); border-top: 3px solid var(--accent); }"
    assert_includes css, ".ss-auth-band strong { color: var(--accent); }"
    assert_includes css, ".ss-auth .ss-btn-primary { background-image: none; background-color: var(--accent-solid); box-shadow: none; }"
    assert_includes css, ".ss-auth .ss-btn-primary::after { display: none; }"
    assert_includes css, ".ss-auth-stamp { border-color: var(--accent); color: var(--accent); }"
    refute_match(/#[0-9a-fA-F]{3,6}\b/, css, "cor só por token")
  end

  test "a marcação da entrada não muda" do
    render_inline(Ss::AuthLayoutComponent.new(product: "Meu Gestor", tagline: "A loja em dia.", title: "Entrar", variant: :wall)) { "" }
    assert_selector "main.ss-auth.is-wall .ss-auth-sheet .ss-auth-band strong", text: "Meu Gestor"
  end
end
