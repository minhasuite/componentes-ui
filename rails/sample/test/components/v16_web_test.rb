require "test_helper"

# v0.16 · o que a migração do minhas-compras e do minhas-viagens pediu, no lado web: legenda de
# gráfico, barras divergentes, estrelas (leitura e campo), comparação com o melhor valor, alvo e
# menor no minigráfico, anel em gomos com aviso, alto contraste gerado das paletas, a série em
# variante de texto e etiqueta/chip que não estouram.
class V16WebTest < ComponentTest
  include ComponentesUi::Helpers

  CSS = Pathname(ComponentesUi::Engine.root).join("app/assets/tailwind/componentes_ui")

  def luminancia(hex)
    hex.delete("#").scan(/../).map { |c| c.to_i(16) / 255.0 }.map { |v| v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055)**2.4 }
       .zip([0.2126, 0.7152, 0.0722]).sum { |v, k| v * k }
  end

  def contraste(a, b)
    la, lb = luminancia(a), luminancia(b)
    ([la, lb].max + 0.05) / ([la, lb].min + 0.05)
  end

  test "ChartLegendComponent: cor por tom, série ou cor; valor em mono; traço e tracejado" do
    render_inline(Ss::ChartLegendComponent.new(items: [
      { label: "Atacadão" }, { label: "menor", value: "R$ 2.148", tone: :success },
      { label: "alvo", value: "R$ 1.990", tone: :muted, line: true, dashed: true }, { label: "Extra", color: "#123456" },
      { label: "Atacadão" }
    ]))
    assert_selector "ul.ss-legend > li", count: 4
    assert_selector "li[style='--c: var(--series-1)'] span", text: "Atacadão"
    assert_selector "li[style='--c: var(--success)'] b.num", text: "R$ 2.148"
    assert_selector "li.is-line.is-dashed[style='--c: var(--muted)']"
    assert_selector "li[style='--c: #123456']"
    assert_selector "li > i[aria-hidden=true]", count: 4
    render_inline(Ss::ChartLegendComponent.new(items: [{ label: "x", color: "red;}</style>" }]))
    assert_selector "li[style='--c: var(--series-1)']"
  end

  test "DivergingBarsComponent: lado, tom, fração do maior, sinal no idioma e unidade" do
    render_inline(Ss::DivergingBarsComponent.new(unit: "p.p.", items: [
      { label: "Café torrado", value: 1.8, detail: "+32% · 9% da cesta" }, { label: "Tomate", value: -0.6 }, { label: "Arroz", value: 0 }
    ]))
    assert_selector "ul.ss-diverging[data-controller~=ss-in-view] > li", count: 3
    assert_selector "li[data-side=up][data-tone=bad][style*='--f: 1.0'] .ss-diverging-head span.num", text: "+1,8 p.p."
    assert_selector "li[data-side=down][data-tone=good][style*='--f: 0.333'] span.num", text: "−0,6 p.p."
    assert_selector "li[data-tone=flat] span.num", text: "0 p.p."
    assert_selector "li small", text: "+32% · 9% da cesta"
    assert_selector ".ss-diverging-bar[aria-hidden=true] > i", count: 3
    render_inline(Ss::DivergingBarsComponent.new(up_is_good: true, format: ->(v) { "#{v}x" }, items: [{ label: "Receita", value: 2 }]))
    assert_selector "li[data-tone=good] span.num", text: "2x"
    render_inline(Ss::DivergingBarsComponent.new(items: []))
    assert_no_selector ".ss-diverging"
  end

  test "RatingComponent: leitura com meia e --max; campo com um rádio por estrela" do
    render_inline(Ss::RatingComponent.new(value: 4.5))
    assert_selector "span.ss-stars[role=img][aria-label='Nota 4,5 de 5'][style*='--v: 4.5'][style*='--max: 5']"
    render_inline(Ss::RatingComponent.new(value: 3, max: 10, size: :lg))
    assert_selector "span.ss-stars[aria-label='Nota 3 de 10'][style*='--star-size: 2rem']"
    render_inline(Ss::RatingComponent.new(name: "review[rating]", value: 4, label: "Sua nota", id: "r"))
    assert_selector "fieldset.ss-rating > legend.ss-sr", text: "Sua nota"
    assert_selector "fieldset.ss-rating input[type=radio][name='review[rating]']", count: 5
    assert_selector "input#r-4[value='4'][checked]"
    assert_selector "label[for=r-1][title='1 estrela'] svg"
    assert_selector "label[for=r-3] .ss-sr", text: "3 estrelas"
    I18n.with_locale(:en) do
      render_inline(Ss::RatingComponent.new(value: 2))
      assert_selector ".ss-stars[aria-label='Rating 2 of 5']"
    end
  end

  test "CompareTableComponent: best: pinta a célula e mono: false tira o .num" do
    render_inline(Ss::CompareTableComponent.new(caption: "Destinos", plans: [{ name: "Lisboa" }, { name: "Porto", recommended: true }],
      features: [{ label: "Total", values: ["R$ 8.000", "R$ 7.200"], best: 1 }, { label: "Visto", values: ["não precisa", "não precisa"], mono: false }]))
    assert_selector "td.is-rec.is-best > span.num", text: "R$ 7.200"
    assert_selector "tr:nth-child(2) td > span:not(.num)", text: "não precisa", count: 2
    assert_selector "td:not(.is-best) > span.num", text: "R$ 8.000"
  end

  test "ss_sparkline: target: tracejado na escala e mark_min: no menor (não no último)" do
    svg = ss_sparkline([30, 10, 20, 25], target: 5, mark_min: true)
    assert_includes svg, %(<path class="target" d="M0,42.0 H100"/>)
    assert_match(/<ellipse class="min" cx="33.33" cy="[\d.]+" rx="1.6" ry="3"\/>/, svg)
    refute_includes ss_sparkline([30, 20, 10], mark_min: true), "ellipse"
    refute_includes ss_sparkline([1, 2]), "target"
  end

  test "ss_countdown: warn_at: aviso e zero" do
    assert_includes ss_countdown(total: 7, left: 2, warn_at: 2), %(data-tone="warn")
    assert_includes ss_countdown(total: 7, left: 0, warn_at: 2), %(data-tone="over")
    refute_includes ss_countdown(total: 7, left: 5, warn_at: 2), "data-tone"
    refute_includes ss_countdown(total: 7, left: 1), "data-tone"
  end

  test "alto contraste: gerado das 30 paletas, a 7:1 no claro e no escuro" do
    css = CSS.join("paletas.css").read
    assert_includes css, %(:root:not([data-theme="dark"]):is(:not([data-palette]), [data-palette="violeta"])[data-ss-contrast="high"])
    regras = css.scan(/\[data-palette="([a-z-]+)"\] \[data-ss-contrast="high"\] \{ --accent: (#\h{6}); --accent-hover: (#\h{6}); --accent-solid: (#\h{6});/)
    assert_equal 30 * 3 - 3, regras.size # a violeta usa o :is(…)
    claros = regras.first(29)
    claros.each do |slug, acc, hov, sol|
      %w[#ffffff #eef0f6 #f6f5fb #f4f5fa].each { |bg| assert_operator contraste(acc, bg), :>=, 7, "#{slug} #{acc} sobre #{bg}" }
      assert_operator contraste(hov, "#ffffff"), :>=, 7, slug
      assert_operator contraste(sol, "#ffffff"), :>=, 7, slug
    end
    regras[29, 29].each do |slug, acc, _hov, sol|
      %w[#0f1017 #171925 #0e0d16 #16142a #000000].each { |bg| assert_operator contraste(acc, bg), :>=, 7, "#{slug} escuro #{acc} sobre #{bg}" }
      assert_operator contraste(sol, "#ffffff"), :>=, 7, slug
    end
    v16 = CSS.join("v16_web.css").read
    assert_includes v16, %(html:root[data-ss-contrast="high"], [data-ss-contrast="high"]:not(:root) {)
    assert_includes v16, "--muted: var(--ink-2);"
    assert_includes CSS.join("engine.css").read, %(@import "./v16_web.css";)
  end

  test "série em variante de texto, etiqueta e chip com reticências" do
    v16 = CSS.join("v16_web.css").read
    (1..6).each { |i| assert_includes v16, "--series-ink-#{i}: color-mix(in srgb, var(--series-#{i}), var(--ink) 45%);" }
    assert_includes v16, ".ss-tag > span { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }"
    assert_includes v16, ".ss-chip > span:not(.ss-chip-count, .ss-chip-swatch) { min-width: 0; overflow: hidden; text-overflow: ellipsis; }"
    %w[.ss-offer-kind .ss-offer-unit .ss-offer-savings .ss-offer-badges .ss-offer-meta .ss-offer-actions .ss-offer.is-hit .ss-offer.is-estimate].each { assert_includes v16, _1 }
  end
end
