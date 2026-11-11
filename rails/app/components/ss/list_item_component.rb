module Ss
  # Item de lista (v0.20, par do SsListItem): o .ss-item como componente, com ícone tonal, título,
  # subtítulo, valor em DM Mono à direita e o que vier no bloco (chevron, ações) no fim.
  #
  #   render Ss::ListItemComponent.new(title: "Boleto 123", subtitle: "Vence hoje", subtitle_tone: :danger,
  #                                    value: ss_money(120), value_caption: "parcela 2/3", icon: "document-text",
  #                                    href: titulo_path(t), dimmed: t.pago?)
  #
  # subtitle_tone:/value_tone: :danger, :warn, :success, :accent, :info, :muted pintam o texto (data-tone);
  # tone: o do ícone (o --tone do .ss-item, como no CardHeaderComponent); icon: nome do ss_icon ou SVG
  # html_safe; href: vira <a> (sem ele, <div>); dimmed: true apaga a linha (.is-dimmed: concluído,
  # arquivado, inativo). money: true põe os centavos menores no valor (ss_amount).
  class ListItemComponent < BaseComponent
    def initialize(title:, subtitle: nil, subtitle_tone: nil, value: nil, value_caption: nil, value_tone: nil, icon: nil,
                   tone: nil, href: nil, dimmed: false, money: false, **rest)
      super(**rest)
      @title, @subtitle, @value, @value_caption, @icon, @href = title, subtitle, value, value_caption, icon, href
      @subtitle_tone, @value_tone = tone_name(subtitle_tone), tone_name(value_tone)
      @tone, @dimmed, @money = tone, dimmed, money
    end

    def call
      tone = Ss::CardHeaderComponent.tone_css(@tone)
      attrs = root_attrs(class: classes("ss-item", ("is-dimmed" if @dimmed)), style: ([@attrs[:style], ("--tone: #{tone}" if tone)].compact.join("; ").presence))
      body = safe_join([
        (tag.span(icon_svg, class: "ss-item-icon", "aria-hidden": "true") if @icon.present?),
        tag.span(class: "ss-item-main") do
          safe_join([tag.strong(@title), (tag.small(@subtitle, class: "ss-item-sub", data: { tone: @subtitle_tone }.compact) if @subtitle.present?)].compact)
        end,
        (if @value.present?
           tag.span(class: "ss-item-value", data: { tone: @value_tone }.compact) do
             safe_join([(@money ? ss_amount(@value) : @value), (tag.small(@value_caption) if @value_caption.present?)].compact)
           end
         end),
        content
      ].compact)
      @href ? link_to(@href, **attrs) { body } : tag.div(**attrs) { body }
    end

    private

    def tone_name(t) = t && ComponentesUi.tone(t).to_s

    def icon_svg
      return @icon if @icon.respond_to?(:html_safe?) && @icon.html_safe?

      ss_icon(@icon.to_s)
    end
  end
end
