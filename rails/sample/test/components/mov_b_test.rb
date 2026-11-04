require "test_helper"

# Movimento (lote B): os componentes ligam o ss-in-view sem perder o controller do app,
# o CountUp ganha roll e o quadro de cotações vigia as células.
class MovBTest < ComponentTest
  test "cards e listas ligam o ss-in-view (e mantêm o controller do app)" do
    render_inline(Ss::ProductCardComponent.new(name: "Costela", price: "R$ 89,90", data: { controller: "carrinho" }))
    assert_selector ".ss-product[data-controller='carrinho ss-in-view']"
    render_inline(Ss::ReviewCardComponent.new(name: "Carla", text: "Bom"))
    assert_selector ".ss-review[data-controller=ss-in-view]"
    render_inline(Ss::TimelineHorizontalComponent.new(items: [{ title: "A", state: :done }]))
    assert_selector "ol.ss-htl[data-controller=ss-in-view][data-ss-in-view-stagger-value=true]"
    render_inline(Ss::AuditTrailComponent.new(entries: [{ who: "Ana", at: "ontem", action: "criou" }]))
    assert_selector "ol.ss-audit[data-ss-in-view-stagger-value=true]"
    render_inline(Ss::EmptyStateComponent.new(title: "Nada", variant: :busca))
    assert_selector ".ss-empty-state[data-variant=busca][data-controller=ss-in-view]"
  end

  test "planos e marcos ganham --i para a cascata" do
    render_inline(Ss::PricingTableComponent.new(plans: [{ name: "A", monthly: "R$ 1,00" }, { name: "B", monthly: "R$ 2,00" }]))
    assert_selector ".ss-pricing[data-controller=ss-in-view] .ss-pricing-plan[style='--i:1']", text: "B"
  end

  test "KPIs contam quando o texto é número e ficam parados quando não é" do
    render_inline(Ss::KpiStripComponent.new(items: [
      { label: "Vendido", value: "R$ 48.320,00", money: true }, { label: "Meta", value: "92,4%" },
      { label: "Pedidos", value: "214" }, { label: "Mil", value: "1,2 mil" }, { label: "Fixo", value: "77", count: false }
    ]))
    assert_selector ".ss-kpis[data-controller=ss-in-view] .ss-kpi[style='--i:0']"
    assert_selector ".ss-kpi .ss-count-up[data-ss-count-up-format-value=money][data-ss-count-up-value-value='48320.0']"
    assert_selector ".ss-kpi .ss-count-up[data-ss-count-up-format-value=percent][data-ss-count-up-decimals-value='1']"
    assert_selector ".ss-kpi .ss-count-up[data-ss-count-up-value-value='214.0'][data-ss-count-up-decimals-value='0']"
    assert_selector ".ss-kpi .ss-count-up", count: 3
    assert_selector ".ss-kpi-value .num", text: "1,2 mil"
  end

  test "CountUp com roll e cotações no modo vigia" do
    render_inline(Ss::CountUpComponent.new(value: 10, roll: true))
    assert_selector ".ss-count-up[data-ss-count-up-roll-value=true]"
    render_inline(Ss::CountUpComponent.new(value: 10))
    assert_no_selector "[data-ss-count-up-roll-value]"
    render_inline(Ss::PriceBoardComponent.new(caption: "M", rows: [{ name: "Ouro", buy: "R$ 1,00", sell: "R$ 2,00" }]))
    assert_selector ".ss-prices[data-controller=ss-count-up][data-ss-count-up-watch-value='td.num']"
  end

  test "gráficos mantêm o controller deles e o painel fecha animando" do
    render_inline(Ss::AreaChartComponent.new(title: "x", points: [["a", 1], ["b", 2]]))
    assert_selector "figure.ss-area[data-controller=ss-chart] path.ss-area-line[pathlength='1']"
    render_inline(Ss::DrawerComponent.new(id: "p", title: "P"))
    assert_selector "dialog#p form[method=dialog] button[data-action='ss-drawer#close']", visible: :all
    render_inline(Ss::LevelCardComponent.new(points: 4860, level: 3, next_at: 6000))
    assert_selector ".ss-level[data-controller=ss-in-view] .ss-level-points .ss-count-up"
  end
end
