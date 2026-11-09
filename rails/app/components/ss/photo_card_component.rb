module Ss
  # Card de foto (v0.13, par do SsPhotoCard): a imagem cobrindo o card na proporção pedida, com o
  # título e um selo de estado (Ligada, 22 °C) por cima de um véu escuro embaixo. dimmed: deixa a
  # foto em cinza e mais escura (aparelho desligado). Sem imagem, fica o fundo de campo.
  #
  #   render Ss::PhotoCardComponent.new(src: foto_url, title: "Varanda", badge: "Ligada", ratio: "4 / 3")
  #   render Ss::PhotoCardComponent.new(src: url, title: "Jardim", dimmed: true, url: ponto_path(p))
  #
  # ratio: "16 / 9" (padrão) ou "4 / 3", "1"...; alt: o texto da imagem (padrão: o título).
  class PhotoCardComponent < BaseComponent
    RATIO = %r{\A\d+(\.\d+)?(\s*/\s*\d+(\.\d+)?)?\z}

    def initialize(src: nil, title: nil, badge: nil, ratio: "16 / 9", dimmed: false, alt: nil, url: nil, **rest)
      super(**rest)
      @src, @title, @badge, @dimmed, @alt, @url = src.presence, title.presence, badge.presence, dimmed, alt, url
      @ratio = ratio.to_s.match?(RATIO) ? ratio.to_s : "16 / 9"
    end

    def call
      attrs = root_attrs(class: classes("ss-card", "ss-photo", ("is-dimmed" if @dimmed), ("is-link" if @url)))
      attrs[:style] = ["aspect-ratio: #{@ratio}", attrs[:style]].compact.join("; ")
      body = safe_join([
        (tag.img(src: @src, alt: @alt || @title.to_s, loading: "lazy", decoding: "async") if @src),
        (if @title || @badge
           content_tag(@url ? :span : :figcaption, class: "ss-photo-cap") do
             safe_join([tag.span(@title.to_s, class: "ss-photo-title"), (tag.span(@badge, class: "ss-photo-badge") if @badge)].compact)
           end
         end)
      ].compact)
      return link_to(body, @url, **attrs) if @url

      tag.figure(body, **attrs)
    end
  end
end
