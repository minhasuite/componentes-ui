# Gera as <section> do catálogo (rails/catalogo/index.html) para a v0.24 (auditoria de UX).
#   bin/rails runner script/catalogo_v024.rb > /tmp/v024.html
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
def box(w, html) = %(<div style="width:#{w}px">#{html}</div>)

linhas = [{ id: 1, numero: "#2904", cliente: "Sabor Caseiro Restaurante", emissao: "14/11/2026", status: "Aguarda", total: 2380.0 },
          { id: 2, numero: "#2903", cliente: "Consumidor final", emissao: "14/11/2026", status: "Entregue", total: 22.87 }]
tabela = r(Ss::DataTableComponent.new(rows: linhas, id: "cat-compacta", caption: "Pedidos", mobile: :compact, tools: false, row_href: ->(l) { "#p#{l[:id]}" })) do |t|
  t.column :numero, "Nº", mobile: :meta
  t.column :cliente, "Cliente", mobile: :title
  t.column :emissao, "Emissão", mobile: :meta
  t.column(:status, "Situação", mobile: :badge) { |l| view.tag.span(l[:status], class: "ss-badge ss-badge-#{l[:status] == "Entregue" ? "success" : "warning"}") }
  t.column :total, "Total", format: :money, mobile: :value
end
out = +""
out << section("ss-data-table-compact", "DataTableComponent(mobile: :compact)",
  "Linha compacta no celular (v0.24, par do SsDataTable(mobile: SsDataTableMobile.compact)): título e valor em cima, meta e selo embaixo, no lugar do cartão RÓTULO valor.",
  ["t.column(..., mobile: :title | :value | :meta | :badge | :hide); sem papel, a 1ª coluna é o título, a 1ª de dinheiro o valor e o resto meta.",
   "Abaixo de 640 px: uma lista num card só, linhas separadas por fio; as metas ficam numa linha com ·; o selo vai à direita.",
   "Seleção e seta da expansão antes do título; ações da linha no fim da 2ª linha; o total vira a última linha (\"Total ……… valor\").",
   "No computador nada muda; stack: false vence (a tabela rola de lado)."],
  [["celular", "pedidos em 360px", box(360, tabela)]])

form = view.ss_form_with(url: "#", class: "grid gap-3 md:grid-cols-2") do |f|
  view.safe_join([f.ss_text_field(:nome, label: "Nome", required: true), f.ss_text_field(:cnpj, label: "CNPJ"),
                  view.tag.div(f.ss_submit("Salvar empresa"), class: "ss-actions")])
end
out << section("ss-actions-v24", ".ss-actions (v0.24)",
  "Barra de salvar dos formulários longos: faixa opaca de largura inteira presa embaixo só enquanto o formulário está na tela (antes uma pílula translúcida que flutuava sobre o rótulo do campo).",
  ["position: sticky dentro do próprio form; ocupa a grade inteira (grid-column: 1 / -1).",
   "O campo em foco (Tab, envio com erro, âncora) para acima da barra: scroll-padding-bottom na página e scroll-margin nos campos (--ss-bar-room).",
   "O ss_form_with liga o ss-validate (v0.24): sem o balão nativo ao passar o mouse; a mensagem vai embaixo do campo ao sair dele e ao enviar."],
  [["form", "formulário com a barra", box(520, form)]])

config = r(Ss::SettingsLayoutComponent.new(title: "Configurações")) do |s|
  s.with_section(id: "cat-empresa", title: "Empresa", form: { url: "#", scope: :empresa }, save_label: "Salvar empresa", save_always: true) do |sec|
    sec.form.ss_text_field(:nome, label: "Nome", value: "Mercado Bom")
  end
  s.with_section(id: "cat-precos", title: "Preços", form: { url: "#", scope: :precos }) { |sec| sec.form.ss_number_field(:margem, label: "Margem alvo (%)") }
end
paginas = r(Ss::SettingsLayoutComponent.new(title: "Configurações")) do |s|
  s.with_section(id: "cat-p-empresa", title: "Empresa", href: "#empresa", current: true) { view.tag.p("Os campos da empresa.") }
  s.with_section(id: "cat-p-equipe", title: "Equipe", href: "#equipe")
end
out << section("ss-settings-v24", "SettingsLayoutComponent(form:, href:)",
  "Configurações com salvar por área (v0.24): cada seção pode ser um formulário com o próprio Salvar, ou as áreas viram páginas (o menu navega).",
  ["form: { model:, url: } na seção: ss_form_with com o ss-validate e uma Ss::StickyActionBarComponent que só aparece quando aquela área muda (save_label:, save_always:). Campos pelo sec.form.",
   "href: (+ current: na atual): o menu leva à URL da área (aria-current=page), sem scrollspy, e só a seção atual aparece.",
   "Sem form:/href:, igual à v0.9 (âncoras com scrollspy)."],
  [["por-area", "área Empresa com o Salvar dela", box(720, config)], ["paginas", "áreas em páginas", box(720, paginas)]])

def shell(tenants) = r(Ss::AppShellComponent.new(brand: "Meu Gestor", tenants:, search: false)) { "" }[/<aside.*?<\/aside>/m]
out << section("ss-shell-tenant", "AppShellComponent: troca de empresa (v0.24)",
  "A troca de empresa só vira menu com 2 ou mais empresas; com uma, o nome fica parado. Nome longo com reticências e o nome inteiro no title=.",
  ["tenants: com 1 item = .ss-shell-tenant.is-single (sem seta, sem menu); single_tenant: false esconde.",
   "Com 2+: o <details> de sempre; o nome num .ss-shell-tenant-name que corta com …"],
  [["uma", "uma empresa, nome longo", box(260, shell([{ name: "Atacadão Teste do Nordeste Ltda", current: true }]))],
   ["duas", "duas empresas", box(260, shell([{ name: "Atacadão Teste do Nordeste Ltda", href: "#", current: true }, { name: "Mercado Novo", href: "#" }]))]])

out << section("ss-ai-card-v24", "AiInsightCardComponent(thinking:, cancel:)",
  "A espera da IA dentro do cartão com Cancelar (v0.24, par do SsAiInsightCard): a tela segue livre.",
  ["cancel: { label:, url:, method: } ou { label:, data: { action: } } põe Cancelar na espera.",
   "thinking_hint: (padrão \"Pode continuar usando a tela.\"; \"\" tira)."],
  [["pensando", "lendo, com Cancelar", box(360, r(Ss::AiInsightCardComponent.new(thinking: true, thinking_text: "A IA está lendo a sugestão.", cancel: { data: { action: "ia#parar" } })))]])
print out
