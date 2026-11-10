module Ss
  # Botão de esconder valores (v0.18, par do SsPrivacyToggle): o olho que liga/desliga o
  # [data-privacy="on"] do controller ss-privacy (que precisa estar num ancestral, ex. o <body>:
  # data-controller="ss-privacy"). aria-pressed acompanha o estado (o controller sincroniza), o
  # ícone troca sozinho (olho cortado quando à vista; olho quando escondido) e a dica lembra a tecla P.
  #
  #   render Ss::PrivacyToggleComponent.new                         (ícone, no topo)
  #   render Ss::PrivacyToggleComponent.new(text: true, css: "lg:hidden")   (ícone + "Ocultar valores")
  #
  # label: nome lido (padrão "Ocultar valores"); hint: a dica (padrão "Ocultar valores (P)"; false
  # tira o atalho); text: true mostra o rótulo ao lado (vira .ss-btn .ss-btn-ghost .ss-btn-sm);
  # size: :sm/:md.
  class PrivacyToggleComponent < BaseComponent
    def initialize(label: nil, hint: nil, text: false, size: :md, **rest)
      super(**rest)
      @label = label || ss_t("privacy.hide", default: "Ocultar valores")
      @hint = hint == false ? @label : (hint || ss_t("privacy.hint", default: "%{label} (P)", label: @label))
      @text = text
      @size = size.to_s == "sm" ? :sm : :md
    end

    def call
      css = @text ? classes("ss-btn", "ss-btn-ghost", "ss-btn-sm", "ss-privacy-toggle") : classes("ss-icon-btn", ("is-sm" if @size == :sm), "ss-privacy-toggle")
      tag.button(type: "button", **root_attrs(class: css, title: @hint, "aria-label": @label, "aria-pressed": "false",
                                              data: { action: "ss-privacy#toggle", privacy_toggle: "" })) do
        safe_join([tag.span(ss_icon("eye-off", size: nil), class: "ss-eye-on", "aria-hidden": "true"),
                   tag.span(ss_icon("eye", size: nil), class: "ss-eye-off", "aria-hidden": "true"),
                   (tag.span(@label) if @text)].compact)
      end
    end
  end
end
