# Gera as <section> do catálogo (rails/catalogo/index.html) para a v0.26 (conversa entre pessoas).
#   bin/rails runner script/catalogo_v026.rb > /tmp/v026.html
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
def box(w, html) = %(<div class="ss-card ss-card-pad" style="width:#{w}px">#{html}</div>)
def log(html) = %(<div class="ss-chat">#{html}</div>)

M = Ss::ChatComponent::Message
DOC = %(<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M6 3h9l3 3v15H6z"/><path d="M9 10h6M9 14h6M9 18h4"/></svg>)
# Foto de exemplo sem arquivo: um SVG em data URI com as cores do token (o catálogo não tem imagem própria).
FOTO = "data:image/svg+xml;utf8," + ERB::Util.url_encode(%(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 200"><rect width="320" height="200" fill="#d5d9e0"/><circle cx="110" cy="90" r="38" fill="#aab1bd"/><path d="M0 200 120 120l70 50 50-30 80 60z" fill="#7a8394"/></svg>))

conversa = [
  r(Ss::ChatDividerComponent.new(label: "Ontem")),
  r(M.new(from: :them, author: "Mercado Sabor Caseiro", text: "Boa tarde! O pedido 2904 já saiu?", time: "17:40")),
  r(Ss::ChatDividerComponent.new(label: "Hoje")),
  r(M.new(from: :me, author: "Ana · pelo celular", text: "Saiu hoje cedo, chega até as 15h.", time: "09:12", status: :read)),
  r(M.new(from: :them, text: "Obrigado!", time: "09:15"))
].join

situacoes = { sending: "10:01", sent: "10:02", delivered: "10:03", read: "10:04", failed: "10:05" }.map do |st, h|
  r(M.new(from: :me, text: { sending: "Enviando…", sent: "Enviada", delivered: "Entregue", read: "Lida", failed: "Sem rede" }[st], time: h, status: st))
end.join

midia = [
  r(M.new(from: :them, time: "09:20")) { view.safe_join([view.tag.img(class: "ss-bubble-media", src: FOTO, alt: "Foto do produto"), view.tag.p("Chegou assim, com a caixa amassada")]) },
  r(M.new(from: :me, time: "09:21", status: :delivered)) { %(<a class="ss-bubble-file" href="#">#{DOC}<span>boleto-pedido-2904.pdf</span><span class="ss-bubble-file-meta">PDF · 84 KB</span></a>).html_safe },
  r(M.new(from: :them, time: "09:22")) { view.tag.audio(class: "ss-bubble-media", controls: true, "aria-label": "Áudio de 0:12") }
].join

out = +""
out << section("ss-chat-pessoas", "Ss::ChatComponent::Message(from: :them, author:, status:) · .ss-bubble.is-them",
  "Conversa entre pessoas (v0.26, par do SsChatBubble(aiMark: false, author:)): a outra pessoa à esquerda na superfície, sem o ✦ da IA; quem escreveu no alto; situação no rodapé.",
  ["from: :them é a outra pessoa (à esquerda, superfície, data-from=them); :me e :ai como antes.",
   "author: legenda pequena em negrito no alto da bolha (apagada; no meu, a tinta clara sobre a marca).",
   "status: :sending (relógio), :sent (✓), :delivered (✓✓ apagado), :read (✓✓ cheio, na marca) e :failed (alerta e \"Não enviada\" à vista no tom de perigo; na bolha da marca, numa pílula da superfície). O nome vai para o leitor de tela (pt/en/es).",
   "O bloco do ChatComponent entra dentro do log depois do slot messages: dá para intercalar Message e ChatDividerComponent e o Turbo Stream append continua no mesmo lugar."],
  [["pessoas", "cliente e atendente com separador de dia", box(400, log(conversa))],
   ["situacoes", "enviando · enviada · entregue · lida · não enviada", box(400, log(situacoes))]])
out << section("ss-chat-divider", "Ss::ChatDividerComponent · .ss-chat-divider",
  "Separador de dia numa conversa (v0.26, par do SsChatDivider): \"Hoje\", \"Ontem\", \"12/11\".",
  ["role=separator com o rótulo no aria-label; pílula em --field entre duas linhas em --line.", "Rótulo longo termina em reticências."],
  [["hoje", "Hoje", box(400, log(r(Ss::ChatDividerComponent.new(label: "Hoje"))))]])
out << section("ss-bubble-media", ".ss-bubble-media · .ss-bubble-file",
  "Mídia dentro da bolha (v0.26): foto, vídeo ou áudio com .ss-bubble-media e documento como linha-link .ss-bubble-file.",
  ["<img>/<video> até a largura da bolha (20rem de altura no máximo), cantos pelo raio do campo.",
   "<audio controls> ocupa a bolha, com 16rem no mínimo.",
   "Documento: ícone, nome com reticências e .ss-bubble-file-meta opcional; na bolha da marca, fundo translúcido da tinta clara."],
  [["midia", "foto, documento e áudio", box(400, log(midia))]])
puts out
