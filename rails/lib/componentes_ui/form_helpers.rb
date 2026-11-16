module ComponentesUi
  # ss_form_with: o form_with do Rails com o ComponentesUi::FormBuilder e a classe .ss-form.
  #   <%= ss_form_with model: @cliente do |f| %> <%= f.ss_text_field :nome %> <% end %>
  module FormHelpers
    #
    # v0.24 (auditoria de UX, B13): validate: :ss (padrão) liga o Stimulus ss-validate, que põe novalidate no form
    # (some o balão/dica nativo "Preencha este campo" ao passar o mouse) e mostra a mensagem embaixo do campo ao
    # sair dele e ao enviar. validate: :native deixa a validação do navegador como era.
    def ss_form_with(validate: :ss, **options, &block)
      html = options.delete(:html) || {}
      html[:class] = ["ss-form", html[:class], options.delete(:class)].compact.join(" ")
      if validate.to_s == "ss"
        data = (options.delete(:data) || {}).merge(html.delete(:data) || {}).transform_keys(&:to_sym)
        data[:controller] = [data[:controller], "ss-validate"].compact.join(" ")
        data[:ss_validate_required_value] ||= I18n.t("componentes_ui.form.required_error", default: "Preencha este campo.")
        html[:data] = data
      end
      form_with(**options, builder: ComponentesUi::FormBuilder, html:, &block)
    end

    # Grupo de campos com legenda e ajuda do grupo (v0.13), também fora do ss_form_with:
    #   <%= ss_fieldset legend: "Horário", help: "Vale para todos os dias" do %> … <% end %>
    # body_class: a grade dos campos; wrapper_class: o fieldset.
    def ss_fieldset(legend:, help: nil, wrapper_class: nil, body_class: nil, &block)
      @ss_fieldset_seq = (@ss_fieldset_seq || 0) + 1
      FormHelpers.fieldset_html(self, "ss-fs-#{@ss_fieldset_seq}", legend:, help:, wrapper_class:, body_class:, &block)
    end

    # O desenho do fieldset, para a view e para o builder (v0.28): o f.ss_fieldset dentro de um
    # componente (ex. a seção com form: do SettingsLayoutComponent) não tem o helper ss_fieldset no
    # @template; montar com o tag/capture do próprio contexto vale nos dois.
    def self.fieldset_html(view, id, legend:, help: nil, wrapper_class: nil, body_class: nil, &block)
      help_id = "#{id}-help" if help
      view.tag.fieldset(class: ["ss-fieldset", "ss-field-group", wrapper_class].compact.join(" "), "aria-describedby": help_id) do
        view.safe_join([view.tag.legend(legend, class: "ss-label"), (view.tag.small(help, class: "ss-field-help", id: help_id) if help),
                        view.tag.div(view.capture(&block), class: ["ss-field-group-body", body_class].compact.join(" "))].compact)
      end
    end

    # Para o fields_for/fields dentro de um form comum.
    def ss_fields(scope = nil, model: nil, **options, &block)
      fields(scope, model:, **options, builder: ComponentesUi::FormBuilder, &block)
    end
  end
end
