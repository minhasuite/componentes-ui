require "test_helper"

# v1.12.0 "Kit Brasil": as contas (ComponentesUi::Br), o QR puro (ComponentesUi::Qr), o detector do colar inteligente
# (ComponentesUi::PasteDetector, contra os exemplos de docs/v1120/exemplos.json, os mesmos do Dart e do JS), os
# formatadores ss_*, os campos f.ss_pix_key/ss_boleto/ss_cep/ss_document e os componentes Ss::PixCardComponent,
# Ss::NfeCardComponent e Ss::SmartPasteComponent.
class V1120WebTest < ComponentTest
  ROOT = Pathname(ComponentesUi::Engine.root)
  CSS = ROOT.join("app/assets/tailwind/componentes_ui")
  JS = ROOT.join("app/javascript/componentes_ui/controllers")
  PARIDADE = YAML.load_file(ROOT.join("../paridade.yml"))
  EXEMPLOS = JSON.parse(ROOT.join("../docs/v1120/exemplos.json").read)
  TODAY = Date.iso8601(EXEMPLOS["today"])
  Br = ComponentesUi::Br

  include ComponentesUi::Helpers

  def cpf(base)
    s = base.dup
    2.times { r = s.chars.each_with_index.sum { |c, i| c.to_i * (s.length + 1 - i) } % 11; s << (r < 2 ? 0 : 11 - r).to_s }
    s
  end

  def form_html(&blk)
    view = ApplicationController.new.view_context
    view.ss_form_with(url: "/x", scope: :c) { |f| blk.call(f) }
  end

  # ── paridade.yml ────────────────────────────────────────────────────
  test "paridade.yml: as peças do Kit Brasil" do
    {
      "SsPixCard" => "Ss::PixCardComponent", "SsNfeCard" => "Ss::NfeCardComponent", "SsSmartPaste" => "Ss::SmartPasteComponent",
      "SsPixKeyField" => "form:ss_pix_key", "SsBoletoField" => "form:ss_boleto", "SsCepField" => "form:ss_cep",
      "SsDocumentField" => "form:ss_document", "SsQrImage" => "helper:ss_qr_svg"
    }.each { |f, r| assert_equal r, PARIDADE["pares"][f], f }
    assert_includes PARIDADE["apis"]["SsPasteDetector"], "js:ss-smart-paste"
    assert_equal({}, PARIDADE["divida"])
    assert_equal({}, PARIDADE["divida_app"])
  end

  # ── CPF e CNPJ ──────────────────────────────────────────────────────
  test "CPF: muitos gerados com DV são válidos; um dígito trocado ou todos iguais, não" do
    rng = Random.new(1120)
    200.times do
      c = cpf(Array.new(9) { rng.rand(10) }.join)
      next if c.match?(/\A(\d)\1{10}\z/)

      assert Br.cpf_valid?(c), c
      assert Br.cpf_valid?(Br.format_cpf(c)), Br.format_cpf(c)
      ruim = c[0, 10] + ((c[10].to_i + 1) % 10).to_s
      refute Br.cpf_valid?(ruim), ruim
    end
    refute Br.cpf_valid?("111.111.111-11")
    refute Br.cpf_valid?("123")
    assert_equal "604.721.385-53", Br.format_cpf("60472138553")
    assert_equal "604.72", Br.format_cpf("60472")
  end

  test "CNPJ: numérico e alfanumérico (2026), com o DV de ASCII − 48" do
    rng = Random.new(7)
    chars = [*"0".."9", *"A".."Z"]
    200.times do
      base = Array.new(12) { chars[rng.rand(chars.size)] }.join
      j = base + Br.cnpj_dv(base)
      assert Br.cnpj_valid?(j), j
      assert Br.cnpj_valid?(Br.format_cnpj(j).downcase), j
      refute Br.cnpj_valid?(j[0, 13] + ((j[13].to_i + 1) % 10).to_s), j
    end
    assert Br.cnpj_valid?("11.222.333/0001-81")
    assert Br.cnpj_valid?("12.ABC.345/01DE-35")
    refute Br.cnpj_valid?("00.000.000/0000-00")
    assert_equal :cnpj, Br.document_kind("12ABC")
    assert_equal :cpf, Br.document_kind("123.456")
  end

  # ── Boleto ──────────────────────────────────────────────────────────
  test "boleto bancário: DVs dos campos (mod 10) e geral (mod 11), valor e vencimento pelo fator novo" do
    venc = Date.new(2026, 12, 10)
    fator = Br.boleto_factor(venc)
    assert_equal venc, Br.boleto_due(fator.to_s, today: TODAY)
    assert_equal Date.new(2025, 2, 22), Br.boleto_due("1000", today: TODAY)
    assert_equal Date.new(2025, 2, 21), Br.boleto_due("9999", today: TODAY)
    assert_nil Br.boleto_due("0000")
    rng = Random.new(3)
    50.times do
      bank = %w[001 033 104 237 341 748].sample(random: rng)
      valor = rng.rand(1..9_999_999).to_s.rjust(10, "0")
      livre = Array.new(25) { rng.rand(10) }.join
      sem_dv = bank + "9" + fator.to_s + valor + livre
      code = bank + "9" + Br.mod11_bank(sem_dv).to_s + fator.to_s + valor + livre
      line = Br.boleto_line_from_barcode(code)
      b = Br.boleto(line, today: TODAY)
      assert b.valid?, line
      assert_equal code, b.barcode
      assert_equal valor.to_i, b.amount_cents
      assert_equal venc, b.due_date
      assert_equal bank, b.bank
      assert_equal 47, line.length
      # Um dígito trocado no 1º campo: o DV do campo (módulo 10) sempre pega.
      ruim = Br.boleto(line[0, 2] + ((line[2].to_i + 1) % 10).to_s + line[3..], today: TODAY)
      refute ruim.valid?
      assert_includes ruim.errors, :field_dv
    end
  end

  test "boleto de arrecadação (48): mod 10 (6/7) e mod 11 (8/9), segmento e valor" do
    rng = Random.new(5)
    %w[6 7 8 9].each do |id|
      20.times do
        seg = %w[1 2 3 4 5 6 7 9].sample(random: rng)
        resto = Array.new(40) { rng.rand(10) }.join
        sem = "8#{seg}#{id}#{resto}"
        dv = %w[6 7].include?(id) ? Br.mod10(sem) : Br.mod11_dv(sem)
        code = "8#{seg}#{id}#{dv}#{resto}"
        line = Br.boleto_line_from_barcode(code)
        b = Br.boleto(line)
        assert b.valid?, line
        assert_equal :collection, b.kind
        assert_equal Br::SEGMENTS[seg], b.segment
        esperado = %w[6 8].include?(id) ? resto[0, 11].to_i.nonzero? : nil
        esperado ? assert_equal(esperado, b.amount_cents) : assert_nil(b.amount_cents)
        refute Br.boleto(line[0, 5] + ((line[5].to_i + 1) % 10).to_s + line[6..]).valid?
      end
    end
    assert_equal "83690000001-6 23450048123-4 45678901234-5 56789012345-6",
                 Br.format_boleto("836900000016234500481234456789012345567890123456")
  end

  # ── NF-e ────────────────────────────────────────────────────────────
  test "chave de acesso: DV mod 11, UF, mês e modelo; formatada em 11 blocos" do
    rng = Random.new(11)
    100.times do
      uf = Br::UFS.keys.sample(random: rng)
      k43 = uf + "26" + format("%02d", rng.rand(1..12)) + Array.new(14) { rng.rand(10) }.join + %w[55 65 57].sample(random: rng) +
            Array.new(21) { rng.rand(10) }.join
      key = k43 + Br.nfe_key_dv(k43).to_s
      k = Br.nfe_key(key)
      assert k.valid?, key
      assert_equal Br::UFS[uf], k.uf
      assert_equal 11, Br.format_nfe_key(key).split.size
      refute Br.nfe_key(key[0, 43] + ((key[43].to_i + 1) % 10).to_s).valid?
    end
    assert_nil Br.nfe_key("123")
  end

  # ── Pix ─────────────────────────────────────────────────────────────
  test "Pix: CRC16 (CCITT), montar e ler o copia e cola; chave por tipo" do
    assert_equal "29B1", Br.crc16("123456789")
    code = Br.pix_build(key: "loja@exemplo.com.br", name: "Loja São João", city: "São Paulo", amount_cents: 12_345, txid: "PED1")
    p = Br.pix_code(code)
    assert p.valid?
    assert_equal 12_345, p.amount_cents
    assert_equal "LOJA SAO JOAO", p.name
    assert_equal "SAO PAULO", p.city
    assert_equal :email, p.key_type
    assert_equal "PED1", p.txid
    refute Br.pix_code(code[0...-4] + "0000").valid? unless code.end_with?("0000")
    assert_nil Br.pix_code("qualquer coisa")
    { "604.721.385-53" => :cpf, "11.222.333/0001-81" => :cnpj, "+55 11 98765-4321" => :phone, "(11) 98765-4321" => :phone,
      "x@exemplo.com" => :email, "123e4567-e89b-42d3-a456-426614174000" => :random, "abc" => nil, "123" => nil }.each do |k, t|
      t ? assert_equal(t, Br.pix_key_type(k), k) : assert_nil(Br.pix_key_type(k), k)
    end
    assert_equal "+5511987654321", Br.pix_key_normalize("(11) 98765-4321")
    assert_equal "60472138553", Br.pix_key_normalize("604.721.385-53")
  end

  # ── QR ──────────────────────────────────────────────────────────────
  test "QR: versão pelo tamanho, padrões de posição, máscara e SVG com um path" do
    m = ComponentesUi::Qr.encode("HELLO")
    assert_equal 21, m.size
    # Os três quadrados de posição (7×7: borda escura, anel claro, miolo 3×3 escuro).
    [[0, 0], [14, 0], [0, 14]].each do |x, y|
      assert m[y][x] && m[y + 6][x + 6] && !m[y + 1][x + 1] && m[y + 3][x + 3], "posição #{x},#{y}"
    end
    pix = Br.pix_build(key: "loja@exemplo.com.br", name: "Loja", city: "Recife", amount_cents: 100)
    assert_operator ComponentesUi::Qr.encode(pix).size, :>=, 41
    assert_equal 177, ComponentesUi::Qr.encode("x" * 2300).size
    assert_raises(ComponentesUi::Qr::TooLong) { ComponentesUi::Qr.encode("x" * 3000) }
    svg = ComponentesUi::Qr.svg("HELLO", label: "QR")
    assert_includes svg, 'viewBox="0 0 29 29"'
    assert_includes svg, 'role="img" aria-label="QR"'
    assert_equal 1, svg.scan("<path").size
    # As matrizes de docs/v1120/exemplos.json (o SsQrCode do Flutter confere as mesmas, módulo a módulo).
    EXEMPLOS["qr"].each do |q|
      assert_equal q["rows"], ComponentesUi::Qr.encode(q["text"]).map { |r| r.map { _1 ? "1" : "0" }.join }, q["text"][0, 30]
    end
  end

  # ── Colar inteligente ───────────────────────────────────────────────
  test "PasteDetector: os exemplos de docs/v1120/exemplos.json" do
    assert_operator EXEMPLOS["exemplos"].size, :>=, 50
    EXEMPLOS["exemplos"].each do |e|
      r = ComponentesUi::PasteDetector.detect(e["input"], today: TODAY).to_h
      assert_equal e["type"], r[:type], e["input"]
      assert_equal e["valid"], r[:valid], e["input"]
      assert_equal e["value"], r[:value], e["input"]
      assert_equal e["also"], r[:also], e["input"]
      assert_equal e["fields"], r[:fields].compact, e["input"]
    end
    assert_nil ComponentesUi::PasteDetector.detect("   ")
  end

  test "PasteDetector: tipos cobertos pelos exemplos e o JS (node) dá o mesmo" do
    tipos = EXEMPLOS["exemplos"].map { _1["type"] }.uniq.sort
    assert_equal ComponentesUi::PasteDetector::TYPES.map(&:to_s).sort, tipos
    node = ENV.fetch("PATH", "").split(":").map { File.join(_1, "node") }.find { File.executable?(_1) }
    skip "sem node no PATH: rode rails/sample/test/js/ss_br_check.mjs à mão" unless node
    out = IO.popen([node, Rails.root.join("test/js/ss_br_check.mjs").to_s], err: %i[child out], &:read)
    assert $?.success?, out
  end

  test "ss_paste_summary: a frase do cartão em pt, en e es" do
    b = ComponentesUi::PasteDetector.detect("34191.09008 00012.345674 89012.345677 1 16560000012345", today: TODAY)
    assert_equal "Isso parece um boleto de R$ 123,45 com vencimento em 10/12/2026", ss_paste_summary(b)
    I18n.with_locale(:en) { assert_match(/\AThis looks like a boleto of .*123\.45 due on/, ss_paste_summary(b)) }
    I18n.with_locale(:es) { assert_match(/\AEsto parece un boleto de/, ss_paste_summary(b)) }
    ruim = ComponentesUi::PasteDetector.detect("123.456.789-00")
    assert_equal "Parece um CPF, mas os números não conferem.", ss_paste_summary(ruim)
    assert_equal "Texto livre, 5 caracteres", ss_paste_summary(ComponentesUi::PasteDetector.detect("oi oi"))
  end

  # ── Formatadores ────────────────────────────────────────────────────
  test "ss_cpf, ss_cnpj, ss_cep, ss_phone_br, ss_boleto e ss_nfe_key" do
    assert_equal "604.721.385-53", ss_cpf("60472138553")
    assert_equal "12.ABC.345/01DE-35", ss_cnpj("12abc34501de35")
    assert_equal "01310-100", ss_cep("01310100")
    assert_equal "(11) 98765-4321", ss_phone_br("11987654321")
    assert_equal "+55 (11) 98765-4321", ss_phone_br("+5511987654321")
    assert_equal "(21) 3456-7890", ss_phone_br("2134567890")
    assert_equal "34191.09008 00012.345674 89012.345677 1 16560000012345", ss_boleto("34191090080001234567489012345677116560000012345")
    assert_equal 11, ss_nfe_key("1" * 44).split.size
  end

  # ── Componentes ─────────────────────────────────────────────────────
  test "PixCard: QR do copia e cola, valor e recebedor lidos, contagem, copiar e os três estados" do
    code = Br.pix_build(key: "loja@exemplo.com.br", name: "Loja Exemplo", city: "Recife", amount_cents: 12_345)
    render_inline(Ss::PixCardComponent.new(code:, expires_at: 10.minutes.from_now))
    assert_selector "article.ss-card.ss-pix[data-state=waiting][data-controller=ss-countdown]"
    assert_selector ".ss-pix-qr[role=img][aria-label='QR Code do Pix'] svg.ss-qr-svg path"
    assert_selector ".ss-pix-amount", text: "123,45"
    assert_text "Recebedor: LOJA EXEMPLO"
    assert_selector "[data-ss-countdown-target=clock]", text: /\A(10:00|09:5\d)\z/
    assert_selector ".ss-pix-code[data-controller=ss-copy][data-ss-copy-done-value='Código copiado'] input[readonly][value='#{code}']"
    assert_selector "button.ss-pix-copy[data-action='ss-copy#copy']", text: "Copiar código"
    assert_selector ".ss-pix-status[role=status] .ss-pix-when-waiting", text: "Aguardando pagamento"
    render_inline(Ss::PixCardComponent.new(code:, status: :paid))
    assert_selector ".ss-pix[data-state=paid] .ss-pix-check svg"
    assert_no_selector "[data-controller=ss-countdown]"
    render_inline(Ss::PixCardComponent.new(code:, expires_at: 1.minute.ago))
    assert_selector ".ss-pix[data-state=expired]"
    render_inline(Ss::PixCardComponent.new(code:, status: :expired, regenerate_href: "/nova"))
    assert_selector "form.ss-pix-regen[action='/nova'] button", text: "Gerar outro código"
    render_inline(Ss::PixCardComponent.new(code: "000201x", amount_cents: nil, hint: false))
    assert_text "Valor livre"
    assert_no_selector ".ss-pix-hint"
    I18n.with_locale(:en) do
      render_inline(Ss::PixCardComponent.new(code:))
      assert_text "Copy code"
    end
  end

  test "NfeCard: chave em blocos, copiar, DV, emitente, CNPJ da chave, valor, situação e QR" do
    k43 = "3526111122233300018165002000000789187654321"
    key = k43 + Br.nfe_key_dv(k43).to_s
    render_inline(Ss::NfeCardComponent.new(access_key: key, issuer: "Mercado Exemplo", issued_at: Date.new(2026, 11, 26),
                                           amount_cents: 8_990, status: :authorized, qr_url: "https://exemplo.gov.br/q?p=#{key}", open_href: "/consulta"))
    assert_selector "article.ss-nfe[data-valid=true] .ss-nfe-title", text: "NFC-e"
    assert_text "Nº 789 · série 2"
    assert_selector ".ss-nfe-key p.num", text: Br.format_nfe_key(key)
    assert_selector ".ss-nfe-actions[data-ss-copy-text-value='#{key}'] button", text: "Copiar chave"
    assert_selector "dd.num", text: "11.222.333/0001-81"
    assert_selector "dd.num", text: "26/11/2026"
    assert_selector ".ss-badge-success", text: "Autorizada"
    assert_selector ".ss-nfe-qr[role=img] svg"
    assert_selector "a[href='/consulta'][target=_blank][rel=noopener]", text: "Consultar na Sefaz"
    assert_no_selector ".ss-nfe-invalid"
    render_inline(Ss::NfeCardComponent.new(access_key: key[0, 43] + ((key[43].to_i + 1) % 10).to_s, status: :canceled))
    assert_selector ".ss-nfe[data-valid=false] .ss-nfe-invalid[role=status]"
    assert_selector ".ss-badge-danger", text: "Cancelada"
  end

  test "SmartPaste: cartão do servidor igual ao do JS, ações do tipo e do also, form com token" do
    render_inline(Ss::SmartPasteComponent.new(value: "34191.09008 00012.345674 89012.345677 1 16560000012345", today: TODAY, actions: {
                                                boleto: [{ label: "Pagar", href: "/pagar?l=%{value}", primary: true, icon: "cash" },
                                                         { label: "Agendar", href: "/agendar", method: :post }],
                                                pix_key: [{ label: "Enviar Pix", href: "/pix" }]
                                              }))
    assert_selector ".ss-smart-paste[data-controller=ss-smart-paste][data-ss-smart-paste-today-value='2026-11-27']"
    assert_selector "textarea.ss-input[data-ss-smart-paste-target=input][data-action='input->ss-smart-paste#detect']"
    assert_selector ".ss-smart-paste-result[aria-live=polite] .ss-paste-card[data-type=boleto][data-valid=true]"
    assert_selector ".ss-paste-summary", text: "Isso parece um boleto de R$ 123,45 com vencimento em 10/12/2026"
    assert_selector ".ss-paste-detail.num", text: "34191.09008"
    assert_selector ".ss-paste-actions[role=group] a.ss-btn-primary[href='/pagar?l=34191090080001234567489012345677116560000012345'] svg"
    assert_selector "form.ss-paste-form[action='/agendar'][method=post] input[name='paste[type]'][value=boleto]", visible: :all
    assert_no_selector "a", text: "Enviar Pix"
    texts = JSON.parse(page.find(".ss-smart-paste")["data-ss-smart-paste-texts-value"])
    assert_equal "Isso parece um boleto de %{amount} com vencimento em %{date}", texts["summary"]["boleto"]
    icons = JSON.parse(page.find(".ss-smart-paste")["data-ss-smart-paste-icons-value"])
    assert icons.key?("action:cash") && icons.key?("invalid")

    render_inline(Ss::SmartPasteComponent.new(value: "604.721.385-53", actions: { pix_key: [{ label: "Enviar Pix", href: "/pix" }] }))
    assert_selector ".ss-paste-card[data-type=cpf] .ss-paste-also", text: "Chave Pix · CPF"
    assert_selector "a", text: "Enviar Pix"
    render_inline(Ss::SmartPasteComponent.new)
    assert_selector ".ss-smart-paste-empty", text: "Cole algo e a gente diz o que é."
  end

  test "f.ss_pix_key, f.ss_boleto, f.ss_cep e f.ss_document: o controller no .ss-field e a linha de retorno" do
    html = form_html do |f|
      f.ss_pix_key(:chave) + f.ss_boleto(:linha) +
        f.ss_cep(:cep, lookup_url: "/cep/%{cep}", fill: { street: "c_rua" }) + f.ss_document(:doc, kind: :cnpj, lookup_url: "/cnpj/%{cnpj}")
    end
    doc = Capybara.string(html.to_s)
    assert doc.has_css?(".ss-field[data-controller=ss-pix-key] input#c_chave[data-ss-pix-key-target=input][data-action~='input->ss-pix-key#check']")
    assert doc.has_css?(".ss-field[data-controller=ss-pix-key] small.ss-br-feedback[aria-live=polite][data-ss-pix-key-target=out]", visible: :all)
    assert doc.has_css?("label[for=c_chave]", text: "Chave Pix")
    assert doc.has_css?(".ss-field[data-controller=ss-boleto] input.ss-input.num[inputmode=numeric]")
    assert doc.has_css?(".ss-field[data-controller=ss-cep][data-ss-cep-url-value='/cep/%{cep}'] input[data-controller=ss-mask][data-ss-mask-kind-value=cep]")
    assert_equal({ "street" => "c_rua" }, JSON.parse(doc.find(".ss-field[data-controller=ss-cep]")["data-ss-cep-fill-value"]))
    assert doc.has_css?(".ss-field[data-controller=ss-document][data-ss-document-kind-value=cnpj] input[data-ss-mask-kind-value=document]")
    assert doc.has_css?("label", text: "CNPJ")
    texts = JSON.parse(doc.find(".ss-field[data-controller=ss-pix-key]")["data-ss-pix-key-texts-value"])
    assert_equal "CPF", texts["types"]["cpf"]
  end

  test "JS e CSS: os controllers existem, importam o ss_br e o CSS usa os tokens de movimento" do
    %w[ss_br ss_smart_paste_controller ss_pix_key_controller ss_boleto_controller ss_cep_controller ss_document_controller].each do |f|
      assert JS.join("#{f}.js").exist?, f
    end
    %w[ss_smart_paste ss_pix_key ss_boleto ss_cep ss_document].each do |c|
      assert_includes JS.join("#{c}_controller.js").read, 'from "componentes_ui/controllers/ss_br"', c
    end
    css = CSS.join("v1120_web.css").read
    assert_includes CSS.join("engine.css").read, '@import "./v1120_web.css";'
    assert_includes css, "var(--ss-dur-long)"
    assert_includes css, "prefers-reduced-motion"
    assert_includes css, "var(--ss-target"
    refute_match(/transition[^;]*\d+m?s\b/, css.gsub(/var\([^)]*\)/, ""))
  end

  test "vitrine: a página da v1.12 está em Novidades, em Comércio e em Formulários" do
    novas = VitrineController.paginas.select { _1[:grupos].include?(VitrineController::GRUPO_NOVIDADES) }
    assert_equal ["pecas_v1120"], novas.map { _1[:slug] }
    assert_equal "1.12", VitrineController::NOVIDADES
    assert_equal ["Comércio e finanças", "Formulários e entrada", VitrineController::GRUPO_NOVIDADES], novas.first[:grupos]
  end

  test "idiomas: as chaves br.* iguais nos três" do
    pt = I18n.t("componentes_ui.br", locale: :"pt-BR")
    %i[en es].each do |l|
      outro = I18n.t("componentes_ui.br", locale: l)
      assert_equal pt.keys.sort, outro.keys.sort, l
      assert_equal pt[:paste_summary].keys.sort, outro[:paste_summary].keys.sort, l
    end
  end
end
