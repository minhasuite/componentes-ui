require "test_helper"

# v0.24 · auditoria de UX de novembro (minhas-vendas C01–C04, meu-gestor B05–B16, U07, U08, U14).
# Cada teste reproduz o achado: falha na v0.23.6 e passa com a correção.
class V24WebTest < ComponentTest
  ROOT = Pathname(ComponentesUi::Engine.root)
  CSS = ROOT.join("app/assets/tailwind/componentes_ui")
  JS = ROOT.join("app/javascript/componentes_ui/controllers")

  class Empresa
    include ActiveModel::Model
    include ActiveModel::Attributes
    def self.model_name = ActiveModel::Name.new(self, nil, "Empresa")
    attribute :nome, :string
    validates :nome, presence: true
  end

  PEDIDOS = [{ id: 1, numero: "#2904", cliente: "Sabor Caseiro", emissao: "14/11/2026", status: "Aguarda", total: 2380 }].freeze

  def pedidos(**opts, &cols)
    cols ||= lambda do |t|
      t.column :numero, "Nº", mobile: :meta
      t.column :cliente, "Cliente", mobile: :title
      t.column :emissao, "Emissão", mobile: :meta
      t.column :status, "Situação", mobile: :badge
      t.column :total, "Total", format: :money, mobile: :value
    end
    render_inline(Ss::DataTableComponent.new(rows: PEDIDOS, id: "pedidos", caption: "Pedidos", **opts), &cols)
  end

  # ── C01: linha compacta no celular ──
  test "C01 DataTable(mobile: :compact): cada célula diz o papel na linha compacta" do
    pedidos(mobile: :compact)
    assert_selector ".ss-dt.is-compact"
    assert_selector "td[data-col='cliente'][data-mobile='title']", text: "Sabor Caseiro"
    assert_selector "td[data-col='total'][data-mobile='value']"
    assert_selector "td[data-col='numero'][data-mobile='meta']"
    assert_selector "td[data-col='emissao'][data-mobile='meta']"
    assert_selector "td[data-col='status'][data-mobile='badge']"
  end

  test "C01 sem papel: 1ª coluna título, 1ª de dinheiro valor, resto meta; ações no fim" do
    render_inline(Ss::DataTableComponent.new(rows: PEDIDOS, id: "p", caption: "P", mobile: :compact)) do |t|
      t.column :cliente, "Cliente"
      t.column :emissao, "Emissão"
      t.column :total, "Total", format: :money
      t.actions { "<a href='#'>Abrir</a>".html_safe }
    end
    assert_selector "td[data-col='cliente'][data-mobile='title']"
    assert_selector "td[data-col='emissao'][data-mobile='meta']"
    assert_selector "td[data-col='total'][data-mobile='value']"
    assert_selector "td[data-col='_actions'][data-mobile='actions']"
  end

  test "C01 sem mobile: (cartões) e com stack: false nada muda" do
    pedidos
    refute_selector ".ss-dt.is-compact"
    refute_selector "td[data-mobile]"
    pedidos(mobile: :compact, stack: false)
    assert_selector ".ss-dt.is-scroll"
    refute_selector ".ss-dt.is-compact"
    assert_raises(ArgumentError) { pedidos(mobile: :lista) }
  end

  test "C01 CSS: linha compacta em duas linhas e sem o rótulo de cada célula" do
    css = CSS.join("v24_web.css").read
    assert_includes css, %(.ss-dt.is-compact .ss-table td[data-label]::before { content: none; })
    assert_includes css, %(td[data-mobile="title"] { order: 1;)
    assert_includes css, %(td[data-mobile="meta"] ~ td[data-mobile="meta"]::before { content: "·";)
    assert_includes CSS.join("engine.css").read, %(@import "./v24_web.css";)
  end

  # ── C02/U14: troca de empresa ──
  test "C02 uma empresa: nome parado, sem menu nem seta, com title e reticências" do
    render_inline(Ss::AppShellComponent.new(brand: "X", tenants: [{ name: "Atacadão Teste do Nordeste", href: "/t/1", current: true }])) { "c" }
    refute_selector "details.ss-shell-tenant"
    refute_selector ".ss-shell-tenant-menu", visible: :all
    assert_selector ".ss-shell-tenant.is-single[title='Atacadão Teste do Nordeste'] .ss-shell-tenant-name", text: "Atacadão Teste do Nordeste"
  end

  test "C02 duas empresas: menu de troca com o nome inteiro no title; single_tenant: false esconde a única" do
    render_inline(Ss::AppShellComponent.new(brand: "X", tenants: [{ name: "Loja Centro", href: "/t/1", current: true }, { name: "Loja Sul", href: "/t/2" }])) { "c" }
    assert_selector "details.ss-shell-tenant summary[title='Loja Centro'] .ss-shell-tenant-name", text: "Loja Centro"
    assert_selector ".ss-shell-tenant-item[title='Loja Sul'] .ss-shell-tenant-name", text: "Loja Sul", visible: :all
    render_inline(Ss::AppShellComponent.new(brand: "X", single_tenant: false, tenants: [{ name: "Loja", current: true }])) { "c" }
    refute_selector ".ss-shell-tenant", visible: :all
  end

  test "U07 busca e marca da barra de cima com nome acessível" do
    render_inline(Ss::AppShellComponent.new(brand: "Meu Gestor", brand_url: "/")) { "c" }
    assert_selector "button.ss-shell-search[aria-label]"
    assert_selector "a.ss-shell-brand-link[aria-label='Meu Gestor']", minimum: 1
  end

  # ── C04/B07/E02b: barras de salvar e configurações por área ──
  test "C04 .ss-actions: faixa opaca de largura inteira (não a pílula translúcida que flutuava sobre o campo)" do
    rule = CSS.join("engine.css").read[/\.ss-actions \{[^}]*\}/m]
    refute_includes rule, "width: fit-content"
    refute_includes rule, "backdrop-filter"
    assert_includes rule, "grid-column: 1 / -1"
    assert_includes rule, "background: var(--surface)"
  end

  test "C04 o campo em foco para acima da barra (scroll-margin) em form com barra fixa ou botão flutuante" do
    css = CSS.join("v24_web.css").read
    assert_match(/form:has\(\.ss-actions, \.ss-sticky-bar\[data-visible\], \.ss-form-actions\.is-sticky\) [^{]*\{\s*scroll-margin-bottom: var\(--ss-bar-room\)/, css)
    assert_match(/body:has\(\.ss-fab:not\(\.is-static\), \.ss-speed-dial:not\(\.is-static\)\) [^{]*\{\s*scroll-margin-bottom/, css)
    assert_includes css, "html:has(.ss-actions, .ss-sticky-bar[data-visible]) { scroll-padding-bottom: var(--ss-bar-room); }"
  end

  test "C04 SettingsLayout(form:): a área é um formulário com o próprio Salvar (barra que aparece ao mudar)" do
    render_inline(Ss::SettingsLayoutComponent.new) do |s|
      s.with_section(id: "empresa", title: "Empresa", form: { model: Empresa.new, url: "/config/empresa" }, save_label: "Salvar empresa") do |sec|
        sec.form.ss_text_field(:nome, label: "Nome")
      end
      s.with_section(id: "conta", title: "Conta")
    end
    assert_selector "section#empresa.has-form form.ss-form.ss-settings-form[action='/config/empresa'][data-controller~='ss-validate'] input#empresa_nome[required]"
    assert_selector "section#empresa form .ss-sticky-bar[data-controller='ss-dirty'] button[type=submit]", text: "Salvar empresa", visible: :all
    refute_selector "section#conta form"
  end

  test "C04 SettingsLayout com href: áreas em páginas (o menu navega, só a atual aparece, sem scrollspy)" do
    render_inline(Ss::SettingsLayoutComponent.new) do |s|
      s.with_section(id: "empresa", title: "Empresa", href: "/config/empresa", current: true) { "Campos da empresa" }
      s.with_section(id: "equipe", title: "Equipe", href: "/config/equipe") { "Campos da equipe" }
    end
    assert_selector ".ss-settings.is-pages"
    refute_selector ".ss-settings[data-controller~='ss-scrollspy']"
    assert_selector "nav a[href='/config/empresa'][aria-current='page']"
    assert_selector "nav a[href='/config/equipe']:not([aria-current])"
    assert_selector "section#empresa", text: "Campos da empresa"
    refute_selector "section#equipe"
  end

  # ── B10: paleta de comandos ──
  test "B10 um Esc fecha a paleta (o input search não consome o 1º) e o foco sai do campo ao fechar" do
    js = JS.join("ss_command_controller.js").read
    assert_match(/event\.key === "Escape"[^\n]*\n\s*\/\/[^\n]*\n\s*event\.preventDefault\(\)\n\s*event\.stopPropagation\(\)\n\s*this\.element\.close\(\)/, js)
    assert_includes js, "if (this.element.contains(document.activeElement)) document.activeElement.blur()"
    assert_includes js, "this.opener.focus({ preventScroll: true })"
  end

  # ── B05/B06: chat ──
  test "B05/B06 chat: vazio e bolha não passam do painel; a tabela da resposta rola dentro da bolha" do
    css = CSS.join("v24_web.css").read
    assert_includes css, ".ss-chat-empty { align-self: stretch; margin-inline: 0; max-width: 100%; min-width: 0;"
    assert_includes css, ".ss-chat-empty :is(.ss-btn, .ss-chip, a, button) { max-width: 100%; white-space: normal;"
    assert_includes css, ".ss-bubble .ss-dt { grid-template-columns: minmax(0, 1fr);"
    assert_includes css, ".ss-bubble .ss-dt-scroll { overflow-x: auto; }"
  end

  # ── U07: alvo de toque ──
  test "U07 alvo de 44 px só com ponteiro grosso: botão pequeno, abas e área invisível no botão de ícone" do
    css = CSS.join("v24_web.css").read
    coarse = css[/@media \(pointer: coarse\) \{.*\z/m]
    assert coarse, "falta o bloco de toque"
    assert_includes coarse, ".ss-btn-sm { min-height: max(var(--ss-control-h-sm), var(--ss-target)); }"
    assert_includes coarse, ".ss-tab, .ss-subnav a, .ss-settings-nav a"
    assert_includes coarse, "width: max(100%, var(--ss-target)); height: max(100%, var(--ss-target))"
  end

  # ── B13: validação do formulário ──
  test "B13 ss_form_with liga o ss-validate (novalidate pelo JS: sem dica nativa ao passar o mouse)" do
    view = vc_test_controller.view_context
    html = Capybara.string(view.ss_form_with(model: Empresa.new, url: "/e", data: { controller: "outro" }) { |f| f.ss_text_field(:nome) })
    assert html.has_selector?("form.ss-form[data-controller='outro ss-validate'][data-ss-validate-required-value='Preencha este campo.'] input[required]")
    native = Capybara.string(view.ss_form_with(model: Empresa.new, url: "/e", validate: :native) { |f| f.ss_text_field(:nome) })
    refute native.has_selector?("form[data-controller~='ss-validate']")
    js = JS.join("ss_validate_controller.js").read
    assert_includes js, "this.element.noValidate = true"
    assert_includes js, "event.submitter?.formNoValidate"
    assert_includes js, %(this.element.addEventListener("submit", this.onSubmit, true))
  end

  # ── B16: espera da IA no cartão ──
  test "B16 AiInsightCard pensando: Cancelar e o aviso de que a tela está livre" do
    render_inline(Ss::AiInsightCardComponent.new(thinking: true, cancel: { url: "/ia/cancelar", method: :delete }))
    assert_selector ".ss-ai-card.is-thinking .ss-ai-thinking form button.ss-ai-cancel", text: "Cancelar"
    assert_selector ".ss-ai-hint", text: "Pode continuar usando a tela."
    render_inline(Ss::AiInsightCardComponent.new(thinking: true, thinking_hint: "", cancel: { label: "Parar", data: { action: "ia#parar" } }))
    assert_selector "button.ss-ai-cancel[type=button][data-action='ia#parar']", text: "Parar"
    refute_selector ".ss-ai-hint"
  end

  # ── U08: botão flutuante ──
  test "U08 página com botão flutuante e sem moldura ganha folga no fim" do
    css = CSS.join("v24_web.css").read
    assert_includes css, "body:has(.ss-fab:not(.is-static), .ss-speed-dial:not(.is-static)):not(:has(.ss-shell)) { padding-bottom:"
  end
end
