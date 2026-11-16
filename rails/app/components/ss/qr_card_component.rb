module Ss
  # Pix/QR: área branca com o QR (SVG ou imagem pronta do app, sem gem nova),
  # código copia-e-cola com botão copiar (ss-copy) e contagem da validade (ss-countdown).
  #   render Ss::QrCardComponent.new(title: "Pague com Pix", amount: "R$ 89,90", code: pix_copia_cola,
  #     expires_at: 30.minutes.from_now) { qr_svg }   (ou qr: "<svg…>".html_safe)
  #
  # v0.28: qr_label: o nome do QR para o leitor de tela (padrão "QR Code para pagamento", do I18n): fora
  # do Pix, ex. o QR do autenticador no segundo fator, diga o que ele é.
  class QrCardComponent < BaseComponent
    COPY = %(<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><rect x="8" y="8" width="12" height="12" rx="3"/><path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2"/></svg>).freeze

    attr_reader :title, :amount, :code, :expires_at, :hint

    def initialize(code:, title: nil, amount: nil, qr: nil, expires_at: nil, hint: nil, qr_label: nil, **opts)
      super(**opts)
      @qr_label = qr_label
      @code = code
      @title = title || ss_t("qr_card.title", default: "Pague com Pix")
      @amount = amount
      @qr = qr
      @expires_at = expires_at
      # hint: false tira a dica.
      @hint = hint.nil? ? ss_t("qr_card.hint", default: "Abra o app do banco, escolha Pix e leia o código.") : hint.presence
    end

    def qr = content.presence || @qr
    def qr_label = @qr_label.presence || ss_t("qr_card.qr", default: "QR Code para pagamento")
    def left = @expires_at ? [(@expires_at - Time.current).to_i, 0].max : 0
    def mmss = Kernel.format("%02d:%02d", left / 60, left % 60)
    def uid = @uid ||= "ss-qr-#{object_id}"
  end
end
