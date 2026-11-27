require "test_helper"

# v1.10.0: os pares Rails das 21 peças do Flutter que eram dívida no paridade.yml, com a dívida zerada.
# Lote A: AttachBar, CardStack, CurvedHeader, Dial, DuoStat, FloatingBars, GoalCard, HexButton, IllustratedSplit,
# IllustrationArt e IllustrationStage. Lote B: ImageViewer, MonthGrid, PeoplePicker, PopOutCard, ProfileHero,
# PulseAvatar, RecurringCard, ShapeIcon, ThumbRail e VerticalSlider.
class V1100WebTest < ComponentTest
  ROOT = Pathname(ComponentesUi::Engine.root)
  JS = ROOT.join("app/javascript/componentes_ui/controllers")
  CSS = ROOT.join("app/assets/tailwind/componentes_ui")
  PARIDADE = YAML.load_file(ROOT.join("../paridade.yml"))

  # ── paridade.yml ────────────────────────────────────────────────────
  test "paridade.yml: dívida zerada nos dois lados" do
    assert_equal({}, PARIDADE["divida"])
    assert_equal({}, PARIDADE["divida_app"])
  end

  test "paridade.yml: as 21 peças e as 4 que saíram do só web têm par" do
    %w[AttachBar CardStack CurvedHeader Dial DuoStat FloatingBars GoalCard HexButton IllustratedSplit IllustrationArt
       IllustrationStage ImageViewer MonthGrid PeoplePicker PopOutCard ProfileHero PulseAvatar RecurringCard ShapeIcon
       ThumbRail VerticalSlider].each do |n|
      assert_includes Array(PARIDADE["pares"]["Ss#{n}"]), "Ss::#{n}Component", "Ss#{n} sem o par"
    end
    %w[FilterBar JobProgress TreeView Popover ProductCard].each do |n|
      refute PARIDADE["so_web"].key?("Ss::#{n}Component"), "Ss::#{n}Component ainda no só web"
      assert PARIDADE["pares"].values.flatten.include?("Ss::#{n}Component"), "Ss::#{n}Component sem par no Flutter"
    end
  end

  test "CSS importado, só tokens e reduzir movimento" do
    assert_includes CSS.join("engine.css").read, '@import "./v1100_web.css";'
    css = CSS.join("v1100_web.css").read.gsub(%r{/\*.*?\*/}m, "")
    refute_match(/#[0-9a-f]{3,8}\b/i, css, "cor fixa no CSS")
    refute_match(/(?<![\w-])\d*\.?\d+m?s\b/, css.gsub(/var\([^)]*\)/, ""), "duração solta no CSS (use --ss-dur-*)")
    assert_includes css, "prefers-reduced-motion: reduce"
  end

  # ── Lote A ──────────────────────────────────────────────────────────
  test "attach bar: arquivo, link e botão, com o rótulo como nome e a cor da série" do
    render_inline(Ss::AttachBarComponent.new(items: [
      { icon: "camera", label: "Foto", accept: "image/*", name: "anexo[foto]" },
      { icon: "location-marker", label: "Local", href: "/local" },
      { icon: "user", label: "Contato", data: { action: "chat#contato" } },
      { icon: "star", label: "Outro", color: "var(--success)" },
      { icon: "star", label: "Claro" }
    ], size: 60))
    assert_selector ".ss-attach[role=group][style='--s:60px']"
    assert_selector "label.ss-attach-item[data-tone='1'] input[type=file][accept='image/*'][name='anexo[foto]'][aria-label=Foto]"
    assert_selector "a.ss-attach-item[href='/local'][aria-label=Local][data-tone='2']", text: "Local"
    assert_selector "button.ss-attach-item[type=button][aria-label=Contato][data-action='chat#contato']"
    assert_selector ".ss-attach-item:not([data-tone])[style*='--c:var(--success)']"
    assert_selector ".ss-attach-item.is-light[data-tone='5']", text: "Claro"
    assert_selector ".ss-attach-item[style*='--i:4']"
  end

  test "pilha de cartões: fechada com o botão de abrir e os de trás inert; aberta, fechar" do
    render_inline(Ss::CardStackComponent.new(card_height: 120)) do |s|
      3.times { |i| s.with_card { "Cartão #{i}" } }
    end
    assert_selector ".ss-cstack[data-controller=ss-card-stack][style*='--hc:148px'][style*='--ho:384px']"
    assert_selector "li.ss-cstack-card", count: 3
    assert_selector "li.ss-cstack-card[style*='--i:0']:not([inert])"
    assert_selector "li.ss-cstack-card[inert]", count: 2
    assert_selector "li.ss-cstack-card[style*='--i:2;--sc:0.9;--op:0.76']"
    assert_selector "button.ss-cstack-toggle[aria-expanded=false]", text: "Abrir 3 cartões"
    render_inline(Ss::CardStackComponent.new(initially_open: true)) { |s| 2.times { s.with_card { "x" } } }
    assert_selector ".ss-cstack.is-open button[aria-expanded=true]", text: "Fechar cartões"
    assert_no_selector "li[inert]"
    I18n.with_locale(:en) do
      render_inline(Ss::CardStackComponent.new) { |s| 2.times { s.with_card { "x" } } }
      assert_selector "button.ss-cstack-toggle", text: "Open 2 cards"
      assert_selector "[data-ss-card-stack-close-label-value='Close cards']"
    end
  end

  test "cabeçalho com curva: tom, voltar, ações, bottom e título centrado" do
    render_inline(Ss::CurvedHeaderComponent.new(title: "Carteira", subtitle: "Novembro", back_href: "/", curve: 20, overlap: 40)) do |h|
      h.with_action { "<a href='/x' aria-label='Ajustes'>⚙</a>".html_safe }
      h.with_bottom { "abas" }
    end
    assert_selector "header.ss-curved.is-centered[data-tone=brand][style='--curve:20px;--overlap:40px']"
    assert_selector ".ss-curved-bg[aria-hidden=true]"
    assert_selector ".ss-curved-lead a.ss-curved-btn[href='/'][aria-label=Voltar]"
    assert_selector "h1.ss-curved-title", text: "Carteira"
    assert_selector ".ss-curved-actions a[aria-label=Ajustes]"
    assert_selector "p.ss-curved-sub", text: "Novembro"
    assert_selector ".ss-curved-bottom", text: "abas"
    render_inline(Ss::CurvedHeaderComponent.new(title: "Início", tone: :dark, heading: :h2))
    assert_selector "header.ss-curved[data-tone=dark]:not(.is-centered) h2.ss-curved-title", text: "Início"
    assert_no_selector ".ss-curved-lead, .ss-curved-actions"
    I18n.with_locale(:es) do
      render_inline(Ss::CurvedHeaderComponent.new(title: "x", back_href: "/"))
      assert_selector "a.ss-curved-btn[aria-label=Volver]"
    end
  end

  test "dial: slider com valor, faixa, texto, hidden e as marcações" do
    render_inline(Ss::DialComponent.new(name: "volume", value: 40, label: "Volume", caption: "Sala", ticks: 20))
    assert_selector ".ss-dial[data-controller=ss-dial][style*='--f:0.4'][data-ss-dial-step-value='1.0']"
    assert_selector ".ss-dial-face[role=slider][tabindex='0'][aria-label=Volume][aria-valuemin='0'][aria-valuemax='100'][aria-valuenow='40'][aria-valuetext='40']"
    assert_selector ".ss-dial-value", text: "40"
    assert_selector ".ss-dial-cap", text: "Sala"
    assert_selector "input[type=hidden][name=volume][value='40']", visible: :all
    assert_selector "line.ss-dial-tick", count: 21
    assert_selector "line.ss-dial-tick.is-big", count: 5
    render_inline(Ss::DialComponent.new(value: 22.5, min: 16, max: 30, step: 0.5, format: "%.1f°", disabled: true))
    assert_selector ".ss-dial.is-disabled .ss-dial-face[tabindex='-1'][aria-disabled=true][aria-valuetext='22.5°']"
    assert_no_selector "input[type=hidden]", visible: :all
    render_inline(Ss::DialComponent.new(value: 999, max: 10, step: 0.5))
    assert_selector ".ss-dial-face[aria-valuenow='10'][aria-valuetext='10,0']"
  end

  test "duo: dois lados, o ativo marcado; links com aria-current; precisa de 2" do
    itens = [{ label: "Despesas", value: "R$ 3.210,40", icon: "arrow-up" }, { label: "Receitas", value: "R$ 5.100,00" }]
    render_inline(Ss::DuoStatComponent.new(items: itens, index: 1, name: "lado"))
    assert_selector ".ss-duo[data-controller=ss-duo][style='--x:1'][role=group]"
    assert_selector "button.ss-duo-side[aria-pressed=false][aria-label='Despesas: R$ 3.210,40'] svg.ss-duo-ico"
    assert_selector "button.ss-duo-side.is-on[aria-pressed=true][data-index='1']", text: "Receitas"
    assert_selector "input[type=hidden][name=lado][value='1']", visible: :all
    render_inline(Ss::DuoStatComponent.new(items: itens.map.with_index { |it, i| it.merge(href: "?l=#{i}") }))
    assert_selector "a.ss-duo-side.is-on[href='?l=0'][aria-current=true]"
    assert_selector "a.ss-duo-side[href='?l=1']:not([aria-current])"
    assert_raises(ArgumentError) { Ss::DuoStatComponent.new(items: itens.first(1)) }
  end

  test "barras no card: escolhida por padrão a última, formato e link" do
    render_inline(Ss::FloatingBarsComponent.new(title: "Gastos", value: "R$ 1.820,00", values: [100, 200, 50], labels: %w[Set Out Nov], format: :money))
    assert_selector ".ss-fbars[data-controller='ss-in-view ss-floating-bars'] .ss-fbars-title", text: "Gastos"
    assert_selector ".ss-fbars-total", text: "R$ 1.820,00"
    assert_selector "button.ss-fbars-item", count: 3
    assert_selector "button.ss-fbars-item.is-on[aria-pressed=true][aria-label^='Nov: R$'][aria-label$='50,00']"
    assert_selector "button.ss-fbars-item[aria-pressed=false][aria-label^='Out: R$'][aria-label$='200,00'] .ss-fbars-bar[style='--f:1.0']"
    assert_selector ".ss-fbars-item[aria-label^='Set'] .ss-fbars-bar[style='--f:0.5']"
    render_inline(Ss::FloatingBarsComponent.new(values: [1, 2], labels: %w[A B], selected: 0, href: "?mes=%{index}", format: :integer))
    assert_selector "a.ss-fbars-item.is-on[href='?mes=0'][aria-current=true]"
    assert_no_selector ".ss-fbars-head"
    assert_raises(ArgumentError) { Ss::FloatingBarsComponent.new(values: [1], labels: %w[a b]) }
  end

  test "card de meta: ícone ou arte, texto e a ação sublinhada" do
    render_inline(Ss::GoalCardComponent.new(text: "Junte para a viagem.", action_label: "Criar meta", href: "/metas/nova"))
    assert_selector ".ss-goal[data-controller=ss-in-view] .ss-goal-art[aria-hidden=true] svg.ss-goal-ico"
    assert_selector "p.ss-goal-text", text: "Junte para a viagem."
    assert_selector "a.ss-goal-action[href='/metas/nova'] .ss-goal-line[aria-hidden=true]"
    render_inline(Ss::GoalCardComponent.new(text: "x", action_label: "Começar", action_data: { action: "a#b" })) do |c|
      c.with_art { "<span class='ss-illus'></span>".html_safe }
    end
    assert_selector "button.ss-goal-action[type=button][data-action='a#b']", text: "Começar"
    assert_selector ".ss-goal-art:not([aria-hidden]) .ss-illus"
  end

  test "botão hexagonal: link ou botão, nome padrão e o alvo mínimo" do
    render_inline(Ss::HexButtonComponent.new(href: "/comecar"))
    assert_selector "a.ss-hex[href='/comecar'][aria-label=Começar][style='--s:72px'] .ss-hex-shape[aria-hidden=true]"
    render_inline(Ss::HexButtonComponent.new(label: "Enviar", type: :submit, form: "f", size: 20))
    assert_selector "button.ss-hex[type=submit][form=f][aria-label=Enviar][style='--s:44px']"
    I18n.with_locale(:en) do
      render_inline(Ss::HexButtonComponent.new)
      assert_selector "button.ss-hex[type=button][aria-label='Get started']"
    end
  end

  test "tela partida: arte, pontinhos, título, texto e as duas ações" do
    render_inline(Ss::IllustratedSplitComponent.new(title: "Num lugar só", text: "Contas e metas.", illustration: :all_done,
                                                    action_label: "Começar", action_href: "/c", secondary_label: "Já tenho conta",
                                                    secondary_href: "/l", page: 1, pages: 3))
    assert_selector "section.ss-isplit .ss-isplit-art .ss-illus[data-illustration=all_done]"
    assert_selector ".ss-isplit-dots[role=img][aria-label='Página 2 de 3'] span", count: 3
    assert_selector ".ss-isplit-dots span.is-on[aria-current=step]", count: 1
    assert_selector "h1.ss-isplit-title", text: "Num lugar só"
    assert_selector "a.ss-btn.ss-btn-primary[href='/c']", text: "Começar"
    assert_selector "a.ss-btn.ss-btn-ghost[href='/l']", text: "Já tenho conta"
    render_inline(Ss::IllustratedSplitComponent.new(title: "x", action_label: "Ir")) { |s| s.with_art { "<img alt='' src='/a.svg'>".html_safe } }
    assert_selector ".ss-isplit-art img"
    assert_selector "button.ss-btn-primary[type=button]", text: "Ir"
    assert_no_selector ".ss-isplit-dots, .ss-btn-ghost"
    I18n.with_locale(:en) do
      render_inline(Ss::IllustratedSplitComponent.new(title: "x", page: 0, pages: 2))
      assert_selector ".ss-isplit-dots[aria-label='Page 1 of 2']"
    end
  end

  test "arte da ilustração: os 5 casos, nomes do Flutter e a mesma do estado vazio" do
    Ss::IllustrationArtComponent::KINDS.each do |k|
      render_inline(Ss::IllustrationArtComponent.new(k))
      assert_selector "span.ss-illus.ss-empty-art.is-anim[aria-hidden=true][data-illustration=#{k}] svg"
    end
    render_inline(Ss::IllustrationArtComponent.new(illustration: :noResults, size: 96))
    assert_selector ".ss-illus[data-illustration=no_results][style='--s:96px']"
    render_inline(Ss::IllustrationArtComponent.new(:nada))
    assert_selector ".ss-illus[data-illustration=empty]"
    assert_same Ss::IllustrationArtComponent::ILLUSTRATIONS, Ss::EmptyStateComponent::ILLUSTRATIONS
    render_inline(Ss::EmptyStateComponent.new(title: "Sem conexão", illustration: :offline))
    assert_selector ".ss-empty-state[data-illustration=offline] .ss-empty-art.is-anim .ss-ill-symbol"
  end

  test "palco da ilustração: altura, respiro e o conteúdo dentro" do
    render_inline(Ss::IllustrationStageComponent.new) { "<svg></svg>".html_safe }
    assert_selector ".ss-ill-stage[style='--h:112px'] .ss-ill-stage-fit svg"
    render_inline(Ss::IllustrationStageComponent.new(height: 160, padding: "24px 0", css: "mb-4"))
    assert_selector ".ss-ill-stage.mb-4[style='--h:160px;--pad:24px 0']"
  end

  # ── Lote B ──────────────────────────────────────────────────────────

  # ── ImageViewer ─────────────────────────────────────────────────────
  test "image viewer: miniatura abre o diálogo com barra, palco e zoom" do
    render_inline(Ss::ImageViewerComponent.new(src: "/cupom.jpg", title: "cupom.jpg", max_scale: 5))
    assert_selector ".ss-viewer-wrap[data-controller=ss-image-viewer][data-ss-image-viewer-max-value='5.0']"
    assert_selector "button.ss-viewer-trigger[aria-haspopup=dialog][aria-label='Abrir imagem: cupom.jpg'] img.ss-viewer-thumb[src='/cupom.jpg']"
    assert_selector "dialog.ss-viewer[aria-label='cupom.jpg'] .ss-viewer-bar button[aria-label=Fechar]"
    assert_selector "dialog .ss-viewer-title", text: "cupom.jpg"
    assert_selector ".ss-viewer-stage[tabindex='0'][role=img] img.ss-viewer-img[src='/cupom.jpg']"
    assert_selector ".ss-viewer-broken[hidden]", visible: :all, text: "Não deu para abrir a imagem"
    assert_selector "output.ss-viewer-pct[aria-live=polite]", text: "100%"
    %w[Reduzir Ampliar].each { |l| assert_selector ".ss-viewer-tools button[aria-label='#{l}']" }
    assert_selector ".ss-viewer-tools button[aria-label='Tamanho original']"
  end

  test "image viewer: inline sem diálogo, gatilho próprio, ações e en" do
    render_inline(Ss::ImageViewerComponent.new(src: "/a.jpg", inline: true))
    assert_selector ".ss-viewer-wrap.is-inline > div.ss-viewer[aria-label=Imagem]"
    assert_no_selector "dialog, .ss-viewer-trigger"
    render_inline(Ss::ImageViewerComponent.new(src: "/a.jpg", title: "Nota")) do |v|
      v.with_trigger { "Ver nota" }
      v.with_action { '<a class="ss-viewer-btn" href="/a.jpg" aria-label="Baixar">B</a>'.html_safe }
    end
    assert_selector ".ss-viewer-trigger", text: "Ver nota"
    assert_no_selector ".ss-viewer-thumb"
    assert_selector ".ss-viewer-actions a[aria-label=Baixar]"
    I18n.with_locale(:en) do
      render_inline(Ss::ImageViewerComponent.new(src: "/a.jpg"))
      assert_selector "button[aria-label='Open image: Image']"
      assert_selector "button[aria-label='Zoom in']"
    end
  end

  # ── MonthGrid ───────────────────────────────────────────────────────
  test "month grid: dias do domingo ao sábado, hoje, escolhido e marcadores" do
    dias = Ss::MonthGridComponent.days(Date.new(2026, 11, 1))
    assert_equal [Date.new(2026, 11, 1), Date.new(2026, 12, 5)], [dias.first, dias.last]
    assert_equal 35, dias.size
    render_inline(Ss::MonthGridComponent.new(month: Date.new(2026, 11, 1), selected: Date.new(2026, 11, 12), today: Date.new(2026, 11, 27),
                                             url: "/agenda?dia=%{date}", month_url: "/agenda?mes=%{month}",
                                             markers: { Date.new(2026, 11, 12) => %i[accent success], Date.new(2026, 11, 3) => [:nope] }))
    assert_selector ".ss-month-grid[role=group][aria-label='Calendário de Novembro 2026'][data-controller=ss-month-grid]"
    assert_selector ".ss-month-grid[data-ss-month-grid-prev-value='/agenda?mes=2026-10'][data-ss-month-grid-next-value='/agenda?mes=2026-12']"
    assert_selector ".ss-month-grid-head span", count: 7
    assert_selector "a.ss-month-grid-day", count: 30
    assert_selector "span.ss-month-grid-day.is-out[aria-hidden=true]", count: 5
    assert_selector "a[href='/agenda?dia=2026-11-12'][aria-current=date][aria-label='12/11/2026, 2 marcadores']:not([tabindex])"
    assert_selector "a.is-today[aria-label='27/11/2026, hoje'][tabindex='-1']"
    assert_selector "a[href='/agenda?dia=2026-11-12'] .ss-month-grid-dots i", count: 2
    assert_no_selector "a[href='/agenda?dia=2026-11-03'] .ss-month-grid-dots i"
  end

  test "month grid: sem url é campo (botões e input escondido); Tab no hoje; es" do
    render_inline(Ss::MonthGridComponent.new(month: Date.new(2026, 11, 1), today: Date.new(2026, 11, 27), name: "entrega"))
    assert_selector "input[type=hidden][name=entrega]", visible: :all
    assert_selector "button.ss-month-grid-day[aria-pressed=false][data-action='ss-month-grid#choose']", count: 30
    assert_selector "button[data-date='2026-11-27']:not([tabindex])"
    assert_selector "button:not([tabindex])", count: 1
    I18n.with_locale(:es) do
      render_inline(Ss::MonthGridComponent.new(month: Date.new(2026, 11, 1), today: Date.new(2026, 11, 2)))
      assert_selector ".ss-month-grid[aria-label^='Calendario de']"
      assert_selector "button[data-date='2026-11-02'][aria-label$='hoy']"
    end
  end

  # ── PeoplePicker ────────────────────────────────────────────────────
  test "people picker: checkbox por pessoa, marcadas e o Novo" do
    render_inline(Ss::PeoplePickerComponent.new(name: "pessoas[]", people: ["Ana Souza", { name: "Bruno Lima", value: 7 }],
                                                 selected: ["Ana Souza", 7], add_url: "/pessoas/new"))
    assert_selector "fieldset.ss-people legend.ss-sr", text: "Pessoas"
    assert_selector "a.ss-people-add[href='/pessoas/new']", text: "Novo"
    assert_selector "input[type=checkbox][name='pessoas[]'][value='Ana Souza'][aria-label='Ana Souza'][checked]"
    assert_selector "input[type=checkbox][value='7'][aria-label='Bruno Lima'][checked]"
    assert_selector ".ss-people-pill .ss-people-name", text: "Bruno"
    assert_selector ".ss-people-pill .ss-avatar", count: 2
    render_inline(Ss::PeoplePickerComponent.new(name: "p[]", people: ["Carla"]))
    assert_selector "input[type=checkbox]:not([checked])"
    assert_no_selector ".ss-people-add"
    I18n.with_locale(:en) { render_inline(Ss::PeoplePickerComponent.new(name: "p[]", people: [], add_url: "/x")) }
    assert_selector ".ss-people-add", text: "New"
  end

  # ── PopOutCard ──────────────────────────────────────────────────────
  test "pop out card: imagem que vaza, link no card, preço e botão de adicionar" do
    render_inline(Ss::PopOutCardComponent.new(title: "Costela-de-adão", subtitle: "Meia-sombra", price: "R$ 89,90", image_url: "/p.png",
                                              url: "/plantas/1", add_url: "/carrinho", tone: :success, pop_out: 30))
    assert_selector "article.ss-popout.is-link[data-tone=success][style*='--po:30px']"
    assert_selector ".ss-popout-img img[src='/p.png'][alt='']"
    assert_selector "h3.ss-popout-title a.ss-popout-link[href='/plantas/1']", text: "Costela-de-adão"
    assert_selector ".ss-popout-sub", text: "Meia-sombra"
    assert_selector ".ss-popout-foot .ss-amount"
    assert_selector "form[action='/carrinho'] button.ss-popout-btn[aria-label='Adicionar: Costela-de-adão']"
    render_inline(Ss::PopOutCardComponent.new(title: "X", add_url: "/x", add_method: :get, action_label: "Ver", tone: :roxo))
    assert_selector "a.ss-popout-btn[href='/x'][aria-label='Ver: X']"
    assert_no_selector ".ss-popout[data-tone], .ss-popout.is-link"
    I18n.with_locale(:es) { render_inline(Ss::PopOutCardComponent.new(title: "Y", add_url: "/y")) }
    assert_selector "button[aria-label='Añadir: Y']"
  end

  # ── ProfileHero ─────────────────────────────────────────────────────
  test "profile hero: iniciais sem foto, status online, métricas e ações" do
    render_inline(Ss::ProfileHeroComponent.new(name: "Ana Souza", status: "Online agora", online: true,
                                               metrics: [%w[128 pedidos], ["4,9", "nota"], ["3", "anos"], %w[9 extra]])) do |h|
      h.with_action { '<a href="/editar" aria-label="Editar">E</a>'.html_safe }
    end
    assert_selector "header.ss-profile-hero h1.ss-profile-hero-name", text: "Ana Souza"
    assert_selector ".ss-profile-hero-photo .ss-profile-hero-initials[aria-hidden=true]", text: "AS"
    assert_selector ".ss-profile-hero-status .ss-profile-hero-dot[role=img][aria-label=Online]"
    assert_selector ".ss-profile-hero-metric", count: 3
    assert_selector ".ss-profile-hero-metric", text: "128 pedidos"
    assert_selector ".ss-profile-hero-actions a[aria-label=Editar]"
    render_inline(Ss::ProfileHeroComponent.new(name: "Bruno", photo_url: "/b.jpg"))
    assert_selector ".ss-profile-hero-photo img[src='/b.jpg'][alt='Foto de Bruno']"
    assert_no_selector ".ss-profile-hero-bar, .ss-profile-hero-status, .ss-profile-hero-metrics"
    I18n.with_locale(:en) { render_inline(Ss::ProfileHeroComponent.new(name: "Bruno", photo_url: "/b.jpg")) }
    assert_selector "img[alt='Photo of Bruno']"
  end

  # ── PulseAvatar ─────────────────────────────────────────────────────
  test "pulse avatar: ondas quando ativo, nome e estado no role=status, bloco troca o avatar" do
    render_inline(Ss::PulseAvatarComponent.new(name: "Ana Souza", status: "chamando", size: 60, tone: :success))
    assert_selector ".ss-pulse.is-active[data-tone=success][style*='--s:60px']"
    assert_selector ".ss-pulse-waves[aria-hidden=true] i", count: 3
    assert_selector ".ss-pulse-face .ss-avatar"
    assert_selector ".ss-sr[role=status]", text: "Ana Souza, chamando"
    render_inline(Ss::PulseAvatarComponent.new(name: "IA", active: false, tone: :x)) { "<svg></svg>".html_safe }
    assert_selector ".ss-pulse:not(.is-active)[data-tone=accent] .ss-pulse-face svg"
    assert_no_selector ".ss-pulse-face .ss-avatar"
    assert_selector "[role=status]", text: "IA"
  end

  # ── RecurringCard ───────────────────────────────────────────────────
  test "recurring card: agenda, valor que rola, destino, check e menu" do
    render_inline(Ss::RecurringCardComponent.new(schedule: "Todo domingo", time: "11:00", amount: "R$ 50,00",
                                                 destination: "para Instituto Sol", done: true, url: "/rec/1", menu_url: "/rec/1/menu"))
    assert_selector "article.ss-recurring.is-done.is-link"
    assert_selector ".ss-recurring-check[role=img][aria-label=Feito]"
    assert_selector ".ss-recurring-when a.ss-recurring-link[href='/rec/1']", text: "Todo domingo"
    assert_selector ".ss-recurring-when .num", text: "11:00"
    assert_selector ".ss-recurring-value .ss-odo[data-controller~=ss-odometer]"
    assert_selector ".ss-recurring-dest", text: "para Instituto Sol"
    assert_selector "a.ss-recurring-more[href='/rec/1/menu'][aria-label='Mais opções']"
    render_inline(Ss::RecurringCardComponent.new(schedule: "Todo mês", amount: "R$ 9,90")) { |c| c.with_menu { "<button>⋮</button>".html_safe } }
    assert_selector ".ss-recurring:not(.is-done):not(.is-link) .ss-recurring-check[aria-label=Pendente]"
    assert_selector "div.ss-recurring-menu button"
    I18n.with_locale(:en) { render_inline(Ss::RecurringCardComponent.new(schedule: "Weekly", amount: "$ 1.00")) }
    assert_selector ".ss-recurring-check[aria-label=Pending]"
  end

  # ── ShapeIcon ───────────────────────────────────────────────────────
  test "shape icon: losango e hexágono, tonal e cheio, decoração sem label" do
    render_inline(Ss::ShapeIconComponent.new(icon: "bolt"))
    assert_selector "span.ss-shape-icon[data-shape=losango][data-tone=accent][aria-hidden=true][style*='--s:52px'] svg.ss-shape-icon-bg path"
    assert_selector ".ss-shape-icon svg.ss-shape-icon-ico"
    render_inline(Ss::ShapeIconComponent.new(icon: "check", shape: :hexagono, tone: :success, filled: true, size: 64, label: "Concluído"))
    assert_selector ".ss-shape-icon.is-filled[data-shape=hexagono][data-tone=success][role=img][aria-label=Concluído]"
    assert_equal 4, Ss::ShapeIconComponent.path(:losango).scan("Q").size
    assert_equal 6, Ss::ShapeIconComponent.path(:hexagono).scan("Q").size
    assert Ss::ShapeIconComponent.path(:losango).start_with?("M") && Ss::ShapeIconComponent.path(:losango).end_with?("Z")
  end

  # ── ThumbRail ───────────────────────────────────────────────────────
  test "thumb rail: miniaturas com a escolhida, setas e o alvo" do
    render_inline(Ss::ThumbRailComponent.new(images: ["/a.jpg", { src: "/b.jpg", full: "/b-g.jpg", alt: "Verso" }, "/c.jpg"],
                                             selected: 1, target: "foto", thumb_size: 56, height: 300))
    assert_selector ".ss-thumbs[role=group][aria-label=Miniaturas][data-controller=ss-thumb-rail][data-ss-thumb-rail-target-value=foto]"
    assert_selector ".ss-thumbs[style*='--ts:56px'][style*='height:300px']"
    assert_selector "button.ss-thumbs-item", count: 3
    assert_selector "button.ss-thumbs-item[aria-pressed=true][data-src='/b-g.jpg'][aria-label='Imagem 2 de 3: Verso']:not([tabindex])"
    assert_selector "button.ss-thumbs-item[aria-pressed=false][tabindex='-1']", count: 2
    assert_selector "button.ss-thumbs-arrow[aria-label='Miniaturas anteriores'][hidden]", visible: :all
    assert_selector "button.ss-thumbs-arrow[aria-label='Próximas miniaturas']:not([hidden])"
    render_inline(Ss::ThumbRailComponent.new(images: %w[/a.jpg /b.jpg], url: "/produto?foto=%{index}"))
    assert_selector "a.ss-thumbs-item[href='/produto?foto=0'][aria-current=true]"
    assert_selector "a.ss-thumbs-item[href='/produto?foto=1']:not([aria-current])"
    I18n.with_locale(:es) { render_inline(Ss::ThumbRailComponent.new(images: %w[/a.jpg])) }
    assert_selector "button[aria-label='Imagen 1 de 1']"
  end

  # ── VerticalSlider ──────────────────────────────────────────────────
  test "vertical slider: range de verdade em pé, fração e texto do valor" do
    render_inline(Ss::VerticalSliderComponent.new(name: "temp", value: 21.5, min: 16, max: 30, step: 0.5, suffix: "°", precision: 1,
                                                  label: "Temperatura", tone: :warn))
    assert_selector ".ss-vslider[data-controller=ss-vslider][data-tone=warn][style*='--f:0.3929'][data-ss-vslider-suffix-value='°']"
    assert_selector "input.ss-vslider-input[type=range][name=temp][min='16'][max='30'][step='0.5'][value='21.5']"
    assert_selector "input[aria-label=Temperatura][aria-valuetext='21,5°'][aria-orientation=vertical]"
    assert_selector ".ss-vslider-thumb[aria-hidden=true] output", text: "21,5°"
    render_inline(Ss::VerticalSliderComponent.new(name: "v", value: 140, disabled: true, format: ->(v) { "#{v.to_i} un" }))
    assert_selector ".ss-vslider.is-disabled[style*='--f:1.0'] input[disabled][value='100']"
    assert_selector "output", text: "100 un"
  end

  test "controllers do lote B existem" do
    %w[image_viewer month_grid thumb_rail vslider].each { |c| assert JS.join("ss_#{c}_controller.js").exist?, "falta ss_#{c}_controller.js" }
  end
end
