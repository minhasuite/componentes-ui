require "test_helper"

# v0.26 · conversa entre pessoas (minhas-vendas: atendimento do WhatsApp, cliente e atendente).
class V26WebTest < ComponentTest
  CSS = Pathname(ComponentesUi::Engine.root).join("app/assets/tailwind/componentes_ui")
  Msg = Ss::ChatComponent::Message

  test "from: :them é a outra pessoa (à esquerda, sem ser a IA); :me e :ai como antes" do
    render_inline(Msg.new(from: :them, text: "O pedido saiu?", time: "09:10"))
    assert_selector ".ss-bubble.is-them[data-from=them]", text: "O pedido saiu?"
    refute_selector ".is-ai, .is-me"
    render_inline(Msg.new(from: :me, text: "Saiu", time: "09:12"))
    assert_selector ".ss-bubble.is-me[data-from=me] > small.num", exact_text: "09:12"
    render_inline(Msg.new(text: "Posso lançar?"))
    assert_selector ".ss-bubble.is-ai[data-from=ai]"
  end

  test "author: legenda no alto, dentro da bolha" do
    render_inline(Msg.new(from: :me, author: "Ana · pelo celular", text: "Saiu hoje cedo."))
    assert_selector ".ss-bubble.is-me > span.ss-bubble-author:first-child", text: "Ana · pelo celular"
    assert_selector ".ss-bubble > span.ss-bubble-author + p", text: "Saiu hoje cedo."
    render_inline(Msg.new(from: :them, text: "Oi"))
    refute_selector ".ss-bubble-author"
  end

  test "status: ícone e nome (leitor de tela) no rodapé, ao lado do horário" do
    { sending: "Enviando", sent: "Enviada", delivered: "Entregue", read: "Lida" }.each do |st, nome|
      render_inline(Msg.new(from: :me, text: "x", time: "10:00", status: st))
      assert_selector "small.num.ss-bubble-foot > span.ss-bubble-time", text: "10:00"
      assert_selector "small.ss-bubble-foot > .ss-bubble-status[data-status=#{st}] > svg[aria-hidden=true]"
      assert_selector ".ss-bubble-status[data-status=#{st}] > span.ss-sr", text: nome
    end
    # Não enviada: o texto fica à vista (sem .ss-sr).
    render_inline(Msg.new(from: :me, text: "x", time: "10:00", status: :failed))
    assert_selector ".ss-bubble-status[data-status=failed] > span:not(.ss-sr)", text: "Não enviada"
    # Só status (sem horário) também mostra o rodapé; status desconhecido é ignorado.
    render_inline(Msg.new(from: :me, text: "x", status: "delivered"))
    assert_selector "small.ss-bubble-foot .ss-bubble-status[data-status=delivered]"
    refute_selector ".ss-bubble-time"
    render_inline(Msg.new(from: :me, text: "x", status: :lixo))
    refute_selector "small"
  end

  test "status traduzido (en, es)" do
    I18n.with_locale(:en) { render_inline(Msg.new(from: :me, text: "x", status: :read)) }
    assert_selector ".ss-bubble-status .ss-sr", text: "Read"
    I18n.with_locale(:es) { render_inline(Msg.new(from: :me, text: "x", status: :failed)) }
    assert_selector ".ss-bubble-status[data-status=failed]", text: "No enviado"
  end

  test "ChatDividerComponent: separador com o rótulo" do
    render_inline(Ss::ChatDividerComponent.new(label: "Hoje"))
    assert_selector "div.ss-chat-divider[role=separator][aria-label=Hoje] > span", text: "Hoje"
  end

  test "o bloco entra dentro do log, depois do slot; o empty só sem mensagem nenhuma" do
    render_inline(Ss::ChatComponent.new(id: "wa", url: "/wa", echo: false)) do |chat|
      chat.with_message(from: :them, text: "primeira")
      chat.with_empty { "Nenhuma mensagem" }
      ActionController::Base.helpers.safe_join([render_inline_html(Ss::ChatDividerComponent.new(label: "Hoje")),
                 render_inline_html(Msg.new(from: :me, text: "segunda", status: :sent))])
    end
    assert_selector "#wa-messages.ss-chat[role=log] > .ss-bubble.is-them:first-child", text: "primeira"
    assert_selector "#wa-messages > .ss-bubble.is-them + .ss-chat-divider + .ss-bubble.is-me", text: "segunda"
    refute_selector ".ss-chat-empty"

    # Só pelo bloco (sem o slot): nada de empty também.
    render_inline(Ss::ChatComponent.new(id: "wb")) do |chat|
      chat.with_empty { "Nenhuma mensagem" }
      render_inline_html(Msg.new(from: :them, text: "oi"))
    end
    assert_selector "#wb-messages > .ss-bubble.is-them", text: "oi"
    refute_selector ".ss-chat-empty"

    # Vazio de verdade: aparece.
    render_inline(Ss::ChatComponent.new(id: "wc")) { |chat| chat.with_empty { "Nenhuma mensagem" } }
    assert_selector "#wc-messages > .ss-chat-empty[data-ss-chat-target=empty]", text: "Nenhuma mensagem"
  end

  test "CSS: bolha da outra pessoa, autor, situação, separador e mídia só com token" do
    css = CSS.join("v26_web.css").read
    assert_includes CSS.join("engine.css").read, %(@import "./v26_web.css";)
    %w[.ss-bubble-author .ss-bubble-foot .ss-bubble-status .ss-chat-divider .ss-bubble-media .ss-bubble-file].each { |c| assert_includes css, c }
    assert_match(/\.ss-bubble-status\[data-status="read"\] \{[^}]*color: var\(--accent\)/, css)
    assert_match(/\.ss-bubble-status\[data-status="failed"\] \{[^}]*color: var\(--danger\)/, css)
    assert_match(/audio\.ss-bubble-media \{[^}]*min-width: min\(16rem, 100%\)/, css)
    refute_match(/#[0-9a-f]{3,8}\b|rgba?\(/i, css, "cor solta no v26_web.css")
  end

  private

  def render_inline_html(component) = vc_test_controller.view_context.render(component)
end
