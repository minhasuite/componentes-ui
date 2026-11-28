require "test_helper"

# v0.28 · a segunda rodada do meulog: o que ele montou à mão vira peça, e o texto apagado passa AA.
class V28WebTest < ComponentTest
  ROOT = Pathname(ComponentesUi::Engine.root)
  CSS = ROOT.join("app/assets/tailwind/componentes_ui")

  class Empresa
    include ActiveModel::Model
    include ActiveModel::Attributes
    attribute :nome, :string
    def self.model_name = ActiveModel::Name.new(self, nil, "Empresa")
  end

  # ── Texto apagado ───────────────────────────────────────────────────
  test "--muted claro é o de AA sobre superfície tingida (conferido também pelo paletas/gerar.py --check)" do
    engine = CSS.join("engine.css").read
    assert_includes engine, "--muted: #615e78;"
    refute_includes engine, "--muted: #6e6a88;"
    assert_includes engine, "%23615e78" # a seta do select segue a cor
  end

  # ── max: dos gráficos ───────────────────────────────────────────────
  test "BarChart(max:) e LineChart(max:): o topo da escala é o max; valor acima alarga" do
    bar = Ss::BarChartComponent.new(title: "t", labels: %w[a b], series: [{ name: "x", values: [3, 5] }], max: 40)
    assert_equal [0.0, 40.0], bar.range
    acima = Ss::BarChartComponent.new(title: "t", labels: %w[a b], series: [{ name: "x", values: [3, 50] }], max: 40)
    # v1.14.7: a escala é redonda (ComponentesUi::ChartScale): o 50 alarga até 60 e o 5 vai a 6 (era 5,4).
    assert_equal 60.0, acima.range.last
    sem = Ss::BarChartComponent.new(title: "t", labels: %w[a b], series: [{ name: "x", values: [3, 5] }])
    assert_equal 6.0, sem.range.last
    linha = Ss::LineChartComponent.new(title: "t", labels: %w[a b], series: [{ name: "x", values: [3, 5] }], max: 40)
    assert_equal [0.0, 40.0], linha.range
    render_inline(bar)
    assert_selector "text.ss-barc-ytext", text: "40", visible: :all
  end

  # ── Faixa por dia ───────────────────────────────────────────────────
  DIAS = [{ date: Date.new(2026, 11, 1), tone: :ok, text: "100% no ar" }, { date: Date.new(2026, 11, 2), tone: :warn, text: "2 falhas" },
          { date: Date.new(2026, 11, 3), tone: :bad, text: "fora 3 h" }, { date: Date.new(2026, 11, 4), tone: :none },
          { date: "05/11", tone: :xyz }].freeze

  test "DayStrip: um traço por dia com o tom, dica com data e texto, pontas e tabela para o leitor" do
    render_inline(Ss::DayStripComponent.new(title: "Disponibilidade", days: DIAS, start_label: "há 5 dias", end_label: "hoje"))
    assert_selector "figure.ss-day-strip .ss-day-strip-days[aria-hidden=true] span.ss-day", count: 5
    assert_selector ".ss-day[data-tone=ok]", count: 1
    assert_selector ".ss-day[data-tone=warn]", count: 1
    assert_selector ".ss-day[data-tone=bad][title*='fora 3 h']", count: 1
    assert_selector ".ss-day[data-tone=none]", count: 2 # sem dado e o tom desconhecido
    assert_selector ".ss-day-strip-ends", text: "há 5 dias"
    assert_selector "table.ss-sr tbody tr", count: 5, visible: :all
    assert_selector "table.ss-sr td", text: "Fora · fora 3 h", visible: :all
    assert_selector "figcaption.ss-sr", text: "Disponibilidade", visible: :all
  end

  test "DayStrip: sem dias não desenha; pontas padrão são o primeiro e o último dia" do
    render_inline(Ss::DayStripComponent.new(title: "x", days: []))
    refute_selector ".ss-day-strip"
    render_inline(Ss::DayStripComponent.new(title: "x", days: [{ label: "seg", tone: :ok }, { label: "ter", tone: :ok }], show_title: true))
    assert_selector ".ss-day-strip-ends span", text: "seg"
    assert_selector ".ss-day-strip-ends span", text: "ter"
    assert_selector "figcaption.ss-day-strip-title", text: "x"
    css = CSS.join("v28_web.css").read
    assert_match(/\.ss-day-strip-days \{[^}]*gap: 3px/, css) # os dias não encostam
  end

  # ── Busca solta ─────────────────────────────────────────────────────
  test "FilterInput: o campo do ss-filter sem <form>, com rótulo escondido e Esc que limpa" do
    render_inline(Ss::FilterInputComponent.new(label: "Buscar no manual", placeholder: "Filtrar", id: "busca"))
    refute_selector "form"
    assert_selector "div.ss-search.ss-filter-input[role=search] svg"
    assert_selector "label.ss-sr[for=busca]", text: "Buscar no manual", visible: :all
    assert_selector "input#busca[type=search][placeholder=Filtrar][data-ss-filter-target=input][autocomplete=off]"
    assert_includes page.find("input#busca")["data-action"], "keydown.esc->ss-filter#clear"
    render_inline(Ss::FilterInputComponent.new)
    assert_selector "input[placeholder='Buscar na lista']"
  end

  # ── QR ──────────────────────────────────────────────────────────────
  test "QrCard(qr_label:) dá nome ao QR; sem ele, o do Pix" do
    render_inline(Ss::QrCardComponent.new(code: "ABC", qr_label: "QR do autenticador")) { "<svg></svg>".html_safe }
    assert_selector ".ss-qr-box[role=img][aria-label='QR do autenticador']"
    render_inline(Ss::QrCardComponent.new(code: "ABC")) { "<svg></svg>".html_safe }
    assert_selector ".ss-qr-box[aria-label='QR Code para pagamento']"
  end

  # ── Título e subtítulo que quebram ──────────────────────────────────
  test "CardHeader(wrap: true) e ListItem(subtitle_wrap: true); o texto inteiro no title= quando corta" do
    render_inline(Ss::CardHeaderComponent.new(title: "O relatório que a ferramenta manda toda manhã", wrap: true))
    assert_selector ".ss-card-head.is-wrap .ss-card-title[title='O relatório que a ferramenta manda toda manhã']"
    render_inline(Ss::ListItemComponent.new(title: "x", subtitle: "um subtítulo comprido", subtitle_wrap: true))
    assert_selector ".ss-item-sub.is-wrap"
    refute_selector ".ss-item-sub[title]"
    render_inline(Ss::ListItemComponent.new(title: "x", subtitle: "um subtítulo comprido"))
    assert_selector ".ss-item-sub[title='um subtítulo comprido']"
    css = CSS.join("v28_web.css").read
    assert_match(/\.ss-card-head\.is-wrap \.ss-card-title \{[^}]*-webkit-line-clamp: 2/, css)
  end

  # ── Subnav ──────────────────────────────────────────────────────────
  test "Subnav: sem item atual, o menu mostra o rótulo (não o primeiro item); count_label: troca o contador" do
    itens = [{ label: "Geral", href: "/a", current: false }, { label: "Usuários", href: "/b", current: false }]
    render_inline(Ss::SubnavComponent.new(label: "Verbetes", items: itens, count_label: "%{n} itens"))
    assert_selector "summary.ss-subnav-current[aria-label='Verbetes'] .ss-subnav-label", text: "Verbetes"
    assert_selector ".ss-subnav-count", text: "2 itens"
    refute_selector "a[aria-current]"
    render_inline(Ss::SubnavComponent.new(items: [{ label: "Geral", href: "/a", current: true }], count_label: false))
    assert_selector "summary .ss-subnav-label", text: "Geral"
    refute_selector ".ss-subnav-count"
  end

  # ── Layouts e value-row (CSS) ───────────────────────────────────────
  test "Masonry, AsideLayout e value-row: as correções de largura estão na folha" do
    css = CSS.join("v28_web.css").read
    assert_match(/\.ss-masonry \{[^}]*align-self: start; height: auto/, css)
    assert_includes css, ".ss-aside-layout, .ss-aside-layout-main, .ss-aside-layout-side { grid-template-columns: minmax(0, 1fr); }"
    assert_match(/\.ss-value-row > :last-child \{[^}]*white-space: normal; overflow-wrap: anywhere/, css)
    assert_includes CSS.join("engine.css").read, '@import "./v28_web.css";'
  end

  # ── Fieldset no SettingsLayout ──────────────────────────────────────
  test "f.ss_fieldset dentro da seção com form: do SettingsLayout (antes: NoMethodError no componente)" do
    render_inline(Ss::SettingsLayoutComponent.new) do |s|
      s.with_section(id: "empresa", title: "Empresa", form: { model: Empresa.new, url: "/config/empresa" }) do |sec|
        sec.form.ss_fieldset(legend: "Horário", help: "Vale para todos os dias", class: "grid gap-2") { sec.form.ss_text_field(:nome, label: "Nome") }
      end
    end
    assert_selector "section#empresa form fieldset.ss-fieldset legend", text: "Horário"
    assert_selector "fieldset.ss-fieldset[aria-describedby] small.ss-field-help", text: "Vale para todos os dias"
    assert_selector "fieldset .ss-field-group-body.grid input#empresa_nome"
  end

  # ── Ordenar com rótulo de ação ──────────────────────────────────────
  test "DataTable: o link de ordenar diz ao leitor de tela o que o Enter faz" do
    rows = [{ id: 1, nome: "A", total: 10 }]
    render_inline(Ss::DataTableComponent.new(rows:, id: "dt28", caption: "Pedidos", sort: "total", dir: "asc")) do |t|
      t.column(:nome, "Nome", sortable: true)
      t.column(:total, "Total", sortable: true)
    end
    assert_selector "th[aria-sort=ascending] a.ss-sort[aria-label='Total: ordenar decrescente']"
    assert_selector "th[aria-sort=none] a.ss-sort[aria-label='Nome: ordenar crescente']"
  end

  # ── Fonte de exibição por página ────────────────────────────────────
  test "ss_display_font_tag(self_hosted: true) e o slot :ss_head (ss_page_head)" do
    view = vc_test_controller.view_context
    html = view.ss_display_font_tag(self_hosted: true).to_s
    assert_match %r{componentes_ui/fonts_display-\h+\.css}, html
    refute_includes html, "googleapis"
    assert_equal "", view.ss_page_head.to_s
    view.content_for(:ss_head, html.html_safe)
    assert_includes view.ss_page_head, "fonts_display"
  end

  # ── ss_select multiple sem o hidden ─────────────────────────────────
  test "f.ss_select(multiple: true, include_hidden: false) não põe o \"\" escondido" do
    view = vc_test_controller.view_context
    com = view.ss_form_with(model: Empresa.new, url: "/e") { |f| f.ss_select(:nome, [%w[A a], %w[B b]], multiple: true) }
    sem = view.ss_form_with(model: Empresa.new, url: "/e") { |f| f.ss_select(:nome, [%w[A a], %w[B b]], multiple: true, include_hidden: false) }
    escondido = /<input name="empresa\[nome\]\[\]" type="hidden" value="" \/>/
    assert_match escondido, com
    refute_match escondido, sem
  end
end
