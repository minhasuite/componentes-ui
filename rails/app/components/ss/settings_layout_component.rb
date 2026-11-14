module Ss
  # Configurações (Modychat Settings): menu de seções à esquerda (chips no celular)
  # e, à direita, cartões com linhas de título, descrição e ação.
  #   render Ss::SettingsLayoutComponent.new(title: "Configurações") do |s|
  #     s.with_section(id: "conta", title: "Conta", description: "Seus dados", icon: svg) do |sec|
  #       sec.with_item(title: "Nome", description: "Como aparece no recibo") { link_to "Editar", … }
  #       sec.with_item(title: "Privacidade", description: "…", href: privacidade_path)   # linha inteira clica, com seta
  #     end
  #   end
  #
  # v0.24 (auditoria de UX, C04/E02/B07): salvar por área, nunca vários "Salvar" soltos numa página só.
  # - form: { model:, url:, method: } na seção: a seção vira um formulário (ss_form_with) com o próprio "Salvar"
  #   numa barra fixa (Ss::StickyActionBarComponent) que só aparece quando aquela área muda e avisa ao sair; o
  #   builder é sec.form. save_label: troca o "Salvar"; save_always: true mostra a barra sempre.
  #     s.with_section(id: "empresa", title: "Empresa", form: { model: @empresa, url: empresa_path }) do |sec|
  #       <%= sec.form.ss_text_field :nome %> …
  #     end
  # - href: (e current: true na da página) faz do menu a navegação entre áreas em páginas próprias: o item vai
  #   para a URL (sem rolar até a âncora nem scrollspy) e só a seção atual (current:) aparece no corpo.
  #     s.with_section(id: "empresa", title: "Empresa", href: config_path(:empresa), current: @area == "empresa", form: {…}) { … }
  class SettingsLayoutComponent < BaseComponent
    class Section < ViewComponent::Base
      class Item < ViewComponent::Base
        def initialize(title:, description: nil, href: nil, danger: false)
          @title = title
          @description = description
          @href = href
          @danger = danger
        end

        def call
          text = tag.div(safe_join([tag.h3(@title), (tag.p(@description) if @description)].compact), class: "ss-settings-text")
          klass = ["ss-settings-row", ("is-danger" if @danger)].compact.join(" ")
          if @href
            chev = '<svg class="ss-settings-chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M9 6l6 6-6 6"/></svg>'.html_safe
            link_to(safe_join([text, (tag.span(content, class: "ss-settings-value") if content?), chev].compact), @href, class: klass)
          else
            tag.div(safe_join([text, (tag.div(content, class: "ss-settings-action") if content?)].compact), class: klass)
          end
        end
      end

      renders_many :items, Item
      attr_reader :id, :title, :icon, :href, :form

      def initialize(id:, title:, description: nil, icon: nil, href: nil, current: false, form: nil, save_label: nil, save_always: false)
        @id = id
        @title = title
        @description = description
        @icon = icon
        @href = href
        @current = current
        @form_opts = form&.to_h
        @save_label = save_label
        @save_always = save_always
      end

      def current? = @current
      def form? = !@form_opts.nil?

      def call
        head = tag.header(safe_join([tag.h2(@title, id: "#{@id}-titulo"), (tag.p(@description) if @description)].compact))
        body = form? ? form_body : safe_join([items_html, (content if content?)].compact)
        tag.section(safe_join([head, body].compact), id: @id, class: ["ss-settings-section", ("has-form" if form?)].compact.join(" "),
                                                     "aria-labelledby": "#{@id}-titulo")
      end

      private

      def items_html = (tag.div(safe_join(items), class: "ss-settings-card ss-card") if items.any?)

      # O formulário da área: o conteúdo (campos pelo sec.form), as linhas e a barra de salvar da área.
      def form_body
        opts = @form_opts.dup
        html = opts.delete(:html).to_h
        html[:class] = ["ss-form ss-settings-form", html[:class], opts.delete(:class)].compact.join(" ")
        data = html[:data].to_h.transform_keys(&:to_sym)
        html[:data] = data.merge(controller: [data[:controller], "ss-validate"].compact.join(" "),
                                 ss_validate_required_value: I18n.t("componentes_ui.form.required_error", default: "Preencha este campo."))
        form_with(**opts, builder: ComponentesUi::FormBuilder, html:) do |f|
          @form = f
          inner = content if content?
          safe_join([items_html, inner, render(Ss::StickyActionBarComponent.new(save_label: @save_label, always: @save_always))].compact)
        end
      end
    end

    renders_many :sections, Section

    def initialize(title: nil, nav_label: nil, **opts)
      super(**opts)
      @title = title
      @nav_label = nav_label || ss_t("settings_layout.nav", default: "Seções")
    end

    # v0.24: áreas em páginas (alguma seção com href:): o menu navega e só a atual aparece.
    def pages? = sections.any?(&:href)
    def shown_sections = pages? ? sections.select { |s| s.current? || s.href.nil? } : sections
    def nav_href(s) = s.href || "##{s.id}"
    def nav_current?(s, i) = pages? ? s.current? : i.zero?

    def icon(svg)
      svg if svg.respond_to?(:html_safe?) && svg.html_safe?
    end
  end
end
