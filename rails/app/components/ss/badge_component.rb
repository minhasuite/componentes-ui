module Ss
  # Selo (v0.25, o .ss-badge como componente; par do SsBadge do Flutter): a pílula pequena e fina de resumo,
  # estado ou contagem ("1 luz acesa", "2 sem sinal", "Rascunho"). Mesmo tamanho em toda tela, com ou sem ícone.
  #
  #   render Ss::BadgeComponent.new(label: "1 luz acesa", icon: "light-bulb")
  #   render Ss::BadgeComponent.new(label: "3 atrasadas", tone: :warn, href: contas_path(f: :atrasadas))
  #   render Ss::BadgeComponent.new(label: "Online", tone: :success, dot: true)
  #
  # tone: :neutral (padrão, fundo de campo; o ghost do SsBadge), :accent, :success, :warn, :danger, :muted.
  # icon: nome do ss_icon ou SVG já seguro. dot: ponto na cor do texto (ignorado com icon:). solid: fundo cheio
  # (.is-solid); mono: texto em DM Mono (.is-mono, para código; contagem comum fica na fonte do texto).
  # href: vira <a> (link_data: no <a>, ex. { turbo_frame: "_top" }); title: dica. O bloco troca o label:.
  class BadgeComponent < BaseComponent
    TONES = { neutral: nil, accent: "ss-badge-accent", success: "ss-badge-success", warn: "ss-badge-warn", warning: "ss-badge-warn",
              danger: "ss-badge-danger", muted: "ss-badge-muted" }.freeze

    def initialize(label: nil, tone: :neutral, icon: nil, dot: false, solid: false, mono: false, href: nil, link_data: nil, title: nil, **rest)
      super(**rest)
      @label, @icon, @dot, @solid, @mono, @href, @link_data, @title = label, icon, dot, solid, mono, href, link_data, title
      @tone = TONES.key?(tone.to_s.to_sym) ? tone.to_s.to_sym : :neutral
    end

    def call
      css = classes("ss-badge", TONES[@tone], ("ss-badge-dot" if @dot && @icon.blank?), ("is-solid" if @solid), ("is-mono" if @mono))
      text = content.presence || @label.to_s
      # Só texto: o texto solto (o .ss-badge vira inline-block e termina em "…"); com ícone, o texto num <span>.
      body = @icon.present? ? safe_join([svg, tag.span(text)]) : text
      if @href
        link_to(@href, **root_attrs(class: css, title: @title, data: @link_data.to_h)) { body }
      else
        tag.span(**root_attrs(class: css, title: @title)) { body }
      end
    end

    private

    def svg
      return @icon if @icon.respond_to?(:html_safe?) && @icon.html_safe?

      ss_icon(@icon.to_s, size: :xs)
    end
  end
end
