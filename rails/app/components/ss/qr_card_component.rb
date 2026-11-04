module Ss
  # Pix/QR: área branca com o QR (SVG ou imagem pronta do app, sem gem nova),
  # código copia-e-cola com botão copiar (ss-copy) e contagem da validade (ss-countdown).
  #   render Ss::QrCardComponent.new(title: "Pague com Pix", amount: "R$ 89,90", code: pix_copia_cola,
  #     expires_at: 30.minutes.from_now) { qr_svg }   (ou qr: "<svg…>".html_safe)
  class QrCardComponent < BaseComponent
    COPY = %(<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><rect x="8" y="8" width="12" height="12" rx="3"/><path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2"/></svg>).freeze

    attr_reader :title, :amount, :code, :expires_at, :hint

    def initialize(code:, title: "Pague com Pix", amount: nil, qr: nil, expires_at: nil, hint: "Abra o app do banco, escolha Pix e leia o código.", **opts)
      super(**opts)
      @code = code
      @title = title
      @amount = amount
      @qr = qr
      @expires_at = expires_at
      @hint = hint
    end

    def qr = content.presence || @qr
    def left = @expires_at ? [(@expires_at - Time.current).to_i, 0].max : 0
    def mmss = format("%02d:%02d", left / 60, left % 60)
    def uid = @uid ||= "ss-qr-#{object_id}"
  end
end
