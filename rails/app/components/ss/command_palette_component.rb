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
  #
  # v0.10.1:
  # - subtitle: segunda linha do item (além do hint:, que fica à direita); entra na busca.
  # - fill: sugestão que preenche a busca em vez de navegar: fill: "texto" põe esse texto
  #   no campo (fill: true põe o label) e filtra de novo (o src: busca de novo também).
  # - src: o HTML do servidor pode vir em grupos: <div class="ss-command-group"><p
  #   class="ss-command-group-title">Clientes</p><a class="ss-command-item">…</a></div>
  #   (h2–h4 no lugar do <p> também vale); os títulos ficam. Item com data-ss-command-fill
  #   também preenche.
  #
  # v0.20: with_action { … } (um ou mais) põe botões ao lado da busca (leitor de código de barras, "novo
  # cliente"); par do showSsPicker(actions:). O botão faz o que o app quiser (data-action do controller dele);
  # data-action="ss-command#close" fecha a paleta.
  #   render(Ss::CommandPaletteComponent.new(id: "produto", …)) do |p|
  #     p.with_action { render Ss::IconButtonComponent.new(icon: "qrcode", label: "Ler código", data: { action: "scanner#open" }) }
  #   end
  class CommandPaletteComponent < BaseComponent
    attr_reader :id, :groups

    renders_many :actions

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
      fill = fill_text(it)
      keywords = [it[:keywords], it[:subtitle]].compact.join(" ").presence
      { href: (fill ? nil : it[:url] || it[:href]), class: ["ss-command-item", ("is-fill" if fill)].compact.join(" "), id: "#{id}-o#{gi}-#{ii}",
        role: "option", tabindex: "-1", data: { ss_command_target: "item", text: it[:label], keywords:, ss_command_fill: fill }.compact }
    end

    # Texto que a sugestão põe na busca (nil = item que navega).
    def fill_text(it)
      f = it[:fill]
      return nil if f.nil? || f == false

      f == true ? it[:label].to_s : f.to_s
    end

    def icon(svg) = (svg if svg.respond_to?(:html_safe?) && svg.html_safe?)

    def shortcut_hint = @shortcut && "Ctrl #{@shortcut.upcase}"
  end
end
