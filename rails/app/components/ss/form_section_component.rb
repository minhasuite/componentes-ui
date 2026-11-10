module Ss
  # Seção de formulário (v0.15): título, ajuda e os campos agrupados num <fieldset>, com
  # divisória opcional acima (divider: true) e grade de colunas (columns: 2 vira 1 no celular).
  # O par Flutter é o SsFieldGroup; dentro do ss_form_with dá no mesmo que f.ss_fieldset, mas
  # serve em qualquer formulário e no form do Turbo.
  #
  #   <%= render(Ss::FormSectionComponent.new(title: "Recorrência", help: "Repete todo mês", divider: true, columns: 2)) do %>
  #     … campos …
  #   <% end %>
  class FormSectionComponent < BaseComponent
    def initialize(title:, help: nil, icon: nil, divider: false, columns: 1, **rest)
      super(**rest)
      @title, @help, @icon, @divider = title, help, icon, divider
      @columns = columns.to_i.clamp(1, 3)
      @uid = "ss-fsec-#{SecureRandom.hex(3)}"
    end

    def call
      help_id = "#{@uid}-help" if @help
      legend = tag.legend(safe_join([(tag.span(@icon.to_s.html_safe, class: "ss-form-section-ico", "aria-hidden": "true") if @icon.present?), @title].compact),
                          class: "ss-form-section-title")
      tag.fieldset(**root_attrs(class: classes("ss-fieldset", "ss-form-section", ("is-divided" if @divider)), "aria-describedby": help_id,
                                style: ("--ss-form-cols:#{@columns}" if @columns > 1))) do
        safe_join([legend, (tag.small(@help, class: "ss-field-help", id: help_id) if @help),
                   tag.div(content, class: ["ss-form-section-body", ("is-cols" if @columns > 1)].compact.join(" "))].compact)
      end
    end
  end
end
