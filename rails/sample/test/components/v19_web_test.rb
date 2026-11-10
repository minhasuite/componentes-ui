require "test_helper"

# v0.19 · o que o Meu Financeiro (web) ainda escrevia à mão para ficar 100% no componentes-ui: botão como
# componente (link, botão do JS, envio, button_to), entrar com o Google, cartão físico com inclinação,
# campos de arquivo e de cor no ss_form_with, nome e método da seleção da DataTable, rodapé sem o
# botão de enviar, botão de ícone que envia e a cor da barra do navegador.
class V19WebTest < ComponentTest
  CSS = Pathname(ComponentesUi::Engine.root).join("app/assets/tailwind/componentes_ui")
  JS = Pathname(ComponentesUi::Engine.root).join("app/javascript/componentes_ui/controllers")

  test "ButtonComponent: botão do JS, com ícone, tamanho, largura toda e atributos" do
    render_inline(Ss::ButtonComponent.new(label: "Ler", icon: "check", variant: :outline, size: :sm, block: true,
                                          title: "Ler o código", data: { action: "boleto#ler" }))
    assert_selector "button.ss-btn.ss-btn-outline.ss-btn-sm.is-block[type=button][title='Ler o código'][data-action='boleto#ler'] svg.ss-icon + span", text: "Ler"
  end

  test "ButtonComponent: link, envio com formaction e texto de espera, ficha e linha de menu de perigo" do
    render_inline(Ss::ButtonComponent.new(label: "Novo", icon: "plus", href: "/novo", data: { turbo_frame: "modal" }))
    assert_selector "a.ss-btn.ss-btn-primary[href='/novo'][data-turbo-frame=modal]", text: "Novo"
    render_inline(Ss::ButtonComponent.new(label: "Trocar", type: :submit, variant: :ghost, name: "op", value: "categorize",
                                          formaction: "/lote", submitting: "Trocando…", confirm: "Trocar?", confirm_tone: :danger))
    assert_selector "button.ss-btn-ghost[type=submit][name=op][value=categorize][formaction='/lote'][data-turbo-submits-with='Trocando…'][data-turbo-confirm='Trocar?'][data-turbo-confirm-tone=danger]"
    render_inline(Ss::ButtonComponent.new(label: "Hoje", variant: :chip, size: :sm))
    assert_selector "button.ss-chip:not(.ss-btn):not(.ss-btn-sm)", text: "Hoje"
    render_inline(Ss::ButtonComponent.new(label: "Remover", variant: :item, tone: :danger))
    assert_selector "button.ss-item.is-danger", text: "Remover"
  end

  test "ButtonComponent: method: vira button_to com o confirm no form, params e o bloco" do
    render_inline(Ss::ButtonComponent.new(label: "Remover", href: "/p/1", method: :delete, variant: :danger, size: :sm,
                                          confirm: "Remover o pedido?", confirm_tone: :danger, confirm_button: "Remover",
                                          params: { scope: "future" }, form: { data: { turbo_frame: "_top" } }))
    assert_selector "form.button_to[action='/p/1'][data-turbo-confirm='Remover o pedido?'][data-turbo-confirm-tone=danger][data-turbo-confirm-button=Remover][data-turbo-frame=_top]"
    assert_selector "form input[name=_method][value=delete]", visible: :all
    assert_selector "form input[name=scope][value=future]", visible: :all
    assert_selector "form button.ss-btn.ss-btn-danger.ss-btn-sm[type=submit]", text: "Remover"
    render_inline(Ss::ButtonComponent.new(href: "/sair", method: :delete, variant: :on_grad)) { "Sair" }
    assert_selector "form button.ss-btn.is-on-grad", text: "Sair"
  end

  test "GoogleButtonComponent: POST sem Turbo com o G e o rótulo; get vira link" do
    render_inline(Ss::GoogleButtonComponent.new(href: "/auth/google"))
    assert_selector "form.ss-google-form[action='/auth/google'][data-turbo=false] button.ss-btn.ss-btn-outline.ss-google-btn[data-turbo=false] svg.ss-google-g[aria-hidden=true]"
    assert_selector "button.ss-google-btn span", text: "Entrar com o Google"
    render_inline(Ss::GoogleButtonComponent.new(href: "/auth/google", label: "Cadastrar com o Google", method: :get))
    assert_selector "a.ss-google-btn[href='/auth/google']", text: "Cadastrar com o Google"
  end

  test "WalletCardComponent: chip, logo, final, nome, valor, cores do cartão e inclinação" do
    render_inline(Ss::WalletCardComponent.new(amount: "R$ 1.234,56", label: "Fatura", holder: "Nubank", number: "4086",
                                              colors: ["#1a1f71", "#3b82f6"], href: "/cartoes/1")) { "VISA" }
    assert_selector "a.ss-wallet-card.has-colors[href='/cartoes/1'][data-controller=ss-tilt][style='--ss-wc-1: #1a1f71; --ss-wc-2: #3b82f6']"
    assert_selector ".ss-wallet-card-top .ss-wallet-card-chip[aria-hidden=true] ~ .ss-wallet-card-logo", text: "VISA"
    assert_selector ".ss-wallet-card-number", text: "•••• •••• •••• 4086"
    assert_selector ".ss-wallet-card-foot .ss-wallet-card-k", text: "Cartão"
    assert_selector ".ss-wallet-card-foot .ss-wallet-card-v", text: "Nubank"
    assert_selector ".ss-wallet-card-foot .is-end .ss-wallet-card-v.money", text: "R$ 1.234,56"
    render_inline(Ss::WalletCardComponent.new(network: "elo", tilt: false, colors: ["red", "blue"]))
    assert_selector "div.ss-wallet-card:not(.has-colors):not([data-controller]) .ss-wallet-card-network", text: "ELO"
  end

  test "ss-tilt e o CSS do cartão: só com mouse, menos movimento e privacidade" do
    js = JS.join("ss_tilt_controller.js").read
    ["(hover: hover) and (pointer: fine)", "prefers-reduced-motion", "--ss-rx", "--ss-my", "mouseleave"].each { |k| assert_includes js, k }
    css = CSS.join("v19_web.css").read
    ["rotateX(var(--ss-rx", "aspect-ratio: 1.586", "[data-privacy=\"on\"] .ss-wallet-card-v.money", "prefers-reduced-motion",
     ".ss-btn.is-block", ".ss-item.is-danger", "::file-selector-button", ".ss-input[type=\"color\"]"].each { |k| assert_includes css, k }
    assert_includes CSS.join("engine.css").read, %(@import "./v19_web.css";)
  end

  test "FormBuilder: ss_file_field e ss_color_field no desenho do campo" do
    view = ApplicationController.new.view_context
    html = view.ss_form_with(url: "/x", scope: :cat) do |f|
      f.ss_file_field(:arquivo, label: "Arquivo", accept: ".csv") + f.ss_color_field(:cor, label: "Cor", value: "#336699")
    end
    page = Capybara.string(html)
    assert page.has_css?(".ss-field label[for=cat_arquivo]", text: "Arquivo")
    assert page.has_css?("input.ss-input[type=file][name='cat[arquivo]'][accept='.csv']")
    assert page.has_css?("input.ss-input[type=color][name='cat[cor]'][value='#336699']")
  end

  test "DataTableComponent: select_name e bulk_method" do
    rows = [{ id: 7, nome: "A" }]
    render_inline(Ss::DataTableComponent.new(rows:, id: "lt", caption: "L", selectable: true, select_name: "transaction_ids[]",
                                             bulk_url: "/lote", bulk_method: :patch)) do |t|
      t.column :nome, "Nome"
      t.bulk_actions { "ok" }
    end
    assert_selector "td.ss-dt-check input[type=checkbox][name='transaction_ids[]'][value='7'][form=lt-bulk]"
    assert_selector "form#lt-bulk[action='/lote'] input[name=_method][value=patch]", visible: :all
    render_inline(Ss::DataTableComponent.new(rows:, id: "l2", caption: "L", selectable: true)) { |t| t.column :nome, "Nome" }
    assert_selector "input[name='ids[]']"
    assert_no_selector "form#l2-bulk input[name=_method]", visible: :all
  end

  test "FormActionsComponent(submit: false) e IconButtonComponent(type: :submit)" do
    render_inline(Ss::FormActionsComponent.new(submit: false, sticky: false)) { "<a class='ss-btn' href='/a'>Aplicar</a>".html_safe }
    assert_selector ".ss-form-actions:not(.is-sticky) > button.ss-btn-ghost[data-ss-dialog-dismiss] + a", text: "Aplicar"
    assert_no_selector "button[type=submit]"
    render_inline(Ss::IconButtonComponent.new(icon: "check", label: "Marcar como pago", type: :submit, size: :sm,
                                              form: "agenda", name: "ids[]", value: "3"))
    assert_selector "button.ss-icon-btn.is-sm[type=submit][form=agenda][name='ids[]'][value='3'][aria-label='Marcar como pago'] svg"
    render_inline(Ss::IconButtonComponent.new(icon: "x", label: "Fechar"))
    assert_selector "button.ss-icon-btn[type=button]"
  end

  test "ss_theme_color_tag: a marca sem hex no produto; outra cor; claro e escuro" do
    view = ApplicationController.new.view_context
    assert_equal %(<meta name="theme-color" content="#5a45e8">), view.ss_theme_color_tag
    assert_includes view.ss_theme_color_tag("#112233"), %(content="#112233")
    assert_includes view.ss_theme_color_tag("vermelho"), %(content="#5a45e8")
    both = view.ss_theme_color_tag(dark: true)
    assert_includes both, %(media="(prefers-color-scheme: light)")
    assert_includes both, %(content="#0e0d16" media="(prefers-color-scheme: dark)")
  end

  test "textos novos em pt-BR, en e es" do
    { "pt-BR": "Entrar com o Google", en: "Sign in with Google", es: "Iniciar sesión con Google" }.each do |loc, txt|
      assert_equal txt, I18n.t("componentes_ui.google.sign_in", locale: loc)
      assert I18n.exists?("componentes_ui.wallet_card.balance", loc)
      assert I18n.exists?("componentes_ui.wallet_card.card", loc)
    end
  end
  test "BarChartComponent: width: no viewBox e rótulos do eixo X de N em N quando não cabem" do
    labels = (1..30).map(&:to_s)
    serie = [{ name: "Receitas", values: Array.new(30) { 10 } }]
    render_inline(Ss::BarChartComponent.new(title: "Mês", labels:, series: serie, width: 1100, height: 280))
    assert_selector "figure.ss-barc svg[viewbox='0 0 1100 280']", visible: :all
    assert_selector "text.ss-barc-xtext", count: 30, visible: :all
    render_inline(Ss::BarChartComponent.new(title: "Mês", labels:, series: serie, active: 9))
    assert_selector "figure.ss-barc svg[viewbox='0 0 560 240']", visible: :all
    assert_selector "text.ss-barc-xtext", count: 16, visible: :all
    render_inline(Ss::BarChartComponent.new(title: "Mês", labels:, series: serie, label_every: 5))
    assert_selector "text.ss-barc-xtext", count: 6, visible: :all
    render_inline(Ss::BarChartComponent.new(title: "Sem", labels: %w[a b c], series: [{ name: "x", values: [1, 2, 3] }]))
    assert_selector "text.ss-barc-xtext", count: 3, visible: :all
    assert_includes CSS.join("v19_web.css").read, ".ss-dialog-panel-body .ss-form-actions.is-sticky { bottom: calc(-1 * var(--ss-card-pad)); }"
    assert_selector "figure.ss-barc > .ss-sr-wrap > table.ss-sr caption", visible: :all
    render_inline(Ss::AreaChartComponent.new(title: "Área", points: [["a", 1], ["b", 2]]))
    assert_selector "figure > .ss-sr-wrap > table.ss-sr", visible: :all
    assert_includes CSS.join("v19_web.css").read, ".ss-sr-wrap { position: absolute; width: 1px; height: 1px; overflow: hidden;"
  end
end
