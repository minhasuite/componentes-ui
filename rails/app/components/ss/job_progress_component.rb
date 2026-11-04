module Ss
  # Job em andamento (importação, relatório, IA): na fila, rodando n%, concluído
  # com link, falhou com motivo. O job atualiza com Turbo Stream:
  #   turbo_stream.replace "importacao-42", Ss::JobProgressComponent.new(id: "importacao-42", state: :running, progress: 0.4, …)
  # (o app transmite com Turbo::StreamsChannel.broadcast_replace_to … renderable: o componente).
  # Movimento: ao aparecer, a barra enche com mola; com method: :morph no stream, a barra
  # anda com mola do valor antigo ao novo (no replace simples, o elemento é outro e pula).
  #
  # v0.10.1, etapas com tempo (execução que já passou, ex. o pipeline de voz):
  #   Ss::JobProgressComponent.new(id: "run-7", title: "Comando de voz", state: :done,
  #     stages: [{ name: "Ouvir", duration: 820, status: :done }, { name: "Entender", duration: "1,2 s", status: :done },
  #              { name: "Executar", status: :skipped, detail: "Nada a fazer" }])
  # duration: número em ms (sai "820 ms" ou "1,2 s" no idioma) ou texto pronto. status: :done,
  # :failed, :skipped ou :running. Com etapas e o job concluído/falho, a barra sai e entra o
  # total (soma das durações em ms; total: troca). Textos: job_progress.stage_states.*, .total.
  class JobProgressComponent < BaseComponent
    include InView
    STAGE_STATES = { done: "Concluída", failed: "Falhou", skipped: "Pulada", running: "Rodando" }.freeze
    STAGE_ICONS = { done: :check, failed: :close, skipped: :minus, running: :refresh }.freeze
    # Rótulo pt-BR de reserva e tom; o texto sai de componentes_ui.job_progress.states.<estado>.
    STATES = {
      queued: ["Na fila", "info"], running: ["Rodando", "accent"], done: ["Concluído", "success"], failed: ["Falhou", "danger"]
    }.freeze

    attr_reader :id, :title, :state, :steps, :current_step, :result_url, :result_label, :error, :detail

    def initialize(id:, title:, state: :queued, progress: nil, steps: [], current_step: nil, result_url: nil,
                   result_label: nil, error: nil, detail: nil, retry_url: nil, stages: [], total: nil, **opts)
      super(**opts)
      @stages = Array(stages).map { _1.to_h.transform_keys(&:to_sym) }
      @total = total
      @id = id
      @title = title
      @state = state.to_sym
      @progress = progress
      @steps = steps
      @current_step = current_step
      @result_url = result_url
      @result_label = result_label || ss_t("job_progress.result", default: "Abrir resultado")
      @error = error
      @detail = detail
      @retry_url = retry_url
    end

    def pct = @state == :done ? 100 : (@progress.to_f.clamp(0, 1) * 100).round
    def determinate? = @state == :done || (@state == :running && !@progress.nil?)
    def state_label = STATES[@state] && ss_t("job_progress.states.#{@state}", default: STATES.dig(@state, 0))
    def tone = STATES.dig(@state, 1)
    def step_state(i)
      return "is-done" if @state == :done || (@current_step && i < @current_step)
      return (@state == :failed ? "is-failed" : "is-current") if @current_step == i

      nil
    end
    attr_reader :retry_url, :stages

    def stages? = stages.any?
    # Com etapas de uma execução que terminou, a barra não diz nada: sai.
    def bar? = !(stages? && %i[done failed].include?(@state))
    def stage_status(s) = STAGE_STATES.key?(s[:status]&.to_sym) ? s[:status].to_sym : :done
    def stage_label(s) = ss_t("job_progress.stage_states.#{stage_status(s)}", default: STAGE_STATES[stage_status(s)])
    def stage_icon(s) = Ss::CasaIcons.svg(STAGE_ICONS[stage_status(s)])

    # 820 → "820 ms"; 1234 → "1,2 s"; 65000 → "1 min 5 s"; texto passa direto.
    def duration_text(v)
      return v.to_s unless v.is_a?(Numeric)
      return "#{ss_number(v.round)} ms" if v < 1000
      return "#{ss_number(v / 1000.0, precision: 1)} s" if v < 60_000

      min, sec = (v / 1000.0).round.divmod(60)
      sec.zero? ? "#{min} min" : "#{min} min #{sec} s"
    end

    def total_text
      return @total.is_a?(Numeric) ? duration_text(@total) : @total.to_s if @total
      nums = stages.map { _1[:duration] }.grep(Numeric)
      duration_text(nums.sum) if nums.any?
    end
  end
end
