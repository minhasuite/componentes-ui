# Gera as <section> do catálogo (rails/catalogo/index.html) para os pares web da v1.10.0 (a dívida do paridade.yml).
#   bin/rails runner script/catalogo_v1100.rb > /tmp/v1100.html
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

print section("ss-attach", "Ss::AttachBarComponent", "Fileira de botões coloridos para anexar (v1.10, par do SsAttachBar): foto, arquivo, local, contato.",
  ["Cada item é um <label> com <input type=file> (accept:, name:), um link (href:) ou um botão (data:); o rótulo é o nome.",
   "Cor da série da suíte na ordem (tone: 1..6) ou color: por token; fundo claro deixa o ícone escuro.",
   "Entram em cascata crescendo com a mola. Alvo ≥ 44. Reduzir movimento: sem entrada."],
  [["quatro", "foto, arquivo, local e contato", box(360, r(Ss::AttachBarComponent.new(items: [
    { icon: "camera", label: "Foto", accept: "image/*", name: "f" }, { icon: "document-text", label: "Arquivo", accept: ".pdf", name: "a" },
    { icon: "location-marker", label: "Local", href: "#" }, { icon: "user", label: "Contato" }])))]])

pilha = ->(open) { r(Ss::CardStackComponent.new(card_height: 96, initially_open: open)) { |s| %w[Nubank Inter C6].each_with_index { |b, i| s.with_card { %(<div class="ss-card ss-card-pad" style="height:100%;background:var(--series-#{i + 1});color:var(--on-accent)"><strong>#{b}</strong></div>).html_safe } } } }
print section("ss-cstack", "Ss::CardStackComponent", "Cartões empilhados que abrem em lista (v1.10, par do SsCardStack).",
  ["Fechado: só a borda de cima dos de trás aparece (peek:, 14 px), menores e mais apagados; um botão cobre a pilha (\"Abrir 3 cartões\").",
   "Clicar abre em lista com a mola (--ss-bounce, passa um pouco e assenta); \"Fechar cartões\" embaixo fecha. Inverter no meio parte de onde está.",
   "Fechados, os de trás ficam inert. Evento ss-card-stack:change { open }. Reduzir movimento: sem animar."],
  [["fechada", "três cartões", box(320, pilha.(false))], ["aberta", "initially_open: true", box(320, pilha.(true))]])

print section("ss-curved", "Ss::CurvedHeaderComponent", "Cabeçalho escuro que termina numa curva côncava (v1.10, par do SsCurvedHeader).",
  ["tone: :brand (a cor funda da paleta) ou :dark (a superfície escura); texto sempre claro (--on-accent).",
   "O fundo desce overlap: (36 px) por trás do conteúdo seguinte, que sobe por cima; curve: a profundidade (28 px).",
   "back_href: o voltar (alvo de 48); with_action e with_bottom (abas, segmentado). Com voltar ou ações, o título centraliza."],
  [["marca", "voltar, título e subtítulo", box(360, r(Ss::CurvedHeaderComponent.new(title: "Carteira", subtitle: "Novembro de 2026", back_href: "#")) + %(<div class="ss-curved-body ss-card ss-card-pad" style="margin:0 12px">Saldo</div>))],
   ["escuro", "tone: :dark", box(360, r(Ss::CurvedHeaderComponent.new(title: "Início", tone: :dark)) + %(<div style="height:40px"></div>))]])

print section("ss-dial", "Ss::DialComponent", "Botão giratório de valor (v1.10, par do SsDial): arco de 270° com marcações e o valor no centro.",
  ["Arrastar em volta (fora do miolo) ou clicar no arco muda; na boca de baixo gruda na ponta mais perto.",
   "role=slider: setas ±step, PageUp/PageDown ±10%, Home/End; o leitor de tela ouve o valor formatado (format: do Kernel.format).",
   "As marcações até o valor e o arco acendem na cor da marca. O valor vai num hidden name:; eventos input/change e ss-dial:change."],
  [["valor", "40, Sala", r(Ss::DialComponent.new(name: "v", value: 40, label: "Volume", caption: "Sala", size: 200))],
   ["desligado", "22,5° desligado", r(Ss::DialComponent.new(value: 22.5, min: 16, max: 30, step: 0.5, format: "%.1f°", size: 160, disabled: true))]])

duo = [{ label: "Despesas", value: ss_money(3210.4), icon: "arrow-up" }, { label: "Receitas", value: ss_money(5100), icon: "arrow-down" }]
print section("ss-duo", "Ss::DuoStatComponent", "Duas estatísticas lado a lado (v1.10, par do SsDuoStat): despesa × receita.",
  ["A ativa tem o gradiente da marca e o texto claro; clicar na outra troca, a pílula desliza com a mola e o ícone gira.",
   "Botões com aria-pressed (troca no lugar, evento ss-duo:change { index }, hidden name:) ou links com aria-current (href:).",
   "Leitor de tela: \"Despesas: R$ 3.210,40\". Reduzir movimento: troca sem deslizar."],
  [["despesas", "index: 0", box(360, r(Ss::DuoStatComponent.new(items: duo, index: 0)))], ["receitas", "index: 1", box(360, r(Ss::DuoStatComponent.new(items: duo, index: 1)))]])

print section("ss-fbars", "Ss::FloatingBarsComponent", "Barras grandes num card da marca com a escolhida em destaque (v1.10, par do SsFloatingBars).",
  ["As outras translúcidas e a escolhida cheia, com o valor numa etiqueta em cima; title: e value: no topo.",
   "Cada barra é um botão (aria-pressed) ou link (href: \"…%{index}\"); clicar escolhe e dispara ss-floating-bars:change { index }.",
   "Sobem com a mola, uma depois da outra, quando o card entra na tela. Reduzir movimento: já aparecem."],
  [["gastos", "cinco meses, o último escolhido", box(360, r(Ss::FloatingBarsComponent.new(title: "Gastos", value: ss_money(1820), values: [320, 410, 280, 520, 290], labels: %w[Jul Ago Set Out Nov], format: :money, height: 240)))]])

print section("ss-goal", "Ss::GoalCardComponent", "Card de meta/convite (v1.10, par do SsGoalCard): arte em cima, texto curto e a ação sublinhada.",
  ["Sem with_art, o ícone (icon:, \"flag\") num brilho da marca.",
   "Ao entrar na tela, a arte brota com a mola e o sublinhado se desenha do meio para as pontas, depois.",
   "A ação é link (href:) ou botão, com alvo de 44. Reduzir movimento: já aparece pronto."],
  [["meta", "ícone e ação", box(320, r(Ss::GoalCardComponent.new(text: "Junte para a viagem de julho sem apertar o mês.", action_label: "Criar meta", href: "#")))]])

print section("ss-hex", "Ss::HexButtonComponent", "Botão hexagonal de destaque na cor da marca (v1.10, par do SsHexButton).",
  ["Hexágono no gradiente da marca com a seta e um brilho em volta; aperta (.92) ao clicar.",
   "href: vira link; sem href, <button> (type:, form:). label: o nome falado (\"Começar\"). Nunca menor que 44."],
  [["padrão", "72 px", %(<div style="padding:24px">#{r(Ss::HexButtonComponent.new(href: "#"))}</div>)]])

print section("ss-isplit", "Ss::IllustratedSplitComponent", "Tela de apresentação partida com a ilustração (v1.10, par do SsIllustratedSplit).",
  ["Ilustração em cima no fundo suave da marca; o painel de baixo sobe numa curva com pontinhos, título, texto e ações.",
   "with_art (a do app) ou illustration: (a do Ss::IllustrationArtComponent). page:/pages: = \"Página 1 de 3\" no leitor de tela.",
   "Ações em botão cheio e fantasma, alvo de 48."],
  [["passo", "página 1 de 3", box(360, %(<div style="height:560px">#{r(Ss::IllustratedSplitComponent.new(title: "Seu dinheiro num lugar só", text: "Contas, cartões e metas.", illustration: :empty, action_label: "Começar", action_href: "#", secondary_label: "Já tenho conta", secondary_href: "#", page: 0, pages: 3))}</div>))]])

artes = Ss::IllustrationArtComponent::KINDS.map { |k| r(Ss::IllustrationArtComponent.new(k, size: 96)) }.join
print section("ss-illus", "Ss::IllustrationArtComponent", "As ilustrações dos estados vazios, soltas (v1.10, par do SsIllustrationArt).",
  [":empty, :offline, :no_results, :all_done e :error (em --danger); a mesma arte do EmptyStateComponent(illustration:).",
   "Entra crescendo com a mola; parada, o símbolo flutua e os brilhos piscam. Reduzir movimento: parada.",
   "Decorativa (aria-hidden): o título ao lado é o que se lê."],
  [["casos", "os cinco", %(<div style="display:flex;gap:8px;flex-wrap:wrap;width:420px">#{artes}</div>)]])

print section("ss-ill-stage", "Ss::IllustrationStageComponent", "Palco da ilustração com o fundo da marca (v1.10, par do SsIllustrationStage).",
  ["Degradê da cor suave da marca para a cor da página, com o raio de folha.",
   "A ilustração encolhe para caber em height: (112 px), para o botão do passo caber sem rolar."],
  [["palco", "com a arte vazia", box(320, r(Ss::IllustrationStageComponent.new) { r(Ss::IllustrationArtComponent.new(:all_done)).html_safe })]])

# ── v1.10 (lote B): pares Rails das peças do Flutter ──────────────────────────
# Foto de mentira (SVG em data URI): um degradê com um círculo, para as peças de imagem.
def foto_b(h, w = 400, alt = 300) = "data:image/svg+xml,#{ERB::Util.url_encode(%(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 #{w} #{alt}"><defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="hsl(#{h} 60% 62%)"/><stop offset="1" stop-color="hsl(#{h + 30} 55% 38%)"/></linearGradient></defs><rect width="#{w}" height="#{alt}" fill="url(#g)"/><circle cx="#{w * 0.62}" cy="#{alt * 0.42}" r="#{alt * 0.22}" fill="hsl(#{h} 80% 88%)"/></svg>))}"

print section("ss-image-viewer", "Ss::ImageViewerComponent", "Foto em tela cheia com zoom (v1.10, par do SsImageViewer): comprovante, foto do cupom, anexo.",
  ["A miniatura (ou o bloco with_trigger) abre um <dialog> escuro: barra com ×, title: e with_action; a imagem inteira no meio.",
   "Zoom de 1× a max_scale: (4): roda no ponto do mouse, pinça, duplo clique (2,5× no ponto e volta), − / + / tamanho original e + − 0 no teclado.",
   "Arrastar (ou as setas) move a ampliada, presa para não sair da tela. Esc e × fecham; o foco volta à miniatura.",
   "O % é um <output aria-live>: \"Zoom 250%\". Imagem que não carrega: ícone e \"Não deu para abrir a imagem\".",
   "Reduzir movimento: o zoom troca sem animar. inline: true desenha o visor no lugar, sem diálogo."],
  [["miniatura", "o gatilho", r(Ss::ImageViewerComponent.new(src: foto_b(200), title: "cupom.jpg"))],
   ["aberto", "visor (inline)", box(360, %(<div style="height:300px">#{r(Ss::ImageViewerComponent.new(src: foto_b(200), title: "cupom.jpg", inline: true))}</div>))]])

print section("ss-month-grid", "Ss::MonthGridComponent", "Grade do mês para escolher o dia (v1.10, par do SsMonthGrid).",
  ["7 colunas a partir do domingo; hoje com anel, o escolhido com o fundo da marca e um pulinho com a mola (--ss-bounce).",
   "markers: até 3 pontinhos por dia (:accent, :success, :warn, :danger, :muted); dias de fora do mês apagados e fora do foco.",
   "url: com %{date}: cada dia é link. Sem url: botões que gravam no input name: e disparam ss-month-grid:select { date }.",
   "Um ponto de Tab: ← → um dia, ↑ ↓ uma semana, Home/End; PageUp/PageDown e arrastar para o lado vão ao mês vizinho (month_url:).",
   "Leitor de tela: \"12/11/2026, hoje, 2 marcadores\"; alvo de 48 px por dia."],
  [["mes", "novembro com marcadores", box(340, r(Ss::MonthGridComponent.new(month: hoje, selected: hoje - 12, today: hoje, url: "#%{date}",
                                                                             markers: { hoje - 12 => %i[accent success], hoje - 20 => [:warn], hoje + 3 => %i[danger accent muted] })))]])

print section("ss-people", "Ss::PeoplePickerComponent", "Escolher várias pessoas com os avatares (v1.10, par do SsPeoplePicker): com quem dividir, quem convidar.",
  ["Pílulas altas com avatar, o primeiro nome e um + que vira ✓; as marcadas ganham anel e o fundo da marca, e o avatar estoura com a mola.",
   "Cada pessoa é um checkbox de verdade (name:), então vai no formulário e o change é o onChanged.",
   "add_url: põe o \"Novo\" no começo. Fileira rola para o lado; Tab entra em cada uma, Espaço marca.",
   "Reduzir movimento: sem o estouro."],
  [["fila", "duas marcadas", box(380, r(Ss::PeoplePickerComponent.new(name: "p[]", people: ["Ana Souza", "Bruno Lima", "Carla Dias", "Davi Rocha"],
                                                                        selected: ["Ana Souza", "Carla Dias"], add_url: "#")))]])

print section("ss-popout", "Ss::PopOutCardComponent", "Card com a imagem vazando para fora da borda de cima (v1.10, par do SsPopOutCard).",
  ["Imagem acima do card (pop_out: px, 44), título em até 2 linhas, detalhe, preço em DM Mono e o botão redondo de ação.",
   "url: o card inteiro é link; add_url: o botão (POST, ou add_method: :get), lido \"Adicionar: <título>\".",
   "Passar o mouse: a imagem sobe e cresce um pouco com a mola. tone: fundo tonal.",
   "O Ss::ProductCardComponent (grade da loja, com selo) continua."],
  [["padrao", "com preço e adicionar", box(220, r(Ss::PopOutCardComponent.new(title: "Costela-de-adão", subtitle: "Meia-sombra", price: ss_money(89.9),
                                                                                image_url: foto_b(140, 200, 200), url: "#", add_url: "#")))],
   ["tonal", "tone: :success", box(220, r(Ss::PopOutCardComponent.new(title: "Jiboia", subtitle: "Sol pleno", price: ss_money(39.9), tone: :success,
                                                                       image_url: foto_b(100, 200, 200), add_url: "#", add_method: :get)))]])

print section("ss-profile-hero", "Ss::ProfileHeroComponent", "Topo do perfil com a curva e o avatar (v1.10, par do SsProfileHero).",
  ["Fundo tonal da marca com a borda de baixo curva; foto grande arredondada (sem foto, as iniciais no gradiente do nome).",
   "Nome, status com o ponto verde (online:) e até 3 métricas (\"128 pedidos\"), separadas por um fio.",
   "with_leading (voltar) e with_action (editar, compartilhar) na barra de cima, com alvo de 44."],
  [["perfil", "sem foto, com métricas", box(360, r(Ss::ProfileHeroComponent.new(name: "Ana Souza", status: "Online agora", online: true,
                                                                                 metrics: [%w[128 pedidos], ["4,9", "nota"], ["3 anos", "cliente"]])))]])

print section("ss-pulse", "Ss::PulseAvatarComponent", "Avatar com as ondas de \"ao vivo\" (v1.10, par do SsPulseAvatar): IA ouvindo, chamando, sincronizando.",
  ["Três ondas na cor saem do avatar e somem, defasadas (uma volta de 2,2 s = 5,5 × --ss-dur-long).",
   "active: false para as ondas; o bloco troca o avatar (ícone da IA). tone: :accent | :success | :warn | :danger.",
   "Leitor de tela: \"Ana Souza, chamando\" num role=status. Reduzir movimento: dois anéis parados."],
  [["ativo", "chamando", r(Ss::PulseAvatarComponent.new(name: "Ana Souza", status: "chamando", size: 64))],
   ["parado", "active: false", r(Ss::PulseAvatarComponent.new(name: "Ana Souza", active: false, size: 64))]])

print section("ss-recurring", "Ss::RecurringCardComponent", "Cartão de conta recorrente com o próximo vencimento (v1.10, par do SsRecurringCard).",
  ["\"Todo domingo · 11:00\", o valor em DM Mono (rola ao mudar: Ss::OdometerComponent), o destino e um check redondo.",
   "done: o check enche de verde e estoura com a mola; o leitor de tela lê \"Feito\" ou \"Pendente\".",
   "url: o cartão é link; with_menu ou menu_url: o ⋮ no canto (alvo de 44)."],
  [["pendente", "a fazer", box(300, r(Ss::RecurringCardComponent.new(schedule: "Todo domingo", time: "11:00", amount: ss_money(50), destination: "para Instituto Sol", url: "#", menu_url: "#")))],
   ["feito", "done: true", box(300, r(Ss::RecurringCardComponent.new(schedule: "Todo dia 5", time: "08:00", amount: ss_money(1290), destination: "Aluguel", done: true, menu_url: "#")))]])

formas = [Ss::ShapeIconComponent.new(icon: "bolt"), Ss::ShapeIconComponent.new(icon: "leaf", tone: :success),
          Ss::ShapeIconComponent.new(icon: "check", shape: :hexagono, filled: true), Ss::ShapeIconComponent.new(icon: "fire", shape: :hexagono, tone: :warn, filled: true)].map { |c| r(c) }.join
print section("ss-shape-icon", "Ss::ShapeIconComponent", "Ícone dentro de um losango ou hexágono da marca (v1.10, par do SsShapeIcon).",
  ["shape: :losango ou :hexagono de cantos arredondados (o mesmo contorno do SsShapeIcon.pathFor).",
   "Tonal (a cor a 14%, 22% no escuro) ou filled: (cheia, ícone em --on-accent). tone: a cor; sem tone, a marca.",
   "Sem label: é decoração (aria-hidden); com label:, role=img."],
  [["formas", "tonal e cheio", %(<div style="display:flex;gap:12px">#{formas}</div>)]])

trilho = r(Ss::ThumbRailComponent.new(images: [200, 140, 30, 280, 330].map { |h| foto_b(h, 200, 200) }, selected: 1, height: 280))
print section("ss-thumbs", "Ss::ThumbRailComponent", "Miniaturas em coluna ao lado da foto (v1.10, par do SsThumbRail).",
  ["A escolhida tem a borda da marca; as outras ficam apagadas (55%).",
   "Setas em cima e embaixo rolam uma miniatura e somem nas pontas; ↑ ↓ andam o foco.",
   "Clicar dispara ss-thumb-rail:select { index, src } e troca o src do <img id=target>; url: com %{index} faz links.",
   "Leitor de tela: \"Imagem 2 de 5\", a escolhida como pressionada."],
  [["coluna", "5 fotos, a 2ª escolhida", %(<div style="display:flex;gap:12px;align-items:flex-start">#{trilho}<img src="#{foto_b(140, 200, 200)}" alt="" style="width:240px;height:240px;border-radius:16px;object-fit:cover"></div>)]])

print section("ss-vslider", "Ss::VerticalSliderComponent", "Slider de pé: volume, brilho, temperatura (v1.10, par do SsVerticalSlider).",
  ["Trilha alta em pílula que enche de baixo; o valor fica escrito no seletor, em DM Mono.",
   "É um <input type=range> em pé: arrastar, clicar, setas e o leitor de tela (aria-valuetext \"21,5°\").",
   "suffix:/precision: formam o texto; tone: a cor; disabled: apagado."],
  [["valores", "volume e temperatura", %(<div style="display:flex;gap:16px">#{r(Ss::VerticalSliderComponent.new(name: "v", value: 40, label: "Volume", suffix: "%"))}#{r(Ss::VerticalSliderComponent.new(name: "t", value: 21.5, min: 16, max: 30, step: 0.5, precision: 1, suffix: "°", tone: :warn, label: "Temperatura"))}#{r(Ss::VerticalSliderComponent.new(name: "d", value: 70, disabled: true, label: "Brilho"))}</div>)]])
