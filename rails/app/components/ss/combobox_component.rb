module Ss
  # Combobox com busca: no servidor (url:, GET ?q=, devolve JSON [{id:, label:, hint:}] ou HTML
  # com <li role="option" data-value data-label>) ou local (options: [{id:, label:, hint:}]).
  # O id escolhido vai num hidden (name:); create: true oferece "Criar ‘x’" (o texto vai em create_name:
  # e o evento ss-combobox:create sai com detail.text).
  #   render Ss::ComboboxComponent.new(name: "pedido[cliente_id]", label: "Cliente", url: clientes_path(format: :json))
  #
  # v0.18: ícone ou imagem por opção, na lista e no campo (a escolhida aparece antes do texto):
  #   options: [{ id: 1, label: "Nubank", image: logo_url }, { id: 2, label: "Mercado", icon: "shopping-cart", color: "#16a34a" }]
  # icon: nome do ss_icon (a gem desenha o SVG no servidor; no JSON do url: só image: vale, por
  # segurança); color: pinta o ícone (cor do usuário, ex. a da categoria); image: URL de uma <img>
  # (logo do banco, foto do perfil; alt vazio, o rótulo já diz). input: {} passa atributos ao <input>
  # visível (title:, data: { action:, …_target: }, aria:, autofocus:, disabled:, required:).
  #
  # v0.20: with_action { … } põe botões ao lado do campo (ler código de barras, cadastrar novo); par do
  # showSsPicker(actions:). O botão é do app (Ss::IconButtonComponent com o data-action dele).
  class ComboboxComponent < BaseComponent
    renders_many :actions
    attr_reader :name, :label, :placeholder, :url, :options, :create, :create_name, :value, :text, :help, :id

    def initialize(name:, label:, url: nil, options: nil, value: nil, text: nil, placeholder: nil,
                   create: false, create_name: nil, help: nil, debounce: 250, min_chars: 1, id: nil, input: {}, **rest)
      super(**rest)
      @input = input.to_h.transform_keys(&:to_sym)
      options = options&.map { |o| decorate_option(o) }
      @name, @label, @url, @options, @value, @text, @placeholder = name, label, url, options, value, text, placeholder
      @create, @create_name, @help, @debounce, @min_chars = create, create_name, help, debounce, min_chars
      @placeholder ||= ss_t("combobox.placeholder", default: "Digite para buscar…")
      @id = id || "ss-combo-#{SecureRandom.hex(3)}"
    end

    # Atributos extras do <input> visível (input:), somando data:/aria: aos do componente.
    def input_extra = @input.except(:data, :aria, :class, :id, :value, :type, :role)
    def input_data = { ss_combobox_target: "input", action: ["input->ss-combobox#search keydown->ss-combobox#key focus->ss-combobox#search blur->ss-combobox#close", @input.dig(:data, :action)].compact.join(" ") }.merge(@input[:data].to_h.except(:action).transform_keys(&:to_sym))
    def input_aria = @input[:aria].to_h
    def input_class = ["ss-input", @input[:class]].compact.join(" ")

    # A opção escolhida (para o ícone/imagem no campo).
    def selected_option
      return if @options.blank? || @value.blank?

      @options.find { |o| (o[:id] || o["id"]).to_s == @value.to_s }
    end

    def lead_html(o)
      return "".html_safe unless o
      if o[:image].present?
        tag.img(src: o[:image], alt: "", loading: "lazy", decoding: "async")
      elsif o[:icon_svg].present?
        tag.span(o[:icon_svg].html_safe, class: "ss-combobox-ico", style: (o[:color].present? ? "--c: #{o[:color]}" : nil))
      else
        "".html_safe
      end
    end

    def lead? = selected_option&.then { |o| o[:image].present? || o[:icon_svg].present? }
    def media? = @options.to_a.any? { |o| o[:image].present? || o[:icon_svg].present? }

    def data_attrs
      d = { controller: "ss-combobox", ss_combobox_debounce_value: @debounce, ss_combobox_min_value: @min_chars,
            # Textos que o controller escreve na lista (o JS não tem texto fixo).
            ss_combobox_create_label_value: ss_t("combobox.create", default: "Criar “%{q}”"),
            ss_combobox_empty_label_value: ss_t("combobox.empty", default: "Nada encontrado"),
            ss_combobox_hint_label_value: ss_t("combobox.hint", default: "Digite para buscar") }
      d[:ss_combobox_url_value] = url if url
      d[:ss_combobox_options_value] = options.to_json if options
      d[:ss_combobox_create_value] = true if create
      d
    end

    private

    # icon: nome vira SVG (icon_svg) desenhado aqui; color: só cor CSS simples.
    def decorate_option(o)
      o = o.to_h.transform_keys(&:to_sym)
      if o[:icon].present?
        o[:icon_svg] = (o[:icon].respond_to?(:html_safe?) && o[:icon].html_safe? ? o[:icon] : ss_icon(o[:icon].to_s, size: nil)).to_s
      end
      color = o[:color].to_s
      ok = color.match?(/\A(#[0-9a-fA-F]{3,8}|[a-z]+|(rgb|hsl|oklch)a?\([\d\s.,%\/-]+\)|var\(--[\w-]+\))\z/)
      ok ? o[:color] = color : o.delete(:color)
      o.except(:icon)
    end
  end
end
