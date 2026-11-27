module Ss
  # v1.12.0 "Kit Brasil" (par do SsPixCard): o Pix de uma cobrança. O QR sai do próprio copia e cola
  # (ComponentesUi::Qr, SVG no servidor, sem gem) ou do qr: pronto do PSP; o valor e o recebedor, a validade com
  # contagem regressiva (ss-countdown), o "Copiar código" com retorno (ss-copy) e o estado. Só exibe: gerar a
  # cobrança e saber que pagou é do produto (troque o status: pela resposta do PSP, por Turbo Stream ou recarga).
  #
  #   render Ss::PixCardComponent.new(code: cobranca.copia_e_cola, expires_at: cobranca.expira_em)
  #   render Ss::PixCardComponent.new(code:, status: :paid)                     # o ✓ com a animação de sucesso
  #   render Ss::PixCardComponent.new(code:, status: :expired, regenerate_href: nova_cobranca_path)
  #
  # Sem amount_cents:/receiver:, lê do copia e cola (campos 54 e 59). Ao zerar a contagem, o cartão passa a
  # "expirado" sozinho (data-expired). hint: false tira a dica. qr: o SVG/<img> pronto (html_safe).
  class PixCardComponent < BaseComponent
    STATUSES = %i[waiting paid expired].freeze

    attr_reader :code, :status, :expires_at, :regenerate_href, :regenerate_method

    def initialize(code:, amount_cents: nil, receiver: nil, expires_at: nil, status: :waiting, qr: nil, title: nil,
                   hint: nil, regenerate_href: nil, regenerate_method: :post, **opts)
      super(**opts)
      @code = code.to_s
      @parsed = ComponentesUi::Br.pix_code(@code)
      @amount_cents = amount_cents || @parsed&.amount_cents
      @receiver = receiver || @parsed&.name
      @expires_at = expires_at
      @status = STATUSES.include?(status.to_s.to_sym) ? status.to_s.to_sym : :waiting
      @status = :expired if @status == :waiting && expires_at && expires_at <= Time.current
      @qr = qr
      @title = title
      @hint = hint
      @regenerate_href = regenerate_href
      @regenerate_method = regenerate_method
    end

    def t(key, **o) = ss_t("br.#{key}", **o)
    def title = @title || t("pix_title")
    def hint = @hint == false ? nil : (@hint || t("pix_hint"))
    def receiver = @receiver.presence
    def amount_text = @amount_cents ? ss_money(@amount_cents / 100.0) : t("pix_any_amount")
    def qr = @qr.presence || ss_qr_svg(@code, margin: 1)
    def left = @expires_at ? [(@expires_at - Time.current).to_i, 0].max : 0

    def clock
      h, rest = left.divmod(3600)
      m, s = rest.divmod(60)
      h.positive? ? Kernel.format("%d:%02d:%02d", h, m, s) : Kernel.format("%02d:%02d", m, s)
    end

    def counting? = @status == :waiting && @expires_at.present?
    def uid = @uid ||= "ss-pix-#{object_id}"

    def root
      data = { state: @status }
      data.merge!(controller: "ss-countdown", ss_countdown_until_value: @expires_at.iso8601) if counting?
      root_attrs(class: classes("ss-card", "ss-pix"), data:, "aria-labelledby": "#{uid}-title")
    end
  end
end
