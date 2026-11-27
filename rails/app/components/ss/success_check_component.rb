module Ss
  # Check que se desenha (v1.14.0, par do SsSuccessCheck): o círculo e depois o traço, na cor de sucesso, com a
  # vibração de sucesso e, com sound: true, o gancho do som curto: o evento `ss:sound` { name: "success" } no window
  # (o produto toca o áudio dele; o pacote não traz som). Toca uma vez, quando aparece (entra na tela ou deixa de
  # estar escondido). Reduzir movimento: aparece pronto, sem desenhar.
  #
  #   render Ss::SuccessCheckComponent.new                                  # 4rem, "Concluído" no leitor de tela
  #   render Ss::SuccessCheckComponent.new(size: "2.5rem", label: "Pago", sound: true)
  #
  # Dentro de outra peça (o ✓ do MorphButtonComponent, do SwipeToConfirmComponent), use Ss::SuccessCheckComponent.mark:
  # só o desenho, que se desenha quando o estado da peça vira "feito" (a vibração e o som ficam com ela, pelo
  # ssSuccess(el, { sound }) do ss_success_check_controller).
  class SuccessCheckComponent < BaseComponent
    PATHS = %(<circle class="ss-sc-circle" cx="26" cy="26" r="23" pathLength="1"/><path class="ss-sc-mark" d="M15.5 27.5l7 7L37 19" pathLength="1"/>).freeze

    # O desenho sozinho (sem controller): o traço segue o currentColor.
    def self.mark(css: nil)
      %(<svg class="#{["ss-sc-svg", css].compact.join(" ")}" viewBox="0 0 52 52" aria-hidden="true" focusable="false">#{PATHS}</svg>).html_safe
    end

    def initialize(size: nil, label: nil, sound: false, haptic: true, **rest)
      super(**rest)
      @size, @label, @sound, @haptic = size, label, sound, haptic
    end

    def call
      size = @size.is_a?(Numeric) ? "#{@size}px" : @size
      label = @label || ss_t("interface.success", default: "Concluído")
      tag.span(self.class.mark, **root_attrs(class: classes("ss-success-check"), role: "img", "aria-label": label,
                                                 style: (size && "--ss-sc-size:#{ERB::Util.h(size)}"),
                                                 data: { controller: "ss-success-check", ss_success_check_sound_value: (@sound || nil),
                                                         ss_success_check_haptic_value: (@haptic ? nil : false) }.compact))
    end
  end
end
