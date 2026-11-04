module Ss
  # Configurações (Modychat Settings): menu de seções à esquerda (chips no celular)
  # e, à direita, cartões com linhas de título, descrição e ação.
  #   render Ss::SettingsLayoutComponent.new(title: "Configurações") do |s|
  #     s.with_section(id: "conta", title: "Conta", description: "Seus dados", icon: svg) do |sec|
  #       sec.with_item(title: "Nome", description: "Como aparece no recibo") { link_to "Editar", … }
  #       sec.with_item(title: "Privacidade", description: "…", href: privacidade_path)   # linha inteira clica, com seta
  #     end
  #   end
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
      attr_reader :id, :title, :icon

      def initialize(id:, title:, description: nil, icon: nil)
        @id = id
        @title = title
        @description = description
        @icon = icon
      end

      def call
        body = items.any? ? tag.div(safe_join(items), class: "ss-settings-card ss-card") : nil
        head = tag.header(safe_join([tag.h2(@title, id: "#{@id}-titulo"), (tag.p(@description) if @description)].compact))
        tag.section(safe_join([head, body, (content if content?)].compact), id: @id, class: "ss-settings-section", "aria-labelledby": "#{@id}-titulo")
      end
    end

    renders_many :sections, Section

    def initialize(title: nil, nav_label: "Seções", **opts)
      super(**opts)
      @title = title
      @nav_label = nav_label
    end

    def icon(svg)
      svg if svg.respond_to?(:html_safe?) && svg.html_safe?
    end
  end
end
