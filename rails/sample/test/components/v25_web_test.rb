require "test_helper"

# v0.25 · auditoria de UX de novembro, rodada 5 (minhas-vendas, onda 2: Configurações › Vendas e preços em 390 px).
# Cada teste reproduz o achado: falha na v0.24.0 e passa com a correção.
class V25WebTest < ComponentTest
  CSS = Pathname(ComponentesUi::Engine.root).join("app/assets/tailwind/componentes_ui")
  LONGO = "Avançado: kit, margem e vencimento do lote que não vai vender a tempo"

  test "Collapsible: o título inteiro fica no title= (quando corta em 2 linhas ainda dá para ler)" do
    render_inline(Ss::CollapsibleComponent.new(title: LONGO, count: 3, label: "2 vencendo", tone: :warn))
    assert_selector "summary.ss-collapse-head .ss-collapse-title[title='#{LONGO}']", text: LONGO
  end

  test "Collapsible: o título quebra linha (até 2, depois reticências) e o grupo não alarga a página" do
    css = CSS.join("v25_web.css").read
    # O título quebra em vez de ficar numa linha só (nowrap: a largura mínima do grupo era o título inteiro e,
    # dentro de grid/flex, empurrava a página para 735 px num celular de 390).
    assert_match(/\.ss-collapse-title \{[^}]*white-space: normal;[^}]*overflow-wrap: anywhere;[^}]*-webkit-line-clamp: 2;/m, css)
    assert_match(/\.ss-collapse-title \{[^}]*flex: 0 1 auto;[^}]*min-width: 0;/m, css)
    # O grupo cabe no pai mesmo como item de flex/grid.
    assert_match(/\.ss-collapse \{[^}]*min-width: 0;[^}]*max-width: 100%;/m, css)
    # Seta, contagem e selo não encolhem nem quebram.
    assert_match(/\.ss-collapse-head > :is\(\.ss-collapse-chev, \.ss-collapse-ico, \.ss-collapse-count, \.ss-collapse-label\) \{[^}]*flex: none;[^}]*white-space: nowrap;/m, css)
    assert_includes CSS.join("engine.css").read, %(@import "./v25_web.css";)
  end
end
