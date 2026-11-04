require "test_helper"

# v0.10 · estrutura do web: página com voltar/selo, moldura com search_action,
# confirmação global, paginação, paleta de comandos e cor livre.
class V10WebTest < ComponentTest
  test "página: voltar antes do título e selo ao lado" do
    render_inline(Ss::PageComponent.new(title: "Sala", back: "/comodos")) do |p|
      p.with_badge { "<span class='ss-badge'>Online</span>".html_safe }
      "corpo"
    end
    assert_selector "a.ss-page-back[href='/comodos']", text: "Voltar"
    assert_selector ".ss-page-titlerow h1.ss-page-title", text: "Sala"
    assert_selector ".ss-page-titlerow .ss-badge", text: "Online"
  end

  test "página sem back nem selo continua igual" do
    render_inline(Ss::PageComponent.new(title: "Pedidos")) { "corpo" }
    assert_no_selector ".ss-page-back"
    assert_no_selector ".ss-page-titlerow"
    assert_selector ".ss-page-titles > h1.ss-page-title", text: "Pedidos"
  end

  test "página: back_label troca e o idioma muda o padrão" do
    render_inline(Ss::PageComponent.new(title: "X", back: "/", back_label: "Início")) { "" }
    assert_selector ".ss-page-back", text: "Início"
    I18n.with_locale(:en) { render_inline(Ss::PageComponent.new(title: "X", back: "/")) { "" } }
    assert_selector ".ss-page-back", text: "Back"
  end

  test "moldura: search_action liga a busca ao dialog e os rótulos vêm do idioma" do
    render_inline(Ss::AppShellComponent.new(brand: "Casa", nav: [], search: false, search_action: "busca")) { "x" }
    assert_selector ".ss-shell[data-ss-shell-search-action-value='busca']"
    assert_selector "button.ss-shell-search[aria-controls='busca']"
    assert_selector ".ss-shell-collapse[aria-label='Recolher menu']"
    I18n.with_locale(:es) { render_inline(Ss::AppShellComponent.new(brand: "Casa", nav: [])) { "x" } }
    assert_selector ".ss-shell-collapse[aria-label='Contraer menú']"
    assert_selector ".ss-shell[data-ss-shell-expand-label-value='Expandir menú']"
  end

  test "confirmação: diálogo global com tom, textos e botões" do
    render_inline Ss::ConfirmDialogComponent.new(id: "confirmar", tone: :danger, ok_label: "Excluir")
    assert_selector "dialog#confirmar.ss-dialog.is-danger[data-controller='ss-confirm-dialog'][data-ss-confirm-dialog-global-value='true']"
    assert_selector "dialog form[method='dialog'] button[value='ok']", text: "Excluir"
    assert_selector "button[value='cancel']", text: "Voltar"
    assert_selector "h2#confirmar-t", text: "Tem certeza?"
    I18n.with_locale(:en) { render_inline Ss::ConfirmDialogComponent.new(global: false) }
    assert_selector "dialog#ss-confirm-dialog[data-ss-confirm-dialog-global-value='false']"
    assert_selector "h2", text: "Are you sure?"
    assert_selector "button[value='cancel']", text: "Cancel"
  end

  test "paginação: janela com reticências, atual e anterior/próxima" do
    render_inline Ss::PaginationComponent.new(page: 5, pages: 12, url: ->(p) { "/l?page=#{p}" }, total: 230)
    assert_selector "nav.ss-dt-pager.ss-pagination[data-controller='ss-indicator']"
    assert_selector "a[aria-current='page']", text: "5"
    assert_selector "a.num", count: 5 # 1 4 5 6 12
    assert_selector ".ss-dt-gap", count: 2
    assert_selector "a[rel='prev'][href='/l?page=4']"
    assert_selector "a[rel='next'][href='/l?page=6']"
    assert_selector ".ss-dt-total", text: "230 itens"
  end

  test "paginação: params:, borda e página única" do
    render_inline Ss::PaginationComponent.new(page: 1, pages: 3, params: { "q" => "luz" })
    assert_selector "span[aria-disabled]", text: "‹"
    assert_selector "a[rel='next'][href='?page=2&q=luz']"
    render_inline Ss::PaginationComponent.new(page: 1, pages: 1, params: {})
    assert_no_selector "nav"
    I18n.with_locale(:en) { render_inline Ss::PaginationComponent.new(page: 2, pages: 3, params: {}, total: 1) }
    assert_selector "nav[aria-label='Pagination']"
    assert_selector "a[rel='prev'][aria-label='Previous page']"
    assert_selector ".ss-dt-total", text: "1 item"
  end

  test "paleta: grupos, itens, atalho e src" do
    svg = '<svg viewBox="0 0 24 24"></svg>'.html_safe
    render_inline Ss::CommandPaletteComponent.new(id: "busca", placeholder: "Buscar…", src: "/busca",
      groups: [{ title: "Cômodos", items: [{ label: "Sala", url: "/sala", icon: svg, hint: "6" }, { label: "Cozinha", url: "/cozinha" }] }])
    assert_selector "dialog#busca.ss-dialog.ss-command[data-controller='ss-command'][data-ss-command-shortcut-value='k'][data-ss-command-src-value='/busca']"
    assert_selector "input[type='search'][placeholder='Buscar…'][aria-controls='busca-list']"
    assert_selector ".ss-command-group-title", text: "Cômodos"
    assert_selector "a.ss-command-item[role='option'][href='/sala'][data-text='Sala'] svg"
    assert_selector "a.ss-command-item small", text: "6"
    assert_selector "[data-ss-command-target='remote']"
    assert_selector ".ss-command-empty[hidden]", text: "Nada encontrado", visible: :all
    render_inline Ss::CommandPaletteComponent.new(id: "b2", shortcut: nil, groups: [])
    assert_selector "dialog#b2[data-ss-command-shortcut-value='']"
    assert_no_selector ".ss-command-foot-k"
  end

  test "cor livre: ficha extra com input color, marcada quando o valor é hex fora das opções" do
    opts = [{ value: "azul", label: "Azul", color: "#2f6fdb" }]
    render_inline Ss::SwatchPickerComponent.new(name: "c", options: opts, selected: "#e0457b", free: true)
    assert_selector "label.is-free.is-set input[type='radio'][value='#e0457b'][checked]", visible: :all
    assert_selector "label.is-free input[type='color'][value='#e0457b']", visible: :all
    render_inline Ss::SwatchPickerComponent.new(name: "c", options: opts, selected: "azul", free: true)
    assert_selector "label.is-free input[type='radio'][value='#2f6fdb']:not([checked])", visible: :all
    render_inline Ss::SwatchPickerComponent.new(name: "c", options: opts)
    assert_no_selector "label.is-free"
  end
end
