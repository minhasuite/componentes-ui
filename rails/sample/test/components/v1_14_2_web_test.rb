require "test_helper"

# v1.14.2: as arquivadas e o desfazer do arquivar no Ss::NotificationCenterComponent (par do
# SsNotificationCenter(loadArchived:, unarchive:)) e a origem do logo do Ss::AppleButtonComponent.
class V1142WebTest < ComponentTest
  ROOT = Pathname(ComponentesUi::Engine.root)
  REPO = ROOT.join("..")
  NOW = Time.utc(2026, 11, 24, 15)

  def avisos(**extra)
    [{ id: 1, title: "Orçamento aprovado", at: Time.utc(2026, 11, 24, 14, 32), unread: true, archive_href: "/avisos/1/arquivar",
       read_href: "/avisos/1/lido", **extra },
     { id: 2, title: "Resumo do dia", at: Time.utc(2026, 11, 23, 19), unread: false, archive_href: "/avisos/2/arquivar", **extra }]
  end

  test "versão 1.14.2" do
    assert_equal "1.14.2", ComponentesUi::VERSION
    assert_includes REPO.join("flutter/pubspec.yaml").read, "version: 1.14.2"
    assert_includes REPO.join("README.md").read, "ref: v1.14.2"
  end

  # ── abas ─────────────────────────────────────────────────────────────
  test "sem archived_url não há abas (como antes)" do
    render_inline(Ss::NotificationCenterComponent.new(items: avisos, now: NOW))
    assert_no_selector ".ss-ncenter-tabs"
    assert_selector ".ss-ncenter-count", text: "1 não lida"
  end

  test "com archived_url: Caixa de entrada | Arquivadas, a caixa de entrada atual" do
    render_inline(Ss::NotificationCenterComponent.new(items: avisos, now: NOW, archived_url: "/avisos?arquivadas=1", inbox_url: "/avisos"))
    tabs = page.find(".ss-ncenter-tabs .ss-seg")
    assert tabs.has_css?("a[href='/avisos'][aria-current=true]", text: "Caixa de entrada")
    assert tabs.has_css?("a[href='/avisos?arquivadas=1']:not([aria-current])", text: "Arquivadas")
    assert_selector ".ss-ncenter-count", text: "1 não lida"
    assert_selector "form[action='/avisos/1/arquivar']"
  end

  test "archived: true: sem contagem, sem ponto, Desarquivar por aviso e a aba Arquivadas atual" do
    itens = avisos.each_with_index.map { |a, i| a.merge(unarchive_href: "/avisos/#{i + 1}/desarquivar") }
    itens[1] = itens[1].except(:unarchive_href).merge(unarchive_url: "/avisos/2/desarquivar")
    render_inline(Ss::NotificationCenterComponent.new(items: itens, now: NOW, archived: true, unread_count: 7,
                                                      archived_url: "/avisos?arquivadas=1", inbox_url: "/avisos"))
    assert_selector ".ss-ncenter-tabs a[href='/avisos?arquivadas=1'][aria-current=true]", text: "Arquivadas"
    assert_no_selector ".ss-ncenter-head"
    assert_no_selector ".ss-ncenter-item.is-unread"
    assert_no_selector ".ss-ncenter-dot"
    assert_no_selector "form[action$='/arquivar']"
    assert_no_selector "form[action$='/lido']"
    assert_selector "form[action='/avisos/1/desarquivar'] button[aria-label='Desarquivar']"
    assert_selector "form[action='/avisos/2/desarquivar'] button[aria-label='Desarquivar']"
    assert_selector "form[action='/avisos/1/desarquivar'] input[name=_method][value=patch]", visible: :all
  end

  test "archived: true vazio: o vazio próprio, com as abas para voltar" do
    render_inline(Ss::NotificationCenterComponent.new(items: [], archived: true, archived_url: "/a?x=1", inbox_url: "/a"))
    assert_selector ".ss-ncenter-tabs a[href='/a']", text: "Caixa de entrada"
    assert_text "Nenhuma notificação arquivada"
    assert_text "O que você arquivar fica aqui, fora da caixa de entrada."
  end

  test "textos em en e es" do
    { en: ["Inbox", "Archived", "Unarchive", "No archived notifications"],
      es: ["Bandeja de entrada", "Archivadas", "Desarchivar", "Ninguna notificación archivada"] }.each do |loc, (caixa, arq, desarq, vazio)|
      I18n.with_locale(loc) do
        render_inline(Ss::NotificationCenterComponent.new(items: [{ id: 1, title: "x", unarchive_href: "/u" }], archived: true,
                                                          archived_url: "/a?x=1", inbox_url: "/a"))
        assert_selector ".ss-seg a", text: caixa
        assert_selector ".ss-seg a", text: arq
        assert_selector "button[aria-label='#{desarq}']"
        render_inline(Ss::NotificationCenterComponent.new(items: [], archived: true))
        assert_text vazio
      end
    end
  end

  # ── desfazer ─────────────────────────────────────────────────────────
  test "archive_undo: o aviso vira ss-undoable e o Arquivar espera o desfazer" do
    render_inline(Ss::NotificationCenterComponent.new(items: avisos, now: NOW, archive_undo: true))
    li = page.find("li#ss-ncenter-item-1")
    assert_includes li[:class], "ss-undoable"
    assert_equal "ss-undoable", li["data-controller"]
    assert_equal "Notificação arquivada", li["data-ss-undoable-message-value"]
    assert_equal "Desfazer", li["data-ss-undoable-label-value"]
    form = li.find("form[action='/avisos/1/arquivar']")
    assert_includes form["data-action"], "submit->ss-undoable#remove"
    assert_equal "_top", form["data-turbo-frame"]
    # Marcar como lida continua direto.
    refute_includes li.find("form[action='/avisos/1/lido']")["data-action"].to_s, "ss-undoable"
  end

  test "sem archive_undo, o Arquivar fica como antes" do
    render_inline(Ss::NotificationCenterComponent.new(items: avisos, now: NOW))
    assert_no_selector "[data-controller=ss-undoable]"
    refute_includes page.find("form[action='/avisos/1/arquivar']")["data-action"].to_s, "ss-undoable"
  end

  test "archive_undo não vale nas arquivadas" do
    render_inline(Ss::NotificationCenterComponent.new(items: avisos(unarchive_href: "/u"), archived: true, archive_undo: true))
    assert_no_selector "[data-controller=ss-undoable]"
  end

  test "CSS das abas importado" do
    css = ROOT.join("app/assets/tailwind/componentes_ui")
    assert_includes css.join("engine.css").read, '@import "./v1142_web.css";'
    assert_includes css.join("v1142_web.css").read, ".ss-ncenter-tabs"
  end

  # ── Apple ────────────────────────────────────────────────────────────
  test "AppleButton: o logo continua o do Simple Icons, com a origem escrita" do
    src = ROOT.join("app/components/ss/apple_button_component.rb").read
    assert_includes src, "Simple Icons"
    assert_includes src, "Apple Design Resources License"
  end
end
