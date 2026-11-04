module Ss
  # Etiquetas digitadas: Enter ou vírgula vira chip, Backspace no campo vazio apaga o último, × remove.
  # A lista vai num hidden (name:) separada por vírgula.
  #   render Ss::TagInputComponent.new(name: "produto[tags]", label: "Etiquetas", values: @produto.tags)
  class TagInputComponent < BaseComponent
    attr_reader :name, :label, :values, :placeholder, :help, :id

    def initialize(name:, label:, values: [], placeholder: nil, help: nil, id: nil, **rest)
      super(**rest)
      @name, @label, @values, @help = name, label, Array(values), help
      @placeholder = placeholder || ss_t("tag_input.placeholder", default: "Digite e tecle Enter")
      @id = id || "ss-tags-#{SecureRandom.hex(3)}"
    end

    def remove_template = ss_t("tag_input.remove", default: "Remover %{tag}")
  end
end
