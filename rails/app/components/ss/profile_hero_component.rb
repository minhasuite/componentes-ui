module Ss
  # Cabeçalho de perfil (v1.10, par do SsProfileHero): foto grande arredondada (sem foto, as iniciais no
  # gradiente do nome, como o ss_avatar), nome, status com ponto e até três métricas em destaque, sobre o fundo
  # tonal da marca com a borda de baixo curva. with_action: os botões do topo à direita; with_leading: à esquerda
  # (voltar).
  #
  #   render Ss::ProfileHeroComponent.new(name: "Ana Souza", photo_url: url, status: "Online agora", online: true,
  #     metrics: [["128", "pedidos"], ["4,9", "nota"], ["3 anos", "cliente"]]) do |h|
  #     h.with_action { render Ss::IconButtonComponent.new(icon: "pencil", label: "Editar", href: editar_path) }
  #   end
  #
  # metrics: [[valor pronto, rótulo]] (até 3; cada uma é lida "128 pedidos"). online: o ponto verde do status.
  class ProfileHeroComponent < BaseComponent
    renders_many :actions
    renders_one :leading

    def initialize(name:, photo_url: nil, status: nil, online: false, metrics: [], brand_hue: 250, **rest)
      super(**rest)
      @name, @photo_url, @status, @online = name, photo_url, status, online
      @metrics = Array(metrics).first(3)
      @hue = (brand_hue + (ss_seed(name.to_s) % 5 - 2) * 24) % 360
    end

    def before_render = content

    def call
      tag.header(**root_attrs(class: classes("ss-profile-hero"))) do
        safe_join([
          ((leading? || actions?) ? tag.div(safe_join([tag.div(leading.to_s), tag.div(safe_join(actions.map(&:to_s)), class: "ss-profile-hero-actions")]), class: "ss-profile-hero-bar") : nil),
          photo,
          tag.h1(@name, class: "ss-profile-hero-name"),
          (status if @status),
          (metrics if @metrics.any?)
        ].compact)
      end
    end

    private

    def photo
      tag.div(class: "ss-profile-hero-photo", style: "--h:#{@hue}") do
        if @photo_url
          image_tag(@photo_url, alt: ss_t("profile_hero.photo", default: "Foto de %{name}", name: @name))
        else
          tag.span(ss_initials(@name.to_s), class: "ss-profile-hero-initials", "aria-hidden": "true")
        end
      end
    end

    def status
      tag.p(class: "ss-profile-hero-status") do
        safe_join([(tag.span(class: "ss-profile-hero-dot", role: "img", "aria-label": ss_t("profile_hero.online", default: "Online")) if @online),
                   tag.span(@status)].compact)
      end
    end

    def metrics
      tag.ul(class: "ss-profile-hero-metrics") do
        safe_join(@metrics.map { |(v, l)| tag.li(safe_join([tag.strong(v, class: "num"), " ", tag.span(l)]), class: "ss-profile-hero-metric") })
      end
    end
  end
end
