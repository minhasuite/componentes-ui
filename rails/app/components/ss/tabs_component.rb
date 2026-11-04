module Ss
  # Abas com indicador que desliza. Cada aba pode ser:
  #  - painel na página (bloco da aba);
  #  - turbo-frame preguiçoso (frame_src:), que só carrega quando a aba abre;
  #  - link de navegação (href:), marcada pela current:.
  # Teclado: ← → Home End.
  # Movimento: o sublinhado anda como minhoca (ss-indicator, kind line) e o rótulo novo sobe
  # 2 px e volta com a mola (ss-tabs); com menos movimento, só troca.
  #   render Ss::TabsComponent.new(label: "Seções do pedido") do |t|
  #     t.with_tab(label: "Itens", selected: true) { … }
  #     t.with_tab(label: "Histórico", frame_src: historico_pedido_path(@pedido))
  #     t.with_tab(label: "Notas", href: notas_path, current: false)
  #   end
  #
  # v0.10.1: icon: (svg, como nos outros componentes da gem; Ss::CasaIcons.svg(:home) serve)
  # antes do rótulo. Muitas abas: a faixa rola na horizontal (sem quebrar linha nem barra
  # visível) e a aba marcada entra na vista ao abrir a página e ao trocar (só a faixa rola;
  # com menos movimento, sem animação). O sublinhado acompanha a rolagem.
  class TabsComponent < BaseComponent
    class Tab < ViewComponent::Base
      attr_reader :label, :href, :frame_src, :badge, :icon
      attr_accessor :key, :selected

      def initialize(label:, href: nil, frame_src: nil, selected: false, current: false, badge: nil, id: nil, icon: nil)
        @label = label
        @icon = icon
        @href = href
        @frame_src = frame_src
        @selected = selected || current
        @badge = badge
        @id = id
      end

      def id_suffix = @id || label.to_s.parameterize.presence || "aba"
      def link? = href.present?
      def call = content
    end

    renders_many :tabs, Tab

    def initialize(label: nil, id: nil, **opts)
      super(**opts)
      @label = label || ss_t("tabs.label", default: "Abas")
      # O id não muda com o idioma: sai do label passado pelo app ou de "abas".
      @id = id || "ss-tabs-#{label.to_s.parameterize.presence || "abas"}"
    end

    def before_render
      tabs.first.selected = true if tabs.any? && tabs.none?(&:selected)
      tabs.each { |t| t.key = "#{@id}-#{t.id_suffix}" }
    end

    def panels? = tabs.any? { !_1.link? }
  end
end
