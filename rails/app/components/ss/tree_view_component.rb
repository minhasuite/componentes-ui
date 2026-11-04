module Ss
  # Árvore (plano de contas, categorias) com <details>: recuo, contagem e valor por nó.
  # Teclado (controller ss-tree): ↑ ↓ andam, → abre/entra, ← fecha/sobe, Home/End.
  #   render Ss::TreeViewComponent.new(label: "Plano de contas", nodes: [
  #     { label: "Receitas", value: "R$ 12.400,00", count: 3, open: true, children: [{ label: "Vendas", value: "R$ 9.000,00", url: "…" }] }])
  class TreeViewComponent < BaseComponent
    def initialize(nodes:, label: "Árvore", **opts)
      super(**opts)
      @nodes = nodes
      @label = label
    end

    def call
      tag.div(**root_attrs(class: classes("ss-tree"), role: "group", "aria-label": @label, data: { controller: "ss-tree", action: "keydown->ss-tree#key" })) do
        list(@nodes, 0)
      end
    end

    private

    def list(nodes, level)
      tag.ul(style: "--level:#{level}") { safe_join(nodes.map { node(_1, level) }) }
    end

    def node(n, level)
      tag.li do
        if n[:children].present?
          tag.details(open: n[:open] ? true : nil) do
            safe_join([tag.summary(row(n), class: "ss-tree-row", data: { ss_tree_item: true }), list(n[:children], level + 1)])
          end
        elsif n[:url]
          link_to(row(n), n[:url], class: "ss-tree-row is-leaf", data: { ss_tree_item: true })
        else
          tag.span(row(n), class: "ss-tree-row is-leaf", tabindex: -1, data: { ss_tree_item: true })
        end
      end
    end

    def row(n)
      safe_join([
        tag.span(n[:label], class: "ss-tree-label"),
        (tag.small(n[:count], class: "ss-tree-count num", "aria-label": "#{n[:count]} itens") if n[:count]),
        (tag.span(n[:value], class: "ss-tree-value num") if n[:value])
      ].compact)
    end
  end
end
