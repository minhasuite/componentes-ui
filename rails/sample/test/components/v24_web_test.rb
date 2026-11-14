require "test_helper"

# v0.24 · sino de avisos no topo (NotificationBellComponent + NotificationListComponent, slot bell do AppShell)
# e o selo como componente (BadgeComponent).
class V24WebTest < ComponentTest
  CSS = Pathname(ComponentesUi::Engine.root).join("app/assets/tailwind/componentes_ui")

  test "BadgeComponent: só texto, com ícone, tom, ponto e link" do
    render_inline(Ss::BadgeComponent.new(label: "1 luz acesa"))
    assert_selector "span.ss-badge", text: "1 luz acesa"
    assert_no_selector "span.ss-badge > *"

    render_inline(Ss::BadgeComponent.new(label: "2 sem sinal", icon: "signal", tone: :warn))
    assert_selector "span.ss-badge.ss-badge-warn > svg.ss-icon + span", text: "2 sem sinal"

    render_inline(Ss::BadgeComponent.new(label: "Online", tone: :success, dot: true, solid: true, mono: true))
    assert_selector "span.ss-badge.ss-badge-success.ss-badge-dot.is-solid.is-mono"

    render_inline(Ss::BadgeComponent.new(label: "3 abertas", href: "/x", link_data: { turbo_frame: "_top" }, title: "Ver", tone: :nada))
    assert_selector "a.ss-badge[href='/x'][data-turbo-frame=_top][title=Ver]", text: "3 abertas"
    assert_no_selector "a.ss-badge[class*=ss-badge-]"
  end

  test "NotificationBellComponent: contador, painel, ações e lista em frame" do
    render_inline(Ss::NotificationBellComponent.new(count: 3, src: "/avisos/recentes", count_url: "/avisos/contagem", every: 30_000,
                                                    all_href: "/avisos", read_all_href: "/avisos/lidas", settings_href: "/avisos/ajustes"))
    assert_selector "span.ss-bell[data-controller='ss-popover ss-bell'][data-ss-bell-url-value='/avisos/contagem'][data-ss-bell-every-value='30000']"
    assert_selector "button.ss-icon-btn.ss-bell-btn[popovertarget=ss-bell-panel][aria-label='Avisos, 3 não lidos'] .ss-bell-count", text: "3"
    assert_selector "div#ss-bell-panel.ss-popover.ss-bell-panel[popover=auto][role=dialog][data-placement=bottom-end]"
    assert_selector ".ss-bell-head form[action='/avisos/lidas'] input[name=_method][value=patch]", visible: :all
    assert_selector ".ss-bell-head a.ss-icon-btn[href='/avisos/ajustes'][aria-label='Preferências dos avisos']"
    assert_selector "turbo-frame#ss-bell-list[src='/avisos/recentes'][loading=lazy][target=_top]"
    assert_selector "a.ss-bell-foot[href='/avisos']", text: "Ver todos os avisos"
  end

  test "NotificationBellComponent: sem não lidos o contador some; 120 vira 99+; lista inline" do
    render_inline(Ss::NotificationBellComponent.new(count: 0, items: []))
    assert_selector ".ss-bell-count[hidden]", visible: :all
    assert_selector "button.ss-bell-btn[aria-label=Avisos]"
    assert_selector "p.ss-bell-empty", text: "Nenhum aviso por aqui."
    assert_no_selector ".ss-bell-foot"

    render_inline(Ss::NotificationBellComponent.new(count: 120, id: "b2", items: [{ title: "Oi" }]))
    assert_selector "#b2-panel"
    assert_selector ".ss-bell-count", text: "99+"
    assert_selector "ul.ss-bell-list li div.ss-bell-item", text: "Oi"
  end

  test "NotificationListComponent: abrir marca como lido (PATCH), link, tom e não lido" do
    render_inline(Ss::NotificationListComponent.new(frame_id: "ss-bell-list", items: [
      { title: "Portão aberto", text: "Há 10 min", time: "há 2 min", href: "/n/1/lida", method: :patch, unread: true, icon: "bell", tone: :danger },
      { title: "Resumo", href: "/n/2" }
    ]))
    assert_selector "turbo-frame#ss-bell-list[target=_top] ul.ss-bell-list > li", count: 2
    assert_selector "form[action='/n/1/lida'] button.ss-bell-item.is-unread .ss-icon-tile.is-danger svg"
    assert_selector "button.ss-bell-item .ss-bell-title", text: "Portão aberto"
    assert_selector "button.ss-bell-item .ss-bell-note", text: "Há 10 min"
    assert_selector "button.ss-bell-item .ss-bell-time", text: "há 2 min"
    assert_selector "button.ss-bell-item .ss-bell-dot .ss-sr", text: "não lido"
    assert_selector "a.ss-bell-item[href='/n/2']:not(.is-unread)", text: "Resumo"
  end

  test "AppShellComponent: slot bell na barra de cima, que não fica vazia" do
    render_inline(Ss::AppShellComponent.new(brand: "X", search: false)) do |s|
      s.with_bell { "<span class='sino'>S</span>".html_safe }
      "conteúdo"
    end
    assert_selector "header.ss-shell-top:not(.is-bare) .ss-shell-top-end span.sino"
  end

  test "CSS v0.24 no engine" do
    assert_includes CSS.join("engine.css").read, %(@import "./v24_web.css";)
    css = CSS.join("v24_web.css").read
    %w[.ss-bell-panel .ss-bell-count .ss-bell-item .ss-bell-foot a.ss-badge].each { |sel| assert_includes css, sel }
  end
end
