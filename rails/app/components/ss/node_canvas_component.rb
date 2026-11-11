module Ss
  # Palco de editor de nós/fluxograma (v0.20): a pele da gem para o Drawflow (ou outra lib que gere a
  # mesma DOM: .drawflow, .drawflow-node, .input/.output, .connection .main-path, .drawflow-delete).
  # O componente desenha o contêiner; a lib e o controller Stimulus de domínio (carregar o grafo, salvar)
  # são do produto. Os atributos extras (data:, id:) vão no palco, que é o elemento que a lib recebe;
  # o bloco fica por cima (barra de ferramentas, zoom, legenda) dentro do .ss-node-canvas-wrap.
  #
  #   render(Ss::NodeCanvasComponent.new(label: "Desenho do fluxo", height: "70vh",
  #                                       data: { canvas_target: "stage" })) { render "barra" }
  #
  # - O palco começa com a classe parent-drawflow (o Drawflow só arrasta o palco quando ela é a 1ª).
  # - grid: false tira a grade de pontos; readonly: true tira as portas e o cursor de mover;
  #   node_delete: false esconde o × do bloco (o bloco sai por um painel; o × da seta continua).
  # - Bloco: o conteúdo do nó é do produto; .ss-node dá a caixa padrão (superfície, fio, raio, sombra).
  #   Decisão (se/senão): .is-branch (ou .is-condition) no .drawflow-node pinta a 1ª saída de verde e a 2ª
  #   de vermelho. Estados no .drawflow-node: .selected (o da lib), .is-changed (brilho verde 3×),
  #   .is-refused/.is-flash (sacode e fica vermelho). Seta: .is-yes/.is-no no .connection pinta;
  #   .is-changed brilha; rótulo da seta é um <text class="ss-node-label"> no svg da conexão.
  #   is-sketch: o app desenha as setas (rough.js) e a .main-path vira só a área de clique.
  # - Reduzir movimento desliga o brilho e a sacudida. Não há versão Flutter (o app não edita fluxo).
  class NodeCanvasComponent < BaseComponent
    def initialize(label: nil, height: nil, grid: true, readonly: false, node_delete: true, sketch: false, **rest)
      super(**rest)
      @label, @height, @grid, @readonly, @node_delete, @sketch = label, height, grid, readonly, node_delete, sketch
    end

    def call
      label = @label || ss_t("node_canvas.label", default: "Editor de fluxo")
      style = [("--ss-node-canvas-h: #{@height}" if @height), @attrs[:style]].compact.join("; ").presence
      stage = tag.div(**root_attrs(class: classes("parent-drawflow", "ss-node-canvas", ("is-grid" if @grid), ("is-readonly" if @readonly),
                                                  ("is-node-delete-off" unless @node_delete), ("is-sketch" if @sketch)),
                                   role: "application", "aria-label": label, tabindex: 0, style:))
      tag.div(class: "ss-node-canvas-wrap") { safe_join([stage, content].compact) }
    end
  end
end
