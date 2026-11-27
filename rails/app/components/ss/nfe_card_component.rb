module Ss
  # v1.12.0 "Kit Brasil" (par do SsNfeCard): a nota fiscal num cartão. Da chave de acesso (44 dígitos) saem o
  # modelo (NF-e, NFC-e, CT-e), o número, a série e o CNPJ do emitente quando o produto não passa; o DV é conferido
  # (errado: aviso no cartão). A chave vai em 11 blocos de 4 com "Copiar chave" (ss-copy). Com qr_url: (a URL do
  # QR da NFC-e/consulta), o QR (ComponentesUi::Qr) fica ao lado da chave; open_href: põe "Consultar na Sefaz".
  #
  #   render Ss::NfeCardComponent.new(access_key: nota.chave, issuer: nota.emitente, issued_at: nota.emitida_em,
  #                                   amount_cents: nota.total_cents, status: :authorized, qr_url: nota.url_qr)
  #
  # status: :authorized, :canceled, :denied ou :pending (nil tira o selo).
  class NfeCardComponent < BaseComponent
    STATUS_TONES = { authorized: "success", canceled: "danger", denied: "danger", pending: "warn" }.freeze

    attr_reader :issuer, :issued_at, :amount_cents, :qr_url, :open_href

    def initialize(access_key:, issuer: nil, issuer_cnpj: nil, issued_at: nil, amount_cents: nil, status: nil, qr_url: nil,
                   open_href: nil, **opts)
      super(**opts)
      @digits = ComponentesUi::Br.digits(access_key)
      @key = ComponentesUi::Br.nfe_key(@digits)
      @issuer = issuer
      @issuer_cnpj = issuer_cnpj
      @issued_at = issued_at
      @amount_cents = amount_cents
      @status = status&.to_sym
      @qr_url = qr_url
      @open_href = open_href
    end

    def t(key, **o) = ss_t("br.#{key}", **o)
    def digits = @digits
    def key_display = ComponentesUi::Br.format_nfe_key(@digits)
    def valid? = @key&.valid?
    def title = @key&.model_name || t("nfe_title")
    def number = @key && t("nfe_number", number: ss_number(@key.number), series: @key.series)
    def cnpj = (c = @issuer_cnpj.presence || @key&.cnpj).present? ? ComponentesUi::Br.format_cnpj(c) : nil
    def status_label = @status && t("nfe_status.#{@status}", default: @status.to_s)
    def status_tone = STATUS_TONES.fetch(@status, "muted")
    def uid = @uid ||= "ss-nfe-#{object_id}"
  end
end
