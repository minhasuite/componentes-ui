require "test_helper"

# v1.4.1 · achados das videoaulas do meu-gestor (17/11/2026): o chat sem o balão nativo, o scrollspy que marca a
# seção do meio da tela e o ss-reveal com rádios. Os três falham na v1.4.0.
class V141WebTest < ComponentTest
  ROOT = Pathname(ComponentesUi::Engine.root)

  def js(name) = ROOT.join("app/javascript/componentes_ui/controllers/#{name}_controller.js").read

  test "ChatComponent: o formulário tem novalidate (sem o balão 'Preencha este campo.' ao parar o mouse no campo vazio)" do
    render_inline(Ss::ChatComponent.new(id: "c", url: "/ia", label: "Conversa"))
    assert_selector "form.ss-chat-form[novalidate]"
    # v1.8.3: sem `required` (com ele o Chrome mostra o balão ao parar o mouse mesmo com novalidate); aria-required diz ao leitor de tela
    assert_no_selector "form.ss-chat-form textarea[required]"
    assert_selector "form.ss-chat-form textarea[aria-required=true]"
    assert_includes js("ss_chat"), "if (!text) { e.preventDefault(); return }" # e o envio vazio continua barrado
  end

  test "ss-scrollspy: a seção é a última cujo topo passou da linha de leitura; a âncora da URL e o clique marcam na hora" do
    code = js("ss_scrollspy")
    refute_includes code, "IntersectionObserver" # a 1ª visível na faixa marcava a seção de cima
    assert_includes code, "getBoundingClientRect().top <= line"
    assert_includes code, "Math.min(window.innerHeight * 0.3, 200)"
    assert_includes code, "location.hash"
    assert_includes code, "this.sections[this.sections.length - 1]" # fim da página: a última
    assert_includes code, %(addEventListener("click", this.pick))
  end

  test "ss-reveal: o source pode ser um grupo de rádios (vale o marcado)" do
    code = js("ss_reveal")
    assert_includes code, %(s.type === "radio")
    assert_includes code, "radios.find((r) => r.checked)?.value"
    form = ApplicationController.new.view_context.ss_form_with(url: "/t", data: { controller: "ss-reveal" }) do |f|
      f.ss_radio_buttons(:kind, [ [ "Numa loja", "store" ], [ "Na empresa toda", "period" ] ], checked: "store",
                         data: { ss_reveal_target: "source", action: "change->ss-reveal#update" })
    end
    page = Capybara.string(form)
    assert_equal 2, page.all("input[type=radio][data-ss-reveal-target=source][data-action='change->ss-reveal#update']").size
  end
end
