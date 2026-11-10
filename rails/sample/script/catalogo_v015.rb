# Gera as <section> do catálogo (rails/catalogo/index.html) para as peças da v0.15.
#   bin/rails runner script/catalogo_v015.rb > /tmp/v015.html
include ComponentesUi::Helpers
require "action_dispatch/testing/test_request"
CTRL = ApplicationController.new.tap { |c| c.request = ActionDispatch::TestRequest.create("PATH_INFO" => "/vitrine/x"); c.response = ActionDispatch::Response.new }
def view = (@view ||= CTRL.view_context)
def r(c, &blk) = view.render(c, &blk).to_s.gsub(/<!-- (BEGIN|END) [^>]*-->/, "").gsub(/\n\s*/, "").gsub(/name="authenticity_token" value="[^"]*"/, 'name="authenticity_token" value=""')
def esc(s) = ERB::Util.h(s)
def section(slug, nome, desc, comps, estados)
  out = +%(<section data-comp="#{slug}" data-nome="#{esc(nome)}" data-descricao="#{esc(desc)}"\n  data-comportamentos='#{esc(comps.to_json)}'>\n)
  estados.each { |(s, t, html, extra)| out << %(  <div data-estado="#{s}" data-titulo="#{esc(t)}"#{extra}>#{html}</div>\n) }
  out << "</section>\n"
end
card = ->(html, w = 360) { %(<div class="ss-card ss-card-pad" style="width:#{w}px">#{html}</div>) }
money = ->(v) { ss_money(v) }
out = +""
icons = %w[credit-card banknotes office-building chart-pie arrow-trending-up calendar-days magnifying-glass bell-alert eye-slash sparkles].map { ss_icon(_1, size: :md) }.join(" ")
out << section("ss-icon", "ss_icon · Ss::IconComponent · .ss-icon", "Ícone do conjunto da gem (v0.15, par do SsIcons.named): Heroicons v1 (MIT) em SVG inline na cor do texto; aceita nome da v2.",
  ["Nome da v2 vira o da v1 (magnifying-glass → search); desconhecido vira question-mark-circle.", "size: xs 16, sm 20 (padrão), md 24, lg 28 ou nil (quem envolve dimensiona).", "variant: :solid para os cheios (estrela, check, avisos); title: vira role=img com <title>."],
  [["conjunto", "contorno · md", %(<div style="display:flex;flex-wrap:wrap;gap:12px;color:var(--ink-2)">#{icons}</div>)],
   ["cheio", "cheio e tamanhos", %(<div style="display:flex;gap:12px;align-items:center">#{ss_icon("star", variant: :solid, size: :xs, css: "text-warn")}#{ss_icon("check-circle", variant: :solid, css: "text-success")}#{ss_icon("x-circle", variant: :solid, size: :md, css: "text-danger")}#{ss_icon("bell", size: :lg)}#{ss_icon("nao-existe")}</div>)]])
out << section("ss-month-switcher", "Ss::MonthSwitcherComponent · .ss-month-switcher", "Seletor de mês (v0.15, par do SsMonthSwitcher): ‹ Outubro 2026 › por link, sem JS para funcionar.",
  ["Setas vão ao mês vizinho (rel=prev/next, data-turbo-frame se frame:).", "Fora do mês atual, o título é link que volta para ele.", "min:/max: apagam a seta (aria-disabled).", "O título novo entra deslizando do lado da troca (mola, 0,45 s); ← → com o foco trocam."],
  [["atual", "mês atual", card.(r(Ss::MonthSwitcherComponent.new(month: Date.new(2026, 11, 1), today: Date.new(2026, 11, 9), url: ->(m) { "?mes=#{m.strftime("%Y-%m")}" })))],
   ["outro", "outro mês · trava no máximo", card.(r(Ss::MonthSwitcherComponent.new(month: Date.new(2026, 10, 1), today: Date.new(2026, 11, 9), max: "2026-10", url: ->(m) { "?mes=#{m.strftime("%Y-%m")}" })))],
   ["hover", "hover na seta", card.(r(Ss::MonthSwitcherComponent.new(month: Date.new(2026, 11, 1), today: Date.new(2026, 11, 9), url: ->(m) { "#" })).sub('class="ss-month-switcher-arrow" rel="prev"', 'data-alvo class="ss-month-switcher-arrow" rel="prev"')), ' data-acao="hover"']])
dlg = r(Ss::DialogComponent.new(id: "cat-dlg", title: "Novo lançamento", subtitle: "Despesa no cartão", icon: ss_icon("credit-card", size: nil))) do |d|
  d.with_footer { %(<button class="ss-btn ss-btn-ghost">Cancelar</button><button class="ss-btn ss-btn-primary">Salvar</button>).html_safe }
  r(Ss::MoneyInputComponent.new(name: "v", label: "Valor", value_cents: 4500, id: "cat-dlg-v")).html_safe
end
dlg_open = dlg.sub("<dialog ", '<dialog open style="position:static;width:100%;margin:0;animation:none" ')
out << section("ss-dialog-panel", "Ss::DialogComponent · .ss-dialog-panel", "Diálogo genérico (v0.15, par do showSsSheet): cabeçalho com ícone, título, subtítulo e X; corpo livre ou num turbo-frame; rodapé de ações.",
  ["Abre por link que carrega o frame (data-turbo-frame) ou por [data-ss-dialog-open=id]; Esc, X e clique no fundo fecham.", "Celular: folha de baixo (.ss-sheet); desktop: caixa central (sm 25rem, md 32rem, lg 44rem).", "Envio que deu certo dentro dele fecha; 422 fica aberto com o erro; [data-ss-dialog-close] na resposta fecha.", "Entra com a mola do .ss-sheet e sai deslizando (.is-closing, 0,22 s); carregando, o corpo apaga (aria-busy)."],
  [["aberto", "aberto (desktop)", dlg_open]])
out << section("ss-money-expression", "Ss::MoneyInputComponent(expression:, signed:)", "Dinheiro com conta (v0.15, par do SsMoneyField(expression:)): aceita 45+12,50 e mostra o resultado; signed: false trava o sinal.",
  ["Modo conta: o texto fica livre, embaixo aparece = R$ 57,50 (aria-live) e o hidden recebe os centavos.", "Ao sair do campo (ou Enter), a conta vira o valor formatado.", "Conta que não fecha marca o campo inválido (borda e frase em vermelho).", "Sem expression: os dígitos entram pela direita, como antes; signed: false ignora a tecla -."],
  [["conta", "com conta", card.(r(Ss::MoneyInputComponent.new(name: "a", label: "Valor", expression: true, id: "cat-mx")).sub('value=""', 'value="45+12,50"').sub('data-ss-money-target="result"></small>', %(data-ss-money-target="result">= #{ss_amount("R$ 57,50")}</small>)))],
   ["invalida", "conta inválida", card.(r(Ss::MoneyInputComponent.new(name: "a", label: "Valor", expression: true, id: "cat-mi")).sub('value=""', 'value="45+" aria-invalid').sub('data-ss-money-target="result"></small>', 'data-ss-money-target="result">Conta ou valor inválido</small>'))]])
bars = r(Ss::BarChartComponent.new(title: "Receitas × despesas", show_title: true, stacked: true, active: 5, format: ->(v) { ss_money(v, precision: 0) }, labels: %w[jun jul ago set out nov],
  series: [{ name: "Receitas", values: [5200, 4800, 5100, 5300, 4900, 5600], tone: :success }, { name: "Despesas", values: [-4100, -5200, -3900, -4700, -5000, -4300], tone: :danger }],
  line: { name: "Saldo", values: [1100, -400, 1200, 600, -100, 1300] }))
grouped = r(Ss::BarChartComponent.new(title: "Por cartão", show_title: true, height: 200, format: ->(v) { ss_money(v, precision: 0) }, labels: %w[ago set out nov],
  series: [{ name: "Nubank", values: [1200, 980, 1430, 1100] }, { name: "Inter", values: [600, 720, 410, 830] }, { name: "C6", values: [300, 0, 250, 190] }]))
out << section("ss-barc", "Ss::BarChartComponent · .ss-barc", "Gráfico de barras (v0.15, par do SsBarChart): agrupadas ou empilhadas, com negativos e linha combinada; SVG do servidor.",
  ["Negativo desce da linha do zero; empilhado soma positivos para cima e negativos para baixo.", "line: desenha uma linha com pontos sobre as barras (ex. saldo).", "Barras crescem da linha do zero com a mola (40 ms entre grupos); a linha se desenha em 0,9 s.", "Hover no grupo pinta o fundo; a dica nativa mostra o rótulo e cada série; tabela para leitor de tela.", "Cores: tone:/color: ou --series-1..6 (a 1ª é a marca)."],
  [["empilhado", "empilhado com negativos e linha", card.(bars, 430)], ["agrupado", "agrupado (3 séries)", card.(grouped, 430)]])
rows = [Ss::ProgressRowComponent.new(label: "Mercado", value: 520, limit: 1000, format: money, icon: ss_icon("shopping-cart", size: nil)),
        Ss::ProgressRowComponent.new(label: "Lazer", value: 870, limit: 1000, format: money, icon: ss_icon("film", size: nil)),
        Ss::ProgressRowComponent.new(label: "Restaurantes", value: 1240, limit: 1000, format: money, icon: ss_icon("cake", size: nil)),
        Ss::ProgressRowComponent.new(label: "Reserva", value: 6000, limit: 6000, kind: :goal, format: money, icon: ss_icon("shield-check", size: nil))]
out << section("ss-progress-row", "Ss::ProgressRowComponent · .ss-progress-row", "Linha de progresso (v0.15, par do SsProgressRow): rótulo, gasto de limite, % e a barra no tom do estado.",
  ["Limite: até 80% (warn_at) na marca ou em color:, de 80% a 100% aviso, acima de 100% estouro (vermelho, \"R$ 240 acima\").", "Meta (kind: :goal): 100% é sucesso (verde, \"Meta batida\").", "A barra enche com a mola ao aparecer; role=progressbar com o texto do valor.", "href: vira link com hover no campo."],
  [["tons", "ok · aviso · estouro · meta", card.(%(<div style="display:grid;gap:16px">#{rows.map { r(_1) }.join}</div>))]])
chat = r(Ss::ChatComponent.new(id: "cat-chat", url: "/ia", placeholder: "Pergunte ou peça um lançamento")) do |c|
  c.with_message(from: :me, text: "Gastei 45 no mercado com o Nubank", time: "14:05")
  c.with_message(from: :ai) { %(<p>Posso lançar assim?</p>).html_safe + r(Ss::ChatActionComponent.new(id: "cat-acao", title: "Lançar despesa", icon: ss_icon("credit-card", size: nil), rows: [["Valor", "R$ 45,00"], ["Cartão", "Nubank"], ["Categoria", "Mercado"]], confirm_url: "/c", cancel_url: "/x")).html_safe }
  nil
end
out << section("ss-chat-panel", "Ss::ChatComponent · .ss-chat-panel · .ss-chat-form", "Chat com o assistente (v0.15, par do SsChatBubble + SsThinking + SsChatInput): mensagens, pensando e campo de envio.",
  ["Enter envia, Shift+Enter quebra linha; o campo cresce até 6 linhas.", "A bolha da pessoa entra na hora (echo) e o pensando fica até chegar resposta do assistente.", "Rola sozinho para a última mensagem (suave, menos com reduzir movimento).", "role=log com aria-live=polite."],
  [["conversa", "conversa com ação proposta", card.(chat, 430)],
   ["pensando", "pensando", card.(r(Ss::ChatComponent.new(id: "cat-chat2", url: "/ia", thinking: true)) { |c| c.with_message(from: :me, text: "Quanto gastei com mercado em outubro?"); nil }, 430)]])
out << section("ss-chat-action", "Ss::ChatActionComponent · .ss-chat-action", "Cartão de ação a confirmar (v0.15, par do SsChatActionCard): o que o assistente propõe, os dados em linhas e Confirmar/Cancelar.",
  ["Confirmar e Cancelar postam pelo Turbo; enquanto envia, os dois travam (aria-busy).", "A resposta troca o cartão pelo estado: feito (verde), cancelado (apagado) ou não deu certo (vermelho), sem botões.", "danger: true pinta o Confirmar de vermelho.", "Entra com a mola (0,35 s)."],
  [["pendente", "pendente", card.(r(Ss::ChatActionComponent.new(id: "cat-a1", title: "Lançar despesa", icon: ss_icon("credit-card", size: nil), rows: [["Valor", "R$ 45,00"], ["Cartão", "Nubank"]], confirm_url: "/c", cancel_url: "/x")))],
   ["feito", "confirmado · cancelado · erro", card.(%(<div style="display:grid;gap:10px">#{r(Ss::ChatActionComponent.new(id: "cat-a2", title: "Lançar despesa", rows: [["Valor", "R$ 45,00"]], state: :confirmed))}#{r(Ss::ChatActionComponent.new(id: "cat-a3", title: "Lançar receita", state: :cancelled))}#{r(Ss::ChatActionComponent.new(id: "cat-a4", title: "Excluir conta", state: :failed, result: "Sem permissão", danger: true))}</div>))]])
fs = r(Ss::FormSectionComponent.new(title: "Detalhes", icon: ss_icon("document-text", size: nil))) { %(<div class="ss-field"><label>Descrição</label><input class="ss-input" value="Aluguel"></div>).html_safe } +
     r(Ss::FormSectionComponent.new(title: "Recorrência", help: "Repete todo mês até a data final.", divider: true, columns: 2)) { %(<div class="ss-field"><label>Dia</label><input class="ss-input" value="5"></div><div class="ss-field"><label>Até</label><input class="ss-input" value="12/2027"></div>).html_safe }
out << section("ss-form-section", "Ss::FormSectionComponent · .ss-form-section", "Seção de formulário (v0.15, par do SsFieldGroup): título em sobrelinha, ajuda e os campos num fieldset.",
  ["divider: true põe a linha acima.", "columns: 2 ou 3 vira uma coluna até 639 px.", "help: liga o aria-describedby do fieldset."],
  [["secoes", "duas seções", card.(%(<div style="display:grid;gap:16px">#{fs}</div>))]])
puts out
