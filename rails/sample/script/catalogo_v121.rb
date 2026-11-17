# Gera a <section> do catálogo (rails/catalogo/index.html) para a v1.2.1 (linha do tempo horizontal sem rolagem).
#   bin/rails runner script/catalogo_v121.rb > /tmp/v121.html
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

PASSOS = [["Recebido", "17/11 09:12", :done], ["Confirmado", "17/11 09:30", :done], ["Separado", "17/11 10:05", :done],
          ["Saiu para entrega", "17/11 11:40", :current], ["Entregue", nil, nil]].map { |t, d, s| { title: t, date: d, state: s } }.freeze

out = +""
out << section("ss-htl-v121", "Ss::TimelineHorizontalComponent (v1.2.1): sem rolagem",
  "A linha do tempo do pedido online sem passo escondido (v1.2.1): os marcos dividem a largura e, com menos de 36rem, a lista fica em pé.",
  ["Os marcos dividem a largura da lista (o texto quebra); nada rola de lado, então o último passo e o atual ficam sempre à vista.",
   "Lista com menos de 36rem (container query, vale para o cartão estreito e para o celular): um marco por linha, a bolinha à esquerda e o fio descendo até a próxima.",
   "Feito, atual (aria-current=step) e a seguir como antes; a mesma marcação, só CSS."],
  [["largo", "cinco passos num cartão de 760", box(760, r(Ss::TimelineHorizontalComponent.new(label: "Andamento", items: PASSOS)))],
   ["estreito", "os mesmos cinco passos no celular", box(340, r(Ss::TimelineHorizontalComponent.new(label: "Andamento do pedido", items: PASSOS)))]])
out << section("ss-stepper-decimals", "Ss::StepperInputComponent(decimals:)",
  "Quantidade fracionada no idioma da página (v1.2.1, par do SsStepper(decimals:)): \"0,5 kg\" no carrinho, nunca \"0.5\".",
  ["decimals: N mostra o número com N casas pelo Intl do lang do <html> (vírgula em pt-BR e es, ponto em en); campo de texto com inputmode=decimal.",
   "−/+ somam o step:, travam em min:/max: e soltam input/change como antes; digitar \"0.5\" ou \"0,5\" vale.",
   "Ao servidor vai o ponto: o name: está num <input type=hidden> (\"0.5\") que acompanha cada mudança; o campo visível não tem name."],
  [["kg", "meio quilo no carrinho", box(300, r(Ss::StepperInputComponent.new(name: "q", label: "Quantidade", value: 0.5, min: 0, max: 3, step: 0.5, unit: "kg", decimals: 1)))]])
puts out
