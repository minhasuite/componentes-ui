require "test_helper"

# v0.12 · agenda que não estoura o card, tile de aparelho com o ícone como chave, cabeçalho de
# card, card de indicador e lista ranqueada (pares do SsDayAgenda(allDay:), SsDeviceTile,
# SsCardHeader, SsKpiCard e SsRankList).
class V12WebTest < ComponentTest
  GEM = Pathname(ComponentesUi::Engine.root)
  CSS = GEM.join("app/assets/tailwind/componentes_ui")

  test "agenda: título inteiro no title e colunas que encolhem" do
    t = Time.zone.local(2026, 11, 9, 15, 0)
    longo = "NOTA TÉCNICA S-1.3 Nº 07/2026 - Implantação em produção restrita"
    render_inline(Ss::AgendaComponent.new(days: [t.to_date], now: t, from: 14, to: 18, events: [
      { title: longo, all_day: true, starts_at: t.to_date },
      { title: "Reunião", sub: "Escritório", starts_at: t + 3600, ends_at: t + 7200 }]))
    assert_selector ".ss-agenda-allday .is-all-day[title='#{longo}']", text: longo
    assert_selector ".ss-agenda-col .ss-agenda-event[title='Reunião · Escritório']"
    css = CSS.join("v12_web.css").read
    ["repeat(var(--days), minmax(0, 1fr))", ".ss-agenda-allday-col { grid-template-columns: minmax(0, 1fr); }", ".ss-agenda-event.is-all-day .ss-agenda-in"].each { assert_includes css, _1 }
    assert_includes CSS.join("engine.css").read, '@import "./v12_web.css";'
  end

  test "tile: o ícone é a chave (switch acessível), texto ao lado, confirmação e estados" do
    render_inline(Ss::DeviceTileComponent.new(name: "Luz da sala", state: "Desligada", url: "/p/1", toggle_url: "/p/1/cmd",
                                              toggle_params: { cmd: "toggle" }, confirm: "Ligar?", confirm_title: "Luz crítica"))
    form = page.find("form.ss-device-toggle-form[action='/p/1/cmd']")
    assert_equal "ss-switch", form["data-controller"]
    assert_equal "Ligar?", form["data-turbo-confirm"]
    assert_equal "Luz crítica", form["data-turbo-confirm-title"]
    assert_equal "Desligar Luz da sala", form["data-ss-switch-on-label-value"]
    assert_selector "form input[type=hidden][name=cmd][value=toggle]", visible: :all
    btn = page.find("button.ss-device-ico.ss-device-toggle")
    assert_equal "switch", btn["role"]
    assert_equal "false", btn["aria-checked"]
    assert_equal "Luz da sala", btn["aria-label"]
    assert_equal "button", btn["data-ss-switch-target"]
    assert_selector "button.ss-device-toggle svg"
    assert_selector "button.ss-device-toggle i.ss-device-spin"
    assert_selector ".ss-device.has-toggle a.ss-device-text[href='/p/1']"
    assert_no_selector ".ss-device-end, .ss-switch"

    # Enviando e indisponível travam a chave; sem permissão não tem chave.
    render_inline(Ss::DeviceTileComponent.new(name: "T", status: :pending, toggle_url: "/t"))
    assert_selector ".ss-device[data-status=pending] button.ss-device-toggle[disabled]"
    render_inline(Ss::DeviceTileComponent.new(name: "T", status: :locked, toggle_url: "/t"))
    assert_selector "span.ss-device-ico"
    assert_no_selector "button.ss-device-toggle"
    # Sem toggle_url (sensor): ícone decorativo.
    render_inline(Ss::DeviceTileComponent.new(name: "Temperatura", state: "24 °C", url: "/p"))
    assert_selector "span.ss-device-ico[aria-hidden=true]"
    assert_no_selector "form"

    I18n.with_locale(:en) { render_inline(Ss::DeviceTileComponent.new(name: "Lamp", on: true, toggle_url: "/t")) }
    assert_selector "button.ss-device-toggle[aria-checked=true][title='Turn off Lamp']"
  end

  test "controller ss-switch usa aria-checked no role=switch" do
    js = GEM.join("app/javascript/componentes_ui/controllers/ss_switch_controller.js").read
    assert_includes js, 'getAttribute("role") === "switch" ? "aria-checked" : "aria-pressed"'
    css = CSS.join("v12_web.css").read
    %w[.ss-device-toggle .ss-device-toggle:focus-visible prefers-reduced-motion].each { assert_includes css, _1 }
  end

  test "cabeçalho de card: título, linha menor, ícone tonal ou ação" do
    render_inline(Ss::CardHeaderComponent.new(title: "Consumo", subtitle: "Mês · 401 kWh", icon: "<svg></svg>", tone: :warn, heading: :h3))
    assert_selector ".ss-card-head h3.ss-card-title", text: "Consumo"
    assert_selector ".ss-card-head p.ss-card-sub", text: "Mês · 401 kWh"
    assert_selector ".ss-card-head-icon[aria-hidden=true][style='--tone: var(--warn)'] svg"
    render_inline(Ss::CardHeaderComponent.new(title: "Agenda", icon: "<svg></svg>", tone: "x;}y")) { |h| h.with_action { "Ver tudo" } }
    assert_selector ".ss-card-head-action", text: "Ver tudo"
    assert_no_selector ".ss-card-head-icon, .ss-card-sub"
  end

  test "card de indicador: cabeçalho padrão, valor, variação e link" do
    render_inline(Ss::KpiCardComponent.new(label: "Gasto do mês", value: "R$ 312,75", money: true, icon: "<svg></svg>", caption: "01/11 a 30/11",
                                           delta: "+4%", good: false, hint: "vs. outubro", spark: [1, 3, 2], url: "/energia"))
    assert_selector ".ss-card.ss-kpi-card.is-link .ss-card-head .ss-card-title a.ss-kpi-card-link[href='/energia']", text: "Gasto do mês"
    assert_selector ".ss-card-sub", text: "01/11 a 30/11"
    assert_selector ".ss-kpi-card-value .ss-amount small", text: ",75"
    assert_selector ".ss-kpi-card-foot .ss-delta.is-bad[aria-label='Variação +4% (ruim)']"
    assert_selector ".ss-kpi-card-foot small", text: "vs. outubro"
    assert_selector ".ss-kpi-card-spark svg"
    render_inline(Ss::KpiCardComponent.new(label: "Ligados", value: "12"))
    assert_selector ".ss-kpi-card:not(.is-link) .ss-kpi-card-value .num", text: "12"
    assert_no_selector ".ss-kpi-card-foot, .ss-kpi-card-spark, .ss-card-head-icon"
  end

  test "lista ranqueada: posição, barra proporcional ao maior, fatia e linha menor" do
    render_inline(Ss::RankListComponent.new(tone: :warn, label: "Consumo por aparelho", items: [
      { label: "Ar", value: "160 kWh", amount: 160, share: "40%", caption: "R$ 150,00", url: "/a" },
      { label: "Chuveiro", value: "80 kWh", amount: 80, share: "20%" },
      { label: "Relógio", value: "0 kWh", amount: 0 }]))
    assert_selector "ol.ss-rank[aria-label='Consumo por aparelho'][style*='--tone: var(--warn)'] > li.ss-rank-item", count: 3
    assert_selector "li.ss-rank-item[style*='--w: 100.0%'] a.ss-rank-link[href='/a']", text: "Ar"
    assert_selector "li.ss-rank-item[style*='--w: 50.0%']", text: "Chuveiro"
    assert_selector "li.ss-rank-item[style*='--w: 2']", text: "Relógio"
    assert_selector ".ss-rank-n[aria-hidden=true]", text: "1"
    assert_selector ".ss-rank-value b", text: "160 kWh"
    assert_selector ".ss-rank-value small", text: "· 40%"
    assert_selector ".ss-rank-caption", text: "R$ 150,00"
    render_inline(Ss::RankListComponent.new(numbered: false, items: [{ label: "X", value: "1" }]))
    assert_selector "ol.ss-rank.is-plain[aria-label=Ranking]"
    assert_no_selector ".ss-rank-n, .ss-rank-bar"
    I18n.with_locale(:es) { render_inline(Ss::RankListComponent.new(items: [])) }
    assert_selector "ol.ss-rank[aria-label=Ranking]"
  end
end
