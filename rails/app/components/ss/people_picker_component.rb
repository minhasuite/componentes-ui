module Ss
  # Fileira horizontal de pessoas em pílulas altas para escolher várias (v1.10, par do SsPeoplePicker): avatar,
  # o primeiro nome e um "+" que vira ✓. As escolhidas ganham anel e fundo na cor da marca, e o avatar estoura
  # com a mola ao ser marcado. add_url: põe o "Novo" no começo.
  #
  #   render Ss::PeoplePickerComponent.new(name: "divisao[pessoas][]", people: ["Ana Souza", "Bruno Lima"],
  #     selected: ["Ana Souza"], add_url: new_pessoa_path)
  #   people: [{ name: "Ana Souza", value: 12 }, …] quando o valor enviado não é o nome.
  #
  # Cada pessoa é um checkbox de verdade (vai no formulário com name:; o `change` é o onChanged): Tab entra,
  # Espaço marca, o leitor de tela lê "Ana Souza, marcado". legend: o nome do grupo (padrão "Pessoas", escondido).
  class PeoplePickerComponent < BaseComponent
    def initialize(people:, name:, selected: [], add_url: nil, add_label: nil, legend: nil, brand_hue: 250, **rest)
      super(**rest)
      @people = Array(people).map { |p| p.is_a?(Hash) ? { name: p[:name].to_s, value: (p[:value] || p[:name]).to_s } : { name: p.to_s, value: p.to_s } }
      @name, @add_url, @hue = name, add_url, brand_hue
      @selected = Array(selected).map(&:to_s)
      @add_label = add_label || ss_t("people_picker.add", default: "Novo")
      @legend = legend || ss_t("people_picker.label", default: "Pessoas")
    end

    def call
      tag.fieldset(**root_attrs(class: classes("ss-people"))) do
        safe_join([
          tag.legend(@legend, class: "ss-sr"),
          tag.div(class: "ss-people-row") { safe_join([add, *@people.map { |p| person(p) }].compact) }
        ])
      end
    end

    private

    def add
      return nil unless @add_url

      link_to(@add_url, class: "ss-people-pill ss-people-add") do
        safe_join([tag.span(ss_icon("user-add", size: nil), class: "ss-people-add-ico", "aria-hidden": "true"),
                   tag.span(@add_label, class: "ss-people-name"), tag.span(class: "ss-people-badge is-blank", "aria-hidden": "true")])
      end
    end

    def person(p)
      tag.label(class: "ss-people-pill", title: p[:name]) do
        safe_join([
          tag.input(type: "checkbox", name: @name, value: p[:value], checked: @selected.include?(p[:value]) || @selected.include?(p[:name]),
                    class: "ss-people-input", "aria-label": p[:name]),
          tag.span(ss_avatar(p[:name], size: 44, brand_hue: @hue), class: "ss-people-face", "aria-hidden": "true"),
          tag.span(p[:name].split.first, class: "ss-people-name", "aria-hidden": "true"),
          tag.span(class: "ss-people-badge", "aria-hidden": "true") { safe_join([ss_icon("plus", size: nil, css: "is-plus"), ss_icon("check", size: nil, css: "is-check")]) }
        ])
      end
    end
  end
end
