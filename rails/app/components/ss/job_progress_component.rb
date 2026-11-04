module Ss
  # Job em andamento (importação, relatório, IA): na fila, rodando n%, concluído
  # com link, falhou com motivo. O job atualiza com Turbo Stream:
  #   turbo_stream.replace "importacao-42", Ss::JobProgressComponent.new(id: "importacao-42", state: :running, progress: 0.4, …)
  # (o app transmite com Turbo::StreamsChannel.broadcast_replace_to … renderable: o componente).
  # Movimento: ao aparecer, a barra enche com mola; com method: :morph no stream, a barra
  # anda com mola do valor antigo ao novo (no replace simples, o elemento é outro e pula).
  class JobProgressComponent < BaseComponent
    include InView
    STATES = {
      queued: ["Na fila", "info"], running: ["Rodando", "accent"], done: ["Concluído", "success"], failed: ["Falhou", "danger"]
    }.freeze

    attr_reader :id, :title, :state, :steps, :current_step, :result_url, :result_label, :error, :detail

    def initialize(id:, title:, state: :queued, progress: nil, steps: [], current_step: nil, result_url: nil,
                   result_label: "Abrir resultado", error: nil, detail: nil, retry_url: nil, **opts)
      super(**opts)
      @id = id
      @title = title
      @state = state.to_sym
      @progress = progress
      @steps = steps
      @current_step = current_step
      @result_url = result_url
      @result_label = result_label
      @error = error
      @detail = detail
      @retry_url = retry_url
    end

    def pct = @state == :done ? 100 : (@progress.to_f.clamp(0, 1) * 100).round
    def determinate? = @state == :done || (@state == :running && !@progress.nil?)
    def state_label = STATES.dig(@state, 0)
    def tone = STATES.dig(@state, 1)
    def step_state(i)
      return "is-done" if @state == :done || (@current_step && i < @current_step)
      return (@state == :failed ? "is-failed" : "is-current") if @current_step == i

      nil
    end
    attr_reader :retry_url
  end
end
