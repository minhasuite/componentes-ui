# Gera as <section> do catálogo (rails/catalogo/index.html) da v1.12.0 "Kit Brasil": Ss::PixCardComponent,
# Ss::NfeCardComponent, Ss::SmartPasteComponent e os campos f.ss_pix_key/ss_boleto/ss_cep/ss_document.
#   bin/rails runner script/catalogo_v1120.rb > /tmp/v1120.html
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

BR = ComponentesUi::Br
TODAY = Date.new(2026, 11, 27)
PIX = BR.pix_build(key: "loja@exemplo.com.br", name: "Loja Exemplo", city: "São Paulo", amount_cents: 12_345, txid: "PEDIDO1042")
K43 = "3526111122233300018155001000012345112345678"
KEY = K43 + BR.nfe_key_dv(K43).to_s
N43 = "3526111122233300018165002000000789187654321"
NFCE = N43 + BR.nfe_key_dv(N43).to_s
LINHA = "34191.09008 00012.345674 89012.345677 1 16560000012345"

print section("ss-pix-card", "Ss::PixCardComponent", "Pix de uma cobrança (v1.12, par do SsPixCard): QR gerado do copia e cola, valor, recebedor, validade com contagem, copiar e o estado.",
  ["O QR sai do próprio copia e cola (ComponentesUi::Qr, SVG no servidor, sem gem); qr: aceita a imagem pronta do PSP.",
   "Sem amount_cents:/receiver:, lê os campos 54 e 59 do BR Code. Sem valor: \"Valor livre\".",
   "Aguardando: contagem regressiva (ss-countdown); ao zerar, o cartão passa a expirado sozinho (data-expired).",
   "Copiar código (ss-copy): o botão vira \"Código copiado\" por 2 s, anunciado pelo leitor de tela.",
   "Pago: o ✓ cresce com a mola e o traço se desenha (reduzir movimento: já pronto). Expirado: QR apagado e \"Gerar outro código\" com regenerate_href:.",
   "O fundo do QR é sempre o papel claro (o leitor do banco precisa), também no tema escuro. O pagamento é do produto."],
  [["aguardando", "aguardando, com contagem", box(360, r(Ss::PixCardComponent.new(code: PIX, expires_at: 14.minutes.from_now + 32)))],
   ["pago", "pago (animação de sucesso)", box(360, r(Ss::PixCardComponent.new(code: PIX, status: :paid)))],
   ["expirado", "expirado, com gerar outro", box(360, r(Ss::PixCardComponent.new(code: PIX, status: :expired, regenerate_href: "#")))]])

print section("ss-nfe-card", "Ss::NfeCardComponent", "Nota fiscal (v1.12, par do SsNfeCard): chave de acesso em blocos com copiar e o DV conferido, emitente, CNPJ, data, valor, situação e o QR da consulta.",
  ["Da chave (44 dígitos) saem o modelo (NF-e, NFC-e, CT-e), número, série e o CNPJ do emitente.",
   "DV errado: aviso no cartão (role=status). status: :authorized, :canceled, :denied ou :pending.",
   "Copiar chave (ss-copy) com retorno; qr_url: põe o QR da consulta ao lado da chave; open_href: \"Consultar na Sefaz\" em outra aba."],
  [["nfe", "NF-e autorizada", box(400, r(Ss::NfeCardComponent.new(access_key: KEY, issuer: "Loja Exemplo Comércio Ltda", issued_at: Date.new(2026, 11, 20), amount_cents: 48_990, status: :authorized)))],
   ["nfce-qr", "NFC-e com o QR da consulta", box(400, r(Ss::NfeCardComponent.new(access_key: NFCE, issuer: "Mercado Exemplo", issued_at: Date.new(2026, 11, 26), amount_cents: 8_990, status: :pending, qr_url: "https://www.exemplo.gov.br/nfce?p=#{NFCE}|2|1|1", open_href: "#")))],
   ["dv-errado", "chave com DV errado", box(400, r(Ss::NfeCardComponent.new(access_key: KEY[0, 43] + ((KEY[43].to_i + 1) % 10).to_s, status: :canceled)))]])

acts = { boleto: [{ label: "Pagar boleto", href: "#", icon: "cash", primary: true }, { label: "Agendar", href: "#" }],
         pix: [{ label: "Pagar Pix", href: "#", icon: "qrcode" }], pix_key: [{ label: "Enviar Pix", href: "#" }],
         nfe: [{ label: "Importar nota", href: "#", icon: "document-text" }], url: [{ label: "Abrir link", href: "#" }] }
print section("ss-smart-paste", "Ss::SmartPasteComponent", "Colar inteligente (v1.12, par do SsSmartPaste): reconhece o que foi colado e mostra as ações que o produto registrou para o tipo.",
  ["Tipos: Pix copia e cola e chave, boleto (47/48), chave de NF-e (solta ou na URL da NFC-e), CPF/CNPJ, CEP, telefone, e-mail, link e domínio, valor em R$, data e texto livre.",
   "O detector é puro e igual nos três lados (ComponentesUi::PasteDetector, ssDetect do ss_br.js e SsPasteDetector), conferido pelos exemplos de docs/v1120/exemplos.json.",
   "A frase do cartão: \"Isso parece um boleto de R$ 123,45 com vencimento em 10/12/2026\"; com o DV errado, \"Parece um boleto, mas os números não conferem.\"",
   "actions: { boleto: [{ label:, href: \"…%{value}\", method:, icon:, primary: }] }; CPF, CNPJ, telefone e e-mail válidos também mostram as de :pix_key.",
   "DV errado: o aviso e nenhuma ação. O botão Colar lê a área de transferência; o resultado é aria-live; o cartão entra com --ss-dur-medium (reduzir movimento: sem)."],
  [["boleto", "boleto com ações", box(420, r(Ss::SmartPasteComponent.new(value: LINHA, today: TODAY, actions: acts)))],
   ["pix", "Pix copia e cola", box(420, r(Ss::SmartPasteComponent.new(value: PIX, today: TODAY, actions: acts)))],
   ["cpf", "CPF (também chave Pix)", box(420, r(Ss::SmartPasteComponent.new(value: "604.721.385-53", today: TODAY, actions: acts)))],
   ["invalido", "dígito errado", box(420, r(Ss::SmartPasteComponent.new(value: "34191.09008 00012.345674 89012.345677 1 16560001012345", today: TODAY, actions: acts)))],
   ["vazio", "vazio", box(420, r(Ss::SmartPasteComponent.new(actions: acts)))]])

form = clean(view.ss_form_with(url: "#", scope: :c) do |f|
  f.ss_document(:doc, value: "11.222.333/0001-81") + f.ss_pix_key(:chave, value: "+55 11 98765-4321") +
    f.ss_boleto(:linha, value: "83690000001-6 23450048123-4 45678901234-5 56789012345-6") + f.ss_cep(:cep, value: "01310-100")
end)
print section("ss-br-fields", "f.ss_pix_key · f.ss_boleto · f.ss_cep · f.ss_document", "Campos brasileiros (v1.12, pares do SsPixKeyField, SsBoletoField, SsCepField e SsDocumentField): máscara, dígitos verificadores e o retorno embaixo.",
  ["f.ss_pix_key: o tipo (CPF, CNPJ, telefone, e-mail, aleatória) enquanto digita, formatada ao sair; type: prende num tipo.",
   "f.ss_boleto: máscara de 47/48 dígitos (o código de barras de 44 colado vira a linha), DV mod 10/11 e o tipo, valor e vencimento embaixo.",
   "f.ss_cep: máscara e, com lookup_url: (o endpoint do produto), o endereço nos campos ligados (fill:). O pacote não chama serviço externo.",
   "f.ss_document: CPF ou CNPJ (o alfanumérico também), DV e, com lookup_url:, a razão social embaixo; kind: :cpf/:cnpj.",
   "O erro vai pelo setCustomValidity e o ss-validate mostra embaixo do campo; a linha de retorno é aria-live."],
  [["campos", "os quatro campos", box(420, form)]])
