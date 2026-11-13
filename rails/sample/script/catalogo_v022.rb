# Gera as <section> do catálogo (rails/catalogo/index.html) para as peças da v0.22.
#   bin/rails runner script/catalogo_v022.rb > /tmp/v022.html
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

DIA = Date.new(2026, 11, 13)
LINKS = [["Termos", "#"], ["Privacidade", "#"]].freeze
def campos
  view.ss_form_with(url: "#", method: :get) do |f|
    view.safe_join([f.ss_email_field(:email, label: "E-mail", placeholder: "voce@exemplo.com"),
                    f.ss_password_field(:password, label: "Senha"), f.ss_submit("Entrar", css: "w-full")])
  end
end
def tela(variant, product, tagline, title, subtitle, w, &corpo)
  html = r(Ss::AuthLayoutComponent.new(product:, tagline:, title:, subtitle:, variant:, date: DIA, links: LINKS, style: "min-height:0"), &corpo)
  %(<div style="width:#{w}px;border-radius:16px;overflow:hidden">#{html}</div>)
end

entrar = tela(:sheet, "Meu Gestor", "A loja em dia, sem planilha.", "Entrar", "no Meu Gestor", 520) do
  view.safe_join([view.render(Ss::GoogleButtonComponent.new(href: "#", method: :get)), view.tag.div("ou com e-mail", class: "ss-divider"), campos])
end
domingo = r(Ss::AuthLayoutComponent.new(product: "Meu Financeiro", title: "Entrar", date: Date.new(2026, 11, 15), style: "min-height:0")) { campos }
erro = tela(:wall, "Minhas Vendas", "A venda não para.", "Entrar", "no Minhas Vendas", 1100) do
  view.safe_join([view.render(Ss::CalloutComponent.new(tone: :danger, title: "E-mail ou senha não conferem.")) { "Confira os dois ou use Esqueci a senha." }, campos])
end
enviado = tela(:pad, "Meu Financeiro", "Seu dinheiro, sem susto.", "Confira seu e-mail", "O link vale por 2 horas.", 520) do
  view.safe_join([view.render(Ss::CalloutComponent.new(tone: :success, title: "Link enviado para ana.souza@exemplo.com.")) { "Não chegou? Veja o spam ou envie de novo." },
                  view.render(Ss::ButtonComponent.new(label: "Voltar para entrar", href: "#", variant: :outline, block: true))])
end

print section("ss-auth", "Ss::AuthLayoutComponent", "Tela de entrada \"Folhinha\" (v0.22, par do SsAuthLayout.folhinha): folhinha de parede com a data de hoje, o formulário do produto no bloco e a faixa do produto em --accent.",
  ["variant: :sheet (folha pendurada, padrão), :wall (folhinha grande à esquerda, formulário numa coluna; no celular empilha) e :pad (bloco de destacar, com a folha de amanhã por baixo).",
   "date: é o dia da folhinha (padrão hoje); domingo em --danger. Mês e dia da semana em pt/en/es (componentes_ui.auth.*).",
   "O bloco é do produto: ss_form_with, Ss::GoogleButtonComponent, Ss::CalloutComponent (erro, link enviado), Ss::TextLinkComponent.",
   "Título e números em --ss-font-display (Big Shoulders Display; ss_display_font_tag no <head>), o resto na fonte da gem.",
   "Na :wall a folhinha grande é aria-hidden; o painel diz \"Parte da MinhaSuite\". links: [[rótulo, href]] embaixo."],
  [["entrar", "sheet: entrar", entrar], ["domingo", "sheet: domingo em vermelho", %(<div style="width:520px;border-radius:16px;overflow:hidden">#{domingo}</div>)],
   ["erro", "wall: senha errada", erro], ["enviado", "pad: link enviado", enviado]])
