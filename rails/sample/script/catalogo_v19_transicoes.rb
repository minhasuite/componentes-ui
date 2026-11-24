# Gera as <section> do catálogo (rails/catalogo/index.html) da v1.9 · transições.
#   bin/rails runner script/catalogo_v19_transicoes.rb > /tmp/v19_transicoes.html
include ComponentesUi::Helpers
include ComponentesUi::TransitionHelpers
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

card = view.link_to("#", class: "ss-card ss-card-pad", **ss_view_transition_attrs("pedido-1042")) do
  view.tag.span(style: "display:flex;justify-content:space-between;gap:12px;align-items:center") do
    view.safe_join([view.tag.span(view.safe_join([view.tag.b("Pedido 1042"), view.tag.br, view.tag.small("Mercado Bom Preço", style: "color:var(--muted)")])), view.tag.b("R$ 318,40", class: "num")])
  end
end.to_s
cabecalho = r(Ss::PageComponent.new(title: "Pedido 1042", subtitle: "Mercado Bom Preço · R$ 318,40", back: "#", view_transition: "pedido-1042"))

print section("ss-open-container", "ss_view_transition_attrs + PageComponent(view_transition:)",
  "Lista → detalhe (v1.9, par do SsOpenContainer): o card da lista e o cabeçalho do detalhe têm o mesmo view-transition-name; na navegação do Turbo o card vira o cabeçalho.",
  ["ss_view_transitions_head no <head> põe o <meta name=\"view-transition\" content=\"same-origin\"> (Turbo 8+).",
   "ss_view_transition_attrs(registro) no card: style view-transition-name (ss-pedido-12-card) e data-ss-vt=\"card\" (curva da suíte, 420 ms).",
   "Ss::PageComponent(view_transition: registro) dá o mesmo nome ao cabeçalho; ss_view_transition_name(registro, :title/:image) para outras partes.",
   "PageComponent(shrink: true): o cabeçalho gruda no alto e encolhe ao rolar (animation-timeline: scroll(), só CSS).",
   ".ss-scroll-reveal e .ss-scroll-stagger > *: aparecem ao entrar na tela (animation-timeline: view()).",
   "Sem suporte do navegador ou com prefers-reduced-motion: corte normal e nada se move."],
  [["lista", "card na lista", box(360, card)],
   ["detalhe", "cabeçalho do detalhe", box(480, cabecalho)]])

ills = { empty: ["Nenhum pedido ainda", "nada ainda"], offline: ["Sem conexão", "sem conexão"], no_results: ["Nada com “xyz”", "sem resultado"],
         all_done: ["Tudo em dia", "tudo feito"], error: ["Não deu para carregar", "erro"] }
print section("ss-illustration", "Ss::EmptyStateComponent(illustration:)",
  "Estados vazios ilustrados (v1.9, par do SsEmptyState(illustration:)): vazio, sem conexão, sem resultado, tudo feito e erro, em SVG na cor da marca.",
  ["illustration: :empty, :offline, :no_results, :all_done ou :error no lugar do variant: (que segue igual).",
   "Entra crescendo com mola; parada, o símbolo flutua devagar e os brilhos piscam (só CSS). :all_done desenha o ✓.",
   ":error na cor de perigo e role=alert; as outras sem papel. Arte aria-hidden (o título é o que se lê).",
   "Nada se move com prefers-reduced-motion."],
  ills.map { |k, (t, titulo)| [k.to_s, titulo, box(260, r(Ss::EmptyStateComponent.new(illustration: k, title: t, compact: true)))] })

btn = ->(rotulo, cls) { %(<button type="button" class="ss-btn #{cls}" data-action="ss-celebrate#celebrate">#{rotulo}</button>).html_safe }
print section("ss-celebrate", "Ss::CelebrateComponent",
  "Comemoração com a regra da suíte (v1.9, par do SsCelebrate(kind:)): meta, sequência e primeiro uso; no máximo uma por sessão por tipo.",
  ["kind: :goal, :streak ou :first_use; o sessionStorage guarda ss-celebrate:<tipo> (a mesma regra do SsCelebrationGate).",
   ":goal e :first_use soltam o confete da suíte; :streak dá o pulo e o estouro em volta do conteúdo, sem confete.",
   "achieved: falso não comemora; on: :click só pelo data-action=\"ss-celebrate#celebrate\" (ou o evento ss:celebrate).",
   "O leitor de tela ouve \"Meta batida!\" / \"Sequência mantida!\" / \"Primeiro passo dado!\" (aria-live; pt, en, es).",
   "ConfettiComponent(kind:) passa pela mesma regra. Com prefers-reduced-motion, só o anúncio."],
  [["botoes", "meta, sequência e primeiro uso",
    box(420, %(<div style="display:flex;gap:12px;flex-wrap:wrap">) +
      r(Ss::CelebrateComponent.new(kind: :goal, on: :click)) { btn.("Bater a meta", "ss-btn-primary") } +
      r(Ss::CelebrateComponent.new(kind: :streak, on: :click, tag_name: :span)) { btn.("12 dias seguidos", "ss-btn-outline") } +
      r(Ss::CelebrateComponent.new(kind: :first_use, on: :click)) { btn.("Primeiro uso", "ss-btn-ghost") } + "</div>")]])
