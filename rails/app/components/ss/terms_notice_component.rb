module Ss
  # "Ao continuar, você concorda com os Termos de uso e a Política de privacidade." (v0.20, par do
  # SsTermsNotice), com os dois links (ss-link, outra aba) em pt-BR/en/es.
  #   render Ss::TermsNoticeComponent.new(terms_url: termos_url, privacy_url: privacidade_url)
  # text: troca a frase (use %{terms} e %{privacy} onde entram os links), ex. "Ao criar a conta você
  # concorda com os %{terms} e a %{privacy}.". align: :center (padrão) ou :start.
  class TermsNoticeComponent < BaseComponent
    def initialize(terms_url:, privacy_url:, text: nil, align: :center, **rest)
      super(**rest)
      @terms_url, @privacy_url, @text, @align = terms_url, privacy_url, text, align
    end

    def call
      frase = @text || ss_t("terms_notice.text", default: "Ao continuar, você concorda com os %{terms} e a %{privacy}.")
      links = {
        "terms" => render(Ss::TextLinkComponent.new(label: ss_t("terms_notice.terms", default: "Termos de uso"), href: @terms_url, external: true)),
        "privacy" => render(Ss::TextLinkComponent.new(label: ss_t("terms_notice.privacy", default: "Política de privacidade"), href: @privacy_url, external: true))
      }
      partes = frase.to_s.split(/(%\{(?:terms|privacy)\})/).map { |p| (m = p.match(/\A%\{(terms|privacy)\}\z/)) ? links[m[1]] : p }
      tag.p(safe_join(partes), **root_attrs(class: classes("ss-terms-notice", ("is-start" if @align.to_s == "start"))))
    end
  end
end
