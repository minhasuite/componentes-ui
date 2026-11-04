module Ss
  # Paleta de comandos (Ctrl+K / ⌘K): busca que ignora acento, destaca o trecho com <mark>,
  # setas + Enter navegam e Esc fecha. Usa o .ss-command do engine.css.
  #   render Ss::CommandPaletteComponent.new(id: "busca", placeholder: "Buscar…",
  #     groups: [{ title: "Páginas", items: [{ label: "Pedidos", url: pedidos_path, icon: svg, hint: "Vendas" }] }])
  #
  # - shortcut: a letra do Ctrl/⌘ (padrão "k"); nil desliga. Com duas paletas de mesmo
  #   atalho na página, abre a primeira (a do conteúdo antes da do layout).
  # - src: resultados do servidor: GET src?q=… devolvendo HTML com <a class="ss-command-item">
  #   (pode vir dentro de um <turbo-frame>); entram no fim da lista a cada busca.
  # - Abrir de outro lugar: [data-ss-command-open="busca"] em qualquer botão, o evento
  #   "ss-command:open" no <dialog>, ou Ss::AppShellComponent.new(search_action: "busca").
  # icon: SVG já seguro (html_safe). Textos do I18n (componentes_ui.command_palette.*).
  class CommandPaletteComponent < BaseComponent
    attr_reader :id, :groups

    def initialize(id:, placeholder: nil, groups: [], shortcut: "k", src: nil, label: nil, empty: nil, **opts)
      super(**opts)
      @id = id
      @placeholder = placeholder
      @groups = groups.map { |g| g.to_h.transform_keys(&:to_sym) }
      @shortcut = shortcut.to_s.downcase.presence
      @src = src
      @label = label
      @empty = empty
    end

    def placeholder = @placeholder || ss_t("command_palette.placeholder", default: "Buscar…")
    def label = @label || ss_t("command_palette.label", default: "Busca rápida")
    def empty = @empty || ss_t("command_palette.empty", default: "Nada encontrado")

    def dialog_attrs
      root_attrs(id:, class: classes("ss-dialog", "ss-command"), "aria-label": label,
                 data: { controller: "ss-command", ss_command_shortcut_value: @shortcut.to_s, ss_command_src_value: @src,
                         action: "ss-command:open->ss-command#open click->ss-command#backdrop keydown->ss-command#nav close->ss-command#closed" }.compact)
    end

    def item_attrs(it, gi, ii)
      it = it.to_h.transform_keys(&:to_sym)
      { href: it[:url] || it[:href], class: "ss-command-item", id: "#{id}-o#{gi}-#{ii}", role: "option", tabindex: "-1",
        data: { ss_command_target: "item", text: it[:label], keywords: it[:keywords] } }
    end

    def icon(svg) = (svg if svg.respond_to?(:html_safe?) && svg.html_safe?)

    def shortcut_hint = @shortcut && "Ctrl #{@shortcut.upcase}"
  end
end
