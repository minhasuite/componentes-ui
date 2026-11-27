module Ss
  # Lançamento recorrente (v1.10, par do SsRecurringCard): "Todo domingo · 11:00", valor em DM Mono, destino e
  # um check redondo (cheio quando já foi feito neste ciclo; estoura com a mola ao marcar). O valor rola ao mudar
  # (Ss::OdometerComponent: o morph do Turbo troca o texto e os dígitos giram).
  #
  #   render Ss::RecurringCardComponent.new(schedule: "Todo domingo", time: "11:00", amount: ss_money(50),
  #     destination: "para Instituto Sol", done: true, url: recorrencia_path(r))
  #   … { |c| c.with_menu { render Ss::RowActionsComponent.new(…) } }
  #
  # url: o cartão inteiro vira link (onTap). with_menu: o menu ⋮ (onMenu) no canto de baixo; menu_url: um link ⋮
  # simples no lugar dele. Leitor de tela: "Feito"/"Pendente" no check.
  class RecurringCardComponent < BaseComponent
    renders_one :menu

    def initialize(schedule:, amount:, time: nil, destination: nil, done: false, url: nil, menu_url: nil, **rest)
      super(**rest)
      @schedule, @amount, @time, @destination, @done, @url, @menu_url = schedule, amount, time, destination, done, url, menu_url
    end

    def before_render = content

    def check_label = @done ? ss_t("recurring_card.done", default: "Feito") : ss_t("recurring_card.pending", default: "Pendente")

    def call
      tag.article(**root_attrs(class: classes("ss-recurring", ("is-done" if @done), ("is-link" if @url)))) do
        safe_join([
          tag.div(class: "ss-recurring-top") do
            safe_join([
              tag.span(ss_icon("check", size: nil), class: "ss-recurring-check", role: "img", "aria-label": check_label),
              tag.div(class: "ss-recurring-when") do
                safe_join([(@url ? link_to(@schedule, @url, class: "ss-recurring-link") : tag.strong(@schedule)),
                           (tag.span(@time, class: "num") if @time)].compact)
              end
            ])
          end,
          tag.div(class: "ss-recurring-foot") do
            safe_join([
              tag.div(class: "ss-recurring-value") do
                safe_join([render(Ss::OdometerComponent.new(text: @amount, size: "1.5rem")),
                           (tag.span(@destination, class: "ss-recurring-dest") if @destination)].compact)
              end,
              menu_slot
            ].compact)
          end
        ])
      end
    end

    private

    def menu_slot
      return tag.div(menu.to_s, class: "ss-recurring-menu") if menu?
      return nil unless @menu_url

      link_to(ss_icon("dots-horizontal", size: nil), @menu_url, class: "ss-recurring-menu ss-recurring-more",
              "aria-label": ss_t("recurring_card.more", default: "Mais opções"))
    end
  end
end
