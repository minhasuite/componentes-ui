# Gera as <section> do catálogo (rails/catalogo/index.html) para as peças da v0.17.
#   bin/rails runner script/catalogo_v017.rb > /tmp/v017.html
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
mic = %(<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M12 3a3 3 0 0 0-3 3v6a3 3 0 0 0 6 0V6a3 3 0 0 0-3-3zM19 11a7 7 0 0 1-14 0M12 18v3"/></svg>)
pencil = %(<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="m15.2 5.2 3.6 3.6M4 20l4.5-1 10.3-10.3a2.5 2.5 0 0 0-3.5-3.5L5 15.5 4 20z"/></svg>)
out = +""
out << section("ss-fab-component", "Ss::FabComponent", "Botão flutuante como componente (v0.17, par do SsFab(extended:, extendedFrom:)): a ação principal num canto, por cima de tudo.",
  ["label: é o nome lido e a dica; extended: false (círculo, padrão), true (pílula), :wide (pílula a partir de 640 px).", "Fixo embaixo à direita (position: :start, esquerda), acima da área segura e da .ss-sticky-bar; lift: sobe acima de uma barra do app.",
   "id estável (padrão ss-fab): renderizado uma vez no layout, o morph do Turbo não duplica; permanent: true põe data-turbo-permanent.", "href: vira link; sem href, button type=button. Foco visível; some na impressão; sem o anel que pulsa (pulse: true liga)."],
  [["variantes", "círculo · pílula · :wide", %(<div style="display:flex;gap:16px;align-items:center">#{r(Ss::FabComponent.new(icon: mic, label: "Falar com a casa", static: true, id: "c1"))}#{r(Ss::FabComponent.new(icon: mic, label: "Falar com a casa", extended: true, static: true, id: "c2"))}</div>)]])
out << section("ss-page-compact", "Ss::PageComponent(eyebrow:, compact:)", "Cabeçalho compacto com a linha de cima (v0.17, par do SsTopBar(eyebrow:)): o topo discreto de um painel.",
  ["eyebrow: linha pequena em caixa alta acima do título (local · data).", "compact: título de 1,2 rem em até duas linhas e ações alinhadas ao centro, sem quebrar."],
  [["padrao", "painel com editar de ícone", %(<div style="width:390px">#{r(Ss::PageComponent.new(title: "Sala de estar", eyebrow: "Casa · 10 de novembro de 2026", compact: true)) { |p| p.with_actions { %(<a href="#" class="ss-icon-btn" aria-label="Editar painel">#{pencil}</a>).html_safe } }}</div>)]])
print out
