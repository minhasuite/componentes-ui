require "test_helper"

# v0.10.1 · lacunas do web: moldura (recolhido no servidor, marca, separador, main), página só
# cabeçalho, paleta (grupos do src, subtítulo, sugestão), paginação em SVG, vazio com arte,
# ícone com rótulo, idioma com form:, passo a passo do servidor, avisos por posição, base com
# class:, blocos, card-link, etapas com tempo, tile de aperto, faixa/câmera, dia inteiro.
class V101WebTest < ComponentTest
  SVG = '<svg viewBox="0 0 24 24"><path d="M4 4h16"/></svg>'.html_safe
  NAV = [{ items: [{ label: "Painel", href: "/", current: true, class: "item-x" }, { separator: true },
                   { label: "Pedidos", href: "/pedidos", badge: 0 }, { label: "Avisos", href: "/avisos", badge: 2 }] },
         { divider: true },
         { title: "Vendas", items: [{ label: "Clientes", href: "/clientes", badge: "" }] }].freeze

  test "moldura: collapsed:, marca, link da marca, separador, class:, badge zero e main" do
    render_inline(Ss::AppShellComponent.new(brand: "Minhas Vendas", nav: NAV, collapsed: true, brand_url: "/inicio",
                                            main_class: "meu-main", main_max: "72rem")) do |s|
      s.with_mark { SVG }
      "conteúdo"
    end
    assert_selector ".ss-shell[data-collapsed]"
    assert_selector "button.ss-shell-collapse[aria-expanded=false][aria-label='Expandir menu']"
    assert_selector "aside a.ss-shell-brand-link[href='/inicio'] .ss-shell-logo.has-mark svg"
    assert_selector "aside a.ss-shell-brand-link .ss-shell-brand-name", text: "Minhas Vendas"
    assert_selector "header a.ss-shell-top-brand.ss-shell-brand-link[href='/inicio']", text: "Minhas Vendas"
    assert_selector "nav hr.ss-shell-sep", count: 2
    assert_selector "a.item-x[href='/'][aria-current=page]"
    assert_no_selector "a[href='/pedidos'] .ss-nav-badge"
    assert_no_selector "a[href='/clientes'] .ss-nav-badge"
    assert_selector "a[href='/avisos'] .ss-nav-badge", text: "2"
    assert_selector "main#conteudo.ss-shell-content.meu-main[tabindex='-1'][data-max][style*='--shell-main-max:72rem']", text: "conteúdo"
  end

  test "moldura: sem parâmetros novos continua como antes e o cookie do usuário vale" do
    render_inline(Ss::AppShellComponent.new(brand: "X", nav: NAV)) { "c" }
    assert_no_selector ".ss-shell[data-collapsed]"
    assert_selector "button.ss-shell-collapse[aria-expanded=true]"
    assert_selector "aside .ss-shell-brand > .ss-shell-logo:not(.has-mark)"
    assert_no_selector ".ss-shell-brand-link"
    assert_selector "main#conteudo[tabindex='-1']:not([data-max])"
    render_inline(Ss::AppShellComponent.new(brand: "X", nav: NAV, mobile_brand: false)) { "c" }
    assert_no_selector ".ss-shell-top-brand"
    vc_test_request.cookies["ss_shell_collapsed"] = "1"
    render_inline(Ss::AppShellComponent.new(brand: "X", nav: NAV)) { "c" }
    assert_selector ".ss-shell[data-collapsed]"
    vc_test_request.cookies["ss_shell_collapsed"] = "0"
    render_inline(Ss::AppShellComponent.new(brand: "X", nav: NAV, collapsed: true)) { "c" }
    assert_no_selector ".ss-shell[data-collapsed]"
  end

  test "moldura: ss_app_shell_head põe o atributo no <html> antes da pintura" do
    html = vc_test_controller.view_context.ss_app_shell_head
    assert html.html_safe?
    assert_includes html, "<script"
    assert_includes html, "data-ss-shell-collapsed"
    assert_includes html, "ss_shell_collapsed="
    assert_includes html, 'localStorage.getItem("ss-shell-collapsed")'
  end

  test "página: só cabeçalho não renderiza o corpo" do
    render_inline(Ss::PageComponent.new(title: "Pedidos", subtitle: "Abril"))
    assert_selector ".ss-page-head h1", text: "Pedidos"
    assert_no_selector ".ss-page-body"
    render_inline(Ss::PageComponent.new(title: "Pedidos")) { "  " }
    assert_no_selector ".ss-page-body"
    render_inline(Ss::PageComponent.new(title: "Pedidos")) { "corpo" }
    assert_selector ".ss-page-body", text: "corpo"
  end

  test "paleta: subtítulo e sugestão que preenche a busca" do
    render_inline(Ss::CommandPaletteComponent.new(id: "b", groups: [
      { title: "Clientes", items: [{ label: "Ana", url: "/c/1", subtitle: "Loja Centro", hint: "Cliente" }] },
      { title: "Sugestões", items: [{ label: "Pedidos abertos", fill: true }, { label: "Só de hoje", fill: "hoje" }] }
    ]))
    assert_selector "a.ss-command-item[href='/c/1'][data-keywords='Loja Centro'] .ss-command-text [data-ss-command-label]", text: "Ana", visible: :all
    assert_selector "a.ss-command-item .ss-command-sub", text: "Loja Centro", visible: :all
    assert_selector "a.ss-command-item small", text: "Cliente", visible: :all
    assert_selector "a.ss-command-item.is-fill[data-ss-command-fill='Pedidos abertos']:not([href])", visible: :all
    assert_selector "a.ss-command-item.is-fill[data-ss-command-fill='hoje']", visible: :all
  end

  test "paginação: SVG no lugar de ‹ › … e ícone trocado" do
    render_inline Ss::PaginationComponent.new(page: 5, pages: 12, url: "/l")
    assert_selector "a[rel=prev] svg.ss-pg-ico"
    assert_selector "a[rel=next] svg.ss-pg-ico"
    assert_selector ".ss-dt-gap svg.ss-pg-dots", count: 2
    refute_match(/[‹›…]/, page.native.to_html)
    render_inline Ss::PaginationComponent.new(page: 2, pages: 3, url: "/l", prev_icon: "<i class='p'></i>".html_safe, next_icon: "<i class='n'></i>".html_safe)
    assert_selector "a[rel=prev] i.p"
    assert_selector "a[rel=next] i.n"
    render_inline Ss::PaginationComponent.new(page: 2, pages: 3, url: "/l", prev_icon: "<b>x</b>") # texto cru não entra
    assert_selector "a[rel=prev] svg.ss-pg-ico"
  end

  test "tabela: pager sem setas em Unicode" do
    render_inline(Ss::DataTableComponent.new(rows: [{ id: 1, n: 1 }], id: "t", caption: "x", params: {}, pagination: { page: 5, pages: 9, total: 90 })) { |t| t.column(:n, "N") }
    assert_selector ".ss-dt-pager a[rel=prev] svg"
    assert_selector ".ss-dt-pager .ss-dt-gap svg"
    refute_match(/[‹›…]/, page.find(".ss-dt-pager").native.to_html)
  end

  test "vazio: arte do app e sem arte" do
    render_inline(Ss::EmptyStateComponent.new(title: "Nada")) { |e| e.with_art { "<img src='/v.svg' alt=''>".html_safe } }
    assert_selector ".ss-empty-art.is-custom img[src='/v.svg']"
    assert_no_selector ".ss-empty-art svg"
    render_inline(Ss::EmptyStateComponent.new(title: "Nada", art: false))
    assert_no_selector ".ss-empty-art"
    assert_selector "h3", text: "Nada"
  end

  test "ícones: rótulo por ícone nos três formatos" do
    render_inline(Ss::IconPickerComponent.new(name: "i", icons: [["fan", SVG], ["bulb", SVG, "Lâmpada"], { name: "tv", svg: SVG, label: "Televisão" }],
                                              icon_labels: { "fan" => "Ventilador" }))
    assert_selector "button[data-name=fan][title=Ventilador][aria-label=Ventilador][data-search='fan ventilador']"
    assert_selector "button[data-name=bulb][aria-label='Lâmpada'][data-search='bulb lampada']"
    assert_selector "button[data-name=tv][title='Televisão']"
    render_inline(Ss::IconPickerComponent.new(name: "i", icons: [["fan", SVG]]))
    assert_selector "button[data-name=fan][title=fan][data-search=fan]"
  end

  test "idioma: form: e button_data: no button_to" do
    render_inline(Ss::LocalePickerComponent.new(value: "pt-BR", url: "/idioma", form: { data: { turbo: false }, class: "x" }, button_data: { foo: "1" }))
    assert_selector "form.ss-loc-form.x[data-turbo=false][action='/idioma']", count: 3
    assert_selector "form button.ss-loc-opt[data-foo='1']", count: 3
  end

  test "passo a passo do servidor: current:, done:, url: e sem painéis" do
    render_inline(Ss::WizardComponent.new(current: 1, done: [0])) do |w|
      w.with_step(title: "Novo", url: "/novo")
      w.with_step(title: "Conectar", url: "/conectar")
      w.with_step(title: "Encontrado")
      "<form id='f'>campos</form>".html_safe
    end
    assert_selector ".ss-wizard.is-server:not([data-controller])"
    assert_selector "li[data-done]:first-child a.ss-wizard-link[href='/novo']", text: "Novo"
    assert_selector "li[aria-current=step] b", text: "Conectar"
    assert_no_selector "li[aria-current=step] a"
    assert_selector ".ss-wizard-progress[aria-valuenow='2'] .ss-progress-bar[style*='66.7']"
    assert_selector ".ss-wizard-panel form#f", text: "campos"
    assert_selector ".ss-wizard-panel", count: 1
    assert_no_selector ".ss-wizard-nav"
    # Sem done:, os anteriores ao atual contam como feitos; com bloco no passo, ele é o corpo.
    render_inline(Ss::WizardComponent.new(current: 2)) do |w|
      w.with_step(title: "A"); w.with_step(title: "B"); w.with_step(title: "C") { "corpo C" }
    end
    assert_selector "li[data-done]", count: 2
    assert_selector ".ss-wizard-panel", text: "corpo C"
  end

  test "passo a passo do cliente continua igual" do
    render_inline(Ss::WizardComponent.new(draft_key: "k")) { |w| w.with_step(title: "A") { "a" }; w.with_step(title: "B") { "b" } }
    assert_selector ".ss-wizard[data-controller='ss-wizard']"
    assert_selector ".ss-wizard-panel", count: 2, visible: :all
    assert_selector ".ss-wizard-nav"
  end

  test "avisos: role: e position: por aviso" do
    render_inline(Ss::ToastStackComponent.new(toasts: [{ message: "Salvo", tone: :good }, { message: "Urgente", role: "alert", position: :top_center }]))
    assert_selector "#ss-toasts[data-position=bottom-right] .ss-toast[role=status]", text: "Salvo"
    assert_selector "#ss-toasts-top-center.ss-toasts[data-position=top-center] .ss-toast[role=alert]", text: "Urgente"
    assert_equal "ss-toasts-top-center", Ss::ToastStackComponent.target_for(:top_center)
  end

  test "base: class: soma com css: e não some" do
    render_inline(Ss::EmptyStateComponent.new(title: "x", class: "a", css: "b"))
    assert_selector ".ss-empty-state.a.b"
    render_inline(Ss::PageComponent.new(title: "x", class: "minha")) { "c" }
    assert_selector ".ss-page.minha"
    render_inline(Ss::PaginationComponent.new(page: 1, pages: 2, url: "/l", class: "pg"))
    assert_selector "nav.ss-pagination.pg"
  end

  test "blocos: html_id, move_url, toggle extra, confirmação e sem duplicar" do
    render_inline(Ss::BlockListComponent.new(name: "p")) do |l|
      l.with_block(id: 7, title: "Avisar", html_id: "passo_7", move_url: "/passos/7/mover", toggle_url: "/passos/7/ligar",
                   toggle_method: :patch, toggle_params: { origem: "lista" }, delete_url: "/passos/7",
                   delete_confirm: "Excluir o passo?", delete_confirm_title: "Excluir", duplicable: false)
      l.with_block(id: 8, title: "Outro", duplicate_url: "/d", delete_url: "/x")
    end
    assert_selector "li#passo_7.ss-blk[data-id='7']"
    assert_selector "li#passo_7 form[action='/passos/7/mover'] input[name=direction][value=up]", visible: :all
    assert_selector "li#passo_7 form[action='/passos/7/mover'] input[name=direction][value=down]", visible: :all
    assert_selector "li#passo_7 form[action='/passos/7/mover'] input[name=_method][value=patch]", visible: :all
    assert_selector "li#passo_7 form[action='/passos/7/ligar'] input[name=origem][value=lista]", visible: :all
    assert_selector "li#passo_7 form[action='/passos/7/ligar'] input[name=_method][value=patch]", visible: :all
    assert_selector "li#passo_7 form.ss-blk-mi-form[action='/passos/7'][data-turbo-confirm='Excluir o passo?'][data-turbo-confirm-tone=danger][data-turbo-confirm-title=Excluir]", visible: :all
    assert_no_selector "li#passo_7 .ss-blk-mi", text: "Duplicar", visible: :all
    assert_selector "li[data-id='8'] a.ss-blk-mi[href='/d']", visible: :all
    assert_selector "li[data-id='8'] button[data-action='ss-block-list#moveUp']", visible: :all
  end

  test "card de opção: modo link" do
    render_inline(Ss::OptionCardComponent.new(url: "/novo?tipo=tuya", title: "Tuya", description: "Tomadas", icon: SVG, checked: true))
    assert_selector "a.ss-option-card.is-link[href='/novo?tipo=tuya'][aria-current=true] .ss-option-card-chev svg"
    assert_no_selector "input"
    assert_raises(ArgumentError) { Ss::OptionCardComponent.new(title: "x") }
    render_inline(Ss::OptionCardComponent.new(name: "p", value: "a", title: "A"))
    assert_selector "label.ss-option-card input[type=radio][name=p][value=a]"
  end

  test "job: etapas com tempo" do
    render_inline(Ss::JobProgressComponent.new(id: "r", title: "Voz", state: :done, stages: [
      { name: "Ouvir", duration: 820, status: :done }, { name: "Entender", duration: 1234, status: :done },
      { name: "Executar", status: :skipped, detail: "Nada a fazer" }, { name: "Falar", duration: "2 s", status: :failed }
    ]))
    assert_no_selector ".ss-job-bar"
    assert_selector ".ss-job-stages li.is-done", count: 2
    assert_selector "li.is-done .ss-job-stage-time", text: "820 ms"
    assert_selector "li.is-done .ss-job-stage-time", text: "1,2 s"
    assert_selector "li.is-skipped small", text: "Nada a fazer"
    assert_selector "li.is-failed .ss-job-stage-time", text: "2 s"
    assert_selector "li.ss-job-stage-total .ss-job-stage-time", text: "2,1 s"
    I18n.with_locale(:en) { render_inline(Ss::JobProgressComponent.new(id: "r", title: "V", state: :running, stages: [{ name: "A", duration: 1500, status: :running }])) }
    assert_selector ".ss-job-bar"
    assert_selector "li.is-running .ss-sr", text: "Running"
    assert_selector ".ss-job-stage-time", text: "1.5 s"
  end

  test "tile: aperto, link_data, confirm_title e cor da luz" do
    render_inline(Ss::DeviceTileComponent.new(name: "Portão", action_url: "/cmd", action_params: { cmd: "abrir" }, confirm: "Abrir o portão?", confirm_title: "Portão"))
    assert_selector ".ss-device.is-press form.ss-device-press-form[action='/cmd'][data-turbo-confirm='Abrir o portão?'][data-turbo-confirm-title='Portão'] button.ss-device-press[aria-label='Acionar Portão']"
    assert_selector "form input[name=cmd][value=abrir]", visible: :all
    assert_selector ".ss-device-run svg"
    assert_no_selector "a.ss-device-text"
    render_inline(Ss::DeviceTileComponent.new(name: "Luz", url: "/l", link_data: { turbo_frame: "_top" }, tone: "rgb(255, 200, 120)",
                                              toggle_url: "/t", confirm: "Desligar?", confirm_title: "Luz"))
    assert_selector "a.ss-device-text[href='/l'][data-turbo-frame=_top]"
    assert_selector ".ss-device[style*='rgb(255, 200, 120)']"
    assert_selector "[data-turbo-confirm-title='Luz'], [data-ss-switch-confirm-title-value='Luz']", visible: :all
  end

  test "faixa: valor com o decimal do idioma" do
    render_inline(Ss::RangeComponent.new(name: "t", label: "Temp", value: 21.5, min: 10, max: 30, step: 0.5, format: "%.1f °C"))
    assert_selector "output", text: "21,5 °C"
    I18n.with_locale(:en) { render_inline(Ss::RangeComponent.new(name: "t", label: "Temp", value: 21.5, format: "%.1f °C")) }
    assert_selector "output", text: "21.5 °C"
    render_inline(Ss::RangeComponent.new(name: "b", label: "Brilho", value: 80, format: "%d%%"))
    assert_selector "output", text: "80%"
    render_inline(Ss::RangeComponent.new(name: "k", label: "K", value: 2700, format: "%s K"))
    assert_selector "output", text: "2700 K"
  end

  test "câmera: selo de status, título por cima do aviso de falha" do
    render_inline(Ss::CameraTileComponent.new(title: "Garagem", state: :offline, status: "Gravando"))
    assert_selector ".ss-cam-top .ss-cam-status", text: "Gravando"
    assert_selector ".ss-cam-fail + figcaption.ss-cam-top" # o título vem depois (fica por cima)
    render_inline(Ss::CameraTileComponent.new(title: "G")) { |c| c.with_status { "Movimento" } }
    assert_selector ".ss-cam-status", text: "Movimento"
  end

  test "agenda: eventos de dia inteiro na faixa de cima" do
    d = Date.new(2026, 11, 4)
    t = Time.zone.local(2026, 11, 4, 9)
    render_inline(Ss::AgendaComponent.new(days: [d, d + 1, d + 2], now: t, events: [
      { title: "Feriado", starts_at: d, all_day: true, tone: :warn },
      { title: "Viagem", starts_at: d + 1, ends_at: d + 2, all_day: true },
      { title: "Reunião", starts_at: t, ends_at: t + 3600 }
    ]))
    assert_selector ".ss-agenda-allday .ss-agenda-allday-label", text: "Dia todo"
    assert_selector ".ss-agenda-allday-col", count: 3
    assert_selector ".ss-agenda-allday-col:nth-of-type(1) .is-all-day", text: "Feriado"
    assert_selector ".ss-agenda-allday .is-all-day", text: "Viagem", count: 2
    assert_selector ".ss-agenda-col .ss-agenda-event:not(.is-all-day)", text: "Reunião", count: 1
    render_inline(Ss::AgendaComponent.new(days: [d], now: t, events: [{ title: "R", starts_at: t, ends_at: t + 60 }]))
    assert_no_selector ".ss-agenda-allday"
  end
end
