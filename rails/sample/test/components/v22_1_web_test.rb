require "test_helper"

# v0.22.1 · barra fixa com always: true não some ao voltar o campo ao valor original.
# O bug (meu-gestor, Revisão de preços): o ss-dirty tirava o data-visible sempre que o form
# voltava ao estado inicial (ou em Cancelar/enviar), sem saber do always; a barra sumia até recarregar.
class V221WebTest < ComponentTest
  JS = Pathname(ComponentesUi::Engine.root).join("app/javascript/componentes_ui/controllers/ss_dirty_controller.js")

  test "always: true avisa o ss-dirty (data-ss-dirty-always-value) e já nasce visível" do
    render_inline(Ss::StickyActionBarComponent.new(always: true)) do |b|
      b.with_summary { "Enviar os marcados" }
      "<button>Enviar</button>".html_safe
    end
    assert_selector ".ss-sticky-bar[data-visible][data-controller='ss-dirty'][data-ss-dirty-always-value='true']"
  end

  test "sem always: nada de always no controller e a barra espera a alteração" do
    render_inline Ss::StickyActionBarComponent.new
    assert_selector ".ss-sticky-bar[data-controller='ss-dirty']", visible: :all
    refute_selector ".ss-sticky-bar[data-ss-dirty-always-value]", visible: :all
    refute_selector ".ss-sticky-bar[data-visible]", visible: :all
  end

  test "ss-dirty: o limpo só esconde a barra quando não é always" do
    js = JS.read
    assert_match(/always:\s*\{\s*type:\s*Boolean/, js)
    assert_includes js, %(this.element.toggleAttribute("data-visible", on || this.alwaysValue))
    refute_includes js, %(this.element.toggleAttribute("data-visible", on))
  end
end
