# Gera a <section> do catálogo (rails/catalogo/index.html) para o cartão de conquista (v1.8.0).
#   bin/rails runner script/catalogo_v180.rb > /tmp/v180.html
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

feita = r(Ss::AchievementCardComponent.new(title: "Primeiro turno coberto", description: "Cobriu um turno aberto da escala.", earned: true, caption: "em 12/11"))
andamento = r(Ss::AchievementCardComponent.new(title: "30 dias seguidos", description: "Sequência de 30 dias escalados com tudo feito.", icon: "fire",
                                               progress: 0.4, progress_label: "12 de 30 dias"))
nada = r(Ss::AchievementCardComponent.new(title: "100 checklists no prazo", description: "Conclua 100 checklists antes do prazo."))
print section("ss-achievement", "Ss::AchievementCardComponent", "Cartão de conquista (v1.8, par do SsAchievementCard): medalhão com o ícone, título, a regra e o rodapé (selo \"Conquistada\" ou a barra do que falta).",
  ["earned: medalhão na cor da marca e o selo \"Conquistada\" com o caption (\"em 12/11\").",
   "Sem earned: medalhão apagado; com progress (0 a 1) a barra fina (role=progressbar, \"Falta: 12 de 30 dias\") e o progress_label.",
   "icon: nome do ss_icon; padrão \"trophy\" (o badge-check do conjunto, o mesmo do Flutter). href: o cartão vira link.",
   "Vários lado a lado: .ss-achievement-grid (auto-fill, mínimo 14rem). Sem altura fixa: o texto quebra.",
   "O título leva \"Conquista:\" só para o leitor de tela (.ss-sr)."],
  [["conquistada", "conquistada, com a data", box(240, feita)],
   ["andamento", "em andamento", box(240, andamento)],
   ["bloqueada", "sem progresso", box(240, nada)]])
