# Gera as <section> do catálogo (rails/catalogo/index.html) para as peças da v0.23.
#   bin/rails runner script/catalogo_v023.rb > /tmp/v023.html
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

seg = r(Ss::SegmentedComponent.new(label: "Período", items: [{ label: "Dia", href: "#", current: true }, { label: "Semana", href: "#" }, { label: "Mês", href: "#" }]))
abas = r(Ss::SegmentedComponent.new(label: "Andar", scroll: true, items: [{ label: "Térreo", pressed: true }, { label: "1º andar" }, { label: "Garagem" }, { label: "Quintal" }]))
print section("ss-segmented", "Ss::SegmentedComponent", "Seletor segmentado (v0.23, par do SsSegmented): o .ss-seg montado sem <button>/<a> à mão.",
  ["items: href: vira <a> com aria-current; sem href, <button> com aria-pressed (type: :submit + name:/value: envia o form).",
   "Até 4 itens de largura igual com a pílula que desliza; scroll: true deixa do tamanho do texto numa faixa que rola (abas leves).",
   "aria-selected/aria-current/aria-pressed marcam o escolhido: o JS do produto só troca o atributo.",
   "label: vira o aria-label do grupo (role=group)."],
  [["links", "três períodos, Dia escolhido", box(320, seg)], ["faixa", "scroll: andares de uma planta", box(360, abas)]])

bare = r(Ss::ButtonComponent.new(variant: :bare, type: :submit, name: "style", value: "glass")) { view.tag.div(view.tag.strong("Vidro") + view.tag.p("Cards translúcidos sobre o fundo", class: "ss-muted"), class: "ss-card ss-card-pad") }
print section("ss-btn-bare", "Ss::ButtonComponent(variant: :bare)", "Botão sem desenho (v0.23, par do SsPressable): para conteúdo livre que já é a peça (card, amostra, linha).",
  ["Só foco (anel --accent), cursor e o toque que encolhe (0,98); o conteúdo vem do bloco.",
   "type:, name:, value:, href:, method:, data: como os outros variants."],
  [["card", "card escolhível que envia o form", box(280, bare)]])

chips = view.ss_form_with(url: "#") do |f|
  view.safe_join([view.tag.div(view.safe_join([f.ss_chip_check_box("rooms[]", label: "Sala", checked_value: "sala", unchecked_value: nil, checked: true),
                                               f.ss_chip_check_box("rooms[]", label: "Cozinha", checked_value: "cozinha", unchecked_value: nil)]), class: "ss-chips"),
                  f.ss_chip_radio_buttons(:mode, [["Limpar", "clean"], ["Aspirar", "vacuum"], ["Passar pano", "mop"]], label: "Modo", checked: "vacuum")])
end
print section("ss-chip-check", "f.ss_chip_check_box / f.ss_chip_radio_buttons", "Chips de marcar no formulário (v0.23, par do SsFilterChip): o .ss-chip com o input dentro, marcado no degradê.",
  ["ss_chip_check_box: uma caixa por chip (name com [] para várias); unchecked_value: nil tira o hidden.",
   "ss_chip_radio_buttons: uma escolha só, num fieldset com legenda (hide_label: só para o leitor de tela).",
   "Teclado e leitor de tela do input nativo; o desenho é o da v0.10.3."],
  [["filtro", "cômodos e modo do robô", box(360, chips)]])

anim = %(<div style="display:flex;gap:16px;align-items:center"><span class="ss-anim-spin" style="display:inline-block">#{view.ss_icon("arrow-path")}</span><span class="ss-anim-float" style="display:inline-block">#{view.ss_icon("home")}</span><span class="ss-anim-breathe" style="display:inline-block">#{view.ss_icon("light-bulb")}</span></div>)
print section("ss-anim", ".ss-anim-*", "Movimento para ilustração e arte viva (v0.23, só web; o app usa o SsMotion): spin, breathe, float, twinkle, blink, dash, draw, ping, shimmer, from, to, shuttle, path, tick e blip.",
  ["Regulado por variáveis: --ss-anim-dur, -delay, -ease, -iter, -dir, -fill e as de cada uma (--ss-anim-float, -dash, -ping, -from, -to).",
   ".ss-anim-path percorre o offset-path do elemento; .ss-anim-shuttle vai ao --ss-anim-to e volta com pausa.",
   "Parado com prefers-reduced-motion (o .ss-anim-draw aparece já desenhado)."],
  [["icones", "girando, flutuando e respirando", box(200, anim)]])

grid = %(<div class="ss-span-grid" data-ss-screen="desktop">#{(1..3).map { |i| %(<div class="ss-span" style="--ss-span-d:#{i == 1 ? 6 : 3}"><div class="ss-card ss-card-pad">Card #{i}</div></div>) }.join}</div>)
print section("ss-span-grid", ".ss-span-grid / .ss-span", "Grade de 12 colunas com largura por tela (v0.23, só web): painéis montados pelo usuário.",
  ["--ss-span-m (celular, 12), --ss-span-t (tablet, 6) e --ss-span-d (computador ≥ 1024, 4) no .ss-span.",
   "data-ss-screen=mobile|tablet|desktop num ancestral força a tela (prévia do editor); .is-full ocupa a linha.",
   ".ss-hide-mobile/-tablet/-desktop, data-tone (contorno do tom) e .ss-span-flags (selos no canto)."],
  [["computador", "6 + 3 + 3 colunas", box(560, grid)]])

wall = %(<div class="ss-wall-glass" style="padding:16px;border-radius:16px;background:var(--grad)"><div class="ss-card ss-card-pad">Card de vidro sobre o fundo</div></div>)
print section("ss-wall", ".ss-wall / .ss-wall-glass", "Papel de parede da tela no <body> e o vidro dos cards por cima (v0.23, só web).",
  ["--ss-wall-img (imagem) e/ou --ss-wall (fundo) fixos atrás de tudo, com --ss-wall-blur; com imagem entra o véu na cor da página.",
   ".is-dim escurece por cima (--ss-wall-dim, 0 a 80%).",
   ".ss-wall-glass troca só os tokens do card (--ss-card-bg/-border/-filter)."],
  [["vidro", "card de vidro sobre o degradê", box(320, wall)]])
