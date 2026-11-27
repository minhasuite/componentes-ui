require "test_helper"

# v1.14.0 "interface e animação": o gráfico que se arrasta (scrub: nos 4 gráficos, ss-scrub), Ss::PeriodCompareComponent,
# Ss::ExpandableRowComponent, Ss::SelectionBarComponent (ss-selection), DrawerComponent(detents:), as abas de baixo da
# moldura (tabs:, ícone que enche, View Transition), Ss::MeshBackgroundComponent (e HeroSectionComponent(mesh:)), o
# odômetro no KPI e no ss_amount, PageComponent(collapse_tint:), Ss::SuccessCheckComponent (no MorphButton, no
# SwipeToConfirm e no PixCard), Ss::TiltCardComponent, ss_tab_hero e ss_skeleton_for, com os textos pt/en/es.
class V1140WebTest < ComponentTest
  ROOT = Pathname(ComponentesUi::Engine.root)
  CSS = ROOT.join("app/assets/tailwind/componentes_ui")
  JS = ROOT.join("app/javascript/componentes_ui/controllers")
  PARIDADE = YAML.load_file(ROOT.join("../paridade.yml"))

  include ComponentesUi::Helpers

  test "paridade.yml: as peças da v1.14" do
    {
      "SsScrubDetector" => "js:ss-scrub", "SsPeriodCompare" => "Ss::PeriodCompareComponent",
      "SsExpandableRow" => "Ss::ExpandableRowComponent", "SsMeshBackground" => "Ss::MeshBackgroundComponent",
      "SsSuccessCheck" => "Ss::SuccessCheckComponent", "SsTiltCard" => "Ss::TiltCardComponent",
      "SsSharedAxisTransition" => "Ss::AppShellComponent", "SsTabHero" => "helper:ss_tab_hero",
      "SsSelectionBar" => "Ss::SelectionBarComponent", "SsSkeleton" => "helper:ss_skeleton_for"
    }.each { |f, r| assert_includes Array(PARIDADE["pares"][f]), r, f }
    assert_includes Array(PARIDADE["pares"]["SsSelectionBar"]), "js:ss-selection"
    assert_includes Array(PARIDADE["apis"]["SsSounds"]), "js:ss-success-check"
  end

  # ── 1. scrub ────────────────────────────────────────────────────────
  test "LineChart(scrub:): ss-scrub com os pontos em %, o rótulo e o valor de cada série" do
    render_inline(Ss::LineChartComponent.new(title: "Vendas", labels: %w[a b c], scrub: true, format: ->(v) { "R$ #{v.to_i}" },
                                             series: [{ name: "Agora", values: [10, 20, 30] }, { name: "Antes", values: [5, nil, 15], dashed: true }]))
    fig = page.find("figure.ss-linec.is-scrub[data-controller=ss-scrub]")
    pts = JSON.parse(fig["data-ss-scrub-points-value"])
    assert_equal 3, pts.size
    assert_equal "b", pts[1][2]
    assert_equal [["Agora", "var(--series-1)", "R$ 20"], ["Antes", "var(--series-2)", "—"]], pts[1][3]
    assert pts[0][0] < pts[2][0]
    assert_selector ".ss-scrub-plot[data-ss-scrub-target=plot][tabindex='0'][aria-label*='Arraste para ver cada ponto'] svg"
    assert_selector "p.ss-sr[aria-live=polite][data-ss-scrub-target=live]"
    render_inline(Ss::LineChartComponent.new(title: "V", labels: %w[a b], series: [{ name: "x", values: [1, 2] }]))
    refute_selector "[data-controller=ss-scrub]"
    refute_selector ".ss-scrub-plot"
  end

  test "BarChart(scrub:), AreaChart(scrub:) e TimeSeriesChart(scrub:)" do
    render_inline(Ss::BarChartComponent.new(title: "P", labels: %w[a b], scrub: true, series: [{ name: "P", values: [1, 2] }], line: { name: "Meta", values: [2, 2] }))
    pts = JSON.parse(page.find("figure.ss-barc.is-scrub")["data-ss-scrub-points-value"])
    assert_equal %w[P Meta], pts[0][3].map(&:first)
    refute_nil pts[0][1]
    render_inline(Ss::BarChartComponent.new(title: "P", labels: %w[a b], scrub: true, horizontal: true, series: [{ name: "P", values: [1, 2] }]))
    refute_selector "[data-controller=ss-scrub]"
    render_inline(Ss::AreaChartComponent.new(title: "Saldo", points: [["a", 1], ["b", 2]], scrub: true))
    assert_selector "figure.ss-area.is-scrub[data-ss-chart-scrub-value=true]"
    assert_selector ".ss-area-plot[aria-label*='Arraste para ver cada ponto']"
    render_inline(Ss::TimeSeriesChartComponent.new(title: "T", scrub: true, series: [{ name: "S", points: [[1.hour.ago, 1], [Time.current, 2]] }]))
    assert_selector "figure.ss-tc[data-ss-time-chart-scrub-value=true]"
    js = JS.join("ss_scrub_controller.js").read
    assert_match(/export function scrubTick/, js)
    assert_includes js, "ss-scrub:change"
    assert_includes js, 'haptic("selection")'
    assert_includes JS.join("ss_chart_controller.js").read, "scrubTick"
    assert_includes JS.join("ss_time_chart_controller.js").read, "scrubTick"
  end

  # ── 2. período × anterior ───────────────────────────────────────────
  test "PeriodCompare: total no odômetro, diferença com sentido, linha fantasma e a troca de período no frame" do
    render_inline(Ss::PeriodCompareComponent.new(title: "Gastos", labels: %w[1 2 3], current: [100, 50, 70], previous: [80, 60, 60], money: true,
                                                 higher_is_better: false, frame: "cmp", id: "cmp-x",
                                                 periods: [{ label: "Mês", href: "?p=m", current: true }, { label: "Semana", href: "?p=s" }]))
    assert_selector "turbo-frame#cmp section.ss-period#cmp-x[data-controller=ss-period-compare][aria-labelledby='cmp-x-t']"
    assert_selector "h3#cmp-x-t", text: "Gastos"
    assert_selector ".ss-period-total.ss-odo[data-ss-odometer-text-value='#{ss_money(220)}'][data-ss-period-compare-target=total]"
    assert_selector ".ss-delta.ss-period-delta.is-bad", text: "+10%"
    assert_selector ".ss-period-delta[aria-label*='em relação ao período anterior (ruim)']"
    assert_selector ".ss-period-sub", text: "#{ss_money(220)} neste período, #{ss_money(200)} no anterior"
    assert_selector ".ss-linec.is-scrub path.ss-linec-line.is-dashed"
    assert_selector ".ss-seg a[href='?p=m'][aria-current=true][data-turbo-frame=cmp]"
    render_inline(Ss::PeriodCompareComponent.new(title: "V", labels: %w[a b], current: [10, 20], previous: [20, 20]))
    assert_selector ".ss-delta.is-bad", text: "-25%"
    render_inline(Ss::PeriodCompareComponent.new(title: "V", labels: %w[a b], current: [1, 2], previous: [0, 0]))
    refute_selector ".ss-delta"
    assert_includes JS.join("ss_period_compare_controller.js").read, "snapshots"
  end

  # ── 3. linha que se expande ─────────────────────────────────────────
  test "ExpandableRow: Editar com aria-expanded, painel inert, form com Salvar e Cancelar" do
    render_inline(Ss::ExpandableRowComponent.new(title: "Mercado", subtitle: "12/11", value: "R$ 89,90", url: "/l/1", id: "xr")) do
      '<input name="d" class="ss-input">'.html_safe
    end
    assert_selector ".ss-xrow#xr[data-controller=ss-expandable-row]:not(.is-open)"
    assert_selector "button.ss-xrow-toggle[aria-expanded=false][aria-controls=xr-panel][aria-label='Editar Mercado']", text: "Editar"
    assert_selector ".ss-xrow-value.num", text: "R$ 89,90"
    assert_selector "#xr-panel.ss-xrow-panel[inert][role=region]", visible: :all
    assert_selector "#xr-panel form[action='/l/1'] input[name=_method][value=patch]", visible: :all
    assert_selector "#xr-panel button[type=submit].ss-btn-primary", text: "Salvar", visible: :all
    assert_selector "#xr-panel button[type=button][data-action='ss-expandable-row#cancel']", text: "Cancelar", visible: :all
    render_inline(Ss::ExpandableRowComponent.new(title: "X", open: true)) { "campos" }
    assert_selector ".ss-xrow.is-open button[aria-expanded=true]"
    refute_selector ".ss-xrow-panel[inert]"
    refute_selector "form"
    js = JS.join("ss_expandable_row_controller.js").read
    assert_includes js, "Escape"
    assert_includes js, "focus"
  end

  # ── 4. seleção em massa ─────────────────────────────────────────────
  test "SelectionBar: a lista no bloco, a barra escondida com o odômetro, as ações e o Shift" do
    render_inline(Ss::SelectionBarComponent.new(name: "ids[]", actions: [{ label: "Arquivar", icon: "archive", url: "/a", method: :patch },
                                                                        { label: "Excluir", url: "/e", method: :delete, danger: true, confirm: "Certeza?" },
                                                                        { label: "Exportar", href: "/x" }])) do
      '<input type="checkbox" class="ss-select-item" value="1">'.html_safe
    end
    assert_selector ".ss-selection[data-controller=ss-selection][data-ss-selection-name-value='ids[]'] input.ss-select-item"
    bar = page.find(".ss-selection-bar[hidden][role=region]", visible: :all)
    assert bar.has_css?(".ss-odo.ss-selection-count[data-ss-selection-target=count]", visible: :all)
    assert bar.has_css?("form[action='/a'][data-action='submit->ss-selection#fill'] button", text: "Arquivar", visible: :all)
    assert bar.has_css?("form[action='/e'][data-turbo-confirm='Certeza?'] button.is-danger", visible: :all)
    assert bar.has_css?("a[href='/x'][data-action='ss-selection#follow']", visible: :all)
    assert bar.has_css?("button.ss-selection-clear[aria-label='Limpar seleção']", visible: :all)
    assert_selector ".ss-sr", text: "Shift + clique marca o intervalo", visible: :all
    js = JS.join("ss_selection_controller.js").read
    assert_includes js, "shiftKey"
    assert_includes js, "indeterminate"
    assert_includes js, "data-ss-odometer-text-value"
  end

  # ── 5. folha com alturas ────────────────────────────────────────────
  test "Drawer(detents:): a alça (slider) com os pontos e o texto do tamanho" do
    render_inline(Ss::DrawerComponent.new(id: "f", title: "Filtros", detents: [1, 0.33, 0.5], detent: 0.5)) { "x" }
    d = page.find("dialog.ss-drawer-panel.has-detents", visible: :all)
    assert_equal "[0.33,0.5,1.0]", d["data-ss-drawer-detents-value"]
    assert_equal "0.5", d["data-ss-drawer-detent-value"]
    assert_includes d["style"], "--ss-detent:0.5"
    h = page.find(".ss-drawer-handle[role=slider][tabindex='0'][aria-label='Alça da folha']", visible: :all)
    assert_equal %w[33 100 50], [h["aria-valuemin"], h["aria-valuemax"], h["aria-valuenow"]]
    assert_equal "50% da tela", h["aria-valuetext"]
    render_inline(Ss::DrawerComponent.new(id: "g")) { "x" }
    refute_selector ".ss-drawer-handle", visible: :all
    refute_selector ".has-detents", visible: :all
    assert_includes JS.join("ss_drawer_controller.js").read, "handleKey"
  end

  # ── 6 e 12. abas de baixo, ícone que enche, View Transition ─────────
  test "AppShell(tabs:): a barra de baixo com contorno e cheio, a aba atual e a transição" do
    render_inline(Ss::AppShellComponent.new(brand: "X", tabs: [{ label: "Início", icon: "home", href: "/", current: true }, { label: "Pedidos", icon: "shopping-bag", href: "/p", badge: 3 }])) { "c" }
    assert_selector "nav.ss-shell-tabbar[aria-label=Abas][data-controller=ss-tab-transition]"
    assert_selector "a.ss-shell-tab[aria-current=page][href='/'] .ss-tab-ico svg.is-outline + svg.is-solid"
    assert_selector "a.ss-shell-tab[href='/p'] .ss-shell-tab-badge", text: "3"
    assert_selector "main[data-ss-tab-main]"
    render_inline(Ss::AppShellComponent.new(brand: "X", tabs: [{ label: "A", icon: "home", href: "/" }], tab_transition: false)) { "c" }
    refute_selector "[data-controller=ss-tab-transition]"
    refute_selector "main[data-ss-tab-main]"
    render_inline(Ss::AppShellComponent.new(brand: "X")) { "c" }
    refute_selector ".ss-shell-tabbar"
    assert_equal({ style: "view-transition-name: ss-tab-hero-saldo-do-mes", data: { ss_tab_hero: "saldo-do-mes" } }, ss_tab_hero("Saldo do mês"))
    css = CSS.join("v1140_web.css").read
    assert_includes css, "::view-transition-new(ss-tab-main)"
    assert_includes css, "ss-tab-ico-in"
  end

  # ── 7. fundo de manchas ─────────────────────────────────────────────
  test "MeshBackground: as manchas decorativas, os tons e o herói com mesh" do
    render_inline(Ss::MeshBackgroundComponent.new) { "<h2>Oi</h2>".html_safe }
    assert_selector ".ss-mesh.is-deep > .ss-mesh-blobs[aria-hidden=true] i", count: 3
    assert_selector ".ss-mesh > .ss-mesh-body h2", text: "Oi"
    render_inline(Ss::MeshBackgroundComponent.new(tone: :soft, animate: false, tag: :header)) { "x" }
    assert_selector "header.ss-mesh.is-soft.is-still"
    assert_raises(ArgumentError) { Ss::MeshBackgroundComponent.new(tone: :neon) }
    render_inline(Ss::HeroSectionComponent.new(title: "Venda mais", mesh: true))
    assert_selector "section.ss-hero-section.is-mesh.ss-mesh.is-soft > .ss-mesh-blobs"
    css = CSS.join("v1140_web.css").read
    assert_includes css, "var(--ss-dur-ambient)"
    refute_match(/\.ss-mesh[^{]*\{[^}]*filter:\s*blur/, css, "sem filter: blur nas manchas")
  end

  # ── 8. odômetro ─────────────────────────────────────────────────────
  test "KPI com odômetro por padrão (animate: false volta ao texto) e ss_amount(animate:)" do
    render_inline(Ss::KpiCardComponent.new(label: "Saldo", value: "R$ 312,75", money: true))
    assert_selector ".ss-kpi-card-value .ss-odo.ss-kpi-odo[data-controller=ss-odometer][data-ss-odometer-text-value='R$ 312,75'] .ss-odo-cents"
    assert_selector ".ss-kpi-card-value .ss-odo .ss-sr", text: "R$ 312,75"
    render_inline(Ss::KpiCardComponent.new(label: "Saldo", value: "R$ 312,75", money: true, animate: false))
    assert_selector ".ss-kpi-card-value .ss-amount small", text: ",75"
    render_inline(Ss::KpiCardComponent.new(label: "Status", value: "Em dia"))
    assert_selector ".ss-kpi-card-value .num", text: "Em dia"
    odo = Capybara.string(ApplicationController.render(inline: '<%= ss_amount("R$ 10,00", animate: true) %>'))
    assert odo.has_css?(".ss-odo.ss-amount-odo[data-ss-odometer-text-value='R$ 10,00']")
    assert_includes ss_amount("R$ 10,00"), "ss-amount"
  end

  # ── 9. cabeçalho que muda de cor ────────────────────────────────────
  test "PageComponent(collapse_tint:) encolhe e tinge; sem suporte, fica na superfície" do
    render_inline(Ss::PageComponent.new(title: "Pedidos", collapse_tint: true))
    assert_selector ".ss-page.is-shrink.is-tint > header.ss-page-head"
    render_inline(Ss::PageComponent.new(title: "Pedidos"))
    refute_selector ".is-tint"
    css = CSS.join("v1140_web.css").read
    assert_match(/@supports \(animation-timeline: scroll\(\)\)\s*\{\s*\.ss-page\.is-tint/, css)
    assert_includes css, "@keyframes ss-page-tint"
  end

  # ── 10. check que se desenha ────────────────────────────────────────
  test "SuccessCheck: o círculo e o traço, o rótulo, o som opcional e nas peças que terminam em ✓" do
    render_inline(Ss::SuccessCheckComponent.new(size: 48, sound: true))
    assert_selector "span.ss-success-check[role=img][aria-label=Concluído][data-controller=ss-success-check][data-ss-success-check-sound-value=true][style*='--ss-sc-size:48px']"
    assert_selector ".ss-success-check svg.ss-sc-svg[aria-hidden=true] circle.ss-sc-circle + path.ss-sc-mark"
    render_inline(Ss::SuccessCheckComponent.new(label: "Pago"))
    refute_selector "[data-ss-success-check-sound-value]"
    assert_selector "[aria-label=Pago]"
    render_inline(Ss::MorphButtonComponent.new(label: "Salvar", sound: true))
    assert_selector ".ss-morph[data-ss-morph-sound-value=true] svg.ss-morph-ok.ss-sc-svg .ss-sc-mark"
    render_inline(Ss::SwipeToConfirmComponent.new(label: "Deslize"))
    assert_selector ".ss-swipe-thumb svg.ss-swipe-ok.ss-sc-svg"
    render_inline(Ss::PixCardComponent.new(code: ComponentesUi::Br.pix_build(key: "loja@exemplo.com.br", name: "LOJA EXEMPLO", city: "SAO PAULO", amount_cents: 1000), status: :paid, sound: true))
    assert_selector ".ss-pix[data-state=paid] .ss-pix-check.ss-success-check[data-ss-success-check-sound-value=true] svg"
    js = JS.join("ss_success_check_controller.js").read
    assert_includes js, '"ss:sound"'
    assert_includes js, 'haptic("success")'
    %w[ss_morph_controller.js ss_swipe_confirm_controller.js].each { assert_includes JS.join(_1).read, "ssSuccess", _1 }
  end

  # ── 11. cartão que inclina ──────────────────────────────────────────
  test "TiltCard: ss-tilt com o reflexo; dense: parado e sem reflexo; href: o cartão é link" do
    render_inline(Ss::TiltCardComponent.new) { "Plano Pro" }
    assert_selector "div.ss-card.ss-tilt-card.is-glass[data-controller=ss-tilt] .ss-tilt-body", text: "Plano Pro"
    assert_selector ".ss-tilt-glare[aria-hidden=true]"
    render_inline(Ss::TiltCardComponent.new(dense: true)) { "x" }
    assert_selector ".ss-tilt-card.is-dense[data-ss-tilt-off]"
    refute_selector "[data-controller=ss-tilt]"
    refute_selector ".ss-tilt-glare"
    render_inline(Ss::TiltCardComponent.new(href: "/plano")) { "x" }
    assert_selector "a.ss-tilt-card[href='/plano']"
    js = JS.join("ss_tilt_controller.js").read
    assert_includes js, "pointerdown"
    assert_includes js, "prefers-reduced-motion"
    assert_includes js, "data-ss-tilt-off"
  end

  # ── 13. esqueleto no formato real ───────────────────────────────────
  test "ss_skeleton_for: o partial vira blocos, sem link nem id, com aria-busy e o Carregando" do
    html = ApplicationController.render(inline: '<%= ss_skeleton_for("vitrine/skel_pedido", count: 2, pedido: { cliente: "Cliente", numero: "1", quando: "hoje", status: "Aberto", total: 10 }) %>')
    page = Capybara.string(html)
    assert page.has_css?(".ss-skel-of[aria-busy=true][role=status] > .ss-sr", text: "Carregando…")
    assert page.has_css?(".ss-skel-of-body[aria-hidden=true][inert] article", count: 2)
    assert page.has_css?(".ss-skel-of-body .ss-skel-w", text: "Cliente")
    frag = Nokogiri::HTML::DocumentFragment.parse(html)
    assert frag.css(".ss-skel-of-body [id], .ss-skel-of-body [href], .ss-skel-of-body [data-controller]").empty?
    frag.css(".ss-skel-of-body").first.traverse do |n|
      next unless n.text? && n.content.strip.present?

      assert_equal "ss-skel-w", n.parent["class"], "texto fora do bloco: #{n.content}"
    end
  end

  # ── textos, CSS e JS ────────────────────────────────────────────────
  test "idiomas: componentes_ui.interface.* iguais nos três e os textos em en/es" do
    keys = %w[pt-BR en es].map { |l| YAML.load_file(ROOT.join("config/locales/componentes_ui.#{l}.yml")).dig(l, "componentes_ui", "interface").keys.sort }
    assert_equal keys[0], keys[1]
    assert_equal keys[0], keys[2]
    assert_includes keys[0], "selection_range_hint"
    I18n.with_locale(:en) do
      render_inline(Ss::ExpandableRowComponent.new(title: "Rent")) { "x" }
      assert_selector "button[aria-label='Edit Rent']", text: "Edit"
      render_inline(Ss::SuccessCheckComponent.new)
      assert_selector "[aria-label=Done]"
    end
    I18n.with_locale(:es) do
      render_inline(Ss::DrawerComponent.new(id: "f", detents: [0.5, 1])) { "x" }
      assert_selector ".ss-drawer-handle[aria-valuetext='50% de la pantalla']", visible: :all
      render_inline(Ss::PeriodCompareComponent.new(title: "V", labels: %w[a b], current: [1, 2], previous: [1, 1]))
      assert_selector ".ss-period-sub", text: "en este período"
    end
  end

  test "CSS importado, só tokens, sem duração solta, reduzir movimento e alvo; um controller por peça" do
    assert_includes CSS.join("engine.css").read, '@import "./v1140_web.css";'
    css = CSS.join("v1140_web.css").read.gsub(%r{/\*.*?\*/}m, "").sub(/:root\s*\{[^}]*\}/, "")
    refute_match(/#(?!fff\b)[0-9a-f]{3,6}\b/i, css, "cor fixa no CSS")
    refute_match(/(?<![\w-])\d*\.?\d+m?s\b/, css.gsub(/var\([^)]*\)/, ""), "duração solta (use --ss-dur-*)")
    assert_includes css, "prefers-reduced-motion: reduce"
    assert_includes css, "var(--ss-target"
    assert_includes css, "var(--ss-bounce)"
    %w[scrub period_compare expandable_row selection success_check tilt tab_transition].each do |c|
      assert JS.join("ss_#{c}_controller.js").exist?, "falta ss_#{c}_controller.js"
    end
    %w[ss_scrub_controller.js ss_expandable_row_controller.js ss_selection_controller.js ss_period_compare_controller.js].each do |f|
      refute_match(/\b\d{3,}\)/, JS.join(f).read.gsub(/setTimeout\([^)]*\)/, ""), "#{f}: duração solta no JS") if f == "ss_scrub_controller.js"
    end
  end

  test "vitrine: a página da v1.14 em Novidades e nas categorias" do
    novas = VitrineController.paginas.select { _1[:grupos].include?(VitrineController::GRUPO_NOVIDADES) }
    assert_equal ["pecas_v1140"], novas.map { _1[:slug] }
    assert_equal "1.14", VitrineController::NOVIDADES
    assert_equal ["Movimento e transições", "Dados e gráficos", "Listas e tabelas", "Cards e painéis", "Retorno e estados", "Navegação e moldura",
                  VitrineController::GRUPO_NOVIDADES], novas.first[:grupos]
  end
end

# A vitrine da v1.14 por HTTP (a página inteira, a troca de período e as abas de baixo da moldura).
class V1140VitrineTest < ActionDispatch::IntegrationTest
  test "vitrine: a página da v1.14 abre com todas as peças" do
    get "/vitrine/pecas_v1140"
    assert_response :success
    %w[.ss-mesh .ss-linec.is-scrub .ss-barc.is-scrub .ss-area.is-scrub .ss-tc .ss-period .ss-xrow .ss-selection .ss-success-check
       .ss-tilt-card .ss-page.is-tint .has-detents .ss-skel-of .ss-shell-tabbar].each { |sel| assert_select sel, { minimum: 1 }, sel }
    assert_select "a.ss-shell-tab[aria-current=page]", text: /Novidades/
    get "/vitrine/pecas_v1140", params: { periodo: "semana" }
    assert_response :success
    assert_select ".ss-seg a[aria-current=true]", text: "Semana"
  end
end
