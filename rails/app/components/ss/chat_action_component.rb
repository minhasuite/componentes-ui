module Ss
  # Cartão de ação a confirmar (v0.15, par do SsChatActionCard): o que o assistente propõe fazer
  # ("Lançar despesa de R$ 45 no Nubank"), com os dados em linhas e Confirmar/Cancelar. Vai dentro
  # de uma mensagem do Ss::ChatComponent (ou sozinho). Os botões postam em confirm_url/cancel_url
  # pelo Turbo; a resposta troca o cartão (turbo_stream replace no id:) pelo mesmo cartão com
  # state: :confirmed / :cancelled / :failed (sem botões, com a frase do resultado).
  #
  #   render Ss::ChatActionComponent.new(id: dom_id(acao), title: "Lançar despesa", icon: ss_icon("credit-card", size: nil),
  #     rows: [["Valor", "R$ 45,00"], ["Cartão", "Nubank"], ["Categoria", "Mercado"]],
  #     confirm_url: confirmar_acao_path(acao), cancel_url: cancelar_acao_path(acao))
  #
  # state: :pending (padrão, com botões), :confirmed, :cancelled, :failed. result: troca a frase do
  # estado. danger: true pinta o Confirmar de vermelho (excluir, desfazer). Enviando, os botões
  # travam (aria-busy) para não confirmar duas vezes.
  class ChatActionComponent < BaseComponent
    STATES = %i[pending confirmed cancelled failed].freeze

    attr_reader :title, :rows, :state

    def initialize(title:, rows: [], id: nil, description: nil, icon: nil, confirm_url: nil, cancel_url: nil, state: :pending,
                   result: nil, confirm_label: nil, cancel_label: nil, danger: false, http_method: :post, **rest)
      super(**rest)
      @title, @rows, @id, @description, @icon = title, rows.map { |(k, v)| [k.to_s, v] }, id, description, icon
      @confirm_url, @cancel_url, @result, @confirm_label, @cancel_label, @danger, @http_method =
        confirm_url, cancel_url, result, confirm_label, cancel_label, danger, http_method
      @state = STATES.include?(state.to_s.to_sym) ? state.to_s.to_sym : :pending
    end

    def pending? = @state == :pending
    def id = @id || "ss-act-#{object_id}"
    def icon = @icon.presence&.to_s&.html_safe
    def description = @description
    def danger? = @danger
    def confirm_url = @confirm_url
    def cancel_url = @cancel_url
    def http_method = @http_method
    def confirm_label = @confirm_label || ss_t("chat.confirm", default: "Confirmar")
    def cancel_label = @cancel_label || ss_t("chat.cancel", default: "Cancelar")
    def kicker = ss_t("chat.action", default: "Ação proposta")

    def result
      @result || { confirmed: ss_t("chat.confirmed", default: "Feito"), cancelled: ss_t("chat.cancelled", default: "Cancelado"),
                   failed: ss_t("chat.failed", default: "Não deu certo") }[@state]
    end

    def tone = { confirmed: "success", cancelled: "muted", failed: "danger" }[@state]
  end
end
