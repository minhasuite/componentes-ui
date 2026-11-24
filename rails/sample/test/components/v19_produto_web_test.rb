require "test_helper"

# v1.9 · produto: Ss::NotificationCenterComponent, Ss::AssistantComponent e Ss::CaptureHubComponent
# (pares do SsNotificationCenter, SsAssistantView e SsCaptureHub).
class V19ProdutoWebTest < ComponentTest
  CSS = Pathname(ComponentesUi::Engine.root).join("app/assets/tailwind/componentes_ui")
  JS = Pathname(ComponentesUi::Engine.root).join("app/javascript/componentes_ui/controllers")
  AGORA = Time.utc(2026, 11, 24, 15)

  def avisos
    [{ id: 1, title: "Orçamento aprovado", text: "Mercado Bom Preço aprovou.", at: Time.utc(2026, 11, 24, 14, 32), unread: true, icon: "check-circle",
       tone: :success, href: "/avisos/1/abrir", method: :patch, read_href: "/avisos/1/lido", archive_href: "/avisos/1/arquivar" },
     { id: 2, title: "Aprovação pendente", at: Time.utc(2026, 11, 24, 9, 10), unread: true, href: "/pedidos/881" },
     { id: 3, title: "Resumo do dia", at: Time.utc(2026, 11, 23, 19), href: "/resumo", archive_href: "/avisos/3/arquivar" },
     { id: 4, title: "Boas-vindas", at: Time.utc(2026, 10, 5, 8) },
     { id: 5, title: "Antigo", at: Time.utc(2025, 12, 31, 8) }]
  end

  # ── Central de notificações ──────────────────────────────────────
  test "central: grupos por dia, contagem, marcar todas e itens lido/não lido" do
    render_inline(Ss::NotificationCenterComponent.new(id: "avisos", items: avisos, now: AGORA, read_all_href: "/avisos/lidos"))
    assert_selector "section.ss-ncenter#avisos[aria-label='Notificações']"
    assert_selector ".ss-ncenter-head .ss-ncenter-count[role=status]", text: "2 não lidas"
    assert_selector ".ss-ncenter-head form[action='/avisos/lidos'] input[name=_method][value=patch]", visible: :all
    assert_selector ".ss-ncenter-head button", text: "Marcar todas como lidas"
    assert_equal ["Hoje", "Ontem", "segunda-feira, 5 de outubro", "31/12/2025"], page.all("h3.ss-ncenter-day").map(&:text)
    assert_selector "li.ss-ncenter-item.is-unread", count: 2
    assert_selector "li#avisos-item-1 .ss-icon-tile.is-success"
    assert_selector "li#avisos-item-1 time.ss-ncenter-time[datetime]", text: "14:32"
    assert_selector "li#avisos-item-1 .ss-ncenter-dot .ss-sr", text: "não lida"
    # Abrir com PATCH vira button_to; sem method, link; sem href, div.
    assert_selector "li#avisos-item-1 form[action='/avisos/1/abrir'] button.ss-ncenter-main", text: "Orçamento aprovado"
    assert_selector "li#avisos-item-2 a.ss-ncenter-main[href='/pedidos/881'][data-turbo-frame=_top]"
    assert_selector "li#avisos-item-4 div.ss-ncenter-main"
    # Ações: lida só na não lida; arquivar quando há href.
    assert_selector "li#avisos-item-1 .ss-ncenter-actions form[action='/avisos/1/lido'] button[aria-label='Marcar como lida']"
    assert_selector "li#avisos-item-1 .ss-ncenter-actions form[action='/avisos/1/arquivar'] button[aria-label='Arquivar']"
    assert_no_selector "li#avisos-item-3 [aria-label='Marcar como lida']"
    assert_selector "li#avisos-item-3 [aria-label='Arquivar']"
    assert_no_selector "li#avisos-item-4 .ss-ncenter-actions"
  end

  test "central: contagem do servidor, tudo lido e vazio" do
    render_inline(Ss::NotificationCenterComponent.new(items: avisos.first(1), unread_count: 12, now: AGORA, read_all_href: "/x"))
    assert_selector ".ss-ncenter-count", text: "12 não lidas"

    render_inline(Ss::NotificationCenterComponent.new(items: [avisos[2]], now: AGORA, read_all_href: "/x"))
    assert_selector ".ss-ncenter-count", text: "Tudo lido"
    assert_no_selector ".ss-ncenter-head button"

    render_inline(Ss::NotificationCenterComponent.new(items: [], empty_text: "Pedido aprovado aparece aqui."))
    assert_selector ".ss-ncenter .ss-empty-state", text: "Nenhuma notificação"
    assert_text "Pedido aprovado aparece aqui."
  end

  test "central: paginação por turbo-frame lazy e o fragmento da próxima página" do
    render_inline(Ss::NotificationCenterComponent.new(id: "av", items: avisos.first(2), now: AGORA, next_href: "/avisos?page=2"))
    assert_selector "turbo-frame#av-p2.ss-ncenter-next[src='/avisos?page=2'][loading=lazy][target=_top] a[data-turbo-frame=av-p2]", text: "Carregar mais"

    render_inline(Ss::NotificationCenterComponent.new(id: "av", items: avisos[2..3], now: AGORA, fragment: true, page: 2,
                                                      after: Time.utc(2026, 11, 23, 20), next_href: "/avisos?page=3"))
    assert_selector "turbo-frame#av-p2[target=_top] > .ss-ncenter-group", count: 2
    assert_no_selector ".ss-ncenter-head"
    assert_equal ["segunda-feira, 5 de outubro"], page.all("h3.ss-ncenter-day").map(&:text) # "Ontem" não repete na emenda
    assert_selector "turbo-frame#av-p2 turbo-frame#av-p3[src='/avisos?page=3']"
  end

  test "central em inglês" do
    I18n.with_locale(:en) do
      render_inline(Ss::NotificationCenterComponent.new(items: avisos, now: AGORA, read_all_href: "/x"))
      assert_selector ".ss-ncenter-count", text: "2 unread"
      assert_equal "Today", page.first("h3.ss-ncenter-day").text
      assert_selector "h3.ss-ncenter-day", text: "Monday, October 5"
      assert_selector "button", text: "Mark all as read"
    end
  end

  # ── Assistente ───────────────────────────────────────────────────
  test "assistente: conversa, ação sugerida, pendente com polling, falha e atalhos no topo" do
    render_inline(Ss::AssistantComponent.new(id: "asst", url: "/mensagens",
      messages: [{ from: :me, text: "Monte um treino", time: "14:02" },
                 { from: :ai, text: "Posso montar assim?", action: { title: "Montar este treino", confirm_url: "/montar", confirm_label: "Montar treino" } },
                 { status: :pending, poll_url: "/mensagens/9" },
                 { status: :failed, error: "A IA caiu.", retry_href: "/mensagens/8/retry" }],
      shortcuts: [{ label: "Resumo da semana", prompt: "Como foi a minha semana?" }, { label: "Metas", href: "/metas" }]))
    assert_selector ".ss-assistant[data-controller=ss-assistant][data-ss-assistant-every-value='2000'][data-ss-assistant-max-value='90']"
    assert_selector ".ss-assistant-main > .ss-assistant-top .ss-assistant-chips[role=group][aria-label='Sugestões']"
    assert_selector ".ss-assistant-top button.ss-chip[data-action='ss-assistant#pick'][data-ss-assistant-prompt-param='Como foi a minha semana?']", text: "Resumo da semana"
    assert_selector ".ss-assistant-top a.ss-chip[href='/metas']", text: "Metas"
    assert_selector "section.ss-chat-panel#asst #asst-messages[role=log] .ss-bubble.is-me", text: "Monte um treino"
    assert_selector "#asst-messages .ss-bubble.is-ai", text: "Posso montar assim?"
    assert_selector "#asst-messages .ss-chat-action", text: "Montar este treino"
    assert_selector "#asst-messages .ss-bubble.is-ai.is-pending[role=status][aria-label=Respondendo][data-ss-assistant-target=pending][data-url='/mensagens/9'] .ss-thinking"
    assert_selector "#asst-messages .ss-bubble.is-failed p", text: "A IA caiu."
    assert_selector "#asst-messages .ss-bubble.is-failed form[action='/mensagens/8/retry'] button", text: "Tentar de novo"
    assert_selector "form.ss-chat-form[action='/mensagens'] textarea:not([disabled])"
    assert_no_selector ".ss-assistant-side"
  end

  test "assistente: vazio com atalhos centrados, sem faixa no topo" do
    render_inline(Ss::AssistantComponent.new(id: "a2", url: "/m", empty_text: "Pergunte sobre o treino.", shortcuts: [{ label: "Metas", icon: "flag" }]))
    assert_selector ".ss-chat-empty .ss-assistant-empty .ss-assistant-empty-title", text: "Como posso ajudar?"
    assert_selector ".ss-chat-empty .ss-assistant-chips.is-center button.ss-chip svg"
    assert_no_selector ".ss-assistant-top"
  end

  test "assistente: conversas ao lado com abrir, nova e apagar com confirmação" do
    render_inline(Ss::AssistantComponent.new(id: "a3", url: "/m", current_conversation_id: 1, new_conversation_href: "/conversas/new",
      conversations: [{ id: 1, title: "Treino de perna", subtitle: "há 2 h", href: "/conversas/1", delete_href: "/conversas/1" }, { id: 2, href: "/conversas/2" }]))
    assert_selector ".ss-assistant.has-side > aside.ss-assistant-side[aria-label=Conversas]"
    assert_selector ".ss-assistant-side-head a.ss-icon-btn[href='/conversas/new'][aria-label='Nova conversa']"
    assert_selector "li.ss-assistant-conv-row.is-current a.ss-assistant-conv[aria-current=page][href='/conversas/1']", text: "Treino de perna"
    assert_selector "li.ss-assistant-conv-row a[href='/conversas/2'] .ss-assistant-conv-title", text: "Conversa"
    assert_selector "form[action='/conversas/1'][data-turbo-confirm='Apagar esta conversa?'][data-turbo-confirm-tone=danger] input[name=_method][value=delete]", visible: :all
    assert_selector "form[action='/conversas/1'] button.ss-icon-btn.is-danger[aria-label='Apagar conversa']"

    render_inline(Ss::AssistantComponent.new(id: "a4", url: "/m", conversations: []))
    assert_selector ".ss-assistant-side-empty", text: "Nenhuma conversa ainda"
  end

  test "assistente: cota acabada trava o campo; plano sem direito troca a conversa" do
    render_inline(Ss::AssistantComponent.new(id: "a5", url: "/m", messages: [{ from: :ai, text: "Oi" }], quota: { used: 10, limit: 10 },
                                             shortcuts: [{ label: "Metas" }]))
    assert_selector ".ss-quota.ss-assistant-quota.is-out[style='--v:1.0'] b", text: "10 de 10"
    assert_selector "textarea.ss-chat-input[disabled][placeholder='Mensagens do mês esgotadas']"
    assert_selector "button.ss-chip[disabled]"

    render_inline(Ss::AssistantComponent.new(id: "a5b", url: "/m", quota: { used: 2, limit: 3, label: "Perguntas" }))
    assert_selector ".ss-quota.is-low span", text: "Perguntas"

    render_inline(Ss::AssistantComponent.new(id: "a6", url: "/m", locked: { feature: "Assistente com IA", text: "Nos planos Pro e Max.", href: "/planos" }))
    assert_selector ".ss-assistant-locked .ss-assistant-locked-title", text: "Assistente com IA"
    assert_selector ".ss-assistant-locked .ss-assistant-locked-tag", text: "Só nos planos pagos"
    assert_selector ".ss-assistant-locked a.ss-btn[href='/planos']", text: "Ver planos"
    assert_no_selector ".ss-chat-panel"
  end

  # ── Formas de capturar ───────────────────────────────────────────
  test "captura: destaque, grupos, padrões por tipo, indisponível com motivo, upload e colar" do
    render_inline(Ss::CaptureHubComponent.new(id: "cap",
      upload: { url: "/leituras", name: "leitura[arquivos][]", accept: "image/*,.pdf,.xml" },
      paste: { url: "/leituras/texto", name: "leitura[texto]" },
      options: [{ kind: :camera, title: "Foto do cupom", description: "Cupom fiscal ou print.", highlighted: true },
                { kind: :paste, group: "Compra" }, { kind: :file, group: "Compra" },
                { kind: :barcode, group: "Produto", href: "/leitor" },
                { kind: :gallery, group: "Produto", disabled_reason: "No plano Pro ou Max", disabled_href: "/planos" },
                { kind: :custom, title: "Manual", group: "Produto", disabled_reason: "Sem permissão" }]))
    assert_selector "section.ss-capture#cap[data-controller=ss-capture-hub][data-action='paste->ss-capture-hub#paste']"
    assert_selector "button.ss-capture-opt.is-highlight[data-action='ss-capture-hub#choose'][data-ss-capture-hub-kind-param=camera] .ss-icon-tile.is-on-grad"
    assert_selector ".ss-capture-opt.is-highlight .ss-capture-eyebrow", text: "Recomendado"
    assert_equal %w[Compra Produto], page.all("h3.ss-capture-group").map(&:text)
    assert_selector ".ss-capture-grid button.ss-capture-opt[data-action='ss-capture-hub#showPaste'] .ss-capture-title", text: "Colar texto"
    assert_selector ".ss-capture-grid button.ss-capture-opt[data-ss-capture-hub-kind-param=file] .ss-capture-note", text: "PDF, XML ou imagem"
    assert_selector ".ss-capture-grid a.ss-capture-opt[href='/leitor'] svg[data-icon=qrcode]"
    assert_selector "a.ss-capture-opt.is-disabled[href='/planos'] .ss-capture-note", text: "No plano Pro ou Max"
    assert_selector "a.ss-capture-opt.is-disabled .ss-sr", text: "Indisponível"
    assert_selector "div.ss-capture-opt.is-disabled[aria-disabled=true] .ss-capture-lock"
    assert_selector "form.ss-capture-paste[action='/leituras/texto'][hidden][data-ss-capture-hub-target=pasteForm] textarea[name='leitura[texto]'][data-ss-capture-hub-target=text]", visible: :all
    assert_selector "form.ss-capture-upload[action='/leituras'][enctype='multipart/form-data'] .ss-file-drop[data-ss-capture-hub-target=drop] input[type=file][name='leitura[arquivos][]'][accept='image/*,.pdf,.xml']", visible: :all
    assert_no_selector "input[type=file][multiple]", visible: :all
  end

  test "captura: sem upload/paste a opção é botão do app; em espanhol" do
    render_inline(Ss::CaptureHubComponent.new(options: [{ kind: :camera, data: { action: "app#foto" } }]))
    assert_selector "button.ss-capture-opt[data-action='app#foto']", text: "Tirar foto"
    assert_no_selector "form"
    I18n.with_locale(:es) do
      render_inline(Ss::CaptureHubComponent.new(options: [{ kind: :barcode, href: "/x" }]))
      assert_selector ".ss-capture-title", text: "Código de barras"
      assert_selector ".ss-capture-note", text: "Apunta al código"
    end
  end

  # ── CSS, JS e textos ─────────────────────────────────────────────
  test "CSS importado, só tokens, alvo de 44px e reduzir movimento" do
    css = CSS.join("v19_produto.css").read
    assert_includes CSS.join("engine.css").read, %(@import "./v19_produto.css";)
    refute_match(/#[0-9a-f]{3,6}\b(?![-\w])/i, css.gsub(/#fff\b/i, ""), "cor fixa além do branco sobre o gradiente")
    assert_includes css, "min-height: 44px"
    assert_includes css, "prefers-reduced-motion: reduce"
    assert_includes css, "var(--accent)"
  end

  test "controllers: polling da pendente e colar no hub" do
    a = JS.join("ss_assistant_controller.js").read
    assert_includes a, "pendingTargetConnected"
    assert_includes a, "document.hidden"
    assert_includes a, "outerHTML"
    c = JS.join("ss_capture_hub_controller.js").read
    assert_includes c, "clipboardData"
    assert_includes c, %(setAttribute("capture", "environment"))
  end

  test "textos nos três idiomas" do
    %i[pt-BR en es].each do |loc|
      I18n.with_locale(loc) do
        %w[assistant.new assistant.delete_confirm assistant.exhausted capture_hub.camera.title capture_hub.unavailable
           notification_center.read_all notification_center.day_pattern].each do |k|
          assert I18n.exists?("componentes_ui.#{k}", loc), "#{loc}: falta componentes_ui.#{k}"
        end
      end
    end
  end
end
