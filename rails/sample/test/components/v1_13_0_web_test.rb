require "test_helper"

# v1.13.0 "confiança na IA e suíte": o valor falado (ComponentesUi::Speech contra docs/v1130/fala.json, os mesmos casos
# do Dart e do JS), o estado no link (ComponentesUi::Handoff contra docs/v1130/handoff.json) e os componentes
# Ss::ExplainComponent, Ss::AiActionPreviewComponent, Ss::SinceLastVisitComponent, Ss::ContinueOnComponent,
# Ss::SuiteSwitcherComponent, Ss::ConflictResolverComponent, o microfone do Ss::MoneyInputComponent e o modo discreto
# automático do ss-privacy.
class V1130WebTest < ComponentTest
  ROOT = Pathname(ComponentesUi::Engine.root)
  CSS = ROOT.join("app/assets/tailwind/componentes_ui")
  JS = ROOT.join("app/javascript/componentes_ui/controllers")
  PARIDADE = YAML.load_file(ROOT.join("../paridade.yml"))
  FALA = JSON.parse(ROOT.join("../docs/v1130/fala.json").read)
  HANDOFF = JSON.parse(ROOT.join("../docs/v1130/handoff.json").read)
  NOW = Time.zone.local(2026, 11, 27, 10, 0)

  include ComponentesUi::Helpers

  # ── paridade.yml ────────────────────────────────────────────────────
  test "paridade.yml: as peças da v1.13" do
    {
      "SsExplain" => "Ss::ExplainComponent", "SsAiActionPreview" => "Ss::AiActionPreviewComponent",
      "SsSinceLastVisit" => "Ss::SinceLastVisitComponent", "SsContinueOn" => "Ss::ContinueOnComponent",
      "SsSuiteSwitcher" => "Ss::SuiteSwitcherComponent", "SsConflictResolver" => "Ss::ConflictResolverComponent",
      "SsSpokenAmount" => "js:ss-spoken-amount"
    }.each do |f, r|
      skip "o paridade.yml ainda sem a v1.13" unless PARIDADE["pares"].key?(f)
      assert_includes Array(PARIDADE["pares"][f]), r, f
    end
    assert_includes Array(PARIDADE["pares"]["SsPrivacyScope"]), "js:ss-privacy"
    assert_equal({}, PARIDADE["divida"])
    assert_equal({}, PARIDADE["divida_app"])
  end

  # ── Valor falado ────────────────────────────────────────────────────
  test "Speech: os casos de docs/v1130/fala.json" do
    assert_operator FALA["casos"].size, :>=, 80
    FALA["casos"].each do |(texto, esperado)|
      r = ComponentesUi::Speech.parse_amount(texto)
      esperado.nil? ? assert_nil(r, texto) : assert_equal(esperado, r, texto)
    end
    assert_nil ComponentesUi::Speech.parse_amount(nil)
    assert_equal 1250, ss_spoken_amount("doze e meio")
    assert_includes ComponentesUi::Speech::WORDS, "quinhentos"
  end

  test "Speech: o JS (node) dá o mesmo nos casos e no handoff" do
    node = ENV.fetch("PATH", "").split(":").map { File.join(_1, "node") }.find { File.executable?(_1) }
    skip "sem node no PATH: rode rails/sample/test/js/ss_speech_check.mjs à mão" unless node
    out = IO.popen([node, Rails.root.join("test/js/ss_speech_check.mjs").to_s], err: %i[child out], &:read)
    assert $?.success?, out
  end

  # ── Handoff ─────────────────────────────────────────────────────────
  test "Handoff: o mesmo vetor do Dart, o link e o decode que não quebra" do
    assert_equal HANDOFF["encoded"], ComponentesUi::Handoff.encode(HANDOFF["state"])
    assert_equal HANDOFF["link"], ComponentesUi::Handoff.link(HANDOFF["base"], HANDOFF["state"])
    assert_equal HANDOFF["link"], ss_handoff_link(HANDOFF["base"], HANDOFF["state"])
    assert_equal HANDOFF["state"], ComponentesUi::Handoff.decode(HANDOFF["encoded"])
    assert_equal "https://x/p?q=eyJhIjoxfQ", ComponentesUi::Handoff.link("https://x/p", { a: 1 }, param: "q")
    assert_equal "https://x/p", ComponentesUi::Handoff.link("https://x/p", nil)
    assert_nil ComponentesUi::Handoff.decode("%%%")
    assert_nil ComponentesUi::Handoff.decode(Base64.urlsafe_encode64("[1,2]"))
    assert_nil ComponentesUi::Handoff.decode(nil)
  end

  # ── Explicar o valor ────────────────────────────────────────────────
  test "Explain: o ?, o popover com fórmula, itens, mais e a IA" do
    render_inline(Ss::ExplainComponent.new(value: "R$ 1.240,00", title: "Gastos de novembro", formula: "Soma dos 23 lançamentos de nov",
                                           items: [{ label: "Mercado", value: "R$ 512,40", href: "/m", hint: "9 lançamentos" }, { label: "Outros", value: "R$ 10,00" }],
                                           more: 21, more_href: "/todos", ai_url: "/explicar")) { "<b>KPI</b>".html_safe }
    assert_selector ".ss-explain[data-controller=ss-explain][data-ss-explain-url-value='/explicar'][data-ss-explain-method-value=POST] .ss-explain-target b", text: "KPI"
    assert_selector "button.ss-explain-btn[aria-label='Ver de onde vem este valor: R$ 1.240,00'][popovertarget]"
    assert_selector ".ss-popover.ss-explain-pop[popover=auto][role=dialog][aria-label='Gastos de novembro']", visible: :all
    assert_selector ".ss-explain-value.num", text: "R$ 1.240,00", visible: :all
    assert_selector ".ss-explain-formula", text: "Soma dos 23 lançamentos de nov", visible: :all
    assert_selector "ul.ss-explain-items a.ss-explain-item[href='/m']", text: "Mercado", visible: :all
    assert_selector "ul.ss-explain-items span.ss-explain-item", text: "Outros", visible: :all
    assert_selector ".ss-explain-more", text: "e mais 21", visible: :all
    assert_selector ".ss-explain-more a[href='/todos']", text: "Ver todos", visible: :all
    assert_selector ".ss-explain-ai[data-state=idle] button[data-action='ss-explain#ask']", text: "Explicar com IA", visible: :all
    assert_selector ".ss-explain-thinking[role=status] .ss-thinking", visible: :all
    assert_selector "button[data-action='ss-explain#cancel']", text: "Cancelar", visible: :all
    assert_selector ".ss-explain-error[role=alert]", text: "Não deu para explicar agora.", visible: :all
    render_inline(Ss::ExplainComponent.new(value: "18%")) { "x" }
    refute_selector ".ss-explain-ai", visible: :all
    assert_selector ".ss-popover[aria-label='De onde vem este valor']", visible: :all
  end

  # ── Prévia da ação da IA ────────────────────────────────────────────
  test "AiActionPreview: o tipo de cada campo" do
    k = Ss::AiActionPreviewComponent
    assert_equal :added, k.kind(nil, "Casa")
    assert_equal :removed, k.kind("Mensal", "")
    assert_equal :changed, k.kind("Outros", "Mercado")
    assert_equal :same, k.kind("A", "A")
    assert_equal :same, k.kind(nil, "")
  end

  test "AiActionPreview: caixas por alteração, antes e depois, contagem e os botões" do
    render_inline(Ss::AiActionPreviewComponent.new(apply_url: "/aplicar", adjust_href: "/ajustar", changes: [
      { id: 1, title: "Lançamento 1", fields: [{ label: "Categoria", before: "Outros", after: "Mercado" }, { label: "Etiqueta", before: nil, after: "Casa" }, { label: "Conta", before: "C", after: "C" }] },
      { id: 2, title: "Lançamento 2", fields: [{ label: "Recorrência", before: "Mensal", after: nil }], selected: false }
    ]))
    assert_selector "form.ss-ai-preview[action='/aplicar'][data-controller=ss-ai-preview][data-ss-ai-preview-total-value='2']"
    assert_selector "input[type=checkbox][name='changes[]'][value='1'][checked][aria-label='Incluir Lançamento 1']"
    assert_selector "input[type=checkbox][name='changes[]'][value='2']:not([checked])"
    assert_selector ".ss-ai-diff-row", count: 3
    assert_selector ".ss-ai-diff-row[data-kind=changed] del", text: "Outros"
    assert_selector ".ss-ai-diff-row[data-kind=changed] ins", text: "Mercado"
    assert_selector ".ss-ai-diff-row[data-kind=changed] .ss-badge-warn", text: "Alterado"
    assert_selector ".ss-ai-diff-row[data-kind=added] del.is-empty", text: "(vazio)"
    assert_selector ".ss-ai-diff-row[data-kind=added] .ss-badge", text: "Novo"
    assert_selector ".ss-ai-diff-row[data-kind=removed] .ss-badge", text: "Removido"
    assert_selector ".ss-ai-diff-row .ss-sr", text: "Antes:", visible: :all
    assert_selector ".ss-ai-preview-count[aria-live=polite]", text: "1 de 2 marcadas"
    assert_selector "button[data-action='ss-ai-preview#all']", text: "Marcar todas"
    assert_selector "button[data-ss-dialog-dismiss]", text: "Cancelar"
    assert_selector "a.ss-btn[href='/ajustar']", text: "Ajustar"
    assert_selector "button[type=submit]:not([disabled])", text: "Aplicar"
    assert_selector ".ss-ai-preview-none[hidden]", visible: :all
    render_inline(Ss::AiActionPreviewComponent.new(apply_url: "/a", cancel_href: "/c", changes: [{ id: 9, title: "X", fields: [], selected: false }]))
    assert_selector "button[type=submit][disabled]", text: "Aplicar"
    assert_selector ".ss-ai-preview-none[role=status]", text: "Marque ao menos uma alteração para aplicar."
    assert_selector "a.ss-btn[href='/c']", text: "Cancelar"
    refute_selector ".ss-ai-preview-count"
  end

  test "ChatAction: review_dialog abre a prévia" do
    render_inline(Ss::ChatActionComponent.new(title: "Recategorizar", review_dialog: "previa", confirm_url: "/ok"))
    assert_selector "button.ss-chat-action-review[data-ss-dialog-open=previa]", text: "Ver alterações"
    render_inline(Ss::ChatActionComponent.new(title: "Recategorizar", confirm_url: "/ok"))
    refute_selector ".ss-chat-action-review"
  end

  # ── Desde a última visita ───────────────────────────────────────────
  test "SinceLastVisit: a frase de quando" do
    k = Ss::SinceLastVisitComponent
    assert_equal "Desde hoje às 8h", k.since_label(NOW.change(hour: 8), now: NOW)
    assert_equal "Desde ontem às 18h", k.since_label(NOW - 1.day + 8.hours, now: NOW)
    assert_equal "Desde ontem às 18h30", k.since_label((NOW - 1.day).change(hour: 18, min: 30), now: NOW)
    assert_equal "Desde segunda às 9h", k.since_label(Time.zone.local(2026, 11, 23, 9), now: NOW)
    assert_equal "Desde 12/11", k.since_label(Time.zone.local(2026, 11, 12, 9), now: NOW)
    I18n.with_locale(:en) { assert_equal "Since yesterday at 6:30 PM", k.since_label((NOW - 1.day).change(hour: 18, min: 30), now: NOW) }
    I18n.with_locale(:es) { assert_equal "Desde ayer a las 18:00", k.since_label((NOW - 1.day).change(hour: 18), now: NOW) }
    I18n.with_locale(:en) { assert_equal "Since today at 12 PM", k.since_label(NOW.change(hour: 12), now: NOW + 1.hour) }
  end

  test "SinceLastVisit: o cartão, os números que rolam, as ações e o Entendi" do
    render_inline(Ss::SinceLastVisitComponent.new(since: (NOW - 1.day).change(hour: 18), now: NOW, items: [
      { value: "3", label: "pedidos novos", icon: "shopping-bag", href: "/pedidos" },
      { value: "R$ 1.240,00", label: "recebidos", icon: "cash", tone: :success },
      { value: "1", label: "tarefa atrasada", tone: :xyz, href: "/t", action_label: "Resolver" }
    ]))
    assert_selector "section.ss-since[role=region][data-controller=ss-since][data-ss-since-key-value=ss-last-visit][data-ss-since-auto-hide-value='12']"
    assert_selector ".ss-since-head h3", text: "Desde ontem às 18h"
    assert_selector ".ss-since-kicker", text: "Enquanto você esteve fora"
    assert_selector "li.ss-since-item", count: 3
    assert_selector "li.ss-since-item[data-tone=success] .ss-odo[data-ss-odometer-roll-in-value=true]"
    assert_selector "li.ss-since-item[data-tone=accent]", count: 2
    assert_selector "a[href='/pedidos'][aria-label='Ver: 3 pedidos novos']", text: "Ver"
    assert_selector "a[href='/t']", text: "Resolver"
    assert_selector "button[data-action='ss-since#dismiss']", text: "Entendi"
    assert_includes page.find("section.ss-since")["data-action"], "mouseenter->ss-since#pause"
    render_inline(Ss::SinceLastVisitComponent.new(since: NOW, items: []))
    refute_selector ".ss-since"
    render_inline(Ss::SinceLastVisitComponent.new(src: "/novidades?desde=%{since}"))
    assert_selector "div.ss-since-host[data-controller=ss-since][data-ss-since-src-value='/novidades?desde=%{since}']", visible: :all
  end

  # ── Continuar no outro aparelho ─────────────────────────────────────
  test "ContinueOn: o botão, o QR do link com o estado, copiar e o rascunho pelo endpoint" do
    render_inline(Ss::ContinueOnComponent.new(url: HANDOFF["base"], state: HANDOFF["state"], handoff_url: "/h", form: "f"))
    assert_selector ".ss-continue-on[data-controller=ss-continue-on][data-ss-continue-on-url-value='/h'][data-ss-continue-on-form-value=f]"
    assert_selector "button.ss-btn[aria-label='Continuar no celular'][data-action*='ss-continue-on#refresh']", text: "Continuar no celular"
    assert_selector ".ss-continue-qr[role=img][aria-label='QR Code para abrir no outro aparelho'] svg", visible: :all
    assert_selector "input.ss-input[readonly][value='#{HANDOFF["link"]}'][data-ss-copy-target=source]", visible: :all
    assert_selector "button[data-action='ss-copy#copy']", text: "Copiar link", visible: :all
    assert_selector ".ss-continue-long[hidden]", visible: :all
    render_inline(Ss::ContinueOnComponent.new(url: "https://x/#{"a" * 320}", target: :computer))
    assert_selector "button", text: "Continuar no computador"
    assert_selector ".ss-continue-hint", text: "navegador do computador", visible: :all
    assert_selector ".ss-continue-long:not([hidden])", text: "O endereço é longo", visible: :all
    p = Ss::ContinueOnComponent.payload("https://x/p")
    assert_equal "https://x/p", p[:url]
    assert_includes p[:svg], "<svg"
  end

  # ── Apps da suíte ───────────────────────────────────────────────────
  test "SuiteSwitcher: seus apps, último acesso, avisos e conhecer" do
    render_inline(Ss::SuiteSwitcherComponent.new(now: NOW, products: [
      { id: "vendas", name: "Minhas Vendas", icon: "shopping-bag", color: "#0F766E", href: "/v", current: true },
      { id: "gestor", name: "Meu Gestor", icon: "chart-bar", color: "#5a45e8", href: "/g", badge: 3, last_used_at: NOW - 3.days },
      { id: "fin", name: "Meu Financeiro", color: "vermelho", href: "/f", badge: 1 },
      { id: "personal", name: "Meu Personal", active: false, description: "Treinos", discover_href: "https://x/personal" }
    ]))
    assert_selector "button.ss-icon-btn.ss-suite-btn[aria-label='Abrir os apps da suíte'] .ss-suite-dot"
    assert_selector ".ss-popover.ss-suite-pop[aria-label='Apps da suíte']", visible: :all
    assert_selector "span.ss-suite-item.is-current[aria-current=page][style='--ss-suite-c:#0f766e']", text: "Você está aqui", visible: :all
    assert_selector "a.ss-suite-item[href='/g']", text: /Usado há.3.dias/, visible: :all
    assert_selector "a.ss-suite-item[href='/g'] .ss-badge .ss-sr", text: "3 avisos", visible: :all
    assert_selector "a.ss-suite-item[href='/f']:not([style])", text: "Ainda não usado", visible: :all
    assert_selector "a.ss-suite-item[href='/f'] .ss-sr", text: "1 aviso", visible: :all
    assert_selector ".ss-suite-list.is-discover a[href='https://x/personal'][aria-label='Conhecer: Meu Personal']", text: "Conhecer", visible: :all
    assert_selector ".ss-suite-sub", text: "Conheça também", visible: :all
    render_inline(Ss::SuiteSwitcherComponent.new(products: [{ name: "A", href: "/a" }]))
    refute_selector ".ss-suite-dot"
  end

  test "AppShell: with_suite ao lado do avatar" do
    render_inline(Ss::AppShellComponent.new(brand: "X", search: false)) do |s|
      s.with_suite { "<span id='suite'>S</span>".html_safe }
      s.with_user { "<span id='user'>U</span>".html_safe }
      "corpo"
    end
    assert_selector "#suite"
    html = page.native.to_html
    assert_operator html.index("id=\"suite\""), :<, html.index("id=\"user\"")
  end

  # ── Conflito ────────────────────────────────────────────────────────
  test "ConflictResolver: só os campos diferentes, rádio por lado e os botões" do
    render_inline(Ss::ConflictResolverComponent.new(url: "/r", theirs_by: "Ana", cancel_href: "/c", fields: [
      { key: :qtd, label: "Quantidade", mine: "12", theirs: "10" },
      { key: :obs, label: "Observação", mine: "Portaria", theirs: nil },
      { key: :cliente, label: "Cliente", mine: "Loja", theirs: "Loja" }
    ]))
    assert_selector "form.ss-conflict[action='/r'][data-controller=ss-conflict] input[name=_method][value=patch]", visible: :all
    assert_selector "fieldset.ss-conflict-field", count: 2
    assert_selector "fieldset legend", text: "Quantidade"
    assert_selector "input[type=radio][name='resolve[qtd]'][value=mine][checked]"
    assert_selector "input[type=radio][name='resolve[qtd]'][value=theirs]:not([checked])"
    assert_selector ".ss-conflict-option[data-side=theirs] .ss-conflict-value", text: "(vazio)"
    assert_selector ".ss-conflict-option[data-side=theirs] .ss-conflict-side small", text: "por Ana"
    assert_selector ".ss-conflict-same", text: "1 campo igual nas duas versões"
    assert_selector "button[data-action='ss-conflict#all'][data-side=mine]", text: "Ficar com a minha"
    assert_selector "button[data-action='ss-conflict#all'][data-side=theirs]", text: "Ficar com a do servidor"
    assert_selector "button[type=submit]", text: "Salvar escolha"
    assert_selector "a[href='/c']", text: "Cancelar"
    assert_selector "h3", text: "Este registro mudou em dois lugares"
  end

  # ── Microfone e modo discreto ───────────────────────────────────────
  test "MoneyInput(voice: true): o microfone, os textos e a linha de retorno" do
    render_inline(Ss::MoneyInputComponent.new(name: "v", label: "Valor", voice: true))
    assert_selector ".ss-money-input.has-voice[data-controller='ss-money ss-spoken-amount']"
    assert_selector "input.ss-money[data-ss-spoken-amount-target=input]"
    assert_selector "button.ss-money-mic[hidden][aria-label='Falar o valor'][data-action='ss-spoken-amount#listen']", visible: :all
    assert_selector "small.ss-spoken[aria-live=polite][hidden]", visible: :all
    textos = JSON.parse(page.find(".ss-money-input")["data-ss-spoken-amount-texts-value"])
    assert_equal "Ouvi “%{text}”", textos["heard"]
    render_inline(Ss::MoneyInputComponent.new(name: "v", label: "Valor"))
    refute_selector ".ss-money-mic", visible: :all
    assert_selector ".ss-money-input[data-controller=ss-money]"
  end

  test "ss-privacy: o automático por aba escondida, tela compartilhada e o evento do produto" do
    js = JS.join("ss_privacy_controller.js").read
    assert_includes js, "auto: Boolean"
    assert_includes js, "visibilitychange"
    assert_includes js, "getDisplayMedia"
    assert_includes js, "ss-privacy:auto"
    assert_includes js, "privacyAuto"
  end

  # ── Textos ──────────────────────────────────────────────────────────
  test "idiomas: as chaves trust.* iguais nos três, e en/es nas peças" do
    pt = I18n.t("componentes_ui.trust", locale: :"pt-BR")
    assert_operator pt.size, :>=, 80
    %i[en es].each do |l|
      outro = I18n.t("componentes_ui.trust", locale: l)
      assert_equal pt.keys.sort, outro.keys.sort, l
      assert_equal pt[:privacy_reasons].keys.sort, outro[:privacy_reasons].keys.sort, l
      assert_equal 7, outro[:weekdays].size
    end
    I18n.with_locale(:en) do
      render_inline(Ss::ConflictResolverComponent.new(url: "/r", fields: [{ key: :a, label: "A", mine: "1", theirs: "2" }]))
      assert_selector "button", text: "Keep mine"
      render_inline(Ss::ContinueOnComponent.new(url: "/x"))
      assert_selector "button", text: "Continue on your phone"
    end
    I18n.with_locale(:es) do
      render_inline(Ss::AiActionPreviewComponent.new(apply_url: "/a", changes: [{ id: 1, title: "X", fields: [{ label: "C", before: "a", after: "b" }] }]))
      assert_selector "button[type=submit]", text: "Aplicar"
      assert_selector ".ss-badge", text: "Cambiado"
      render_inline(Ss::SuiteSwitcherComponent.new(products: [{ name: "A", active: false, discover_href: "/d" }]))
      assert_selector "a", text: "Conocer", visible: :all
    end
  end

  # ── CSS e JS ────────────────────────────────────────────────────────
  test "CSS importado, só tokens, sem duração solta, reduzir movimento e alvo; um controller por peça" do
    assert_includes CSS.join("engine.css").read, '@import "./v1130_web.css";'
    css = CSS.join("v1130_web.css").read.gsub(%r{/\*.*?\*/}m, "")
    refute_match(/#(?!fff\b)[0-9a-f]{3,6}\b/i, css, "cor fixa no CSS (só o papel claro do QR)")
    refute_match(/(?<![\w-])\d*\.?\d+m?s\b/, css.gsub(/var\([^)]*\)/, ""), "duração solta (use --ss-dur-*)")
    assert_includes css, "prefers-reduced-motion: reduce"
    assert_includes css, "var(--ss-target"
    %w[explain ai_preview since continue_on conflict spoken_amount privacy].each do |c|
      assert JS.join("ss_#{c}_controller.js").exist?, "falta ss_#{c}_controller.js"
    end
    assert_match(/export function ssParseAmount/, JS.join("ss_speech.js").read)
  end

  # v1.14.0: Novidades passou à v1.14; a página da v1.13 continua marcada com a versão e nas categorias dela.
  test "vitrine: a página da v1.13 nas quatro categorias, marcada com a versão dela" do
    pagina = VitrineController.paginas.find { _1[:slug] == "pecas_v1130" }
    assert_includes Rails.root.join("app/views/vitrine/pecas_v1130.html.erb").read.lines.first, "versao: 1.13"
    assert_equal ["Conversa, IA e avisos", "Navegação e moldura", "Retorno e estados", "Formulários e entrada"], pagina[:grupos]
  end
end

# A vitrine da v1.13 por HTTP (a página inteira e os endpoints de exemplo).
class V1130VitrineTest < ActionDispatch::IntegrationTest
  test "vitrine: a página da v1.13 abre e os endpoints de exemplo respondem" do
    get "/vitrine/pecas_v1130"
    assert_response :success
    assert_select ".ss-explain"
    assert_select ".ss-ai-preview"
    assert_select ".ss-since"
    assert_select ".ss-continue-on"
    assert_select ".ss-suite"
    assert_select ".ss-conflict"
    assert_select ".ss-money-input.has-voice"
    post "/demo/explicar"
    assert_match(/R\$/, response.parsed_body["text"])
    post "/demo/continuar", params: { demo_continuar: { cliente: "Loja" } }
    body = response.parsed_body
    assert_includes body["url"], "s="
    assert_equal({ "demo_continuar" => { "cliente" => "Loja" } }, ComponentesUi::Handoff.decode(body["url"][/s=([^&]+)/, 1]))
    assert_includes body["svg"], "<svg"
  end
end
