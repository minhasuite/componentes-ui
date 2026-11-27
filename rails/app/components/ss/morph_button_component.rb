module Ss
  # Botão que vira carregando e depois ✓/✗ (v1.9, par do SsMorphButton): a pílula encolhe num círculo com o anel
  # enquanto o formulário vai, termina em ✓ (verde) ou ✗ (vermelho, quando o servidor recusa) e volta à pílula
  # depois de 1,6 s. Diferente do Ss::ButtonComponent(loading:), que fica do tamanho do botão: use quando o
  # resultado precisa ficar visível ("Salvo", "Enviado").
  #
  #   <%= form_with model: @nota do |f| %> … <%= render Ss::MorphButtonComponent.new(label: "Salvar", icon: "check") %> <% end %>
  #   render Ss::MorphButtonComponent.new(label: "Enviar", type: :button)   # o app ouve "ss-morph:run"
  #
  # Dentro de formulário (type: :submit, o padrão): turbo:submit-start → carregando; turbo:submit-end → ✓ ou ✗.
  # Progresso real: direct-upload:progress do Active Storage no formulário, ou o evento "ss-morph:progress"
  # (detail: { value: 0..1 }) no botão; sem ele, o anel gira. type: :button dispara "ss-morph:run" (cancelável;
  # detail.waitUntil(promise) segura o carregando até a promessa: resolvida = ✓, rejeitada = ✗).
  # block: false deixa do tamanho do texto (padrão: a largura toda). O leitor de tela ouve "Salvar: carregando",
  # "concluído" ou "falhou". Reduzir movimento: troca sem animar.
  # v1.14.0: o ✓ é o Ss::SuccessCheckComponent.mark (círculo e traço que se desenham), com a vibração de sucesso;
  # sound: true dispara o gancho `ss:sound` { name: "success" } (o produto toca).
  class MorphButtonComponent < BaseComponent
    attr_reader :label

    def initialize(label:, icon: nil, type: :submit, name: nil, value: nil, form: nil, block: true, disabled: false, sound: false, **rest)
      super(**rest)
      @label, @icon, @type, @name, @value, @form, @block, @disabled = label, icon, type.to_s, name, value, form, block, disabled
      @sound = sound
    end

    def texts
      { loading: ss_t("morph_button.loading", default: "%{label}: carregando", label:),
        done: ss_t("morph_button.done", default: "%{label}: concluído", label:),
        failed: ss_t("morph_button.failed", default: "%{label}: falhou", label:) }
    end

    def call
      tag.span(class: classes("ss-morph-wrap", ("is-inline" if !@block))) do
        tag.button(type: (@type == "button" ? "button" : "submit"), name: @name, value: @value, form: @form, disabled: (@disabled || nil),
                   **root_attrs(class: "ss-morph", data: { controller: "ss-morph", state: "idle", ss_morph_loading_value: texts[:loading],
                                                           ss_morph_done_value: texts[:done], ss_morph_failed_value: texts[:failed],
                                                           ss_morph_label_value: label, ss_morph_sound_value: (@sound || nil), action: "click->ss-morph#click" })) do
          safe_join([
            tag.span(safe_join([(ss_icon(@icon, size: nil) if @icon), tag.span(label, class: "ss-morph-text")].compact), class: "ss-morph-idle"),
            tag.svg(tag.circle(cx: 12, cy: 12, r: 9, class: "track", pathLength: 100) + tag.circle(cx: 12, cy: 12, r: 9, class: "bar", pathLength: 100),
                    class: "ss-morph-ring", viewBox: "0 0 24 24", "aria-hidden": "true"),
            Ss::SuccessCheckComponent.mark(css: "ss-morph-ok"),
            ss_icon("x", size: nil, css: "ss-morph-err"),
            tag.span(class: "ss-sr", role: "status", data: { ss_morph_target: "status" })
          ])
        end
      end
    end
  end
end
