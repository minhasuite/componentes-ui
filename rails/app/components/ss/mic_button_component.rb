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
  #
  # v0.10.3 (par do SsMicButton(holdToTalk:, compact:) do Flutter):
  # - hold: true → segurar para falar: encostar (pointerdown, ou Espaço/Enter apertado) dispara
  #   "ss-mic:hold-start"; soltar, "ss-mic:hold-end"; arrastar para longe (80 px) ou o navegador
  #   cancelar, "ss-mic:hold-cancel". Leitor de tela (clique sem ponteiro): um clique começa, outro
  #   termina. Não dispara "ss-mic:press". Rótulos: hold "Segure para falar", release "Ouvindo,
  #   solte para enviar" (labels: { hold:, release: } trocam).
  # - compact: true → a caixa é o próprio botão (mín. 48 px) e os anéis passam por fora: cabe ao
  #   lado do campo de mensagem. Ex.: MicButtonComponent.new(hold: true, compact: true, size: 44).
  class MicButtonComponent < BaseComponent
    STATES = %i[idle listening processing error].freeze
    DEFAULTS = { idle: "Falar", listening: "Ouvindo, toque para parar", processing: "Processando",
                 error: "Erro no microfone, toque para tentar de novo", hold: "Segure para falar",
                 release: "Ouvindo, solte para enviar" }.freeze
    HOLD_ACTIONS = %w[pointerdown->ss-mic#holdStart pointermove->ss-mic#holdMove pointerup->ss-mic#holdEnd
                      pointercancel->ss-mic#holdCancel keydown->ss-mic#holdKey keyup->ss-mic#holdKey
                      click->ss-mic#holdClick contextmenu->ss-mic#noMenu].join(" ").freeze

    attr_reader :state, :level, :size

    def initialize(state: :idle, level: 0, size: 72, labels: {}, hold: false, compact: false, **rest)
      super(**rest)
      @state = STATES.include?(state.to_s.to_sym) ? state.to_s.to_sym : :idle
      @level = level.to_f.clamp(0.0, 1.0)
      @size = size.to_i
      @labels = labels.to_h.transform_keys(&:to_sym)
      @hold, @compact = hold, compact
    end

    def hold? = !!@hold
    def compact? = !!@compact
    def label(key) = @labels[key] || ss_t("mic_button.#{key}", default: DEFAULTS[key])

    # Rótulo de cada estado; segurando, parado e ouvindo dizem para segurar e soltar.
    def state_label(s)
      return label(@labels.key?(s) ? s : (s == :idle ? :hold : :release)) if hold? && %i[idle listening].include?(s)

      label(s)
    end

    def labels_json = STATES.to_h { |s| [s, state_label(s)] }.to_json

    def call
      own = @attrs.to_h[:data].to_h
      data = { controller: [own[:controller] || own["controller"], "ss-mic"].compact.join(" "),
               ss_mic_state_value: state, ss_mic_labels_value: labels_json, state: }
      css = classes("ss-mic", ("is-hold" if hold?), ("is-compact" if compact?))
      tag.div(**root_attrs(class: css, style: "--size: #{size}px; --level: #{level}", data:)) do
        tag.button(type: "button", class: "ss-mic-btn", aria: { label: state_label(state) },
                   data: { action: hold? ? HOLD_ACTIONS : "ss-mic#press", ss_mic_target: "button" }) do
          safe_join([tag.i(class: "ss-mic-ring", style: "--n: 1"), tag.i(class: "ss-mic-ring", style: "--n: 2"),
                     tag.i(class: "ss-mic-ring", style: "--n: 3"), tag.i(class: "ss-mic-arc"),
                     tag.span(Ss::CasaIcons.svg(:mic), class: "ss-mic-on"), tag.span(Ss::CasaIcons.svg(:mic_off), class: "ss-mic-off")])
        end
      end
    end
  end
end
