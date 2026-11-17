require "test_helper"

# v1.2 · o que a auditoria de UX (V02, P03, U03) e as videoaulas (achado 14) do minhas-vendas acharam nas peças genéricas.
class V120WebTest < ComponentTest
  CSS = Pathname(ComponentesUi::Engine.root).join("app/assets/tailwind/componentes_ui")
  JS = Pathname(ComponentesUi::Engine.root).join("app/javascript/componentes_ui/controllers")

  def field(label) = "<div class='ss-field'><label>#{label}</label><input></div>".html_safe

  # ── RepeaterComponent(mobile: :compact) + r.cell ─────────────────────────
  test "RepeaterComponent(mobile: :compact): papel de cada campo e o Detalhes só na linha com detalhe" do
    render_inline(Ss::RepeaterComponent.new(header: %w[Produto Descrição Qtd Unitário Desc. Total], columns: [4, 2, 1, 2, 1, 2], mobile: :compact)) do |r|
      r.row do
        r.cell(:primary) { field("Produto") } + r.cell(:detail) { field("Descrição") } +
          r.cell(:inline) { field("Qtd") + field("Unitário") } + r.cell(:detail) { field("Desc.") } + r.cell(:inline) { field("Total") }
      end + r.row { r.cell(:primary) { field("Produto") } + r.cell(:inline) { field("Qtd") } }
    end
    assert_selector ".ss-repeater.is-compact.has-header"
    rows = page.all(".ss-repeater-row")
    assert_equal 2, rows.size
    first = rows.first
    assert_equal 1, first.all(".ss-repeater-fields > .ss-repeater-cell.is-primary .ss-field").size
    assert_equal 3, first.all(".ss-repeater-cell.is-inline .ss-field").size
    assert_equal 2, first.all(".ss-repeater-cell.is-detail .ss-field").size
    # Um "Detalhes" por linha com detalhe, depois dos campos, fechado, ligado ao ss-repeater.
    btn = first.find(".ss-repeater-fields > button.ss-repeater-more[type=button][aria-expanded=false][data-action='ss-repeater#details']")
    assert_equal "Detalhes", btn.text.strip
    assert_equal 0, rows.last.all(".ss-repeater-more").size
  end

  test "RepeaterComponent sem mobile: :compact não muda (r.cell é só um invólucro, sem Detalhes)" do
    render_inline(Ss::RepeaterComponent.new) { |r| r.row { r.cell(:detail) { field("Lote") } } }
    refute_selector ".ss-repeater.is-compact"
    refute_selector ".ss-repeater-more"
    assert_selector ".ss-repeater-cell.is-detail .ss-field"
    render_inline(Ss::RepeaterComponent.new(mobile: :compact, details_label: "Mais")) { |r| r.row { field("a") + r.cell(:detail) { field("b") } } }
    assert_selector ".ss-repeater-more", text: "Mais"
    assert_raises(ArgumentError) { Ss::RepeaterComponent.new(mobile: :cards) }
    assert_raises(ArgumentError) { render_inline(Ss::RepeaterComponent.new) { |r| r.row { r.cell(:extra) { "x" } } } }
  end

  test "RepeaterComponent(mobile: :compact): o template (linha nova) também ganha o Detalhes; textos em/es" do
    render_inline(Ss::RepeaterComponent.new(mobile: :compact)) do |r|
      r.with_template { r.row { r.cell(:primary) { field("Produto") } + r.cell(:detail) { field("Lote") } } }
      r.row { field("Produto") }
    end
    html = rendered_content
    assert_includes html[html.index("<template")..], "ss-repeater-more"
    assert_equal 0, page.all(".ss-repeater-list .ss-repeater-more").size # a linha de fora não tem detalhe
    I18n.with_locale(:en) do
      render_inline(Ss::RepeaterComponent.new(mobile: :compact)) { |r| r.row { r.cell(:detail) { field("Lot") } } }
      assert_selector ".ss-repeater-more", text: "Details"
    end
    I18n.with_locale(:es) do
      render_inline(Ss::RepeaterComponent.new(mobile: :compact)) { |r| r.row { r.cell(:detail) { field("Lote") } } }
      assert_selector ".ss-repeater-more", text: "Detalles"
    end
  end

  test "linha compacta: CSS do celular (primary inteiro, inline lado a lado, detail recolhido e aberto com erro) e o JS" do
    assert_includes CSS.join("engine.css").read, '@import "./v120_web.css";'
    css = CSS.join("v120_web.css").read
    assert_includes css, ".ss-repeater-cell { display: contents; }"
    assert_includes css, "@media (max-width: 47.99rem)"
    assert_includes css, ".ss-repeater.is-compact .ss-repeater-cell.is-inline > * { flex: 1 1 0; order: 1; }"
    assert_match(/\.is-compact \.ss-repeater-row:not\(\.is-open\):not\(:has\(\.ss-repeater-cell\.is-detail :is\(\.is-invalid, \[aria-invalid="true"\], :user-invalid\)\)\)\s+\.ss-repeater-cell\.is-detail > \* \{ display: none; \}/, css)
    js = JS.join("ss_repeater_controller.js").read
    assert_includes js, "details(event)"
    assert_includes js, 'row.classList.toggle("is-open", open)'
    assert_includes js, 'button.setAttribute("aria-expanded", String(open))'
  end

  # ── Moldura: scroll-padding-top com a barra do topo (P03/O01) ───────────
  test "moldura: o html com .ss-shell-top ganha scroll-padding-top da altura da barra (token --ss-top-room)" do
    css = CSS.join("v120_web.css").read
    assert_includes css, "html:has(.ss-shell-top) { scroll-padding-top: var(--ss-top-room); }"
    assert_match(/--ss-top-room: calc\(max\(var\(--ss-control-h\) \+ 1\.25rem, var\(--ss-control-h\) \+ var\(--ss-pad-y\) \* 2\.4\) \+ 1px \+ env\(safe-area-inset-top, 0px\)/, css)
    assert_includes css, "html:has(.ss-shell-top.is-bare) { scroll-padding-top: 0; }"
    # A conta segue a da barra (v09_layout.css): mínimo control-h + 1.25rem, padding vertical pad-y * 1.2.
    layout = CSS.join("v09_layout.css").read
    assert_includes layout, "min-height: calc(var(--ss-control-h) + 1.25rem); padding: calc(var(--ss-pad-y) * 1.2)"
  end

  # ── BarChartComponent: rótulos do eixo X que não colam em 360 px (U03) ──
  MESES = %w[dez jan fev mar abr mai jun jul ago set out nov].freeze

  def xlabels = page.all("text.ss-barc-xtext").map(&:text)

  test "BarChart: doze meses no desenho de 360 saem de 2 em 2, a partir do mês ativo (sem MARABR)" do
    render_inline(Ss::BarChartComponent.new(title: "12 meses", labels: MESES, series: [{ name: "Faturamento", values: (1..12).to_a }], width: 360, active: 11))
    assert_equal %w[jan mar mai jul set nov], xlabels
    render_inline(Ss::BarChartComponent.new(title: "12 meses", labels: MESES, series: [{ name: "Faturamento", values: (1..12).to_a }], width: 760, active: 11))
    assert_equal MESES, xlabels
  end

  test "BarChart: sem active: a contagem parte do 1º; rótulo longo pede mais espaço; label_every: ainda força" do
    render_inline(Ss::BarChartComponent.new(title: "t", labels: MESES, series: [{ name: "x", values: (1..12).to_a }], width: 360))
    assert_equal %w[dez fev abr jun ago out], xlabels
    dias = %w[Seg\ 10/11 Ter\ 11/11 Qua\ 12/11 Qui\ 13/11 Sex\ 14/11 Sáb\ 15/11 Dom\ 16/11]
    render_inline(Ss::BarChartComponent.new(title: "t", labels: dias, series: [{ name: "x", values: (1..7).to_a }]))
    assert_equal 4, xlabels.size # 9 letras não cabem em 76 unidades: de 2 em 2
    render_inline(Ss::BarChartComponent.new(title: "t", labels: MESES, series: [{ name: "x", values: (1..12).to_a }], width: 360, label_every: 1))
    assert_equal 12, xlabels.size
  end

  test "LineChart: a mesma conta dos rótulos (doze meses em 360 de 2 em 2, a partir do ativo)" do
    render_inline(Ss::LineChartComponent.new(title: "t", labels: MESES, series: [{ name: "x", values: (1..12).to_a }], width: 360, active: 11))
    assert_equal %w[jan mar mai jul set nov], xlabels
  end

  # ── DataTableComponent: nome legível da caixa de cada linha (achado 14) ──
  ROWS = [{ id: "0b6f3f5e-6a2e-4c55-9d1e-6b9a2f0e7c11", numero: 2904, cliente: "Bar do Tonhão & Cia" },
          { id: "4c1d9a77-3f0b-4f7e-8a2d-1e5c7b9d0f22", numero: 2905, cliente: "" }].freeze

  def table(**opts, &cols)
    cols ||= ->(t) { t.column(:cliente, "Cliente") && t.column(:numero, "Nº") }
    render_inline(Ss::DataTableComponent.new(rows: ROWS, id: "pedidos", caption: "Pedidos", tools: false, selectable: true, **opts), &cols)
    page.all("td.ss-dt-check input[type=checkbox]").map { _1["aria-label"] }
  end

  test "DataTable: a caixa da linha diz o título da linha, nunca o id" do
    labels = table
    assert_equal ["Selecionar Bar do Tonhão & Cia", "Selecionar linha 2"], labels
    labels.each { |l| refute_match(/\h{8}-\h{4}/, l) }
    # A coluna de título (mobile: :title) vence a 1ª coluna; o HTML do bloco sai.
    labels = table(mobile: :compact) do |t|
      t.column(:numero, "Nº", mobile: :meta)
      t.column(:cliente, "Cliente", mobile: :title) { |r| "<a href='/p/#{r[:numero]}'>#{ERB::Util.h(r[:cliente])}</a>".html_safe }
    end
    assert_equal "Selecionar Bar do Tonhão & Cia", labels.first
  end

  test "DataTable(select_label:): proc com o texto inteiro ou o campo da linha; en/es" do
    assert_equal ["Selecionar pedido 2904", "Selecionar pedido 2905"], table(select_label: ->(r) { "Selecionar pedido #{r[:numero]}" })
    assert_equal ["Selecionar 2904", "Selecionar 2905"], table(select_label: :numero)
    I18n.with_locale(:en) { assert_equal ["Select Bar do Tonhão & Cia", "Select row 2"], table }
    I18n.with_locale(:es) { assert_equal ["Seleccionar Bar do Tonhão & Cia", "Seleccionar fila 2"], table }
  end
end
