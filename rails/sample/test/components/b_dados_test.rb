require "test_helper"

class BDadosTest < ComponentTest
  ROWS = [{ id: 1, cliente: "Bia", total: 30.0 }, { id: 2, cliente: "Ana", total: 10.5 }, { id: 3, cliente: "Caio", total: 20.0 }].freeze

  def table(**opts, &block)
    block ||= ->(t) { t.column(:cliente, "Cliente", sortable: true); t.column(:total, "Total", format: :money, sortable: true); t.column(:id, "Nº") }
    render_inline(Ss::DataTableComponent.new(rows: ROWS, id: "t", caption: "Pedidos", params: {}, **opts), &block)
  end

  test "tabela: caption, th com scope e aria-sort nas ordenáveis" do
    table(sort: "total", dir: "desc")
    assert_selector "table.ss-table caption", text: "Pedidos"
    assert_selector "th[scope=col][data-col=total][aria-sort=descending]"
    assert_selector "th[data-col=cliente][aria-sort=none]"
    assert_no_selector "th[data-col=id][aria-sort]"
    assert_selector "td.r.num .ss-amount", text: "R$\u00A030,00"
  end

  test "tabela: link de ordenar alterna o sentido e volta à página 1" do
    table(sort: "cliente", dir: "asc", params: { "page" => "3", "q" => "x" })
    href = page.find("th[data-col=cliente] a.ss-sort")[:href]
    assert_includes href, "dir=desc"
    assert_includes href, "sort=cliente"
    assert_includes href, "q=x"
    refute_includes href, "page="
    assert_includes page.find("th[data-col=total] a.ss-sort")[:href], "dir=asc"
  end

  test "tabela: sort_rows ordena em memória" do
    c = Ss::DataTableComponent.new(rows: ROWS, id: "t", caption: "x", sort: "cliente", dir: "asc", sort_rows: true, params: {})
    render_inline(c) { |t| t.column(:cliente, "Cliente", sortable: true) }
    assert_equal %w[Ana Bia Caio], page.all("td[data-col=cliente]").map(&:text)
    c2 = Ss::DataTableComponent.new(rows: ROWS, id: "t", caption: "x", sort: "total", dir: "desc", sort_rows: true, params: {})
    render_inline(c2) { |t| t.column(:total, "Total", sortable: true, format: :money) }
    assert_equal ["R$\u00A030,00", "R$\u00A020,00", "R$\u00A010,50"], page.all("td[data-col=total]").map(&:text)
  end

  test "tabela: seleção, barra, expansão, paginação e vazio" do
    render_inline(Ss::DataTableComponent.new(rows: ROWS, id: "t", caption: "x", selectable: true, bulk_url: "/lote", params: {}, pagination: { page: 2, pages: 9 })) do |t|
      t.column(:cliente, "Cliente")
      t.expansion { |r| "detalhe #{r[:id]}" }
      t.bulk_actions { "<button>Excluir</button>".html_safe }
    end
    assert_selector "input[type=checkbox][name='ids[]'][form=t-bulk]", count: 3
    assert_selector ".ss-selection-bar[hidden] form#t-bulk[action='/lote'] button", text: "Excluir", visible: :all
    assert_selector "button.ss-dt-toggle[aria-expanded=false][aria-controls=t-d-1]"
    assert_selector "tr.ss-dt-detail#t-d-1[hidden]", text: "detalhe 1", visible: :all
    assert_selector "nav.ss-dt-pager a[aria-current=page]", text: "2"
    assert_selector "nav.ss-dt-pager .ss-dt-gap"
    assert_selector "nav.ss-dt-pager a[rel=next][href*='page=3']"
    render_inline(Ss::DataTableComponent.new(rows: [], id: "v", caption: "x", empty: "Nada aqui", params: {})) { |t| t.column(:a, "A") }
    assert_selector "tr.ss-dt-empty .ss-empty", text: "Nada aqui"
  end

  test "barra de filtros: chips ativos, remover, visão atual e busca preserva filtros" do
    render_inline(Ss::FilterBarComponent.new(params: { "status" => "vencido", "q" => "pad" },
                                             views: [{ label: "Todos", params: {} }, { label: "Vencidos", params: { status: "vencido" } }],
                                             filters: [{ param: :status, label: "Situação", options: [["Vencido", "vencido"], ["Pago", "pago"]] }]))
    assert_selector ".ss-fb-chip", text: "Situação: Vencido"
    assert_selector ".ss-fb-chip a[href='?q=pad']"
    assert_selector ".ss-fb-view[aria-current=page]", text: "Vencidos"
    assert_selector "form[method=get] input[type=search][value=pad]"
    assert_selector "form[method=get] input[type=hidden][name=status][value=vencido]", visible: :all
    assert_selector ".ss-fb-add a[href*='status=pago']", visible: :all
  end

  test "kpis: variação pelo sentido e minigráfico" do
    render_inline(Ss::KpiStripComponent.new(items: [{ label: "Vendido", value: "R$ 1,00", money: true, delta: "+5%", good: true, spark: [1, 2, 3] },
                                                    { label: "Atraso", value: "3", delta: "+2", good: false }]))
    assert_selector ".ss-kpis[role=list] .ss-kpi", count: 2
    assert_selector ".ss-kpi .ss-amount"
    assert_selector ".ss-delta.is-good", text: "+5%"
    assert_selector ".ss-delta.is-bad", text: "+2"
    assert_selector ".ss-kpi svg.ss-spark"
  end

  test "área: svg, pontos, ativo e tabela alternativa" do
    c = Ss::AreaChartComponent.new(title: "Gastos", points: [["jan", 10], ["fev", 30], ["mar", 20]], active: 1)
    render_inline(c)
    assert_selector "figure.ss-area[data-controller=ss-chart][data-ss-chart-index-value='1']"
    assert_selector "svg path.ss-area-line"
    assert_selector "text.ss-area-xtext.is-active", text: "fev"
    assert_selector "table.ss-sr caption", text: "Gastos"
    assert_selector "table.ss-sr tbody tr", count: 3
    xs = c.coords.map(&:first)
    assert_equal xs, xs.sort
    assert_operator c.coords[1][1], :<, c.coords[0][1] # maior valor fica mais alto
  end

  test "rosca: fatias somam 100% e legenda clicável" do
    c = Ss::DonutChartComponent.new(title: "Gastos", center: "R$ 100", exploded: true,
                                    slices: [{ label: "A", value: 50 }, { label: "B", value: 30 }, { label: "C", value: 20 }, { label: "Zero", value: 0 }])
    render_inline(c)
    segs = c.segments
    assert_in_delta 100.0, segs.sum { _1[:pct] }, 0.001
    assert_in_delta 50.0, segs[1][:start], 0.001
    assert_operator segs[0][:width], :>, segs[2][:width] # maior fatia mais grossa
    assert_selector "circle.ss-donut-slice", count: 3
    assert_selector "svg[role=img] title", text: /A 50%/
    assert_selector ".ss-donut-legend button[aria-pressed=false]", count: 3
    assert_selector ".ss-donut-center b", text: "R$ 100"
  end

  test "agenda: posição dos blocos e sobrepostos lado a lado" do
    d = Date.new(2026, 11, 4)
    t = ->(h, m = 0) { Time.utc(2026, 11, 4, h, m) }
    ev = [{ title: "A", starts_at: t.(8), ends_at: t.(10) }, { title: "B", starts_at: t.(9), ends_at: t.(11) },
          { title: "C", starts_at: t.(12), ends_at: t.(13) }]
    c = Ss::AgendaComponent.new(days: [d], from: 8, to: 18, now: t.(13, 30), events: ev)
    lay = c.layout(ev).to_h { [_1[:event][:title], _1] }
    assert_equal 0.0, lay["A"][:top]
    assert_equal 20.0, lay["A"][:height]
    assert_equal 10.0, lay["B"][:top]
    assert_equal 50.0, lay["A"][:width]
    assert_equal 50.0, lay["B"][:left]
    assert_equal 100.0, lay["C"][:width]
    assert_equal 40.0, lay["C"][:top]
    assert_equal 55.0, c.now_top(d)
    render_inline(c)
    assert_selector ".ss-agenda-event", count: 3
    assert_selector ".ss-agenda-now"
  end

  test "linha do tempo horizontal e gantt" do
    render_inline(Ss::TimelineHorizontalComponent.new(items: [{ title: "A", date: "1/11", state: :done }, { title: "B", date: "2/11", state: :current }, { title: "C", date: "3/11" }]))
    assert_selector "ol.ss-htl li.is-done", text: "A"
    assert_selector "li.is-current[aria-current=step]"
    s = Date.new(2026, 11, 1)
    g = Ss::GanttComponent.new(start: s, days: 10, today: s + 2, tasks: [{ label: "X", from: s + 1, to: s + 3, progress: 0.5 }, { label: "Fora", from: s + 20, to: s + 22 }])
    render_inline(g)
    assert_equal [3, 6], g.span_for(g.tasks[0])
    assert_selector ".ss-gantt-bar", count: 1
    assert_selector ".ss-gantt-bar[style*='grid-column:3 / 6'][style*='--p:50%']"
    assert_selector ".ss-gantt-day.is-today", text: "3"
  end

  test "árvore, histórico, cotações e comparação" do
    render_inline(Ss::TreeViewComponent.new(nodes: [{ label: "Receitas", value: "R$ 10", count: 2, open: true, children: [{ label: "Vendas", url: "/v" }, { label: "Outras" }] }]))
    assert_selector ".ss-tree[data-controller=ss-tree] details[open] summary .ss-tree-label", text: "Receitas"
    assert_selector "a.ss-tree-row.is-leaf[href='/v'][data-ss-tree-item]"
    assert_selector "span.ss-tree-row.is-leaf[tabindex='-1']", text: "Outras"

    assert_equal [["R$ ", "1.250,00", ""], ["R$ ", "1.320,00", ""]], Ss::AuditTrailComponent.diff("R$ 1.250,00", "R$ 1.320,00")
    render_inline(Ss::AuditTrailComponent.new(entries: [{ who: "Ana Souza", at: Time.utc(2026, 11, 4, 10), action: "alterou", changes: [{ field: "Valor", from: "a b", to: "a c" }, { field: "Tel", from: nil, to: "1" }] }]))
    assert_selector ".ss-audit .ss-avatar"
    assert_selector ".ss-audit-from del", text: "b"
    assert_selector ".ss-audit-to ins", text: "c"
    assert_selector ".ss-audit-none", text: "vazio"
    assert_selector "time[datetime]"

    render_inline(Ss::PriceBoardComponent.new(caption: "Metais", rows: [{ name: "Ouro", buy: "1", sell: "2", delta: "+1%", good: true, highlight: true }]))
    assert_selector "table caption", text: "Metais"
    assert_selector "tr.is-highlight th[scope=row]", text: "Ouro"
    assert_selector ".ss-delta.is-good"

    render_inline(Ss::CompareTableComponent.new(caption: "Planos", plans: [{ name: "A" }, { name: "B", recommended: true }], features: [{ label: "IA", values: [false, true] }]))
    assert_selector "thead th.is-rec", text: "Recomendado"
    assert_selector "td.is-rec .ss-compare-yes"
    assert_selector "td .ss-compare-no .ss-sr", text: "Não incluído"
  end
end
