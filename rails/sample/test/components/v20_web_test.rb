require "test_helper"

# v0.20 · o que o minhas-vendas e o meu-gestor acharam ao migrar para 100% de componentização (pares do Flutter).
class V20WebTest < ComponentTest
  CSS = Pathname(ComponentesUi::Engine.root).join("app/assets/tailwind/componentes_ui")
  JS = Pathname(ComponentesUi::Engine.root).join("app/javascript/componentes_ui/controllers")
  include ComponentesUi::Helpers

  def form(&block)
    view = vc_test_controller.view_context
    @page = Capybara.string(view.ss_form_with(url: "/x", scope: :p, &block).to_s)
  end

  def page = @page || super

  test "form: hide_label esconde o rótulo só da vista (texto, select, rádio, caixa)" do
    form do |f|
      f.ss_text_field(:busca, label: "Buscar", hide_label: true) + f.ss_select(:uf, %w[CE SP], label: "UF", hide_label: true) +
        f.ss_radio_buttons(:tipo, [%w[PF pf], %w[PJ pj]], label: "Tipo", hide_label: true) +
        f.ss_check_box(:ok, label: "Aceito", hide_label: true)
    end
    assert_selector "label.ss-sr[for=p_busca]", text: "Buscar"
    assert_selector "label.ss-sr[for=p_uf]", text: "UF"
    assert_selector "legend.ss-label.ss-sr", text: "Tipo"
    assert_selector "label.ss-check span.ss-sr", text: "Aceito"
    form { |f| f.ss_text_field(:nome, label: "Nome") }
    assert_selector "label[for=p_nome]:not(.ss-sr)", text: "Nome"
  end

  test "form: ss_radio_buttons(checked:) marca sem model; sem checked: nada marcado" do
    form { |f| f.ss_radio_buttons(:tipo, [%w[PF pf], %w[PJ pj]], label: "Tipo", checked: "pj") }
    assert_selector "input[type=radio][value=pj][checked]"
    assert_no_selector "input[type=radio][value=pf][checked]"
    form { |f| f.ss_radio_buttons(:tipo, [%w[PF pf], %w[PJ pj]], label: "Tipo", checked: :pf) }
    assert_selector "input[type=radio][value=pf][checked]"
    form { |f| f.ss_radio_buttons(:tipo, [%w[PF pf], %w[PJ pj]], label: "Tipo") }
    assert_no_selector "input[type=radio][checked]"
  end

  test "form: ss_check_box(id:) liga o rótulo ao id passado" do
    form { |f| f.ss_check_box(:ativo, label: "Ativo", id: "ativo-3") }
    assert_selector "input[type=checkbox]#ativo-3"
    assert_selector "label.ss-check[for=ativo-3]", text: "Ativo"
    form { |f| f.ss_text_field(:nome, label: "Nome", id: "nome-3") }
    assert_selector "label[for=nome-3]"
  end

  test "form: mask: liga o ss-mask com teclado, autocomplete e tamanho; máscara errada avisa" do
    form { |f| f.ss_text_field(:doc, label: "CPF/CNPJ", mask: :document) + f.ss_telephone_field(:fone, label: "Fone", mask: :phone) + f.ss_text_field(:cep, label: "CEP", mask: :cep) }
    assert_selector "input#p_doc[data-controller~=ss-mask][data-ss-mask-kind-value=document][inputmode=numeric][maxlength='18'][data-action*='input->ss-mask#format']"
    assert_selector "input#p_fone[data-ss-mask-kind-value=phone][inputmode=tel][autocomplete=tel][maxlength='15']"
    assert_selector "input#p_cep[data-ss-mask-kind-value=cep][autocomplete=postal-code][maxlength='9']"
    assert_raises(ArgumentError) { form { |f| f.ss_text_field(:x, mask: :rg) } }
    assert JS.join("ss_mask_controller.js").read.include?("[2, 5, 8, 12]")
  end

  test "ButtonComponent ghost/outline com tone: :danger tem o CSS do perigo" do
    render_inline(Ss::ButtonComponent.new(label: "Excluir", icon: "trash", variant: :ghost, tone: :danger))
    assert_selector "button.ss-btn.ss-btn-ghost.is-danger", text: "Excluir"
    css = CSS.join("v20_web.css").read
    assert_includes css, ".ss-btn-ghost.is-danger, .ss-btn-outline.is-danger { color: var(--danger); }"
  end

  test "ListItemComponent: título, subtítulo e valor em tom, ícone, link e apagado" do
    render_inline(Ss::ListItemComponent.new(title: "Boleto 12", subtitle: "Vence hoje", subtitle_tone: :danger, value: "R$ 120,00",
                                            value_caption: "2/3", value_tone: :warning, icon: "document-text", tone: :warn, href: "/t/12", dimmed: true))
    assert_selector "a.ss-item.is-dimmed[href='/t/12'] .ss-item-icon svg"
    assert_selector ".ss-item-main strong", text: "Boleto 12"
    assert_selector ".ss-item-main small.ss-item-sub[data-tone=danger]", text: "Vence hoje"
    assert_selector ".ss-item-value[data-tone=warn] small", text: "2/3"
    render_inline(Ss::ListItemComponent.new(title: "Sem link")) { "›" }
    assert_selector "div.ss-item:not(.is-dimmed)", text: "›"
    refute_selector "[data-tone]"
  end

  test "KpiCardComponent(value_tone:) e CardHeaderComponent(eyebrow:)" do
    render_inline(Ss::KpiCardComponent.new(label: "Saldo", value: "−R$ 10,00", value_tone: :danger))
    assert_selector ".ss-kpi-card-value[data-tone=danger]"
    render_inline(Ss::KpiCardComponent.new(label: "Saldo", value: "R$ 10,00"))
    refute_selector ".ss-kpi-card-value[data-tone]"
    render_inline(Ss::CardHeaderComponent.new(title: "Ruptura", eyebrow: "Estoque · urgente", eyebrow_tone: :danger))
    assert_selector ".ss-card-head-text > p.ss-card-eyebrow[data-tone=danger] + .ss-card-title", text: "Ruptura"
  end

  Row = Struct.new(:id, :nome, :total, :ativo, keyword_init: true)

  test "DataTableComponent: row_href, coluna parada com cabeçalho montado, total, flat e linha apagada" do
    rows = [Row.new(id: 1, nome: "Ana", total: 10, ativo: true), Row.new(id: 2, nome: "Bia", total: 5, ativo: false)]
    render_inline(Ss::DataTableComponent.new(rows:, id: "t", caption: "Clientes", tools: false, flat: true,
                                             row_href: ->(r) { "/c/#{r.id}" }, row_attrs: ->(r) { { class: ("is-dimmed" unless r.ativo) } })) do |t|
      t.column :nome, "Cliente", sticky: true, header: "<b>Cli</b>ente".html_safe
      t.column :total, "Total", format: :number
      t.total :total, "15"
    end
    assert_selector ".ss-dt.is-flat.has-sticky > .ss-dt-scroll:not(.ss-card)"
    assert_selector "thead th.is-sticky b", text: "Cli"
    assert_selector "tbody tr.is-link[data-href='/c/1'][tabindex='0'][data-action*='click->ss-table#go'][data-action*='keydown->ss-table#go']"
    assert_selector "tbody tr.is-link.is-dimmed[data-href='/c/2']"
    assert_selector "tbody td.is-sticky[data-label=Cliente]", text: "Ana"
    assert_selector "tfoot tr.ss-dt-total td.is-sticky", text: "Total"
    assert_selector "tfoot tr.ss-dt-total td.r", text: "15"
    assert JS.join("ss_table_controller.js").read.include?("go(event)")
  end

  test "DataTableComponent: footer livre, total por bloco e sem total = sem tfoot" do
    rows = [Row.new(id: 1, nome: "Ana", total: 10)]
    render_inline(Ss::DataTableComponent.new(rows:, id: "t2", caption: "C", tools: false)) do |t|
      t.column :nome, "Cliente"
      t.column :total, "Total"
      t.total(:nome, "Geral")
      t.total(:total) { |rs| rs.sum(&:total).to_s }
      t.footer { |rs| "#{rs.size} linha" }
    end
    assert_selector ".ss-card.ss-dt-scroll tfoot tr.ss-dt-total td", text: "Geral"
    assert_selector "tfoot tr.ss-dt-total td", text: "10"
    assert_selector "tfoot tr.ss-dt-foot td[colspan='2']", text: "1 linha"
    render_inline(Ss::DataTableComponent.new(rows:, id: "t3", caption: "C", tools: false)) { |t| t.column :nome, "Cliente" }
    refute_selector "tfoot"
    refute_selector "tr.is-link"
  end

  test "StickyActionBarComponent#with_summary: resumo livre no lugar da mensagem" do
    render_inline(Ss::StickyActionBarComponent.new(always: true)) do |b|
      b.with_summary { "3 itens · R$ 120,00" }
      "<button>Fechar</button>".html_safe
    end
    assert_selector ".ss-sticky-bar .ss-sticky-bar-summary[aria-live=polite]", text: "3 itens"
    refute_selector ".ss-sticky-bar-msg"
    render_inline(Ss::StickyActionBarComponent.new)
    assert_selector ".ss-sticky-bar-msg"
  end

  test "CommandPalette e Combobox: ação ao lado da busca" do
    render_inline(Ss::CommandPaletteComponent.new(id: "prod", groups: [])) do |p|
      p.with_action { "<button class='ler'>Ler</button>".html_safe }
    end
    assert_selector ".ss-command .ss-command-bar > input[type=search] + .ss-command-actions button.ler"
    render_inline(Ss::CommandPaletteComponent.new(id: "prod2", groups: []))
    refute_selector ".ss-command-bar"
    render_inline(Ss::ComboboxComponent.new(name: "x", label: "Produto", options: [])) do |c|
      c.with_action { "<button class='ler'>Ler</button>".html_safe }
    end
    assert_selector ".ss-combobox .ss-combobox-row > .ss-combobox-box + .ss-combobox-actions button.ler"
  end

  test "NodeCanvasComponent: palco com parent-drawflow primeiro, atributos no palco, bloco por cima" do
    render_inline(Ss::NodeCanvasComponent.new(height: "60vh", readonly: true, node_delete: false, sketch: true, data: { canvas_target: "stage" })) { "<div class='barra'></div>".html_safe }
    el = page.find(".ss-node-canvas-wrap > .ss-node-canvas")
    assert_equal "parent-drawflow", el[:class].split.first
    assert_selector ".ss-node-canvas.is-grid.is-readonly.is-node-delete-off.is-sketch[role=application][aria-label='Editor de fluxo'][tabindex='0'][data-canvas-target=stage]"
    assert_includes el[:style], "--ss-node-canvas-h: 60vh"
    assert_selector ".ss-node-canvas-wrap > .barra"
    css = CSS.join("v20_web.css").read
    %w[.drawflow-node .output_1 .output_2 .main-path .drawflow-delete is-changed is-refused .ss-node-label].each { |s| assert_includes css, s }
  end

  test "RepeaterComponent: linhas com ×, template, adicionar e textos" do
    render_inline(Ss::RepeaterComponent.new(add_label: "Adicionar item", min: 1, label: "Itens")) do |r|
      r.with_template { r.row { "<input name='p[itens][NEW_RECORD][nome]'>".html_safe } }
      r.row { "<input name='p[itens][0][nome]'>".html_safe }
    end
    assert_selector ".ss-repeater[data-controller=ss-repeater][data-ss-repeater-min-value='1'][role=group][aria-label=Itens]"
    assert_selector ".ss-repeater-list .ss-repeater-row[data-ss-repeater-target=row] .ss-repeater-fields input"
    assert_selector ".ss-repeater-row button.ss-repeater-remove[data-action='ss-repeater#remove'][aria-label='Remover linha']"
    assert_includes page.native.to_html, "NEW_RECORD"
    assert_selector "template[data-ss-repeater-target=template]", visible: :all
    assert_selector "button.ss-repeater-add[data-action='ss-repeater#add']", text: "Adicionar item"
  end

  test "TextLink, TermsNotice e EditableValue" do
    render_inline(Ss::TextLinkComponent.new(label: "termos", href: "/t", external: true))
    assert_selector "a.ss-link.is-external[href='/t'][target=_blank][rel=noopener] svg"
    assert_selector "a.ss-link .ss-sr", text: "(abre em outra aba)"
    render_inline(Ss::TermsNoticeComponent.new(terms_url: "/termos", privacy_url: "/priv"))
    assert_selector "p.ss-terms-notice", text: "Ao continuar, você concorda com os Termos de uso"
    assert_selector "p.ss-terms-notice a.ss-link[href='/termos']", text: "Termos de uso"
    assert_selector "p.ss-terms-notice a.ss-link[href='/priv']", text: "Política de privacidade"
    I18n.with_locale(:en) { render_inline(Ss::TermsNoticeComponent.new(terms_url: "/t", privacy_url: "/p")) }
    assert_selector "p.ss-terms-notice", text: "By continuing, you agree to the Terms of Use"
    render_inline(Ss::EditableValueComponent.new(label: "novo", value: "R$ 12,90", href: "/preco/1/edit"))
    assert_selector "a.ss-editable-value[href='/preco/1/edit'][aria-label='novo: R$ 12,90, Editar'] .ss-editable-value-v.num", text: "R$ 12,90"
    render_inline(Ss::EditableValueComponent.new(value: "10", mono: false, data: { action: "x#y" }))
    assert_selector "button.ss-editable-value[type=button][data-action='x#y'] em", text: "editar"
  end

  test "GoogleButtonComponent(mode: :gis): g_id_onload e g_id_signin com os data-* do Google" do
    render_inline(Ss::GoogleButtonComponent.new(mode: :gis, client_id: "abc.apps", login_uri: "https://x/auth/google", text: :continue_with))
    assert_selector ".ss-google-gis script[src='https://accounts.google.com/gsi/client']", visible: :all
    assert_selector "#g_id_onload[data-client_id='abc.apps'][data-login_uri='https://x/auth/google'][data-auto_prompt=false]", visible: :all
    assert_selector ".g_id_signin[data-shape=pill][data-text=continue_with][data-theme=outline][data-width='400']", visible: :all
    assert_raises(ArgumentError) { Ss::GoogleButtonComponent.new(mode: :gis, client_id: "x") }
    assert_raises(ArgumentError) { Ss::GoogleButtonComponent.new }
    render_inline(Ss::GoogleButtonComponent.new(href: "/auth/google", method: :get))
    assert_selector "a.ss-google-btn[href='/auth/google']"
  end

  test "AppShellComponent: item externo abre em outra aba com ícone e aviso" do
    render_inline(Ss::AppShellComponent.new(nav: [{ items: [{ label: "Ajuda", href: "https://ajuda", external: true }, { label: "Pedidos", href: "/p" }] }]))
    assert_selector "a.is-external[href='https://ajuda'][target=_blank][rel=noopener] .ss-shell-label svg.ss-shell-ext"
    assert_selector "a[href='/p']:not([target])"
  end

  test "privacidade desligada num contêiner e linha apagada no CSS" do
    css = CSS.join("v20_web.css").read
    assert_includes css, %([data-privacy="on"] [data-ss-privacy="off"])
    assert_includes css, ".ss-table tr.is-dimmed > :is(td, th) { opacity: .5; }"
  end

  test "textos novos em pt-BR, en e es" do
    %i[pt-BR en es].each do |l|
      I18n.with_locale(l) do
        %w[app_shell.external data_table.total node_canvas.label repeater.add repeater.remove repeater.added repeater.removed
           terms_notice.text terms_notice.terms terms_notice.privacy].each do |k|
          assert I18n.exists?("componentes_ui.#{k}", l), "#{l} #{k}"
        end
      end
    end
  end

  test "vitrine da v0.20 renderiza" do
    html = VitrineController.render(template: "vitrine/pecas_v020", layout: false)
    assert_includes html, "ss-node-canvas"
    assert_includes html, "tr class=\"is-link"
    assert_includes html, "ss-repeater"
  end
end
