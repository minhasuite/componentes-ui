require "test_helper"

# v0.10.2 · o que faltava para o minha-automacao (web) ficar 100% na gem: barra de topo,
# abertura, aviso em linha, bloco de código, atalhos de seção com menu, lista de ordenar,
# pergunta de um campo, pular para o conteúdo, agenda com fim/dia todo e coluna que cresce,
# e os controllers genéricos (filtro, poll, reload, autosubmit, privacidade, marcar todos).
class V102WebTest < ComponentTest
  SVG = '<svg viewBox="0 0 24 24"><path d="M4 4h16"/></svg>'.html_safe
  GEM = Pathname(ComponentesUi::Engine.root)

  test "barra de topo: título, sub, voltar, ações e variantes" do
    render_inline(Ss::TopBarComponent.new(title: "Mapa", subtitle: "Casa", back: "/sites/1", variant: :overlay)) do |b|
      b.with_action { %(<button class="ss-icon-btn" aria-label="Centralizar">#{SVG}</button>).html_safe }
    end
    assert_selector "header.ss-topbar.is-overlay"
    assert_selector "a.ss-icon-btn[href='/sites/1'][aria-label=Voltar] svg"
    assert_selector "h1.ss-topbar-title", text: "Mapa"
    assert_selector ".ss-topbar-sub", text: "Casa"
    assert_selector ".ss-topbar-actions button[aria-label=Centralizar]"
    render_inline(Ss::TopBarComponent.new(title: "Câmera", variant: :dark, sticky: false))
    assert_selector "header.ss-topbar.is-dark.is-static"
    assert_no_selector ".ss-topbar a, .ss-topbar-actions"
    render_inline(Ss::TopBarComponent.new(title: "X", variant: :nada))
    assert_selector "header.ss-topbar:not(.is-nada)"
    I18n.with_locale(:en) { render_inline(Ss::TopBarComponent.new(title: "X", back: "/")) }
    assert_selector "a[aria-label=Back]"
  end

  test "abertura: marca, título, anel e mensagem (ou o Carregando escondido)" do
    render_inline(Ss::SplashComponent.new(title: "Minha Automação", message: "Instalando…")) { |s| s.with_mark { SVG } }
    assert_selector ".ss-splash[role=status] .ss-splash-mark svg"
    assert_selector "h1.ss-splash-title", text: "Minha Automação"
    assert_selector ".ss-splash-wait .ss-spinner.is-lg[aria-hidden=true]"
    assert_selector "p.ss-splash-msg", text: "Instalando…"
    render_inline(Ss::SplashComponent.new(inline: true))
    assert_selector ".ss-splash.is-inline p.ss-sr", text: "Carregando"
  end

  test "aviso em linha: tom, papel, ícone, título, corpo e ações" do
    render_inline(Ss::CalloutComponent.new(tone: :warn, title: "Faltam campos")) do |c|
      c.with_action { '<a href="#" class="ss-btn ss-btn-sm">Revisar</a>'.html_safe }
      "<ul><li>Aparelho</li></ul>".html_safe
    end
    assert_selector ".ss-callout[data-tone=warn][role=alert] svg.ss-callout-ico"
    assert_selector ".ss-callout-title", text: "Faltam campos"
    assert_selector ".ss-callout-body ul li", text: "Aparelho"
    assert_selector ".ss-callout-actions a", text: "Revisar"
    render_inline(Ss::CalloutComponent.new(tone: :qualquer, icon: false)) { "Publique para valer." }
    assert_selector ".ss-callout[data-tone=info][role=status]", text: "Publique para valer."
    assert_no_selector ".ss-callout svg"
  end

  test "bloco de código: copiar com ss-copy, terminal, altura e sem quebra" do
    render_inline(Ss::CodeBlockComponent.new(text: "token: abc", terminal: true, max_height: "20rem", wrap: false))
    assert_selector ".ss-code-wrap[data-controller=ss-copy][data-ss-copy-text-value='token: abc'][style*='--ss-code-max: 20rem']"
    assert_selector "pre.ss-code.is-terminal.is-nowrap[tabindex='0'] code", text: "token: abc"
    assert_selector "button.ss-icon-btn.ss-code-copy[title=Copiar][data-action='ss-copy#copy'] .ss-sr[data-ss-copy-target=label]", text: "Copiar"
    assert_selector ".ss-code-wrap[data-ss-copy-done-value=Copiado]"
    render_inline(Ss::CodeBlockComponent.new(text: "x", copy: false))
    assert_no_selector "[data-controller], button"
    assert_selector "pre.ss-code:not(.is-terminal):not([tabindex])"
  end

  test "atalhos de seção: faixa com a atual, menu do celular com a atual e a grade" do
    items = [{ label: "Geral", href: "/c/geral", icon: SVG, current: true }, { label: "Usuários", href: "/c/usuarios" }, { label: "Sistema", href: "/c/sistema" }]
    render_inline(Ss::SubnavComponent.new(items:, label: "Configurações"))
    assert_selector ".ss-subnav-wrap.has-menu nav.ss-subnav[aria-label=Configurações] a[aria-current=page][href='/c/geral']", text: "Geral"
    assert_selector "nav.ss-subnav a:not([aria-current])", count: 2
    assert_selector "details.ss-subnav-menu summary.ss-subnav-current[aria-label='Configurações: Geral'] .ss-subnav-label", text: "Geral"
    assert_selector ".ss-subnav-current .ss-subnav-count", text: "3 seções"
    assert_selector "nav.ss-subnav-grid a", count: 3, visible: false
    assert_selector "nav.ss-subnav-grid a[aria-current=page] span", text: "Geral", visible: false
    render_inline(Ss::SubnavComponent.new(items:, menu: false))
    assert_no_selector ".ss-subnav-menu"
    render_inline(Ss::SubnavComponent.new(items: []))
    assert_no_selector ".ss-subnav-wrap"
  end

  test "lista de ordenar: alça com nome, url/param, inputs do form e região viva" do
    render_inline(Ss::SortableListComponent.new(url: "/favoritos/ordem", name: "ids", label: "Favoritos", gap: ".75rem", id: "fav")) do |l|
      l.with_item(id: 7, title: "Sala") { "Sala" }
      l.with_item(id: 9, title: "Cozinha", class: "extra") { "Cozinha" }
    end
    assert_selector ".ss-sortable-wrap[data-controller=ss-sortable][data-ss-sortable-url-value='/favoritos/ordem'][data-ss-sortable-method-value=PATCH][data-ss-sortable-param-value=ids][style*='--ss-sortable-gap: .75rem']"
    assert_selector "ol#fav.ss-sortable[aria-label=Favoritos] li.ss-sortable-item[data-id='7']", text: "Sala"
    assert_selector "li.ss-sortable-item.extra[data-id='9']"
    assert_selector "button.ss-sortable-handle[aria-label='Arrastar para mudar a ordem: Sala'][aria-describedby=fav-hint][data-action*='ss-sortable#grab'][data-action*='ss-sortable#key']"
    assert_selector "input[type=hidden][name='ids[]'][value='7']", visible: false
    assert_selector "p#fav-hint.ss-sr", text: /Mover para cima/, visible: false
    assert_selector "p.ss-sr[role=status][data-ss-sortable-target=live]", visible: false
    assert_includes page.native.to_html, 'data-ss-sortable-moved-value="Movido para a posição {n} de {total}"'
    render_inline(Ss::SortableListComponent.new) { |l| l.with_item(id: 1) { "a" } }
    assert_no_selector "[data-ss-sortable-url-value]"
    assert_no_selector "input[type=hidden]", visible: false
    assert_selector "button.ss-sortable-handle[aria-label='Arrastar para mudar a ordem']"
  end

  test "pergunta de um campo: form de verdade com método e token, ou por JS" do
    render_inline(Ss::PromptDialogComponent.new(id: "nova", title: "Nova seção", label: "Título", url: "/secoes", method: :patch,
                                                 name: "section[title]", value: "Sala", max_length: 40, hint: "Aparece no painel."))
    assert_selector "dialog#nova.ss-dialog.ss-prompt-dialog[data-controller=ss-prompt-dialog][aria-labelledby=nova-t]"
    assert_selector "form[action='/secoes'][method=post] input[name=_method][value=patch]", visible: false
    assert_selector "h2#nova-t", text: "Nova seção"
    assert_selector "p.ss-field-help", text: "Aparece no painel."
    assert_selector "label.ss-field .ss-label", text: "Título"
    assert_selector "input.ss-input[name='section[title]'][value=Sala][required][maxlength='40'][autofocus]"
    assert_selector "button[type=submit].ss-btn-primary", text: "Confirmar"
    assert_selector "button[type=button][data-action='ss-prompt-dialog#cancel']", text: "Cancelar"
    render_inline(Ss::PromptDialogComponent.new(id: "js", title: "Renomear", required: false))
    assert_selector "form[method=dialog] input.ss-input:not([name]):not([required])"
    I18n.with_locale(:es) { render_inline(Ss::PromptDialogComponent.new(id: "e", title: "x")) }
    assert_selector ".ss-label", text: "Nombre"
  end

  test "pular para o conteúdo" do
    html = vc_test_controller.view_context.ss_skip_link
    assert_equal '<a href="#conteudo" class="ss-skip">Pular para o conteúdo</a>', html
    assert html.html_safe?
    assert_includes vc_test_controller.view_context.ss_skip_link("#lista", "Ir <já>"), "Ir &lt;já&gt;"
  end

  test "agenda em lista: end:, all_day: e a coluna da hora que cresce" do
    dia = Date.new(2026, 11, 5)
    render_inline(Ss::AgendaListComponent.new(now: Time.zone.local(2026, 11, 5, 9), days: [
      { date: dia, events: [{ time: "15:00–16:00", title: "Reunião" }, { time: "18:30", end: "19:15", title: "Academia" },
                            { all_day: true, title: "Feriado" }] }]))
    assert_selector ".ss-agl[style*='--ss-agl-tw: max(2.6rem, calc(11 * .47rem + .3rem))']"
    assert_selector ".ss-agl-time span", text: "15:00–16:00"
    assert_selector ".ss-agl-time small", text: "– 19:15"
    assert_selector ".ss-agl-time small .ss-sr", text: "–", visible: false
    assert_selector ".ss-agl-time.is-allday span", text: "Dia todo"
    I18n.with_locale(:en) { render_inline(Ss::AgendaListComponent.new(days: [{ date: dia, events: [{ all_day: true, title: "Holiday" }] }])) }
    assert_selector ".ss-agl-time.is-allday", text: "All day"
    assert_no_selector ".ss-agl[style]"
    render_inline(Ss::AgendaListComponent.new(style: "max-height: 20rem", days: [{ date: dia, events: [{ time: "08:00–09:30", title: "x" }] }]))
    assert_selector ".ss-agl[style*='max-height: 20rem'][style*='--ss-agl-tw']"
  end

  test "CSS da v0.10.2 entra pelo engine.css e traz as classes da migração" do
    engine = GEM.join("app/assets/tailwind/componentes_ui/engine.css").read
    assert_includes engine, '@import "./v10_2_web.css";'
    css = GEM.join("app/assets/tailwind/componentes_ui/v10_2_web.css").read
    %w[.ss-inputs .ss-badge-muted .ss-badge-dot .ss-chip.is-solid .ss-chip-count .ss-chips .ss-rows .ss-btn-group .ss-icon-btn
       .ss-icon-tile.is-grad .ss-danger-zone .ss-callout .ss-code .ss-code-input .ss-fab .ss-divider .ss-steps-head .ss-go .ss-summary
       .ss-spinner .ss-splash .ss-topbar .ss-sortable .ss-skip .ss-subnav-menu .ss-subnav-grid turbo-frame.ss-live].each do |c|
      assert_includes css, c, "falta #{c}"
    end
    assert_includes css, "prefers-reduced-motion"
    refute_match(/#5a45e8|#7b5cff/i, css, "cor da marca fixa no CSS")
  end

  test "controllers genéricos existem e não têm texto pt fixo" do
    dir = GEM.join("app/javascript/componentes_ui/controllers")
    %w[filter poll reload autosubmit privacy check_all sortable prompt_dialog].each do |n|
      assert dir.join("ss_#{n}_controller.js").exist?, "falta ss_#{n}_controller.js"
    end
    assert_includes dir.join("ss_theme_controller.js").read, "toggle()"
    assert_includes dir.join("ss_copy_controller.js").read, '"source"'
  end
end
