require "test_helper"

# Área segura do celular: com viewport-fit=cover a moldura e o que fica preso na tela respeitam o env(safe-area-inset-*).
class SafeAreaWebTest < ComponentTest
  ROOT = Pathname(ComponentesUi::Engine.root)

  test "engine importa a área segura depois da v0.23" do
    engine = ROOT.join("app/assets/tailwind/componentes_ui/engine.css").read
    assert_operator engine.index(%(@import "./safe_area_web.css";)), :>, engine.index(%(@import "./v23_web.css";))
  end

  test "moldura, toasts, barras e gavetas usam o env() com o espaçamento de sempre como mínimo" do
    css = ROOT.join("app/assets/tailwind/componentes_ui/safe_area_web.css").read
    %w[.ss-shell-top .ss-shell-content .ss-shell-side .ss-toasts .ss-selection-bar .ss-sticky-bar .ss-drawer dialog.ss-drawer-panel].each do |sel|
      assert_includes css, "#{sel} {", sel
    end
    %w[top bottom left right].each { |side| assert_includes css, "env(safe-area-inset-#{side}, 0px)" }
    assert_includes css, "max(clamp(1rem, 3vw, 2rem), env(safe-area-inset-left, 0px))"
  end
end
