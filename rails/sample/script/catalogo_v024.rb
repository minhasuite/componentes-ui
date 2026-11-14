# Gera as <section> do catálogo (rails/catalogo/index.html) para as peças da v0.24.
#   bin/rails runner script/catalogo_v024.rb > /tmp/v024.html
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

itens = [{ title: "Portão principal aberto", text: "Aberto há 10 minutos", time: "há 2 min", href: "#", unread: true, icon: "exclamation-circle", tone: :danger },
         { title: "Resumo do dia", text: "3 automações rodaram", time: "há 1 h", href: "#", icon: "calendar", tone: :accent }]
painel = %(<div class="ss-popover ss-bell-panel" style="position:static;opacity:1;scale:1;translate:0 0;display:block">) +
         %(<div class="ss-bell-head"><p class="ss-popover-title">Avisos</p></div><div class="ss-bell-body">#{r(Ss::NotificationListComponent.new(items: itens))}</div>) +
         %(<a class="ss-bell-foot" href="#">Ver todos os avisos</a></div>)
print section("ss-bell", "Ss::NotificationBellComponent", "Sino de avisos do topo (v0.24, par do SsNotificationBell): contador de não lidos e o popover com os últimos avisos.",
  ["count: (0 some, mais de 99 vira 99+); count_url: atualiza a cada every: ms com a aba visível, ao voltar e ao abrir.",
   "items: ou src: (turbo-frame lazy, recarregado ao reabrir); item com method: vira button_to (abrir marca como lido).",
   "read_all_href: (PATCH), settings_href: (engrenagem) e all_href: (\"Ver todos\") no painel; links vão para a página inteira.",
   "No slot bell do Ss::AppShellComponent: canto direito da barra de cima, no computador e no celular."],
  [["fechado", "com 3 não lidos", box(80, r(Ss::NotificationBellComponent.new(id: "cat-sino", count: 3, items: itens)).sub(/<div id="cat-sino-panel".*<\/div><\/span>\z/m, "</span>"))],
   ["aberto", "painel com a lista", box(400, painel)]])
print section("ss-badge-c", "Ss::BadgeComponent", "Selo (v0.24, par do SsBadge): a pílula pequena de resumo, estado ou contagem, igual em toda tela.",
  ["tone: :neutral (padrão), :accent, :success, :warn, :danger, :muted; solid: e mono: como no .ss-badge.",
   "icon: antes do texto; dot: ponto na cor do texto (sem ícone).",
   "href: vira <a> (link_data: no link), com o contorno da marca ao passar."],
  [["resumo", "selos do topo de um painel", box(360, %(<div style="display:flex;flex-wrap:wrap;gap:8px">) +
     r(Ss::BadgeComponent.new(label: "1 luz acesa", icon: "light-bulb")) + r(Ss::BadgeComponent.new(label: "1 abertura", icon: "lock-open", href: "#")) +
     r(Ss::BadgeComponent.new(label: "2 sem sinal", icon: "status-offline", tone: :warn)) + r(Ss::BadgeComponent.new(label: "Online", tone: :success, dot: true)) + "</div>")]])
