module Ss
  # Cartão de embarque: origem → destino com arco tracejado e o avião na posição
  # `progress` (0 a 1), grade de campos e, na base, QR opcional (SVG/imagem pronta do app).
  #   render Ss::BoardingPassComponent.new(from: { code: "JOG", city: "Yogyakarta", time: "20:50", date: "qui, 02/05" },
  #     to: { code: "DPS", city: "Bali", time: "23:00", date: "qui, 02/05" }, progress: 0.45,
  #     fields: [["Passageiro", "Sukijan"], ["Assento", "24A"]], carrier: "Garuda", qr: qr_svg)
  class BoardingPassComponent < BaseComponent
    include InView
    P0 = [16.0, 84.0].freeze
    P1 = [150.0, -14.0].freeze
    P2 = [284.0, 84.0].freeze

    attr_reader :from, :to, :fields, :carrier, :qr, :note

    def initialize(from:, to:, progress: 0, fields: [], carrier: nil, qr: nil, note: nil, **opts)
      super(**opts)
      @from = from
      @to = to
      @progress = progress.to_f.clamp(0, 1)
      @fields = fields
      @carrier = carrier
      @qr = qr
      @note = note
    end

    def progress = @progress

    # Ponto e ângulo do avião na curva (Bézier quadrática).
    def plane
      t = @progress
      x = (1 - t)**2 * P0[0] + 2 * (1 - t) * t * P1[0] + t**2 * P2[0]
      y = (1 - t)**2 * P0[1] + 2 * (1 - t) * t * P1[1] + t**2 * P2[1]
      dx = 2 * (1 - t) * (P1[0] - P0[0]) + 2 * t * (P2[0] - P1[0])
      dy = 2 * (1 - t) * (P1[1] - P0[1]) + 2 * t * (P2[1] - P1[1])
      [x.round(2), y.round(2), (Math.atan2(dy, dx) * 180 / Math::PI).round(1)]
    end

    def arc_d = "M#{P0.join(",")} Q#{P1.join(",")} #{P2.join(",")}"
  end
end
