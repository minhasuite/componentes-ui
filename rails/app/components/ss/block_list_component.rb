module Ss
  # Lista ordenada de blocos recolhíveis (<details>): o núcleo genérico de um editor de automação.
  # Cada bloco: ícone, título, resumo, liga/desliga, ⋮ com mover para cima/baixo, duplicar e excluir,
  # e o corpo (o formulário do app). Aninha: o corpo de um bloco pode ter outra BlockList.
  #
  #   render Ss::BlockListComponent.new(name: "automacao[passos]") do |l|
  #     l.with_block(id: "g1", title: "Quando", summary: "A porta abrir", icon: svg, tone: :warn, open: true) do
  #       …campos…
  #     end
  #     l.with_block(id: "a1", title: "Avisar", error: "Escolha para quem avisar.", delete_url: passo_path(p))
  #   end
  #
  # Cada bloco manda name[id][position] (hidden) e name[id][enabled] (chave). Mover (controller
  # ss-block-list) troca a ordem no DOM e renumera as posições. Duplicar/excluir: com
  # duplicate_url:/delete_url: viram link Turbo (POST/DELETE); sem URL, disparam
  # "ss-block-list:duplicate|delete" (detail: { id }); excluir sem URL e sem preventDefault tira
  # o bloco da lista. tone: :accent | :info | :warn | :success | :danger. focused: true põe o anel.
  class BlockListComponent < BaseComponent
    DEFAULTS = { move_up: "Mover para cima", move_down: "Mover para baixo", duplicate: "Duplicar", delete: "Excluir",
                 enabled: "Ativo: %{title}", more: "Mais opções", moved: "Movido para a posição %{n}", list: "Blocos" }.freeze

    renders_many :blocks, lambda { |**kw|
      @position = (@position || -1) + 1
      BlockComponent.new(list: self, position: @position, **kw)
    }

    attr_reader :name

    def initialize(name: "blocks", label: nil, labels: {}, **rest)
      super(**rest)
      @name, @label = name, label
      @labels = labels.to_h.transform_keys(&:to_sym)
    end

    def label(key, **vars)
      text = @labels[key] || ss_t("block_list.#{key}", default: DEFAULTS[key], **vars)
      I18n.interpolate(text, vars)
    end

    def list_label = @label || label(:list)

    def root_data
      own = @attrs.to_h[:data].to_h
      { controller: [own[:controller] || own["controller"], "ss-block-list"].compact.join(" "),
        ss_block_list_moved_value: label(:moved, n: "{n}") }
    end

    def call
      tag.div(**root_attrs(class: classes("ss-blocks"), data: root_data)) do
        safe_join([
          tag.ol(safe_join(blocks.map(&:to_s)), class: "ss-blocks-list", aria: { label: list_label }, data: { ss_block_list_target: "list" }),
          tag.p(class: "ss-sr", role: "status", data: { ss_block_list_target: "live" })
        ])
      end
    end
  end
end
