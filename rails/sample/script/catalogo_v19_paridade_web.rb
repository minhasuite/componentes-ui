# Gera as <section> do catálogo (rails/catalogo/index.html) para os pares web da v1.9 (paridade web).
#   bin/rails runner script/catalogo_v19_paridade_web.rb > /tmp/v19.html
include ComponentesUi::Helpers
require "action_dispatch/testing/test_request"
CTRL = ApplicationController.new.tap { |c| c.request = ActionDispatch::TestRequest.create("PATH_INFO" => "/vitrine/x"); c.response = ActionDispatch::Response.new }
def view = (@view ||= CTRL.view_context)
def r(c, &blk) = view.render(c, &blk).to_s.gsub(/<!-- (BEGIN|END) [^>]*-->/, "").gsub(/\n\s*/, "").gsub(/ss-[a-z]+-\d{4,}/) { |m| m.sub(/\d+\z/, "cat") }
def esc(s) = ERB::Util.h(s)
def section(slug, nome, desc, comps, estados)
  out = +%(<section data-comp="#{slug}" data-nome="#{esc(nome)}" data-descricao="#{esc(desc)}"\n  data-comportamentos='#{esc(comps.to_json)}'>\n)
  estados.each { |(s, t, html)| out << %(  <div data-estado="#{s}" data-titulo="#{esc(t)}">#{html}</div>\n) }
  out << "</section>\n"
end
def box(w, html) = %(<div style="width:#{w}px">#{html}</div>)
hoje = Date.new(2026, 11, 24)

print section("ss-swipe-confirm", "Ss::SwipeToConfirmComponent", "Arrastar a bolinha até o fim para confirmar (v1.9, par do SsSwipeToConfirm): pagar, fechar o pedido.",
  ["Passou de 85% ao soltar: gruda no fim, mostra carregando e envia o formulário (url:, method:, params:).",
   "turbo:submit-end sem sucesso: a bolinha volta; com sucesso: ✓ done_label no fundo verde.",
   "Sem url: o evento ss-swipe-confirm:confirm (detail.done()/fail()).",
   "Teclado e leitor de tela: a bolinha é um botão; Enter/Espaço confirma direto. Clique de mouse sem arrastar só cutuca.",
   "Reduzir movimento: sem a mola da volta."],
  [["parado", "antes de arrastar", box(340, r(Ss::SwipeToConfirmComponent.new(label: "Deslize para pagar R$ 120,00")))],
   ["pago", "done: true", box(340, r(Ss::SwipeToConfirmComponent.new(label: "Pago", done: true, done_label: "Pago")))]])

print section("ss-hold-confirm", "Ss::HoldToConfirmComponent", "Segurar para confirmar (v1.9, par do SsHoldToConfirm): o fundo enche da esquerda enquanto o botão fica pressionado.",
  ["Mouse, dedo, Espaço ou Enter seguram; cheio (duration:, 1200 ms) mostra ✓ e envia o formulário (url:, method:).",
   "Soltou antes: volta. O clique do leitor de tela confirma direto. danger: vermelho de erro.",
   "Sem url: o evento ss-hold-confirm:confirm; volta ao começo depois de 1,6 s."],
  [["parado", "segurar para transferir", box(320, r(Ss::HoldToConfirmComponent.new(label: "Segure para transferir")))],
   ["enchendo", "na metade, perigo", box(320, r(Ss::HoldToConfirmComponent.new(label: "Segure para excluir", danger: true, style: "--p:.5")))]])

print section("ss-morph", "Ss::MorphButtonComponent", "Botão que vira carregando e depois ✓/✗ (v1.9, par do SsMorphButton).",
  ["No formulário: turbo:submit-start encolhe num círculo com o anel; turbo:submit-end termina em ✓ (verde) ou ✗ (vermelho) e volta em 1,6 s.",
   "Progresso real: direct-upload:progress do Active Storage ou o evento ss-morph:progress { value }.",
   "type: :button dispara ss-morph:run com detail.waitUntil(promise).",
   "O leitor de tela ouve \"Salvar: carregando\", \"concluído\" ou \"falhou\"."],
  [["parado", "pílula", box(300, r(Ss::MorphButtonComponent.new(label: "Salvar", icon: "check")))],
   ["ok", "deu certo", box(300, r(Ss::MorphButtonComponent.new(label: "Salvar")).sub('data-state="idle"', 'data-state="ok"'))]])

carrossel = r(Ss::SnapCarouselComponent.new(label: "Ofertas", height: 140)) do |c|
  %w[Arroz Feijão Café].each { |p| c.with_slide { %(<div class="ss-card ss-card-pad" style="height:100%;display:grid;place-items:center"><strong>#{p}</strong></div>).html_safe } }
end
print section("ss-carousel", "Ss::SnapCarouselComponent", "Carrossel que para em cada item (v1.9, par do SsSnapCarousel): o do meio maior, os vizinhos cortados e menores.",
  ["scroll-snap no centro; peek: a fração da largura de cada item (0,78).",
   "indicator: :dots (a ativa vira pílula), :counter (\"2/5\") ou :none; setas de anterior/próximo para mouse e teclado.",
   "← → andam um item com o foco na faixa; o leitor de tela ouve \"Item 2 de 5\". Evento ss-carousel:change { index }."],
  [["dots", "três itens", box(360, carrossel)]])

aneis = [Ss::StoryRingComponent.new(name: "Você", segments: 0, caption: "Você", add_href: "#"), Ss::StoryRingComponent.new(name: "Ana Souza", segments: 3, seen: 1, caption: "Ana", href: "#"),
         Ss::StoryRingComponent.new(name: "Carla Dias", segments: 2, seen: 2, caption: "Carla", href: "#")].map { |c| r(c) }.join
print section("ss-story", "Ss::StoryRingComponent", "Avatar com anel de novidades em gomos (v1.9, par do SsStoryRing).",
  ["Um gomo por novidade: os novos no gradiente da marca, os vistos numa linha neutra fina; desenham em sequência ao entrar na tela.",
   "href: o avatar vira link; add_href: o \"+\" no canto. caption: o nome embaixo (negrito com novidade).",
   "Leitor de tela: \"Ana Souza, 2 novidades\"."],
  [["fila", "você, com novidade e visto", %(<div style="display:flex;gap:16px">#{aneis}</div>)]])

print section("ss-odo", "Ss::OdometerComponent", "Número que rola por dígito (v1.9, par do SsOdometer); o Ss::CountUpComponent continua.",
  ["Cada dígito é um rolo 0–9 que gira até o novo e assenta com mola, subindo quando aumentou e descendo quando caiu.",
   "Cascata da direita para a esquerda (35 ms); vírgula e \"R$\" parados; casa nova entra com fade; centavos menores.",
   "Trocar data-ss-odometer-text-value (morph do Turbo ou JS) rola; roll_in: parte do 0 ao entrar na tela.",
   "Leitor de tela: o texto inteiro, avisado ao mudar. Reduzir movimento: troca sem rolar."],
  [["dinheiro", "R$ 1.234,56", r(Ss::OdometerComponent.new(text: ss_money(1234.56)))]])

print section("ss-burst", "Ss::BurstComponent", "Estouro de risquinhos em volta do conteúdo (v1.9, par do SsBurst): o \"deu certo\" da caixa marcada.",
  ["on: :click (padrão), :change (só ao marcar), :connect ou :manual (ss-burst#play / evento ss:burst).",
   "count: traços (7), distance: px (14), tone: :accent | :success | :warn | :danger. Decoração fora do leitor de tela.",
   "Reduzir movimento: não toca."],
  [["caixa", "ao marcar", r(Ss::BurstComponent.new(on: :change, tone: :success)) { %(<label class="ss-check"><input type="checkbox" checked> Feito</label>).html_safe }]])

print section("ss-heatcal", "Ss::HeatCalendarComponent", "Constância estilo contribuições do GitHub (v1.9, par do SsHeatCalendar).",
  ["Uma coluna por semana (domingo a sábado), 5 níveis da cor da marca (a fração do maior valor, o ssHeatLevel).",
   "weeks: até end_date (hoje) ou month: só o mês. Clicar ou focar mostra \"12/11/2026: 3\" embaixo.",
   "Um ponto de tab: ↑ ↓ um dia, ← → uma semana. format: :qty, :integer, :money ou lambda. legend: false."],
  [["semanas", "12 semanas", box(360, r(Ss::HeatCalendarComponent.new(values: (0..84).to_h { |i| [hoje - i, i * 7 % 5] }, weeks: 12, end_date: hoje)))]])

print section("ss-bigring", "Ss::BigRingComponent", "Percentual grande num anel fino com marcações, estilo termostato (v1.9, par do SsBigRing).",
  ["As marcações até o valor acendem (uma a cada 5 é maior); o arco e a bolinha enchem e o número conta ao entrar na tela.",
   "tone: :accent | :success | :warn | :danger. Leitor de tela: \"72% da meta\"."],
  [["meta", "72% da meta", r(Ss::BigRingComponent.new(value: 0.72, caption: "da meta", size: 180))]])

print section("ss-rings-c", "Ss::RingsComponent", "Anéis concêntricos (v1.9, par do SsRings; o componente do ss_rings).",
  ["Até 3 anéis de 0 a 1 sobre a trilha a 14%, que enchem em cascata ao entrar na tela; center: o texto do meio.",
   "ring: { value:, label:, tone: }; sem tom, as cores da aurora da marca. Leitor de tela: \"Calorias 80%, Exercício 50%\"."],
  [["tres", "três anéis", r(Ss::RingsComponent.new(rings: [{ value: 0.8, label: "Calorias" }, { value: 0.55, label: "Exercício" }, { value: 0.3, label: "Em pé" }], center: "80%"))]])

print section("ss-date-strip", "Ss::DateStripComponent", "Faixa horizontal com os dias do mês (v1.9, par do SsDateStrip).",
  ["O escolhido é a pílula alta na cor da marca, que desliza com mola até o dia novo (no clique e no morph do Turbo).",
   "url: com %{date} (aaaa-mm-dd); markers: { Date => [tons] } põe até 3 pontinhos.",
   "O cabeçalho \"Novembro 2026 ⌄\" abre o calendário do navegador para pular de mês. ← → andam entre os dias."],
  [["mes", "dia 12 escolhido", box(360, r(Ss::DateStripComponent.new(selected: Date.new(2026, 11, 12), today: hoje, url: "?dia=%{date}",
                                                                        markers: { Date.new(2026, 11, 14) => [:accent, :success] })))]])

print section("ss-split-slider", "Ss::SplitSliderComponent", "Divide um valor entre pessoas, em centavos (v1.9, par do SsSplitSlider).",
  ["locked (padrão): mexer numa linha redistribui o resto entre as outras na proporção delas, fechando o total ao centavo.",
   "Sem locked: cada uma livre e o rodapé diz \"Falta R$ 20,00\" ou \"Sobra\". Cada linha manda name[key] = centavos.",
   "Range nativo (teclado e leitor de tela) com o valor em dinheiro no aria-valuetext."],
  [["travada", "três pessoas", box(360, r(Ss::SplitSliderComponent.new(name: "d", total: 75_086, entries: [{ key: "eu", name: "Eu", cents: 25_000 },
                                                                                                       { key: "ana", name: "Ana", cents: 25_043 }, { key: "bia", name: "Bia", cents: 25_043 }])))]])

sync = [[:synced, 0, 0], [:pending, 3, 0], [:failed, 0, 2], [:offline, 1, 0]].map { |(s, n, f)| r(Ss::SyncStatusComponent.new(state: s, pending_count: n, failed_count: f)) }.join
print section("ss-sync-c", "Ss::SyncStatusComponent", "Situação da sincronização (v1.9, par do SsSyncStatus): a pílula do .ss-sync.",
  ["state: :synced, :pending, :sending, :failed, :offline; resolve(syncing:, failed:, offline:, pending:) é a regra do app.",
   "failed_count: \"2 com erro\"; last_synced_at: \"Sincronizado às 14:32\" na dica e no leitor de tela; href: vira link.",
   "O texto é avisado ao mudar (role=status)."],
  [["estados", "salvo, pendente, com erro e sem conexão", %(<div style="display:flex;gap:12px;flex-wrap:wrap;width:520px">#{sync}</div>)]])
