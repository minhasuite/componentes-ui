# Gera as <section> do catálogo (rails/catalogo/index.html) para as peças da v0.19.
#   bin/rails runner script/catalogo_v019.rb > /tmp/v019.html
include ComponentesUi::Helpers
require "action_dispatch/testing/test_request"
CTRL = ApplicationController.new.tap { |c| c.request = ActionDispatch::TestRequest.create("PATH_INFO" => "/vitrine/x"); c.response = ActionDispatch::Response.new }
def view = (@view ||= CTRL.view_context)
def r(c, &blk) = view.render(c, &blk).to_s.gsub(/<!-- (BEGIN|END) [^>]*-->/, "").gsub(/\n\s*/, "")
def esc(s) = ERB::Util.h(s)
def section(slug, nome, desc, comps, estados)
  out = +%(<section data-comp="#{slug}" data-nome="#{esc(nome)}" data-descricao="#{esc(desc)}"\n  data-comportamentos='#{esc(comps.to_json)}'>\n)
  estados.each { |(s, t, html)| out << %(  <div data-estado="#{s}" data-titulo="#{esc(t)}">#{html}</div>\n) }
  out << "</section>\n"
end
row = ->(*cs) { %(<div style="display:flex;flex-wrap:wrap;gap:8px;align-items:center">#{cs.join}</div>) }
out = +""
out << section("ss-button", "Ss::ButtonComponent", "O .ss-btn como componente (v0.19, par do SsButton): link, botão do JS, envio do formulário e button_to.",
  ["href: vira <a>; sem href, <button type=button> (ação pelo data-action) ou type: :submit com name/value/formaction.", "method: :post/:patch/:delete vira button_to (form com o token); confirm: abre a confirmação da suíte (data-turbo-confirm, confirm_tone:, confirm_button:).",
   "Variantes: primary, outline, ghost, danger, on_grad (sobre o gradiente), chip (ficha) e item (linha de menu; tone: :danger).", "submitting: põe data-turbo-submits-with (texto enquanto envia); block: true = largura toda."],
  [["variantes", "primary · outline · ghost · danger", row.(r(Ss::ButtonComponent.new(label: "Novo", icon: "plus", href: "#")), r(Ss::ButtonComponent.new(label: "Ler", variant: :outline)), r(Ss::ButtonComponent.new(label: "Cancelar", variant: :ghost)), r(Ss::ButtonComponent.new(label: "Remover", icon: "trash", variant: :danger, size: :sm)))],
   ["fichas", "chip · item de menu", row.(r(Ss::ButtonComponent.new(label: "Hoje", variant: :chip)), r(Ss::ButtonComponent.new(label: "Ontem", variant: :chip)), %(<div class="ss-card" style="width:220px;padding:4px">#{r(Ss::ButtonComponent.new(label: "Editar", variant: :item))}#{r(Ss::ButtonComponent.new(label: "Remover", variant: :item, tone: :danger))}</div>))],
   ["sobre-grad", "sobre o gradiente", %(<div class="bg-grad" style="padding:16px;border-radius:16px;width:280px">#{r(Ss::ButtonComponent.new(label: "Novo lançamento", icon: "plus", variant: :on_grad, size: :sm))}</div>)]])
out << section("ss-google-btn", "Ss::GoogleButtonComponent", "Entrar com o Google (v0.19, par do SsGoogleButton): o G de quatro cores e o POST sem Turbo para o OmniAuth.",
  ["POST com o token (omniauth-rails_csrf_protection); method: :get vira link.", "data-turbo=false: o OmniAuth redireciona para fora.", "Largura toda; as cores do G são da marca Google e ficam no SVG da gem."],
  [["padrao", "padrão", %(<div style="width:340px">#{r(Ss::GoogleButtonComponent.new(href: "#", method: :get))}</div>)]])
out << section("ss-wallet-card", "Ss::WalletCardComponent", "Cartão físico (v0.19, par do SsWalletCard): chip, bandeira, final, nome e valor no gradiente.",
  ["Inclina até ~6° seguindo o mouse e o brilho acompanha (ss-tilt); nada no toque nem com reduzir movimento.", "colors: as cores do cartão/bandeira (dado, inline como variável); sem ele, o gradiente da marca.",
   "href: o cartão vira link; o valor é borrado no modo privacidade."],
  [["marca", "cores da marca", %(<div style="width:300px">#{r(Ss::WalletCardComponent.new(amount: "R$ 1.234,56", label: "Fatura", holder: "Nubank Roxinho", number: "4086", network: "visa", tilt: false))}</div>)],
   ["cores", "cores do cartão", %(<div style="width:300px">#{r(Ss::WalletCardComponent.new(amount: "R$ 89,90", label: "Fatura", holder: "Inter", number: "1123", network: "elo", colors: ["#1f1b2e", "#eb5e28"], tilt: false))}</div>)]])
form = view.ss_form_with(url: "#", scope: :cat19) { |f| f.ss_file_field(:arquivo, label: "Extrato (CSV, OFX)") + f.ss_color_field(:cor, label: "Cor", value: "#0ea5e9") }.to_s.gsub(/\n\s*/, "")
out << section("ss-file-color", "f.ss_file_field · f.ss_color_field", "Campos de arquivo e de cor no ss_form_with (v0.19).",
  ["O botão do arquivo é uma pílula na linha do campo; accept:/multiple: passam ao input.", "A cor abre o seletor do navegador e mostra a amostra arredondada no desenho do campo."],
  [["campos", "arquivo e cor", %(<div style="width:360px" class="ss-card ss-card-pad">#{form}</div>)]])
dias = (1..30).map(&:to_s)
rec = Array.new(30) { |i| [5, 18].include?(i) ? 4200 : (i % 7).zero? ? 300 : 0 }
des = Array.new(30) { |i| -[120, 0, 80, 0, 260, 40, 0][i % 7] }
acc = rec.zip(des).each_with_object([]) { |(r, d), a| a << (a.last || 0) + r + d }
out << section("ss-barc-width", "Ss::BarChartComponent(width:, label_every:)", "Barras num card largo (v0.19): a largura do desenho e os rótulos do eixo X de N em N quando não cabem.",
  ["width: é a largura do viewBox (padrão 560): num card largo, a largura de verdade evita o texto gigante; no celular, outro com o padrão.", "Com muitos grupos, os rótulos saem de N em N (automático; o ativo sempre aparece); label_every: força o N."],
  [["mes", "30 dias com o saldo acumulado", %(<div style="width:560px">#{r(Ss::BarChartComponent.new(title: "Fluxo do mês", labels: dias, series: [{ name: "Receitas", values: rec, tone: :success }, { name: "Despesas", values: des, tone: :danger }], line: { name: "Saldo acumulado", values: acc, tone: :accent }, active: 9))}</div>)]])
print out
