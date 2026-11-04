module Ss
  # Card com aba de situação no topo (recorte em S), avatares e progresso ao lado
  # da aba, ícone em losango, título, subtítulo e menu (bloco = itens do menu ⋮).
  #   render Ss::StatusTabCardComponent.new(status: "Concluída", tone: :success, title: "Web design",
  #     subtitle: "Projeto do cliente", progress: 1.0, people: ["Ana Souza", "Bruno Lima"], url: tarefa_path(t))
  # tone: accent, success, warn, danger, info.
  class StatusTabCardComponent < BaseComponent
    ICON = %(<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M5 7l1.5 1.5L9 6M12 7.5h7M5 15l1.5 1.5L9 14M12 15.5h7"/></svg>).freeze

    def initialize(status:, title:, tone: :accent, subtitle: nil, progress: nil, people: [], icon: nil, url: nil, **opts)
      super(**opts)
      @status = status
      @title = title
      @tone = tone
      @subtitle = subtitle
      @progress = progress
      @people = people
      @icon = icon
      @url = url
    end

    def call
      pct = @progress && (@progress.to_f.clamp(0, 1) * 100).round
      tag.article(**root_attrs(class: classes("ss-tabcard"), data: { tone: @tone })) do
        safe_join([
          tag.div(class: "ss-tabcard-top") do
            safe_join([
              tag.span(@status, class: "ss-tabcard-tab"),
              (tag.span(class: "ss-avatars") { safe_join(@people.first(3).map { ss_avatar(_1, size: 30) } + (@people.size > 3 ? [tag.span("+#{@people.size - 3}", class: "ss-avatar more", style: "--s:30px")] : [])) } if @people.any?),
              (tag.span(class: "ss-tabcard-progress") { safe_join([tag.i(tag.b(style: "width:#{pct}%"), role: "progressbar", "aria-valuenow": pct, "aria-valuemin": 0, "aria-valuemax": 100, "aria-label": "Progresso"), tag.span("#{pct}%", class: "num")]) } if pct)
            ].compact)
          end,
          tag.div(class: "ss-tabcard-body") do
            safe_join([
              tag.span((@icon || ICON).html_safe, class: "ss-tabcard-icon"),
              tag.div(class: "ss-tabcard-text") { safe_join([tag.h3(@url ? link_to(@title, @url) : @title), (tag.p(@subtitle) if @subtitle)].compact) },
              (tag.details(class: "ss-menu") { safe_join([tag.summary("⋮", "aria-label": "Mais ações"), tag.div(content)]) } if content.present?)
            ].compact)
          end
        ])
      end
    end
  end
end
