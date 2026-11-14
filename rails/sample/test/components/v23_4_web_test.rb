require "test_helper"

# v0.23.4 · ss-reveal: campos que aparecem conforme a escolha de um <select>.
class V234WebTest < ComponentTest
  ROOT = Pathname(ComponentesUi::Engine.root)

  test "controller ss-reveal: source, update e itens só do próprio controller" do
    js = ROOT.join("app/javascript/componentes_ui/controllers/ss_reveal_controller.js").read
    assert_includes js, %(static targets = ["source"])
    assert_includes js, "data-ss-reveal-for"
    assert_includes js, %(closest("[data-controller~='ss-reveal']") === this.element)
    assert_includes js, "el.hidden ="
  end

  test "CSS: item escondido some mesmo com display próprio" do
    assert_includes ROOT.join("app/assets/tailwind/componentes_ui/v23_web.css").read, "[data-ss-reveal-for][hidden] { display: none !important; }"
  end
end
