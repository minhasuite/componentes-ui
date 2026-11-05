module Ss
  # Radio ou checkbox como card (ícone, título, descrição); marcado pelo :has(:checked).
  # Agrupe vários num <div class="ss-option-grid" role="radiogroup" aria-label="…">.
  #   render Ss::OptionCardComponent.new(name: "plano", value: "anual", title: "Anual", description: "2 meses grátis", icon: svg)
  #
  # v0.10.1, modo link (escolher num catálogo por link, sem rádio): url: vira um <a> com a seta;
  # checked: true marca o atual (aria-current). name:/value: só valem no modo rádio/checkbox.
  #   render Ss::OptionCardComponent.new(url: novo_dispositivo_path(tipo: "tuya"), title: "Tuya", description: "Tomadas e lâmpadas", icon: svg)
  #
  # v0.10.3: id: vai no <input> (para um <label for> de fora, ou o teste achar); input: {} passa
  # outros atributos ao input (disabled:, required:, form:, data: { action: … }). dense: true é a
  # variante compacta (listas longas: menos respiro, ícone menor, descrição numa linha);
  # vertical: true põe o ícone em cima, centralizado (tiles estreitos numa grade).
  class OptionCardComponent < BaseComponent
    CHEVRON = %(<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M9 6l6 6-6 6"/></svg>).freeze

    attr_reader :name, :value, :title, :description, :icon, :type, :checked, :badge, :url

    def initialize(title:, name: nil, value: nil, description: nil, icon: nil, type: :radio, checked: false, badge: nil, url: nil,
                   id: nil, input: {}, dense: false, vertical: false, **rest)
      raise ArgumentError, "Ss::OptionCardComponent: passe name:/value: (rádio) ou url: (link)" if url.nil? && (name.nil? || value.nil?)

      super(**rest)
      @name, @value, @title, @description, @icon, @type, @checked, @badge = name, value, title, description, icon, type.to_s, checked, badge
      @url = url
      @input_id, @input, @dense, @vertical = id, input.to_h, dense, vertical
    end

    def link? = !@url.nil?

    def variant_classes = [("is-dense" if @dense), ("is-vertical" if @vertical)]

    # O <input> do rádio/checkbox, com id: e os atributos de input:.
    def input_tag
      tag.input(type:, name:, value:, checked: (checked ? true : nil), id: @input_id, **@input.symbolize_keys)
    end
  end
end
