# Gera a <section> do catálogo (rails/catalogo/index.html) para a v1.4 (a folhinha da entrada reage).
#   bin/rails runner script/catalogo_v140.rb > /tmp/v140.html
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

DIA = Date.new(2026, 11, 17)
html = r(Ss::AuthLayoutComponent.new(product: "Meu Gestor", tagline: "A loja em dia, sem planilha.", title: "Entrar",
                                     variant: :wall, date: DIA, motion: true, style: "min-height:0")) { "" }
folha = html[%r{<template data-ss-auth-target="next">(.*?)</template>}m, 1]
  .sub('<p class="ss-auth-hello"></p>', '<p class="ss-auth-hello">Boa tarde.</p>')
  .sub('class="ss-auth-next"', 'class="ss-auth-next" style="position:relative;width:420px;height:560px"')
parado = html.sub(%r{<template.*?</template>}m, "")

print section("ss-auth-motion", "Ss::AuthLayoutComponent(motion: true)",
  "A folhinha da entrada reage (v1.4, variante :wall, controlador ss-auth): cai ao entrar e treme no erro.",
  ["Ao enviar o formulário ou tocar em \"Entrar com o Google\", a folha se solta do pino e cai (1 s); o envio segue na hora, sem esperar.",
   "Por baixo aparece a folha seguinte, da mesma largura e altura: a saudação pela hora de quem abre (Bom dia até 12h, Boa tarde até 18h, Boa noite), \"Abrindo o <produto>…\" com a barra enchendo e o carimbo \"Em dia\" (em --danger).",
   "error: true: a folha treme ao abrir (a página voltou com o erro de login). Se o Turbo devolver falha sem trocar a página, a folha volta ao pino e treme.",
   "Voltar pelo histórico (bfcache) devolve a folha ao pino.",
   "Reduzir movimento: a folha só some e nada treme; o carimbo e a barra já aparecem prontos.",
   "Textos em pt/en/es (componentes_ui.auth.greetings, opening, stamp). Só na :wall; nas outras variações motion: é ignorado."],
  [["parada", "wall com motion: true, antes de entrar", %(<div style="width:1100px;border-radius:16px;overflow:hidden">#{parado}</div>)],
   ["entrando", "a folha de baixo, com saudação e carimbo", %(<div style="padding:24px">#{folha}</div>)]])
