module Ss
  # Card de foto (v0.13, par do SsPhotoCard): a imagem cobrindo o card na proporção pedida, com o
  # título e um selo de estado (Ligada, 22 °C) por cima de um véu escuro embaixo. dimmed: deixa a
  # foto em cinza e mais escura (aparelho desligado). Sem imagem, fica o fundo de campo.
  #
  #   render Ss::PhotoCardComponent.new(src: foto_url, title: "Varanda", badge: "Ligada", ratio: "4 / 3")
  #   render Ss::PhotoCardComponent.new(src: url, title: "Jardim", dimmed: true, url: ponto_path(p))
  #
  # ratio: "16 / 9" (padrão) ou "4 / 3", "1"...; alt: o texto da imagem (padrão: o título).
  #
  # v0.19.2 (par do SsPhotoCard(subtitle:, credit:, selected:)): subtitle: embaixo do título (o título
  # cresce); credit: o crédito da foto no canto de cima ("Foto: Autor · CC BY 4.0"), com credit_url: vira
  # link para a página da foto (só quando o card não é link: link dentro de link não vale); selected: true
  # põe o contorno da marca e o ✓ (aria-current="true").
  #   render Ss::PhotoCardComponent.new(src: url, title: "Praia do Rosa", subtitle: "Imbituba, SC",
  #                                     credit: "Foto: Fulano · CC BY 4.0", credit_url: pagina, selected: true)
  class PhotoCardComponent < BaseComponent
    RATIO = %r{\A\d+(\.\d+)?(\s*/\s*\d+(\.\d+)?)?\z}

    def initialize(src: nil, title: nil, badge: nil, ratio: "16 / 9", dimmed: false, alt: nil, url: nil,
                   subtitle: nil, credit: nil, credit_url: nil, selected: false, **rest)
      super(**rest)
      @src, @title, @badge, @dimmed, @alt, @url = src.presence, title.presence, badge.presence, dimmed, alt, url
      @subtitle, @credit, @credit_url, @selected = subtitle.presence, credit.presence, credit_url.presence, selected
      @ratio = ratio.to_s.match?(RATIO) ? ratio.to_s : "16 / 9"
    end

    def call
      attrs = root_attrs(class: classes("ss-card", "ss-photo", ("is-dimmed" if @dimmed), ("is-link" if @url),
                                        ("has-subtitle" if @subtitle), ("is-selected" if @selected)))
      attrs[:style] = ["aspect-ratio: #{@ratio}", attrs[:style]].compact.join("; ")
      attrs[:aria] = (attrs[:aria] || {}).merge(current: "true") if @selected
      body = safe_join([
        (tag.img(src: @src, alt: @alt || @title.to_s, loading: "lazy", decoding: "async") if @src),
        (if @title || @badge || @subtitle
           content_tag(@url ? :span : :figcaption, class: "ss-photo-cap") do
             safe_join([title_html, (tag.span(@badge, class: "ss-photo-badge") if @badge)].compact)
           end
         end),
        credit_html
      ].compact)
      return link_to(body, @url, **attrs) if @url

      tag.figure(body, **attrs)
    end

    private

    def title_html
      title = tag.span(@title.to_s, class: "ss-photo-title")
      return title unless @subtitle

      tag.span(class: "ss-photo-text") { safe_join([title, tag.span(@subtitle, class: "ss-photo-subtitle")]) }
    end

    def credit_html
      return nil unless @credit
      return tag.span(@credit, class: "ss-photo-credit") if @url || !@credit_url

      link_to(@credit, @credit_url, class: "ss-photo-credit", target: "_blank", rel: "noopener",
                                    title: ss_t("photo_card.source", default: "Abrir a página da foto"))
    end
  end
end
