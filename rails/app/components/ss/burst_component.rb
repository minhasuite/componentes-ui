module Ss
  # Estouro de risquinhos em volta do conteúdo (v1.9, par do SsBurst): count traços saem do contorno, andam
  # distance px para fora e somem, uma vez (~450 ms). O "deu certo" da caixa marcada, da estrela, do favorito.
  #
  #   <%= render Ss::BurstComponent.new(on: :change) do %><%= f.check_box :feito %><% end %>   (toca ao marcar)
  #   <%= render Ss::BurstComponent.new(tone: :warn) do %><button class="ss-icon-btn">…</button><% end %>   (toca no clique)
  #
  # on: :click (padrão) | :change (só quando um checkbox/radio de dentro fica marcado) | :connect (ao aparecer) |
  # :manual (data-action="ss-burst#play" ou o evento "ss:burst" no elemento). tone: :accent | :success | :warn |
  # :danger. radius: px a partir do centro (padrão metade do lado menor). Decoração: fora do leitor de tela.
  # Reduzir movimento: não toca.
  class BurstComponent < BaseComponent
    TRIGGERS = %i[click change connect manual].freeze
    TONES = %i[accent success warn danger].freeze

    def initialize(on: :click, count: 7, distance: 14, radius: nil, tone: :accent, **rest)
      super(**rest)
      @on = TRIGGERS.include?(on&.to_sym) ? on.to_sym : :click
      @count, @distance, @radius = count.to_i.clamp(3, 24), distance.to_i.clamp(4, 64), radius&.to_i
      @tone = TONES.include?(tone&.to_sym) ? tone.to_sym : :accent
    end

    def call
      action = { click: "click->ss-burst#play", change: "change->ss-burst#changed", manual: "ss:burst->ss-burst#play" }[@on]
      tag.span(content, **root_attrs(class: classes("ss-burst"), data: { controller: "ss-burst", tone: @tone, action:, ss_burst_count_value: @count,
                                                                         ss_burst_distance_value: @distance, ss_burst_radius_value: @radius,
                                                                         ss_burst_auto_value: (@on == :connect || nil) }.compact))
    end
  end
end
