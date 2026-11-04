module Ss
  # Código de verificação: uma caixinha por dígito, pula sozinha, Backspace volta, colar preenche todas.
  # O código inteiro vai no hidden (name:); ao completar sai o evento ss-otp:complete (detail.code).
  #   render Ss::OtpInputComponent.new(name: "codigo", length: 6)
  class OtpInputComponent < BaseComponent
    attr_reader :name, :length, :label

    def initialize(name:, length: 6, label: nil, **rest)
      super(**rest)
      @name, @length, @label = name, length, label || ss_t("otp.label", default: "Código de verificação")
    end
  end
end
