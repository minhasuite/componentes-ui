module Ss
  # Tela de abertura / espera (v0.10.2, par do SsSplash): a marca (with_mark), o nome, o anel
  # (.ss-spinner) e a mensagem; o anel e a mensagem só aparecem depois de 300 ms (a espera curta
  # não pisca). inline: true cabe dentro de um card (sem ocupar a tela toda).
  #
  #   render(Ss::SplashComponent.new(title: "Minha Automação", message: "Instalando o app…")) { |s| s.with_mark { image_tag "logo.svg", alt: "" } }
  class SplashComponent < BaseComponent
    renders_one :mark

    def initialize(title: nil, message: nil, inline: false, **opts)
      super(**opts)
      @title, @message, @inline = title, message, inline
    end

    def call
      tag.div(**root_attrs(class: classes("ss-splash", ("is-inline" if @inline)), role: "status", "aria-live": "polite")) do
        safe_join([
          (tag.div(mark, class: "ss-splash-mark") if mark?),
          (tag.h1(@title, class: "ss-splash-title") if @title),
          tag.div(class: "ss-splash-wait") do
            safe_join([tag.span(class: "ss-spinner is-lg", "aria-hidden": "true"),
                       tag.p(@message || ss_t("spinner.label", default: "Carregando"), class: ("ss-splash-msg" if @message) || "ss-splash-msg ss-sr")])
          end
        ].compact)
      end
    end
  end
end
