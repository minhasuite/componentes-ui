# Gera as <section> do catálogo (rails/catalogo/index.html) para a v1.2 (auditoria de UX e videoaulas do minhas-vendas).
#   bin/rails runner script/catalogo_v120.rb > /tmp/v120.html
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
def campo(rotulo, valor = "") = %(<div class="ss-field"><label>#{rotulo}</label><input class="ss-input" value="#{valor}"></div>).html_safe

def pedido(aberto: false)
  r(Ss::RepeaterComponent.new(add_label: "Adicionar item", label: "Itens", mobile: :compact,
                              header: ["Produto", "Descrição", "Qtd", "Unitário", "Desc.", { label: "Total", align: :end }], columns: [4, 2, 1, 2, 1, 2])) do |rep|
    [["Arroz 5 kg", "2", "25,90", "R$ 51,80"], ["Feijão 1 kg", "3", "8,90", "R$ 26,70"]].each_with_index.map do |(p, q, u, t), i|
      rep.row(class: ("is-open" if aberto && i.zero?)) do
        rep.cell(:primary) { campo("Produto", p) } + rep.cell(:detail) { campo("Descrição") } +
          rep.cell(:inline) { campo("Qtd", q) + campo("Unitário", u) } + rep.cell(:detail) { campo("Desc.") } +
          rep.cell(:inline) { %(<div class="text-right"><p class="ss-label">Total</p><p class="num font-bold py-2">#{t}</p></div>).html_safe }
      end
    end.join.html_safe
  end
end

MESES = %w[dez jan fev mar abr mai jun jul ago set out nov].freeze

out = +""
out << section("ss-repeater-compact", "Ss::RepeaterComponent(mobile: :compact) + r.cell",
  "Linha de item compacta no celular (v1.2, par do SsRepeater(mobile: SsRepeaterMobile.compact) + SsRepeaterCell): o pedido deixa de ter 7 campos empilhados por item.",
  ["Abaixo de 48rem: r.cell(:primary) na linha inteira (produto), r.cell(:inline) lado a lado numa linha (qtd × preço × total), r.cell(:detail) recolhido atrás do \"Detalhes\" da linha.",
   "\"Detalhes\" (componentes_ui.repeater.details, pt/en/es; details_label: troca) com aria-expanded; o ss-repeater#details põe .is-open na linha. Só aparece na linha que tem detalhe.",
   "O detalhe com erro (.is-invalid, aria-invalid, :user-invalid) aparece mesmo fechado.",
   "Em tela larga nada muda: a r.cell é display: contents e cada campo segue uma coluna do header:/columns:. Campo fora de r.cell é primary.",
   "A linha nova (template) também ganha o Detalhes; o × fica no alto da linha."],
  [["fechado", "pedido no celular, detalhes fechados", box(360, pedido)],
   ["aberto", "detalhes da 1ª linha abertos", box(360, pedido(aberto: true))]])
out << section("ss-v120-correcoes", "v1.2: rótulos do eixo que não colam, foco fora da barra do topo e o nome da caixa da linha",
  "O que a auditoria de UX e as videoaulas do minhas-vendas acharam nas peças genéricas (v1.2).",
  ["BarChart/LineChart: os rótulos do eixo X saem de N em N pela largura do maior rótulo (não mais 26 unidades fixas) e a contagem parte do active: (o mês atual nunca ganha um vizinho colado). Em 360, doze meses saem de 2 em 2 (antes \"MARABR\"). label_every: ainda força.",
   "Moldura: html:has(.ss-shell-top) ganha scroll-padding-top: var(--ss-top-room) (a altura da barra do topo + área segura + respiro); o campo em foco ou a âncora param abaixo da barra. Sem barra no computador (.is-bare), sem folga.",
   "DataTable(selectable: true): a caixa de cada linha diz \"Selecionar <título da linha>\" (coluna mobile: :title ou a 1ª coluna, sem HTML), nunca o id; select_label: ->(row) { … } ou :campo troca; sem texto, \"Selecionar linha N\" (posição)."],
  [["meses-360", "doze meses no desenho de 360, o atual em destaque", box(320, r(Ss::BarChartComponent.new(title: "Faturamento por mês", labels: MESES, series: [{ name: "Faturamento", values: [18, 17, 15, 21, 19, 17, 23, 21, 19, 26, 24, 22] }], width: 360, height: 200, active: 11, legend: false)))],
   ["selecao", "caixa da linha com o nome do cliente", box(480, r(Ss::DataTableComponent.new(rows: [{ id: "0b6f3f5e-6a2e", numero: 2904, cliente: "Sabor Caseiro" }, { id: "4c1d9a77-3f0b", numero: 2905, cliente: "Bar do Tonhão" }], id: "cat-sel", caption: "Pedidos", tools: false, selectable: true)) { |t| t.column(:cliente, "Cliente"); t.column(:numero, "Nº", format: :number) })]])
puts out
