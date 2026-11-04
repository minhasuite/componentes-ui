module Ss
  # Passo a passo: cabeçalho com os passos e progresso, um painel por vez, Voltar/Avançar; no último,
  # o botão vira enviar (o form fica por conta do app, em volta). Avançar valida os campos do passo.
  # draft_key: guarda o rascunho no localStorage (apaga ao enviar).
  # Movimento: ligação e progresso enchem como minhoca com faísca na cabeça (ss-wizard) e o
  # círculo do passo novo estala com ondinha (ss-indicator, motion-value="pop").
  #   render Ss::WizardComponent.new(draft_key: "novo-cliente") do |w|
  #     w.with_step(title: "Dados") { ... } ; w.with_step(title: "Endereço") { ... }
  #   end
  class WizardComponent < BaseComponent
    class StepComponent < ViewComponent::Base
      attr_reader :title

      def initialize(title:)
        @title = title
      end

      def call = content
    end

    renders_many :steps, StepComponent

    attr_reader :draft_key, :submit_label

    def initialize(draft_key: nil, submit_label: nil, **rest)
      super(**rest)
      @draft_key = draft_key
      @submit_label = submit_label || ss_t("wizard.submit", default: "Concluir")
    end
  end
end
