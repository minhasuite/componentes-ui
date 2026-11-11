# Gera a <section> do catálogo (rails/catalogo/index.html) da projeção no gráfico de barras (v0.20).
#   bin/rails runner script/catalogo_v020_projecao.rb > /tmp/v020p.html
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
row = ->(*cs) { %(<div style="display:flex;flex-wrap:wrap;gap:8px;align-items:center">#{cs.join}</div>) }
out = +""
dias = (1..30).map(&:to_s)
hoje = 11
rec = Array.new(30) { |i| i == 4 ? 4200 : (i % 9).zero? ? 300 : 0 }
des = Array.new(30) { |i| i > hoje ? 0 : -[120, 0, 80, 0, 260, 40, 0][i % 7] }
acc = rec.zip(des).each_with_object([]) { |(r, d), a| a << (a.last || 0) + r + d }
real = acc.each_with_index.map { |v, i| i <= hoje ? v : nil }
fut = { 14 => -1800, 19 => -350, 24 => 600, 27 => -900 }
proj = acc.each_with_index.map { |_, i| i < hoje ? nil : acc[hoje] + fut.select { |d, _| d <= i }.values.sum }
out << section("ss-barc-proj", "Ss::BarChartComponent(projection:, projection_from:)", "Projeção tracejada no gráfico de barras (v0.20, par do SsBarChart(projection:, projectionFrom:)): a linha do que ainda vai acontecer.",
  ["projection: { name:, values:, tone:/color: } desenha uma segunda linha tracejada (6/6), sem pontos, com um ponto só no fim; sem cor, a da linha.",
   "projection_from: N ignora os valores antes do índice N; nil num valor = sem ponto. A linha real para onde a projeção começa se vier com nil depois.",
   "Entra na legenda (traço tracejado), na dica do grupo e na tabela para leitor de tela (— onde não há ponto); a faixa do eixo inclui a projeção.",
   "Aparece com um esmaecer depois das barras; nada com reduzir movimento."],
  [["mes", "saldo real até hoje e projeção até o fim do mês", %(<div style="width:560px">#{r(Ss::BarChartComponent.new(title: "Fluxo do mês", labels: dias, series: [{ name: "Receitas", values: rec, tone: :success }, { name: "Despesas", values: des, tone: :danger }], line: { name: "Saldo acumulado", values: real, tone: :accent }, projection: { name: "Projeção", values: proj }, projection_from: hoje, active: hoje))}</div>)]])
print out
