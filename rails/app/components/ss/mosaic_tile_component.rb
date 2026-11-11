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
  #
  # v0.19.3: cada pílula pode ter tone: (ok, warn, danger, info → .is-ok etc., cores semânticas da
  # suíte; success e warning, os nomes do SsTone, também valem), title: (dica e nome acessível) e
  # url: (link próprio, com o link_data: dela). Como link dentro de link não vale, com alguma pílula
  # com url: o bloco com url: vira <div class="ss-mosaic is-linked"> e o link dele passa a ser um
  # <a class="ss-mosaic-link"> esticado por cima de tudo (com o link_data: e aria-label = title),
  # e as pílulas com url: ficam acima dele.
  #
  #   facts: [{ label: "12 em dia" }, { label: "3 atrasadas", tone: :warn, url: contas_path(f: :atrasadas),
  #             title: "Ver as 3 atrasadas", link_data: { turbo_frame: "_top" } }]
  class MosaicTileComponent < BaseComponent
    IMAGE = %r{\A(https://|/)[^"'()\s<>]+\z}
    TONES = %w[ok warn danger info].freeze
    TONE_ALIAS = { "success" => "ok", "warning" => "warn" }.freeze # os nomes do SsTone do Flutter

    def initialize(title:, caption: nil, icon: nil, image_url: nil, variant: 0, facts: nil, url: nil, link_data: nil, **rest)
      super(**rest)
      @title, @caption, @icon, @url, @link_data = title, caption, icon, url, link_data
      @image = image_url.to_s.match?(IMAGE) ? image_url.to_s : nil
      @variant = variant.to_i.abs % 5
      @facts = Array(facts).map { |f| f.is_a?(Hash) ? f.transform_keys(&:to_sym) : { label: f.to_s } }
    end

    def call
      linked = @url && @facts.any? { |f| f[:url].present? }
      attrs = root_attrs(class: classes("ss-mosaic", ("has-photo" if @image), ("is-linked" if linked)), data: { variant: @variant })
      attrs[:style] = ["--photo: url(#{@image})", attrs[:style]].compact.join("; ") if @image
      body = safe_join([
        (tag.span(@icon.to_s.html_safe, class: "ss-mosaic-ico", "aria-hidden": "true") if @icon.present?),
        tag.span(@title, class: "ss-mosaic-title"),
        (tag.span(@caption, class: "ss-mosaic-caption") if @caption.present? && @facts.empty?),
        (facts if @facts.any?)
      ].compact)
      if linked
        # Link esticado: o <a> do bloco cobre o card e as pílulas com url: ficam por cima.
        stretched = link_to("", @url, class: "ss-mosaic-link", "aria-label": @title, data: @link_data.to_h)
        return tag.div(safe_join([stretched, body]), **attrs)
      end
      return link_to(body, @url, **attrs.merge(data: attrs[:data].merge(@link_data.to_h))) if @url

      tag.div(body, **attrs)
    end

    private

    def facts
      tag.span(class: "ss-mosaic-facts") do
        safe_join(@facts.map { |f| fact(f) })
      end
    end

    def fact(f)
      content = safe_join([(f[:icon].to_s.html_safe if f[:icon].present?), f[:label]].compact)
      tone = f[:tone].to_s
      tone = TONE_ALIAS.fetch(tone, tone)
      css = ["ss-mosaic-fact", ("num" if f[:num]), ("is-#{tone}" if TONES.include?(tone))].compact.join(" ")
      title = f[:title].presence
      return link_to(content, f[:url], class: css, title: title, "aria-label": title, data: f[:link_data].to_h) if f[:url].present?

      tag.span(content, class: css, title: title)
    end
  end
end
