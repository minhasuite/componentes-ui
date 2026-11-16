require "test_helper"

# v0.27 · o que a migração do meulog (monitor de erros, roda em rede fechada) pediu.
class V27WebTest < ComponentTest
  ROOT = Pathname(ComponentesUi::Engine.root)
  CSS = ROOT.join("app/assets/tailwind/componentes_ui")
  DIAS = %w[10/11 11/11 12/11 13/11 14/11].freeze

  # ── Fontes sem CDN ──────────────────────────────────────────────────
  test "ss_font_tags(self_hosted: true) não sai do app: preload e stylesheet com digest" do
    html = vc_test_controller.view_context.ss_font_tags(self_hosted: true)
    refute_includes html, "googleapis"
    refute_includes html, "gstatic"
    assert_match %r{<link rel="preload" href="/assets/componentes_ui/Manrope-Regular-\h+\.woff2" as="font" type="font/woff2" crossorigin>}, html
    assert_match %r{href="/assets/componentes_ui/fonts-\h+\.css"}, html
    refute_match(/fonts_display/, html)
    assert_match %r{componentes_ui/fonts_display-\h+\.css}, vc_test_controller.view_context.ss_font_tags(self_hosted: true, display: true)
  end

  test "ss_font_tags sem self_hosted é o Google Fonts de sempre (os outros produtos não mudam)" do
    html = vc_test_controller.view_context.ss_font_tags
    assert_includes html, ComponentesUi::Helpers::GOOGLE_FONTS_URL
    assert_includes html, %(rel="preconnect" href="https://fonts.gstatic.com" crossorigin)
    refute_includes vc_test_controller.view_context.ss_font_tags(preconnect: false), "preconnect"
    assert_includes vc_test_controller.view_context.ss_font_tags(display: true), "Big+Shoulders+Display"
  end

  test "o Propshaft troca cada url() do fonts.css pelo woff2 com digest, e o arquivo existe" do
    assets = Rails.application.assets
    css = assets.compilers.compile(assets.load_path.find("componentes_ui/fonts.css"))
    urls = css.scan(/url\("([^"]+)"\)/).flatten
    assert_equal 7, urls.size
    urls.each do |u|
      assert_match %r{\A/assets/componentes_ui/(Manrope|DMMono)-\w+-\h+\.woff2\z}, u
      logical = u.delete_prefix("/assets/").sub(/-\h+\.woff2\z/, ".woff2")
      assert assets.load_path.find(logical), "falta #{logical}"
    end
    %w[400 500 600 700 800].each { |w| assert_match(/"Manrope".*font-weight: #{w};/, css) }
    %w[400 500].each { |w| assert_match(/"DM Mono".*font-weight: #{w};/, css) }
    assert ROOT.join("app/assets/fonts/componentes_ui/OFL-Manrope.txt").exist?
    assert ROOT.join("app/assets/fonts/componentes_ui/OFL-DMMono.txt").exist?
  end

  # ── LineChart ───────────────────────────────────────────────────────
  def linha(**opts)
    render_inline(Ss::LineChartComponent.new(title: "Ocorrências por dia", labels: DIAS,
      series: [{ name: "Agora", values: [12, 19, 8, 24, 17] },
               { name: "Semana anterior", values: [10, 11, 9, 14, 12], tone: :muted, dashed: true }], **opts))
  end

  test "LineChart: uma linha reta por série, a anterior tracejada, legenda e tabela" do
    linha
    assert_selector "figure.ss-linec path.ss-linec-line", count: 2
    assert_selector "path.ss-linec-line.is-dashed[style*='var(--muted)']", count: 1
    d = page.find("path.ss-linec-line:not(.is-dashed)", visible: :all)[:d]
    assert_match(/\AM[\d.]+,[\d.]+( L[\d.]+,[\d.]+){4}\z/, d) # só M e L: sem curva
    assert_selector "ul.ss-barc-legend li.is-dashed", text: "Semana anterior"
    assert_selector "table.ss-sr tbody tr", count: 5, visible: :all
    assert_selector "table.ss-sr th", text: "Semana anterior", visible: :all
    assert_selector "g.ss-linec-g title", text: "Agora: 19", visible: :all
  end

  test "LineChart: uma série não tem legenda; nil vira buraco na linha" do
    render_inline(Ss::LineChartComponent.new(title: "t", labels: DIAS, series: [{ name: "a", values: [1, 2, nil, 4, 5] }]))
    refute_selector ".ss-barc-legend"
    d = page.find("path.ss-linec-line", visible: :all)[:d]
    assert_equal 2, d.scan("M").size
  end

  test "LineChart(stacked: true): áreas empilhadas, a de cima soma as de baixo" do
    render_inline(Ss::LineChartComponent.new(title: "t", labels: %w[a b], stacked: true,
      series: [{ name: "x", values: [10, 10] }, { name: "y", values: [5, 5] }]))
    assert_selector "figure.ss-linec.is-stacked path.ss-linec-area", count: 2
    c = Ss::LineChartComponent.new(title: "t", labels: %w[a b], stacked: true, series: [{ name: "x", values: [10, 10] }, { name: "y", values: [5, 5] }])
    assert_equal [[10.0, 10.0], [15.0, 15.0]], c.tops
    assert_selector "table.ss-sr td", text: "5", visible: :all # a tabela mostra o valor, não a soma
  end

  test "LineChart: empty: desenha o vazio; sem empty:, nada" do
    render_inline(Ss::LineChartComponent.new(title: "t", labels: [], series: [], empty: "Sem dados no período"))
    assert_selector "figure.ss-linec.is-empty p.ss-chart-empty", text: "Sem dados no período"
    refute_selector "svg"
    render_inline(Ss::LineChartComponent.new(title: "t", labels: DIAS, series: [{ name: "a", values: [nil] * 5 }]))
    refute_selector "figure"
  end

  # ── Marcas ──────────────────────────────────────────────────────────
  MARCAS = [{ at: "12/11", label: "v2.3.1", kind: :deploy }, { at: "12/11", label: "API fora", kind: :incident },
            { at: "14/11", label: "migração", kind: "note" }, { at: "01/01", label: "fora do eixo", kind: :deploy }].freeze

  test "markers: traço tracejado, rótulo no alto (empilhado no mesmo dia), cor por tipo e na tabela" do
    linha(markers: MARCAS)
    assert_selector "g.ss-chart-mark", count: 3, visible: :all
    assert_selector "g.ss-chart-mark[data-kind=deploy] line.ss-chart-mark-line[style*='var(--ss-info)']", visible: :all
    assert_selector "g.ss-chart-mark[data-kind=incident] text[style*='var(--danger)']", text: "API fora", visible: :all
    assert_selector "g.ss-chart-mark[data-kind=note] text[style*='var(--muted)']", text: "migração", visible: :all
    ys = page.all("g.ss-chart-mark text", visible: :all).first(2).map { _1[:y].to_f }
    assert_operator ys[1], :>, ys[0]
    refute_text "fora do eixo"
    assert_selector "table.ss-sr th", text: "Marcas", visible: :all
    assert_selector "table.ss-sr td", text: "v2.3.1 (implantação); API fora (incidente)", visible: :all
  end

  test "markers no BarChart (em pé) empurram o desenho para baixo; no deitado são ignoradas" do
    base = Ss::BarChartComponent.new(title: "t", labels: DIAS, series: [{ name: "a", values: [1, 2, 3, 4, 5] }])
    com = Ss::BarChartComponent.new(title: "t", labels: DIAS, series: [{ name: "a", values: [1, 2, 3, 4, 5] }], markers: MARCAS)
    assert_operator com.h, :>, base.h
    render_inline(com)
    assert_selector ".ss-barc g.ss-chart-mark", count: 3, visible: :all
    render_inline(Ss::BarChartComponent.new(title: "t", labels: DIAS, horizontal: true, series: [{ name: "a", values: [1, 2, 3, 4, 5] }], markers: MARCAS))
    refute_selector "g.ss-chart-mark", visible: :all
  end

  test "markers em en" do
    I18n.with_locale(:en) { linha(markers: MARCAS.first(1)) }
    assert_selector "table.ss-sr td", text: "v2.3.1 (deploy)", visible: :all
  end

  # ── BarChart deitado, cor por valor e vazio ─────────────────────────
  CLASSES = ["ActiveRecord::RecordNotFound in UsersController#show (muito longo)", "Net::ReadTimeout", "Outros"].freeze

  test "BarChart(horizontal: true): uma linha por rótulo, rótulo com reticências e nome inteiro na dica" do
    render_inline(Ss::BarChartComponent.new(title: "Erros por classe", horizontal: true, labels: CLASSES,
      series: [{ name: "Ocorrências", values: [120, 48, 30] }]))
    assert_selector "figure.ss-barc.is-horizontal g.ss-barc-g", count: 3, visible: :all
    assert_selector "rect.ss-barc-bar.is-h", count: 3, visible: :all
    texto = page.all("text.ss-barc-ltext", visible: :all).first.text
    assert texto.end_with?("…")
    assert_selector "g.ss-barc-g title", text: CLASSES.first, visible: :all
    assert_selector "text.ss-barc-vtext", text: "120", visible: :all
    larguras = page.all("rect.ss-barc-bar", visible: :all).map { _1[:width].to_f }
    assert_operator larguras[0], :>, larguras[1]
  end

  test "BarChart: tones: por valor (a última categoria apagada) e colors: por valor" do
    render_inline(Ss::BarChartComponent.new(title: "t", labels: CLASSES, horizontal: true,
      series: [{ name: "Ocorrências", values: [120, 48, 30], tones: [nil, nil, :muted] }]))
    cores = page.all("rect.ss-barc-bar", visible: :all).map { _1[:style] }
    assert_equal ["fill:var(--series-1)", "fill:var(--series-1)", "fill:var(--muted)"], cores
    render_inline(Ss::BarChartComponent.new(title: "t", labels: %w[a b], series: [{ name: "x", values: [1, 2], colors: [nil, "var(--danger)"] }]))
    assert_selector "rect.ss-barc-bar[style='fill:var(--danger)']", count: 1, visible: :all
  end

  test "BarChart: empty: desenha o vazio; sem empty:, nada (como antes)" do
    render_inline(Ss::BarChartComponent.new(title: "t", labels: [], series: [], empty: "Sem dados"))
    assert_selector "figure.ss-barc.is-empty p.ss-chart-empty", text: "Sem dados"
    render_inline(Ss::BarChartComponent.new(title: "t", labels: [], series: []))
    refute_selector "figure"
  end

  test "o CSS da v0.27 entra no engine.css e desliga a animação com menos movimento" do
    assert_includes CSS.join("engine.css").read, %(@import "./v27_web.css";)
    css = CSS.join("v27_web.css").read
    %w[.ss-linec-line .ss-linec-area .ss-barc-ltext .ss-chart-mark-line .ss-chart-empty].each { assert_includes css, _1 }
    assert_match(/prefers-reduced-motion: reduce\)\s*\{\s*\.ss-linec-line/m, css)
    refute_match(/#\h{3,6}\b/, css.gsub(%r{/\*.*?\*/}m, ""))
  end

  # ── Ícones do monitor de erros ──────────────────────────────────────
  NOVOS = %w[activity bug git-branch git-merge robot broadcast webhook tree-structure signpost stack brackets-curly
             file-code file-csv hard-drives gauge compass].freeze

  test "ícones novos e apelidos (Lucide/Phosphor)" do
    NOVOS.each { assert ComponentesUi::Icons::OUTLINE.key?(_1), "falta #{_1}" }
    view = vc_test_controller.view_context
    { "heartbeat" => "activity", "pulse" => "activity", "kanban" => "view-boards", "palette" => "color-swatch",
      "prohibit" => "ban", "funnel" => "filter", "gear" => "cog", "bot" => "robot", "layers" => "stack" }.each do |de, para|
      assert_equal para, view.ss_icon_name(de), de
    end
    assert_includes view.ss_icon("bug"), %(data-icon="bug")
  end
end
