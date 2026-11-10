module Ss
  # Botão flutuante com várias ações (v0.18, par do SsSpeedDial): o "+" no canto abre a lista de ações
  # acima dele (rótulo + ícone), o "+" vira "×", e Esc, clique fora, Tab para fora ou escolher uma ação
  # fecham. Fica no mesmo lugar do Ss::FabComponent (canto de baixo, área segura, acima da
  # .ss-sticky-bar, lift:) e some na impressão. Com UMA ação só, vira o Ss::FabComponent dela.
  #
  #   render Ss::SpeedDialComponent.new(items: [
  #     { label: "Novo lançamento", icon: "plus", href: new_lancamento_path, turbo_frame: "modal" },
  #     { label: "Assistente", icon: "chat-bubble-left-right", action: "assistant#toggle" },
  #   ])
  #
  # Item: label: (obrigatório); icon: nome do ss_icon ("plus") ou SVG já seguro (html_safe);
  # href: vira <a> (turbo_frame: põe data-turbo-frame; method: :post/:delete põe data-turbo-method);
  # sem href, <button type="button"> com action: (o data-action do app, ex. "assistant#toggle"; a ação
  # do botão alcança controllers ancestrais: envolva o componente no elemento do controller do app);
  # data: {} e id: vão no item.
  #
  # label: é o nome do botão (aria-label e dica; padrão "Ações rápidas"); icon: troca o "+" (nome ou
  # SVG). position: :end/:start, lift:, static:, permanent: e id: como no FabComponent. Acessível:
  # aria-expanded/aria-controls/aria-haspopup no botão, role=menu/menuitem na lista, ↑ ↓ Home End
  # movem o foco, Esc fecha e devolve o foco ao botão.
  class SpeedDialComponent < BaseComponent
    def initialize(items:, label: nil, icon: "plus", position: :end, lift: nil, static: false, permanent: false,
                   id: "ss-speed-dial", **rest)
      super(id:, **rest)
      @items = Array(items).compact.map { |i| i.to_h.transform_keys(&:to_sym) }.reject { |i| i[:label].blank? }
      @label = label.presence || ss_t("speed_dial.label", default: "Ações rápidas")
      @icon, @id = icon, id.to_s
      @position = position.to_s == "start" ? :start : :end
      @lift = lift.to_s[/\A[\d.]+(px|rem|em|vh)\z/]
      @static, @permanent = static, permanent
    end

    def render? = @items.any?

    def call
      return single if @items.one?

      attrs = root_attrs(class: classes("ss-speed-dial", ("is-start" if @position == :start), ("is-static" if @static)),
                         style: ("--ss-fab-lift: #{@lift}" if @lift),
                         data: { controller: "ss-speed-dial", turbo_permanent: (true if @permanent),
                                 action: "keydown->ss-speed-dial#key focusout->ss-speed-dial#blur" }.compact)
      tag.div(**attrs) do
        safe_join([
          tag.div(safe_join(@items.map { |i| item(i) }), id: "#{@id}-menu", class: "ss-speed-dial-menu", role: "menu",
                                                         "aria-label": @label, hidden: true, data: { ss_speed_dial_target: "menu" }),
          tag.button(type: "button", class: "ss-fab is-icon is-still is-static ss-speed-dial-toggle", title: @label,
                     "aria-label": @label, "aria-expanded": "false", "aria-haspopup": "menu", "aria-controls": "#{@id}-menu",
                     data: { ss_speed_dial_target: "button", action: "ss-speed-dial#toggle" }) do
            tag.span(icon_svg(@icon), class: "ss-fab-ico", "aria-hidden": "true")
          end
        ])
      end
    end

    private

    # Uma ação só: o botão flutuante dela, sem lista.
    def single
      i = @items.first
      data = item_data(i)
      render(Ss::FabComponent.new(icon: icon_svg(i[:icon]), label: i[:label], href: i[:href], position: @position, lift: @lift,
                                  static: @static, permanent: @permanent, id: @id, css: @css, data:))
    end

    def item(i)
      body = safe_join([tag.span(i[:label], class: "ss-speed-dial-label"),
                        tag.span(icon_svg(i[:icon]), class: "ss-speed-dial-ico", "aria-hidden": "true")])
      attrs = { class: "ss-speed-dial-item", role: "menuitem", tabindex: "-1", id: i[:id],
                data: item_data(i).merge(ss_speed_dial_target: "item") }.compact
      attrs[:data][:action] = ["click->ss-speed-dial#chosen", attrs[:data][:action]].compact.join(" ")
      i[:href] ? link_to(i[:href], **attrs) { body } : tag.button(type: "button", **attrs) { body }
    end

    def item_data(i)
      d = i[:data].to_h.transform_keys(&:to_sym)
      d[:turbo_frame] = i[:turbo_frame] if i[:turbo_frame]
      d[:turbo_method] = i[:method] if i[:method] && i[:href]
      d[:action] = [d[:action], i[:action]].compact.join(" ").presence
      d.compact
    end

    def icon_svg(icon)
      return "".html_safe if icon.blank?
      return icon if icon.respond_to?(:html_safe?) && icon.html_safe?

      ss_icon(icon.to_s, size: nil)
    end
  end
end
