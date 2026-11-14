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
  # - v0.19: f.ss_file_field (arquivo: accept:, multiple:) e f.ss_color_field (cor livre do usuário, a
  #   amostra do navegador no desenho do campo).
  # - v0.13: wrapper_class: em todo f.ss_* vai no .ss-field (coluna de grade sem <div> a mais);
  #   ss_select(selected:) sem model; ss_submit(variant: :outline/:ghost/:danger); f.ss_fieldset
  #   agrupa campos com legenda e uma ajuda do grupo.
  # - v0.20: hide_label: true em todo f.ss_* (o rótulo fica só para o leitor de tela, .ss-sr; par do
  #   SsTextField(hideLabel:)); mask: :document (CPF/CNPJ), :phone ou :cep no f.ss_text_field/ss_telephone_field
  #   (Stimulus ss-mask; par do SsMask); f.ss_radio_buttons(checked:) marca a opção sem model (par do
  #   SsRadioGroup(value:)); o id: passado ao f.ss_check_box vale no for= do rótulo.
  class FormBuilder < ActionView::Helpers::FormBuilder
    TEXT_KINDS = %i[text_field email_field number_field password_field telephone_field url_field search_field date_field
                    datetime_local_field time_field month_field text_area file_field color_field].freeze

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
    def ss_check_box(method, label: nil, help: nil, checked_value: "1", unchecked_value: "0", wrapper_class: nil, hide_label: false, **opts)
      ss_no_wrap do
        errs = ss_errors(method)
        box = check_box(method, opts.merge(ss_aria(method, errs, help)), checked_value, unchecked_value)
        text = label || ss_human(method)
        text = @template.tag.span(text, class: "ss-sr") if hide_label
        lbl = @template.tag.label(class: "ss-check", for: opts[:id] || field_id(method)) { @template.safe_join([box, " ", text, ss_req(method)]) }
        ss_wrap(method, errs, help, [lbl], wrapper_class:)
      end
    end

    # Grupo de opções (radio) num fieldset: f.ss_radio_buttons :tipo, [["Pessoa física", "pf"], ["Empresa", "pj"]], label:
    # checked: (v0.20) o valor marcado quando não há model (ou para sobrepor o dele); hide_label: a legenda só
    # para o leitor de tela.
    NO_CHECKED = Object.new.freeze

    def ss_radio_buttons(method, choices, label: nil, help: nil, inline: true, wrapper_class: nil, checked: NO_CHECKED, hide_label: false, **opts)
      ss_no_wrap do
        errs = ss_errors(method)
        items = choices.map do |text, value|
          value = text if value.nil?
          ropts = opts.merge(ss_aria(method, errs, help))
          ropts[:checked] = checked.to_s == value.to_s unless checked.equal?(NO_CHECKED)
          radio = radio_button(method, value, ropts)
          @template.tag.label(class: "ss-check", for: field_id(method, value)) { @template.safe_join([radio, " ", text]) }
        end
        legend = @template.tag.legend(class: ["ss-label", ("ss-sr" if hide_label)]) { @template.safe_join([label || ss_human(method), ss_req(method)]) }
        body = @template.tag.div(class: ["ss-radio-row", ("is-stacked" unless inline)]) { @template.safe_join(items) }
        @template.tag.fieldset(class: ["ss-field", "ss-fieldset", ("is-invalid" if errs.any?), wrapper_class]) do
          @template.safe_join([legend, body, ss_help(method, help), ss_error(method, errs)].compact)
        end
      end
    end

    # v0.23 (par do SsFilterChip): caixa de marcar em forma de chip (.ss-chip com o input dentro; marcada fica no
    # degradê), para filtros e escolhas curtas lado a lado. Sem o .ss-field em volta: ponha num .ss-chips/flex.
    #   <%= f.ss_chip_check_box "rooms[]", label: "Sala", checked_value: "sala", unchecked_value: nil, checked: true %>
    # icon: antes do texto; o resto (id:, data:, checked:, disabled:) vai no input.
    def ss_chip_check_box(method, label: nil, checked_value: "1", unchecked_value: "0", icon: nil, **opts)
      ss_no_wrap do
        box = check_box(method, opts, checked_value, unchecked_value)
        @template.tag.label(class: "ss-chip") { @template.safe_join([box, ss_chip_icon(icon), label || ss_human(method)].compact) }
      end
    end

    # Grupo de chips de uma escolha só (radio): f.ss_chip_radio_buttons :modo, [["Limpar", "clean"], ["Aspirar", "vacuum"]],
    # label: (legenda, pode ficar só para o leitor com hide_label: true), checked: sem model.
    def ss_chip_radio_buttons(method, choices, label: nil, hide_label: false, checked: NO_CHECKED, wrapper_class: nil, **opts)
      ss_no_wrap do
        items = choices.map do |text, value|
          value = text if value.nil?
          ropts = opts.dup
          ropts[:checked] = checked.to_s == value.to_s unless checked.equal?(NO_CHECKED)
          @template.tag.label(class: "ss-chip") { @template.safe_join([radio_button(method, value, ropts), text]) }
        end
        legend = (@template.tag.legend(label, class: ["ss-label", ("ss-sr" if hide_label)]) if label)
        @template.tag.fieldset(class: ["ss-fieldset", "ss-chip-group", wrapper_class]) do
          @template.safe_join([legend, @template.tag.div(@template.safe_join(items), class: "ss-chips")].compact)
        end
      end
    end

    # f.ss_collection_radio_buttons :plano_id, Plano.all, :id, :nome, label:
    def ss_collection_radio_buttons(method, collection, value_method, text_method, **opts)
      ss_radio_buttons(method, collection.map { |o| [o.public_send(text_method), o.public_send(value_method)] }, **opts)
    end

    # Botão de enviar; o texto padrão é "Salvar" (componentes_ui.form.submit).
    # variant: :primary (padrão), :outline, :ghost ou :danger (v0.13); small: true = .ss-btn-sm.
    # Máscaras do f.ss_text_field(mask:) → tamanho já formatado (v0.20).
    MASKS = { "document" => 18, "phone" => 15, "cep" => 9 }.freeze

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

    def ss_chip_icon(icon)
      return nil if icon.blank?
      return icon if icon.respond_to?(:html_safe?) && icon.html_safe?

      @template.ss_icon(icon.to_s, size: :xs)
    end

    # Monta o .ss-field: rótulo, (prefixo) input (sufixo), ajuda, contador e erro.
    def ss_field(method, opts)
      wrapper_class = opts.delete(:wrapper_class)
      label = opts.delete(:label)
      help = opts.delete(:help)
      prefix = opts.delete(:prefix)
      suffix = opts.delete(:suffix)
      counter = opts.delete(:counter)
      hide_label = opts.delete(:hide_label)
      mask = opts.delete(:mask)
      ss_no_wrap do
        errs = ss_errors(method)
        io = opts.merge(ss_aria(method, errs, help))
        io[:class] = ["ss-input", io[:class]].compact.join(" ")
        io[:required] = true if !io.key?(:required) && ss_required?(method)
        if mask
          kind = mask.to_s
          raise ArgumentError, "mask: #{kind} (use :document, :phone ou :cep)" unless MASKS.key?(kind)

          io[:inputmode] ||= kind == "phone" ? "tel" : "numeric"
          io[:autocomplete] ||= { "phone" => "tel", "cep" => "postal-code" }.fetch(kind, "off")
          io[:maxlength] ||= MASKS[kind]
          io[:data] = (io[:data] || {}).merge(ss_mask_kind_value: kind,
                                              controller: [io.dig(:data, :controller), "ss-mask"].compact.join(" "),
                                              action: [io.dig(:data, :action), "input->ss-mask#format"].compact.join(" "))
        end
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
        lbl = @template.tag.label(for: io[:id] || field_id(method), class: ("ss-sr" if hide_label)) { @template.safe_join([label || ss_human(method), ss_req(method)]) }
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
