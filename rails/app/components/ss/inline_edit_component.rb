module Ss
  # Valor que vira campo ao clicar: Enter salva (form com Turbo para url:, method: :patch), Esc cancela.
  # Sem url: é só local e dispara o evento ss-inline-edit:save (detail.value).
  # A resposta pode ser turbo_stream que troca o componente; sem isso, o texto novo fica na tela.
  #   render Ss::InlineEditComponent.new(value: @cliente.nome, name: "cliente[nome]", url: cliente_path(@cliente), label: "Nome")
  class InlineEditComponent < BaseComponent
    attr_reader :value, :name, :url, :method_name, :label, :type

    def initialize(value:, name:, label:, url: nil, method: :patch, type: "text", **rest)
      super(**rest)
      @value, @name, @url, @method_name, @label, @type = value, name, url, method, label, type
    end
  end
end
