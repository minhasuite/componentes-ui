require "test_helper"

# v1.6 · ajuda da moldura: Ss::HelpMenuComponent (Aprenda e Novidades) e o slot help do AppShell.
class V160WebTest < ComponentTest
  CSS = Pathname(ComponentesUi::Engine.root).join("app/assets/tailwind/componentes_ui")

  test "HelpMenuComponent: botão com ponto, Aprenda e Novidades em outra aba e o selo de não vistas" do
    render_inline(Ss::HelpMenuComponent.new(learn_href: "https://x/aprenda/", news_href: "/novidades", unseen_news: 2))
    assert_selector "span.ss-help.ss-popover-host[data-controller='ss-popover ss-help'][data-ss-help-label-value=Ajuda]"
    assert_selector "button.ss-icon-btn.ss-help-btn[popovertarget=ss-help-panel][aria-label='Ajuda, 2 novidades não vistas'][title=Ajuda] .ss-help-dot"
    assert_selector "div#ss-help-panel.ss-popover.ss-help-panel[popover=auto][role=dialog][data-placement=bottom-end]"
    assert_selector ".ss-help-panel p.ss-popover-title", text: "Ajuda"
    assert_selector "ul.ss-help-list > li", count: 2
    assert_selector "a.ss-help-item[href='https://x/aprenda/'][target=_blank][rel=noopener][data-action='ss-help#close'] .ss-help-title", text: "Aprenda"
    assert_selector "a.ss-help-item[href='https://x/aprenda/'] .ss-help-note", text: "Videoaulas de cada tela"
    assert_selector "a.ss-help-item[href='https://x/aprenda/'] svg.ss-help-out"
    assert_selector "a.ss-help-item[href='https://x/aprenda/'] .ss-sr", text: "(abre em outra aba)"
    assert_selector "a.ss-help-item[href='/novidades'][target=_blank][data-action='ss-help#seen'] .ss-help-title", text: "Novidades"
    assert_selector "a.ss-help-item[href='/novidades'] .ss-badge.ss-badge-accent.ss-help-new[data-ss-help-target=badge]", text: "2 novas"
    assert_no_selector "a.ss-help-item[href='/novidades'] svg.ss-help-out"
  end

  test "HelpMenuComponent: uma nova no singular; tudo visto sem ponto nem selo; sem news_href só Aprenda; itens extras" do
    render_inline(Ss::HelpMenuComponent.new(learn_href: "/a", news_href: "/n", unseen_news: 1))
    assert_selector "button.ss-help-btn[aria-label='Ajuda, 1 novidade não vista']"
    assert_selector ".ss-help-new", text: "1 nova"

    render_inline(Ss::HelpMenuComponent.new(learn_href: "/a", news_href: "/n", unseen_news: 0))
    assert_selector "button.ss-help-btn[aria-label=Ajuda]"
    assert_no_selector ".ss-help-dot"
    assert_no_selector ".ss-help-new"
    assert_selector "a.ss-help-item[href='/n'] svg.ss-help-out"

    render_inline(Ss::HelpMenuComponent.new(learn_href: "/a", unseen_news: 3, id: "h2",
                                            items: [{ label: "Atalhos do teclado", text: "Tecla ?", href: "/atalhos", icon: "lightning-bolt" }]))
    assert_selector "#h2-panel ul.ss-help-list > li", count: 2
    assert_no_selector ".ss-help-dot"
    assert_no_selector "a.ss-help-item[href='/n']"
    assert_selector "a.ss-help-item[href='/atalhos']:not([target])", text: "Atalhos do teclado"
  end

  test "HelpMenuComponent em inglês e espanhol" do
    I18n.with_locale(:en) do
      render_inline(Ss::HelpMenuComponent.new(learn_href: "/a", news_href: "/n", unseen_news: 2))
      assert_selector "button.ss-help-btn[aria-label='Help, 2 unseen updates']"
      assert_selector ".ss-help-title", text: "Learn"
    end
    I18n.with_locale(:es) do
      render_inline(Ss::HelpMenuComponent.new(learn_href: "/a", news_href: "/n", unseen_news: 1))
      assert_selector ".ss-help-new", text: "1 nueva"
      assert_selector ".ss-help-title", text: "Novedades"
    end
  end

  test "AppShellComponent: slot help antes do sino, e a barra não fica vazia" do
    render_inline(Ss::AppShellComponent.new(brand: "X", search: false)) do |s|
      s.with_help { "<span class='ajuda'>?</span>".html_safe }
      s.with_bell { "<span class='sino'>S</span>".html_safe }
      "conteúdo"
    end
    assert_selector "header.ss-shell-top:not(.is-bare) .ss-shell-top-end span.ajuda + span.sino"
  end

  test "CSS e controller da ajuda (v1.6.0)" do
    assert_includes CSS.join("engine.css").read, %(@import "./v160_ajuda_web.css";)
    css = CSS.join("v160_ajuda_web.css").read
    %w[.ss-help-panel .ss-help-dot .ss-help-item .ss-help-out].each { |sel| assert_includes css, sel }
    js = Pathname(ComponentesUi::Engine.root).join("app/javascript/componentes_ui/controllers/ss_help_controller.js").read
    assert_includes js, "hidePopover"
  end
end
