module Ss
  # Combobox com busca: no servidor (url:, GET ?q=, devolve JSON [{id:, label:, hint:}] ou HTML
  # com <li role="option" data-value data-label>) ou local (options: [{id:, label:, hint:}]).
  # O id escolhido vai num hidden (name:); create: true oferece "Criar ‘x’" (o texto vai em create_name:
  # e o evento ss-combobox:create sai com detail.text).
  #   render Ss::ComboboxComponent.new(name: "pedido[cliente_id]", label: "Cliente", url: clientes_path(format: :json))
  class ComboboxComponent < BaseComponent
    attr_reader :name, :label, :placeholder, :url, :options, :create, :create_name, :value, :text, :help, :id

    def initialize(name:, label:, url: nil, options: nil, value: nil, text: nil, placeholder: "Digite para buscar…",
                   create: false, create_name: nil, help: nil, debounce: 250, min_chars: 1, id: nil, **rest)
      super(**rest)
      @name, @label, @url, @options, @value, @text, @placeholder = name, label, url, options, value, text, placeholder
      @create, @create_name, @help, @debounce, @min_chars = create, create_name, help, debounce, min_chars
      @id = id || "ss-combo-#{SecureRandom.hex(3)}"
    end

    def data_attrs
      d = { controller: "ss-combobox", ss_combobox_debounce_value: @debounce, ss_combobox_min_value: @min_chars }
      d[:ss_combobox_url_value] = url if url
      d[:ss_combobox_options_value] = options.to_json if options
      d[:ss_combobox_create_value] = true if create
      d
    end
  end
end
