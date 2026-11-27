require "test_helper"

# v1.9.3: target: no Ss::ButtonComponent (link externo em outra aba, com rel="noopener"), a ação com URL externa
# da Ss::NotificationCenterComponent abrindo em outra aba e o singular no nome do sino ("Avisos, 1 não lido").
class V193WebTest < ComponentTest
  AGORA = Time.utc(2026, 11, 27, 15)

  test "botão-link com target: _blank ganha rel=noopener" do
    render_inline(Ss::ButtonComponent.new(label: "Ver no site", href: "https://exemplo.com/x", target: "_blank"))
    assert_selector "a.ss-btn[href='https://exemplo.com/x'][target=_blank][rel=noopener]", text: "Ver no site"
  end

  test "sem target: nada muda; rel: troca o padrão" do
    render_inline(Ss::ButtonComponent.new(label: "Abrir", href: "/pedidos"))
    assert_selector "a.ss-btn[href='/pedidos']"
    assert_no_selector "a[target], a[rel]"
    render_inline(Ss::ButtonComponent.new(label: "Abrir", href: "https://x.com", target: "_blank", rel: "noopener noreferrer"))
    assert_selector "a[target=_blank][rel='noopener noreferrer']"
    render_inline(Ss::ButtonComponent.new(label: "Aqui", href: "/a", target: "_self"))
    assert_selector "a[target=_self]"
    assert_no_selector "a[rel]"
  end

  test "target: em <button> e button_to não vaza para o elemento" do
    render_inline(Ss::ButtonComponent.new(label: "Salvar", target: "_blank"))
    assert_selector "button.ss-btn:not([target])", text: "Salvar"
    render_inline(Ss::ButtonComponent.new(label: "Remover", href: "/p/1", method: :delete, target: "_blank"))
    assert_selector "form[action='/p/1'] button:not([target])"
  end

  def central(actions)
    render_inline(Ss::NotificationCenterComponent.new(id: "avisos", now: AGORA,
                                                      items: [{ id: 1, title: "Pedido enviado", at: AGORA - 600, actions: }]))
  end

  test "central: ação com URL externa abre em outra aba; a interna continua no _top" do
    central([{ label: "Rastrear", href: "https://correios.com.br/rastreio/AB123", method: :get },
             { label: "Ver pedido", href: "/pedidos/1", method: :get },
             { label: "Confirmar", href: "/avisos/1/responder" }])
    extra = "li#avisos-item-1 .ss-ncenter-replies"
    assert_selector "#{extra} a[href='https://correios.com.br/rastreio/AB123'][target=_blank][rel=noopener]", text: "Rastrear"
    assert_no_selector "#{extra} a[target=_blank][data-turbo-frame]"
    assert_selector "#{extra} a[href='/pedidos/1'][data-turbo-frame=_top]:not([target])", text: "Ver pedido"
    assert_selector "#{extra} form[action='/avisos/1/responder'] button:not([target])", text: "Confirmar"
  end

  test "central: URL absoluta do próprio host não é externa; target: explícito ganha" do
    central([{ label: "Mesmo site", href: "http://test.host/pedidos/1", method: :get },
             { label: "Forçado", href: "https://fora.com/x", method: :get, target: nil }])
    assert_selector "a[href='http://test.host/pedidos/1']:not([target])", text: "Mesmo site"
    assert_selector "a[href='https://fora.com/x']:not([target])", text: "Forçado"
  end

  test "sino: singular no nome lido e no valor do JS" do
    render_inline(Ss::NotificationBellComponent.new(count: 1))
    assert_selector "button.ss-bell-btn[aria-label='Avisos, 1 não lido']"
    assert_selector "[data-ss-bell-unread-one-value='Avisos, 1 não lido']"
    render_inline(Ss::NotificationBellComponent.new(count: 3))
    assert_selector "button.ss-bell-btn[aria-label='Avisos, 3 não lidos']"
    I18n.with_locale(:es) do
      render_inline(Ss::NotificationBellComponent.new(count: 1))
      assert_selector "button.ss-bell-btn[aria-label='Avisos, 1 sin leer']"
    end
  end
end
