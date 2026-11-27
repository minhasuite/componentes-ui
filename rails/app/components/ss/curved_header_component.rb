module Ss
  # Cabeçalho escuro que termina numa curva côncava (v1.10, par do SsCurvedHeader): o fundo (a cor funda da
  # marca ou a superfície escura) desce overlap: px por trás do conteúdo seguinte, que sobe por cima dele.
  # Título, voltar opcional, ações e um bottom (abas, segmentado). Texto sempre claro (--on-accent).
  #
  #   render(Ss::CurvedHeaderComponent.new(title: "Carteira", subtitle: "Novembro", back_href: root_path)) do |h|
  #     h.with_action { render Ss::IconButtonComponent.new(icon: "cog", label: "Ajustes", href: ajustes_path, css: "is-on-grad") }
  #     h.with_bottom { render Ss::SegmentedComponent.new(...) }
  #   end
  #   <div class="ss-curved-body">…o conteúdo que sobe por cima…</div>
  #
  # tone: :brand (padrão) | :dark. curve: px da curva (28). overlap: px que o fundo desce (36).
  # back_href: o "voltar" (rótulo componentes_ui.curved_header.back) ou with_leading com o que quiser.
  # O título centraliza quando há voltar ou ações; sem eles, alinha à esquerda (como no Flutter).
  class CurvedHeaderComponent < BaseComponent
    TONES = %i[brand dark].freeze
    renders_one :leading
    renders_many :actions
    renders_one :bottom

    def initialize(title:, subtitle: nil, tone: :brand, curve: 28, overlap: 36, back_href: nil, back_label: nil,
                   heading: :h1, **rest)
      super(**rest)
      @title, @subtitle, @back_href, @heading = title, subtitle, back_href, heading
      @tone = TONES.include?(tone&.to_sym) ? tone.to_sym : :brand
      @curve, @overlap = curve.to_i.clamp(0, 120), overlap.to_i.clamp(0, 240)
      @back_label = back_label || ss_t("curved_header.back", default: "Voltar")
    end

    def lead
      return leading if leading?
      return nil unless @back_href

      link_to(ss_icon("arrow-left", size: nil), @back_href, class: "ss-curved-btn", "aria-label": @back_label, title: @back_label)
    end

    def call
      l = lead
      centered = l || actions?
      tag.header(**root_attrs(class: classes("ss-curved", ("is-centered" if centered)), style: "--curve:#{@curve}px;--overlap:#{@overlap}px",
                              data: { tone: @tone })) do
        safe_join([
          tag.div(class: "ss-curved-bg", "aria-hidden": "true"),
          tag.div(class: "ss-curved-row") do
            safe_join([
              (l ? tag.div(l, class: "ss-curved-lead") : (tag.span(class: "ss-curved-lead") if centered)),
              content_tag(@heading, @title, class: "ss-curved-title"),
              (actions? ? tag.div(safe_join(actions), class: "ss-curved-actions") : (tag.span(class: "ss-curved-actions") if centered))
            ].compact)
          end,
          (tag.p(@subtitle, class: "ss-curved-sub") if @subtitle),
          (tag.div(bottom, class: "ss-curved-bottom") if bottom?)
        ].compact)
      end
    end
  end
end
