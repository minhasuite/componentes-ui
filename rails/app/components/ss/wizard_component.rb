module Ss
  # Passo a passo: cabeçalho com os passos e progresso, um painel por vez, Voltar/Avançar; no último,
  # o botão vira enviar (o form fica por conta do app, em volta). Avançar valida os campos do passo.
  # draft_key: guarda o rascunho no localStorage (apaga ao enviar).
  # Movimento: ligação e progresso enchem como minhoca com faísca na cabeça (ss-wizard) e o
  # círculo do passo novo estala com ondinha (ss-indicator, motion-value="pop").
  #   render Ss::WizardComponent.new(draft_key: "novo-cliente") do |w|
  #     w.with_step(title: "Dados") { ... } ; w.with_step(title: "Endereço") { ... }
  #   end
  #
  # v0.10.1, modo servidor (uma página do servidor por passo): current: (índice do passo atual,
  # 0 = primeiro) liga o modo. done: [0, 1] marca os concluídos (sem done:, os anteriores ao
  # atual). Passo com url: vira link (voltar a um passo já feito). Os passos não precisam de
  # bloco: o conteúdo é o bloco do próprio wizard (ou o do passo atual, se tiver). Sem JS de
  # passos, sem Voltar/Avançar: o form e os botões são do app.
  #   render Ss::WizardComponent.new(current: 1, done: [0]) do |w|
  #     w.with_step(title: "Novo", url: novo_path); w.with_step(title: "Conectar"); w.with_step(title: "Encontrado")
  #     form_with(...) { ... }
  #   end
  class WizardComponent < BaseComponent
    class StepComponent < ViewComponent::Base
      attr_reader :title, :url

      def initialize(title:, url: nil)
        @title = title
        @url = url
      end

      def call = content
    end

    renders_many :steps, StepComponent

    attr_reader :draft_key, :submit_label

    def initialize(draft_key: nil, submit_label: nil, current: nil, done: nil, **rest)
      super(**rest)
      @draft_key = draft_key
      @submit_label = submit_label || ss_t("wizard.submit", default: "Concluir")
      @current = current&.to_i
      @done = done&.map(&:to_i)
    end

    # Modo servidor: current: dado.
    def server? = !@current.nil?
    def current = @current.to_i.clamp(0, [steps.size - 1, 0].max)
    def done?(i) = @done ? @done.include?(i) : i < current
    def progress_width = (100.0 * (current + 1) / [steps.size, 1].max).round(1)

    # Corpo do passo atual no modo servidor: o bloco do passo, ou o do wizard.
    def server_body
      step = steps[current]
      body = step.to_s if step
      # (sem os comentários de anotação do ViewComponent, que o modo dev põe em volta)
      body.to_s.gsub(/<!--.*?-->/m, "").strip.present? ? body : content
    end
  end
end
