require "test_helper"

# v0.18 · o que o Meu Financeiro (web) ainda tinha de genérico: speed dial, diálogo com formulário em
# frame (ficar aberto, recarregar ao fechar, frame ausente, frame global), ações de linha no hover só
# com mouse, DataTable com atributos por linha e vazio compacto, resumo de erros, rodapé de formulário,
# combobox com ícone/imagem e atributos no input, popover com atributos no botão, tons warn/warning,
# botão de ícone que alterna, olho de esconder valores, barra vazia do AppShell e ícone no grupo,
# utilitários de cor sobre a marca.
class V18WebTest < ComponentTest
  CSS = Pathname(ComponentesUi::Engine.root).join("app/assets/tailwind/componentes_ui")
  JS = Pathname(ComponentesUi::Engine.root).join("app/javascript/componentes_ui/controllers")
  Rec = Struct.new(:id, :name, keyword_init: true)

  test "SpeedDialComponent: botão com aria, lista em menu, link com frame e botão com ação" do
    render_inline(Ss::SpeedDialComponent.new(items: [
      { label: "Novo lançamento", icon: "plus", href: "/lancamentos/novo", turbo_frame: "modal" },
      { label: "Assistente", icon: "chat-bubble-left-right", action: "assistant#toggle" },
      nil,
    ]))
    assert_selector "div#ss-speed-dial.ss-speed-dial[data-controller=ss-speed-dial]"
    assert_selector "button.ss-fab.is-icon.is-static.ss-speed-dial-toggle[aria-expanded=false][aria-haspopup=menu][aria-controls='ss-speed-dial-menu'][aria-label='Ações rápidas'][title='Ações rápidas'][data-action='ss-speed-dial#toggle'] svg"
    assert_selector "#ss-speed-dial-menu.ss-speed-dial-menu[role=menu][hidden]", visible: :all
    assert_selector "a.ss-speed-dial-item[role=menuitem][tabindex='-1'][href='/lancamentos/novo'][data-turbo-frame=modal][data-ss-speed-dial-target=item][data-action='click->ss-speed-dial#chosen']", visible: :all
    assert_selector "a .ss-speed-dial-label", text: "Novo lançamento", visible: :all
    assert_selector "a .ss-speed-dial-ico[aria-hidden=true] svg", visible: :all
    assert_selector "button.ss-speed-dial-item[type=button][data-action='click->ss-speed-dial#chosen assistant#toggle']", visible: :all
  end

  test "SpeedDialComponent: uma ação só vira o FabComponent; nenhuma não renderiza; start/lift" do
    render_inline(Ss::SpeedDialComponent.new(items: [{ label: "Novo", icon: "plus", href: "/novo", turbo_frame: "modal" }]))
    assert_selector "a#ss-speed-dial.ss-fab.is-icon[href='/novo'][data-turbo-frame=modal][aria-label=Novo]"
    assert_no_selector ".ss-speed-dial"
    render_inline(Ss::SpeedDialComponent.new(items: []))
    assert_no_selector "div"
    render_inline(Ss::SpeedDialComponent.new(items: [{ label: "A", href: "/a" }, { label: "B", href: "/b" }], position: :start, lift: "4rem", label: "Criar", id: "sd"))
    assert_selector "div#sd.ss-speed-dial.is-start[style='--ss-fab-lift: 4rem'] button[aria-label=Criar][aria-controls='sd-menu']"
  end

  test "SpeedDial: controller e CSS (teclado, fora, cache, mola, menos movimento, área segura)" do
    js = JS.join("ss_speed_dial_controller.js").read
    %w[Escape ArrowUp ArrowDown Home End turbo:before-cache aria-expanded relatedTarget].each { |k| assert_includes js, k }
    css = CSS.join("v18_web.css").read
    assert_includes css, "env(safe-area-inset-bottom)"
    assert_includes css, "body:has(.ss-sticky-bar) .ss-speed-dial"
    assert_includes css, ".ss-speed-dial-toggle[aria-expanded=\"true\"] svg { rotate: 45deg; }"
    assert_includes css, "prefers-reduced-motion"
    assert_includes CSS.join("engine.css").read, %(@import "./v18_web.css";)
  end

  test "DialogComponent: global, sem cabeçalho, limpar, recarregar e frame ausente" do
    render_inline(Ss::DialogComponent.new(id: "modal-dialog", title: "Formulário", global: true, header: false, size: :lg))
    assert_selector "dialog#modal-dialog.ss-sheet.ss-dialog-panel.is-lg.is-headless[aria-label=Formulário]:not([aria-labelledby])", visible: :all
    assert_selector "dialog[data-ss-dialog-global-value=true][data-ss-dialog-clear-value=true]", visible: :all
    assert_selector "dialog[data-action*='turbo:frame-missing->ss-dialog#missing'][data-action*='click->ss-dialog#closer']", visible: :all
    assert_selector "dialog turbo-frame#modal[data-ss-dialog-target=frame]", visible: :all
    assert_no_selector "header.ss-dialog-panel-head", visible: :all
    assert_no_selector "dialog[data-ss-dialog-follow-missing-value]", visible: :all
  end

  test "DialogComponent: o uso de antes não muda; follow_missing: false e refresh_on_close" do
    render_inline(Ss::DialogComponent.new(id: "novo", title: "Novo", frame_id: "dialogo"))
    assert_selector "dialog#novo[aria-labelledby='novo-title'] header.ss-dialog-panel-head h2#novo-title", text: "Novo", visible: :all
    assert_no_selector "dialog[data-ss-dialog-global-value]", visible: :all
    assert_no_selector "dialog[data-ss-dialog-clear-value]", visible: :all
    render_inline(Ss::DialogComponent.new(id: "d2", frame_id: "f", follow_missing: false, refresh_on_close: true, clear_on_close: true))
    assert_selector "dialog#d2[data-ss-dialog-follow-missing-value=false][data-ss-dialog-refresh-value=true][data-ss-dialog-clear-value=true]", visible: :all
  end

  test "ss-dialog: ficar aberto, recarregar, frame ausente, dispensar e cache" do
    js = JS.join("ss_dialog_controller.js").read
    ["data-ss-dialog-keep-open", "data-ss-dialog-refresh", "data-modal-refresh-on-close", "[data-ss-dialog-dismiss]",
     "Turbo.visit(window.location.href, { action: \"replace\" })", "turbo:before-cache", "MutationObserver", "missing(event)"].each { |k| assert_includes js, k }
  end

  test "FormActionsComponent: Cancelar que dispensa o diálogo, enviar com texto de espera e bloco extra" do
    render_inline(Ss::FormActionsComponent.new) do
      %(<button type="submit" name="save_and_new" class="ss-btn ss-btn-outline" data-ss-dialog-keep-open>Salvar e criar outro</button>).html_safe
    end
    assert_selector ".ss-form-actions.is-sticky > button.ss-btn.ss-btn-ghost[type=button][data-ss-dialog-dismiss]:first-child", text: "Cancelar"
    assert_selector ".ss-form-actions > button[data-ss-dialog-keep-open] + button.ss-btn-primary[type=submit][data-turbo-submits-with='Salvando…']", text: "Salvar"
    render_inline(Ss::FormActionsComponent.new(dialog: false, cancel_href: "/contas", submit: "Criar", submitting: false, align: :between))
    assert_selector ".ss-form-actions.is-between:not(.is-sticky) > a.ss-btn-ghost[href='/contas']", text: "Cancelar"
    assert_selector "button.ss-btn-primary:not([data-turbo-submits-with])", text: "Criar"
    render_inline(Ss::FormActionsComponent.new(cancel: false))
    assert_no_selector ".ss-btn-ghost"
  end

  test "FormErrorsComponent: callout de perigo com a lista; some sem erro" do
    rec = Class.new do
      include ActiveModel::Model
      attr_accessor :nome
      def self.name = "Conta"
    end.new
    render_inline(Ss::FormErrorsComponent.new(record: rec))
    assert_no_selector ".ss-callout"
    rec.errors.add(:nome, "não pode ficar em branco")
    rec.errors.add(:base, "Limite estourado")
    render_inline(Ss::FormErrorsComponent.new(record: rec, errors: ["Outro"]))
    assert_selector ".ss-callout.ss-form-errors[data-tone=danger][role=alert] .ss-callout-title", text: "Confira os campos"
    assert_selector ".ss-form-errors li", count: 3
    render_inline(Ss::FormErrorsComponent.new(record: rec, base_only: true, title: "Não deu"))
    assert_selector ".ss-form-errors li", count: 1, text: "Limite estourado"
    assert_selector ".ss-callout-title", text: "Não deu"
  end

  test "RowActionsComponent: Editar no frame, Remover com confirmação, ícones e sempre à vista" do
    render_inline(Ss::RowActionsComponent.new(edit: "/c/1/edit", destroy: "/c/1", confirm: "Remover a conta?"))
    assert_selector ".ss-row-actions.is-reveal > a.ss-btn.ss-btn-ghost.ss-btn-sm[href='/c/1/edit'][data-turbo-frame=modal]", text: "Editar"
    assert_selector ".ss-row-actions form.ss-row-actions-form[action='/c/1'][data-turbo-confirm='Remover a conta?'] button.ss-btn-danger", text: "Remover"
    assert_selector ".ss-row-actions form input[name=_method][value=delete]", visible: :all
    render_inline(Ss::RowActionsComponent.new(edit: "/e", destroy: "/d", icons: true, reveal: false, edit_frame: nil))
    assert_selector ".ss-row-actions:not(.is-reveal) a.ss-icon-btn.is-sm[aria-label=Editar][title=Editar]:not([data-turbo-frame]) svg"
    assert_selector "button.ss-icon-btn.is-danger[aria-label=Remover] svg"
  end

  test "Ações de linha: hover só com mouse (Tailwind 4 puro), visível no toque, foco e menu aberto" do
    css = CSS.join("v18_web.css").read
    assert_includes css, "@media (hover: hover) and (pointer: fine)"
    assert_includes css, ":not(:hover, :focus-within)"
    assert_includes css, ":popover-open"
    refute_includes css, "@custom-variant"
  end

  test "DataTable: row_attrs (Hash ou lambda), t.actions e vazio compacto" do
    rows = [Rec.new(id: 1, name: "Nubank"), Rec.new(id: 2, name: "Inter")]
    render_inline(Ss::DataTableComponent.new(rows:, id: "contas", caption: "Contas", tools: false,
                                             row_attrs: ->(r) { { id: "conta_#{r.id}", class: "group", data: { edit_url: "/c/#{r.id}/edit" } } })) do |t|
      t.column :name, "Nome"
      t.actions { |r| %(<a href="/c/#{r.id}/edit">Editar</a>).html_safe }
    end
    assert_selector "tr#conta_1.group[data-edit-url='/c/1/edit'][data-ss-table-target=row] td", text: "Nubank"
    assert_selector "tr#conta_2 td.r.ss-dt-actions[data-label='Ações'] > .ss-row-actions.is-reveal > a[href='/c/2/edit']"
    assert_selector "th[data-col=_actions] .ss-sr", text: "Ações"
    render_inline(Ss::DataTableComponent.new(rows: [], id: "v", caption: "V", tools: false, empty: "Nenhuma conta.", empty_art: false)) { |t| t.column :name, "Nome" }
    assert_selector "tr.ss-dt-empty .ss-empty.ss-empty-plain.is-compact", text: "Nenhuma conta."
    render_inline(Ss::DataTableComponent.new(rows: [], id: "v2", caption: "V", tools: false)) { |t| t.column :name, "Nome" }
    assert_selector ".ss-empty:not(.ss-empty-plain)"
  end

  test "Combobox: ícone e imagem por opção, a escolhida no campo e atributos no input" do
    render_inline(Ss::ComboboxComponent.new(name: "conta[banco_id]", label: "Banco", id: "banco", value: 2, text: "Inter",
                                            options: [{ id: 1, label: "Nubank", image: "/logos/nu.png" },
                                                      { id: 2, label: "Inter", icon: "office-building", color: "#ff7a00" },
                                                      { id: 3, label: "Mau", icon: "x", color: "red;}</style>" }],
                                            input: { title: "Banco da conta", data: { action: "change->f#x", f_target: "banco" }, aria: { required: "true" } }))
    assert_selector ".ss-combobox.has-media .ss-combobox-box.has-lead .ss-combobox-lead[aria-hidden=true] .ss-combobox-ico[style='--c: #ff7a00'] svg"
    assert_selector "input#banco.ss-input[role=combobox][title='Banco da conta'][data-f-target=banco][aria-required=true][aria-controls=banco-list][aria-autocomplete=list]"
    assert_selector "input#banco[data-action='input->ss-combobox#search keydown->ss-combobox#key focus->ss-combobox#search blur->ss-combobox#close change->f#x'][data-ss-combobox-target=input]"
    opts = JSON.parse(page.find(".ss-combobox")["data-ss-combobox-options-value"])
    assert_equal "/logos/nu.png", opts[0]["image"]
    assert_includes opts[1]["icon_svg"], "<svg"
    assert_nil opts[2]["color"]
    assert_nil opts[0]["icon"]
    render_inline(Ss::ComboboxComponent.new(name: "x", label: "X", options: [{ id: 1, label: "A" }]))
    assert_no_selector ".has-media"
    assert_no_selector ".has-lead"
    js = JS.join("ss_combobox_controller.js").read
    assert_includes js, "syncLead"
    assert_includes js, "local && o.icon_svg"
  end

  test "Popover: trigger_attrs no botão; com trigger, o rótulo vira a dica" do
    render_inline(Ss::PopoverComponent.new(label: "Mais ações para Mercado", trigger: "⋯", trigger_class: "ss-icon-btn is-sm", id: "p1",
                                           trigger_attrs: { title: "Mais ações", data: { action: "click->x#y", testid: "menu" } })) { "corpo" }
    assert_selector "button.ss-icon-btn.is-sm[popovertarget=p1][title='Mais ações'][aria-label='Mais ações para Mercado'][data-action='click->x#y'][data-testid=menu][data-ss-popover-target=trigger]"
    render_inline(Ss::PopoverComponent.new(label: "Detalhes", id: "p2")) { "c" }
    assert_selector "button.ss-btn[popovertarget=p2]:not([title]):not([aria-label])", text: "Detalhes"
  end

  test "ss_status e tons: warn e warning dão o mesmo âmbar em todo lugar" do
    view = ApplicationController.new.view_context
    map = { "a" => ["Atenção", :warn], "b" => ["Atenção", :warning], "c" => ["Ok", :success] }
    assert_includes view.ss_status("a", map), %(data-tone="warning")
    assert_includes view.ss_status("b", map), %(data-tone="warning")
    assert_includes view.ss_status("c", map), %(data-tone="success")
    assert_equal :warn, ComponentesUi.tone("warning")
    assert_equal :danger, ComponentesUi.tone(:error)
    render_inline(Ss::CalloutComponent.new(tone: :warning, title: "x"))
    assert_selector ".ss-callout[data-tone=warn][role=alert]"
    render_inline(Ss::NoteComponent.new(text: "x", tone: "warning"))
    assert_selector ".ss-note[data-tone=warn]"
    render_inline(Ss::CardHeaderComponent.new(title: "x", icon: "<svg></svg>".html_safe, tone: :warning))
    assert_selector ".ss-card-head-icon[style='--tone: var(--warn)']"
    assert_includes CSS.join("v18_web.css").read, %(.ss-status[data-tone="warn"])
  end

  test "IconButtonComponent: nome e dica, link, variantes e alternar com dois ícones" do
    render_inline(Ss::IconButtonComponent.new(icon: "pencil", label: "Editar", href: "/e", size: :sm))
    assert_selector "a.ss-icon-btn.is-sm[href='/e'][aria-label=Editar][title=Editar]:not([aria-pressed]) svg"
    render_inline(Ss::IconButtonComponent.new(icon: "bell", pressed_icon: "x", label: "Silenciar", pressed: true, variant: :tonal, title: "Silenciar (S)",
                                              data: { action: "avisos#toggle" }))
    assert_selector "button.ss-icon-btn.is-tonal.is-toggle[type=button][aria-pressed=true][title='Silenciar (S)'][data-action='avisos#toggle']"
    assert_selector "button .ss-icon-off[aria-hidden=true] svg", visible: :all
    assert_selector "button .ss-icon-on[aria-hidden=true] svg", visible: :all
  end

  test "PrivacyToggleComponent: olho do ss-privacy com aria-pressed, dica com a tecla P e rótulo" do
    render_inline(Ss::PrivacyToggleComponent.new(css: "lg:hidden"))
    assert_selector "button.ss-icon-btn.ss-privacy-toggle.lg\\:hidden[type=button][data-action='ss-privacy#toggle'][data-privacy-toggle][aria-pressed=false][aria-label='Ocultar valores'][title='Ocultar valores (P)']"
    assert_selector "button .ss-eye-on svg", visible: :all
    assert_selector "button .ss-eye-off svg", visible: :all
    render_inline(Ss::PrivacyToggleComponent.new(text: true, hint: false))
    assert_selector "button.ss-btn.ss-btn-ghost.ss-btn-sm[title='Ocultar valores'] > span", text: "Ocultar valores"
  end

  test "AppShell: barra de cima vazia some no computador; top_mobile não conta; ícone no grupo" do
    icon = %(<svg viewBox="0 0 24 24"><path d="M3 7h18"/></svg>).html_safe
    nav = [{ title: "Cadastros", icon:, items: [{ label: "Contas", href: "/contas", icon: }] }]
    render_inline(Ss::AppShellComponent.new(brand: "Meu Financeiro", nav:, search: false)) { "x" }
    assert_selector "header.ss-shell-top.is-bare"
    assert_selector "details summary .ss-shell-group-ico[aria-hidden=true] svg", visible: :all
    assert_selector "details summary .ss-shell-group-ico + .ss-shell-label", text: "Cadastros", visible: :all
    render_inline(Ss::AppShellComponent.new(brand: "M", nav:, search: false)) do |s|
      s.with_top_mobile { %(<button class="ss-icon-btn" aria-label="Olho">o</button>).html_safe }
      "x"
    end
    assert_selector "header.ss-shell-top.is-bare .ss-shell-top-end .ss-shell-top-mobile button[aria-label=Olho]"
    render_inline(Ss::AppShellComponent.new(brand: "M", nav:)) { "x" }
    assert_selector "header.ss-shell-top:not(.is-bare)"
    render_inline(Ss::AppShellComponent.new(brand: "M", nav:, search: false)) do |s|
      s.with_top { "Novo" }
      "x"
    end
    assert_selector "header.ss-shell-top:not(.is-bare)"
    css = CSS.join("v18_web.css").read
    assert_match(/@media \(min-width: 1024px\) \{\s*\.ss-shell-top\.is-bare \{ display: none; \}/, css)
  end

  test "Cores sobre a marca e semânticas como utilitários do Tailwind" do
    css = CSS.join("v18_web.css").read
    ["--color-on-accent: var(--on-accent);", "--color-accent-solid: var(--accent-solid);", "--color-info: var(--ss-info);",
     "@utility bg-grad {", ":root { --on-accent: #fff; }"].each { |k| assert_includes css, k }
  end

  test "Textos novos nos três idiomas" do
    %w[pt-BR en es].each do |l|
      I18n.with_locale(l) do
        %w[speed_dial.label form_errors.title privacy.hide common.edit common.remove common.saving data_table.actions].each do |k|
          assert I18n.exists?("componentes_ui.#{k}"), "#{l}: falta #{k}"
        end
      end
    end
    I18n.with_locale(:en) do
      render_inline(Ss::SpeedDialComponent.new(items: [{ label: "A", href: "/a" }, { label: "B", href: "/b" }]))
      assert_selector "button[aria-label='Quick actions']"
    end
  end

  test "vitrine da v0.18 renderiza com todas as peças" do
    html = VitrineController.render(template: "vitrine/pecas_v018", layout: false)
    %w[ss-speed-dial ss-dialog-panel ss-row-actions ss-form-actions ss-form-errors ss-combobox-ico ss-privacy-toggle bg-grad].each { |c| assert_includes html, c }
  end
end
