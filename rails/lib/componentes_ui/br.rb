require "date"

module ComponentesUi
  # v1.12.0 "Kit Brasil": as contas brasileiras, puras e sem rede (par do SsBr/SsBoleto/SsNfeKey/SsPixCode do
  # Flutter e do ss_br.js do Stimulus; a mesma conta nos três, conferida pelos mesmos exemplos em
  # docs/v1120/exemplos.json):
  #
  #   Br.cpf_valid?("529.982.247-25")          # dígitos verificadores (módulo 11)
  #   Br.cnpj_valid?("12.ABC.345/01DE-35")      # CNPJ numérico e o alfanumérico de 2026 (valor = código ASCII − 48)
  #   Br.boleto("23793.38128 …")               # linha digitável de 47 (bancário) ou 48 (arrecadação) dígitos
  #   Br.nfe_key("3526 1112 …")                # chave de acesso da NF-e/NFC-e (44 dígitos, DV módulo 11)
  #   Br.pix_code("000201…6304ABCD")           # Pix copia e cola (BR Code EMV, CRC16)
  #   Br.pix_key_type("+5511987654321")        # :cpf, :cnpj, :phone, :email, :random
  #
  # Nada aqui chama serviço externo: buscar CEP ou CNPJ é do produto (callback/endpoint).
  module Br
    module_function

    # DDDs em uso (Anatel).
    DDDS = %w[11 12 13 14 15 16 17 18 19 21 22 24 27 28 31 32 33 34 35 37 38 41 42 43 44 45 46 47 48 49 51 53 54 55
              61 62 63 64 65 66 67 68 69 71 73 74 75 77 79 81 82 83 84 85 86 87 88 89 91 92 93 94 95 96 97 98 99].freeze

    # Código IBGE da UF (os 2 primeiros dígitos da chave da NF-e).
    UFS = { "11" => "RO", "12" => "AC", "13" => "AM", "14" => "RR", "15" => "PA", "16" => "AP", "17" => "TO", "21" => "MA",
            "22" => "PI", "23" => "CE", "24" => "RN", "25" => "PB", "26" => "PE", "27" => "AL", "28" => "SE", "29" => "BA",
            "31" => "MG", "32" => "ES", "33" => "RJ", "35" => "SP", "41" => "PR", "42" => "SC", "43" => "RS", "50" => "MS",
            "51" => "MT", "52" => "GO", "53" => "DF" }.freeze

    # Modelo do documento na chave de acesso.
    MODELS = { "55" => "NF-e", "65" => "NFC-e", "57" => "CT-e", "58" => "MDF-e", "59" => "CF-e SAT", "67" => "CT-e OS" }.freeze

    # Segmento do boleto de arrecadação (2º dígito).
    SEGMENTS = { "1" => :prefeitura, "2" => :saneamento, "3" => :energia, "4" => :telecom, "5" => :governo,
                 "6" => :carne, "7" => :transito, "9" => :banco }.freeze

    EMAIL = /\A[^@\s]+@[^@\s]+\.[^@\s.]{2,}\z/
    EVP = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/

    # Texto com %{x} trocado pelos valores (sem o I18n, para os moldes que o JS também usa).
    def fill(template, vars) = template.to_s.gsub(/%\{(\w+)\}/) { vars[Regexp.last_match(1).to_sym].to_s }

    def digits(text) = text.to_s.gsub(/\D/, "")

    # Só letras e dígitos, em maiúscula (o CNPJ alfanumérico).
    def alnum(text) = text.to_s.upcase.gsub(/[^0-9A-Z]/, "")

    # ── CPF e CNPJ ────────────────────────────────────────────────────
    def cpf_valid?(text)
      d = digits(text)
      return false unless d.length == 11 && !d.match?(/\A(\d)\1{10}\z/)

      dv = ->(n) { r = (0...n).sum { |i| d[i].to_i * (n + 1 - i) } % 11; r < 2 ? 0 : 11 - r }
      dv.(9) == d[9].to_i && dv.(10) == d[10].to_i
    end

    # Os 2 dígitos do CNPJ para as 12 primeiras posições (números ou letras; valor = ASCII − 48).
    def cnpj_dv(base12)
      v = base12.chars.map { |c| c.ord - 48 }
      calc = lambda do |vals|
        pesos = (2..9).cycle.take(vals.length).reverse
        r = vals.zip(pesos).sum { |a, b| a * b } % 11
        r < 2 ? 0 : 11 - r
      end
      d1 = calc.(v)
      d2 = calc.(v + [d1])
      "#{d1}#{d2}"
    end

    def cnpj_valid?(text)
      s = alnum(text)
      return false unless s.match?(/\A[0-9A-Z]{12}\d{2}\z/) && !s.match?(/\A(.)\1{13}\z/)

      cnpj_dv(s[0, 12]) == s[12, 2]
    end

    # :cpf (até 11 dígitos), :cnpj (12 ou mais, ou com letra) ou nil (vazio).
    def document_kind(text)
      s = alnum(text)
      return nil if s.empty?

      s.length > 11 || s.match?(/[A-Z]/) ? :cnpj : :cpf
    end

    def document_valid?(text) = document_kind(text) == :cnpj ? cnpj_valid?(text) : cpf_valid?(text)

    # ── Formatadores (texto pronto; parcial quando incompleto) ─────────
    def join(raw, cuts, seps) = raw.chars.each_with_index.map { |ch, i| (k = cuts.index(i)) ? "#{seps[k]}#{ch}" : ch }.join

    def format_cpf(text) = join(digits(text)[0, 11], [3, 6, 9], [".", ".", "-"])

    def format_cnpj(text)
      s = alnum(text)[0, 14]
      s = s[0, 12] + s[12..].to_s.gsub(/\D/, "")
      join(s, [2, 5, 8, 12], [".", ".", "/", "-"])
    end

    def format_document(text) = document_kind(text) == :cnpj ? format_cnpj(text) : format_cpf(text)

    def format_cep(text) = join(digits(text)[0, 8], [5], ["-"])

    # (11) 98765-4321, (11) 3456-7890; com +55, o DDI na frente: +55 (11) 98765-4321.
    def format_phone(text)
      raw = digits(text)
      ddi = raw.length > 11 && raw.start_with?("55")
      raw = raw[2..] if ddi
      raw = raw[0, 11]
      return "" if raw.empty?

      out = if raw.length <= 2 then "(#{raw}"
            else "(#{raw[0, 2]}) #{join(raw[2..], [raw.length <= 10 ? 4 : 5], ["-"])}"
            end
      ddi ? "+55 #{out}" : out
    end

    # Linha digitável: 00000.00000 00000.000000 00000.000000 0 00000000000000 (47) ou
    # 00000000000-0 00000000000-0 00000000000-0 00000000000-0 (48). 44 dígitos (código de barras) viram a linha.
    def format_boleto(text)
      d = digits(text)
      d = boleto_line_from_barcode(d) || d if d.length == 44
      if d.start_with?("8")
        d[0, 48].scan(/.{1,12}/).map { |b| b.length == 12 ? "#{b[0, 11]}-#{b[11]}" : b }.join(" ")
      else
        d = d[0, 47]
        join(d, [5, 10, 15, 21, 26, 32, 33], [".", " ", ".", " ", ".", " ", " "])
      end
    end

    # Chave de acesso em 11 blocos de 4: 3526 1112 3456 7800 0195 5500 1000 0012 3410 0000 1234.
    def format_nfe_key(text) = digits(text)[0, 44].scan(/.{1,4}/).join(" ")

    # ── CEP, telefone, e-mail e chave Pix ──────────────────────────────
    def cep_valid?(text) = (d = digits(text)).length == 8 && d != "00000000"

    # Os 10 ou 11 dígitos nacionais (sem o 55), ou nil se não for telefone brasileiro.
    def phone_national(text)
      raw = text.to_s.strip
      d = digits(raw)
      d = d[2..] if (raw.start_with?("+55") || raw.start_with?("55")) && d.length > 11
      d = d[1..] if d.length == 12 && d.start_with?("0") # 0 de longa distância
      return nil unless [10, 11].include?(d.length) && DDDS.include?(d[0, 2])
      return nil if d.length == 11 && d[2] != "9"
      return nil if d.length == 10 && !d[2].match?(/[2-5]/)

      d
    end

    def phone_valid?(text) = !phone_national(text).nil?

    # +5511987654321 (o formato da chave Pix de telefone).
    def phone_e164(text) = (n = phone_national(text)) && "+55#{n}"

    def email_valid?(text) = text.to_s.strip.match?(EMAIL)

    def evp_valid?(text) = text.to_s.strip.match?(EVP)

    # Tipo da chave Pix: :cpf, :cnpj, :phone, :email, :random (EVP) ou nil. 11 dígitos com CPF válido é CPF; senão,
    # se for celular com DDD, telefone. "+55…" é sempre telefone.
    def pix_key_type(text)
      t = text.to_s.strip
      return nil if t.empty?
      return :email if t.include?("@")
      return :random if t.match?(EVP)
      return (phone_valid?(t) ? :phone : nil) if t.start_with?("+")
      return nil if t.match?(/[^\d.\-\/\s()A-Za-z]/)

      a = alnum(t)
      d = digits(t)
      if t.match?(/[A-Za-z]/)
        return cnpj_valid?(t) ? :cnpj : nil
      end
      return :cpf if d.length == 11 && cpf_valid?(d)
      return :cnpj if d.length == 14 && cnpj_valid?(d)
      return :phone if phone_valid?(t) && a == d

      nil
    end

    # A chave como vai no Pix: CPF/CNPJ só dígitos (letras do CNPJ em maiúscula), +55… no telefone, e-mail e
    # aleatória em minúscula.
    def pix_key_normalize(text, type = pix_key_type(text))
      case type&.to_sym
      when :cpf then digits(text)
      when :cnpj then alnum(text)
      when :phone then phone_e164(text)
      when :email, :random then text.to_s.strip.downcase
      end
    end

    # A chave formatada para mostrar (CPF e CNPJ com pontuação, telefone com DDD).
    def pix_key_display(text, type = pix_key_type(text))
      case type&.to_sym
      when :cpf then format_cpf(text)
      when :cnpj then format_cnpj(text)
      when :phone then format_phone(phone_e164(text))
      else text.to_s.strip
      end
    end

    # ── Módulos 10 e 11 (boleto e chave de acesso) ────────────────────
    def mod10(num)
      sum = num.chars.reverse.each_with_index.sum do |c, i|
        p = c.to_i * (i.even? ? 2 : 1)
        p > 9 ? p - 9 : p
      end
      (10 - sum % 10) % 10
    end

    def mod11_sum(num) = num.chars.reverse.each_with_index.sum { |c, i| c.to_i * (2 + i % 8) }

    # DV geral do boleto bancário: 0, 10 e 11 viram 1.
    def mod11_bank(num)
      dv = 11 - mod11_sum(num) % 11
      [0, 10, 11].include?(dv) ? 1 : dv
    end

    # DV do boleto de arrecadação e da chave de acesso: resto 0 ou 1 vira 0.
    def mod11_dv(num)
      r = mod11_sum(num) % 11
      r < 2 ? 0 : 11 - r
    end

    # ── Boleto ───────────────────────────────────────────────────────
    # kind: :bank (47) ou :collection (48, arrecadação: concessionária, tributo). amount_cents/due_date nil
    # quando o boleto não traz (valor zero, fator 0000). errors: [:length, :field_dv, :general_dv].
    Boleto = Struct.new(:kind, :line, :barcode, :valid, :amount_cents, :due_date, :bank, :segment, :errors, keyword_init: true) do
      def valid? = valid
      def display = Br.format_boleto(line)
    end

    BASE_OLD = Date.new(1997, 10, 7)
    BASE_NEW = Date.new(2025, 2, 22) # fator 1000 de novo (Febraban, depois do 9999 de 21/02/2025)

    # Data do fator de vencimento (4 dígitos), no ciclo mais perto de [today]; 0 = sem vencimento.
    def boleto_due(fator, today: Date.today)
      f = fator.to_i
      return nil if f.zero?

      old = BASE_OLD + f
      return old if f < 1000

      novo = BASE_NEW + (f - 1000)
      (novo - today).abs < (old - today).abs ? novo : old
    end

    # Fator de vencimento de uma data (o inverso, para montar exemplos e o código).
    def boleto_factor(date)
      f = (date - BASE_OLD).to_i
      f > 9999 ? (date - BASE_NEW).to_i + 1000 : f
    end

    # Código de barras (44) → linha digitável (47 ou 48); nil se não for código de boleto válido no tamanho.
    def boleto_line_from_barcode(code)
      c = digits(code)
      return nil unless c.length == 44

      if c.start_with?("8")
        m = %w[6 7].include?(c[2]) ? method(:mod10) : method(:mod11_dv)
        c.scan(/.{11}/).map { |b| b + m.(b).to_s }.join
      else
        f1 = c[0, 4] + c[19, 5]
        f2 = c[24, 10]
        f3 = c[34, 10]
        "#{f1}#{mod10(f1)}#{f2}#{mod10(f2)}#{f3}#{mod10(f3)}#{c[4]}#{c[5, 14]}"
      end
    end

    # Linha digitável (47 ou 48 dígitos, com ou sem pontuação) ou código de barras (44) → Boleto; nil se o
    # tamanho não é de boleto.
    def boleto(text, today: Date.today)
      d = digits(text)
      d = boleto_line_from_barcode(d) if d.length == 44
      return nil if d.nil?

      if d.length == 48 && d.start_with?("8") then boleto_collection(d)
      elsif d.length == 47 then boleto_bank(d, today:)
      end
    end

    def boleto_bank(d, today: Date.today)
      errors = []
      fields = [[d[0, 9], d[9]], [d[10, 10], d[20]], [d[21, 10], d[31]]]
      errors << :field_dv unless fields.all? { |f, dv| mod10(f).to_s == dv }
      barcode = d[0, 4] + d[32] + d[33, 14] + d[4, 5] + d[10, 10] + d[21, 10]
      errors << :general_dv unless mod11_bank(barcode[0, 4] + barcode[5..]).to_s == barcode[4]
      valor = d[37, 10].to_i
      Boleto.new(kind: :bank, line: d, barcode:, valid: errors.empty?, amount_cents: (valor.zero? ? nil : valor),
                 due_date: boleto_due(d[33, 4], today:), bank: d[0, 3], segment: nil, errors:)
    end

    def boleto_collection(d)
      errors = []
      blocks = d.scan(/.{12}/)
      barcode = blocks.map { |b| b[0, 11] }.join
      m = %w[6 7].include?(barcode[2]) ? method(:mod10) : method(:mod11_dv)
      errors << :value_id unless %w[6 7 8 9].include?(barcode[2])
      errors << :field_dv unless blocks.all? { |b| m.(b[0, 11]).to_s == b[11] }
      errors << :general_dv unless m.(barcode[0, 3] + barcode[4..]).to_s == barcode[3]
      valor = %w[6 8].include?(barcode[2]) ? barcode[4, 11].to_i : 0
      Boleto.new(kind: :collection, line: d, barcode:, valid: errors.empty?, amount_cents: (valor.zero? ? nil : valor),
                 due_date: nil, bank: nil, segment: SEGMENTS[barcode[1]], errors:)
    end

    # ── Chave de acesso (NF-e, NFC-e, CT-e) ───────────────────────────
    NfeKey = Struct.new(:key, :valid, :uf, :uf_code, :year, :month, :cnpj, :model, :model_name, :series, :number,
                        :emission, :code, :dv, keyword_init: true) do
      def valid? = valid
      def display = Br.format_nfe_key(key)
    end

    # 44 dígitos (com ou sem espaço) → NfeKey (valid: DV, UF, mês e modelo conferem); nil se não tiver 44 dígitos.
    def nfe_key(text)
      k = digits(text)
      return nil unless k.length == 44

      uf = UFS[k[0, 2]]
      mes = k[4, 2].to_i
      ok = !uf.nil? && mes.between?(1, 12) && mod11_dv(k[0, 43]).to_s == k[43] && MODELS.key?(k[20, 2])
      NfeKey.new(key: k, valid: ok, uf:, uf_code: k[0, 2], year: 2000 + k[2, 2].to_i, month: mes, cnpj: k[6, 14],
                 model: k[20, 2], model_name: MODELS[k[20, 2]], series: k[22, 3].to_i, number: k[25, 9].to_i,
                 emission: k[34], code: k[35, 8], dv: k[43])
    end

    # O DV (44º dígito) para 43 dígitos: para montar exemplos.
    def nfe_key_dv(key43) = mod11_dv(digits(key43)[0, 43])

    # ── Pix copia e cola (BR Code EMV) ────────────────────────────────
    # dynamic: QR dinâmico (01 = 12, ou URL no 26.25). amount_cents nil = o pagador digita o valor.
    PixCode = Struct.new(:payload, :valid, :key, :key_type, :name, :city, :amount_cents, :txid, :description, :url,
                         :dynamic, :errors, keyword_init: true) do
      def valid? = valid
    end

    # CRC16-CCITT (polinômio 0x1021, início 0xFFFF), 4 dígitos hexadecimais em maiúscula.
    def crc16(text)
      crc = 0xFFFF
      text.to_s.each_byte do |b|
        crc ^= b << 8
        8.times { crc = (crc & 0x8000).zero? ? (crc << 1) : ((crc << 1) ^ 0x1021); crc &= 0xFFFF }
      end
      format("%04X", crc)
    end

    # TLV do EMV: { "00" => "01", "26" => "0014br.gov…" }; nil se quebrado.
    def emv_fields(text)
      out = {}
      i = 0
      while i < text.length
        id = text[i, 2]
        len = text[i + 2, 2]
        return nil unless id&.match?(/\A\d\d\z/) && len&.match?(/\A\d\d\z/)

        v = text[i + 4, len.to_i]
        return nil if v.nil? || v.length != len.to_i

        out[id] = v
        i += 4 + len.to_i
      end
      out
    end

    # "000201…6304ABCD" → PixCode (valid: CRC confere e tem a chave ou a URL); nil se não for BR Code do Pix.
    def pix_code(text)
      t = text.to_s.strip.gsub(/[\r\n]/, "")
      return nil unless t.start_with?("000201") && t.downcase.include?("br.gov.bcb.pix")

      f = emv_fields(t)
      return PixCode.new(payload: t, valid: false, errors: [:format], dynamic: false) if f.nil?

      mai = emv_fields(f["26"].to_s) || {}
      extra = emv_fields(f["62"].to_s) || {}
      errors = []
      errors << :crc unless f["63"].to_s.upcase == crc16(t[0...-4])
      key = mai["01"]
      errors << :key if key.nil? && mai["25"].nil?
      valor = amount_cents(f["54"])
      PixCode.new(payload: t, valid: errors.empty?, key:, key_type: (key && pix_key_type(key)), name: f["59"],
                  city: f["60"], amount_cents: valor, txid: extra["05"], description: mai["02"], url: mai["25"],
                  dynamic: f["01"] == "12" || !mai["25"].nil?, errors:)
    end

    # "123.45" (o campo 54 do BR Code) → 12345; nil se vazio ou fora do formato.
    def amount_cents(text)
      m = text.to_s.strip.match(/\A(\d+)(?:\.(\d{1,2}))?\z/)
      m && (m[1].to_i * 100 + m[2].to_s.ljust(2, "0").to_i)
    end

    ACCENTS = { "ÁÀÂÃÄ" => "A", "ÉÈÊË" => "E", "ÍÌÎÏ" => "I", "ÓÒÔÕÖ" => "O", "ÚÙÛÜ" => "U", "Ç" => "C", "Ñ" => "N" }.freeze

    # Sem acento (o nome e a cidade do BR Code são ASCII): "São Paulo" → "Sao Paulo".
    def ascii(text)
      s = text.to_s.dup
      ACCENTS.each { |from, to| s = s.tr(from + from.downcase, to * from.length + to.downcase * from.length) }
      s
    end

    # Monta o copia e cola estático (para exemplo, teste e o Pix de balcão sem PSP): chave, nome (até 25),
    # cidade (até 15), valor em centavos (nil = livre) e o txid ("***" = sem).
    def pix_build(key:, name:, city:, amount_cents: nil, txid: "***", description: nil)
      tlv = ->(id, v) { format("%s%02d%s", id, v.length, v) }
      plain = ->(s, n) { ascii(s).upcase.gsub(/[^A-Z0-9 ]/, "")[0, n] }
      mai = tlv.("00", "br.gov.bcb.pix") + tlv.("01", key.to_s) + (description ? tlv.("02", description.to_s[0, 40]) : "")
      body = tlv.("00", "01") + tlv.("26", mai) + tlv.("52", "0000") + tlv.("53", "986") +
             (amount_cents ? tlv.("54", format("%.2f", amount_cents / 100.0)) : "") + tlv.("58", "BR") +
             tlv.("59", plain.(name, 25)) + tlv.("60", plain.(city, 15)) + tlv.("62", tlv.("05", txid.to_s[0, 25])) + "6304"
      body + crc16(body)
    end
  end
end
