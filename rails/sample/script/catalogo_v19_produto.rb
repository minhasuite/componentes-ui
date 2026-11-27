# Gera as <section> do catálogo (rails/catalogo/index.html) da v1.9 · produto: central de notificações, assistente e
# formas de capturar.
#   bin/rails runner script/catalogo_v19_produto.rb > /tmp/v19_produto.html
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

agora = Time.utc(2026, 11, 24, 15)
avisos = [
  { id: 1, title: "Orçamento aprovado", text: "Mercado Bom Preço aprovou o orçamento 1042.", at: Time.utc(2026, 11, 24, 14, 32), unread: true,
    icon: "check-circle", tone: :success, href: "#", read_href: "#", archive_href: "#" },
  { id: 2, title: "Aprovação pendente", text: "Desconto de 12% no pedido 881 espera a sua alçada.", at: Time.utc(2026, 11, 24, 9, 10), unread: true,
    icon: "clock", tone: :warn, href: "#", read_href: "#", archive_href: "#" },
  { id: 3, title: "Resumo do dia", text: "8 pedidos, R$ 12.480,00 vendidos.", at: Time.utc(2026, 11, 23, 19), icon: "sun", href: "#", archive_href: "#" }
]
lista = r(Ss::NotificationCenterComponent.new(id: "cat-avisos", items: avisos, now: agora, read_all_href: "#", next_href: nil))
vazio = r(Ss::NotificationCenterComponent.new(id: "cat-avisos-vazio", items: []))
foto = "data:image/svg+xml;utf8," + ERB::Util.url_encode(%(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 90"><rect width="160" height="90" fill="#334155"/><rect x="18" y="30" width="60" height="44" rx="4" fill="#64748b"/><circle cx="128" cy="24" r="10" fill="#f59e0b"/></svg>))
ricos = r(Ss::NotificationCenterComponent.new(id: "cat-avisos-ricos", now: agora, items: [
  { id: 11, title: "Portão da garagem aberto", text: "Aberto há 10 min, sem ninguém em casa.", at: Time.utc(2026, 11, 24, 14, 50), unread: true, level: :critical,
    image: foto, image_alt: "Câmera da garagem", href: "#", actions: [{ label: "Fechar portão", href: "#" }, { label: "Deixar aberto", href: "#" }],
    mute: { options: [1, 8, 24].map { |h| { label: "Por #{h} h", href: "#" } } } },
  { id: 12, title: "Bateria fraca no sensor da sala", text: "12% de carga.", at: Time.utc(2026, 11, 24, 13), level: :warning, href: "#", mute: { href: "#" } }]))
print section("ss-notification-center", "Ss::NotificationCenterComponent",
  "Central de notificações (v1.9, par do SsNotificationCenter): por dia, lida/não lida, marcar todas, ler e arquivar por aviso, paginação por turbo-frame lazy e vazio.",
  ["Grupos \"Hoje\", \"Ontem\", \"segunda-feira, 5 de outubro\" (no ano) ou a data; a hora em DM Mono.",
   "Não lida: título em negrito, contorno da marca, sombra e o ponto (\"não lida\" para o leitor de tela).",
   "Abrir: href: com method: :patch vira button_to (marca lida e leva ao destino); sem method, link (_top).",
   "Faixa: \"2 não lidas\" (role=status) e \"Marcar todas como lidas\" (PATCH em read_all_href:).",
   "read_href:/archive_href: viram botões de ícone de 44px; com mouse, aparecem ao passar ou com o foco.",
   "next_href: <turbo-frame id=\"<id>-p2\" loading=lazy> com \"Carregar mais\"; a resposta é o mesmo componente com fragment: true, page: 2 e after: (não repete o dia).",
   "Sem itens: Ss::EmptyStateComponent \"Nenhuma notificação\".",
   "v1.9.2, aviso rico (opcional): level: :warning/:critical (tom no ícone e no contorno, selo \"Aviso\"/\"Crítico\"), image: (foto 16:9), actions: (botões de resposta, o 1º cheio) e mute: (\"Silenciar\": um botão ou o menu com options:)."],
  [["lista", "hoje e ontem, com não lidas", box(420, lista)],
   ["vazio", "nenhuma notificação", box(360, vazio)],
   ["rico", "aviso rico: nível, foto, respostas e silenciar", box(420, ricos)]])

conversa = r(Ss::AssistantComponent.new(id: "cat-asst", url: "#", current_conversation_id: 1, new_conversation_href: "#",
  conversations: [{ id: 1, title: "Treino de 4 dias", subtitle: "há 2 min", href: "#", delete_href: "#" }, { id: 2, title: "Platô no supino", subtitle: "ontem", href: "#", delete_href: "#" }],
  shortcuts: [{ label: "Resumo da semana", icon: "chart-bar" }, { label: "Estou estagnado?" }], quota: { used: 7, limit: 10 },
  messages: [{ from: :me, text: "Monte um treino de 4 dias para hipertrofia", time: "14:02" },
             { from: :ai, text: "Posso montar 4 dias (A/B/C/D). Quer que eu monte?", time: "14:02",
               action: { title: "Montar este treino", description: "4 dias · 45 min", icon: "sparkles", confirm_url: "#", cancel_url: "#", confirm_label: "Montar treino", cancel_label: "Agora não" } },
             { status: :pending }]))
vazio_asst = r(Ss::AssistantComponent.new(id: "cat-asst-vazio", url: "#", empty_text: "Pergunte sobre o seu treino.", shortcuts: [{ label: "Resumo da semana" }, { label: "Metas" }]))
bloqueado = r(Ss::AssistantComponent.new(id: "cat-asst-lock", url: "#", locked: { feature: "Assistente com IA", text: "Faz parte dos planos Pro e Max.", href: "#" }))
print section("ss-assistant", "Ss::AssistantComponent",
  "Assistente com IA (v1.9, par do SsAssistantView) sobre o Ss::ChatComponent: conversas ao lado, atalhos no topo e no vazio, ação sugerida, resposta pendente que se busca sozinha, plano sem direito e cota.",
  ["conversations: lista ao lado a partir de 840px (abrir, + nova, lixeira com confirmação de perigo); a atual com aria-current.",
   "shortcuts: chips no topo da conversa (no vazio, centrados): tocar escreve o prompt no campo e envia; com href:, link.",
   "messages: bolhas do ChatComponent; action: o Ss::ChatActionComponent abaixo; status: :failed mostra o erro e \"Tentar de novo\".",
   "status: :pending: bolha com os três pontos (role=status \"Respondendo\"); o ss-assistant pede poll_url a cada 2 s e troca pela resposta (204 = ainda pensando).",
   "quota: barra .ss-quota (is-low falta 1, is-out acabou); acabada, o campo trava com \"Mensagens do mês esgotadas\".",
   "locked: cartão com cadeado, \"Só nos planos pagos\" e \"Ver planos\" no lugar da conversa (sem campo)."],
  [["conversa", "conversas, atalhos, ação e respondendo", box(900, conversa)],
   ["vazio", "vazio com atalhos", box(420, vazio_asst)],
   ["bloqueado", "plano sem direito", box(420, bloqueado)]])

hub = r(Ss::CaptureHubComponent.new(id: "cat-cap", upload: { url: "#", name: "arquivos[]", accept: "image/*,.pdf,.xml" }, paste: { url: "#", name: "texto" },
  options: [{ kind: :camera, title: "Foto do cupom", description: "Cupom fiscal ou print do pedido.", highlighted: true },
            { kind: :paste, group: "Compra" }, { kind: :file, group: "Compra", description: "XML da NF-e" },
            { kind: :barcode, group: "Produto", href: "#" }, { kind: :gallery, group: "Produto", disabled_reason: "No plano Pro ou Max", disabled_href: "#" }]))
print section("ss-capture-hub", "Ss::CaptureHubComponent",
  "Formas de capturar (v1.9, par do SsCaptureHub): opção destacada no gradiente, grade com ícone, título e descrição, indisponível com o motivo, e o envio por arrastar, colar e escolher (Ss::FileDropComponent).",
  ["kind: (:camera, :gallery, :paste, :barcode, :file) dá ícone, título e descrição padrão do I18n; title:/description:/icon: trocam.",
   "highlighted: bloco largo no gradiente (--grad) com \"Recomendado\".",
   "disabled_reason: apagada, cadeado e o motivo; disabled_href: continua link (planos); \"Indisponível\" para o leitor de tela.",
   "Sem href:, câmera/galeria/arquivo abrem o seletor do upload: (câmera com capture=environment) e enviam ao escolher; colar abre o campo de texto.",
   "Ctrl+V em qualquer ponto: arquivo (print) vai para o envio; texto, para o campo de colar.",
   "group: título da seção; grade auto-fit (mínimo 13rem), uma coluna no celular estreito."],
  [["grade", "destaque, grupos, indisponível e envio", box(520, hub)]])
