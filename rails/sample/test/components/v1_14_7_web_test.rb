require "test_helper"

# v1.14.7 · gráficos com tudo zero (o SsBarChart do meu-tempo-app com 7 dias sem uso) e a escala redonda de todas as
# peças (ComponentesUi::ChartScale). Os casos da escala são os mesmos do flutter/test/v1147_test.dart.
class V1147WebTest < ComponentTest
  REPO = Pathname(ComponentesUi::Engine.root).join("..")
  CS = ComponentesUi::ChartScale
  DIAS = %w[seg ter qua qui sex sáb dom].freeze
  ZEROS = [0] * 7
  VAZIO = "Sem dados no período".freeze
  # O formatter do app que arredonda (minutos inteiros): o que fazia o eixo dizer "1 min, 1 min".
  MIN = ->(v) { "#{v.round} min" }

  test "versão 1.14.7" do
    assert_equal "1.14.7", ComponentesUi::VERSION
    assert_includes REPO.join("flutter/pubspec.yaml").read, "version: 1.14.7"
    assert_includes REPO.join("README.md").read, "ref: v1.14.7"
    assert_includes REPO.join("README.md").read, "## v1.14.7"
  end

  # ── a escala (mesmos casos do SsChartScale) ──────────────────────────
  test "passo redondo: 1, 2, 2,5, 5 × 10ⁿ" do
    assert_equal [1.0, 2.0, 2.5, 5.0, 10.0, 0.002], [0.7, 1.2, 2.2, 3, 7, 0.0013].map { CS.nice_step(_1) }
    assert_equal 2.5, CS.next_step(2)
    assert_equal 10.0, CS.next_step(5)
  end

  test "tudo zero: 0 a 1, sem guia repetida" do
    e = CS.of(0, 0)
    assert_equal [0.0, 1.0, [0.0, 0.5, 1.0]], [e.lo, e.hi, e.ticks]
  end

  test "todos iguais (3): de 0 a 3; sem o zero, em volta do 3" do
    assert_equal [0.0, 1.0, 2.0, 3.0], CS.of(3, 3).ticks
    assert_equal [2.5, 3.0, 3.5], CS.of(3, 3, zero: false).ticks
  end

  test "um só valor (7): de 2,5 em 2,5" do
    e = CS.of(0, 7)
    assert_equal [7.5, 2.5, [0.0, 2.5, 5.0, 7.5]], [e.hi, e.step, e.ticks]
  end

  test "valores minúsculos: passo redondo e sem ruído do ponto flutuante" do
    assert_equal [0.0, 0.001, 0.002, 0.003], CS.of(0, 0.003).ticks
    assert_equal [0.0, 0.1, 0.2, 0.3], CS.of(0, 0.3).ticks
  end

  test "negativo: o zero dentro, até 3 faixas" do
    assert_equal [-400.0, -200.0, 0.0, 200.0], CS.of(-250, 100).ticks
    assert_equal [-400.0, -200.0, 200.0], CS.of(-250, 100).guides
  end

  test "formatter que arredonda: o passo cresce até nenhum rótulo repetir" do
    assert_equal [0.0, 1.0], CS.of(0, 1, format: MIN).ticks
    assert_equal [0.0, 0.5], CS.of(0, 0.4, format: MIN).ticks
  end

  test "max: é o topo mínimo; valor acima alarga" do
    assert_equal [0.0, 20.0, 40.0], CS.of(3, 5, top: 40).ticks
    assert_equal 60.0, CS.of(3, 50, top: 40).hi
  end

  test "casas decimais do passo e tudo zero" do
    assert_equal [1, 2, 3, 0, 0], [2.5, 0.25, 0.001, 50, 1].map { CS.decimals(_1) }
    assert CS.all_zero?([0, nil, 0])
    assert CS.all_zero?([])
    refute CS.all_zero?([0, 0.01])
  end

  # ── BarChartComponent ────────────────────────────────────────────────
  test "BarChart com tudo zero: o vazio de sempre (empty:, ou o padrão)" do
    render_inline(Ss::BarChartComponent.new(title: "Uso", labels: DIAS, series: [{ name: "Uso", values: ZEROS }], empty: "Sem uso nesta semana"))
    assert_selector "figure.ss-barc.is-empty p.ss-chart-empty", text: "Sem uso nesta semana"
    assert_no_selector "svg"

    render_inline(Ss::BarChartComponent.new(title: "Uso", labels: DIAS, series: [{ name: "Uso", values: ZEROS }]))
    assert_selector "p.ss-chart-empty", text: VAZIO
  end

  test "BarChart: a linha com valor não é vazio; treat_zero_as_empty: false desenha no chão" do
    render_inline(Ss::BarChartComponent.new(title: "t", labels: DIAS, series: [{ name: "x", values: ZEROS }], line: { name: "s", values: [0, 0, 2, 0, 0, 0, 0] }))
    assert_no_selector "p.ss-chart-empty"
    render_inline(Ss::BarChartComponent.new(title: "t", labels: DIAS, series: [{ name: "x", values: ZEROS }], treat_zero_as_empty: false, format: MIN))
    assert_no_selector "p.ss-chart-empty"
    assert_selector "svg line.ss-barc-zero", visible: :all
    textos = page.all("text.ss-barc-ytext", visible: :all).map(&:text)
    assert_equal textos.uniq, textos
  end

  test "BarChart: guias redondas e sem \"1 min, 1 min\" com o formatter que arredonda" do
    c = Ss::BarChartComponent.new(title: "t", labels: DIAS, series: [{ name: "x", values: [1, 0, 0, 1, 0, 0, 0] }], format: MIN)
    assert_equal [0.0, 1.0], c.range
    render_inline(c)
    assert_equal ["1 min"], page.all("text.ss-barc-ytext", visible: :all).map(&:text)
  end

  test "BarChart: todos iguais e um só valor com topo redondo" do
    tres = Ss::BarChartComponent.new(title: "t", labels: %w[a b c], series: [{ name: "x", values: [3, 3, 3] }])
    assert_equal [1.0, 2.0, 3.0], tres.scale.guides
    um = Ss::BarChartComponent.new(title: "t", labels: %w[a], series: [{ name: "x", values: [7] }])
    assert_equal [2.5, 5.0, 7.5], um.scale.guides
  end

  # ── as peças irmãs ───────────────────────────────────────────────────
  test "LineChart: tudo zero é vazio; com valor, guias sem repetir" do
    render_inline(Ss::LineChartComponent.new(title: "t", labels: DIAS, series: [{ name: "x", values: ZEROS }]))
    assert_selector "figure.ss-linec.is-empty p.ss-chart-empty", text: VAZIO
    render_inline(Ss::LineChartComponent.new(title: "t", labels: %w[a b c], series: [{ name: "x", values: [0.2, 0.4, 0.3] }], format: MIN))
    textos = page.all("text.ss-barc-ytext, text.ss-linec-ytext", visible: :all).map(&:text)
    assert_equal textos.uniq, textos
    render_inline(Ss::LineChartComponent.new(title: "t", labels: DIAS, series: [{ name: "x", values: ZEROS }], treat_zero_as_empty: false))
    assert_no_selector "p.ss-chart-empty"
  end

  test "AreaChart, DonutChart e FloatingBars: tudo zero é vazio" do
    render_inline(Ss::AreaChartComponent.new(title: "t", points: DIAS.zip(ZEROS)))
    assert_selector "figure.ss-area.is-empty p.ss-chart-empty", text: VAZIO
    area = Ss::AreaChartComponent.new(title: "t", points: [["a", 3], ["b", 3]])
    assert_equal [2.5, 3.0, 3.5], area.guides.map(&:last)

    render_inline(Ss::DonutChartComponent.new(title: "t", slices: [{ label: "Mercado", value: 0 }, { label: "Lazer", value: 0 }], empty: "Sem gastos"))
    assert_selector "figure.ss-donut.is-empty p.ss-chart-empty", text: "Sem gastos"

    render_inline(Ss::FloatingBarsComponent.new(title: "Gastos", values: ZEROS, labels: DIAS))
    assert_selector ".ss-fbars p.ss-fbars-empty", text: VAZIO
    assert_no_selector ".ss-fbars-row"
    render_inline(Ss::FloatingBarsComponent.new(title: "Gastos", values: ZEROS, labels: DIAS, treat_zero_as_empty: false))
    assert_selector ".ss-fbars-row"
  end

  test "DivergingBars: tudo zero é vazio; um negativo só vai inteiro para a esquerda" do
    render_inline(Ss::DivergingBarsComponent.new(items: [{ label: "Café", value: 0 }, { label: "Tomate", value: 0 }]))
    assert_selector "p.ss-chart-empty", text: VAZIO
    render_inline(Ss::DivergingBarsComponent.new(items: [{ label: "Tomate", value: -0.6 }]))
    assert_no_selector "p.ss-chart-empty"
    assert_selector "li[data-side=down][style*='--f: 1.0']"
    assert_selector ".num", text: "−0,6"
  end

  test "PeriodCompare: os dois períodos zero mostram o vazio no lugar do gráfico" do
    render_inline(Ss::PeriodCompareComponent.new(title: "Gastos", labels: DIAS, current: ZEROS, previous: ZEROS, empty: "Sem gastos"))
    assert_selector ".ss-period p.ss-chart-empty", text: "Sem gastos"
  end

  test "TimeSeriesChart: só leituras zero é o vazio" do
    t0 = Time.zone.local(2026, 11, 20, 8)
    pts = (0..4).map { |i| [t0 + i.hours, 0] }
    render_inline(Ss::TimeSeriesChartComponent.new(title: "Uso", series: [{ name: "Uso", points: pts }]))
    assert_selector "figure.ss-tc.is-empty"
    render_inline(Ss::TimeSeriesChartComponent.new(title: "Uso", series: [{ name: "Uso", points: pts }], treat_zero_as_empty: false))
    assert_no_selector "figure.ss-tc.is-empty"
  end

  test "catálogo: o estado sem dados (tudo zero) do BarChart nos dois lados" do
    assert REPO.join("rails/catalogo/index.html").read.include?(%(data-estado="sem-dados-zero")), "falta no rails/catalogo/index.html"
    assert REPO.join("flutter/test/catalogo_v15.dart").read.include?("'sem-dados-zero'"), "falta no catalogo_v15.dart"
  end
end
