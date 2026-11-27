require "test_helper"

# v1.14.1: o subtítulo do item da paleta (par do SsCommand(subtitle:)), o align: dos f.ss_* (par do
# SsTextField(textAlign:)) e a saída dos testes de produto que o odômetro do KPI da v1.14.0 deixou frágeis.
class V1141WebTest < ComponentTest
  ROOT = Pathname(ComponentesUi::Engine.root)
  CSS = ROOT.join("app/assets/tailwind/componentes_ui")

  class Item
    include ActiveModel::Model
    include ActiveModel::Attributes
    def self.model_name = ActiveModel::Name.new(self, nil, "Item")
    attribute :qtd, :integer
    attribute :nome, :string
  end

  def form(&block)
    view = vc_test_controller.view_context
    Capybara.string(view.ss_form_with(model: Item.new(qtd: 12, nome: "Café"), url: "/itens", &block))
  end

  test "versão 1.14.1" do
    assert_equal "1.14.1", ComponentesUi::VERSION
  end

  # ── 1. subtítulo do comando ─────────────────────────────────────────
  test "CommandPalette: o subtítulo é a 2ª linha, entra na busca e no nome lido do item" do
    render_inline(Ss::CommandPaletteComponent.new(id: "casa", groups: [
      { title: "Aparelhos", items: [{ label: "Luz do teto", subtitle: "Quarto", url: "/a/1" },
                                    { label: "Luz do teto", subtitle: "Sala", url: "/a/2", keywords: "lampada", hint: "Ligada" },
                                    { label: "Configurações", url: "/c" }] }
    ]))
    item = page.find("a.ss-command-item[href='/a/1'][role=option]")
    assert_equal "Luz do teto", item["data-text"]
    assert_equal "Quarto", item["data-keywords"]
    assert item.has_css?(".ss-command-text [data-ss-command-label]", text: "Luz do teto")
    assert item.has_css?(".ss-command-text .ss-command-sub", text: "Quarto")
    # O nome lido: as duas linhas com vírgula (o conteúdo sairia colado, "Luz do tetoQuarto").
    assert_equal "Luz do teto, Quarto", item["aria-label"]
    assert_equal "lampada Sala", page.find("a[href='/a/2']")["data-keywords"]
    assert_equal "Luz do teto, Sala, Ligada", page.find("a[href='/a/2']")["aria-label"]
    assert_selector "a[href='/c']:not([data-keywords]):not([aria-label]) > [data-ss-command-label]", text: "Configurações"
    assert_no_selector "a[href='/c'] .ss-command-sub"
  end

  # ── 2. alinhamento do campo ─────────────────────────────────────────
  test "f.ss_*(align: :end) põe .ss-input-end no input; padrão sem classe; valor errado avisa" do
    f = form do |b|
      b.ss_number_field(:qtd, label: "Quantidade", align: :end, suffix: "un") +
        b.ss_text_field(:nome, label: "Nome") + b.ss_text_field(:nome, id: "n2", align: "center")
    end
    assert f.has_css?(".ss-field .ss-affix input.ss-input.ss-input-end[type=number][value='12']")
    assert f.has_css?("input#item_nome.ss-input:not(.ss-input-end):not(.ss-input-center)")
    assert f.has_css?("input#n2.ss-input.ss-input-center")
    assert_raises(ArgumentError) { form { |b| b.ss_text_field(:nome, align: :right) } }
  end

  test "CSS: .ss-input-end/-center no v1141_web.css, importado pelo engine.css; o dinheiro já à direita" do
    assert_includes CSS.join("engine.css").read, '@import "./v1141_web.css";'
    css = CSS.join("v1141_web.css").read
    assert_includes css, ".ss-input.ss-input-end { text-align: end; }"
    assert_includes css, ".ss-input.ss-input-center { text-align: center; }"
    assert_match(/\.ss-money \{[^}]*text-align: right/, CSS.join("engine.css").read)
  end

  # ── 3. a saída dos testes de produto ────────────────────────────────
  test "KPI com odômetro: o valor fica no data-ss-odometer-text-value e no .ss-sr; animate: false é o texto" do
    render_inline(Ss::KpiCardComponent.new(label: "Receita", value: "R$ 4.870,00", money: true))
    # O que o teste do produto procura em vez do texto corrido (os dígitos são colunas 0–9):
    assert_selector "[data-ss-odometer-text-value='R$ 4.870,00']"
    assert_selector ".ss-kpi-card-value .ss-sr", text: "R$ 4.870,00"
    refute_equal "R$ 4.870,00", page.find(".ss-kpi-card-value").text.squish
    render_inline(Ss::KpiCardComponent.new(label: "Receita", value: "R$ 4.870,00", money: true, animate: false))
    assert_equal "R$ 4.870,00", page.find(".ss-kpi-card-value").text.squish
  end
end
