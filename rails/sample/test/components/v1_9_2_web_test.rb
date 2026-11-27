require "test_helper"

# v1.9.2: aviso rico na Ss::NotificationCenterComponent (nível, foto, botões de resposta e "Silenciar"), o par do
# SsNotificationItem(level:, image:, actions:, onMute:) que a minha-automacao precisa para trocar a página feita à mão.
class V192WebTest < ComponentTest
  AGORA = Time.utc(2026, 11, 24, 15)

  def central(**item)
    render_inline(Ss::NotificationCenterComponent.new(id: "avisos", now: AGORA,
                                                      items: [{ id: 1, title: "Portão aberto", text: "Há 10 min", at: Time.utc(2026, 11, 24, 14), unread: true, **item }]))
  end

  test "sem os campos novos: igual a antes (sem nível, sem faixa de baixo)" do
    central
    assert_selector "li#avisos-item-1.ss-ncenter-item.is-unread"
    assert_no_selector ".ss-ncenter-item.has-extra, .ss-ncenter-extra, .ss-ncenter-level"
    assert_selector "li#avisos-item-1 .ss-icon-tile:not([class*='is-'])"
  end

  test "nível: crítico e aviso com tom, ícone e selo; info fica como antes" do
    central(level: :critical)
    assert_selector "li#avisos-item-1.is-critical .ss-icon-tile.is-danger"
    assert_selector "li#avisos-item-1 .ss-ncenter-level.ss-badge.ss-badge-danger", text: "Crítico"
    central(level: "warning")
    assert_selector "li#avisos-item-1.is-warning .ss-icon-tile.is-warn"
    assert_selector ".ss-ncenter-level.ss-badge-warning", text: "Aviso"
    central(level: :info)
    assert_no_selector ".ss-ncenter-level"
    assert_no_selector "li.is-info"
    # icon:/tone: passados ganham do nível.
    central(level: :critical, tone: :muted)
    assert_selector "li#avisos-item-1.is-critical .ss-icon-tile.is-muted"
  end

  test "foto, botões de resposta (o 1º cheio) e Silenciar com um botão" do
    central(image: "/snap/1.jpg", image_alt: "Câmera da garagem",
            actions: [{ label: "Fechar", href: "/avisos/1/responder", params: { action_id: "close" } },
                      { label: "Ignorar", href: "/avisos/1/responder", params: { action_id: "ignore" } },
                      { label: "Ver câmera", href: "/cameras/1", method: :get }],
            mute: { href: "/avisos/1/silenciar", params: { hours: 1 } })
    li = "li#avisos-item-1.has-extra .ss-ncenter-extra"
    assert_selector "#{li} img.ss-ncenter-img[src='/snap/1.jpg'][alt='Câmera da garagem'][loading=lazy]"
    assert_selector "#{li} .ss-ncenter-replies form[action='/avisos/1/responder'] input[name=_method][value=patch]", visible: :all, count: 2
    assert_selector "#{li} .ss-ncenter-replies form[action='/avisos/1/responder'] input[name=action_id][value=close]", visible: :all
    assert_selector "#{li} .ss-ncenter-replies button.ss-btn.ss-btn-sm:not(.ss-btn-ghost)", text: "Fechar"
    assert_selector "#{li} .ss-ncenter-replies button.ss-btn-ghost", text: "Ignorar"
    assert_selector "#{li} .ss-ncenter-replies a.ss-btn-ghost[href='/cameras/1']", text: "Ver câmera"
    assert_selector "#{li} .ss-ncenter-replies form[action='/avisos/1/silenciar'] button.ss-btn-ghost", text: "Silenciar"
  end

  test "Silenciar com opções vira menu" do
    central(mute: { label: "Silenciar a garagem", options: [{ label: "Por 1 hora", href: "/avisos/1/silenciar?hours=1" },
                                                            { label: "Por 8 horas", href: "/avisos/1/silenciar?hours=8" }] })
    assert_selector ".ss-ncenter-extra details.ss-menu.ss-ncenter-mute > summary.ss-menu-btn", text: "Silenciar a garagem"
    assert_selector ".ss-ncenter-mute-list form[action='/avisos/1/silenciar?hours=8'] button", text: "Por 8 horas", visible: :all
  end

  test "textos em inglês" do
    I18n.with_locale(:en) do
      central(level: :critical, mute: { href: "/m" })
      assert_selector ".ss-ncenter-level", text: "Critical"
      assert_selector ".ss-ncenter-replies button", text: "Mute"
    end
  end
end
