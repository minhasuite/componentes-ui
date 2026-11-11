module Ss
  # Link no meio do texto (v0.20, par do SsTextLink do SsLinkText): a.ss-link na cor da marca em 700,
  # sublinhado no hover/foco. external: true abre em outra aba (target=_blank rel=noopener) com o ícone
  # de saída e "(abre em outra aba)" para o leitor de tela.
  #   Li e aceito os <%= render Ss::TextLinkComponent.new(label: "termos", href: termos_url, external: true) %>.
  class TextLinkComponent < BaseComponent
    def initialize(label: nil, href:, external: false, **rest)
      super(**rest)
      @label, @href, @external = label, href, external
    end

    def call
      ext = { target: "_blank", rel: "noopener" } if @external
      link_to(@href, **root_attrs(class: classes("ss-link", ("is-external" if @external)), **ext.to_h)) do
        safe_join([content.presence || @label,
                   (ss_icon("external-link", size: :xs) if @external),
                   (tag.span(" #{ss_t("app_shell.external", default: "(abre em outra aba)")}", class: "ss-sr") if @external)].compact)
      end
    end
  end
end
