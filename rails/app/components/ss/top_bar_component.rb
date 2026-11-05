module Ss
  # Barra de topo compacta (v0.10.2, mesmo papel do SsTopBar do Flutter) para a tela cheia que
  # não usa o cabeçalho grande do PageComponent: mapa, câmera, quiosque, editor ao vivo.
  #
  #   render Ss::TopBarComponent.new(title: "Mapa", subtitle: "Casa da praia", back: site_path(@site), variant: :overlay) do |b|
  #     b.with_action { button_tag icon, class: "ss-icon-btn", title: "Centralizar", "aria-label": "Centralizar" }
  #   end
  #
  # - variant: :surface (padrão, fundo da página com vidro), :dark (câmera, foto) ou :overlay
  #   (transparente com véu sobre o mapa/planta; o pai precisa de position: relative).
  # - sticky: false tira o grudar no topo. back: (url) põe o voltar (.ss-icon-btn) com
  #   back_label: (padrão top_bar.back). with_title troca o título de texto (ex.: um seletor).
  class TopBarComponent < BaseComponent
    VARIANTS = %i[surface dark overlay].freeze
    BACK = %(<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M19 12H5m6-6-6 6 6 6"/></svg>).freeze

    renders_many :actions
    renders_one :title_slot

    def initialize(title: nil, subtitle: nil, back: nil, back_label: nil, variant: :surface, sticky: true, tag: :header, **opts)
      super(**opts)
      @title, @subtitle, @back, @back_label = title, subtitle, back, back_label
      @variant = VARIANTS.include?(variant.to_s.to_sym) ? variant.to_s.to_sym : :surface
      @sticky = sticky
      @tag = tag
    end

    attr_reader :title, :subtitle, :back

    def back_label = @back_label || ss_t("top_bar.back", default: "Voltar")

    def bar_attrs
      root_attrs(class: classes("ss-topbar", ("is-#{@variant}" unless @variant == :surface), ("is-static" unless @sticky)))
    end

    def call
      content_tag(@tag, **bar_attrs) do
        safe_join([
          (link_to(BACK.html_safe, back, class: "ss-icon-btn", title: back_label, "aria-label": back_label) if back),
          tag.div(class: "ss-topbar-titles") do
            safe_join([title_slot? ? title_slot : (tag.h1(title, class: "ss-topbar-title") if title),
                       (tag.span(subtitle, class: "ss-topbar-sub") if subtitle)].compact)
          end,
          (tag.div(safe_join(actions), class: "ss-topbar-actions") if actions?)
        ].compact)
      end
    end
  end
end
