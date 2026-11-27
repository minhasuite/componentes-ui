# Gera as <section> do catálogo (rails/catalogo/index.html) da v1.11.0: o Ss::AppleButtonComponent, a linha de entrar
# com outra conta (with_provider do AuthLayoutComponent) e os acertos da v1.10 (CurvedHeader escuro e PulseAvatar).
#   bin/rails runner script/catalogo_v1110.rb > /tmp/v1110.html
include ComponentesUi::Helpers
require "action_dispatch/testing/test_request"
CTRL = ApplicationController.new.tap { |c| c.request = ActionDispatch::TestRequest.create("PATH_INFO" => "/vitrine/x"); c.response = ActionDispatch::Response.new }
def view = (@view ||= CTRL.view_context)
def r(c, &blk) = view.render(c, &blk).to_s.gsub(/<!-- (BEGIN|END) [^>]*-->/, "").gsub(/\n\s*/, "").gsub(/ss-[a-z]+-\d{4,}/) { |m| m.sub(/\d+\z/, "cat") }
def esc(s) = ERB::Util.h(s)
def section(slug, nome, desc, comps, estados)
  out = +%(<section data-comp="#{slug}" data-nome="#{esc(nome)}" data-descricao="#{esc(desc)}"\n  data-comportamentos='#{esc(comps.to_json)}'>\n)
  estados.each { |(s, t, html)| out << %(  <div data-estado="#{s}" data-titulo="#{esc(t)}">#{html}</div>\n) }
  out << "</section>\n"
end
def box(w, html, style = "") = %(<div style="width:#{w}px;#{style}">#{html}</div>)

print section("ss-apple-btn", "Ss::AppleButtonComponent", "Entrar com a Apple (v1.11, par do SsAppleButton): o logo e o texto, preto, branco ou com contorno, como pedem as diretrizes da Apple.",
  ["label: :continue (\"Continuar com a Apple\", padrão), :sign_in (\"Entrar com a Apple\") ou o texto; pt, en e es.",
   "style: :black (fundo claro), :white (fundo escuro) ou :outline. O preto e o branco são os da Apple (--ss-apple-ink/-paper).",
   "href: faz o POST sem Turbo (OmniAuth); method: :get vira link; sem href:, um <button type=button> para o Sign in with Apple JS do produto.",
   "compact: true é o quadrado só com o logo (nome no aria-label), ao lado do Ss::GoogleButtonComponent na linha .ss-auth-providers.",
   "Mesma altura e raio do botão do Google; foco com o anel da marca; reduzir movimento tira o afundar."],
  [["estilos", "preto, contorno e branco (sobre o escuro)", box(320, r(Ss::AppleButtonComponent.new(href: "#", method: :get)) +
      %(<div style="height:12px"></div>) + r(Ss::AppleButtonComponent.new(href: "#", method: :get, label: :sign_in, style: :outline)) +
      %(<div style="height:12px"></div><div style="background:var(--side);padding:12px;border-radius:var(--r-card)">) +
      r(Ss::AppleButtonComponent.new(style: :white)) + "</div>")],
   ["ao-lado-do-google", "with_provider: o G e a Apple lado a lado", box(320, %(<div class="ss-auth-providers is-row">) +
      r(Ss::GoogleButtonComponent.new(href: "#", method: :get)) + r(Ss::AppleButtonComponent.new(href: "#", method: :get, compact: true)) + "</div>")]])

print section("ss-curved-v1110", "Ss::CurvedHeaderComponent (v1.11)", "O cabeçalho curvo escuro (v1.11, acerto da v1.10): o tone: :dark agora levanta do fundo no tema escuro.",
  ["tone: :dark mistura 18% da tinta (--ink) no --side: no escuro fica visível sobre a página; no claro quase não muda.",
   "O texto continua claro (--on-accent) e o voltar com alvo de 48."],
  [["escuro", "tone: :dark", box(360, r(Ss::CurvedHeaderComponent.new(title: "Início", tone: :dark)) + %(<div style="height:40px"></div>), "position:relative;isolation:isolate")]])

print section("ss-pulse-v1110", "Ss::PulseAvatarComponent (v1.11)", "As ondas do avatar ao vivo (v1.11, acerto da v1.10): mais fortes e com aro no tema claro.",
  ["No claro, a onda tem 34% da cor e um aro de 1,5 px (antes 22%, que sumia no papel); no escuro fica a de antes.",
   "Reduzir movimento deixa as ondas paradas."],
  [["claro", "chamando e ouvindo", %(<div style="display:flex;gap:16px">) + r(Ss::PulseAvatarComponent.new(name: "Ana Souza", status: "chamando")) +
      r(Ss::PulseAvatarComponent.new(name: "Assistente", status: "ouvindo", tone: :success)) + "</div>"]])
