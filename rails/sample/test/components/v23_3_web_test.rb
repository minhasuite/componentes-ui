require "test_helper"

# v0.23.3 · role no seletor segmentado (abas) e o botão sem desenho com especificidade zero.
class V233WebTest < ComponentTest
  CSS = Pathname(ComponentesUi::Engine.root).join("app/assets/tailwind/componentes_ui")

  test "SegmentedComponent: role no grupo e no item (tablist/tab com aria-selected)" do
    render_inline(Ss::SegmentedComponent.new(label: "Andares", role: "tablist", scroll: true,
                                             items: [{ label: "Térreo", role: "tab", aria: { selected: "true", controls: "p1" } }]))
    assert_selector "div.ss-seg.is-scroll[role=tablist][aria-label=Andares] button[role=tab][aria-selected=true][aria-controls=p1]", text: "Térreo"
    render_inline(Ss::SegmentedComponent.new(items: [{ label: "A" }]))
    assert_selector "div.ss-seg[role=group]"
  end

  test "CSS: .ss-btn-bare só em :where (outra classe do botão vence)" do
    css = CSS.join("v23_web.css").read
    assert_includes css, ":where(.ss-btn-bare) {"
    assert_no_match(/^\s*\.ss-btn-bare\b/, css)
  end
end
