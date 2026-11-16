# Gera as <section> do catálogo (rails/catalogo/index.html) para a v0.28 (a segunda rodada do meulog).
#   bin/rails runner script/catalogo_v028.rb > /tmp/v028.html
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
def box(w, html) = %(<div class="ss-card ss-card-pad" style="width:#{w}px">#{html}</div>)

DIAS = [[1, :ok, "100% no ar"], [2, :ok, "100% no ar"], [3, :warn, "2 falhas em 288"], [4, :ok, "100% no ar"],
        [5, :bad, "fora 3 h"], [6, :ok, "100% no ar"], [7, :none, nil]].map { |d, t, x| { date: Date.new(2026, 11, d), tone: t, text: x } }.freeze

out = +""
out << section("ss-day-strip", "Ss::DayStripComponent · .ss-day-strip",
  "Faixa de status por dia (v0.28, par do SsDayStrip): um traço por dia, com respiro, como numa página de status.",
  ["Tom por dia: ok (--success), warn (--warn), bad (--danger), none (vazado, só a borda: sem dado não é \"no ar\").",
   "Dica nativa (title=) com a data, a situação e o texto do dia; pontas embaixo em DM Mono (start_label:/end_label:).",
   "Tabela .ss-sr (dia, situação) e o título no figcaption para o leitor de tela; a faixa é aria-hidden.",
   "Os dias têm 3 px de respiro e encolhem até 2 px (30, 60 ou 90 dias cabem no celular)."],
  [["padrao", "sete dias com uma queda e um instável", box(420, r(Ss::DayStripComponent.new(title: "Disponibilidade", days: DIAS, start_label: "há 7 dias", end_label: "hoje")))],
   ["titulo", "com o título à vista e traço baixo", box(420, r(Ss::DayStripComponent.new(title: "Rotina noturna, 7 dias", days: DIAS, show_title: true, height: 20)))]])
out << section("ss-filter-input", "Ss::FilterInputComponent · .ss-search.ss-filter-input",
  "Busca solta do ss-filter (v0.28): filtra a lista que já está na página, sem <form> e sem ir ao servidor.",
  ["Já sai com data-ss-filter-target=\"input\" e as ações (input aplica, Esc limpa); vai dentro do data-controller=\"ss-filter\".",
   "Lupa, rótulo só para o leitor de tela (label:, padrão \"Buscar na lista\") e placeholder:.",
   "Borda e anel de foco na cor da marca, como o campo da barra de filtros."],
  [["padrao", "dentro de uma lista", box(420, %(<div data-controller="ss-filter" class="grid gap-2">#{r(Ss::FilterInputComponent.new(label: "Buscar nos verbetes", placeholder: "Filtrar os verbetes"))}#{%w[Erros Ocorrências Funil].map { |v| r(Ss::ListItemComponent.new(title: v, subtitle: "Verbete", data: { ss_filter_target: "item" })) }.join}</div>))]])
out << section("ss-v28-correcoes", "v0.28: max:, título e subtítulo que quebram, qr_label:, ordenar com rótulo",
  "O que o meulog montou à mão e virou parâmetro (v0.28).",
  ["BarChart/LineChart(max:): o topo da escala fixo, para pequenos múltiplos na mesma escala (valor acima alarga).",
   "CardHeader(wrap: true): título em até 2 linhas; o título inteiro no title=. ListItem(subtitle_wrap: true): subtítulo inteiro.",
   "QrCard(qr_label:): o nome do QR para o leitor de tela (ex. o do autenticador).",
   "DataTable: o link de ordenar diz o que o Enter faz (\"Total: ordenar decrescente\"); Subnav sem item atual mostra o rótulo; count_label:.",
   "Correções: masonry que vazava numa coluna, AsideLayout que alargava a página, .ss-value-row com valor longo, f.ss_fieldset na seção com form: e o --muted a 4,5:1 sobre superfície tingida."],
  [["max", "dois gráficos com max: 40", %(<div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;width:520px">#{[[30, 12, 40], [4, 6, 3]].map { |v| box(250, r(Ss::BarChartComponent.new(title: "t", labels: %w[a b c], series: [{ name: "x", values: v }], max: 40, height: 140))) }.join}</div>)],
   ["wrap", "título em 2 linhas e subtítulo inteiro", box(360, r(Ss::CardHeaderComponent.new(title: "O relatório que a ferramenta manda toda manhã para o plantão", wrap: true)) +
      r(Ss::ListItemComponent.new(title: "Erros e regressões", subtitle: "O que o meulog agrupa, como prioriza e quando avisa quem está de plantão.", subtitle_wrap: true)))]])
puts out
