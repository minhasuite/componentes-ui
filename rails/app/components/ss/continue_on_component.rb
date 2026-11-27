module Ss
  # v1.13.0 "confiança na IA e suíte" (par do SsContinueOn): "Continuar no celular". O botão abre um popover com o QR
  # (ss_qr_svg, sem gem) do link profundo da tela atual com o estado que o produto serializa (filtros, rascunho), o
  # link e "Copiar link". target: :computer é o texto do outro lado ("Continuar no computador"), para telas que abrem
  # no celular pelo navegador.
  #
  #   <%= render Ss::ContinueOnComponent.new(url: pedidos_url(app: 1), state: { filtros: params.permit(:status).to_h }) %>
  #
  # state: vai no link pelo ComponentesUi::Handoff (JSON em base64url no param: "s"; no app, SsHandoff.decode).
  # Rascunho ainda não salvo: handoff_url: + form: "id-do-form" — ao abrir, o ss-continue-on manda o FormData do
  # formulário (POST, com o token do Rails) para o endpoint do produto, que guarda o rascunho e responde
  # render json: Ss::ContinueOnComponent.payload(rascunho_url(token)) ({ url:, svg: }); o QR e o link trocam.
  #
  # Onde entra: minhas-vendas (pedido começado no computador, terminado na visita), meu-financeiro (lançamento com
  # foto do cupom pelo celular), meu-gestor (checklist), minhas-compras e minhas-viagens (o painel web).
  class ContinueOnComponent < BaseComponent
    LONG = 300

    # O que o endpoint do produto responde ao ss-continue-on: o link e o QR dele em SVG.
    def self.payload(url) = { url: url.to_s, svg: ComponentesUi::Qr.svg(url.to_s, margin: 1) }

    def initialize(url:, target: :phone, state: nil, param: "s", handoff_url: nil, form: nil, label: nil, **opts)
      super(**opts)
      @target = target.to_s == "computer" ? :computer : :phone
      @link = ComponentesUi::Handoff.link(url, state, param:)
      @handoff_url = handoff_url
      @form = form
      @label = label
    end

    attr_reader :link

    def t(key, **o) = ss_t("trust.#{key}", **o)
    def label = @label || t(@target == :phone ? "continue_phone" : "continue_computer")
    def hint = t(@target == :phone ? "continue_phone_hint" : "continue_computer_hint")
    def icon = @target == :phone ? "device-mobile" : "desktop-computer"
    def long? = @link.length > LONG
    def uid = @uid ||= "ss-cont-#{object_id}"
    def data
      { controller: "ss-continue-on", ss_continue_on_url_value: @handoff_url, ss_continue_on_form_value: @form,
        ss_continue_on_long_value: LONG }.compact
    end
  end
end
