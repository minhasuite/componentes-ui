# Gera a <section> do catálogo (rails/catalogo/index.html) para a ajuda da moldura (v1.6.0).
#   bin/rails runner script/catalogo_v160.rb > /tmp/v160.html
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
# Painel aberto fora do popover (o catálogo é estático).
def aberto(html) = html.sub(/\A.*?(<div id="[^"]+-panel")/m, '\1').sub(/<\/span>\z/, "")
                       .sub('class="ss-popover ss-help-panel"', 'class="ss-popover ss-help-panel" style="position:static;opacity:1;scale:1;translate:0 0;display:block"')
def fechado(html) = html.sub(/<div id="[^"]+-panel".*<\/div><\/span>\z/m, "</span>")

novas = r(Ss::HelpMenuComponent.new(id: "cat-ajuda", learn_href: "#", news_href: "#", unseen_news: 2))
visto = r(Ss::HelpMenuComponent.new(id: "cat-ajuda-v", learn_href: "#", news_href: "#"))
print section("ss-help", "Ss::HelpMenuComponent", "Ajuda da moldura (v1.6, par do SsHelpMenu): o \"?\" da barra de cima com Aprenda (videoaulas) e Novidades, em outra aba.",
  ["learn_href: e news_href: abrem em outra aba (ícone de saída e \"(abre em outra aba)\" para o leitor de tela).",
   "unseen_news: põe o ponto da marca no botão (nome lido \"Ajuda, 2 novidades não vistas\") e o selo \"2 novas\" na linha Novidades.",
   "Clicar em Novidades apaga ponto e selo na hora (ss-help) e fecha o popover; o produto grava o visto no servidor pelo link.",
   "news_href: nil esconde Novidades (produto sem novidade publicada); items: soma linhas (ex. atalhos).",
   "No slot help do Ss::AppShellComponent: barra de cima, antes do sino, no computador e no celular."],
  [["novas", "botão com novidade não vista", box(80, fechado(novas))],
   ["visto", "botão sem novidade", box(80, fechado(visto))],
   ["aberto", "painel com 2 novas", box(340, aberto(novas))]])
