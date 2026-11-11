require "test_helper"

# v0.21 · micro-animações da casa (ss-cue ↔ SsCue) e brilho real no tile (level: ↔ SsDeviceTile(level:)).
class V21WebTest < ComponentTest
  CSS = Pathname(ComponentesUi::Engine.root).join("app/assets/tailwind/componentes_ui")
  JS = Pathname(ComponentesUi::Engine.root).join("app/javascript/componentes_ui/controllers")
  include ComponentesUi::Helpers

  test "DeviceTileComponent(level:) põe --ss-level e has-level, preso entre 0 e 1" do
    render_inline(Ss::DeviceTileComponent.new(name: "Abajur", on: true, tone: "#ffaa5a", level: 0.25))
    assert_selector ".ss-device.is-on.has-level[style*='--ss-level: 0.25'][style*='--tone: #ffaa5a']"
    render_inline(Ss::DeviceTileComponent.new(name: "Abajur", on: true, level: 3))
    assert_selector ".ss-device.has-level[style*='--ss-level: 1.0']"
    render_inline(Ss::DeviceTileComponent.new(name: "Abajur", on: true, level: "x"))
    assert_no_selector ".ss-device.has-level"
    render_inline(Ss::DeviceTileComponent.new(name: "Abajur"))
    assert_no_selector ".ss-device[style]"
  end

  test "ss_cue_data: controller, tipo, estado e chave; tipo desconhecido vira on" do
    d = ss_cue_data(kind: :open, active: true, key: "w1-p2")
    assert_equal({ controller: "ss-cue", ss_cue_kind_value: "open", ss_cue_active_value: "true", ss_cue_key_value: "w1-p2" }, d)
    assert_equal "on", ss_cue_data(kind: :x, active: false)[:ss_cue_kind_value]
    assert_equal "false", ss_cue_data(kind: :arrive, active: nil)[:ss_cue_active_value]
    refute ss_cue_data(kind: :on, active: true).key?(:ss_cue_key_value)
  end

  test "CSS e Stimulus da v0.21: três acenos, menos movimento e brilho" do
    css = CSS.join("v21_web.css").read
    %w[ss-cue-on ss-cue-open ss-cue-arrive prefers-reduced-motion has-level --ss-level].each { assert_includes css, _1 }
    assert_includes CSS.join("engine.css").read, "v21_web.css"
    js = JS.join("ss_cue_controller.js").read
    assert_includes js, "prefers-reduced-motion"
    assert_includes js, "before === false && now"
  end

  test "vitrine da v0.21 renderiza" do
    html = VitrineController.render(template: "vitrine/pecas_v021", layout: false)
    assert_includes html, "has-level"
    assert_includes html, "data-controller=\"ss-cue\""
  end
end
