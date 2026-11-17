require "test_helper"

# v1.4 · a folhinha da entrada reage: Ss::AuthLayoutComponent(motion: true) com o controlador ss-auth.
class V140WebTest < ComponentTest
  CSS = Pathname(ComponentesUi::Engine.root).join("app/assets/tailwind/componentes_ui")
  JS = Pathname(ComponentesUi::Engine.root).join("app/javascript/componentes_ui/controllers")

  def tela(**opts)
    render_inline(Ss::AuthLayoutComponent.new(product: "Meu Gestor", tagline: "A loja em dia.", title: "Entrar",
                                              variant: :wall, date: Date.new(2026, 11, 17), **opts)) { "<form></form>".html_safe }
  end

  test "motion: true na :wall liga o ss-auth com as saudações e o modelo da folha de baixo" do
    tela(motion: true)
    main = page.find("main.ss-auth.is-wall[data-controller=ss-auth]")
    assert_equal "submit->ss-auth#leave click->ss-auth#click", main["data-action"]
    assert_equal "false", main["data-ss-auth-error-value"]
    assert_equal ["Bom dia", "Boa tarde", "Boa noite"], JSON.parse(main["data-ss-auth-greetings-value"])
    tpl = rendered_content[%r{<template data-ss-auth-target="next">(.*?)</template>}m, 1]
    assert tpl, "falta o <template> da folha de baixo"
    frag = Nokogiri::HTML5.fragment(tpl)
    assert frag.at_css(".ss-auth-next[aria-hidden=true] .ss-auth-head .ss-auth-month")
    assert frag.at_css(".ss-auth-next .ss-auth-hello")
    assert_equal "Em dia", frag.at_css(".ss-auth-stamp").text.strip
    assert_includes frag.at_css(".ss-auth-opening").text, "Abrindo o Meu Gestor…"
    assert frag.at_css(".ss-auth-opening .ss-auth-bar > i")
    assert_equal "Meu Gestor", frag.at_css(".ss-auth-band strong").text
  end

  test "error: true vai no valor do controlador (a folha treme ao abrir)" do
    tela(motion: true, error: true)
    assert_selector "main[data-ss-auth-error-value=true]"
  end

  test "sem motion, ou fora da :wall, nada muda" do
    tela
    assert_no_selector "main[data-controller]"
    assert_no_selector "template", visible: :all
    render_inline(Ss::AuthLayoutComponent.new(product: "X", title: "Entrar", motion: true)) { "" }
    assert_selector "main.ss-auth.is-sheet"
    assert_no_selector "main[data-controller]"
  end

  test "textos em en e es" do
    I18n.with_locale(:en) do
      tela(motion: true)
      assert_equal ["Good morning", "Good afternoon", "Good evening"], JSON.parse(page.find("main")["data-ss-auth-greetings-value"])
      assert_includes rendered_content, "Opening Meu Gestor…"
    end
    I18n.with_locale(:es) do
      tela(motion: true)
      assert_includes rendered_content, "Al día"
    end
  end

  test "CSS e controlador: cai, treme, posição da folha de baixo e reduzir movimento" do
    assert_includes CSS.join("engine.css").read, '@import "./v140_web.css";'
    css = CSS.join("v140_web.css").read
    assert_includes css, ".ss-auth-sheet.is-tearing { animation: ss-auth-tear"
    assert_includes css, ".ss-auth-sheet.is-shaking { animation: ss-auth-shake"
    assert_includes css, ".ss-auth-next { position: absolute;"
    assert_match(/prefers-reduced-motion: reduce\) \{\n  \.ss-auth-sheet\.is-tearing \{ animation: none; opacity: 0; \}/, css)
    js = JS.join("ss_auth_controller.js").read
    assert_includes js, 'static values = { error: Boolean, greetings: Array }'
    assert_includes js, 'document.addEventListener("turbo:submit-end", this.onEnd)'
    assert_includes js, 'Object.assign(next.style, { left: s.offsetLeft + "px"'
  end
end
