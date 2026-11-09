module ComponentesUi
  # FormBuilder da suíte: cada f.ss_* monta o campo inteiro em cima de .ss-field:
  #
  #   <%= ss_form_with model: @cliente do |f| %>
  #     <%= f.ss_text_field :nome, label: "Nome", help: "Como aparece no pedido", counter: 80 %>
  #     <%= f.ss_number_field :limite, label: "Limite", prefix: "R$", suffix: "/mês" %>
  #     <%= f.ss_select :plano, [["Mensal", "m"], ["Anual", "a"]], label: "Plano" %>
  #     <%= f.ss_check_box :ativo, label: "Ativo" %>
  #     <%= f.ss_submit "Salvar" %>
  #   <% end %>
  #
  # - Rótulo com * quando o model tem validates presence (sem if/unless/on).
  # - Erro do model inline (.ss-field-error) e .is-invalid no .ss-field; o input
  #   ganha aria-invalid e aria-describedby (ajuda/erro). Sem erro do servidor, o
  #   campo obrigatório leva "Preencha este campo." para o :user-invalid do navegador.
  # - Não usa o field_with_errors do Rails (quebraria o grid do .ss-field).
  # - v0.13: wrapper_class: em todo f.ss_* vai no .ss-field (coluna de grade sem <div> a mais);
  #   ss_select(selected:) sem model; ss_submit(variant: :outline/:ghost/:danger); f.ss_fieldset
  #   agrupa campos com legenda e uma ajuda do grupo.
  class FormBuilder < ActionView::Helpers::FormBuilder
    TEXT_KINDS = %i[text_field email_field number_field password_field telephone_field url_field search_field date_field
                    datetime_local_field time_field month_field text_area].freeze

    TEXT_KINDS.each do |kind|
      define_method(:"ss_#{kind}") do |method, **opts|
        ss_field(method, opts) { |input_opts| public_send(kind, method, input_opts) }
      end
    end

    # f.ss_select :plano, opções, label:, include_blank: "Escolha…"
    # selected: (v0.13) marca a opção quando não há model (ou para sobrepor o valor dele).
    def ss_select(method, choices = nil, label: nil, help: nil, include_blank: nil, prompt: nil, selected: nil, **opts)
      select_opts = { include_blank:, prompt:, selected: }.compact
      ss_field(method, opts.merge(label:, help:)) { |io| select(method, choices, select_opts, io) }
    end

    # f.ss_collection_select :cliente_id, Cliente.all, :id, :nome, label:
    def ss_collection_select(method, collection, value_method, text_method, label: nil, help: nil, include_blank: nil, prompt: nil, selected: nil, **opts)
      select_opts = { include_blank:, prompt:, selected: }.compact
      ss_field(method, opts.merge(label:, help:)) { |io| collection_select(method, collection, value_method, text_method, select_opts, io) }
    end

    # Caixa de marcar com o texto ao lado (.ss-check).
    def ss_check_box(method, label: nil, help: nil, checked_value: "1", unchecked_value: "0", wrapper_class: nil, **opts)
      ss_no_wrap do
        errs = ss_errors(method)
        box = check_box(method, opts.merge(ss_aria(method, errs, help)), checked_value, unchecked_value)
        lbl = @template.tag.label(class: "ss-check", for: field_id(method)) { @template.safe_join([box, " ", label || ss_human(method), ss_req(method)]) }
        ss_wrap(method, errs, help, [lbl], wrapper_class:)
      end
    end

    # Grupo de opções (radio) num fieldset: f.ss_radio_buttons :tipo, [["Pessoa física", "pf"], ["Empresa", "pj"]], label:
    def ss_radio_buttons(method, choices, label: nil, help: nil, inline: true, wrapper_class: nil, **opts)
      ss_no_wrap do
        errs = ss_errors(method)
        items = choices.map do |text, value|
          value = text if value.nil?
          radio = radio_button(method, value, opts.merge(ss_aria(method, errs, help)))
          @template.tag.label(class: "ss-check", for: field_id(method, value)) { @template.safe_join([radio, " ", text]) }
        end
        legend = @template.tag.legend(class: "ss-label") { @template.safe_join([label || ss_human(method), ss_req(method)]) }
        body = @template.tag.div(class: ["ss-radio-row", ("is-stacked" unless inline)]) { @template.safe_join(items) }
        @template.tag.fieldset(class: ["ss-field", "ss-fieldset", ("is-invalid" if errs.any?), wrapper_class]) do
          @template.safe_join([legend, body, ss_help(method, help), ss_error(method, errs)].compact)
        end
      end
    end

    # f.ss_collection_radio_buttons :plano_id, Plano.all, :id, :nome, label:
    def ss_collection_radio_buttons(method, collection, value_method, text_method, **opts)
      ss_radio_buttons(method, collection.map { |o| [o.public_send(text_method), o.public_send(value_method)] }, **opts)
    end

    # Botão de enviar; o texto padrão é "Salvar" (componentes_ui.form.submit).
    # variant: :primary (padrão), :outline, :ghost ou :danger (v0.13); small: true = .ss-btn-sm.
    SUBMIT_VARIANTS = { primary: "ss-btn-primary", outline: "ss-btn-outline", ghost: "ss-btn-ghost", danger: "ss-btn-danger" }.freeze

    def ss_submit(value = nil, css: nil, variant: :primary, small: false, **opts)
      value ||= ss_t("form.submit", default: "Salvar")
      klass = ["ss-btn", SUBMIT_VARIANTS.fetch(variant.to_s.to_sym, SUBMIT_VARIANTS[:primary]), ("ss-btn-sm" if small), css].compact.join(" ")
      submit(value, { class: klass, data: { turbo_submits_with: ss_t("form.submitting", default: "Salvando…") } }.deep_merge(opts))
    end

    # Grupo de campos com legenda e uma ajuda do grupo (v0.13; o SsFieldGroup do Flutter):
    #   <%= f.ss_fieldset legend: "Horário", help: "Vale para todos os dias", class: "grid sm:grid-cols-2 gap-3" do %> … <% end %>
    # class: vai no corpo (a grade dos campos); wrapper_class: no fieldset.
    def ss_fieldset(legend:, help: nil, wrapper_class: nil, **opts, &block)
      body_class = opts.delete(:class)
      @template.ss_fieldset(legend:, help:, wrapper_class:, body_class:, &block)
    end

    private

    # Monta o .ss-field: rótulo, (prefixo) input (sufixo), ajuda, contador e erro.
    def ss_field(method, opts)
      wrapper_class = opts.delete(:wrapper_class)
      label = opts.delete(:label)
      help = opts.delete(:help)
      prefix = opts.delete(:prefix)
      suffix = opts.delete(:suffix)
      counter = opts.delete(:counter)
      ss_no_wrap do
        errs = ss_errors(method)
        io = opts.merge(ss_aria(method, errs, help))
        io[:class] = ["ss-input", io[:class]].compact.join(" ")
        io[:required] = true if !io.key?(:required) && ss_required?(method)
        if counter
          io[:maxlength] ||= counter
          io[:data] = (io[:data] || {}).merge(ss_counter_target: "input", action: [io.dig(:data, :action), "input->ss-counter#update"].compact.join(" "))
        end
        input = yield(io)
        if prefix || suffix
          input = @template.tag.div(class: "ss-affix") do
            @template.safe_join([(@template.tag.span(prefix, class: "ss-affix-pre") if prefix), input,
                                 (@template.tag.span(suffix, class: "ss-affix-suf") if suffix)].compact)
          end
        end
        lbl = @template.tag.label(for: io[:id] || field_id(method)) { @template.safe_join([label || ss_human(method), ss_req(method)]) }
        count = (@template.tag.small("0/#{counter}", class: "ss-counter num", data: { ss_counter_target: "output" }, "aria-live": "polite") if counter)
        ss_wrap(method, errs, help, [lbl, input, count].compact, counter:, wrapper_class:)
      end
    end

    def ss_wrap(method, errs, help, parts, counter: nil, wrapper_class: nil)
      data = counter ? { controller: "ss-counter" } : {}
      @template.tag.div(class: ["ss-field", ("is-invalid" if errs.any?), wrapper_class], data:) do
        @template.safe_join([*parts, ss_help(method, help), ss_error(method, errs)].compact)
      end
    end

    def ss_help(method, help)
      @template.tag.small(help, class: "ss-field-help", id: "#{field_id(method)}_help") if help
    end

    def ss_error(method, errs)
      msg = errs.any? ? errs.map { |m| m.to_s.upcase_first }.uniq.to_sentence : (ss_t("form.required_error", default: "Preencha este campo.") if ss_required?(method))
      @template.tag.small(msg, class: "ss-field-error", id: "#{field_id(method)}_error") if msg
    end

    def ss_aria(method, errs, help)
      ids = []
      ids << "#{field_id(method)}_help" if help
      ids << "#{field_id(method)}_error" if errs.any? || ss_required?(method)
      aria = {}
      aria[:describedby] = ids.join(" ") if ids.any?
      aria[:invalid] = "true" if errs.any?
      aria.any? ? { aria: } : {}
    end

    def ss_errors(method)
      return [] unless object.respond_to?(:errors)

      object.errors[method].to_a
    end

    def ss_required?(method)
      return false unless object&.class.respond_to?(:validators_on)

      object.class.validators_on(method).any? do |v|
        v.kind == :presence && v.options.slice(:if, :unless, :on).empty?
      end
    end

    def ss_req(method)
      @template.tag.abbr("*", class: "ss-req", title: ss_t("form.required", default: "obrigatório")) if ss_required?(method)
    end

    # Texto da gem (componentes_ui.*), com o pt-BR de reserva.
    def ss_t(key, **opts) = I18n.t("componentes_ui.#{key}", **opts)

    def ss_human(method)
      object&.class.respond_to?(:human_attribute_name) ? object.class.human_attribute_name(method) : method.to_s.humanize
    end

    def ss_no_wrap
      was = Thread.current[:componentes_ui_no_error_wrap]
      Thread.current[:componentes_ui_no_error_wrap] = true
      yield
    ensure
      Thread.current[:componentes_ui_no_error_wrap] = was
    end
  end

  # Desliga o <div class="field_with_errors"> só dentro dos f.ss_* (por thread).
  module NoErrorWrap
    private

    def object_has_errors?
      Thread.current[:componentes_ui_no_error_wrap] ? false : super
    end
  end
  ActionView::Helpers::Tags::Base.prepend(NoErrorWrap)
end
