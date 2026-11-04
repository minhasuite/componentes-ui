module Ss
  # Tour guiado: escurece a tela com um recorte em volta do alvo [data-tour-step="nome"],
  # balão com passo n/total, Voltar/Próximo/Pular. Lembra no navegador que a pessoa
  # já viu (chave "ss-tour:<id>"); autostart: false só abre pelo botão.
  #   render Ss::TourComponent.new(id: "painel-v2", steps: [{ target: "kpis", title: "Seus números", text: "…" }, …])
  #   <button data-action="ss-tour#start">Ver tour</button> (dentro do componente, ou use start_label:)
  class TourComponent < BaseComponent
    def initialize(id:, steps:, autostart: true, start_label: nil, **opts)
      super(**opts)
      @id = id
      @steps = steps
      @autostart = autostart
      @start_label = start_label
    end

    def call
      tag.div(**root_attrs(class: classes("ss-tour"), data: { controller: "ss-tour", ss_tour_key_value: "ss-tour:#{@id}",
                                                      # Textos que o controller troca a cada passo.
                                                      ss_tour_count_label_value: ss_t("tour.count", default: "%{n} de %{total}"),
                                                      ss_tour_next_label_value: ss_t("tour.next", default: "Próximo"),
                                                      ss_tour_done_label_value: ss_t("tour.done", default: "Concluir"),
                                                              ss_tour_steps_value: @steps.to_json, ss_tour_autostart_value: @autostart })) do
        safe_join([
          (tag.button(@start_label, type: "button", class: "ss-btn ss-btn-outline ss-btn-sm", data: { action: "ss-tour#start" }) if @start_label),
          content,
          tag.div(class: "ss-tour-layer", hidden: true, data: { ss_tour_target: "layer" }) do
            safe_join([
              tag.div(class: "ss-tour-hole", data: { ss_tour_target: "hole" }),
              tag.div(class: "ss-tour-pop", role: "dialog", "aria-modal": "true", "aria-labelledby": "#{@id}-tt", tabindex: -1, data: { ss_tour_target: "pop" }) do
                safe_join([
                  tag.small(class: "ss-tour-count num", data: { ss_tour_target: "count" }),
                  tag.h3("", id: "#{@id}-tt", data: { ss_tour_target: "title" }),
                  tag.p("", data: { ss_tour_target: "text" }),
                  tag.div(class: "ss-tour-actions") do
                    safe_join([
                      tag.button(ss_t("tour.skip", default: "Pular"), type: "button", class: "ss-btn ss-btn-ghost ss-btn-sm", data: { action: "ss-tour#finish", ss_tour_target: "skip" }),
                      tag.button(ss_t("common.back", default: "Voltar"), type: "button", class: "ss-btn ss-btn-outline ss-btn-sm", data: { action: "ss-tour#prev", ss_tour_target: "back" }),
                      tag.button(ss_t("tour.next", default: "Próximo"), type: "button", class: "ss-btn ss-btn-primary ss-btn-sm", data: { action: "ss-tour#next", ss_tour_target: "next" })
                    ])
                  end
                ])
              end
            ])
          end
        ].compact)
      end
    end
  end
end
