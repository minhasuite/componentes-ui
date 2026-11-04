module Ss
  # Botão de microfone. Ouvindo, os anéis crescem com o nível do áudio (0..1), como um medidor.
  # O app alimenta o nível e troca o estado pelo controller ss-mic:
  #
  #   render Ss::MicButtonComponent.new(state: :idle, id: "mic")
  #   const mic = application.getControllerForElementAndIdentifier(el, "ss-mic")
  #   mic.setLevel(0.6)            // ou el.dispatchEvent(new CustomEvent("ss-mic:level", { detail: 0.6 }))
  #   mic.setState("processing")   // ou el.dataset.ssMicStateValue = "processing"
  #
  # state: :idle | :listening | :processing (arco girando) | :error. O toque dispara "ss-mic:press"
  # (detail: { state }); o app liga/desliga a captura. size: diâmetro em px.
  class MicButtonComponent < BaseComponent
    STATES = %i[idle listening processing error].freeze
    DEFAULTS = { idle: "Falar", listening: "Ouvindo, toque para parar", processing: "Processando",
                 error: "Erro no microfone, toque para tentar de novo" }.freeze

    attr_reader :state, :level, :size

    def initialize(state: :idle, level: 0, size: 72, labels: {}, **rest)
      super(**rest)
      @state = STATES.include?(state.to_s.to_sym) ? state.to_s.to_sym : :idle
      @level = level.to_f.clamp(0.0, 1.0)
      @size = size.to_i
      @labels = labels.to_h.transform_keys(&:to_sym)
    end

    def label(key) = @labels[key] || ss_t("mic_button.#{key}", default: DEFAULTS[key])
    def labels_json = STATES.to_h { |s| [s, label(s)] }.to_json

    def call
      own = @attrs.to_h[:data].to_h
      data = { controller: [own[:controller] || own["controller"], "ss-mic"].compact.join(" "),
               ss_mic_state_value: state, ss_mic_labels_value: labels_json, state: }
      tag.div(**root_attrs(class: classes("ss-mic"), style: "--size: #{size}px; --level: #{level}", data:)) do
        tag.button(type: "button", class: "ss-mic-btn", aria: { label: label(state) },
                   data: { action: "ss-mic#press", ss_mic_target: "button" }) do
          safe_join([tag.i(class: "ss-mic-ring", style: "--n: 1"), tag.i(class: "ss-mic-ring", style: "--n: 2"),
                     tag.i(class: "ss-mic-ring", style: "--n: 3"), tag.i(class: "ss-mic-arc"),
                     tag.span(Ss::CasaIcons.svg(:mic), class: "ss-mic-on"), tag.span(Ss::CasaIcons.svg(:mic_off), class: "ss-mic-off")])
        end
      end
    end
  end
end
