# Gera as <section> do catálogo (rails/catalogo/index.html) para as peças da v0.16.
#   bin/rails runner script/catalogo_v016.rb > /tmp/v016.html
include ComponentesUi::Helpers
require "action_dispatch/testing/test_request"
CTRL = ApplicationController.new.tap { |c| c.request = ActionDispatch::TestRequest.create("PATH_INFO" => "/vitrine/x"); c.response = ActionDispatch::Response.new }
def view = (@view ||= CTRL.view_context)
def r(c, &blk) = view.render(c, &blk).to_s.gsub(/<!-- (BEGIN|END) [^>]*-->/, "").gsub(/\n\s*/, "")
def esc(s) = ERB::Util.h(s)
def section(slug, nome, desc, comps, estados)
  out = +%(<section data-comp="#{slug}" data-nome="#{esc(nome)}" data-descricao="#{esc(desc)}"\n  data-comportamentos='#{esc(comps.to_json)}'>\n)
  estados.each { |(s, t, html, extra)| out << %(  <div data-estado="#{s}" data-titulo="#{esc(t)}"#{extra}>#{html}</div>\n) }
  out << "</section>\n"
end
card = ->(html, w = 360) { %(<div class="ss-card ss-card-pad" style="width:#{w}px">#{html}</div>) }
out = +""
out << section("ss-legend", "Ss::ChartLegendComponent · .ss-legend", "Legenda de gráfico (v0.16, par do SsChartLegend): cor da série, rótulo e valor opcional em DM Mono.",
  ["tone: (:accent, :success, :muted, :s1..:s6) ou color:; sem cor, a série pela posição.", "line: traço (série de linha); dashed: tracejado (alvo, média).", "Rótulo longo termina em … na largura do contêiner."],
  [["padrao", "séries, valor e alvo tracejado", card.(r(Ss::ChartLegendComponent.new(items: [{ label: "Atacadão" }, { label: "Carrefour" },
    { label: "menor", value: ss_money(2148), tone: :success }, { label: "alvo", value: ss_money(1990), tone: :muted, line: true, dashed: true }])))]])
out << section("ss-diverging", "Ss::DivergingBarsComponent · .ss-diverging", "Barras para os dois lados de um eixo (v0.16, par do SsDivergingBars): subiu à direita, caiu à esquerda.",
  ["Tamanho pelo maior |valor| (--f); nome em cima da barra e o valor com sinal em DM Mono.", "Subir é ruim (vermelho) por padrão; up_is_good: true inverte.", "As barras crescem do eixo com a mola, em cascata."],
  [["padrao", "inflação da cesta (p.p.)", card.(r(Ss::DivergingBarsComponent.new(unit: "p.p.", items: [{ label: "Café torrado", value: 1.8, detail: "+32% · 9% da cesta" },
    { label: "Azeite extra virgem", value: 0.9 }, { label: "Tomate", value: -0.6, detail: "−18%" }])))]])
out << section("ss-rating", "Ss::RatingComponent · .ss-stars · .ss-rating", "Estrelas (v0.16, par do SsRating): leitura com meia (.ss-stars) e campo com um rádio por estrela (.ss-rating), sem JS.",
  ["Leitura: --v e --max; o leitor de tela lê \"Nota 4,5 de 5\".", "Campo (name:): setas trocam a nota, o hover acende até a estrela sob o mouse e o toque encolhe com a mola.", "size: :sm, :md (padrão), :lg."],
  [["leitura", "4,5 de 5", card.(r(Ss::RatingComponent.new(value: 4.5)))],
   ["campo", "campo com 3 marcadas", card.(r(Ss::RatingComponent.new(name: "nota", value: 3, size: :lg, id: "cat-nota")))]])
out << section("ss-compare-best", "Ss::CompareTableComponent(best:, mono:)", "Comparação com o melhor valor (v0.16, par do SsCompareTable): best: pinta a célula de verde; mono: false tira o DM Mono.",
  ["best: índice da coluna cuja célula sai em verde (o menor total).", "mono: false para texto (fuso, visto).", "A coluna recomendada continua com a fita e o fundo da marca."],
  [["destinos", "destinos com o menor total", card.(r(Ss::CompareTableComponent.new(caption: "Destinos", plans: [{ name: "Lisboa", price: "maio" }, { name: "Porto", price: "maio", recommended: true }],
    features: [{ label: "Total", values: [ss_money(8000, precision: 0), ss_money(7200, precision: 0)], best: 1 }, { label: "Voo direto", values: [true, false] }, { label: "Fuso", values: ["+3 h", "+3 h"], mono: false }])), 420)]])
amostra = %(<div class="ss-card ss-card-pad" style="display:grid;gap:.5rem"><b style="color:var(--ink)">Lisboa em maio</b><small style="color:var(--muted)">12 dias · 2 pessoas</small><div style="display:flex;gap:.5rem;align-items:center"><span class="ss-badge ss-badge-accent">Confirmada</span><button class="ss-btn ss-btn-primary ss-btn-sm">Ver roteiro</button><a href="#" style="color:var(--accent);font-weight:700">Detalhes</a></div></div>)
out << section("ss-contrast", "data-ss-contrast=\"high\"", "Alto contraste (v0.16, par do AppTheme.build(highContrast: true)): accent a 7:1 gerado das paletas, texto apagado no --ink-2 e linhas mais fortes.",
  ["No <html> ou num contêiner; vale com qualquer data-palette e no claro e no escuro.", "O accent sai do paletas/gerar.py (a mesma conta do SsBrand.highContrast).", "--grad e --accent-solid a 7:1 com texto branco."],
  [["normal", "normal", %(<div style="width:360px">#{amostra}</div>)], ["alto", "alto contraste", %(<div data-ss-contrast="high" style="width:360px">#{amostra}</div>)]])
out << section("ss-series-ink", "--series-ink-1..6", "Série em variante de texto (v0.16, par do SsColors.seriesInk): a cor da série puxada para a tinta, para texto sobre o fundo.",
  ["--series-ink-N escreve o que --series-N pinta (mais escura no claro, mais clara no escuro).", "Carimbo, rótulo colorido, ícone pequeno por categoria."],
  [["padrao", "série (ponto) × tinta (texto)", %(<div style="display:flex;flex-wrap:wrap;gap:.6rem 1rem;width:360px">#{(1..6).map { %(<span style="display:inline-flex;align-items:center;gap:.4rem;font-weight:800;color:var(--series-ink-#{_1})"><i style="width:.6rem;height:.6rem;border-radius:50%;background:var(--series-#{_1})"></i>Série #{_1}</span>) }.join}</div>)]])
out << section("ss-tag-v16", ".ss-tag (ícone e reticências)", "Etiqueta removível (v0.16, par do SsInputChip): ícone antes do texto e rótulo longo com reticências.",
  ["O texto vai num <span> (termina em …); o × é o <button> com aria-label.", "Ícone (svg) antes do texto."],
  [["padrao", "com ícone e rótulo longo em 240 px", %(<div style="width:240px;display:flex;flex-wrap:wrap;gap:.35rem"><span class="ss-tag">#{ss_icon("location-marker", size: nil)}<span>Lisboa</span><button type="button" aria-label="Remover Lisboa">×</button></span><span class="ss-tag"><span>Madri, Espanha, Península Ibérica</span><button type="button" aria-label="Remover Madri">×</button></span></div>)]])
out << section("ss-chip-v16", ".ss-chip (reticências)", "Chip com o texto num <span>: termina em … em vez de estourar (v0.16, par do SsFilterChip).",
  ["max-width: 100%; o contador e a amostra de cor ficam."],
  [["padrao", "rótulo longo em 220 px", %(<div style="width:220px;display:flex;flex-wrap:wrap;gap:.35rem"><button class="ss-chip" aria-pressed="false"><span>Quanto gastei com café este ano?</span></button><button class="ss-chip" aria-pressed="true"><span>Mercado</span><span class="ss-chip-count">3</span></button></div>)]])
out << section("ss-spark-v16", "ss_sparkline(target:, mark_min:)", "Minigráfico com o alvo tracejado e o menor valor marcado (v0.16, par do SsSparkline(target:, markMin:)).",
  ["target: entra na escala e vira a linha tracejada apagada.", "mark_min: ponto verde no menor (não repete o último)."],
  [["padrao", "alvo e menor", %(<div style="width:320px;color:var(--accent)">#{ss_sparkline([329, 312, 298, 305, 279, 301, 318], height: 56, target: 290, mark_min: true)}</div>)]])
out << section("ss-countdown-v16", "ss_countdown(warn_at:)", "Anel em gomos com aviso (v0.16, par do SsCountdownRing(warnAt:)): âmbar com warn_at ou menos, vermelho no zero.",
  ["Sem warn_at, fica como antes (sempre na marca)."],
  [["padrao", "6 · 2 · 0 de 7 (warn_at: 2)", %(<div style="display:flex;gap:24px">#{[6, 2, 0].map { ss_countdown(total: 7, left: _1, label: "dias", warn_at: 2) }.join}</div>)]])
out << section("ss-proportion-v16", ".ss-proportion.is-on-dark", "Proporção sobre o gradiente do herói (v0.16, par do SsProportionBar(onDark:)): trilha translúcida e legenda clara.",
  ["A legenda \"N rótulo\" é só o texto do <li> (\"<b>3</b> vencidos\")."],
  [["padrao", "sobre o gradiente", %(<div class="ss-hero" style="padding:20px;width:360px"><div class="ss-proportion is-on-dark"><div><i style="--w:8%;--c:color-mix(in srgb, var(--danger), #fff 45%)"></i><i style="--w:23%;--c:var(--warn)"></i><i style="--w:69%;--c:color-mix(in srgb, var(--success), #fff 45%)"></i></div><ul><li style="--c:color-mix(in srgb, var(--danger), #fff 45%)"><b>1</b> vencido</li><li style="--c:var(--warn)"><b>3</b> vencem na semana</li><li style="--c:color-mix(in srgb, var(--success), #fff 45%)"><b>9</b> em dia</li></ul></div></div>)]])
out << section("ss-timeline-v16", ".ss-timeline (time e .is-alert)", "Linha do tempo com horário e fim (<time>) e o passo em alerta (v0.16, par do SsTimelineItem(endTime:, alert:)).",
  ["<time> em DM Mono em cima do título (\"09:30 – 11:00\").", ".is-alert: horário em vermelho com ⚠ e o nó com borda vermelha."],
  [["padrao", "roteiro com conflito", %(<ol class="ss-timeline" style="width:320px"><li class="is-done"><time>09:30 – 11:00</time><b>Voo GRU → LIS</b></li><li class="is-current is-alert"><time>10:45</time><b>Check-in no hotel</b><small>Conflita com o voo</small></li><li><time>20:00</time><b>Jantar no Bairro Alto</b></li></ol>)]])
oferta = %(<div class="ss-offer is-hit"><span class="ss-source">mercadolivre.com.br<small>há 2 h</small></span><span class="ss-offer-kind">Fone</span><b>Fone Bluetooth JBL Tune 520BT</b><span class="ss-offer-price">R$ 219,90</span><span class="ss-offer-unit">ou 10x R$ 23,90</span><div class="ss-offer-badges"><span class="ss-badge ss-badge-success">promoção de verdade</span></div><span class="ss-offer-meta">verificado 12/10/2026 14:00</span><div class="ss-offer-actions"><a class="ss-btn ss-btn-ghost ss-btn-sm" href="#">Ver oferta</a></div></div>)
estimativa = %(<div class="ss-offer is-estimate"><span class="ss-offer-kind">Estimativa · voo + hospedagem</span><b>Kayak + Booking</b><span class="ss-offer-price">R$ 8.120,00</span><span class="ss-offer-savings is-bad">+R$ 312,00 que a mais barata</span></div>)
out << section("ss-offer-v16", ".ss-offer (v0.16)", "Oferta completa (v0.16, par do SsOfferCard): tipo, unidade, economia, selos, linha pequena, ações, preço no alvo e estimativa.",
  [".is-hit: preço no alvo em verde (sem a fita do .is-best).", ".is-estimate: montada por conta, borda tracejada, fundo de campo e ≈ antes do preço.", ".ss-offer-kind, -unit, -savings (.is-bad apagado), -badges, -meta e -actions."],
  [["padrao", "no alvo · estimativa", %(<div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;width:440px">#{oferta}#{estimativa}</div>)]])
puts out
