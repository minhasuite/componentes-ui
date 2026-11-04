module Ss
  # Pessoa (vendedor, cliente, membro da equipe): avatar, nome, papel, métricas e a
  # equipe em avatares empilhados. Bloco = ações (botões/links) no rodapé.
  #   render Ss::PersonCardComponent.new(name: "Ana Souza", role: "Vendedora · Zona Sul", status: "ok",
  #     metrics: [["Vendido", "R$ 48 mil"], ["Pedidos", "214"]], team: ["Bruno", "Caio", "Duda"], url: vendedor_path(v))
  class PersonCardComponent < BaseComponent
    include InView
    def initialize(name:, role: nil, status: nil, metrics: [], team: [], team_label: "Equipe", url: nil, **opts)
      super(**opts)
      @name = name
      @role = role
      @status = status
      @metrics = metrics
      @team = team
      @team_label = team_label
      @url = url
    end

    def call
      tag.article(**root_attrs(class: classes("ss-card", "ss-person"), data: in_view_data)) do
        safe_join([
          tag.div(class: "ss-person-head") do
            safe_join([ss_avatar(@name, size: 56, status: @status),
                       tag.div { safe_join([tag.h3(@url ? link_to(@name, @url) : @name), (tag.p(@role) if @role)].compact) }])
          end,
          (tag.dl(class: "ss-person-metrics") { safe_join(@metrics.map { |(l, v)| tag.div(safe_join([tag.dt(l), tag.dd(v, class: "num")])) }) } if @metrics.any?),
          (team if @team.any?),
          (tag.div(content, class: "ss-person-actions") if content.present?)
        ].compact)
      end
    end

    private

    def team
      shown = @team.first(4)
      tag.div(class: "ss-person-team") do
        safe_join([tag.small(@team_label),
                   tag.span(class: "ss-avatars", "aria-label": "#{@team_label}: #{@team.join(", ")}") do
                     safe_join(shown.map { ss_avatar(_1, size: 28) } + (@team.size > 4 ? [tag.span("+#{@team.size - 4}", class: "ss-avatar more", style: "--s:28px")] : []))
                   end])
      end
    end
  end
end
