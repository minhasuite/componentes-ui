module Ss
  # Bloco do mosaico (v0.13, par do SsMosaicTile): um card colorido na cor da marca (variant: 0 a 4
  # desloca o matiz, como o SsMosaicTile.colorsFor) ou uma foto com véu, com o ícone em cima, o
  # título grande embaixo e uma linha em versalete (caption:) ou as pílulas de resumo (facts:).
  # Cômodo, área, coleção, categoria. Com url: o bloco todo é um link.
  #
  #   render Ss::MosaicTileComponent.new(title: "Sala", icon: svg, url: area_path(a), variant: 2,
  #                                      facts: [{ label: "2 ligados", icon: bulb }, { label: "87 W" }])
  #   render Ss::MosaicTileComponent.new(title: "Cozinha", caption: "Tudo calmo", image_url: foto)
  #
  # image_url: https ou caminho (/...) da foto; outro valor é ignorado. link_data: data- do link.
  class MosaicTileComponent < BaseComponent
    IMAGE = %r{\A(https://|/)[^"'()\s<>]+\z}

    def initialize(title:, caption: nil, icon: nil, image_url: nil, variant: 0, facts: nil, url: nil, link_data: nil, **rest)
      super(**rest)
      @title, @caption, @icon, @url, @link_data = title, caption, icon, url, link_data
      @image = image_url.to_s.match?(IMAGE) ? image_url.to_s : nil
      @variant = variant.to_i.abs % 5
      @facts = Array(facts).map { |f| f.is_a?(Hash) ? f.transform_keys(&:to_sym) : { label: f.to_s } }
    end

    def call
      attrs = root_attrs(class: classes("ss-mosaic", ("has-photo" if @image)), data: { variant: @variant })
      attrs[:style] = ["--photo: url(#{@image})", attrs[:style]].compact.join("; ") if @image
      body = safe_join([
        (tag.span(@icon.to_s.html_safe, class: "ss-mosaic-ico", "aria-hidden": "true") if @icon.present?),
        tag.span(@title, class: "ss-mosaic-title"),
        (tag.span(@caption, class: "ss-mosaic-caption") if @caption.present? && @facts.empty?),
        (facts if @facts.any?)
      ].compact)
      return link_to(body, @url, **attrs.merge(data: attrs[:data].merge(@link_data.to_h))) if @url

      tag.div(body, **attrs)
    end

    private

    def facts
      tag.span(class: "ss-mosaic-facts") do
        safe_join(@facts.map { |f| tag.span(safe_join([(f[:icon].to_s.html_safe if f[:icon].present?), f[:label]].compact), class: ["ss-mosaic-fact", ("num" if f[:num])].compact.join(" ")) })
      end
    end
  end
end
