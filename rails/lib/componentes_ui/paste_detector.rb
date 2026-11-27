require "date"
require "componentes_ui/br"

module ComponentesUi
  # v1.12.0: o que foi colado é o quê? Puro e testável (par do SsPasteDetector do Flutter e do ssDetect do
  # ss_br.js, o retorno ao vivo do Ss::SmartPasteComponent). Os três seguem a mesma ordem e devolvem as mesmas
  # chaves; os exemplos de docs/v1120/exemplos.json passam nos três.
  #
  #   PasteDetector.detect("23793.38128 60000.000003 …")
  #   # => #<Match type=:boleto, value="2379338128…", valid=true, fields={ amount_cents: 12345, due_date: "2026-12-10", … }>
  #
  # Tipos, na ordem em que são tentados: :pix (copia e cola, BR Code), :url (com a chave da NFC-e dentro vira
  # :nfe), :date, os só de números (:boleto 47/48, :nfe ou código de barras 44, :cnpj 14, :cpf ou :phone 11,
  # :phone 10, :cep 8), :phone (+55…), :email, :pix_key (aleatória), :cnpj alfanumérico, :money, :url (domínio
  # solto) e :text. valid diz se o dígito verificador (ou o CRC, ou a data) confere. also: outros tipos que o
  # mesmo valor também é (CPF, CNPJ, telefone e e-mail válidos também são chave Pix: also = [:pix_key]).
  module PasteDetector
    TYPES = %i[pix pix_key boleto nfe cpf cnpj cep phone email url money date text].freeze

    Match = Struct.new(:type, :text, :value, :valid, :fields, :also, keyword_init: true) do
      def valid? = valid

      # Os tipos para procurar ações: o principal e os do also.
      def types = [type, *also]

      def to_h = { type: type.to_s, value:, valid:, fields: fields.transform_keys(&:to_s), also: also.map(&:to_s) }
    end

    URL = %r{\Ahttps?://[^\s/$.?#][^\s]*\z}i
    DOMAIN = %r{\A(?:www\.)?[a-z0-9](?:[a-z0-9-]*[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]*[a-z0-9])?)*\.[a-z]{2,}(?:/\S*)?\z}i
    DATE_BR = %r{\A(\d{1,2})/(\d{1,2})(?:/(\d{2}|\d{4}))?\z}
    DATE_ISO = /\A(\d{4})-(\d{2})-(\d{2})\z/
    NUMERIC = %r{\A[\d\s.\-/()]+\z}
    MONEY = /\A(-)?\s*(R\$\s*)?(-)?(\d{1,3}(?:\.\d{3})+|\d+)(?:,(\d{1,2}))?\z/i
    CEP = /\A\d{2}\.?\d{3}-?\d{3}\z/
    CNPJ_ALNUM = %r{\A[0-9A-Z]{2}\.?[0-9A-Z]{3}\.?[0-9A-Z]{3}/?[0-9A-Z]{4}-?\d{2}\z}i

    module_function

    # nil para texto vazio.
    def detect(text, today: Date.today)
      t = text.to_s.gsub(/\r\n?/, "\n").strip
      return nil if t.empty?

      single = t.gsub(/\s+/, " ")
      pix(t) || url(single) || date(single, today) || numeric(single, today) || plus_phone(single) || email(single) ||
        evp(single) || cnpj_alnum(single) || money(single) || domain(single) ||
        m(:text, t, t, true, { length: t.length, lines: t.count("\n") + 1 })
    end

    def m(type, text, value, valid, fields = {}, also = [])
      Match.new(type:, text:, value:, valid:, fields:, also:)
    end

    def pix(t)
      p = Br.pix_code(t.delete("\n"))
      return nil unless p

      m(:pix, t, p.payload, p.valid, { amount_cents: p.amount_cents, name: p.name, city: p.city, key: p.key,
                                       key_type: p.key_type&.to_s, txid: p.txid, dynamic: p.dynamic })
    end

    def url(t)
      return nil unless t.match?(URL)

      key = t.scan(/\d{44}/).find { |k| Br.nfe_key(k)&.valid? }
      return nfe_match(t, Br.nfe_key(key), url: t) if key

      host = t.sub(%r{\Ahttps?://}i, "").split(%r{[/?#:]}).first.to_s.downcase.sub(/\Awww\./, "")
      m(:url, t, t, true, { domain: host })
    end

    def nfe_match(t, k, url: nil)
      f = { uf: k.uf, model: k.model, model_name: k.model_name, cnpj: k.cnpj, series: k.series, number: k.number,
            year: k.year, month: k.month }
      f[:url] = url if url
      m(:nfe, t, k.key, k.valid?, f)
    end

    def date(t, today)
      y = mo = d = nil
      if (x = t.match(DATE_BR))
        d, mo = x[1].to_i, x[2].to_i
        y = x[3] ? x[3].to_i : today.year
        y += 2000 if x[3]&.length == 2
      elsif (x = t.match(DATE_ISO))
        y, mo, d = x[1].to_i, x[2].to_i, x[3].to_i
      else
        return nil
      end
      return nil unless Date.valid_date?(y, mo, d)

      iso = Date.new(y, mo, d).iso8601
      m(:date, t, iso, true, { date: iso })
    end

    def numeric(t, today)
      return nil unless t.match?(NUMERIC)

      d = Br.digits(t)
      case d.length
      when 47, 48 then boleto_match(t, Br.boleto(d, today:)) if d.length == 47 || d.start_with?("8")
      when 44
        k = Br.nfe_key(d)
        b = Br.boleto(d, today:)
        if k.valid? then nfe_match(t, k)
        elsif b&.valid? then boleto_match(t, b)
        elsif d.start_with?("8") && b then boleto_match(t, b)
        else nfe_match(t, k)
        end
      when 14 then doc(:cnpj, t, d)
      when 11
        if Br.cpf_valid?(d) then doc(:cpf, t, d)
        elsif Br.phone_valid?(d) then phone(t)
        elsif t.include?("(") then phone(t, valid: false)
        else doc(:cpf, t, d)
        end
      when 10, 12, 13 then (Br.phone_valid?(t) || t.include?("(") ? phone(t, valid: Br.phone_valid?(t)) : nil)
      when 8 then (t.match?(CEP) ? m(:cep, t, d, Br.cep_valid?(d), { display: Br.format_cep(d) }) : nil)
      end
    end

    def boleto_match(t, b)
      return nil unless b

      m(:boleto, t, b.line, b.valid?, { kind: b.kind.to_s, amount_cents: b.amount_cents, due_date: b.due_date&.iso8601,
                                        bank: b.bank, segment: b.segment&.to_s, barcode: b.barcode,
                                        display: Br.format_boleto(b.line) })
    end

    def doc(type, t, raw)
      ok = type == :cpf ? Br.cpf_valid?(raw) : Br.cnpj_valid?(raw)
      display = type == :cpf ? Br.format_cpf(raw) : Br.format_cnpj(raw)
      m(type, t, raw, ok, { display: }, ok ? [:pix_key] : [])
    end

    def phone(t, valid: true)
      e164 = Br.phone_e164(t)
      return m(:phone, t, Br.digits(t), false, { display: t }) if e164.nil? || !valid

      m(:phone, t, e164, true, { display: Br.format_phone(e164) }, [:pix_key])
    end

    def plus_phone(t)
      return nil unless t.start_with?("+") && t[1..].match?(/\A[\d\s\-()]+\z/)

      Br.phone_valid?(t) ? phone(t) : m(:phone, t, Br.digits(t), false, { display: t })
    end

    def email(t)
      return nil unless t.match?(/\A[^@\s]+@[^@\s]+\z/)

      ok = Br.email_valid?(t)
      m(:email, t, t.downcase, ok, {}, ok ? [:pix_key] : [])
    end

    def evp(t) = (m(:pix_key, t, t.downcase, true, { key_type: "random" }) if Br.evp_valid?(t))

    def cnpj_alnum(t)
      return nil unless t.match?(CNPJ_ALNUM) && t.match?(/[A-Za-z]/)

      doc(:cnpj, t, Br.alnum(t))
    end

    def money(t)
      x = t.match(MONEY)
      return nil unless x && (x[2] || x[5])

      cents = Br.digits(x[4]).to_i * 100 + x[5].to_s.ljust(2, "0").to_i
      cents = -cents if x[1] || x[3]
      m(:money, t, cents.to_s, true, { amount_cents: cents })
    end

    def domain(t)
      return nil unless t.match?(DOMAIN) && !t.match?(/\A[\d.]+\z/)

      host = t.split("/").first.downcase.sub(/\Awww\./, "")
      m(:url, t, "https://#{t}", true, { domain: host })
    end
  end
end
