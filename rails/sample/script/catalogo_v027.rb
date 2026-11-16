# Gera as <section> do catálogo (rails/catalogo/index.html) para a v0.27 (o que o meulog pediu).
#   bin/rails runner script/catalogo_v027.rb > /tmp/v027.html
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

DIAS = %w[01/11 02/11 03/11 04/11 05/11 06/11 07/11].freeze
MARCAS = [{ at: "03/11", label: "v2.3.1", kind: :deploy }, { at: "05/11", label: "API fora", kind: :incident },
          { at: "05/11", label: "v2.3.2", kind: :deploy }, { at: "07/11", label: "nota", kind: :note }].freeze
AGORA = [12, 19, 8, 24, 17, 22, 30].freeze
ANTES = [10, 11, 9, 14, 12, 15, 18].freeze

out = +""
out << section("ss-linec", "Ss::LineChartComponent · .ss-linec",
  "Linhas por categoria (v0.27, par do SsLineChart(curved: false)): retas de ponto a ponto, o período anterior tracejado e fino, áreas empilhadas, marcas e o vazio.",
  ["Linha reta (só M/L): uma curva suave inventaria valor entre dois dias.",
   "series: [{ name:, values:, tone:/color:, dashed: true }]; dashed: traço 4/3 e 1,25 px (a referência). nil num valor = buraco na linha.",
   "stacked: true empilha em áreas (a de cima soma as de baixo); a dica e a tabela mostram o valor de cada série.",
   "Legenda só com 2+ séries; pontos com até 14 rótulos (dots: força); cursor vertical no rótulo sob o mouse.",
   "Tabela .ss-sr com cada série (e as marcas) para o leitor de tela; empty: \"…\" mostra a caixa tracejada sem dados.",
   "Menos movimento: sem o fade de entrada."],
  [["linhas", "agora e a semana anterior, com marcas", box(480, r(Ss::LineChartComponent.new(title: "Ocorrências", labels: DIAS, markers: MARCAS,
      series: [{ name: "Agora", values: AGORA }, { name: "Anterior", values: ANTES, tone: :muted, dashed: true }])))],
   ["empilhado", "áreas empilhadas por versão", box(480, r(Ss::LineChartComponent.new(title: "Por versão", labels: DIAS, stacked: true,
      series: [{ name: "2.3.0", values: [8, 6, 4, 2, 1, 0, 0] }, { name: "2.3.1", values: [0, 3, 6, 9, 7, 5, 3] }, { name: "2.3.2", values: [0, 0, 0, 2, 5, 9, 12] }])))],
   ["vazio", "sem dados", box(480, r(Ss::LineChartComponent.new(title: "Ocorrências", labels: [], series: [], empty: "Sem dados no período")))]])
out << section("ss-barc-horizontal", "Ss::BarChartComponent(horizontal: true, tones:) · .ss-barc.is-horizontal",
  "Barras deitadas (v0.27, par do SsBarChart(horizontal: true)): uma linha por rótulo para categoria de nome longo, cor por valor e o valor no fim da barra.",
  ["Rótulo à esquerda (34% da largura) com reticências; o nome inteiro na dica (<title>).",
   "A barra cresce da esquerda (da direita, se negativa); o valor em DM Mono no fim.",
   "tones: [nil, …, :muted] (ou colors:) pinta cada valor; ex. a categoria Outros apagada para não parecer o maior item.",
   "A altura sai do número de linhas (30 px cada); line:, projection: e markers: não valem no deitado."],
  [["classes", "erros por classe com Outros apagado", box(480, r(Ss::BarChartComponent.new(title: "Erros por classe", horizontal: true,
      labels: ["ActiveRecord::RecordNotFound", "Net::ReadTimeout em PagamentosController#create", "NoMethodError", "Outros"],
      series: [{ name: "Ocorrências", values: [120, 64, 48, 30], tones: [nil, nil, nil, :muted] }])))],
   ["vazio", "sem dados", box(480, r(Ss::BarChartComponent.new(title: "t", labels: [], series: [], empty: "Sem dados no período")))]])
out << section("ss-chart-mark", "markers: (BarChart e LineChart) · .ss-chart-mark",
  "Marcas verticais (v0.27, par do SsChartMarker): o que mudou (deploy) e o que caiu (incidente) no eixo do tempo, e notas escritas à mão.",
  ["markers: [{ at: \"<rótulo>\", label:, kind: :deploy|:incident|:note }]; at: fora dos rótulos não aparece.",
   "Traço tracejado 4/3 de cima a baixo e o rótulo em DM Mono no alto; perto da borda direita alinha pelo fim.",
   "Deploy na cor de informação (--ss-info), incidente em --danger, nota em --muted.",
   "Duas marcas no mesmo rótulo empilham o texto (a área de cima cresce 13 px por linha).",
   "Coluna Marcas na tabela do leitor de tela e linha na dica do rótulo (\"v2.3.1 (implantação)\"; en: deploy, es: despliegue)."],
  [["colunas", "colunas com deploy, incidente e nota", box(480, r(Ss::BarChartComponent.new(title: "Por dia", labels: DIAS, markers: MARCAS,
      series: [{ name: "Agora", values: AGORA }, { name: "Anterior", values: ANTES, tone: :muted }])))]])
out << section("ss-icon-v27", "ss_icon: ícones do monitor de erros (v0.27)",
  "16 ícones novos no conjunto (desenho do Lucide, ISC, no traço 24/2 do conjunto) e apelidos com os nomes do Phosphor e do Lucide.",
  ["activity bug git-branch git-merge robot broadcast webhook tree-structure signpost stack brackets-curly file-code file-csv hard-drives gauge compass.",
   "Apelidos: heartbeat/pulse → activity, kanban/columns → view-boards, palette → color-swatch, prohibit → ban, funnel → filter, gear → cog, bot → robot, layers → stack…",
   "No Flutter, SsIcons.named com os mesmos nomes (Material equivalente)."],
  [["novos", "os 16", %(<div style="width:480px;display:flex;flex-wrap:wrap;gap:14px">#{%w[activity bug git-branch git-merge robot broadcast webhook tree-structure signpost stack brackets-curly file-code file-csv hard-drives gauge compass].map { |n| ss_icon(n, size: :lg) }.join}</div>)]])
puts out
