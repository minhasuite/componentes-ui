# Gera a <section> do catálogo (rails/catalogo/index.html) para a entrada "Cartaz + papel" (v1.7.0).
#   bin/rails runner script/catalogo_v170.rb > /tmp/v170.html
include ComponentesUi::Helpers
require "action_dispatch/testing/test_request"
CTRL = ApplicationController.new.tap { |c| c.request = ActionDispatch::TestRequest.create("PATH_INFO" => "/vitrine/x"); c.response = ActionDispatch::Response.new }
def view = (@view ||= CTRL.view_context)
def r(c, &blk) = view.render(c, &blk).to_s.gsub(/<!-- (BEGIN|END) [^>]*-->/, "").gsub(/\n\s*/, "")
def esc(s) = ERB::Util.h(s)
def section(slug, nome, desc, comps, estados)
  out = +%(<section data-comp="#{slug}" data-nome="#{esc(nome)}" data-descricao="#{esc(desc)}"\n  data-comportamentos='#{esc(comps.to_json)}'>\n)
  estados.each { |(s, t, html)| out << %(  <div data-estado="#{s}" data-titulo="#{esc(t)}">#{html}</div>\n) }
  out << "</section>\n"
end

FORM = %(<div class="ss-field"><label class="ss-label">E-mail</label><input class="ss-input" placeholder="voce@exemplo.com"></div>) +
       %(<div class="ss-field" style="margin-top:12px"><label class="ss-label">Senha</label><input class="ss-input" type="password"></div>) +
       %(<button class="ss-btn ss-btn-primary" style="width:100%;margin-top:16px">Entrar</button>).html_safe
def entrada(**o) = r(Ss::AuthLayoutComponent.new(product: "Minhas Vendas", tagline: "A venda não para.", title: "Entrar", subtitle: "no Minhas Vendas",
                                                  variant: :cartaz, icon: "chart-bar", links: [["Termos", "#"], ["Privacidade", "#"]], **o)) { FORM.html_safe }

print section("ss-auth-cartaz", "Ss::AuthLayoutComponent(variant: :cartaz)",
  "Tela de entrada \"Cartaz + papel\" (v1.7, par do SsAuthLayout.cartaz): metade cartaz na cor funda da paleta do produto, com a frase grande e a palavra gigante cortada pela borda; metade papel com o formulário.",
  ["layout: :split (o único por enquanto). Acima de 860 px, cartaz (6/11) e papel (5/11) lado a lado; abaixo, o cartaz vira uma faixa em cima (sem a linha de dados) e o papel desce.",
   "Cor: --brand-deep da paleta (paletas.css, por data-palette); no escuro e no OLED, --brand-deep a 52% com a --page. Texto branco ≥ 7:1 e secundário ≥ 4,5:1 em todas as paletas (gerar.py confere).",
   "word: a palavra gigante (aria-hidden); padrão é a última palavra do product: em minúsculas. facts: a linha de dados em DM Mono. icon: um nome do ss_icon antes do produto.",
   "Ao abrir, uma passada de cor varre o cartaz uma vez e a palavra entra deslizando; reduzir movimento desliga.",
   "Foco visível: branco sobre o cartaz, cor da marca no papel. Alto contraste: o texto secundário fica branco inteiro.",
   "O papel usa --page e põe os campos em --surface; o formulário e os avisos são do produto (ss_form_with, GoogleButton, Callout, TextLink).",
   "date:, note: e motion: não valem no :cartaz; as variações :sheet, :wall e :pad seguem iguais."],
  [["computador", "1100 px, lado a lado", %(<div style="width:1100px;border-radius:16px;overflow:hidden">#{entrada(word: "vendas", facts: %w[Web Windows Caixa App], style: "min-height:640px")}</div>)]])
