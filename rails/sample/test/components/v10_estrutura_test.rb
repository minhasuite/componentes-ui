require "test_helper"

# v0.10 (estrutura): seletor de ícone, seletor de idioma, lista de blocos e grupo recolhível.
class V10EstruturaTest < ComponentTest
  SVG = '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="5"/></svg>'.freeze

  test "seletor de ícone: hidden com o nome, radiogroup, busca e nenhum" do
    render_inline(Ss::IconPickerComponent.new(name: "ponto[icone]", value: "lightbulb", allow_none: true,
                                              icons: [["lightbulb", SVG], ["ar-condicionado", SVG]]))
    assert_selector ".ss-iconpick[data-controller=ss-icon-picker] input[type=hidden][name='ponto[icone]'][value=lightbulb]", visible: :all
    assert_selector "[role=radiogroup] button[role=radio]", count: 3
    assert_selector "button[role=radio][aria-checked=true][data-name=lightbulb][tabindex='0'] svg"
    assert_selector "button.is-none[aria-checked=false][aria-label='Sem ícone']"
    assert_selector "button[data-name='ar-condicionado'][data-search='ar condicionado']"
    assert_selector "input[type=search][placeholder='Buscar ícone'][data-action='input->ss-icon-picker#filter']"
    assert_selector "p.ss-iconpick-empty[hidden][data-template='Nenhum ícone com “%{q}”']", visible: :all
    assert_equal "ar condicionado", Ss::IconPickerComponent.normalize("Ar_Condicionádo")

    render_inline(Ss::IconPickerComponent.new(name: "i", icons: [["a", SVG], ["b", SVG]]))
    assert_no_selector "button.is-none"
    assert_selector "button[data-name=a][tabindex='0']"
    assert_selector "button[aria-checked=true]", count: 0
  end

  test "seletor de idioma: rádios no form, button_to com url e segmented" do
    render_inline(Ss::LocalePickerComponent.new(value: "en", name: "user[locale]", flags: false))
    assert_selector ".ss-loc.ss-card[role=radiogroup][aria-label=Idioma] input[type=radio][name='user[locale]']", count: 3, visible: :all
    assert_selector "input[value=en][checked]", visible: :all
    assert_selector ".ss-loc-name[lang=es]", text: "Español"
    assert_selector ".ss-loc-badge.is-code", text: "PT"
    render_inline(Ss::LocalePickerComponent.new(value: "pt-BR", url: "/idioma", segmented: true))
    assert_selector ".ss-loc.is-segmented[role=group] form[action='/idioma'] input[name=locale][value=es]", visible: :all
    assert_selector "button.ss-loc-opt[aria-current=true]", text: "Português"
    assert_selector ".ss-loc-badge", text: "🇧🇷"
  end

  test "seletor de idioma v0.10.1: seguir o sistema (valor vazio) primeiro" do
    render_inline(Ss::LocalePickerComponent.new(value: nil, name: "user[locale]", system_option: true))
    assert_selector "input[type=radio][name='user[locale]']", count: 4, visible: :all
    first = page.all("input[type=radio]", visible: :all).first
    assert_equal "", first["value"].to_s
    assert first.checked?
    assert_selector ".ss-loc-opt:first-child .ss-loc-badge.is-system svg"
    assert_selector ".ss-loc-name", text: "Seguir o sistema"
    render_inline(Ss::LocalePickerComponent.new(value: "es", name: "l", system_option: true))
    assert_selector "input[value=es][checked]", visible: :all
    assert_no_selector "input#ss-loc-l-system[checked]", visible: :all
    render_inline(Ss::LocalePickerComponent.new(value: "", url: "/idioma", system_option: true, system_label: "Automático"))
    assert_selector "form[action='/idioma'] input[name=locale][value='']", visible: :all
    assert_selector "button.ss-loc-opt[aria-current=true]", text: "Automático"
    I18n.with_locale(:en) do
      render_inline(Ss::LocalePickerComponent.new(value: nil, name: "l", system_option: true))
      assert_selector ".ss-loc-name", text: "Follow system"
    end
    render_inline(Ss::LocalePickerComponent.new(value: nil, name: "l"))
    assert_selector "input[type=radio]", count: 3, visible: :all
    assert_no_selector "input[checked]", visible: :all
  end

  test "lista de blocos: details, posição, chave, menu, erro, foco e aninhada" do
    render_inline(Ss::BlockListComponent.new(name: "auto[passos]")) do |l|
      l.with_block(id: "g1", title: "Quando", summary: "A porta abrir", tone: :warn, open: true) { "CORPO" }
      l.with_block(id: "a1", title: "Avisar", error: "Escolha para quem avisar.", focused: true, delete_url: "/passos/a1")
      l.with_block(id: "m1", title: "Música", enabled: false) do
        render_inline(Ss::BlockListComponent.new(name: "auto[filhos]")) { |i| i.with_block(id: "f1", title: "Filho") }.to_html.html_safe
      end
    end
    assert_selector ".ss-blocks[data-controller=ss-block-list] > ol.ss-blocks-list > li.ss-blk", count: 3
    assert_selector "li.ss-blk[data-id=g1][data-tone=warn] details.ss-blk-d[open] .ss-blk-body", text: "CORPO"
    assert_selector "li[data-id=g1] input[type=hidden][name='auto[passos][g1][position]'][value='0']", visible: :all
    assert_selector "li[data-id=a1] input[name='auto[passos][a1][position]'][value='1']", visible: :all
    assert_selector "li[data-id=g1] .ss-blk-tools input[role=switch][name='auto[passos][g1][enabled]'][checked]"
    assert_selector "li.ss-blk.is-invalid.is-focused[aria-invalid=true] .ss-blk-error[role=alert]", text: "Escolha para quem avisar."
    assert_selector "li[data-id=a1] a.ss-blk-mi.is-danger[href='/passos/a1'][data-turbo-method=delete]", text: "Excluir", visible: :all
    assert_selector "li[data-id=g1] button.ss-blk-mi[data-action='ss-block-list#moveUp'][data-move=up]", visible: :all
    assert_selector "li[data-id=g1] button.ss-blk-mi[data-action='ss-block-list#delete']", visible: :all
    assert_selector "li.ss-blk.is-off[data-id=m1]"
    assert_no_selector "li[data-id=m1] input[role=switch][checked]"
    assert_selector "li[data-id=m1] .ss-blk-body .ss-blocks li.ss-blk[data-id=f1]", visible: :all
    assert_selector "p.ss-sr[role=status][data-ss-block-list-target=live]", visible: :all
  end

  test "grupo recolhível: details, contagem, selo com tom" do
    render_inline(Ss::CollapsibleComponent.new(title: "Sala", count: 3, label: "2 ligados", tone: :success, open: true)) { "DENTRO" }
    assert_selector "details.ss-collapse[open] > summary.ss-collapse-head .ss-collapse-title", text: "Sala"
    assert_selector ".ss-collapse-count", text: "3"
    assert_selector ".ss-collapse-label[data-tone=success]", text: "2 ligados"
    assert_selector ".ss-collapse-body", text: "DENTRO"
    render_inline(Ss::CollapsibleComponent.new(title: "Garagem")) { "X" }
    assert_selector "details.ss-collapse:not([open])"
    assert_no_selector ".ss-collapse-count"
  end
end
