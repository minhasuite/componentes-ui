require "test_helper"

# v0.10 (dados): gráfico de séries no tempo, faixas de estado e logbook.
class V10DadosTest < ComponentTest
  T0 = Time.zone.parse("2026-11-04 10:00")

  def serie(name = "Sala", unit: "°C", pts: nil, **extra)
    { name:, unit:, points: pts || [[T0, 20.0], [T0 + 10.minutes, 22.0], [T0 + 20.minutes, nil], [T0 + 40.minutes, 25.0]], **extra }
  end

  def luz
    { label: "Luz", current: "Desligada",
      segments: [{ from: T0, to: T0 + 150.minutes, state: "on", label: "Ligada" },
                 { from: T0 + 150.minutes, to: T0 + 240.minutes, state: "off", label: "Desligada" }] }
  end

  # ── apoio ──
  test "duração curta e tom pelo estado" do
    assert_equal "2 h 30 min", Ss::TimeData.duration(150 * 60, :"pt-BR")
    assert_equal "45 min", Ss::TimeData.duration(45 * 60, :"pt-BR")
    assert_equal "2 d 4 h", Ss::TimeData.duration(52 * 3600, :"pt-BR")
    assert_equal "2h 30m", Ss::TimeData.duration(150 * 60, :en)
    assert_equal "accent", Ss::TimeData.tone_for("on")
    assert_equal "neutral", Ss::TimeData.tone_for("closed")
    assert_equal "danger", Ss::TimeData.tone_for("error")
    assert_nil Ss::TimeData.tone_for("cleaning")
    assert_equal "success", Ss::TimeData.tone_for("cleaning", { "cleaning" => :success })
    rows = [{ segments: [{ state: "on" }, { state: "cleaning" }, { state: "docked" }] }]
    assert_equal({ "on" => "accent", "cleaning" => "s2", "docked" => "s3" }, Ss::TimeData.tones_of(rows))
  end

  # ── gráfico ──
  test "gráfico: dados do controller, eixo por série e resumo para o leitor de tela" do
    render_inline(Ss::TimeSeriesChartComponent.new(title: "Clima", series: [serie, serie("Umidade", unit: "%", pts: [[T0, 60], [T0 + 30.minutes, 58.5]])],
                                                   zoom_url: "/historico"))
    fig = page.find("figure.ss-tc[data-controller~='ss-time-chart']")
    assert_equal T0.to_i * 1000, fig["data-ss-time-chart-from-value"].to_i
    assert_equal (T0 + 40.minutes).to_i * 1000, fig["data-ss-time-chart-to-value"].to_i
    assert_equal "/historico", fig["data-ss-time-chart-zoom-url-value"]
    dados = JSON.parse(fig["data-ss-time-chart-series-value"])
    assert_equal ["Sala", "Umidade"], dados.map { _1["name"] }
    assert_equal [T0.to_i * 1000, 20.0], dados[0]["pts"][0]
    assert_nil dados[0]["pts"][2][1], "buraco vira null"
    assert_equal "var(--series-2)", dados[1]["color"]
    assert_selector ".ss-tc-plot[tabindex='0'][role=group][aria-roledescription]"
    assert_selector ".ss-tc-legend button[aria-pressed=true]", count: 2
    assert_selector ".ss-tc-reset[hidden]", visible: :all
    sumario = page.find(".ss-sr[id$='-sum']", visible: :all).text(:all)
    assert_includes sumario, "Clima, 04/11 10:00 a 04/11 10:40"
    assert_includes sumario, "Sala: mínimo 20 °C, máximo 25 °C, último 25 °C"
    assert_includes sumario, "Umidade: mínimo 58,5%, máximo 60%"
  end

  test "gráfico: uma série não tem legenda; carregando e vazio" do
    render_inline(Ss::TimeSeriesChartComponent.new(title: "Sala", series: [serie]))
    assert_no_selector ".ss-tc-legend"
    render_inline(Ss::TimeSeriesChartComponent.new(title: "Energia", loading: true))
    assert_selector "figure.ss-tc.is-loading[aria-busy=true] .ss-tc-skel"
    render_inline(Ss::TimeSeriesChartComponent.new(title: "Energia", series: [serie(pts: [])]))
    assert_selector ".ss-tc.is-empty .ss-tc-empty", text: "Sem leituras neste período"
    render_inline(Ss::TimeSeriesChartComponent.new(title: "Energia", series: [], texts: { empty: "Nada ainda" }))
    assert_selector ".ss-tc-empty", text: "Nada ainda"
  end

  test "gráfico: faixas dentro, no mesmo eixo, sem controller próprio" do
    render_inline(Ss::TimeSeriesChartComponent.new(title: "Casa", series: [serie], bands: [luz], from: T0, to: T0 + 4.hours, mode: :step))
    assert_equal "step", page.find("figure.ss-tc")["data-ss-time-chart-mode-value"]
    band = page.find(".ss-tc-bands .ss-sb.is-embedded.is-top[data-ss-time-chart-target=bands]")
    refute_includes band["data-controller"].to_s, "ss-state-bands"
    assert_selector ".ss-sb-fill > i[data-tone=accent][data-label=Ligada][style*='left:0.0%'][style*='62.5%']"
    assert_no_selector ".ss-sb-axis"
  end

  test "gráfico: agregado (min/max) e locale" do
    render_inline(Ss::TimeSeriesChartComponent.new(title: "x", locale: :en,
                                                   series: [serie(pts: [{ t: T0, v: 1234.5, min: 1000, max: 1500 }, [T0 + 1.hour, 1300.0]], decimals: 1)]))
    fig = page.find("figure.ss-tc")
    assert_equal "en", fig["data-ss-time-chart-lang-value"]
    assert_equal [T0.to_i * 1000, 1234.5, 1000.0, 1500.0], JSON.parse(fig["data-ss-time-chart-series-value"])[0]["pts"][0]
    assert_includes page.find(".ss-sr[id$='-sum']", visible: :all).text(:all), "1,234.5 °C"
  end

  # ── faixas ──
  test "faixas: posição, tom, balão nativo e resumo por linha" do
    render_inline(Ss::StateBandsComponent.new(title: "Luzes", rows: [luz, { label: "Aspirador", segments: [{ from: T0, to: T0 + 1.hour, state: "cleaning" }] }]))
    root = page.find(".ss-sb[role=group][aria-label=Luzes]")
    assert_includes root["data-controller"], "ss-state-bands"
    assert_includes root["data-controller"], "ss-in-view"
    seg = page.find(".ss-sb-fill > i[data-state=on]")
    assert_equal "accent", seg["data-tone"]
    assert_includes seg["title"], "Ligada · 04/11 10:00 – 12:30 · 2 h 30 min"
    assert_equal "neutral", page.find(".ss-sb-fill > i[data-state=off]")["data-tone"]
    assert_equal "s2", page.find(".ss-sb-fill > i[data-state=cleaning]")["data-tone"]
    assert_selector ".ss-sb-bar[tabindex='0'][aria-label='Luz: Ligada 2 h 30 min, Desligada 1 h 30 min. Desligada']"
    assert_selector ".ss-sb-now", text: "Desligada"
    assert_selector ".ss-sb-axis[data-ss-state-bands-target=axis]"
    assert_selector ".ss-sb-tip[hidden]", visible: :all
  end

  test "faixas: nome em cima, tons do app, linha sem leituras e vazio" do
    render_inline(Ss::StateBandsComponent.new(rows: [luz, { label: "Porta", segments: [] }], tones: { "on" => :success }, label_position: :top, from: T0, to: T0 + 4.hours))
    assert_selector ".ss-sb.is-top"
    assert_equal "success", page.find(".ss-sb-fill > i[data-state=on]")["data-tone"]
    assert_selector ".ss-sb-none", text: "sem leituras"
    render_inline(Ss::StateBandsComponent.new(rows: []))
    assert_selector ".ss-sb-empty[role=status]", text: "Nenhuma mudança neste período"
  end

  # ── logbook ──
  def eventos(now)
    [{ at: now - 1.hour, title: "Luz ligada", detail: "pela automação", icon: "light", tone: :accent, state: "Ligada", href: "/p/1" },
     { at: now - 2.hours, title: "Porta aberta", icon: "door", tone: :warning },
     { at: now - 1.day, title: "Alarme armado", tone: :success },
     { at: now - 2.days, title: "Cena", icon: "<svg class='meu'></svg>".html_safe }]
  end

  test "logbook: dias (Hoje, Ontem, data), linha e fim" do
    now = Time.zone.parse("2026-11-04 14:30")
    render_inline(Ss::LogbookComponent.new(entries: eventos(now), now: now))
    assert_selector ".ss-lb[role=feed][data-controller=ss-logbook]"
    assert_equal ["Hoje", "Ontem", "seg, 02/11"], page.all(".ss-lb-head").map(&:text)
    assert_selector ".ss-lb-day[data-day='2026-11-04'] article.ss-lb-item", count: 2
    item = page.find("article.ss-lb-item", match: :first)
    assert_equal "accent", item["data-tone"]
    assert_selector "time.ss-lb-time[datetime]", text: "13:30"
    assert_selector "a.ss-lb-link[href='/p/1'][data-turbo-frame=_top]", text: "Luz ligada"
    assert_selector ".ss-lb-state", text: "Ligada"
    assert_selector ".ss-lb-detail", text: "pela automação"
    assert_selector "article[data-tone=warn]" # :warning vira warn
    assert_selector ".ss-lb-ico svg.meu"
    assert_selector ".ss-lb-foot.is-end", text: "Início do registro"
  end

  test "logbook: carregar mais em turbo-frame (lazy e botão) e a página seguinte" do
    now = Time.zone.parse("2026-11-04 14:30")
    render_inline(Ss::LogbookComponent.new(entries: eventos(now), now: now, more_url: "/logbook?pg=2"))
    assert_selector "turbo-frame.ss-lb-more[src='/logbook?pg=2'][loading=lazy]", text: "Carregando…"
    render_inline(Ss::LogbookComponent.new(entries: eventos(now), now: now, more_url: "/logbook?pg=2", lazy: false))
    frame = page.find("turbo-frame.ss-lb-more")
    assert_nil frame[:src]
    assert_selector "turbo-frame##{frame[:id]} a.ss-btn[href='/logbook?pg=2'][data-turbo-frame='#{frame[:id]}']", text: "Carregar mais"
    render_inline(Ss::LogbookComponent.new(entries: eventos(now).first(1), now: now, frame: "ss-lb-abc"))
    assert_selector "turbo-frame#ss-lb-abc .ss-lb-day article", count: 1
    assert_no_selector ".ss-lb[role=feed]"
  end

  test "logbook: carregando, vazio e erro" do
    render_inline(Ss::LogbookComponent.new(entries: [], loading: true))
    assert_selector ".ss-lb.is-loading[aria-busy=true] .ss-lb-ghost", count: 6
    render_inline(Ss::LogbookComponent.new(entries: []))
    assert_text "Nada registrado ainda"
    render_inline(Ss::LogbookComponent.new(entries: [], error: "Falhou", retry_url: "/x"))
    assert_selector ".ss-lb.is-error[role=alert]", text: "Falhou"
    assert_selector "a.ss-btn[href='/x']", text: "Tentar de novo"
    render_inline(Ss::LogbookComponent.new(entries: [], texts: { empty: "Sem eventos" }))
    assert_text "Sem eventos"
  end
end
