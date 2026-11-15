# Gera a <section> do catálogo (rails/catalogo/index.html) para a v0.25 (rodada 5 da auditoria de UX).
#   bin/rails runner script/catalogo_v025.rb > /tmp/v025.html
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
def box(w, html) = %(<div style="width:#{w}px">#{html}</div>)

longo = "Avançado: kit, margem e vencimento do lote que não vai vender a tempo"
grupo = ->(**o) { r(Ss::CollapsibleComponent.new(title: longo, css: "ss-card ss-card-pad", **o)) { view.tag.p("Campos do grupo.") } }
out = +""
out << section("ss-collapsible-v25", "Ss::CollapsibleComponent: título longo (v0.25)",
  "Grupo recolhível com título comprido no celular (v0.25, par do SsCollapsible): o título quebra em até 2 linhas e o grupo não alarga a página.",
  ["O título quebra linha (até 2; depois reticências) e o texto inteiro fica no title= do título.",
   "Seta, contagem e selo não encolhem nem quebram; o selo segue à direita.",
   "O grupo cabe no pai mesmo como item de grid/flex (min-width: 0; max-width: 100%): antes, em 390 px, a página ia a 735 px."],
  [["celular", "título longo em 358px", box(358, grupo.call)],
   ["celular-selo", "com contagem e selo em 358px", box(358, grupo.call(count: 12, label: "2 vencendo hoje", tone: :warn))]])
puts out
