require "test_helper"

# v0.17 · botão flutuante como componente (Ss::FabComponent, par do SsFab) e o cabeçalho compacto com a
# linha de cima (Ss::PageComponent(eyebrow:, compact:), par do SsTopBar(eyebrow:)).
class V17WebTest < ComponentTest
  MIC = %(<svg viewBox="0 0 24 24"><path d="M12 3v9"/></svg>).freeze
  CSS = Pathname(ComponentesUi::Engine.root).join("app/assets/tailwind/componentes_ui")

  test "FabComponent: botão só com o ícone, nome lido, dica, id estável e sem o anel" do
    render_inline(Ss::FabComponent.new(icon: MIC, label: "Falar com a casa", data: { action: "assist#open" }))
    assert_selector "button#ss-fab.ss-fab.is-icon.is-still[type=button][aria-label='Falar com a casa'][title='Falar com a casa'][data-action='assist#open']"
    assert_selector "button .ss-fab-ico[aria-hidden=true] svg"
    assert_no_selector ".ss-fab-label"
    assert_no_selector "[data-turbo-permanent]"
  end

  test "FabComponent: estendido, :wide, link, canto esquerdo, lift, pulse, static e permanent" do
    render_inline(Ss::FabComponent.new(icon: MIC, label: "Novo pedido", extended: true, href: "/pedidos/novo", id: "novo"))
    assert_selector "a#novo.ss-fab[href='/pedidos/novo'][aria-label='Novo pedido'] .ss-fab-label", text: "Novo pedido"
    assert_no_selector ".is-icon"
    render_inline(Ss::FabComponent.new(icon: MIC, label: "Falar", extended: :wide, position: :start, lift: "4.5rem", pulse: true, permanent: true))
    assert_selector "button.ss-fab.is-wide.is-start[style='--ss-fab-lift: 4.5rem'][data-turbo-permanent] .ss-fab-label", text: "Falar"
    assert_no_selector ".is-still"
    render_inline(Ss::FabComponent.new(icon: MIC, label: "x", lift: "1px;}</style>", static: true, css: "mt-2"))
    assert_selector "button.ss-fab.is-static.mt-2:not([style])"
  end

  test "FabComponent: CSS com área segura, lift, barra fixa e foco" do
    css = CSS.join("v17_web.css").read
    assert_includes css, "env(safe-area-inset-bottom)"
    assert_includes css, "var(--ss-fab-lift, 0px)"
    assert_includes css, "body:has(.ss-sticky-bar) .ss-fab"
    assert_includes css, ".ss-fab:focus-visible"
    assert_includes CSS.join("engine.css").read, %(@import "./v17_web.css";)
  end

  test "PageComponent(eyebrow:, compact:): linha de cima antes do título e cabeçalho menor" do
    render_inline(Ss::PageComponent.new(title: "Sala de estar", eyebrow: "Casa · 10 de novembro", compact: true)) do |p|
      p.with_actions { %(<a class="ss-icon-btn" aria-label="Editar painel" href="/e">e</a>).html_safe }
    end
    assert_selector ".ss-page.is-compact .ss-page-titles > p.ss-kicker.ss-page-eyebrow + h1.ss-page-title", text: "Sala de estar"
    assert_selector ".ss-page-eyebrow", text: "Casa · 10 de novembro"
    assert_selector ".ss-page-actions a.ss-icon-btn[aria-label='Editar painel']"
    render_inline(Ss::PageComponent.new(title: "Pedidos"))
    assert_no_selector ".is-compact"
    assert_no_selector ".ss-page-eyebrow"
  end
end
