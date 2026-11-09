module ComponentesUi
  # ss_form_with: o form_with do Rails com o ComponentesUi::FormBuilder e a classe .ss-form.
  #   <%= ss_form_with model: @cliente do |f| %> <%= f.ss_text_field :nome %> <% end %>
  module FormHelpers
    def ss_form_with(**options, &block)
      html = options.delete(:html) || {}
      html[:class] = ["ss-form", html[:class], options.delete(:class)].compact.join(" ")
      form_with(**options, builder: ComponentesUi::FormBuilder, html:, &block)
    end

    # Grupo de campos com legenda e ajuda do grupo (v0.13), também fora do ss_form_with:
    #   <%= ss_fieldset legend: "Horário", help: "Vale para todos os dias" do %> … <% end %>
    # body_class: a grade dos campos; wrapper_class: o fieldset.
    def ss_fieldset(legend:, help: nil, wrapper_class: nil, body_class: nil, &block)
      @ss_fieldset_seq = (@ss_fieldset_seq || 0) + 1
      help_id = "ss-fs-#{@ss_fieldset_seq}-help" if help
      tag.fieldset(class: ["ss-fieldset", "ss-field-group", wrapper_class].compact.join(" "), "aria-describedby": help_id) do
        safe_join([tag.legend(legend, class: "ss-label"), (tag.small(help, class: "ss-field-help", id: help_id) if help),
                   tag.div(capture(&block), class: ["ss-field-group-body", body_class].compact.join(" "))].compact)
      end
    end

    # Para o fields_for/fields dentro de um form comum.
    def ss_fields(scope = nil, model: nil, **options, &block)
      fields(scope, model:, **options, builder: ComponentesUi::FormBuilder, &block)
    end
  end
end
