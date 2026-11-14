# Gera as <section> do catálogo (rails/catalogo/index.html) para as peças da v0.23.
#   bin/rails runner script/catalogo_v023.rb > /tmp/v023.html
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

temas = view.ss_form_with(url: "#") do |f|
  view.tag.div(view.safe_join([
    f.ss_swatch_radio(:theme, "violeta", label: "Violeta", style: "--p1: var(--accent); --p2: var(--series-2); --p3: var(--accent-soft)", block: true, checked: true),
    f.ss_swatch_radio(:theme, "verde", label: "Verde", style: "--p1: var(--success); --p2: var(--series-3); --p3: var(--success-soft)", block: true)
  ]), class: "grid grid-cols-2 gap-3")
end
print section("ss-swatch-radio", "f.ss_swatch_radio", "Tema numa amostra no formulário (v0.23.1): o .ss-swatch da v0.14 com o rádio montado pela gem.",
  ["label:, style: (as cores --p1..--p4 e --ss-swatch-wall do tema), size: :lg, block: true.",
   "dots: (4; 0 tira) e bar: false; com bloco, o conteúdo entra no lugar (ex. a opção Herdar com um ícone).",
   "O rádio some; a escolhida ganha o anel e o foco do teclado aparece na amostra."],
  [["galeria", "dois temas, Violeta escolhido", box(320, temas)]])
