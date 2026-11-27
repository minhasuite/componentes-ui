# Gera docs/v1120/exemplos.json: os exemplos do colar inteligente (v1.12.0), com DV calculado e sem dados de pessoas
# reais, e o que o ComponentesUi::PasteDetector diz de cada um; e as matrizes do ComponentesUi::Qr para alguns textos (qr:). Os testes do Dart (SsPasteDetector), do Ruby e do
# ss_br.js (node) leem o arquivo e precisam dar o mesmo resultado.
#   ruby rails/sample/script/exemplos_v1120.rb > docs/v1120/exemplos.json
require "json"; require "date"
$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "erb"; require "componentes_ui/br"; require "componentes_ui/paste_detector"; require "componentes_ui/qr"
B = ComponentesUi::Br; P = ComponentesUi::PasteDetector
TODAY = Date.new(2026, 11, 27)
def cpf(base)
  s = base.dup
  2.times { r = s.chars.each_with_index.sum { |c, i| c.to_i * (s.length + 1 - i) } % 11; s << (r < 2 ? 0 : 11 - r).to_s }
  s
end
def cnpj(base) = base + B.cnpj_dv(base)
c1 = cpf("604721385"); c2 = cpf("390533447"); c3 = cpf("071880123")
j1 = cnpj("112223330001"); j2 = cnpj("12ABC34501DE")
def bank_line(bank, fator, valor, free)
  bc = bank + "9" + fator + valor + free
  dv = B.mod11_bank(bc)
  B.boleto_line_from_barcode(bank + "9" + dv.to_s + fator + valor + free)
end
fat = B.boleto_factor(Date.new(2026, 12, 10)).to_s.rjust(4, "0")
l1 = bank_line("341", fat, "0000012345", "1090000012345678901234567")
l2 = bank_line("001", "0000", "0000000000", "0000002345678901234567890")
bc1 = l1[0, 4] + l1[32] + l1[33, 14] + l1[4, 5] + l1[10, 10] + l1[21, 10]
def arr(seg, id, valor, rest)
  b = "8" + seg + id + valor + rest
  dv = %w[6 7].include?(id) ? B.mod10(b) : B.mod11_dv(b)
  B.boleto_line_from_barcode("8" + seg + id + dv.to_s + valor + rest)
end
a1 = arr("3", "6", "00000012345", "00481234567890123456789012345")
a2 = arr("5", "8", "00000098765", "12345678901234567890123456789")
k43 = "35" + "2611" + j1 + "55" + "001" + "000012345" + "1" + "12345678"
nfe = k43 + B.nfe_key_dv(k43).to_s
k43b = "35" + "2611" + j1 + "65" + "002" + "000000789" + "1" + "87654321"
nfce = k43b + B.nfe_key_dv(k43b).to_s
pix1 = B.pix_build(key: "loja@exemplo.com.br", name: "Loja Exemplo", city: "São Paulo", amount_cents: 12345, txid: "PEDIDO1042")
pix2 = B.pix_build(key: "+5511987654321", name: "Ana Exemplo", city: "Recife")
tlv = ->(id, v) { format("%s%02d%s", id, v.length, v) }
dyn = tlv.("00", "01") + tlv.("01", "12") + tlv.("26", tlv.("00", "br.gov.bcb.pix") + tlv.("25", "pix.exemplo.com.br/qr/v2/9d36b84f-c70b-478f-b95c-12729b90ca25")) +
      tlv.("52", "0000") + tlv.("53", "986") + tlv.("54", "89.90") + tlv.("58", "BR") + tlv.("59", "MERCADO EXEMPLO") + tlv.("60", "CURITIBA") + tlv.("62", tlv.("05", "***")) + "6304"
dyn += B.crc16(dyn)
bad_pix = pix1[0...-4] + (pix1[-4, 4] == "0000" ? "FFFF" : "0000")
flip = ->(s, i) { s[0, i] + ((s[i].to_i + 1) % 10).to_s + s[(i + 1)..] }
inputs = [
  pix1, pix2, dyn, bad_pix,
  B.format_boleto(l1), l1, B.format_boleto(l2), flip.(l1, 40), bc1,
  B.format_boleto(a1), a1, a2, flip.(a1, 5),
  nfe, B.format_nfe_key(nfe), flip.(nfe, 30),
  "https://www.nfce.fazenda.sp.gov.br/NFCeConsultaPublica/Paginas/ConsultaQRCode.aspx?p=#{nfce}|2|1|1|ABCDEF0123456789",
  B.format_cpf(c1), c2, B.format_cpf(c3), flip.(c1, 10), "111.111.111-11",
  B.format_cnpj(j1), j1, B.format_cnpj(j2), flip.(j1, 13),
  "01310-100", "01310100", "00000-000",
  "(11) 98765-4321", "+55 11 98765-4321", "11987654321", "(21) 3456-7890", "+5521934567890", "(20) 98765-4321",
  "Contato@Exemplo.com.br", "fulano@", "123e4567-e89b-42d3-a456-426614174000",
  "https://minhasuite.com/precos?plano=pro", "www.exemplo.com.br", "exemplo.com.br/loja", "minhasuite.com",
  "R$ 123,45", "1.234,56", "R$ 10", "R$1.000.000,00", "-R$ 5,00", "12,5",
  "10/12/2026", "2026-12-10", "10/12", "05/01/27", "31/02/2026",
  "Comprar pão amanhã", "123", "1.234", "  \n  Linha um\nLinha dois  "
]
out = inputs.map do |t|
  r = P.detect(t, today: TODAY)
  h = r.to_h
  { input: t, type: h[:type], valid: h[:valid], value: h[:value], also: h[:also], fields: h[:fields].compact }
end
qr = ["HELLO", "Olá, São Paulo!", pix1, "https://www.exemplo.gov.br/nfce?p=#{nfce}|2|1|1", "x" * 400].map do |t|
  { text: t, rows: ComponentesUi::Qr.encode(t).map { |r| r.map { |b| b ? "1" : "0" }.join } }
end
puts JSON.pretty_generate({ today: TODAY.iso8601, qr:, _sobre: "Exemplos do colar inteligente (v1.12.0), gerados com DV calculado e sem dados de pessoas reais. Os três detectores (Ruby ComponentesUi::PasteDetector, Dart SsPasteDetector e o ssDetect do ss_br.js) precisam dar o mesmo tipo, valid, value, also e fields.", exemplos: out })
