module Ss
  # Etiquetas digitadas: Enter ou vírgula vira chip, Backspace no campo vazio apaga o último, × remove.
  # A lista vai num hidden (name:) separada por vírgula.
  #   render Ss::TagInputComponent.new(name: "produto[tags]", label: "Etiquetas", values: @produto.tags)
  class TagInputComponent < BaseComponent
    attr_reader :name, :label, :values, :placeholder, :help, :id

    def initialize(name:, label:, values: [], placeholder: "Digite e tecle Enter", help: nil, id: nil, **rest)
      super(**rest)
      @name, @label, @values, @placeholder, @help = name, label, Array(values), placeholder, help
      @id = id || "ss-tags-#{SecureRandom.hex(3)}"
    end
  end
end
