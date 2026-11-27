# Gera as <section> do catálogo (rails/catalogo/index.html) da v1.13.0 "confiança na IA e suíte": Ss::ExplainComponent,
# Ss::AiActionPreviewComponent, Ss::SinceLastVisitComponent, Ss::ContinueOnComponent, Ss::SuiteSwitcherComponent,
# Ss::ConflictResolverComponent e o Ss::MoneyInputComponent(voice: true).
#   bin/rails runner script/catalogo_v1130.rb > /tmp/v1130.html
include ComponentesUi::Helpers
require "action_dispatch/testing/test_request"
CTRL = ApplicationController.new.tap { |c| c.request = ActionDispatch::TestRequest.create("PATH_INFO" => "/vitrine/x"); c.response = ActionDispatch::Response.new }
def view = (@view ||= CTRL.view_context)
def clean(html) = html.to_s.gsub(/<!-- (BEGIN|END) [^>]*-->/, "").gsub(/\n\s*/, "").gsub(/ss-[a-z]+-\d{4,}/) { |m| m.sub(/\d+\z/, "cat") }
def r(c, &blk) = clean(view.render(c, &blk))
def esc(s) = ERB::Util.h(s)
def section(slug, nome, desc, comps, estados)
  out = +%(<section data-comp="#{slug}" data-nome="#{esc(nome)}" data-descricao="#{esc(desc)}"\n  data-comportamentos='#{esc(comps.to_json)}'>\n)
  estados.each { |(s, t, html)| out << %(  <div data-estado="#{s}" data-titulo="#{esc(t)}">#{html}</div>\n) }
  out << "</section>\n"
end
def box(w, html, style = "") = %(<div style="width:#{w}px;#{style}">#{html}</div>)

NOW = Time.zone.local(2026, 11, 27, 10, 0)
# Popover aberto na captura: o painel vira bloco estático (sem a Popover API do navegador da captura).
def open_pop(html) = html.gsub(' popover="auto"', "").gsub('style="position-anchor:', 'style="position:static;opacity:1;scale:1;translate:0 0;margin-top:.5rem;position-anchor:')

ITENS = [{ label: "Mercado Exemplo", value: view.ss_money(512.40), href: "#", hint: "9 lançamentos" },
         { label: "Restaurantes", value: view.ss_money(268.90), href: "#", hint: "6 lançamentos" },
         { label: "Transporte", value: view.ss_money(186.30), href: "#" }]
kpi = ->(label, value) { r(Ss::KpiCardComponent.new(label:, value:, money: value.start_with?("R$"))) }
print section("ss-explain", "Ss::ExplainComponent", "De onde vem este valor (v1.13, par do SsExplain): o \"?\" no foco ou com o mouse abre a fórmula, o que compõe o valor e \"Explicar com IA\".",
  ["Envolve qualquer valor, KPI ou ponto de gráfico (o bloco); o botão \"?\" aparece no hover e no foco (no toque, sempre).",
   "Popover nativo (role=dialog): valor em mono, fórmula/origem, os itens com link, \"e mais N\" e \"Ver todos\".",
   "Explicar com IA (ai_url:): POST com o token, espera { text: }; enquanto pensa, os pontinhos e Cancelar (AbortController); erro com Tentar de novo.",
   "O pacote só apresenta: os dados e a IA são do produto."],
  [["fechado", "o KPI com o ? (foco)", box(320, r(Ss::ExplainComponent.new(value: view.ss_money(1240), formula: "Soma dos 23 lançamentos de nov")) { kpi.call("Gastos de novembro", view.ss_money(1240)) }.sub('class="ss-explain-btn"', 'class="ss-explain-btn" style="opacity:1"'))],
   ["aberto", "aberto: fórmula, itens e IA", box(380, open_pop(r(Ss::ExplainComponent.new(value: view.ss_money(1240), title: "Gastos de novembro", formula: "Soma dos 23 lançamentos de nov", items: ITENS, more: 20, more_href: "#", ai_url: "#")) { kpi.call("Gastos de novembro", view.ss_money(1240)) }), "padding-bottom:1rem")],
   ["pensando", "a IA pensando, com Cancelar", box(380, open_pop(r(Ss::ExplainComponent.new(value: "18%", formula: "Gastos de nov ÷ gastos de out − 1", ai_url: "#")) { kpi.call("Acima de outubro", "18%") }).sub('data-state="idle"', 'data-state="thinking"'))]])

MUD = [{ id: 1, title: "Lançamento de 12/11 · Mercado Exemplo", subtitle: "R$ 89,90", fields: [{ label: "Categoria", before: "Outros", after: "Mercado" }, { label: "Etiqueta", before: nil, after: "Casa" }] },
       { id: 2, title: "Lançamento de 14/11 · Posto Exemplo", subtitle: "R$ 150,00", fields: [{ label: "Categoria", before: "Outros", after: "Transporte" }] },
       { id: 3, title: "Assinatura antiga", fields: [{ label: "Recorrência", before: "Mensal", after: nil }], selected: false }]
print section("ss-ai-action-preview", "Ss::AiActionPreviewComponent", "Antes de aplicar (v1.13, par do SsAiActionPreview): o antes e depois campo a campo, com marcar e desmarcar cada alteração.",
  ["Diff com as cores semânticas e o nome em texto: Novo (verde), Removido (vermelho), Alterado (âmbar); antes em <del>, depois em <ins>, \"(vazio)\".",
   "Uma caixa por alteração (changes[] = id); \"Marcar todas\"/\"Desmarcar todas\"; \"2 de 3 marcadas\" ao vivo (ss-ai-preview).",
   "Aplicar trava sem nenhuma marcada (com a frase); Ajustar (adjust_href:) e Cancelar (cancel_href: ou fecha o diálogo).",
   "Depois de aplicar, o produto responde com o Ss::ToastComponent(undo_url:) (\"3 alterações aplicadas · Desfazer\"). No chat: ChatActionComponent(review_dialog:)."],
  [["varias", "três alterações, uma desmarcada", box(560, r(Ss::AiActionPreviewComponent.new(changes: MUD, apply_url: "#", adjust_href: "#")))],
   ["nenhuma", "nenhuma marcada", box(560, r(Ss::AiActionPreviewComponent.new(changes: [MUD.first.merge(selected: false)], apply_url: "#")))],
   ["chat", "no chat: Ver alterações", box(420, r(Ss::ChatActionComponent.new(title: "Recategorizar 3 lançamentos", icon: view.ss_icon("sparkles", size: nil), review_dialog: "previa", rows: [["Lançamentos", "3"]], confirm_url: "#", cancel_url: "#")))]])

SINCE = [{ value: "3", label: "pedidos novos", icon: "shopping-bag", href: "#" }, { value: view.ss_money(1240), label: "recebidos", icon: "cash", tone: :success },
         { value: "1", label: "tarefa atrasada", icon: "clock", tone: :warn, href: "#", action_label: "Resolver" }]
print section("ss-since-last-visit", "Ss::SinceLastVisitComponent", "Desde a última visita (v1.13, par do SsSinceLastVisit): o cartão ao abrir com o que mudou, números que rolam e uma ação por item.",
  ["\"Desde ontem às 18h\" (hoje, ontem, o dia da semana até 6 dias, depois a data).",
   "Cada número rola (OdometerComponent(roll_in:)); cada item tem a ação dele.",
   "Some sozinho em auto_hide: s (pausa com o mouse ou o foco) ou com Entendi; grava a visita no localStorage (storage_key:).",
   "src: \"/novidades?desde=%{since}\" busca o cartão com a última visita do navegador. Sem itens, nada aparece."],
  [["ontem", "desde ontem às 18h", box(640, r(Ss::SinceLastVisitComponent.new(since: (NOW - 1.day).change(hour: 18), now: NOW, items: SINCE, auto_hide: nil)))],
   ["semana", "desde segunda, celular", box(360, r(Ss::SinceLastVisitComponent.new(since: Time.zone.local(2026, 11, 23, 9, 30), now: NOW, items: SINCE.first(2), auto_hide: nil)))]])

LINK = ComponentesUi::Handoff.link("https://vendas.exemplo.com.br/pedidos/novo", { cliente: "Loja Exemplo", itens: 3 })
print section("ss-continue-on", "Ss::ContinueOnComponent", "Continuar no outro aparelho (v1.13, par do SsContinueOn): o QR e o link da tela atual com o estado (filtros e rascunho).",
  ["state: vai no link (ComponentesUi::Handoff: JSON em base64url no ?s=); o app lê com SsHandoff.decode.",
   "handoff_url: + form: manda o rascunho ao endpoint do produto ao abrir e troca o QR e o link pelo { url:, svg: } da resposta.",
   "QR com nome no leitor de tela, fundo claro em qualquer tema; Copiar link com retorno; link longo avisa.",
   "target: :computer é o \"Continuar no computador\" (tela aberta no navegador do celular)."],
  [["celular", "continuar no celular (aberto)", box(360, open_pop(r(Ss::ContinueOnComponent.new(url: LINK))), "padding-bottom:1rem")],
   ["computador", "botão do computador", box(360, r(Ss::ContinueOnComponent.new(url: LINK, target: :computer)))]])

PRODS = [{ id: "vendas", name: "Minhas Vendas", icon: "shopping-bag", color: "#0f766e", href: "#", current: true },
         { id: "gestor", name: "Meu Gestor", icon: "chart-bar", color: "#5a45e8", href: "#", badge: 3, last_used_at: NOW - 3.days },
         { id: "fin", name: "Meu Financeiro", icon: "cash", color: "#2563eb", href: "#", last_used_at: NOW - 5.hours },
         { id: "personal", name: "Meu Personal", icon: "lightning-bolt", color: "#e11d48", active: false, description: "Treinos e alunos no celular", discover_href: "#" }]
print section("ss-suite-switcher", "Ss::SuiteSwitcherComponent", "Apps da suíte (v1.13, par do SsSuiteSwitcher): os produtos que a conta usa e \"Conhecer\" os outros, ao lado do avatar na moldura.",
  ["Recebe a lista por parâmetro (a gem não sabe quais produtos existem); color: é dado (#rrggbb inline).",
   "Seus apps: ícone na cor do produto, nome, \"Você está aqui\" ou \"Usado há 3 dias\", selo de avisos (com o texto para o leitor de tela).",
   "Conheça também: descrição e Conhecer (outra aba). O ponto no botão quando há aviso.",
   "Na moldura: Ss::AppShellComponent#with_suite, entre o sino e o avatar."],
  [["aberto", "a grade aberta", box(360, open_pop(r(Ss::SuiteSwitcherComponent.new(products: PRODS, now: NOW))), "padding-bottom:1rem;display:flex;justify-content:flex-end")]])

print section("ss-conflict-resolver", "Ss::ConflictResolverComponent", "Conflito de versões (v1.13, par do SsConflictResolver): \"Sua versão\" × \"Versão do servidor\" campo a campo.",
  ["Só os campos que diferem; os iguais viram \"N campos iguais nas duas versões\".",
   "Um rádio por lado em cada campo (resolve[campo] = mine | theirs), a sua marcada; quando e quem mudou do lado de lá.",
   "Ficar com a minha / Ficar com a do servidor marcam todos (ss-conflict); Salvar escolha envia.",
   "No web: o salvar que bateu num registro velho (lock_version). No app: a fila offline pelo SsSyncPanel."],
  [["pedido", "pedido mudado em dois lugares", box(560, r(Ss::ConflictResolverComponent.new(url: "#", theirs_by: "Ana (desktop)", theirs_at: 20.minutes.ago, mine_at: 5.minutes.ago, cancel_href: "#",
     fields: [{ key: :qtd, label: "Quantidade", mine: "12", theirs: "10" }, { key: :entrega, label: "Entrega", mine: "Sexta, 05/12", theirs: "Quinta, 04/12" },
              { key: :obs, label: "Observação", mine: "Deixar na portaria", theirs: nil }, { key: :cliente, label: "Cliente", mine: "Loja", theirs: "Loja" }])))]])

mic = ->(html) { html.sub(" hidden aria-label=", " aria-label=") }
print section("ss-money-voice", "Ss::MoneyInputComponent(voice: true)", "Valor falado (v1.13, par do SsMoneyField(onVoice:)/SsSpokenAmount): o microfone no campo de dinheiro e o texto em centavos.",
  ["O reconhecimento é o do navegador (SpeechRecognition); sem ele, o microfone não aparece.",
   "O texto vira centavos pelo ssParseAmount (\"cento e vinte e três e cinquenta\" → R$ 123,50), o mesmo do ComponentesUi::Speech e do SsSpeech.",
   "\"Ouvi “…”\" embaixo (região viva); sem entender, a frase de erro. Eventos ss-spoken-amount:text (texto de fora) e :heard."],
  [["ouviu", "ouviu um valor", box(360, mic.(r(Ss::MoneyInputComponent.new(name: "v", label: "Valor", voice: true, value_cents: 12_350))).sub('<small class="ss-spoken" aria-live="polite" hidden', '<small class="ss-spoken" aria-live="polite"').sub('data-ss-spoken-amount-target="out"></small>', 'data-ss-spoken-amount-target="out">Ouvi “cento e vinte e três e cinquenta”</small>'))],
   ["nao-entendeu", "não entendeu", box(360, mic.(r(Ss::MoneyInputComponent.new(name: "v", label: "Valor", voice: true))).sub('<small class="ss-spoken" aria-live="polite" hidden', '<small class="ss-spoken is-bad" aria-live="polite"').sub('data-ss-spoken-amount-target="out"></small>', 'data-ss-spoken-amount-target="out">Não entendi o valor em “uns trocados”. Fale de novo ou digite.</small>'))]])
