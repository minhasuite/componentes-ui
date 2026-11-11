require "test_helper"

# v0.20 · projeção no gráfico de barras: a segunda linha, tracejada, do que ainda vai acontecer (saldo projetado
# de hoje ao fim do mês), com legenda, dica, tabela para leitor de tela e a faixa do eixo.
class ProjecaoWebTest < ComponentTest
  def chart(**opts)
    Ss::BarChartComponent.new(title: "Fluxo", labels: %w[1 2 3 4],
                              series: [{ name: "Receitas", values: [100, 0, 0, 0], tone: :success }],
                              line: { name: "Saldo", values: [100, 80, nil, nil], tone: :accent }, **opts)
  end

  test "projection: linha tracejada, ponto só no fim, legenda tracejada e a cor da linha por padrão" do
    render_inline(chart(projection: { name: "Projeção", values: [nil, 80, 40, 120] }))
    assert_selector "path.ss-barc-line", count: 1
    assert_selector "path.ss-barc-proj[style*='var(--accent)']", count: 1
    assert_selector "circle.ss-barc-dot.is-proj", count: 1
    assert_selector ".ss-barc-legend li.is-dashed", text: "Projeção"
    assert_selector "g.ss-barc-g:nth-of-type(3) title", text: /Projeção: 40/
    assert_no_selector "g.ss-barc-g:nth-of-type(1) title", text: /Projeção/
  end

  test "projection: entra na tabela para leitor de tela, com — onde não há ponto" do
    render_inline(chart(projection: { name: "Projeção", values: [nil, 80, 40, 120], tone: :warn }))
    assert_selector "table.ss-sr thead th", text: "Projeção"
    assert_selector "table.ss-sr tbody tr:first-child td:last-child", text: "—"
    assert_selector "table.ss-sr tbody tr:last-child td:last-child", text: "120"
    assert_selector "path.ss-barc-proj[style*='var(--warn)']"
  end

  test "projection_from: ignora o que vem antes do índice e a projeção alarga a faixa" do
    c = chart(projection: { name: "Projeção", values: [-900, 80, 40, 500] }, projection_from: 1)
    assert_nil c.projection[:values][0]
    assert_operator c.range[1], :>, 500
    assert_equal 0.0, c.range[0]
    render_inline(c)
    assert_selector "table.ss-sr tbody tr:first-child td:last-child", text: "—"
  end

  test "sem projection: nada muda (API antiga)" do
    render_inline(chart)
    assert_no_selector "path.ss-barc-proj"
    assert_no_selector ".ss-barc-legend li.is-dashed"
    assert_selector "table.ss-sr thead th", count: 3
  end

  test "projeção de um ponto só não desenha caminho" do
    render_inline(chart(projection: { name: "Projeção", values: [nil, nil, nil, 10] }))
    assert_no_selector "path.ss-barc-proj"
  end
end
