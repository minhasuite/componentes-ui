# Gera as <section> do catálogo (rails/catalogo/index.html) para as peças da v0.20.
#   bin/rails runner script/catalogo_v020.rb > /tmp/v020.html
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
box = ->(w, html) { %(<div style="width:#{w}px">#{html}</div>) }
out = +""

linhas = [{ id: 1, cliente: "Mercado Bom Preço", cidade: "Fortaleza", vendedor: "João", total: 1250.4, ativo: true },
          { id: 2, cliente: "Padaria Pão Quente", cidade: "Sobral", vendedor: "Maria", total: 380, ativo: false }]
tabela = r(Ss::DataTableComponent.new(rows: linhas, id: "cat-v20", caption: "Pedidos", tools: false, flat: true,
                                      row_href: ->(x) { "#p#{x[:id]}" }, row_attrs: ->(x) { { class: ("is-dimmed" unless x[:ativo]) } })) do |t|
  t.column :cliente, "Cliente", sticky: true
  t.column :cidade, "Cidade"
  t.column :vendedor, "Vendedor"
  t.column :total, "Total", format: :money
  t.total :total, view.ss_amount(view.ss_money(1630.4))
end
out << section("ss-data-table-v20", "Ss::DataTableComponent (v0.20)", "Tabela com linha-link, 1ª coluna parada, total no <tfoot>, linha apagada e sem card (pares do SsDataTable(stickyFirstColumn:, footer:, flat:)).",
  ["row_href: a linha vira link (clique fora de link/botão/campo, Enter com o foco; Ctrl/⌘ abre em outra aba).", "t.column(sticky: true): a 1ª coluna fica parada ao rolar de lado; header: troca o texto do cabeçalho por HTML.",
   "t.total(:col, valor) / t.footer { }: linha de total em negrito no fundo do campo; no celular vira um bloco no fim.", "flat: true tira a moldura de card; row_attrs com is-dimmed apaga a linha (opacidade .5)."],
  [["total", "total, linha apagada, sem card", %(<div class="ss-card ss-card-pad" style="width:620px">#{tabela}</div>)]])

form = view.ss_form_with(url: "#", scope: :cat20) do |f|
  f.ss_text_field(:doc, label: "CPF ou CNPJ", mask: :document, value: "11.222.333/0001-81") + f.ss_telephone_field(:fone, label: "Telefone", mask: :phone, value: "(85) 98765-4321") +
    f.ss_search_field(:busca, label: "Buscar", hide_label: true, placeholder: "Buscar cliente…") +
    f.ss_radio_buttons(:tipo, [["Pessoa física", "pf"], ["Empresa", "pj"]], label: "Tipo", checked: "pj")
end.to_s.gsub(/\n\s*/, "")
out << section("ss-form-v20", "f.ss_* (v0.20): mask:, hide_label:, checked:", "Máscara brasileira, rótulo escondido e rádio marcado sem model (pares do SsTextField(mask:, hideLabel:) e do SsRadioGroup(value:)).",
  ["mask: :document (CPF; com 12+ caracteres ou letra, CNPJ, inclusive o alfanumérico), :phone, :cep: o ss-mask formata enquanto digita e mantém o cursor.", "hide_label: o rótulo fica só para o leitor de tela (.ss-sr).",
   "f.ss_radio_buttons(checked:) marca a opção sem model; f.ss_check_box(id:) liga o rótulo ao id passado."],
  [["campos", "máscara, busca sem rótulo e rádio", box.(360, %(<div class="ss-card ss-card-pad">#{form}</div>))]])

out << section("ss-button-v20", "Ss::ButtonComponent(variant: :ghost, tone: :danger)", "Botão discreto de perigo (v0.20, par do SsButton.ghost(tone: SsTone.danger)).",
  ["Texto no vermelho da suíte; no hover, fundo de perigo suave.", "Também no :outline (contorno no tom)."],
  [["perigo", "ghost e outline de perigo", row.(r(Ss::ButtonComponent.new(label: "Excluir", icon: "trash", variant: :ghost, tone: :danger)), r(Ss::ButtonComponent.new(label: "Cancelar pedido", variant: :outline, tone: :danger)), r(Ss::ButtonComponent.new(label: "Voltar", variant: :ghost)))]])

itens = r(Ss::ListItemComponent.new(title: "Boleto 1234", subtitle: "Vence hoje", subtitle_tone: :danger, value: view.ss_money(120), icon: "document-text", tone: :danger, href: "#")) +
        r(Ss::ListItemComponent.new(title: "Boleto 1233", subtitle: "Pago", subtitle_tone: :success, value: view.ss_money(80), value_tone: :success, icon: "document-text", dimmed: true))
out << section("ss-list-item", "Ss::ListItemComponent", "O .ss-item como componente (v0.20, par do SsListItem): ícone tonal, título, subtítulo e valor em tom, link e linha apagada.",
  ["subtitle_tone:/value_tone: pintam o texto (danger, warn, success, accent, info, muted).", "href: vira <a> com hover; dimmed: apaga (concluído, arquivado).", "O bloco vai no fim (chevron, ações)."],
  [["tons", "vence hoje · pago", box.(360, %(<div class="ss-card ss-card-pad">#{itens}</div>))]])

out << section("ss-kpi-tone-v20", "KpiCardComponent(value_tone:) · CardHeaderComponent(eyebrow:)", "Valor do indicador em tom e sobrelinha no cabeçalho do card (v0.20, pares do SsKpiCard(valueTone:) e do SsCardHeader(eyebrow:)).",
  ["value_tone: :danger no saldo negativo, :success na meta batida.", "eyebrow: versalete pequena em cima do título; eyebrow_tone: pinta."],
  [["tons", "saldo negativo e sobrelinha", row.(box.(240, r(Ss::KpiCardComponent.new(label: "Saldo do caixa", value: view.ss_money(-1250), money: true, value_tone: :danger))),
                                              box.(260, %(<div class="ss-card ss-card-pad">#{r(Ss::CardHeaderComponent.new(title: "Ruptura em 3 produtos", eyebrow: "Estoque · urgente", eyebrow_tone: :danger, subtitle: "Hoje"))}</div>)))]])

bar = r(Ss::StickyActionBarComponent.new(always: true, style: "position:static")) do |b|
  b.with_summary { view.safe_join([view.tag.span("3 itens"), view.ss_amount(view.ss_money(120))]) }
  r(Ss::ButtonComponent.new(label: "Fechar pedido", size: :sm)).html_safe
end
out << section("ss-sticky-bar-v20", "StickyActionBarComponent#with_summary", "Barra fixa com resumo livre à esquerda (v0.20, par do SsStickyActionBar(summary:)).",
  ["with_summary: conteúdo livre no lugar da mensagem (sem o ponto amarelo), região viva para o leitor de tela.", "As ações vêm no bloco; always: true mostra sem esperar alteração e continua visível ao voltar o campo ao original, em Cancelar e ao enviar (v0.22.1)."],
  [["resumo", "resumo do pedido", box.(420, bar)]])

rep = r(Ss::RepeaterComponent.new(add_label: "Adicionar telefone", min: 1, label: "Telefones")) do |rp|
  rp.row { %(<div class="ss-field"><label>Telefone</label><input class="ss-input" value="(85) 98765-4321"></div>).html_safe } +
    rp.row { %(<div class="ss-field"><label>Telefone</label><input class="ss-input" value="(85) 3234-5678"></div>).html_safe }
end
out << section("ss-repeater", "Ss::RepeaterComponent", "Linhas repetíveis de formulário (v0.20, par do SsRepeater) com o Stimulus ss-repeater.",
  ["Adicionar clona o <template> trocando NEW_RECORD por um número único; o foco vai ao 1º campo da linha nova.", "Tirar: linha salva ganha _destroy=1 e some; linha nova sai do DOM; min: esconde o ×.",
   "Eventos ss-repeater:add/remove; o leitor de tela ouve \"Linha adicionada\"/\"Linha removida\"."],
  [["linhas", "dois telefones", box.(360, %(<div class="ss-card ss-card-pad">#{rep}</div>))]])

pal = r(Ss::ComboboxComponent.new(name: "produto_id", label: "Produto", options: [{ id: 1, label: "Arroz 5 kg" }])) do |c|
  c.with_action { r(Ss::IconButtonComponent.new(icon: "qrcode", label: "Ler código de barras")).html_safe }
end
rep2 = r(Ss::RepeaterComponent.new(add_label: "Adicionar item", header: ["Produto", "Qtd", { label: "Total", align: :end }], columns: [4, 1, "7rem"])) do |rp|
  [["Arroz 5 kg", "1", "R$ 25,90"], ["Feijão 1 kg", "2", "R$ 17,80"]].map do |(p, q, tot)|
    rp.row { %(<div class="ss-field"><label>Produto</label><input class="ss-input" value="#{p}"></div><div class="ss-field"><label>Qtd</label><input class="ss-input num" value="#{q}"></div><p class="num" style="margin:0;text-align:end;font-weight:700">#{tot}</p>).html_safe }
  end.join.html_safe
end
out << section("ss-repeater-header", "Ss::RepeaterComponent(header:, columns:)", "Linhas do pedido com o cabeçalho uma vez (v0.20.3, par do SsRepeater(header:, flex:)).",
  ["header: cabeçalho único em tela larga; os rótulos dos campos ficam só para o leitor de tela (hide_labels:, padrão com header:) e o × fica no meio da linha.", "columns: [4, 1, \"7rem\"] (número = fr) ou um texto de grid-template-columns, para o cabeçalho e as linhas; r.row(columns:) troca numa linha.",
   "No celular (abaixo de 48rem): sem cabeçalho, rótulos de volta e a grade automática."],
  [["pedido", "pedido com cabeçalho", %(<div style="width:620px"><div class="ss-card ss-card-pad">#{rep2}</div></div>)]])

out << section("ss-search-action-v20", "with_action (Combobox, CommandPalette)", "Botão ao lado da busca (v0.20, par do showSsPicker(actions:)): leitor de código de barras, cadastrar novo.",
  ["O botão é do app (Ss::IconButtonComponent com o data-action dele); na paleta, ss-command#close fecha."],
  [["combobox", "leitor de código ao lado", box.(360, %(<div class="ss-card ss-card-pad">#{pal}</div>))]])

txt = %(<p style="margin:0 0 12px">Leia o #{r(Ss::TextLinkComponent.new(label: "manual do vendedor", href: "#", external: true))} antes.</p>) +
      r(Ss::TermsNoticeComponent.new(terms_url: "#t", privacy_url: "#p"))
out << section("ss-link-v20", "TextLinkComponent · TermsNoticeComponent", "Link no meio do texto e o aviso de termos (v0.20, pares do SsLinkText/SsTextLink e do SsTermsNotice).",
  ["a.ss-link: cor da marca em 700, sublinha no hover/foco; external: abre em outra aba com o ícone e o aviso para o leitor de tela.", "TermsNotice: frase em pt-BR/en/es com %{terms} e %{privacy}; text: troca."],
  [["texto", "link e termos", box.(360, %(<div class="ss-card ss-card-pad">#{txt}</div>))]])

out << section("ss-editable-value", "Ss::EditableValueComponent", "Valor que se edita ao toque (v0.20, par do SsEditableValue): rótulo, valor em DM Mono e \"editar\".",
  ["href: abre a edição (diálogo em turbo-frame); sem href, <button> com o data-action do app.", "Lido como \"novo: R$ 12,90, Editar\"; para editar no lugar, InlineEditComponent."],
  [["padrao", "preço novo", box.(260, %(<div class="ss-card ss-card-pad" style="display:flex;justify-content:space-between;align-items:center"><span>Arroz 5 kg</span>#{r(Ss::EditableValueComponent.new(label: "novo", value: view.ss_money(12.9), href: "#"))}</div>))]])

canvas = view.render(partial: "vitrine/node_canvas_demo").to_s.gsub(/<%#.*?%>/m, "").gsub(/\n\s*/, "")
out << section("ss-node-canvas", "Ss::NodeCanvasComponent", "Palco do editor de nós/fluxograma (v0.20): a pele da gem para a DOM do Drawflow. Só web (o app não edita fluxo).",
  ["Grade de pontos (grid: false tira); o palco começa com parent-drawflow (o Drawflow arrasta por ela).", "Portas na cor da marca; .is-branch pinta a 1ª saída de verde (sim) e a 2ª de vermelho (senão); setas .is-yes/.is-no.",
   "Estados: .selected (brilho da marca), .is-changed (brilho verde 3×), .is-refused/.is-flash (sacode e fica vermelho); reduzir movimento desliga.", "× da seta em vermelho; node_delete: false esconde o × do bloco; readonly: tira as portas."],
  [["fluxo", "fase, decisão e recusado", box.(620, canvas)]])

escala = (1..14).map { |d| { id: d, nome: %w[Ana Bia Caio][d % 3], **(1..14).to_h { |k| [:"d#{k}", (k + d).even? ? "M" : "T"] } } }.first(3)
esc = r(Ss::DataTableComponent.new(rows: escala, id: "cat-escala", caption: "Escala", tools: false, stack: false)) do |t|
  t.column :nome, "Pessoa", sticky: true
  (1..14).each { |k| t.column :"d#{k}", k.to_s.rjust(2, "0") }
end
out << section("ss-data-table-scroll", "DataTableComponent(stack: false)", "Tabela que continua tabela no celular (v0.20.4, par do SsDataTable(stack: false)): rola de lado com a 1ª coluna parada.",
  ["Sem stack: false, abaixo de 640px cada linha vira um card.", "Com sticky: na 1ª coluna, o nome fica parado enquanto os dias rolam."],
  [["celular", "escala de 14 dias em 360px", box.(360, esc)]])
out << section("ss-figure", ".ss-figure (número grande)", "O número grande da v0.5 com nome próprio (v0.20.4, par do AppType.statNum): no herói, num card ou solto. .ss-stat solto continua igual.",
  [".ss-stat só vira card com .is-card ou com o markup dele (.ss-stat-body).", "No herói o número herda o branco do gradiente."],
  [["heroi", "no herói e num card", row.(%(<div class="ss-hero" style="padding:16px 20px;width:220px"><p class="ss-kicker" style="color:inherit;opacity:.8">Vendido hoje</p><p class="ss-figure">R$ 4.280</p></div>), %(<div class="ss-card ss-card-pad" style="width:200px"><p class="ss-kicker">Pedidos</p><p class="ss-stat">128</p></div>))]])
print out
