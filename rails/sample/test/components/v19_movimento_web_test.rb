require "test_helper"

# v1.9 · movimento: tokens --ss-dur/ease/dist, erro do campo sem salto no clique (ss-validate), mapa de vibração
# (ss-haptics), skeleton que vira conteúdo (ss-skeleton) e remoção com desfazer (ss-undoable / UndoableRemovalComponent).
class V19MovimentoWebTest < ComponentTest
  ROOT = Pathname(ComponentesUi::Engine.root)
  CSS = ROOT.join("app/assets/tailwind/componentes_ui")
  JS = ROOT.join("app/javascript/componentes_ui/controllers")

  def css = CSS.join("v19_movimento.css").read
  def js(nome) = JS.join("#{nome}_controller.js").read

  test "tokens únicos importados e com os valores do SsMotion" do
    engine = CSS.join("engine.css").read
    assert_includes engine, '@import "./v19_movimento.css";'
    { "--ss-dur-short" => ".18s", "--ss-dur-medium" => ".28s", "--ss-dur-long" => ".4s",
      "--ss-ease-standard" => "cubic-bezier(.2, 0, 0, 1)", "--ss-ease-enter" => "cubic-bezier(.33, 1, .68, 1)",
      "--ss-ease-exit" => "cubic-bezier(.32, 0, .67, 0)", "--ss-ease-spring" => "cubic-bezier(.34, 1.56, .64, 1)",
      "--ss-dist-small" => "4px", "--ss-dist-medium" => "12px", "--ss-dist-large" => "24px" }.each do |token, valor|
      assert_includes css, "#{token}: #{valor};", token
    end
    refute_match(/#[0-9a-fA-F]{3,6}\b/, css, "cor só por token")
  end

  test "as durações soltas das transições viraram os tokens" do
    usos = CSS.glob("*.css").sum { |f| f.read.scan(/var\(--ss-dur-(?:short|medium|long)\)/).size }
    assert_operator usos, :>, 150
    soltas = CSS.glob("*.css").reject { _1.basename.to_s == "paletas.css" }.flat_map do |f|
      f.read.scan(/transition(?:-duration)?\s*:[^;}]*/).select { _1.match?(/(?<![\w.\-])\.(?:15|16|18|2|22|25|28|3|4)s\b/) }
    end
    assert_empty soltas, "transição com duração solta que tem token"
  end

  test "erro do campo: a marca espera o clique terminar e o CSS não mostra no :user-invalid" do
    v = js("ss_validate")
    assert_includes v, 'this.element.dataset.ssValidateReady = ""'
    assert_includes v, 'document.addEventListener("pointerdown", this.onDown, true)'
    assert_includes v, 'document.addEventListener("pointerup", this.onUp, true)'
    assert_includes v, "setTimeout(() => this.flush(), 0)"
    assert_match(/leave\(f\) \{\n\s+const toque = .*\n\s+if \(!this\.pressing && !toque\) return this\.mark\(f\)\n\s+this\.pending\.add\(f\)/, v)
    assert_includes css, "form[data-ss-validate-ready] .ss-field:not(.is-invalid) .ss-field-error { display: none; }"
    assert_includes css, "form[data-ss-validate-ready] .ss-field:not(.is-invalid) .ss-field-help { display: block; }"
  end

  test "o ss_form_with liga o ss-validate (o form que ganha data-ss-validate-ready)" do
    html = vc_test_controller.view_context.ss_form_with(url: "/x") { |f| f.ss_email_field(:email, label: "E-mail", required: true) }
    assert_includes html, 'data-controller="ss-validate"'
  end

  test "mapa de vibração: os nomes do SsHaptics, opcional e desligado no desktop" do
    h = js("ss_haptics")
    assert_includes h, "export const PATTERNS = { selection: 8, limit: 14, success: [10, 60, 10], warning: 24, error: [30, 50, 30] }"
    assert_includes h, 'if (pref === "off" || typeof navigator.vibrate !== "function") return false'
    assert_includes h, 'return matchMedia("(pointer: coarse)").matches'
    assert_includes js("ss_range"), 'haptic("limit")'
    assert_includes js("ss_confirm_dialog"), '"warning" : "success"'
    assert_includes js("ss_toast"), 'if (this.element.classList.contains("is-bad")) haptic("error")'
    %w[ss_range ss_confirm_dialog ss_toast ss_undoable].each do |c|
      assert_includes js(c), 'import { haptic } from "componentes_ui/controllers/ss_haptics_controller"', c
    end
  end

  test "skeleton com frame liga o ss-skeleton, que faz o crossfade" do
    render_inline(Ss::SkeletonComponent.new(shape: :list, frame: { id: "ultimos", src: "/ultimos" }))
    assert_selector 'turbo-frame#ultimos[data-controller="ss-skeleton"][loading="lazy"] .ss-skel.is-list'
    s = js("ss_skeleton")
    assert_includes s, '"turbo:before-frame-render"'
    assert_includes s, 'ghost.classList.add("ss-skel-ghost")'
    assert_includes s, 'c.classList.add("ss-skel-in")'
    assert_includes s, "reduced()"
    assert_includes css, ".ss-skel-in { animation: ss-skel-in var(--ss-dur-medium) var(--ss-ease-enter) both; }"
    assert_includes css, "@keyframes ss-skel-in { from { opacity: 0; transform: translateY(var(--ss-dist-medium)); } }"
  end

  test "skeleton sem frame não muda" do
    render_inline(Ss::SkeletonComponent.new(shape: :line))
    assert_no_selector "turbo-frame"
    assert_selector '.ss-skel.is-line[role="status"]'
  end

  test "UndoableRemovalComponent liga o ss-undoable com os textos do idioma" do
    render_inline(Ss::UndoableRemovalComponent.new(message: "Pedido 1042 excluído", tag: :li, css: "ss-card", duration: 7)) { "Pedido 1042" }
    li = page.find("li.ss-undoable.ss-card")
    assert_equal "ss-undoable", li["data-controller"]
    assert_equal "Pedido 1042 excluído", li["data-ss-undoable-message-value"]
    assert_equal "Desfazer", li["data-ss-undoable-label-value"]
    assert_equal "7", li["data-ss-undoable-duration-value"]
    assert_text "Pedido 1042"
    assert_equal({ action: "submit->ss-undoable#remove" }, Ss::UndoableRemovalComponent::FORM_DATA)
    I18n.with_locale(:en) do
      render_inline(Ss::UndoableRemovalComponent.new(message: "Deleted")) { "x" }
      assert_equal "Undo", page.find("div.ss-undoable")["data-ss-undoable-label-value"]
    end
  end

  test "ss-undoable: encolhe, desfaz no mesmo lugar, envia depois do aviso e volta na falha" do
    u = js("ss_undoable")
    assert_includes u, "event.preventDefault()"
    assert_includes u, 'this.dur("--ss-dur-medium", 280)'
    assert_includes u, 'this.ease("--ss-ease-exit", "ease-in")'
    assert_includes u, 'this.ease("--ss-ease-enter", "ease-out")'
    assert_includes u, "a.reverse()"
    assert_includes u, '"ss-toast:closed"'
    assert_includes u, "this.form.requestSubmit(this.submitter)"
    assert_includes u, 'this.toast({ message: this.errorValue, bad: true })'
    assert_includes u, "keepalive: true"
    assert_includes u, "el.inert = true"
    assert_includes js("ss_toast"), 'this.element.dispatchEvent(new CustomEvent("ss-toast:closed", { bubbles: true }))'
  end

  test "textos novos nos três idiomas" do
    { "pt-BR" => "Desfazer", en: "Undo", es: "Deshacer" }.each do |loc, undo|
      assert_equal undo, I18n.t("componentes_ui.undoable_removal.undo", locale: loc)
      assert I18n.exists?("componentes_ui.undoable_removal.error", loc)
      assert I18n.exists?("componentes_ui.undoable_removal.close", loc)
    end
  end
end
