module ComponentesUi
  # ss_form_with: o form_with do Rails com o ComponentesUi::FormBuilder e a classe .ss-form.
  #   <%= ss_form_with model: @cliente do |f| %> <%= f.ss_text_field :nome %> <% end %>
  module FormHelpers
    def ss_form_with(**options, &block)
      html = options.delete(:html) || {}
      html[:class] = ["ss-form", html[:class], options.delete(:class)].compact.join(" ")
      form_with(**options, builder: ComponentesUi::FormBuilder, html:, &block)
    end

    # Para o fields_for/fields dentro de um form comum.
    def ss_fields(scope = nil, model: nil, **options, &block)
      fields(scope, model:, **options, builder: ComponentesUi::FormBuilder, &block)
    end
  end
end
