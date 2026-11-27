# Gera as <section> do catálogo (rails/catalogo/index.html) da v1.14.0 "interface e animação": o scrub dos gráficos,
# Ss::PeriodCompareComponent, Ss::ExpandableRowComponent, Ss::SelectionBarComponent, DrawerComponent(detents:), as abas
# de baixo da moldura, Ss::MeshBackgroundComponent, o odômetro no KPI, PageComponent(collapse_tint:),
# Ss::SuccessCheckComponent, Ss::TiltCardComponent e o ss_skeleton_for.
#   bin/rails runner script/catalogo_v1140.rb > /tmp/v1140.html
include ComponentesUi::Helpers
require "action_dispatch/testing/test_request"
CTRL = ApplicationController.new.tap { |c| c.request = ActionDispatch::TestRequest.create("PATH_INFO" => "/vitrine/x"); c.response = ActionDispatch::Response.new }
def view = (@view ||= CTRL.view_context)
def clean(html) = html.to_s.gsub(/<!-- (BEGIN|END) [^>]*-->/, "").gsub(/\n\s*/, "").gsub(/ss-[a-z]+-\d{4,}/) { |m| m.sub(/\d+\z/, "cat") }
def r(c, &blk) = clean(view.render(c, &blk))
def esc(s) = ERB::Util.h(s)
def section(slug, nome, desc, comps, estados)
  out = +%(<section data-comp="#{slug}" data-nome="#{esc(nome)}" data-descricao="#{esc(desc)}"\n  data-comportamentos='#{esc(comps.to_json)}'>\n)
  estados.each { |(s, t, html)| out << %(  <div data-estado="#{s}" data-titulo="#{esc(t)}">#{html}</div>\n) }
  out << "</section>\n"
end
def box(w, html, style = "") = %(<div style="width:#{w}px;#{style}">#{html}</div>)

DIAS = (1..10).map { |d| format("%02d/11", d) }
VENDAS = [80, 120, 95, 140, 110, 160, 210, 180, 150, 175]
# O balão do scrub aparece com o JS; na captura, o estado "arrastando" põe o cursor, o ponto e o balão à mão.
def scrubbing(html, x:, y:, label:, rows:)
  tip = %(<span class="ss-scrub-cursor" style="left:#{x}%"></span><span class="ss-scrub-dot" style="left:#{x}%;top:#{y}%"></span>) +
        %(<span class="ss-scrub-tip" style="left:#{x}%"><b>#{esc(label)}</b>#{rows.map { |(n, c, t)| %(<span><i style="background:#{c}"></i><em>#{esc(n)}</em><strong class="num">#{esc(t)}</strong></span>) }.join}</span>)
  html.sub(%r{</svg></div>}) { "</svg>#{tip}</div>" }
end

line = r(Ss::LineChartComponent.new(title: "Vendas por dia", labels: DIAS, scrub: true, show_title: true, format: ->(v) { view.ss_money(v) }, series: [{ name: "Vendas", values: VENDAS }]))
print section("ss-scrub", "scrub: (gráficos)", "Gráfico que se arrasta (v1.14, par do SsLineChart/SsBarChart/SsAreaChart/SsTimeChart(scrub:)): o marcador segue o dedo ou o mouse, com o valor e a data num balão.",
  ["scrub: true no LineChartComponent, BarChartComponent, AreaChartComponent e TimeSeriesChartComponent.",
   "Pointer events: mouse ao passar, dedo ao arrastar (touch-action: pan-y, a página ainda rola na vertical).",
   "Vibra (selection) a cada ponto novo e dispara ss-scrub:change { index, label } (index null ao soltar): a tela inteira acompanha.",
   "Teclado: ← → Home End no gráfico focado, com o ponto lido pelo leitor de tela; reduzir movimento tira o deslize do marcador."],
  [["parado", "linha, sem tocar", box(560, line)],
   ["arrastando", "o dedo no dia 07/11", box(560, scrubbing(line, x: 66.9, y: 30, label: "07/11", rows: [["Vendas", "var(--series-1)", view.ss_money(210)]]))],
   ["barras", "barras com a meta", box(560, r(Ss::BarChartComponent.new(title: "Pedidos por dia", labels: DIAS.first(7), scrub: true, show_title: true, series: [{ name: "Pedidos", values: [12, 18, 9, 22, 25, 14, 8] }], line: { name: "Meta", values: [15] * 7 })))]])

cmp = ->(**o) { r(Ss::PeriodCompareComponent.new(title: "Vendas", labels: DIAS, current: VENDAS, previous: [90, 100, 110, 120, 105, 130, 150, 140, 160, 150], money: true, current_label: "Este mês", previous_label: "Mês passado",
                                                 periods: [{ label: "Mês", href: "#", current: true }, { label: "Semana", href: "#" }], **o)) }
print section("ss-period-compare", "Ss::PeriodCompareComponent", "Este período × o anterior (v1.14, par do SsPeriodCompare): o total, a diferença em destaque e o anterior como linha fantasma no mesmo gráfico.",
  ["Total em DM Mono no odômetro (rola ao trocar); diferença em % na pílula .ss-delta, verde ou vermelha pelo sentido (higher_is_better: false para gasto).",
   "O gráfico é o LineChartComponent com scrub: o anterior tracejado e apagado; o balão mostra os dois valores do dia.",
   "Troca de período pelo segmentado (frame: mira o turbo-frame): a linha desliza do desenho antigo para o novo e o total rola.",
   "Leitor de tela: \"R$ 1.620,00 neste período, R$ 1.255,00 no anterior\" e \"+29% em relação ao período anterior (bom)\"."],
  [["mes", "vendas: mês × mês passado", box(600, cmp.call)],
   ["gasto", "gasto que subiu (ruim)", box(600, cmp.call(higher_is_better: false, periods: []))]])

xr = ->(open) { r(Ss::ExpandableRowComponent.new(title: "Mercado Exemplo", subtitle: "12/11 · Mercado", value: view.ss_money(89.9), url: "#", open:)) { '<label class="ss-field"><span class="ss-label">Descrição</span><input class="ss-input" value="Mercado Exemplo"></label><label class="ss-field"><span class="ss-label">Valor</span><input class="ss-input num" value="89,90"></label>'.html_safe } }
print section("ss-expandable-row", "Ss::ExpandableRowComponent", "Linha que se expande no lugar (v1.14, par do SsExpandableRow): edição rápida com os campos, Salvar e Cancelar embaixo da linha.",
  ["\"Editar\" (aria-expanded) abre o painel: a altura anima (grid-template-rows 0fr → 1fr) e o foco vai ao 1º campo.",
   "Esc ou Cancelar desfazem o digitado, fecham e devolvem o foco ao Editar; Salvar envia (url:/method:) e, deu certo, fecha com \"Salvo\".",
   "Fechado, o painel fica inert (fora do Tab e do leitor de tela)."],
  [["fechada", "a linha", box(560, xr.call(false))], ["aberta", "editando", box(560, xr.call(true))]])

sel = r(Ss::SelectionBarComponent.new(actions: [{ label: "Arquivar", icon: "archive", url: "#" }, { label: "Excluir", icon: "trash", url: "#", danger: true }])) do
  '<label class="ss-check"><input type="checkbox" class="ss-select-item" value="1" checked> Pedido 1042</label><br><label class="ss-check"><input type="checkbox" class="ss-select-item" value="2" checked> Pedido 1043</label>'.html_safe
end
sel_on = sel.sub(' hidden="hidden"', "").sub("ss-selection-bar\"", "ss-selection-bar\" style=\"position:static;translate:none;margin-top:12px;width:max-content\"")
            .sub(/data-ss-odometer-text-value="0"/, 'data-ss-odometer-text-value="2"').sub(/--pos:10;/, "--pos:12;")
print section("ss-selection-bar", "Ss::SelectionBarComponent", "Seleção em massa (v1.14, par do SsSelectable + SsSelectionBar): marcar itens sobe a barra com as ações e o contador no odômetro.",
  ["A lista no bloco: caixas com .ss-select-item (ou data-ss-selection-target=item) e, opcional, a de todos (target all, indeterminada no meio).",
   "Shift + clique marca ou desmarca o intervalo desde o último clicado; Esc limpa.",
   "A barra sobe com a mola (--ss-bounce) e desce reta; o número rola (Ss::OdometerComponent); \"Limpar seleção\".",
   "Ação com url: é um form que leva um ids[] por marcado (confirm: pede antes); com href:, os ids vão na query."],
  [["marcados", "dois marcados", box(520, sel_on, "padding-bottom:8px")]])

drawer = r(Ss::DrawerComponent.new(id: "cat-folha", title: "Filtros", detents: [0.33, 0.5, 1], detent: 0.5)) { '<label class="ss-check"><input type="checkbox" checked> Abertos</label><br><label class="ss-check"><input type="checkbox"> Faturados</label>'.html_safe }
drawer = drawer.sub("<dialog ", '<dialog open style="position:static;display:flex;flex-direction:column;height:320px;width:390px;border-radius:20px 20px 0 0;margin:0" ')
print section("ss-drawer-detents", "Ss::DrawerComponent(detents:)", "Folha com três alturas no celular (v1.14, par do showSsSheet(detents:)): arrastar a alça leva de 33% a 50% e à tela cheia, com a mola.",
  ["detents: [0.33, 0.5, 1] (fração da tela); detent: onde abre (padrão a 1ª). Só até 40rem; no computador, o painel lateral.",
   "Arrastar a alça muda a altura com o dedo; soltou, vai à altura mais perto (com o embalo) com a mola; abaixo da menor, fecha.",
   "A alça é um slider (role=slider): ↑ ↓ Home End e Enter andam pelas alturas; o leitor de tela ouve \"50% da tela\"."],
  [["metade", "aberta em 50% (celular)", box(390, drawer.gsub('class="ss-drawer-handle"', 'class="ss-drawer-handle" style="display:grid;place-items:center;height:44px"').gsub("<i></i>", '<i style="display:block;width:38px;height:5px;border-radius:99px;background:var(--line)"></i>'))]])

shell = r(Ss::AppShellComponent.new(brand: "Minhas Vendas", tabs: [{ label: "Início", icon: "home", href: "#", current: true }, { label: "Pedidos", icon: "shopping-bag", href: "#", badge: 3 },
                                                                 { label: "Clientes", icon: "users", href: "#" }, { label: "Relatórios", icon: "chart-bar", href: "#" }])) { "<p style='padding:16px'>Conteúdo da aba</p>".html_safe }
tabbar = shell[/<nav class="ss-shell-tabbar".*?<\/nav>/m].to_s.sub('class="ss-shell-tabbar"', 'class="ss-shell-tabbar" style="display:flex;position:static"')
print section("ss-shell-tabs", "Ss::AppShellComponent(tabs:)", "Abas de baixo no celular (v1.14, par do SsNavBar + SsNavScaffold): o ícone da aba atual passa de contorno a cheio com mola e leve rotação; a troca é uma View Transition.",
  ["tabs: [{ label:, icon:, href:, current:, badge: }]; só até 1023 px. icon: nome do ss_icon (contorno e cheio do mesmo nome).",
   "Aba atual (aria-current=page): o cheio entra com escala de mola e -14° → 0; a pílula tonal atrás.",
   "tab_transition: true (padrão): fade through no conteúdo, a barra parada (precisa do ss_view_transitions_head); ss_tab_hero(\"x\") faz a mesma peça voar entre as abas.",
   "Reduzir movimento: corte seco e o ícone troca sem a mola."],
  [["celular", "a barra com Início na frente", box(390, %(<div style="max-width:390px">#{tabbar}</div>))]])

print section("ss-mesh-background", "Ss::MeshBackgroundComponent", "Fundo de manchas da marca que se movem devagar (v1.14, par do SsMeshBackground), para cabeçalhos de destaque.",
  ["Só transform em gradientes radiais (sem filter: blur), uma animação contínua no ritmo --ss-dur-ambient (24 s); animate: false para.",
   "tone: :deep (padrão) na cor funda da paleta com véu e texto branco (≥ 4,5:1); :soft na página com o texto na tinta.",
   "HeroSectionComponent(mesh: true) põe o tom soft atrás do topo da landing. Reduzir movimento: parado."],
  [["deep", "saldo no topo", box(420, r(Ss::MeshBackgroundComponent.new(animate: false, css: "ss-card-pad")) { '<p style="font-size:13px;opacity:.85">Saldo de novembro</p><p class="num" style="font-size:30px">R$ 8.420,15</p>'.html_safe })],
   ["soft", "tom suave", box(420, r(Ss::MeshBackgroundComponent.new(tone: :soft, animate: false, css: "ss-card-pad")) { '<strong style="font-size:20px">Bom dia, Ana</strong><p class="ss-muted">3 pedidos novos</p>'.html_safe })]])

print section("ss-kpi-odometer", "KpiCardComponent(animate:)", "Odômetro como padrão (v1.14, par do SsKpiCard(animate:)/SsAmount(animate:)): o número do KPI rola cada dígito ao mudar.",
  ["animate: true é o padrão do KpiCardComponent; animate: false volta ao texto parado.",
   "ss_amount(texto, animate: true) usa o mesmo OdometerComponent, com os centavos menores.",
   "Rola no morph do Turbo, no turbo_stream ou com JS no data-ss-odometer-text-value; o leitor de tela ouve o valor novo."],
  [["kpi", "recebido hoje", box(300, r(Ss::KpiCardComponent.new(label: "Recebido hoje", value: view.ss_money(1240), money: true, delta: "+12%", good: true, hint: "vs. ontem")))]])

print section("ss-page-tint", "PageComponent(collapse_tint:)", "Cabeçalho que encolhe e muda de cor ao rolar (v1.14, par do SsScreenHeader(collapseTint:)).",
  ["Transparente no topo; ao rolar (0 a 96 px), a superfície com sombra e o título menor (animation-timeline: scroll()).",
   "Sem suporte do navegador, fica na superfície, parado; reduzir movimento também."],
  [["rolado", "depois de rolar", box(560, r(Ss::PageComponent.new(title: "Pedidos", subtitle: "Novembro", collapse_tint: true)))]])

ok = r(Ss::SuccessCheckComponent.new(label: "Pagamento confirmado")).sub('class="ss-success-check"', 'class="ss-success-check is-drawn"')
print section("ss-success-check", "Ss::SuccessCheckComponent", "Check que se desenha (v1.14, par do SsSuccessCheck): o círculo e depois o traço, com a vibração de sucesso e o gancho do som.",
  ["Toca uma vez quando aparece: o círculo se desenha (--ss-dur-long), o traço vem depois e o ✓ dá o pulinho da mola.",
   "sound: true dispara ss:sound { name: \"success\" } no window: o produto toca o áudio dele (o pacote não traz som).",
   "Está no fim do MorphButtonComponent, do SwipeToConfirmComponent e do PixCardComponent pago.",
   "role=img com o rótulo (\"Concluído\"); reduzir movimento: aparece pronto."],
  [["desenhado", "pagamento confirmado", box(200, %(<div style="display:grid;place-items:center;padding:16px">#{ok}</div>))],
   ["botao", "no fim do MorphButton", box(240, r(Ss::MorphButtonComponent.new(label: "Salvar", block: false)).sub('data-state="idle"', 'data-state="ok"'))]])

print section("ss-tilt-card", "Ss::TiltCardComponent", "Cartão que inclina (v1.14, par do SsTiltCard): segue o mouse ou o dedo com o reflexo de vidro, para cartão de destaque.",
  ["Gira até ~6° (perspectiva) e o reflexo anda com o ponteiro; solta voltando com a mola.",
   "Mouse ao passar; toque enquanto o dedo está no cartão (a página ainda rola na vertical).",
   "dense: true (tela de dados densos) e reduzir movimento: parado e sem reflexo. href: o cartão é link."],
  [["inclinado", "plano Pro (inclinado)", box(320, r(Ss::TiltCardComponent.new(css: "ss-card-pad")) { '<small class="ss-muted">Plano</small><p style="font-size:20px;font-weight:800">Pro anual</p><p class="num">R$ 19,90/mês</p>'.html_safe }
                                                     .sub('class="ss-card ss-tilt-card is-glass"', 'class="ss-card ss-tilt-card is-glass is-tilting" style="--ss-rx:3deg;--ss-ry:-5deg;--ss-mx:30%;--ss-my:20%"'), "padding:12px")]])

skel = clean(view.ss_skeleton_for("vitrine/skel_pedido", count: 2, pedido: { cliente: "Cliente exemplo", numero: "0000", quando: "hoje", status: "Aberto", total: 1234.56 }))
print section("ss-skeleton-for", "ss_skeleton_for", "Esqueleto no formato real (v1.14, par do SsSkeleton.of): o partial da linha renderizado e trocado por blocos, com o pulso do skeleton.",
  ["ss_skeleton_for(\"pedidos/linha\", count: 3, pedido: exemplo): renderiza o partial com dados de exemplo e troca cada texto por um bloco do tamanho dele.",
   "Imagem, svg e vídeo viram blocos do mesmo tamanho; saem id, href, action, name e eventos (nada clicável nem id repetido).",
   "aria-busy e \"Carregando…\" para o leitor de tela; o desenho fica aria-hidden e inert. Reduzir movimento: sem o pulso."],
  [["lista", "duas linhas carregando", box(520, skel)]])
