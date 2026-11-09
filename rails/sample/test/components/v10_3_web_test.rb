require "test_helper"

# v0.10.3 · pares do que a migração do minha-automacao-app para a v0.10.2 pediu: microfone de
# segurar para falar e compacto, e o ⋯ (mais opções) do tile de aparelho, que no app é o
# onLongPress.
class V103WebTest < ComponentTest
  GEM = Pathname(ComponentesUi::Engine.root)

  test "microfone de segurar: ações de ponteiro e teclado, rótulos de segurar e soltar, sem press" do
    render_inline(Ss::MicButtonComponent.new(hold: true, compact: true, size: 44))
    assert_selector ".ss-mic.is-hold.is-compact[data-controller=ss-mic][style*='--size: 44px']"
    btn = page.find("button.ss-mic-btn")
    assert_equal "Segure para falar", btn["aria-label"]
    acts = btn["data-action"].split
    %w[pointerdown->ss-mic#holdStart pointerup->ss-mic#holdEnd pointercancel->ss-mic#holdCancel
       pointermove->ss-mic#holdMove keydown->ss-mic#holdKey keyup->ss-mic#holdKey click->ss-mic#holdClick].each do |a|
      assert_includes acts, a
    end
    refute_includes acts, "ss-mic#press"
    labels = JSON.parse(page.find(".ss-mic")["data-ss-mic-labels-value"])
    assert_equal "Segure para falar", labels["idle"]
    assert_equal "Ouvindo, solte para enviar", labels["listening"]
    assert_equal "Processando", labels["processing"]

    render_inline(Ss::MicButtonComponent.new(hold: true, state: :listening, labels: { listening: "Gravando" }))
    assert_selector "button.ss-mic-btn[aria-label=Gravando]"

    I18n.with_locale(:en) { render_inline(Ss::MicButtonComponent.new(hold: true)) }
    assert_selector "button[aria-label='Hold to talk']"
    I18n.with_locale(:es) { render_inline(Ss::MicButtonComponent.new(hold: true, state: :listening)) }
    assert_selector "button[aria-label='Escuchando, suelta para enviar']"

    # Sem hold: igual à v0.10.2.
    render_inline(Ss::MicButtonComponent.new)
    assert_selector ".ss-mic:not(.is-hold):not(.is-compact) button[data-action='ss-mic#press'][aria-label=Falar]"
  end

  test "controller do microfone: eventos de segurar, cancelar por distância e leitor de tela" do
    js = GEM.join("app/javascript/componentes_ui/controllers/ss_mic_controller.js").read
    %w[hold-start hold-end hold-cancel setPointerCapture CANCEL_DISTANCE e.detail navigator.vibrate].each { |k| assert_includes js, k }
  end

  test "tile de aparelho: more_url põe o ⋯ e liga o menu de contexto" do
    render_inline(Ss::DeviceTileComponent.new(name: "Luz da sala", state: "Ligada", url: "/p/1", toggle_url: "/p/1/t",
                                              more_url: "/p/1/menu", more_data: { turbo_frame: "modal" }))
    assert_selector ".ss-device.has-more[data-controller=ss-device][data-action='contextmenu->ss-device#more']"
    assert_selector "button.ss-device-toggle[role=switch]"
    assert_selector ".ss-device-end a.ss-icon-btn.ss-device-more[href='/p/1/menu'][aria-label='Mais opções de Luz da sala']" \
                    "[data-ss-device-target=more][data-turbo-frame=modal] svg"
    assert_selector "a.ss-device-text[href='/p/1']"

    # Modo aperto: o toque executa; url: (detalhes) vira o ⋯.
    render_inline(Ss::DeviceTileComponent.new(name: "Portão", url: "/p/2", action_url: "/p/2/run"))
    assert_selector ".ss-device.is-press.has-more .ss-device-end .ss-device-run + a.ss-device-more[href='/p/2']"

    # Sem permissão ainda mostra o ⋯ (editar, remover).
    render_inline(Ss::DeviceTileComponent.new(name: "Câmera", status: :locked, more_url: "/p/3"))
    assert_selector ".ss-device-end .ss-device-lock + a.ss-device-more"

    # Controller do app no data-controller continua.
    render_inline(Ss::DeviceTileComponent.new(name: "X", more_url: "/x", data: { controller: "meu", action: "click->meu#y" }))
    assert_selector ".ss-device[data-controller='meu ss-device'][data-action='click->meu#y contextmenu->ss-device#more']"

    # Sem more_url, nada muda.
    render_inline(Ss::DeviceTileComponent.new(name: "Luz", url: "/p/4"))
    assert_no_selector ".ss-device-more, .ss-device[data-controller]"

    I18n.with_locale(:en) { render_inline(Ss::DeviceTileComponent.new(name: "Lamp", more_url: "/x")) }
    assert_selector "a.ss-device-more[aria-label='More options for Lamp']"
  end

  test "CSS da v0.10.3 importado, com movimento desligável" do
    engine = GEM.join("app/assets/tailwind/componentes_ui/engine.css").read
    assert_includes engine, '@import "./v10_3_web.css";'
    css = GEM.join("app/assets/tailwind/componentes_ui/v10_3_web.css").read
    %w[.ss-mic.is-compact .ss-mic.is-hold [data-holding] .ss-device-more prefers-reduced-motion].each { |k| assert_includes css, k }
    assert GEM.join("app/javascript/componentes_ui/controllers/ss_device_controller.js").exist?
  end

  # ── Lacunas da migração do minha-automacao (web) ──

  test "barra de filtros: valores em array viram um chip cada e name[] na busca" do
    render_inline(Ss::FilterBarComponent.new(params: { "tipo" => %w[luz tomada], "q" => "sala", "status" => "on" },
                                             filters: [{ param: :tipo, label: "Tipo", multiple: true, options: [["Luz", "luz"], ["Tomada", "tomada"], ["Sensor", "sensor"]] },
                                                       { param: :status, label: "Estado", options: [["Ligado", "on"]] }]))
    assert_selector ".ss-fb-chip", text: "Tipo: Luz"
    assert_selector ".ss-fb-chip", text: "Tipo: Tomada"
    # O × tira só aquele valor.
    href = page.find(".ss-fb-chip", text: "Tipo: Luz").find("a")["href"]
    q = Rack::Utils.parse_nested_query(href.split("?", 2).last)
    assert_equal({ "tipo" => ["tomada"], "q" => "sala", "status" => "on" }, q)
    # A busca leva os outros filtros, com name[].
    assert_selector "form input[type=hidden][name='tipo[]'][value=luz]", visible: :all
    assert_selector "form input[type=hidden][name='tipo[]'][value=tomada]", visible: :all
    assert_selector "form input[type=hidden][name=status][value=on]", visible: :all
    assert_no_selector "form input[type=hidden][name=q]", visible: :all
    # "+ Filtro" acrescenta ao array e marca os já escolhidos.
    add = page.find(".ss-fb-add a", text: "Sensor", visible: :all)["href"]
    assert_equal %w[luz tomada sensor], Rack::Utils.parse_nested_query(add.split("?", 2).last)["tipo"]
    assert_selector ".ss-fb-add a[aria-current=true]", text: "Luz", visible: :all
  end

  test "barra de filtros: url: com query mantém os parâmetros (busca, links e Limpar filtros)" do
    render_inline(Ss::FilterBarComponent.new(url: "/pontos?site_id=3", params: { "site_id" => "3", "status" => "on", "q" => "x" },
                                             views: [{ label: "Todos", params: {} }, { label: "Ligados", params: { status: "on" } }],
                                             filters: [{ param: :status, label: "Estado", options: [["Ligado", "on"], ["Desligado", "off"]] }]))
    assert_selector "form.ss-fb-search[action='/pontos'] input[type=hidden][name=site_id][value='3']", visible: :all
    assert_selector "a.ss-fb-clear[href='/pontos?site_id=3']"
    assert_selector ".ss-fb-view[aria-current=page]", text: "Ligados"
    assert_selector ".ss-fb-view[href*='site_id=3']", count: 2
    assert_selector ".ss-fb-chip a[href*='site_id=3']"
    # Sem filtros: o url fica intacto e o Todos é o atual.
    render_inline(Ss::FilterBarComponent.new(url: "/pontos?site_id=3", params: {}, views: [{ label: "Todos", params: {} }]))
    assert_selector ".ss-fb-view[aria-current=page][href='/pontos?site_id=3']", text: "Todos"
    assert_selector "form input[type=hidden][name=site_id]", visible: :all
    assert_no_selector "a.ss-fb-clear"
  end

  test "card de opção: id e atributos no input, compacto e vertical" do
    render_inline(Ss::OptionCardComponent.new(name: "tipo", value: "luz", title: "Luz", id: "tipo_luz", dense: true,
                                              input: { required: true, data: { action: "change->x#y" } }, data: { k: "v" }))
    assert_selector "label.ss-option-card.is-dense[data-k=v] input#tipo_luz[type=radio][name=tipo][value=luz][required][data-action='change->x#y']"
    assert_no_selector "input[checked]"
    render_inline(Ss::OptionCardComponent.new(name: "t", value: "1", title: "Tuya", vertical: true, checked: true, type: :checkbox))
    assert_selector "label.ss-option-card.is-check.is-vertical input[type=checkbox][checked]"
    render_inline(Ss::OptionCardComponent.new(url: "/x", title: "Link", vertical: true))
    assert_selector "a.ss-option-card.is-link.is-vertical"
  end

  test "atalhos de seção: abas no desktop e a faixa rola até a atual" do
    items = [{ label: "Geral", href: "/a", current: true }, { label: "Usuários", href: "/b" }]
    render_inline(Ss::SubnavComponent.new(items:, layout: :tabs))
    assert_selector ".ss-subnav-wrap.is-tabs.has-menu nav.ss-subnav[data-controller=ss-scroll-current] a[aria-current=page]", text: "Geral"
    render_inline(Ss::SubnavComponent.new(items:, layout: :nada))
    assert_selector ".ss-subnav-wrap:not(.is-tabs)"
    render_inline(Ss::FilterBarComponent.new(params: {}, views: [{ label: "Todos", params: {} }]))
    assert_selector "nav.ss-fb-views[data-controller='ss-indicator ss-scroll-current']"
  end

  test "CSS das lacunas web: live com contents, tag com link, chips, checklist, ícone, abas e base" do
    css = GEM.join("app/assets/tailwind/componentes_ui/v10_3_web.css").read
    v102 = GEM.join("app/assets/tailwind/componentes_ui/v10_2_web.css").read
    assert_includes v102, "@layer components { turbo-frame.ss-live { display: block; } }"
    refute_match(/^turbo-frame\.ss-live \{ display: block/, v102)
    [".ss-tag > a", ".ss-option-card.is-dense", ".ss-option-card.is-vertical", '.ss-chip[aria-current="page"]',
     ".ss-chip:has(> input:checked)", ".ss-checklist li > label:has(> input:checked)", ".ss-icon-tile.is-on-grad",
     ".ss-subnav-wrap.is-tabs", ":where(.ss-base) summary", ":where(.ss-reduce-motion)", "turbo-frame.ss-live:is(.contents"].each do |k|
      assert_includes css, k
    end
    js = GEM.join("app/javascript/componentes_ui/controllers/ss_scroll_current_controller.js").read
    assert_includes js, "scrollTo"
    assert_includes js, "prefers-reduced-motion"
    refute_includes js, "scrollIntoView" # rolar a página junto não
  end

  test "vitrine da v0.10.3 renderiza com todas as peças" do
    html = VitrineController.render(template: "vitrine/tela_v103", layout: false)
    page = Capybara.string(html)
    assert page.has_css?(".ss-mic.is-hold.is-compact")
    assert page.has_css?(".ss-device.has-more a.ss-device-more")
    assert page.has_css?(".ss-option-card.is-vertical"), "vertical"
    assert page.has_css?(".ss-option-card.is-dense"), "dense"
    assert page.has_css?(".ss-subnav-wrap.is-tabs")
    assert page.has_css?("label.ss-chip input[type=checkbox][checked]")
    assert page.has_css?("turbo-frame.ss-live.contents")
    assert_includes VitrineController::GRUPOS, "Tela (v0.10.3)"
  end
end
